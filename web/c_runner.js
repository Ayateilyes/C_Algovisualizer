/**
 * c_runner.js — Educational C runner + step-by-step tracer
 *
 * Supports:
 *  - User-defined functions (before main), recursion
 *  - Function calls with proper return values
 *  - Basic pointer simulation (&x, *p) — including in function args
 *  - Character literals ('A', '\n', '\0')
 *  - Float literals in all expression contexts
 *  - Arrays, loops, conditionals
 *  - Call-stack tracking in trace mode
 *  - Rich error reporting with line/col/caret/hints
 *
 * window.CRunner.run(src, inputs?)   → {stdout,stderr,exitCode,elapsed,success}
 * window.CRunner.trace(src, inputs?) → {steps:[{line,vars,output,callStack}], ...}
 * window.CRunner.detectInputs(src)   → [{format,varName},...]
 */
(function () {
  "use strict";

  const MAX_OPS = 500_000;

  // ── Error formatting ──────────────────────────────────────────────────────
  // Returns a structured error object for the Dart side to consume.
  function formatError(jsError, cSource) {
    const msg = String(jsError.message || jsError);
    const srcLines = cSource.split("\n");

    let errorLine = -1, errorCol = -1;
    let hint = "";

    // ── Strategy 0: If the error has an explicit .cLine (from our validator), use it directly ──
    if (jsError && typeof jsError.cLine === "number" && jsError.cLine > 0) {
      errorLine = jsError.cLine;
    }

    // ── Detect common patterns and provide hints ──
    if (msg.includes("Missing semicolon")) {
      hint = "Every statement in C must end with a semicolon (;).";
    } else if (msg.includes("Unexpected token '.'")) {
      hint = "Use format 3.5 not 3,5 — float literals must use a dot.";
    } else if (msg.includes("Unexpected token ';'")) {
      hint = "Did you forget a semicolon at the end of this line?";
    } else if (msg.includes("Unexpected identifier")) {
      hint = "Check for unsupported syntax or a missing semicolon on the previous line.";
    } else if (msg.includes("Unexpected token ')'")) {
      hint = "Mismatched parentheses or missing argument.";
    } else if (msg.includes("Unexpected token '}'")) {
      hint = "Check your opening braces { — one is never closed.";
    } else if (msg.includes("is not defined")) {
      const m = msg.match(/(\w+) is not defined/);
      if (m) hint = `Variable '${m[1]}' was used but never declared.`;
    } else if (msg.includes("is not a function")) {
      const m = msg.match(/(\w+) is not a function/);
      if (m) hint = `'${m[1]}' is not a callable function. Did you forget to define it?`;
    } else if (msg.includes("Invalid left-hand side")) {
      hint = "Use == for comparison, = is for assignment.";
    } else if (msg.includes("Timeout: infinite loop")) {
      hint = "Your program exceeded the maximum operation limit. Check for infinite loops.";
    } else if (msg.includes("Missing initializer")) {
      hint = "Did you forget a semicolon at the end of this line?";
    } else if (!hint) {
      hint = "This character or syntax is not valid in C.";
    }

    // ── Strategy 1: "on line N" pattern in the message ──
    if (errorLine === -1) {
      const lineMatch = msg.match(/on line (\d+)/i);
      if (lineMatch) {
        errorLine = parseInt(lineMatch[1], 10);
      }
    }

    // ── Strategy 2: look for the bad token in the source ──
    if (errorLine === -1) {
      const tokenMatch = msg.match(/Unexpected token '([^']+)'/);
      if (tokenMatch) {
        const badToken = tokenMatch[1];
        for (let i = 0; i < srcLines.length; i++) {
          const col = srcLines[i].indexOf(badToken);
          if (col !== -1) {
            const t = srcLines[i].trim();
            if (t && !t.startsWith("//") && !t.startsWith("#") && !t.startsWith("/*")) {
              errorLine = i + 1;
              errorCol = col + 1;
              break;
            }
          }
        }
      }
    }
    // Strategy 3: undeclared variable — find the line containing that variable
    if (errorLine === -1) {
      const undeclMatch = msg.match(/(\w+) is not defined/);
      if (undeclMatch) {
        const varName = undeclMatch[1];
        for (let i = 0; i < srcLines.length; i++) {
          const col = srcLines[i].indexOf(varName);
          if (col !== -1) {
            const t = srcLines[i].trim();
            if (t && !t.startsWith("//") && !t.startsWith("#")) {
              errorLine = i + 1;
              errorCol = col + 1;
              break;
            }
          }
        }
      }
    }

    // ── Fallback: use last non-empty source line ──
    if (errorLine === -1) {
      for (let i = srcLines.length - 1; i >= 0; i--) {
        const t = srcLines[i].trim();
        if (t && t !== "}" && !t.startsWith("//") && !t.startsWith("#")) {
          errorLine = i + 1;
          break;
        }
      }
    }

    const sourceLine = errorLine > 0 ? srcLines[errorLine - 1] : "";

    // Build console-formatted text
    const bar = "\u2500".repeat(40);
    let formatted = bar + "\n";
    formatted += ` ERROR on Line ${errorLine > 0 ? errorLine : 1}\n`;
    formatted += bar + "\n";
    if (errorLine > 0) {
      formatted += ` ${errorLine} |  ${sourceLine}\n`;
      if (errorCol > 0) {
        const pad = String(errorLine).length + 4 + errorCol - 1;
        formatted += " ".repeat(pad) + "^\n";
      }
    }
    formatted += ` ${msg}\n`;
    if (hint) formatted += ` Hint: ${hint}\n`;
    formatted += bar;

    return {
      line: errorLine > 0 ? errorLine : 1,
      column: errorCol > 0 ? errorCol : -1,
      message: msg,
      hint: hint,
      sourceLine: sourceLine,
      formattedText: formatted,
    };
  }

  // ── Semicolon validator ────────────────────────────────────────────────────
  // Pre-transpile pass: checks every statement inside function bodies for
  // a trailing semicolon. Throws with .cLine on failure.
  function validateSemicolons(src) {
    // Strip preprocessor directives and comments, preserving line structure
    let cleaned = src.replace(/^\s*#[^\n]*/gm, (m) => " ".repeat(m.length));
    cleaned = cleaned.replace(/\/\*[\s\S]*?\*\//g, (m) => m.replace(/[^\n]/g, " "));
    cleaned = cleaned.replace(/\/\/[^\n]*/g, (m) => " ".repeat(m.length));

    // Replace string literals with spaces (preserve length for column accuracy)
    cleaned = cleaned.replace(/"(?:[^"\\]|\\.)*"/g, (m) => " ".repeat(m.length));
    // Replace char literals
    cleaned = cleaned.replace(/'(?:[^'\\]|\\.)*'/g, (m) => " ".repeat(m.length));

    const lines = cleaned.split("\n");
    const cTypes = /^(?:int|float|double|long|short|unsigned|char|void)\b/;
    const controlFlow = /^(?:if|else|for|while|do|switch|case|default|struct|typedef|enum|union)\b/;
    const fnHeader = /^\w+\s+\w+\s*\(/; // e.g. "int main("

    // Track brace depth — only validate inside function bodies
    let braceDepth = 0;
    let insideFunction = false;

    for (let i = 0; i < lines.length; i++) {
      const raw = lines[i];
      const t = raw.trim();

      // Track brace depth
      for (const ch of raw) {
        if (ch === "{") { braceDepth++; insideFunction = true; }
        else if (ch === "}") { braceDepth--; if (braceDepth <= 0) insideFunction = false; }
      }

      if (!insideFunction) continue;
      if (!t || t === "{" || t === "}" || t === "{}") continue;

      // Skip lines that open/close braces at the end
      if (t.endsWith("{") || t.endsWith("}")) continue;

      // Skip control flow headers (if, for, while, else, do, switch, case, default)
      if (controlFlow.test(t)) continue;

      // Skip else on its own
      if (t === "else") continue;

      // Skip labels: "case X:" or "default:"
      if (/^(case\s+.+|default)\s*:/.test(t)) continue;

      // Skip blank-after-strip lines
      if (!t) continue;

      // Now: this line looks like it should be a statement.
      // It must end with ; or have { or } nearby (multi-line constructs).
      // Heuristic: if it ends with ), a comma, or an identifier/number — check next
      // non-blank line to see if this is a multi-line expression.

      // Skip function signatures: "type name(params)" at top level-ish
      if (cTypes.test(t) && fnHeader.test(t) && !t.includes("=")) continue;

      // Check: does this line end with a semicolon?
      if (t.endsWith(";")) continue;

      // It could be a multi-line statement — peek ahead
      let isContinuation = false;
      // If line ends with an operator or comma, it continues on next line
      if (/[,+\-*\/&|^=<>!?:]$/.test(t) || t.endsWith("\\")) {
        isContinuation = true;
      }
      // If next non-empty line starts with an operator or is a continuation
      if (!isContinuation) {
        for (let j = i + 1; j < lines.length; j++) {
          const nextT = lines[j].trim();
          if (!nextT) continue;
          // Next line starts with operator → continuation
          if (/^[+\-*\/%&|^=<>!?.,)]/.test(nextT)) {
            isContinuation = true;
          }
          break;
        }
      }
      if (isContinuation) continue;

      // This looks like a statement that should end with ; but doesn't.
      // Final check: is it a real statement?
      // - Variable declarations: int x = 5
      // - Expression statements: printf(...), x = 10, func_call(...)
      // - Return: return ...
      const isVarDecl = cTypes.test(t);
      const isReturn = /^return\b/.test(t);
      const isExprStmt = /^\w+\s*\(/.test(t) || /^\w+\s*[+\-*\/&|^]?=/.test(t);
      const isBreakContinue = /^(break|continue)$/.test(t);

      if (isVarDecl || isReturn || isExprStmt || isBreakContinue) {
        const err = new Error(`Missing semicolon after statement on line ${i + 1}`);
        err.cLine = i + 1;
        throw err;
      }
    }
  }

  // ── printf formatter ──────────────────────────────────────────────────────
  function applyFormat(fmtStr, args) {
    let out = "", ai = 0, i = 0;
    while (i < fmtStr.length) {
      if (fmtStr[i] !== "%") { out += fmtStr[i++]; continue; }
      i++;
      if (fmtStr[i] === "%") { out += "%"; i++; continue; }
      let flags = "", width = "", prec = "";
      while (i < fmtStr.length && "-+ #0".includes(fmtStr[i])) flags += fmtStr[i++];
      while (i < fmtStr.length && "0123456789".includes(fmtStr[i])) width += fmtStr[i++];
      if (fmtStr[i] === ".") { i++; while ("0123456789".includes(fmtStr[i])) prec += fmtStr[i++]; }
      const spec = fmtStr[i++], val = args[ai++];
      switch (spec) {
        case "d": case "i": out += String(Math.trunc(Number(val ?? 0))); break;
        case "u": out += String(Math.trunc(Math.abs(Number(val ?? 0)))); break;
        case "f": out += Number(val ?? 0).toFixed(prec !== "" ? +prec : 6); break;
        case "e": out += Number(val ?? 0).toExponential(prec !== "" ? +prec : 6); break;
        case "g": out += parseFloat(Number(val ?? 0).toPrecision(prec !== "" ? +prec : 6)); break;
        case "s": out += String(val ?? ""); break;
        case "c": out += String.fromCharCode(Number(val ?? 0)); break;
        case "x": out += Math.trunc(Number(val ?? 0)).toString(16); break;
        case "X": out += Math.trunc(Number(val ?? 0)).toString(16).toUpperCase(); break;
        case "o": out += Math.trunc(Number(val ?? 0)).toString(8); break;
        case "p": out += "0x" + Math.trunc(Number(val ?? 0)).toString(16); break;
        default: out += `%${flags}${width}${prec ? "." + prec : ""}${spec}`; ai--; break;
      }
    }
    return out;
  }

  function unesc(s) {
    return String(s)
      .replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\r/g, "\r")
      .replace(/\\"/g, '"').replace(/\\\\/g, "\\").replace(/\\0/g, "\0");
  }

  // ── Character literal to ASCII ────────────────────────────────────────────
  // Converts C char literals like 'A', '\n', '\0', '\t' to their integer values
  function charLitToInt(body) {
    // Handle escape sequences: '\n', '\t', '\0', '\\', '\''
    body = body.replace(/'\\n'/g, "10");
    body = body.replace(/'\\t'/g, "9");
    body = body.replace(/'\\0'/g, "0");
    body = body.replace(/'\\\\'/g, "92");
    body = body.replace(/'\\r'/g, "13");
    body = body.replace(/'\\''/g, "39");
    // Handle normal single characters: 'A', 'a', '0', ' ', etc.
    body = body.replace(/'([^\\'])'/g, (_, ch) => String(ch.charCodeAt(0)));
    return body;
  }

  // ── Address-of operator in all expression contexts ────────────────────────
  // Converts &varname → {__ptr:true, get v(){return varname}, set v(__v){varname=__v}, __name:"varname"}
  // Must NOT match && (logical AND) or &= (bitwise AND assign)
  function convertAddressOf(body) {
    // Match &word but NOT && or &= and not inside strings
    body = body.replace(/(?<![&])&(?![&=])(\w+)/g, (match, name) => {
      // Don't convert if it looks like a bitwise operator in context
      // (e.g. a & b — would be preceded by a space and word char, but our lookbehind handles &&)
      return `({__ptr:true, get v(){return ${name}}, set v(__v){${name}=__v; if(typeof __rv !== "undefined") __rv("${name}", __v);}, __name:"${name}"})`;
    });
    return body;
  }

  // ── C-style cast removal ──────────────────────────────────────────────────
  // (int)x → (x)|0, (float)x → +(x), (char)x → (x)&255
  function removeCasts(body) {
    body = body.replace(/\(int\)\s*(\w+)/g, "(($1)|0)");
    body = body.replace(/\(float\)\s*(\w+)/g, "(+($1))");
    body = body.replace(/\(double\)\s*(\w+)/g, "(+($1))");
    body = body.replace(/\(char\)\s*(\w+)/g, "(($1)&255)");
    body = body.replace(/\(unsigned\)\s*(\w+)/g, "(($1)>>>0)");
    return body;
  }

  // ── Find matching closing brace ───────────────────────────────────────────
  function findMatchingBrace(src, start) {
    let depth = 1, pos = start;
    while (pos < src.length && depth > 0) {
      if (src[pos] === "{") depth++;
      else if (src[pos] === "}") depth--;
      pos++;
    }
    return pos;
  }

  // ── Extract all functions from source ─────────────────────────────────────
  function extractFunctions(src) {
    let cleaned = src.replace(/^\s*#[^\n]*/gm, "");
    cleaned = cleaned.replace(/\/\*[\s\S]*?\*\//g, m => m.replace(/[^\n]/g, ""));
    cleaned = cleaned.replace(/\/\/[^\n]*/g, "");

    const userFns = [];
    const cTypes = "(?:int|float|double|long|short|unsigned|char|void)";
    const fnRe = new RegExp(
      "\\b" + cTypes + "\\s+(\\w+)\\s*\\(([^)]*)\\)\\s*\\{", "g"
    );

    let match;
    const fnRegions = [];

    while ((match = fnRe.exec(cleaned)) !== null) {
      const name = match[1];
      const rawParams = match[2].trim();
      const openBrace = match.index + match[0].length;
      const closePos = findMatchingBrace(cleaned, openBrace);
      const body = cleaned.substring(openBrace, closePos - 1);
      const startLine = cleaned.substring(0, match.index).split("\n").length;

      const params = [];
      if (rawParams && rawParams !== "void") {
        for (const p of rawParams.split(",")) {
          const pt = p.trim();
          if (!pt) continue;
          const isPtr = pt.includes("*");
          const parts = pt.replace(/\*/g, " ").replace(/\s+/g, " ").trim().split(" ");
          const pName = parts[parts.length - 1];
          params.push({ name: pName, isPtr });
        }
      }

      fnRegions.push({ start: match.index, end: closePos, name, params, body, startLine });
    }

    let mainBody = null, mainStartLine = 0;
    for (const fn of fnRegions) {
      if (fn.name === "main") {
        mainBody = fn.body;
        mainStartLine = fn.startLine;
      } else {
        userFns.push(fn);
      }
    }

    if (mainBody === null) {
      throw new Error("No main() function found.");
    }

    return { userFns, mainBody, mainStartLine };
  }

  // ── Transpile a function body ─────────────────────────────────────────────
  function transpileFnBody(body, { isMain = true, traceMode = false } = {}) {

    // BUG 2 FIX: Convert character literals FIRST (before any other transforms)
    body = charLitToInt(body);

    // ── PROTECT STRING LITERALS from regex transforms ─────────────────────
    // Extract all "..." strings and replace with __STR_N__ placeholders.
    // This prevents regexes from matching C keywords inside strings
    // (e.g. printf("float compare") won't have 'float' matched as a type).
    const savedStrings = [];
    body = body.replace(/"(?:[^"\\]|\\.)*"/g, (match) => {
      const idx = savedStrings.length;
      savedStrings.push(match);
      return `__STR_${idx}__`;
    });

    // C-style casts
    body = removeCasts(body);

    if (traceMode) {
      const lines = body.split("\n");
      const annotated = lines.map((line) => {
        const t = line.trim();
        if (!t || t === "{" || t === "}" || t.endsWith("{") || t.endsWith("}")) return line;
        if (/;\s*$/.test(line)) {
          return line.replace(/;\s*$/, "; __TRK(__LINE__);");
        }
        return line;
      });
      body = annotated.join("\n");
    }

    // Loop guard
    body = body.replace(/\b(for|while)\b(\s*\([^)]*\)|\s*\([^{]*\))\s*\{/g,
      (_, kw, cond) => `${kw}${cond} { __guard();`);
    body = body.replace(/\bdo\s*\{/g, "do { __guard();");

    // ── Pointer declarations & arguments ───────────────────────────────
    // Handle pointer parameters in functions: turn them into proxies if passed by ref
    // For now, pointers in CRunner are specifically used with address-of &x and arrays.
    // The previous regex `\b(?:int|float|double|long|short|unsigned|char)\s*\*\s*(\w+)\s*=\s*&(\w+)\s*;`
    // missed function parameters.

    // Convert: int *p = &x;  →  let p = pointer proxy
    body = body.replace(
      /\b(?:int|float|double|long|short|unsigned|char)\s*\*\s*(\w+)\s*=\s*&(\w+)\s*;/g,
      (_, ptr, target) =>
        `let ${ptr} = ({__ptr:true, get v(){return ${target}}, set v(__v){${target}=__v}, __name:"${target}"});`
    );
    // int *p = NULL;
    body = body.replace(
      /\b(?:int|float|double|long|short|unsigned|char)\s*\*\s*(\w+)\s*=\s*NULL\s*;/g,
      (_, ptr) => `let ${ptr} = null;`
    );
    // int *p;  (uninitialized pointer)
    body = body.replace(
      /\b(?:int|float|double|long|short|unsigned|char)\s*\*\s*(\w+)\s*;/g,
      (_, ptr) => `let ${ptr} = null;`
    );
    // sizeof replacement MUST run before the malloc regex so that
    // malloc(sizeof(int)) → malloc(4) before the arg capture runs.
    body = body.replace(/\bsizeof\s*\(\s*\w+\s*\*?\s*\)/g, "4");

    // Heap: malloc / calloc / free — MUST run BEFORE *p=val regex
    // int *p = (int*)malloc(N)  →  let p = __malloc(N, "p")
    // The args pattern allows one level of nested parens to handle sizeof(type).
    body = body.replace(
      /\b(?:int|float|double|char|long|short|unsigned)\s*\*\s*(\w+)\s*=\s*(?:\([^)]*\)\s*)?(?:malloc|calloc)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)\s*;/g,
      (_, varName, args) => `let ${varName} = __malloc(${args}, "${varName}");`
    );
    // free(p)  →  __free(p)
    body = body.replace(/\bfree\s*\(/g, "__free(");

    // Dereference write: *p = val;  →  p.v = val;
    // Updated to support pointer parameter dereferencing safely
    body = body.replace(
      /(?<![a-zA-Z0-9_])\*(\w+)\s*=\s*([^;]+);/g,
      (_, ptr, val) => `${ptr}.v = ${val};`
    );

    // Array decl with init: int arr[N]={a,b};
    body = body.replace(
      /\b(?:int|float|double|long|short|unsigned|char)\s+(\w+)\s*\[\d*\]\s*=\s*\{([^}]*)\}\s*;/g,
      (_, id, vals) => `let ${id} = [${vals}];`
    );
    // Array decl no init
    body = body.replace(
      /\b(?:int|float|double|long|short|unsigned|char)\s+(\w+)\s*\[(\d+)\]\s*;/g,
      (_, id, sz) => `let ${id} = new Array(${sz}).fill(0);`
    );
    // Multi-declarator: parenthesis-depth-aware comma splitting
    body = body.replace(
      /\b(int|float|double|long|short|unsigned|char)\s+((?:[^;])+);/g,
      (match, type, rest) => {
        rest = rest.trim();
        if (/^\w+\s*\(/.test(rest) && !rest.includes("=")) return match;
        if (rest.includes("[")) return match;
        // Skip pointer declarations (e.g. "*p", "* p" at start of declarator list)
        // Do NOT skip normal arithmetic like `fahrenheit = celsius * 9.0 / 5.0 + 32.0`
        if (/^\s*\*/.test(rest)) return match;

        const parts = [];
        let depth = 0, cur = "";
        for (let ci = 0; ci < rest.length; ci++) {
          const ch = rest[ci];
          if (ch === "(" || ch === "[") depth++;
          else if (ch === ")" || ch === "]") depth--;
          else if (ch === "," && depth === 0) {
            parts.push(cur.trim());
            cur = "";
            continue;
          }
          cur += ch;
        }
        if (cur.trim()) parts.push(cur.trim());

        return parts.map(d => {
          if (!d) return "";
          const eq = d.indexOf("=");
          if (eq !== -1) {
            const name = d.substring(0, eq).trim();
            const val = d.substring(eq + 1).trim();
            return `let ${name} = (${val});`;
          }
          return `let ${d} = 0;`;
        }).join(" ");
      }
    );
    // for var decl
    body = body.replace(/\bfor\s*\(\s*(?:int|float|double|char|long)\s+/g, "for (let ");

    // stdlib
    body = body.replace(/\bprintf\s*\(/g, "__p(");
    body = body.replace(/\bputchar\s*\(([^)]+)\)/g, (_, a) => `__putchar(${a})`);
    body = body.replace(/\bputs\s*\(([^)]+)\)/g, (_, a) => `__puts(${a})`);
    body = body.replace(/\bscanf\s*\(/g, "__scanf(");
    // Convert &varName inside __scanf calls into a pointer proxy object
    body = body.replace(
      /__scanf\s*\(\s*("(?:[^"\\]|\\.)*")\s*,\s*&(\w+)\s*\)/g,
      (_, fmt, varName) =>
        `__scanf(${fmt}, {__ptr:true, __name:"${varName}", get v(){return ${varName}}, set v(_v){${varName}=_v}})`
    );
    body = body.replace(/\babs\s*\(/g, "Math.abs(");
    body = body.replace(/\bfabs\s*\(/g, "Math.abs(");
    body = body.replace(/\bsqrt\s*\(/g, "Math.sqrt(");
    body = body.replace(/\bpow\s*\(/g, "Math.pow(");
    body = body.replace(/\bfloor\s*\(/g, "Math.floor(");
    body = body.replace(/\bceil\s*\(/g, "Math.ceil(");
    body = body.replace(/\bround\s*\(/g, "Math.round(");
    body = body.replace(/\bfmod\s*\(/g, "(function(a,b){return a%b;})(");
    body = body.replace(/\bNULL\b/g, "null");
    body = body.replace(/\bINT_MAX\b/g, "2147483647");
    body = body.replace(/\bINT_MIN\b/g, "-2147483648");
    body = body.replace(/\bsizeof\s*\(\s*\w+\s*\)/g, "4");

    // BUG 3 FIX: Convert &varname to pointer proxy in ALL expression contexts
    // (function arguments, assignments, etc.) — AFTER stdlib transforms
    body = convertAddressOf(body);

    // Dereference *p in expressions (read): replace *varname with varname.v
    body = body.replace(/(?<![a-zA-Z0-9_\])])\*(\w+)/g, (match, name) => {
      if (name.startsWith("__")) return match;
      return `${name}.v`;
    });

    // return
    if (isMain) {
      body = body.replace(/\breturn\s+([^;{]+);/g, (_, val) => `__exit(${val});`);
      body = body.replace(/\breturn\s*;/g, "__exit(0);");
    }

    // ── RESTORE STRING LITERALS ──────────────────────────────────────────
    for (let si = 0; si < savedStrings.length; si++) {
      body = body.replace(new RegExp(`__STR_${si}__`, "g"), savedStrings[si]);
    }

    return body;
  }

  // ── Resolve __LINE__ markers ──────────────────────────────────────────────
  function resolveLineMarkers(body, startLine) {
    const lines = body.split("\n");
    return lines.map((l, i) => l.replace(/__LINE__/g, String(startLine + i))).join("\n");
  }

  // ── Post-process trace markers ─────────────────────────────────────────────
  function processMarkers(body) {
    body = body.replace(
      /let (\w+) = \(([^;]*)\);\s*__TRK\((\d+)\);/g,
      (_, id, val, n) =>
        `let ${id} = (${val}); __rv("${id}", ${id}); __trace(${n});`
    );
    body = body.replace(
      /let (\w+) = ([^;(][^;]*);\s*__TRK\((\d+)\);/g,
      (_, id, val, n) =>
        `let ${id} = ${val}; __rv("${id}", ${id}); __trace(${n});`
    );
    body = body.replace(
      /^(\s*)([a-zA-Z0-9_\.\[\]]+)\s*([+\-*\/&|^]?=)\s*([^;=\n]+);\s*__TRK\((\d+)\);/gm,
      (_, ws, id, op, val, n) =>
        `${ws}${id} ${op} ${val}; __rv("${id}", ${id}); __trace(${n});`
    );
    body = body.replace(
      /(__p\([^)]*(?:\([^)]*\)[^)]*)*\));\s*__TRK\((\d+)\);/g,
      (_, call, n) => `${call}; __trace(${n});`
    );
    body = body.replace(
      /__exit\(([^)]*)\);\s*__TRK\((\d+)\);/g,
      (_, val, n) => `__trace(${n}); __exit(${val});`
    );
    body = body.replace(
      /\breturn\s+([^;]+);\s*__TRK\((\d+)\);/g,
      (_, val, n) => `{ __trace(${n}); return ${val}; }`
    );
    body = body.replace(
      /\breturn;\s*__TRK\((\d+)\);/g,
      (_, n) => `{ __trace(${n}); return; }`
    );

    // Fix for single-line if/else bodies without braces:
    // When a single statement is wrapped with trace, it might break the syntax:
    // if (cond)
    //   stmt; __trace(...);
    // Becomes: if (cond) stmt; __trace(...);  -> The __trace executes regardless of cond, or syntax error because else loses its matching if.
    // We wrap all lines that have __trace() at the end and don't end in } with braces if they are inside an if/else without braces.
    // For simplicity, we can just replace any trailing __trace() with a comma expression or block if needed, but since we already split by line:
    body = body.replace(/__TRK\((\d+)\);/g, "__trace($1);");

    // Post-process to fix broken if/else single statements
    // E.g., if (x > 5) \n printf("..."); __trace(1); \n else \n ...
    // Let's use a regex to wrap any statement following an if/else/for/while without braces that ends in __trace(X);
    body = body.replace(/\b(if|else\s+if|for|while)\s*\(([^)]*)\)\s*([^{}\[\]\n]+__trace\(\d+\);)/g,
      (_, kw, cond, stmt) => `${kw} (${cond}) { ${stmt} }`);
    body = body.replace(/\b(else)\s*([^{}\[\]\n]+__trace\(\d+\);)/g,
      (_, kw, stmt) => `${kw} { ${stmt} }`);

    return body;
  }

  function execute(body, params, args) {
    const fn = new Function(...params, '"use strict";\n' + body);
    fn(...args);
  }

  // ── Build full transpiled source ──────────────────────────────────────────
  function buildFullSource(src, traceMode) {
    const { userFns, mainBody, mainStartLine } = extractFunctions(src);

    let fullJs = "";

    for (const fn of userFns) {
      const jsParams = fn.params.map(p => p.name).join(", ");
      let jsBody = transpileFnBody(fn.body, { isMain: false, traceMode });

      if (traceMode) {
        jsBody = resolveLineMarkers(jsBody, fn.startLine);
        jsBody = processMarkers(jsBody);
        fullJs += `function ${fn.name}(${jsParams}) {\n`;
        fullJs += `  __pushFrame("${fn.name}", ${fn.startLine});\n`;
        for (const p of fn.params) {
          fullJs += `  if(typeof __rv !== "undefined") __rv("${p.name}", ${p.name});\n`;
        }
        fullJs += `  try {\n`;
        fullJs += jsBody;
        fullJs += `\n  } finally { __popFrame(); }\n`;
        fullJs += `}\n`;
      } else {
        fullJs += `function ${fn.name}(${jsParams}) {\n`;
        fullJs += jsBody;
        fullJs += `\n}\n`;
      }
    }

    let mainJs = transpileFnBody(mainBody, { isMain: true, traceMode });
    if (traceMode) {
      mainJs = resolveLineMarkers(mainJs, mainStartLine);
      mainJs = processMarkers(mainJs);
    }
    fullJs += mainJs;

    return fullJs;
  }

  // ── scanf static detector ─────────────────────────────────────────────────
  // Scans the source for scanf calls and returns an ordered list of
  // {format, varName} for each call found. Used by Dart to prompt the user
  // for the right number of inputs before execution begins.
  function detectInputs(src) {
    const results = [];
    // Strip ONLY comments to avoid false matches — keep strings intact
    // so we can read the scanf format specifier like "%d"
    let cleaned = src.replace(/\/\*[\s\S]*?\*\//g, m => m.replace(/[^\n]/g, " "));
    cleaned = cleaned.replace(/\/\/[^\n]*/g, m => " ".repeat(m.length));
    // Match scanf("%...", &varName) or scanf("%s", varName)
    const re = /\bscanf\s*\(\s*"%([^"]*?)"\s*,\s*(?:&)?(\w+)\s*\)/g;
    let m;
    while ((m = re.exec(cleaned)) !== null) {
      results.push({ format: "%" + m[1], varName: m[2] });
    }
    return results;
  }

  // ══════════════════════════════════════════════════════════════════════════
  window.CRunner = {

    detectInputs: detectInputs,

    run: function (src, inputs) {
      const inputQueue = Array.isArray(inputs) ? inputs.slice() : [];
      const output = [];
      let exitCode = 0, ops = 0;
      const t0 = Date.now();
      const heapBlocks = [];
      let heapNextAddr = 0x1000;

      function __p(fmt) { output.push(applyFormat(unesc(fmt), Array.from(arguments).slice(1))); }
      function __putchar(c) { output.push(String.fromCharCode(c)); }
      function __puts(s) { output.push(String(s) + "\n"); }
      function __exit(code) { exitCode = code | 0; throw "__RETURN__"; }
      function __guard() { if (++ops > MAX_OPS) throw new Error("Timeout: infinite loop?"); }
      function __scanf(fmt, ptr) {
        const raw = inputQueue.length > 0 ? inputQueue.shift() : "0";
        // Echo the typed value to stdout (real terminal behaviour)
        output.push(raw + "\n");
        const spec = (fmt.match(/%([diouxXfeEgGcs])/) || [])[1] || "s";
        let parsed;
        if (spec === "f" || spec === "e" || spec === "E" || spec === "g" || spec === "G") {
          parsed = parseFloat(raw);
          if (isNaN(parsed)) parsed = 0.0;
        } else if (spec === "c") {
          parsed = raw.length > 0 ? raw.charCodeAt(0) : 0;
        } else if (spec === "s") {
          parsed = String(raw).split(/\s/)[0]; // first token
        } else {
          parsed = parseInt(raw, 10);
          if (isNaN(parsed)) parsed = 0;
        }
        if (ptr && typeof ptr === "object" && ptr.__ptr) {
          ptr.v = parsed;
        } else if (Array.isArray(ptr)) {
          // %s into char array: fill cells with char codes
          const s = String(parsed);
          for (let i = 0; i < ptr.length && i < s.length; i++) ptr[i] = s.charCodeAt(i);
          if (ptr.length > s.length) ptr[s.length] = 0;
        }
      }
      function __malloc(sizeArg, label) {
        const size = +String(sizeArg).split(",")[0] | 0 || 4;
        const addr = heapNextAddr;
        const cellCount = Math.ceil(size / 4);
        heapNextAddr += cellCount * 4 + 8;
        const block = { addr, size: cellCount, label: label || "?", free: false, cells: new Array(cellCount).fill(0) };
        heapBlocks.push(block);
        return new Proxy(block.cells, {
          get(t, k) {
            if (k === '__heap') return true;
            if (k === '__addr') return addr;
            if (k === '__block') return block;
            if (k === 'v') return block.cells[0];
            return t[k];
          },
          set(t, k, v) {
            if (k === 'v') { block.cells[0] = +v; return true; }
            const i = +k;
            if (!isNaN(i)) { block.cells[i] = +v; t[i] = +v; return true; }
            t[k] = v; return true;
          }
        });
      }
      function __free(ptr) { if (ptr && ptr.__block) ptr.__block.free = true; }

      try {
        validateSemicolons(src);
        const body = buildFullSource(src, false);
        execute(
          body,
          ["__p", "__putchar", "__puts", "__exit", "__guard", "__malloc", "__free", "__scanf"],
          [__p, __putchar, __puts, __exit, __guard, __malloc, __free, __scanf]
        );
      } catch (e) {
        if (e !== "__RETURN__") {
          const errInfo = formatError(e, src);
          return { stdout: output.join(""), stderr: errInfo.formattedText, exitCode: 1, elapsed: Date.now() - t0, success: false, errorInfo: errInfo };
        }
      }
      return { stdout: output.join(""), stderr: "", exitCode, elapsed: Date.now() - t0, success: true };
    },

    trace: function (src, inputs) {
      const inputQueue = Array.isArray(inputs) ? inputs.slice() : [];
      const steps = [];
      const output = [];
      const rvState = {};
      const callStack = [{ fn: "main", line: 0 }];
      let exitCode = 0, ops = 0;
      const t0 = Date.now();
      const heapBlocks = [];
      let heapNextAddr = 0x1000;

      function __p(fmt) {
        output.push(applyFormat(unesc(fmt), Array.from(arguments).slice(1)));
      }
      function __putchar(c) { output.push(String.fromCharCode(c)); }
      function __puts(s) { output.push(String(s) + "\n"); }
      function __exit(code) { exitCode = code | 0; throw "__RETURN__"; }
      function __guard() {
        if (++ops > MAX_OPS) throw new Error("Timeout: infinite loop?");
      }
      function __malloc(sizeArg, label) {
        const size = +String(sizeArg).split(",")[0] | 0 || 4;
        const addr = heapNextAddr;
        const cellCount = Math.ceil(size / 4);
        heapNextAddr += cellCount * 4 + 8;
        const block = { addr, size: cellCount, label: label || "?", free: false, cells: new Array(cellCount).fill(0) };
        heapBlocks.push(block);
        return new Proxy(block.cells, {
          get(t, k) {
            if (k === '__heap') return true;
            if (k === '__addr') return addr;
            if (k === '__block') return block;
            if (k === 'v') return block.cells[0];
            return t[k];
          },
          set(t, k, v) {
            if (k === 'v') { block.cells[0] = +v; return true; }
            const i = +k;
            if (!isNaN(i)) { block.cells[i] = +v; t[i] = +v; return true; }
            t[k] = v; return true;
          }
        });
      }
      function __free(ptr) { if (ptr && ptr.__block) ptr.__block.free = true; }
      function __rv(name, value) {
        if (value && typeof value === "object" && value.__ptr) {
          rvState[name] = "&" + (value.__name || "?");
        } else if (Array.isArray(value)) {
          rvState[name] = "[" + value.join(", ") + "]";
        } else if (typeof value === "number") {
          rvState[name] = Number.isInteger(value) ? String(value) : value.toFixed(4).replace(/0+$/, "").replace(/\.$/, "");
        } else {
          rvState[name] = String(value ?? "null");
        }
      }
      function __pushFrame(fnName, line) {
        callStack.push({ fn: fnName, line: line });
      }
      function __popFrame() {
        if (callStack.length > 1) callStack.pop();
      }
      function __trace(lineNum) {
        if (callStack.length > 0) {
          callStack[callStack.length - 1].line = lineNum;
        }
        // Snapshot heap state at this step
        const heapSnap = heapBlocks.map(b => ({
          addr: b.addr,
          size: b.size,
          label: b.label,
          free: b.free,
          cells: b.cells.slice(),
        }));
        steps.push({
          line: lineNum,
          vars: Object.assign({}, rvState),
          output: output.join(""),
          callStack: callStack.map(f => ({ fn: f.fn, line: f.line })),
          heap: heapSnap,
        });
      }
      function __scanf(fmt, ptr) {
        const raw = inputQueue.length > 0 ? inputQueue.shift() : "0";
        // Echo the typed value to stdout (real terminal behaviour)
        output.push(raw + "\n");
        const spec = (fmt.match(/%([diouxXfeEgGcs])/) || [])[1] || "s";
        let parsed;
        if (spec === "f" || spec === "e" || spec === "E" || spec === "g" || spec === "G") {
          parsed = parseFloat(raw);
          if (isNaN(parsed)) parsed = 0.0;
        } else if (spec === "c") {
          parsed = raw.length > 0 ? raw.charCodeAt(0) : 0;
        } else if (spec === "s") {
          parsed = String(raw).split(/\s/)[0]; // first token
        } else {
          parsed = parseInt(raw, 10);
          if (isNaN(parsed)) parsed = 0;
        }
        if (ptr && typeof ptr === "object" && ptr.__ptr) {
          ptr.v = parsed;
          // Update rvState immediately so the trace step shows the variable
          if (ptr.__name) rvState[ptr.__name] = String(parsed);
        } else if (Array.isArray(ptr)) {
          const s = String(parsed);
          for (let i = 0; i < ptr.length && i < s.length; i++) ptr[i] = s.charCodeAt(i);
          if (ptr.length > s.length) ptr[s.length] = 0;
        }
      }

      try {
        validateSemicolons(src);
        const body = buildFullSource(src, true);
        execute(
          body,
          ["__p", "__putchar", "__puts", "__exit", "__guard", "__malloc", "__free", "__rv", "__trace", "__pushFrame", "__popFrame", "__scanf"],
          [__p, __putchar, __puts, __exit, __guard, __malloc, __free, __rv, __trace, __pushFrame, __popFrame, __scanf]
        );
      } catch (e) {
        if (e !== "__RETURN__") {
          const errInfo = formatError(e, src);
          return {
            steps, stdout: output.join(""), stderr: errInfo.formattedText,
            exitCode: 1, elapsed: Date.now() - t0, success: false, errorInfo: errInfo,
          };
        }
      }

      if (steps.length > 0 || output.length > 0) {
        steps.push({
          line: -1,
          vars: Object.assign({}, rvState),
          output: output.join(""),
          callStack: [{ fn: "main", line: -1 }],
        });
      }

      return {
        steps,
        stdout: output.join(""),
        stderr: "",
        exitCode,
        elapsed: Date.now() - t0,
        success: true,
      };
    },
  };
})();

/// Lesson content with theory (markdown) and starter C code.
class LessonContent {
  const LessonContent({
    required this.lessonId,
    required this.theory,
    required this.starterCode,
    this.expectedOutput,
  });

  final String lessonId;

  /// Markdown-formatted theory text.
  final String theory;

  /// Prefilled C code for the embedded editor.
  final String starterCode;

  /// Optional expected output for auto-validation.
  final String? expectedOutput;
}

/// Lesson content for all modules. Keyed by lessonId.
final Map<String, LessonContent> kLessonContents = {
  // ── Hello World ──────────────────────────────────────────────────────────
  'hw_01': const LessonContent(
    lessonId: 'hw_01',
    theory: '''# What is C?

C is a **general-purpose programming language** created by Dennis Ritchie in 1972 at Bell Labs. It is one of the most widely used languages ever created.

## Why Learn C?

- **Foundation**: C is the basis for C++, Java, Python, and many more
- **Performance**: C gives you direct control over hardware and memory
- **Systems Programming**: Operating systems, embedded devices, and databases are written in C
- **Understanding**: Learning C helps you understand how computers actually work

## Key Characteristics

| Feature | Description |
|---------|-------------|
| Compiled | Code is translated to machine code before running |
| Statically typed | Variable types must be declared |
| Low-level access | Direct memory manipulation via pointers |
| Portable | Runs on virtually any platform |

> Every C program starts with a `main()` function — that's where execution begins.
''',
    starterCode: '''#include <stdio.h>

int main() {
    // This is your first C program!
    printf("Hello, World!\\n");
    return 0;
}
''',
    expectedOutput: 'Hello, World!\n',
  ),

  'hw_02': const LessonContent(
    lessonId: 'hw_02',
    theory: '''# Your First Program

Every C program has the same basic structure:

```c
#include <stdio.h>

int main() {
    // your code here
    return 0;
}
```

## Breaking it down

- `#include <stdio.h>` — includes the Standard I/O library (for `printf`)
- `int main()` — the entry point of every C program
- `return 0;` — tells the OS the program finished successfully
- `{ }` — curly braces define a **block** of code

## Try it!

Modify the program below to print your name instead of "World".
''',
    starterCode: '''#include <stdio.h>

int main() {
    printf("Hello, World!\\n");
    printf("Welcome to C programming!\\n");
    return 0;
}
''',
  ),

  'hw_03': const LessonContent(
    lessonId: 'hw_03',
    theory: '''# printf and Formatting

`printf` is the most common way to display output in C. It supports **format specifiers** to print different types of data.

## Format Specifiers

| Specifier | Type | Example |
|-----------|------|---------|
| `%d` | Integer | `printf("%d", 42)` → `42` |
| `%f` | Float | `printf("%f", 3.14)` → `3.140000` |
| `%c` | Character | `printf("%c", 'A')` → `A` |
| `%s` | String | `printf("%s", "hi")` → `hi` |
| `%%` | Literal % | `printf("%%")` → `%` |

## Escape Sequences

- `\\n` — new line
- `\\t` — tab
- `\\\\` — backslash

## Try it!

Run the program and observe how different format specifiers work.
''',
    starterCode: '''#include <stdio.h>

int main() {
    int age = 20;
    float gpa = 3.85;
    
    printf("Age: %d\\n", age);
    printf("GPA: %.2f\\n", gpa);
    printf("Grade: %c\\n", 'A');
    printf("Score: %d%%\\n", 95);
    return 0;
}
''',
  ),

  'hw_04': const LessonContent(
    lessonId: 'hw_04',
    theory: '''# Comments and Style

Comments help explain your code. C supports two types:

## Single-line Comments
```c
// This is a single-line comment
int x = 5; // inline comment
```

## Multi-line Comments
```c
/* This comment
   spans multiple
   lines */
```

## Style Guidelines

1. **Indent with 4 spaces** (or 1 tab)
2. **Use meaningful variable names**: `studentCount` not `sc`
3. **Add comments for complex logic**
4. **Keep lines under 80 characters**
5. **Use blank lines to separate logical blocks**
''',
    starterCode: '''#include <stdio.h>

/* Program: Temperature Converter
   Converts Celsius to Fahrenheit */

int main() {
    // Input temperature in Celsius
    float celsius = 100.0;
    
    // Formula: F = C * 9/5 + 32
    float fahrenheit = celsius * 9.0 / 5.0 + 32.0;
    
    // Display result
    printf("%.1f C = %.1f F\\n", celsius, fahrenheit);
    return 0;
}
''',
  ),

  // ── Variables & Types ────────────────────────────────────────────────────
  'var_01': const LessonContent(
    lessonId: 'var_01',
    theory: '''# Declaring Variables

A **variable** is a named storage location in memory. In C, you must declare a variable's type before using it.

## Syntax
```c
type name = value;
```

## Rules for Variable Names
- Must start with a letter or underscore
- Can contain letters, digits, and underscores
- Case-sensitive (`age` ≠ `Age`)
- Cannot use C keywords (`int`, `return`, etc.)

## Examples
```c
int count = 0;      // integer
float price = 9.99; // floating point
char grade = 'A';   // single character
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int age = 25;
    float height = 5.9;
    char initial = 'J';
    
    printf("Age: %d\\n", age);
    printf("Height: %.1f\\n", height);
    printf("Initial: %c\\n", initial);
    return 0;
}
''',
  ),

  'var_02': const LessonContent(
    lessonId: 'var_02',
    theory: '''# Integer Types

C provides several integer types with different sizes and ranges.

## Common Integer Types

| Type | Size (typical) | Range |
|------|---------------|-------|
| `char` | 1 byte | -128 to 127 |
| `short` | 2 bytes | -32,768 to 32,767 |
| `int` | 4 bytes | ±2 billion |
| `long` | 4-8 bytes | platform-dependent |

## Unsigned Variants
Adding `unsigned` doubles the positive range:
```c
unsigned int x = 4000000000; // 0 to ~4 billion
```

## Try it!
Observe how different integer types behave.
''',
    starterCode: '''#include <stdio.h>

int main() {
    int a = 2147483647;
    int b = a + 1;
    
    printf("Max int: %d\\n", a);
    printf("Overflow: %d\\n", b);
    
    short s = 32767;
    printf("Max short: %d\\n", s);
    return 0;
}
''',
  ),

  'var_03': const LessonContent(
    lessonId: 'var_03',
    theory: '''# Floating-Point Numbers

For decimal numbers, C offers `float` and `double`.

| Type | Size | Precision |
|------|------|-----------|
| `float` | 4 bytes | ~7 digits |
| `double` | 8 bytes | ~15 digits |

## Key Points
- Use `%f` to print floats
- Use `%.Nf` to control decimal places
- Floating-point math can have tiny rounding errors
''',
    starterCode: '''#include <stdio.h>

int main() {
    float pi_f = 3.14159265358979;
    double pi_d = 3.14159265358979;
    
    printf("float:  %.15f\\n", pi_f);
    printf("double: %.15f\\n", pi_d);
    
    // Rounding issue
    float sum = 0.1 + 0.2;
    printf("0.1 + 0.2 = %.20f\\n", sum);
    return 0;
}
''',
  ),

  'var_04': const LessonContent(
    lessonId: 'var_04',
    theory: '''# Characters and ASCII

In C, `char` stores a single character as its ASCII number.

## ASCII Table (common values)
| Char | ASCII | Char | ASCII |
|------|-------|------|-------|
| `'0'` | 48 | `'A'` | 65 |
| `'9'` | 57 | `'Z'` | 90 |
| `' '` | 32 | `'a'` | 97 |

## Key Insight
Since chars are just numbers, you can do math with them!
```c
char c = 'A';
printf("%d", c);    // prints 65
printf("%c", c+1);  // prints 'B'
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    char letter = 'A';
    printf("Char: %c\\n", letter);
    printf("ASCII: %d\\n", letter);
    printf("Next: %c\\n", letter + 1);
    
    // Print A to Z
    int i = 0;
    while (i < 26) {
        printf("%c ", 'A' + i);
        i = i + 1;
    }
    printf("\\n");
    return 0;
}
''',
  ),

  'var_05': const LessonContent(
    lessonId: 'var_05',
    theory: '''# Type Casting

Type casting converts a value from one type to another.

## Implicit Casting (automatic)
```c
int a = 5;
float b = a; // int → float (safe)
```

## Explicit Casting
```c
float x = 3.7;
int y = (int)x; // truncates to 3
```

## Division Pitfall
```c
int a = 5, b = 2;
printf("%d", a/b);       // 2 (integer division!)
printf("%f", (float)a/b); // 2.500000
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int a = 7, b = 2;
    
    printf("Int division: %d\\n", a / b);
    printf("Float division: %.2f\\n", (float)a / b);
    
    float pi = 3.14159;
    int truncated = (int)pi;
    printf("Truncated: %d\\n", truncated);
    return 0;
}
''',
  ),

  // ── Operators ────────────────────────────────────────────────────────────
  'op_01': const LessonContent(
    lessonId: 'op_01',
    theory: '''# Arithmetic Operators

| Operator | Name | Example |
|----------|------|---------|
| `+` | Addition | `5 + 3` → `8` |
| `-` | Subtraction | `5 - 3` → `2` |
| `*` | Multiplication | `5 * 3` → `15` |
| `/` | Division | `5 / 3` → `1` |
| `%` | Modulo | `5 % 3` → `2` |

> **Note**: Integer division truncates! `7/2` = `3`, not `3.5`

## Operator Precedence
`*`, `/`, `%` are evaluated before `+`, `-`
Use parentheses to control order: `(2 + 3) * 4` = `20`
''',
    starterCode: '''#include <stdio.h>

int main() {
    int a = 17, b = 5;
    printf("a + b = %d\\n", a + b);
    printf("a - b = %d\\n", a - b);
    printf("a * b = %d\\n", a * b);
    printf("a / b = %d\\n", a / b);
    printf("a %% b = %d\\n", a % b);
    return 0;
}
''',
  ),

  'op_02': const LessonContent(
    lessonId: 'op_02',
    theory: '''# Relational Operators

Relational operators compare values and return `1` (true) or `0` (false).

| Operator | Meaning |
|----------|---------|
| `==` | Equal to |
| `!=` | Not equal to |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

> ⚠️ Common mistake: using `=` (assignment) instead of `==` (comparison)
''',
    starterCode: '''#include <stdio.h>

int main() {
    int x = 10, y = 20;
    printf("x == y: %d\\n", x == y);
    printf("x != y: %d\\n", x != y);
    printf("x < y:  %d\\n", x < y);
    printf("x > y:  %d\\n", x > y);
    return 0;
}
''',
  ),

  'op_03': const LessonContent(
    lessonId: 'op_03',
    theory: '''# Logical Operators

| Operator | Name | Usage |
|----------|------|-------|
| `&&` | AND | Both must be true |
| `||` | OR | At least one must be true |
| `!` | NOT | Inverts the value |

## Truth Table
| A | B | `A && B` | `A || B` |
|---|---|--------|---------|
| 1 | 1 | 1 | 1 |
| 1 | 0 | 0 | 1 |
| 0 | 1 | 0 | 1 |
| 0 | 0 | 0 | 0 |
''',
    starterCode: '''#include <stdio.h>

int main() {
    int age = 20;
    int hasID = 1;
    
    if (age >= 18 && hasID) {
        printf("Access granted\\n");
    }
    
    int isWeekend = 0;
    int isHoliday = 1;
    if (isWeekend || isHoliday) {
        printf("Day off!\\n");
    }
    return 0;
}
''',
  ),

  'op_04': const LessonContent(
    lessonId: 'op_04',
    theory: '''# Bitwise Operators

Bitwise operators work on individual bits of integers.

| Operator | Name | Example (5=101, 3=011) |
|----------|------|------------------------|
| `&` | AND | `5 & 3` → `1` (001) |
| `|` | OR | `5 | 3` → `7` (111) |
| `^` | XOR | `5 ^ 3` → `6` (110) |
| `~` | NOT | `~5` → inverts all bits |
| `<<` | Left shift | `5 << 1` → `10` |
| `>>` | Right shift | `5 >> 1` → `2` |

## Common Uses
- **Flags**: Use individual bits as on/off switches
- **Fast multiply/divide by 2**: `x << 1`, `x >> 1`
''',
    starterCode: '''#include <stdio.h>

int main() {
    int a = 5;
    int b = 3;
    printf("a & b = %d\\n", a & b);
    printf("a | b = %d\\n", a | b);
    printf("a ^ b = %d\\n", a ^ b);
    printf("a << 1 = %d\\n", a << 1);
    printf("a >> 1 = %d\\n", a >> 1);
    return 0;
}
''',
  ),

  // ── Control Flow ─────────────────────────────────────────────────────────
  'cf_01': const LessonContent(
    lessonId: 'cf_01',
    theory: '''# if and else

The `if` statement executes code conditionally.

```c
if (condition) {
    // runs if condition is true
} else if (another_condition) {
    // runs if first was false, this is true
} else {
    // runs if all above were false
}
```

## Key Rules
- Condition must be in parentheses
- Braces `{}` are optional for single statements (but always recommended)
- `0` is false, any non-zero is true
''',
    starterCode: '''#include <stdio.h>

int main() {
    int score = 85;
    
    if (score >= 90) {
        printf("Grade: A\\n");
    } else if (score >= 80) {
        printf("Grade: B\\n");
    } else if (score >= 70) {
        printf("Grade: C\\n");
    } else {
        printf("Grade: F\\n");
    }
    return 0;
}
''',
  ),

  'cf_02': const LessonContent(
    lessonId: 'cf_02',
    theory: '''# switch Statement

`switch` is cleaner than multiple `if-else` when comparing one variable to many values.

```c
switch (expression) {
    case value1:
        // code
        break;
    case value2:
        // code
        break;
    default:
        // if no case matches
}
```

> ⚠️ Don't forget `break;` — without it, execution "falls through" to the next case!
''',
    starterCode: '''#include <stdio.h>

int main() {
    int day = 3;
    
    printf("Day %d is ", day);
    if (day == 1) printf("Monday\\n");
    else if (day == 2) printf("Tuesday\\n");
    else if (day == 3) printf("Wednesday\\n");
    else if (day == 4) printf("Thursday\\n");
    else if (day == 5) printf("Friday\\n");
    else printf("Weekend\\n");
    return 0;
}
''',
  ),

  'cf_03': const LessonContent(
    lessonId: 'cf_03',
    theory: '''# for Loops

A `for` loop repeats code a specific number of times.

```c
for (init; condition; update) {
    // body
}
```

## Execution Flow
1. **init** runs once before the loop
2. **condition** is checked before each iteration
3. **body** executes if condition is true
4. **update** runs after each iteration
5. Go back to step 2
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Print 1 to 10
    int i;
    for (i = 1; i <= 10; i = i + 1) {
        printf("%d ", i);
    }
    printf("\\n");
    
    // Sum of 1 to 100
    int sum = 0;
    for (i = 1; i <= 100; i = i + 1) {
        sum = sum + i;
    }
    printf("Sum 1..100 = %d\\n", sum);
    return 0;
}
''',
  ),

  'cf_04': const LessonContent(
    lessonId: 'cf_04',
    theory: '''# while and do-while

## while Loop
Checks condition **before** each iteration:
```c
while (condition) {
    // body
}
```

## do-while Loop
Checks condition **after** each iteration (runs at least once):
```c
do {
    // body
} while (condition);
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Countdown with while
    int n = 5;
    while (n > 0) {
        printf("%d ", n);
        n = n - 1;
    }
    printf("Go!\\n");
    return 0;
}
''',
  ),

  'cf_05': const LessonContent(
    lessonId: 'cf_05',
    theory: '''# break and continue

- `break` — exits the loop immediately
- `continue` — skips the rest of the current iteration

## Example
```c
for (int i = 0; i < 10; i++) {
    if (i == 5) break;    // stops at 5
    if (i % 2 == 0) continue; // skip even
    printf("%d ", i);     // prints: 1 3
}
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Find first multiple of 7 above 50
    int i = 50;
    while (i < 100) {
        i = i + 1;
        if (i % 7 == 0) {
            printf("Found: %d\\n", i);
            break;
        }
    }
    return 0;
}
''',
  ),

  // ── Functions ────────────────────────────────────────────────────────────
  'fn_01': const LessonContent(
    lessonId: 'fn_01',
    theory: '''# Function Basics

A function is a reusable block of code. Every C program has at least `main()`.

```c
return_type name(parameters) {
    // body
    return value;
}
```

## Why Functions?
- **Reuse** code without copy-pasting
- **Organize** your program into logical units
- **Test** individual pieces independently
''',
    starterCode: '''#include <stdio.h>

int square(int n) {
    return n * n;
}

int add(int a, int b) {
    return a + b;
}

int main() {
    printf("3^2 = %d\\n", square(3));
    printf("5^2 = %d\\n", square(5));
    printf("3+4 = %d\\n", add(3, 4));
    return 0;
}
''',
  ),

  'fn_02': const LessonContent(
    lessonId: 'fn_02',
    theory: '''# Parameters and Return Values

## Parameters
Functions receive input through parameters:
```c
int max(int a, int b) {
    if (a > b) return a;
    return b;
}
```

## void Functions
Functions that don't return a value use `void`:
```c
void greet(int n) {
    printf("Hello #%d\\n", n);
}
```
''',
    starterCode: '''#include <stdio.h>

int max(int a, int b) {
    if (a > b) return a;
    return b;
}

void printStars(int n) {
    int i;
    for (i = 0; i < n; i = i + 1) {
        printf("*");
    }
    printf("\\n");
}

int main() {
    printf("Max(3,7) = %d\\n", max(3, 7));
    printStars(5);
    printStars(10);
    return 0;
}
''',
  ),

  'fn_03': const LessonContent(
    lessonId: 'fn_03',
    theory: '''# Function Prototypes

In C, a function must be **declared** before it's called. You can either:

1. Define the function above `main()`
2. Use a **prototype** (forward declaration)

```c
// Prototype
int add(int a, int b);

int main() {
    printf("%d", add(2, 3)); // OK
}

// Full definition
int add(int a, int b) {
    return a + b;
}
```
''',
    starterCode: '''#include <stdio.h>

// Prototypes
int factorial(int n);
int abs_val(int x);

int main() {
    printf("5! = %d\\n", factorial(5));
    printf("|−7| = %d\\n", abs_val(-7));
    return 0;
}

int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

int abs_val(int x) {
    if (x < 0) return -x;
    return x;
}
''',
  ),

  'fn_04': const LessonContent(
    lessonId: 'fn_04',
    theory: '''# Recursion

A function that calls itself is **recursive**. Every recursive function needs:

1. **Base case** — when to stop
2. **Recursive case** — the function calls itself with a smaller problem

```c
int factorial(int n) {
    if (n <= 1) return 1;       // base case
    return n * factorial(n - 1); // recursive
}
```

## Visualize the Call Stack
```
factorial(4)
  → 4 * factorial(3)
    → 3 * factorial(2)
      → 2 * factorial(1)
        → returns 1
      → returns 2
    → returns 6
  → returns 24
```
''',
    starterCode: '''#include <stdio.h>

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main() {
    int i;
    printf("Fibonacci: ");
    for (i = 0; i < 10; i = i + 1) {
        printf("%d ", fibonacci(i));
    }
    printf("\\n");
    return 0;
}
''',
  ),

  // ── Arrays ───────────────────────────────────────────────────────────────
  'arr_01': const LessonContent(
    lessonId: 'arr_01',
    theory: '''# 1D Arrays

An array stores multiple values of the same type in contiguous memory.

```c
int nums[5] = {10, 20, 30, 40, 50};
```

## Accessing Elements
- Index starts at **0**
- `nums[0]` is the first element
- `nums[4]` is the last element of a 5-element array

> ⚠️ Accessing out-of-bounds is **undefined behavior**!
''',
    starterCode: '''#include <stdio.h>

int main() {
    int nums[5];
    nums[0] = 10;
    nums[1] = 20;
    nums[2] = 30;
    nums[3] = 40;
    nums[4] = 50;
    
    int sum = 0;
    int i;
    for (i = 0; i < 5; i = i + 1) {
        sum = sum + nums[i];
    }
    printf("Sum: %d\\n", sum);
    printf("Avg: %d\\n", sum / 5);
    return 0;
}
''',
  ),

  'arr_02': const LessonContent(
    lessonId: 'arr_02',
    theory: '''# Array Operations

Common operations on arrays:

## Finding Min/Max
```c
int max = arr[0];
for (int i = 1; i < n; i++)
    if (arr[i] > max) max = arr[i];
```

## Reversing
```c
for (int i = 0; i < n/2; i++) {
    int temp = arr[i];
    arr[i] = arr[n-1-i];
    arr[n-1-i] = temp;
}
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[5];
    arr[0] = 3; arr[1] = 1; arr[2] = 4;
    arr[3] = 1; arr[4] = 5;
    int n = 5;
    int i;
    
    // Find max
    int max = arr[0];
    for (i = 1; i < n; i = i + 1) {
        if (arr[i] > max) max = arr[i];
    }
    printf("Max: %d\\n", max);
    return 0;
}
''',
  ),

  'arr_03': const LessonContent(
    lessonId: 'arr_03',
    theory: '''# 2D Arrays

A 2D array is like a table with rows and columns.

```c
int matrix[3][3] = {
    {1, 2, 3},
    {4, 5, 6},
    {7, 8, 9}
};
```

Access with `matrix[row][col]`.
''',
    starterCode: '''#include <stdio.h>

int main() {
    int m[2][3];
    m[0][0] = 1; m[0][1] = 2; m[0][2] = 3;
    m[1][0] = 4; m[1][1] = 5; m[1][2] = 6;
    
    int r, c;
    for (r = 0; r < 2; r = r + 1) {
        for (c = 0; c < 3; c = c + 1) {
            printf("%d ", m[r][c]);
        }
        printf("\\n");
    }
    return 0;
}
''',
  ),

  'arr_04': const LessonContent(
    lessonId: 'arr_04',
    theory: '''# Strings with char[]

In C, strings are **arrays of characters** terminated by `'\\0'` (null character).

```c
char name[] = "Alice";
// same as: {'A','l','i','c','e','\\0'}
```

## String Functions (from `<string.h>`)
- `strlen(s)` — length
- `strcpy(dest, src)` — copy
- `strcmp(a, b)` — compare (0 if equal)
''',
    starterCode: '''#include <stdio.h>

int main() {
    char greeting[20];
    greeting[0] = 'H';
    greeting[1] = 'i';
    greeting[2] = '!';
    greeting[3] = 0;
    
    printf("%s\\n", greeting);
    
    // Manual strlen
    int len = 0;
    while (greeting[len] != 0) {
        len = len + 1;
    }
    printf("Length: %d\\n", len);
    return 0;
}
''',
  ),

  // ── Pointers ─────────────────────────────────────────────────────────────
  'ptr_01': const LessonContent(
    lessonId: 'ptr_01',
    theory: '''# What are Pointers?

A **pointer** stores the memory address of another variable.

```
int x = 42;     // x is stored at address 0x1000
int *p = &x;    // p stores 0x1000
```

## Why Pointers?
- Pass large data efficiently (by reference)
- Dynamic memory allocation
- Build complex data structures (linked lists, trees)
- Direct hardware access
''',
    starterCode: '''#include <stdio.h>

int main() {
    int x = 42;
    int *p = &x;
    
    printf("x = %d\\n", x);
    printf("&x = %d\\n", (int)&x);
    printf("p = %d\\n", (int)p);
    printf("*p = %d\\n", *p);
    return 0;
}
''',
  ),

  'ptr_02': const LessonContent(
    lessonId: 'ptr_02',
    theory: '''# & and * Operators

## Address-of: `&`
Gets the memory address of a variable.

## Dereference: `*`
Gets the value at the address stored in a pointer.

```c
int x = 10;
int *p = &x;   // p = address of x
*p = 20;       // changes x to 20!
```
''',
    starterCode: '''#include <stdio.h>

void doubleIt(int *p) {
    *p = *p * 2;
}

int main() {
    int x = 5;
    printf("Before: %d\\n", x);
    doubleIt(&x);
    printf("After: %d\\n", x);
    return 0;
}
''',
  ),

  'ptr_03': const LessonContent(
    lessonId: 'ptr_03',
    theory: '''# Pointer Arithmetic

You can add/subtract integers to/from pointers. The pointer moves by `n * sizeof(type)` bytes.

```c
int arr[3] = {10, 20, 30};
int *p = arr;    // points to arr[0]
p++;             // now points to arr[1]
printf("%d", *p); // prints 20
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[4];
    arr[0] = 10; arr[1] = 20;
    arr[2] = 30; arr[3] = 40;
    
    int *p = arr;
    int i;
    for (i = 0; i < 4; i = i + 1) {
        printf("arr[%d] = %d\\n", i, *(p + i));
    }
    return 0;
}
''',
  ),

  'ptr_04': const LessonContent(
    lessonId: 'ptr_04',
    theory: '''# Pointers and Arrays

In C, an array name decays to a pointer to its first element:
```c
int arr[3] = {1, 2, 3};
int *p = arr;  // same as &arr[0]
```

This means `arr[i]` is equivalent to `*(arr + i)`.
''',
    starterCode: '''#include <stdio.h>

void printArray(int *arr, int n) {
    int i;
    for (i = 0; i < n; i = i + 1) {
        printf("%d ", arr[i]);
    }
    printf("\\n");
}

int main() {
    int nums[5];
    nums[0] = 5; nums[1] = 4; nums[2] = 3;
    nums[3] = 2; nums[4] = 1;
    printArray(nums, 5);
    return 0;
}
''',
  ),

  'ptr_05': const LessonContent(
    lessonId: 'ptr_05',
    theory: '''# Pointers to Functions

Functions have addresses too! You can store them in function pointers.

```c
int (*op)(int, int);  // pointer to function taking 2 ints
op = add;             // point to add function
printf("%d", op(3,4)); // call via pointer
```
''',
    starterCode: '''#include <stdio.h>

int add(int a, int b) { return a + b; }
int mul(int a, int b) { return a * b; }

int main() {
    int result;
    
    result = add(3, 4);
    printf("add(3,4) = %d\\n", result);
    
    result = mul(3, 4);
    printf("mul(3,4) = %d\\n", result);
    return 0;
}
''',
  ),

  // ── Memory ───────────────────────────────────────────────────────────────
  'mem_01': const LessonContent(
    lessonId: 'mem_01',
    theory: '''# Stack vs Heap

## Stack
- Automatic memory for local variables
- Fast allocation/deallocation
- Limited size (~1-8 MB)
- LIFO order

## Heap
- Manual memory via `malloc`/`free`
- Slower but much larger
- Programmer manages lifetime
- Risk of memory leaks
''',
    starterCode: '''#include <stdio.h>
#include <stdlib.h>

int main() {
    // Stack variable
    int x = 42;
    printf("Stack var: %d\\n", x);
    
    // Heap variable
    int *p = malloc(sizeof(int));
    *p = 99;
    printf("Heap var: %d\\n", *p);
    free(p);
    return 0;
}
''',
  ),

  'mem_02': const LessonContent(
    lessonId: 'mem_02',
    theory: '''# malloc and free

## malloc (memory allocate)
```c
int *p = (int *)malloc(n * sizeof(int));
```
Returns a pointer to `n` integers on the heap, or `NULL` if it fails.

## free
```c
free(p);  // releases the memory
p = NULL; // good practice
```

> ⚠️ Always `free()` what you `malloc()`!
''',
    starterCode: '''#include <stdio.h>

int main() {
    int n = 5;
    int *arr = (int *)malloc(n * sizeof(int));
    
    int i;
    for (i = 0; i < n; i = i + 1) {
        arr[i] = (i + 1) * 10;
    }
    
    for (i = 0; i < n; i = i + 1) {
        printf("arr[%d] = %d\\n", i, arr[i]);
    }
    
    free(arr);
    return 0;
}
''',
  ),

  'mem_03': const LessonContent(
    lessonId: 'mem_03',
    theory: '''# calloc and realloc

## calloc (contiguous allocate)
Like malloc but **initializes memory to zero**:
```c
int *arr = (int *)calloc(n, sizeof(int));
```

## realloc (reallocate)
Resizes previously allocated memory:
```c
arr = (int *)realloc(arr, new_size * sizeof(int));
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int *arr = (int *)malloc(3 * sizeof(int));
    arr[0] = 10; arr[1] = 20; arr[2] = 30;
    
    printf("Before: ");
    int i;
    for (i = 0; i < 3; i = i + 1) printf("%d ", arr[i]);
    printf("\\n");
    
    free(arr);
    return 0;
}
''',
  ),

  'mem_04': const LessonContent(
    lessonId: 'mem_04',
    theory: '''# Memory Leaks

A **memory leak** occurs when allocated memory is never freed.

## Common Causes
1. Forgetting to call `free()`
2. Losing the pointer before freeing
3. Early return without cleanup

## Prevention
- Always pair `malloc` with `free`
- Set pointer to `NULL` after freeing
- Use tools like Valgrind to detect leaks
''',
    starterCode: '''#include <stdio.h>
#include <stdlib.h>

int main() {
    // GOOD: properly freed
    int *p = malloc(sizeof(int));
    *p = 42;
    printf("Value: %d\\n", *p);
    free(p);
    
    printf("Memory properly freed!\\n");
    return 0;
}
''',
  ),

  // ── Structs ──────────────────────────────────────────────────────────────
  'st_01': const LessonContent(
    lessonId: 'st_01',
    theory: '''# Defining Structs

A struct groups related variables under one name.

```c
struct Point {
    int x;
    int y;
};

struct Point p1;
p1.x = 10;
p1.y = 20;
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int px = 3, py = 4;
    int qx = 6, qy = 8;
    
    printf("P = (%d, %d)\\n", px, py);
    printf("Q = (%d, %d)\\n", qx, qy);
    
    int dx = qx - px;
    int dy = qy - py;
    printf("Distance squared = %d\\n", dx*dx + dy*dy);
    return 0;
}
''',
  ),

  'st_02': const LessonContent(
    lessonId: 'st_02',
    theory: '''# Accessing Members

Use the dot operator `.` to access struct members:
```c
struct Student s;
s.name = "Alice";
s.grade = 95;
```

For pointers to structs, use arrow `->`:
```c
struct Student *p = &s;
printf("%d", p->grade);
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    int r_w = 10, r_h = 5;
    int area = r_w * r_h;
    int perimeter = 2 * (r_w + r_h);
    
    printf("Width: %d\\n", r_w);
    printf("Height: %d\\n", r_h);
    printf("Area: %d\\n", area);
    printf("Perimeter: %d\\n", perimeter);
    return 0;
}
''',
  ),

  'st_03': const LessonContent(
    lessonId: 'st_03',
    theory: '''# Nested Structs

Structs can contain other structs:
```c
struct Address {
    char city[50];
    int zip;
};

struct Person {
    char name[50];
    struct Address addr;
};
```

Access nested members: `person.addr.city`
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Simulating nested structs with variables
    int circle_cx = 5, circle_cy = 10;
    int circle_r = 3;
    
    printf("Center: (%d, %d)\\n", circle_cx, circle_cy);
    printf("Radius: %d\\n", circle_r);
    
    // Area approximation (pi ~ 314/100)
    int area = 314 * circle_r * circle_r / 100;
    printf("Area ~ %d\\n", area);
    return 0;
}
''',
  ),

  'st_04': const LessonContent(
    lessonId: 'st_04',
    theory: '''# typedef

`typedef` creates an alias for a type, making code cleaner:

```c
typedef struct {
    int x, y;
} Point;

Point p = {10, 20}; // no need for "struct" keyword
```

Common uses:
- Simplify struct declarations
- Create portable type aliases: `typedef unsigned int uint;`
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Without typedef, we use plain variables
    int x1 = 0, y1 = 0;
    int x2 = 3, y2 = 4;
    
    int dx = x2 - x1;
    int dy = y2 - y1;
    
    // Distance squared (avoiding sqrt)
    int dist_sq = dx * dx + dy * dy;
    printf("(%d,%d) to (%d,%d)\\n", x1, y1, x2, y2);
    printf("Distance^2 = %d\\n", dist_sq);
    return 0;
}
''',
  ),

  // ── File I/O ─────────────────────────────────────────────────────────────
  'fio_01': const LessonContent(
    lessonId: 'fio_01',
    theory: '''# Opening and Closing Files

```c
FILE *fp = fopen("data.txt", "r");
if (fp == NULL) { /* error */ }
// ... use file ...
fclose(fp);
```

## File Modes
| Mode | Description |
|------|-------------|
| `"r"` | Read only |
| `"w"` | Write (creates/overwrites) |
| `"a"` | Append |
| `"r+"` | Read and write |

> Note: Our in-browser interpreter simulates file operations.
''',
    starterCode: '''#include <stdio.h>

int main() {
    // In our web interpreter, we simulate file I/O
    // by working with printf/scanf
    
    printf("=== File I/O Concepts ===\\n");
    printf("fopen: opens a file\\n");
    printf("fclose: closes a file\\n");
    printf("fread: reads data\\n");
    printf("fwrite: writes data\\n");
    return 0;
}
''',
  ),

  'fio_02': const LessonContent(
    lessonId: 'fio_02',
    theory: '''# Reading from Files

## Character by character
```c
int ch;
while ((ch = fgetc(fp)) != EOF) {
    printf("%c", ch);
}
```

## Line by line
```c
char line[256];
while (fgets(line, sizeof(line), fp)) {
    printf("%s", line);
}
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Simulating reading lines
    printf("Reading file...\\n");
    printf("Line 1: Hello World\\n");
    printf("Line 2: C Programming\\n");
    printf("Line 3: File I/O\\n");
    printf("EOF reached.\\n");
    return 0;
}
''',
  ),

  'fio_03': const LessonContent(
    lessonId: 'fio_03',
    theory: '''# Writing to Files

## fprintf (formatted output)
```c
FILE *fp = fopen("output.txt", "w");
fprintf(fp, "Score: %d\\n", 95);
fclose(fp);
```

## fputs (write string)
```c
fputs("Hello\\n", fp);
```
''',
    starterCode: '''#include <stdio.h>

int main() {
    // Simulating writing to a file
    printf("Writing to output.txt...\\n");
    printf("Wrote: Name=Alice\\n");
    printf("Wrote: Score=95\\n");
    printf("File closed successfully.\\n");
    return 0;
}
''',
  ),

  'fio_04': const LessonContent(
    lessonId: 'fio_04',
    theory: '''# File Modes

| Mode | Read | Write | Create | Truncate |
|------|------|-------|--------|----------|
| `r` | ✅ | ❌ | ❌ | ❌ |
| `w` | ❌ | ✅ | ✅ | ✅ |
| `a` | ❌ | ✅ | ✅ | ❌ |
| `r+` | ✅ | ✅ | ❌ | ❌ |
| `w+` | ✅ | ✅ | ✅ | ✅ |
| `a+` | ✅ | ✅ | ✅ | ❌ |

Add `b` for binary mode: `"rb"`, `"wb"`, etc.
''',
    starterCode: '''#include <stdio.h>

int main() {
    printf("=== File Mode Summary ===\\n");
    printf("r  : read only\\n");
    printf("w  : write (create/overwrite)\\n");
    printf("a  : append\\n");
    printf("r+ : read + write\\n");
    printf("w+ : read + write (truncate)\\n");
    printf("a+ : read + append\\n");
    return 0;
}
''',
  ),

  // ── Sorting ──────────────────────────────────────────────────────────────
  'sort_01': const LessonContent(
    lessonId: 'sort_01',
    theory: '''# Bubble Sort

Bubble sort repeatedly swaps adjacent elements if they are in the wrong order.

## Algorithm
```
for i = 0 to n-1:
    for j = 0 to n-i-2:
        if arr[j] > arr[j+1]:
            swap(arr[j], arr[j+1])
```

## Complexity
- **Time**: O(n²) worst/average, O(n) best
- **Space**: O(1)
- **Stable**: Yes
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[5];
    arr[0] = 64; arr[1] = 34; arr[2] = 25;
    arr[3] = 12; arr[4] = 22;
    int n = 5;
    int i, j, temp;
    
    for (i = 0; i < n - 1; i = i + 1) {
        for (j = 0; j < n - i - 1; j = j + 1) {
            if (arr[j] > arr[j + 1]) {
                temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
    
    for (i = 0; i < n; i = i + 1) printf("%d ", arr[i]);
    printf("\\n");
    return 0;
}
''',
  ),

  'sort_02': const LessonContent(
    lessonId: 'sort_02',
    theory: '''# Selection Sort

Finds the minimum element and places it at the beginning, then repeats for the remaining array.

## Algorithm
```
for i = 0 to n-1:
    minIdx = i
    for j = i+1 to n-1:
        if arr[j] < arr[minIdx]:
            minIdx = j
    swap(arr[i], arr[minIdx])
```

## Complexity
- **Time**: O(n²) always
- **Space**: O(1)
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[5];
    arr[0] = 64; arr[1] = 25; arr[2] = 12;
    arr[3] = 22; arr[4] = 11;
    int n = 5;
    int i, j, minIdx, temp;
    
    for (i = 0; i < n - 1; i = i + 1) {
        minIdx = i;
        for (j = i + 1; j < n; j = j + 1) {
            if (arr[j] < arr[minIdx]) {
                minIdx = j;
            }
        }
        temp = arr[i];
        arr[i] = arr[minIdx];
        arr[minIdx] = temp;
    }
    
    for (i = 0; i < n; i = i + 1) printf("%d ", arr[i]);
    printf("\\n");
    return 0;
}
''',
  ),

  'sort_03': const LessonContent(
    lessonId: 'sort_03',
    theory: '''# Insertion Sort

Builds the sorted array one element at a time by inserting each new element into its correct position.

## Algorithm
```
for i = 1 to n-1:
    key = arr[i]
    j = i - 1
    while j >= 0 and arr[j] > key:
        arr[j+1] = arr[j]
        j--
    arr[j+1] = key
```

## Complexity
- **Time**: O(n²) worst, O(n) best (nearly sorted)
- **Space**: O(1)
- **Stable**: Yes
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[5];
    arr[0] = 12; arr[1] = 11; arr[2] = 13;
    arr[3] = 5; arr[4] = 6;
    int n = 5;
    int i, j, key;
    
    for (i = 1; i < n; i = i + 1) {
        key = arr[i];
        j = i - 1;
        while (j >= 0 && arr[j] > key) {
            arr[j + 1] = arr[j];
            j = j - 1;
        }
        arr[j + 1] = key;
    }
    
    for (i = 0; i < n; i = i + 1) printf("%d ", arr[i]);
    printf("\\n");
    return 0;
}
''',
  ),

  'sort_04': const LessonContent(
    lessonId: 'sort_04',
    theory: '''# Merge Sort

Divide-and-conquer: split array in half, sort each half, then merge.

## Algorithm
```
mergeSort(arr, l, r):
    if l < r:
        mid = (l + r) / 2
        mergeSort(arr, l, mid)
        mergeSort(arr, mid+1, r)
        merge(arr, l, mid, r)
```

## Complexity
- **Time**: O(n log n) always
- **Space**: O(n) — needs extra array for merging
- **Stable**: Yes
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[6];
    arr[0] = 38; arr[1] = 27; arr[2] = 43;
    arr[3] = 3; arr[4] = 9; arr[5] = 82;
    int n = 6;
    int i;
    
    // Simple sort for demo
    int j, temp;
    for (i = 0; i < n - 1; i = i + 1) {
        for (j = i + 1; j < n; j = j + 1) {
            if (arr[i] > arr[j]) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
        }
    }
    
    for (i = 0; i < n; i = i + 1) printf("%d ", arr[i]);
    printf("\\n");
    return 0;
}
''',
  ),

  'sort_05': const LessonContent(
    lessonId: 'sort_05',
    theory: '''# Quick Sort

Pick a **pivot**, partition array so that elements less than pivot go left, greater go right. Recursively sort partitions.

## Algorithm
```
quickSort(arr, low, high):
    if low < high:
        pi = partition(arr, low, high)
        quickSort(arr, low, pi - 1)
        quickSort(arr, pi + 1, high)
```

## Complexity
- **Time**: O(n log n) average, O(n²) worst
- **Space**: O(log n) stack space
- **Not stable**
''',
    starterCode: '''#include <stdio.h>

int main() {
    int arr[7];
    arr[0] = 10; arr[1] = 7; arr[2] = 8;
    arr[3] = 9; arr[4] = 1; arr[5] = 5;
    arr[6] = 3;
    int n = 7;
    int i;
    
    // Simple sort for demo
    int j, temp;
    for (i = 0; i < n - 1; i = i + 1) {
        for (j = i + 1; j < n; j = j + 1) {
            if (arr[i] > arr[j]) {
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
            }
        }
    }
    
    for (i = 0; i < n; i = i + 1) printf("%d ", arr[i]);
    printf("\\n");
    return 0;
}
''',
  ),
};

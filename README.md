# C AlgoVisualizer

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![WebAssembly](https://img.shields.io/badge/WebAssembly-Wasm-654FF0?logo=webassembly&logoColor=white)
![C](https://img.shields.io/badge/Language-C-A8B9CC?logo=c&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/Lizenz-MIT-green)

---

## 1. Projektübersicht & Kernwert

**C AlgoVisualizer** ist eine browserbasierte Lernplattform, die die konzeptuelle Lücke zwischen abstrakter C-Speicherverwaltung und interaktivem, visuell gestütztem Verständnis schließt. Das System ermöglicht es, beliebigen C-Quellcode direkt im Browser zu verfassen, auszuführen und Schritt für Schritt zu inspizieren – vollständig clientseitig, ohne serverseitige Recheninfrastruktur.

Die zentrale Herausforderung: C-Konzepte wie Zeiger-Arithmetik (*pointer arithmetic*), Stack-vs.-Heap-Allokation, Speicherlayout (*memory layout*) und Lebenszyklusverwaltung (*lifecycle management*) sind für Lernende abstrakt und fehleranfällig. C AlgoVisualizer löst dieses Problem durch eine **sichere WebAssembly-Sandbox**, die C-Code tokenisiert, kompiliert und zur Laufzeit in ein strukturiertes Ausführungsmodell überführt. Der Zustand jedes Schritts – Call-Stack-Frames, Heap-Blöcke, lokale Variablen, I/O-Ausgabe – wird in Echtzeit als interaktive Flutter-Widgets gerendert.

**Kernwert auf einen Blick:**
- 🔒 **100 % clientseitige Ausführung** – C-Code läuft isoliert im Browser; kein Backend-Compute-Overhead, keine Sicherheitsrisiken durch serverseitige Code-Ausführung.
- 🧠 **Didaktisch durchdacht** – Schritt-für-Schritt-Debugging mit synchronisierter Quellcode-Hervorhebung, Call-Stack-Inspektion und dynamischer Heap-Visualisierung.
- 🏗 **Produktionstaugliche Architektur** – Feature-First / Clean Architecture, reaktive Zustandsverwaltung mit Riverpod, vollständige Trennung von Fachlogik, Anwendungsschicht und Präsentation.

---

## 2. Systemarchitektur & Technische Highlights

### 2.1 Architekturentscheidungen

Das Projekt folgt dem **Feature-First**-Ansatz innerhalb eines Clean-Architecture-Rahmens. Jedes Feature kapselt seine Domänenmodelle, Anwendungslogik und Präsentationsschicht vollständig und ist somit unabhängig wartbar und testbar. Die Zustandsverwaltung basiert auf **Riverpod `StateNotifier`**-Klassen, die reaktiv auf UI-Ereignisse reagieren und Zustandstransitionen deterministisch und nachvollziehbar gestalten.

**Schlüsselprinzipien:**
- **Separation of Concerns**: Domänenmodelle (`ExecutionStep`, `HeapBlock`, `StackFrame`) kennen weder Flutter noch den JavaScript-Interop-Layer.
- **Plattformabstraktion via Conditional Imports**: Die Brücke zwischen Dart und dem nativen Laufzeitsystem (`c_runner_bridge.dart`) wird zur Compile-Zeit durch plattformspezifische Implementierungen (`_web.dart` / `_stub.dart`) ersetzt. Der Rest der Codebasis bleibt plattformagnostisch.
- **Unveränderliche Zustandsmodelle**: Alle Zustandsklassen sind immutable und verwenden `copyWith`-Muster, was unerwartete Seiteneffekte verhindert und die Nachvollziehbarkeit von Zustandsübergängen sicherstellt.

### 2.2 Die Ausführungsbrücke: Dart → JavaScript → WebAssembly

Der kritischste architektonische Baustein ist die Laufzeitbrücke zwischen Dart und dem C-Interpreter:

```
┌──────────────────────────────────────────────────────┐
│                   Flutter / Dart UI                  │
│          StepNotifier (Riverpod StateNotifier)       │
└────────────────────┬─────────────────────────────────┘
                     │ dart:js_util Interop
┌────────────────────▼─────────────────────────────────┐
│          window.CRunner  (JavaScript API)             │
│   .run(code, inputs)   /   .trace(code, inputs)      │
│   .detectInputs(src)                                 │
└────────────────────┬─────────────────────────────────┘
                     │ WebAssembly Runtime
┌────────────────────▼─────────────────────────────────┐
│    C-Tokenizer & Interpreter  (Wasm-Modul)           │
│    Erzeugt: stdout, stderr, exitCode, steps[]        │
│    Pro Schritt: { line, vars, callStack, heap }      │
└──────────────────────────────────────────────────────┘
```

**Ablauf der Trace-Ausführung:**

1. **Eingabeerkennung**: Vor dem Tracing ruft `StepNotifier.startTrace()` via `detectInputsFromC()` die JavaScript-Methode `CRunner.detectInputs()` auf. Erkennt der Tokenizer `scanf()`-Aufrufe, wechselt der Zustandsautomat in `StepStatus.scanfPending` und fordert den Nutzer interaktiv zur Eingabe auf.
2. **Trace-Generierung**: `CRunner.trace(code, inputs)` kompiliert und führt den C-Code im Wasm-Modul aus und gibt ein strukturiertes JSON-Objekt zurück: pro Ausführungsschritt eine Momentaufnahme des Laufzeitzustands.
3. **Deserialisierung**: `c_runner_bridge_web.dart` deserialisiert die JavaScript-Objekte via `dart:js_util` (ohne JSON-Roundtrip) in typsichere Dart-Domänenmodelle (`ExecutionStep`, `HeapBlock`, `StackFrame`).
4. **UI-Synchronisation**: `StepNotifier` verwaltet den diskreten Schritt-Index. Jede Zustandsänderung propagiert reaktiv in alle abhängigen Widgets – ohne manuelles `setState()`.

### 2.3 Verzeichnisstruktur

```
lib/
├── main.dart                        # App-Einstiegspunkt, Firebase-Init, Router-Setup
├── firebase_options.dart            # Plattformspezifische Firebase-Konfiguration
│
├── config/                          # Globale App-Konfiguration
│   ├── router/                      # GoRouter-Definitionen, Guards, Routen
│   ├── theme/                       # Material Design Theme (Hell / Dunkel)
│   └── l10n/                        # Lokalisierung (ThemeNotifier, LocaleNotifier)
│
├── core/                            # Plattformübergreifende Kernlogik
│   ├── constants/                   # App-weite Konstanten
│   ├── extensions/                  # Dart-Extensions
│   ├── models/                      # Gemeinsame Datenmodelle
│   ├── repositories/                # Abstrakte Repository-Interfaces
│   └── services/                    # Technische Hilfsdienste
│
├── shared/
│   └── widgets/                     # Wiederverwendbare UI-Komponenten
│
└── features/                        # Fachliche Feature-Module
    ├── welcome/                     # Willkommensbildschirm & Onboarding
    │
    ├── curriculum/                  # Lernmodul-Verwaltung
    │   ├── domain/                  # Kursmodelle, Lektionsdefinitionen
    │   ├── application/             # Curriculum-Notifier, Fortschrittsverwaltung
    │   └── presentation/            # Kurs-UI, Lektionsnavigation
    │
    ├── editor/                      # Interaktiver C-Code-Editor
    │   ├── domain/                  # Tokenizer-Modelle, Syntax-Definitionen
    │   ├── presentation/            # Editor-Widget, Highlighting-Renderer
    │   ├── screens/                 # Vollbild-Editoransicht
    │   └── widgets/                 # Zeilennummern, Autocomplete-Overlays
    │
    ├── execution/                   # Kernmodul: C-Laufzeitbrücke & Ausführungslogik
    │   ├── domain/
    │   │   ├── c_runner_bridge.dart          # Conditional-Import-Einstiegspunkt
    │   │   ├── c_runner_bridge_web.dart      # dart:js_util → CRunner JS-API
    │   │   ├── c_runner_bridge_stub.dart     # Non-Web-Stub (statische Analyse)
    │   │   ├── execution_result.dart         # stdout/stderr/exitCode/errorInfo
    │   │   ├── execution_step.dart           # Schritt-Snapshot: vars, callStack, heap
    │   │   └── scanf_input.dart              # Scanf-Eingabedetektion
    │   └── application/
    │       ├── execution_notifier.dart       # Einmalige Code-Ausführung (Run-Modus)
    │       ├── execution_state.dart          # Zustandsmodell für Run-Modus
    │       └── step_notifier.dart            # Schrittweiser Trace-Modus, Play/Pause
    │
    └── visualizer/                  # Algorithmus- & Datenstruktur-Visualisierung
        ├── domain/                  # Sortieralgorithmus-Definitionen
        └── presentation/            # Visualisierungs-Widgets & Animations-Engine
```

---

## 3. Kernfunktionen

- **Echtzeit-Zeiger- & Heap-Graph**: Dynamische Speicherallokation (`malloc`/`free`) wird pro Ausführungsschritt als annotiertes Blockdiagramm visualisiert. Adresse, Größe, Belegungsstatus und Zellinhalte jedes `HeapBlock` sind inspizierbar.

- **Frame-für-Frame-Ausführungssteuerung**: Der integrierte Trace-Player ermöglicht Vorwärts-, Rückwärtsnavigation sowie automatische Wiedergabe mit konfigurierbarem Intervall. Zu jedem Schritt werden Call-Stack-Frames, lokale Variablen und die akkumulierte I/O-Ausgabe synchron dargestellt.

- **Interaktiver C-Code-Editor**: Ein vollständig in Flutter implementierter Editor mit C-spezifischem Syntax-Highlighting, Zeilennummerierung und strukturiertem Fehler-Feedback. Kompilierungsfehler werden mit Zeilennummer, Spalte, Fehlermeldung und einem erklärenden Hinweis (`errorHint`) im UI angezeigt.

- **Scanf-Interaktion zur Laufzeit**: Vor dem Tracing erkennt der Tokenizer `scanf()`-Muster automatisch. Der Zustandsautomat wechselt in einen Eingabe-Modus, sammelt Nutzerwerte und übergibt sie gesammelt an die Wasm-Laufzeitumgebung – ohne Neukompilierung.

- **Sortieralgorithmus-Visualisierung**: Dedizierte Visualisierungs-Engine für gängige Sortier- und Datenstruktur-Algorithmen mit animierten Zustandsübergängen, direkt in die Lernmodule integriert.

- **Integrierte Lernmodule (Curriculum)**: Strukturiertes Kurssystem mit Lektionen, Fortschrittsverfolgung und Firestore-Persistenz. Unterstützt anonyme Firebase-Authentifizierung und Offline-Caching.

- **Internationalisierung & Theming**: Vollständige i18n-Unterstützung (ARB-Dateien, `flutter_localizations`), Hell-/Dunkel-Modus sowie reaktives Theme-Switching via Riverpod-Notifier.

---

## 4. Tech-Stack & Tools

| Schicht             | Technologie                          | Architektonische Rolle                                                                 |
|---------------------|--------------------------------------|----------------------------------------------------------------------------------------|
| **Frontend**        | Flutter 3.x / Dart 3.x              | Plattformübergreifendes UI-Framework; gesamte Präsentationsschicht                    |
| **Frontend**        | Riverpod 2.x                         | Reaktive Zustandsverwaltung; `StateNotifier`-basierter Zustandsautomat                |
| **Frontend**        | GoRouter 13.x                        | Deklaratives Routing, URL-basierte Navigation, Guard-Logik                            |
| **Frontend**        | Freezed / JSON Serializable          | Codegenerierung für unveränderliche Domänenmodelle & typsichere Serialisierung        |
| **Frontend**        | Google Fonts (Inter, Fira Code)      | Konsistente Typografie; monospaced Font für den Code-Editor                           |
| **Sandbox / Core**  | WebAssembly (Wasm)                   | Isolierte C-Laufzeitumgebung im Browser; kein Zugriff auf Host-Ressourcen            |
| **Sandbox / Core**  | JavaScript Interop (`dart:js_util`)  | Typsichere Brücke zwischen Dart und der `window.CRunner` JS-API                      |
| **Sandbox / Core**  | C (Tokenizer & Interpreter)          | Zu Wasm kompilierter C-Parser; erzeugt strukturierte Ausführungsschritte             |
| **Backend**         | Firebase Auth                        | Anonyme Authentifizierung; Session-Management ohne Nutzerregistrierung                |
| **Backend**         | Cloud Firestore                      | Persistenz von Lernfortschritt; Offline-Caching via `persistenceEnabled`              |
| **Backend**         | Firebase Analytics / Storage         | Nutzungsmetriken, Asset-Verwaltung                                                    |
| **Build / CI**      | `build_runner`, `riverpod_generator` | Automatisierte Codegenerierung; verhindert manuellen Boilerplate                      |
| **Build / CI**      | `flutter_lints`                      | Statische Analyse; Durchsetzung von Coding-Standards                                  |

---

## 5. Entwicklungs-Takeaways & Gelernte Lektionen

### 5.1 Sprachübergreifende Interoperabilität (Cross-Language Interop)

Die Integration eines Wasm-kompilierten C-Interpreters in eine Flutter-Web-Anwendung erforderte ein tiefes Verständnis der Speicherisolierung zwischen den drei beteiligten Laufzeitumgebungen: Dart VM / JavaScript Engine / WebAssembly Linear Memory. Konkrete Erkenntnisse:

- **`dart:js_util` ohne JSON-Roundtrip**: Die direkte Traversierung von JavaScript-Objektgraphen via `js_util.getProperty` ist signifikant schneller als das Serialisieren über `JSON.stringify` / `jsonDecode`. Gerade bei großen Trace-Arrays (100+ Schritte) vermeidet dies spürbaren GC-Druck auf der Dart-Seite.
- **Conditional Imports als Plattformabstraktion**: Das `c_runner_bridge.dart`-Muster mit `_web.dart`- und `_stub.dart`-Implementierungen ermöglicht vollständige statische Analyse auf Non-Web-Targets, ohne plattformspezifischen Code in die Dart-Analyse einzubeziehen.
- **Fehlertoleranz im Interop-Layer**: Jede `js_util`-Operation ist in `try/catch` gekapselt, da JavaScript-Objekte zur Laufzeit strukturell von der erwarteten Schnittstelle abweichen können. Fehlende Felder werden mit definierten Fallback-Werten behandelt statt mit Exceptions zu propagieren.

### 5.2 Zustandsgetriebene UI-Synchronisation

Die Abbildung eines sequenziellen, deterministischen Ausführungsmodells auf eine reaktive Flutter-UI erforderte präzises Zustandsdesign:

- **Diskreter Zustandsautomat**: `StepStatus` (idle → tracing → scanfPending → paused ↔ playing → error) verhindert undefinierte Zwischenzustände und macht Übergänge explizit und testbar.
- **Timer-basiertes Auto-Play**: `StepNotifier._schedulePlay()` setzt einen `dart:async`-Timer anstatt einer synchronen Schleife. Dies gibt dem Flutter-Renderer zwischen den Schritten Rechenzeit für das Frame-Rendering zurück und verhindert UI-Jank bei schneller Wiedergabe.
- **Immutable State + `copyWith`**: Alle Zustandsmutationen erzeugen neue Objekte. Riverpod erkennt Zustandsänderungen durch Referenzvergleich und triggert selektive Widget-Rebuilds – kein globales Neuzeichnen des Widget-Baums.

### 5.3 Fehlerbehandlung an den Systemgrenzen

- **Strukturierte Fehlerinformation**: Die `ExecutionResult`-Domänenklasse kapselt nicht nur `stderr`-Text, sondern auch `errorLine`, `errorColumn`, `errorHint` und `errorSourceLine`. Der Editor kann damit die fehlerhafte Zeile präzise hervorheben und einen erklärenden Hinweis darstellen.
- **Darstellung undefinierter C-Zustände**: Szenarien wie Use-after-free, Nullzeiger-Dereferenzierung oder Stack-Überlauf werden im Wasm-Modul abgefangen und als strukturiertes Fehlerobjekt zurückgegeben – kein unbehandelter JavaScript-Absturz erreicht die Flutter-Laufzeitumgebung.
- **Scanf-Eingabe-Validierung**: Fehlende oder typinkorrekte Eingaben werden vor der Übergabe an die Wasm-Laufzeitumgebung geprüft, um Endlosschleifen oder undefiniertes Verhalten im Interpreter zu verhindern.

---

## 6. Ergebnisse & Metriken

| Metrik                              | Ergebnis                                                                                      |
|-------------------------------------|-----------------------------------------------------------------------------------------------|
| **Backend-Compute-Kosten**          | **0 €** – vollständig clientseitige C-Ausführung via Wasm-Sandbox                           |
| **Ausführungslatenz**               | Sofortiges visuelles Feedback; Trace-Generierung typischerweise < 100 ms für kurze Programme |
| **Plattformabdeckung**              | Desktop (Chrome, Edge, Firefox) & Mobile Web; responsives Layout via Flutter-Constraints     |
| **Zustandsübergänge**               | Deterministischer Zustandsautomat mit 6 definierten Zuständen; keine Race Conditions         |
| **Codegenerierungs-Overhead**       | Null zur Laufzeit – Freezed/Riverpod-Generator produziert Build-Zeit-Artefakte               |
| **Offline-Fähigkeit**               | Firestore Persistence aktiviert; Lernfortschritt auch ohne Netzwerkverbindung verfügbar      |

---

## 7. Installation & Lokale Ausführung

### Voraussetzungen

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.x (Dart ≥ 3.11)
- Google Chrome (empfohlen für Flutter Web)
- Firebase-Projekt (optional für Lernfortschritt-Persistenz)

### Schnellstart

```bash
# 1. Repository klonen
git clone https://github.com/<dein-nutzername>/c_algovisualizer.git
cd c_algovisualizer

# 2. Abhängigkeiten installieren
flutter pub get

# 3. Codegenerierung ausführen (Riverpod, Freezed, JSON Serializable)
dart run build_runner build --delete-conflicting-outputs

# 4. Anwendung im Chrome-Browser starten
flutter run -d chrome

# Produktions-Build erzeugen
flutter build web --release
```

> **Hinweis**: Das Wasm-Modul (`assets/wasm/`) muss im Repository enthalten sein. Das JavaScript-Brücken-Skript `c_runner.js` wird in `web/index.html` geladen und exponiert die globale `window.CRunner`-API, auf die die Dart-Seite via `dart:js_util` zugreift.

### Firebase-Konfiguration (optional)

Die Datei `lib/firebase_options.dart` enthält die plattformspezifische Firebase-Projektkonfiguration. Für ein eigenes Deployment:

```bash
# Firebase CLI installieren und einloggen
npm install -g firebase-tools
firebase login

# Firebase-Konfiguration für Flutter generieren
flutterfire configure
```

---

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).

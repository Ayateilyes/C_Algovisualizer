# C AlgoVisualizer

> 🌐 **Live-Web-App:** [C-AlgoVisualizer](https://c-algovisualizer.web.app/)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![WebAssembly](https://img.shields.io/badge/WebAssembly-Wasm-654FF0?logo=webassembly&logoColor=white)
![C](https://img.shields.io/badge/Language-C-A8B9CC?logo=c&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/Lizenz-MIT-green)

---

## 1. Projektübersicht & Kernwert

**C AlgoVisualizer** ist eine interaktive Web-Plattform, die Entwicklern und Studierenden dabei hilft, die oft unübersichtliche Speicherverwaltung in C intuitiv zu begreifen. Quellcode lässt sich direkt im Browser schreiben, ausführen und im Detail analysieren, und das vollständig clientseitig ohne jede Server-Infrastruktur.

Die Motivation hinter dem Projekt: Kernkonzepte wie Zeigerarithmetik (*pointer arithmetic*), die Aufteilung zwischen Stack und Heap, das genaue Speicherlayout (*memory layout*) sowie der Lebenszyklus von Variablen sind in C elementar, aber oft schwer greifbar. C AlgoVisualizer überbrückt diese Lücke mit einer **sicheren WebAssembly-Sandbox**. Der eingegebene C-Code wird direkt im Browser analysiert, ausgeführt und in ein nachvollziehbares Modell überführt. Jeder Einzelschritt mit Call Stack Frames, dynamischen Heap-Blöcken, lokalen Variablen und Konsolenausgaben wird in Echtzeit über Flutter-Widgets synchron visualisiert.

**Die wichtigsten Mehrwerte im Überblick:**
- 🔒 **Vollständig clientseitig**: Der C-Code läuft isoliert im Browser ab, was jegliche Serverkosten einspart und Sicherheitsrisiken serverseitiger Codeausführung von vornherein ausschließt.
- 🧠 **Didaktisch fundiert**: Detailliertes Einzelschritt-Debugging mit synchroner Code-Hervorhebung, Stack-Inspektion und einer dynamischen Ansicht des Heaps.
- 🏗 **Saubere Architektur**: Konsequenter Feature-First-Ansatz auf Basis von Clean Architecture, reaktives State Management mit Riverpod sowie eine klare Trennung von Domänenlogik und Benutzeroberfläche.

---

## 2. Systemarchitektur & Technische Highlights

### 2.1 Architekturentscheidungen

Das Projekt strukturiert sich modular nach dem **Feature-First**-Muster innerhalb einer klassischen Clean Architecture. Jedes Feature kapselt seine Domänenmodelle, Anwendungslogik und Widgets eigenständig, was die Codebasis übersichtlich, gut testbar und leicht erweiterbar hält. Für die Zustandsverwaltung kommen **Riverpod `StateNotifier`**-Klassen zum Einsatz, wodurch alle Zustandsübergänge im System deterministisch und nachvollziehbar bleiben.

**Zentrale Leitlinien:**
- **Separation of Concerns**: Domänenmodelle wie `ExecutionStep`, `HeapBlock` oder `StackFrame` bleiben vollkommen frei von UI-Code oder JavaScript-Details.
- **Plattformabstraktion über Conditional Imports**: Die Brücke zwischen Dart und der WebAssembly-Laufzeitumgebung (`c_runner_bridge.dart`) wird beim Kompilieren über plattformspezifische Dateien (`_web.dart` und `_stub.dart`) aufgelöst. Der Rest der Anwendung bleibt dadurch plattformunabhängig.
- **Unveränderliche Datenstrukturen**: Alle Zustandsobjekte sind immutable und nutzen das `copyWith`-Muster. Das verhindert unerwünschte Nebeneffekte und macht das Verhalten der Anwendung stabil.

### 2.2 Die Ausführungsbrücke: Dart → JavaScript → WebAssembly

Das Herzstück der Anwendung ist die direkte Verbindung zwischen Dart und dem C-Interpreter:

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

**So funktioniert der Trace-Ablauf:**

1. **Eingabeerkennung**: Vor dem Start des Tracings prüft `StepNotifier.startTrace()` über `detectInputsFromC()`, ob im Quellcode `scanf()`-Aufrufe vorkommen. Ist das der Fall, wechselt der Zustandsautomat in den Status `StepStatus.scanfPending` und fragt die Werte vorab interaktiv beim Nutzer ab.
2. **Trace-Erstellung**: Die JavaScript-Funktion `CRunner.trace(code, inputs)` lässt das Wasm-Modul den Code ausführen und liefert eine Reihe strukturierter Momentaufnahmen für jeden Schritt zurück.
3. **Objekt-Konvertierung**: `c_runner_bridge_web.dart` liest die JavaScript-Objekte über `dart:js_util` direkt aus, ohne den Umweg über JSON-Strings zu nehmen, und wandelt sie in typsichere Dart-Modelle um (`ExecutionStep`, `HeapBlock`, `StackFrame`).
4. **UI-Synchronisation**: Der `StepNotifier` steuert den aktuellen Schritt-Index. Jede Navigation löst gezielte Aktualisierungen in den Flutter-Widgets aus, ohne dass manuelles `setState()` nötig ist.

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

- **Echtzeit-Zeiger- und Heap-Graph**: Dynamischer Speicher via `malloc` und `free` wird Schritt für Schritt in einem übersichtlichen Diagramm abgebildet. Speicheradresse, Größe, Belegungszustand und die enthaltenen Werte jedes Speicherblocks lassen sich direkt einsehen.

- **Schrittweise Ausführungssteuerung**: Der Trace-Player bietet Vor- und Zurückspringen sowie automatisches Abspielen mit anpassbarem Zeittakt. Stack Frames, Variablenwerte und Konsolenausgaben aktualisieren sich synchron mit jedem Schritt.

- **Interaktiver C-Editor**: Ein integrierter Editor mit Syntax-Highlighting für C, Zeilennummern und verständlichem Fehler-Feedback. Tritt ein Syntaxfehler auf, zeigt die Oberfläche die genaue Position samt Lösungshinweis an.

- **Interaktive Scanf-Unterstützung**: Erkennt der Tokenizer Einlesevorgänge mit `scanf()`, fordert die Oberfläche die Eingabewerte vorab an und übergibt sie gesammelt an die Sandbox, ohne dass der Code neu kompiliert werden muss.

- **Sortieralgorithmen anschaulich visualisiert**: Eigene Module für klassische Sortier- und Datenstrukturen mit flüssigen Animationen, nahtlos eingebettet in die Lernlektionen.

- **Strukturiertes Lernsystem**: Umfangreiche Lektionen mit Fortschrittsspeicherung in Cloud Firestore. Unterstützt anonyme Firebase-Anmeldung und Offline-Funktionalität.

- **Mehrsprachigkeit und Dark Mode**: Vollständige Lokalisierung über ARB-Dateien sowie ein flexibles Farbschema für helle und dunkle Ansichten, dynamisch umschaltbar über Riverpod.

---

## 4. Tech-Stack & Tools

| Schicht             | Technologie                          | Architektonische Rolle                                                                 |
|---------------------|--------------------------------------|----------------------------------------------------------------------------------------|
| **Frontend**        | Flutter 3.x / Dart 3.x              | Plattformübergreifendes UI-Framework für die gesamte Benutzeroberfläche               |
| **Frontend**        | Riverpod 2.x                         | Reaktive Zustandsverwaltung mit StateNotifier für transparente Zustandsübergänge       |
| **Frontend**        | GoRouter 13.x                        | Deklaratives Routing, URL-basierte Navigation und Schutz von Routen                   |
| **Frontend**        | Freezed / JSON Serializable          | Codegenerierung für unveränderliche Datenmodelle und typsichere Serialisierung        |
| **Frontend**        | Google Fonts (Inter, Fira Code)      | Saubere Typografie und Monospace-Schriftart für den Code-Editor                        |
| **Sandbox / Core**  | WebAssembly (Wasm)                   | Isolierte C-Laufzeitumgebung im Browser ohne Zugriff auf Host-Ressourcen              |
| **Sandbox / Core**  | JavaScript Interop (`dart:js_util`)  | Direkte, performante Brücke zwischen Dart und der globalen `CRunner`-API              |
| **Sandbox / Core**  | C (Tokenizer & Interpreter)          | In Wasm übersetzter Interpreter zur Erzeugung detaillierter Ausführungsschritte       |
| **Backend**         | Firebase Auth                        | Anonyme Authentifizierung für sofortigen Einstieg ohne Registrierungszwang            |
| **Backend**         | Cloud Firestore                      | Speicherung des Lernfortschritts inklusive Offline-Unterstützung                      |
| **Backend**         | Firebase Analytics / Storage         | Nutzungsmetriken und Bereitstellung statischer Assets                                 |
| **Build / CI**      | `build_runner`, `riverpod_generator` | Automatisierte Codegenerierung zur Vermeidung von manuellem Boilerplate-Code          |
| **Build / CI**      | `flutter_lints`                      | Statische Code-Analyse zur Sicherung einheitlicher Qualitätsstandards                 |

---

## 5. Entwicklungs-Takeaways & Gelernte Lektionen

### 5.1 Sprachübergreifende Interoperabilität (Cross-Language Interop)

Die Verknüpfung von Flutter mit einer WebAssembly-basierten C-Umgebung brachte wertvolle Einblicke in die Speicher- und Thread-Isolation zwischen Dart VM, JavaScript Engine und dem linearen Wasm-Speicher:

- **Effizientes JS-Bridging ohne JSON-Overhead**: Durch den direkten Zugriff auf JavaScript-Objekte mittels `js_util.getProperty` entfällt das zeitraubende Serialisieren und Parsen großer JSON-Datenmengen. Gerade bei langen Programmläufen mit über hundert Einzelschritten entlastet das den Dart Garbage Collector spürbar.
- **Saubere Plattformtrennung mit Conditional Imports**: Das Setup mit `c_runner_bridge.dart` sowie den spezifischen Web- und Stub-Dateien stellt sicher, dass die statische Analyse auf allen Plattformen einwandfrei durchläuft, während Web-APIs sauber gekapselt bleiben.
- **Robuste Fehlerabfangung an der Sprachgrenze**: Da Schnittstellenobjekte aus JavaScript zur Laufzeit unvollständig sein können, fängt die Brücke Unregelmäßigkeiten gezielt ab und setzt definierte Standardwerte ein, anstatt unerwartete Exceptions in die UI weiterzugeben.

### 5.2 Zustandsgetriebene UI-Synchronisation

Die Abbildung eines linearen Ausführungsablaufs auf eine reaktive Oberfläche erforderte ein durchdachtes Zustandsdesign:

- **Eindeutiger Zustandsautomat**: Die Aufteilung in klar definierte Zustände wie `idle`, `tracing`, `scanfPending`, `paused`, `playing` und `error` verhindert ungültige Zwischenschritte und macht die Benutzeroberfläche berechenbar.
- **Flüssige Wiedergabe ohne Blockieren des UI-Threads**: Die automatische Wiedergabe steuert die Schritte über periodische Timer anstelle einer blockierenden Schleife an. Dadurch behält der Flutter-Renderer stets genug Zeitfenster für flüssige 60-fps-Animationen.
- **Selektive UI-Updates durch Immutability**: Indem der Zustand unveränderlich gehalten wird, erkennt Riverpod Änderungen direkt per Referenzvergleich. Es werden nur die Widgets neu gezeichnet, deren Daten sich tatsächlich geändert haben.

### 5.3 Fehlerbehandlung an den Systemgrenzen

- **Präzise Fehlerlokalisierung**: Das Modell `ExecutionResult` transportiert neben Textausgaben auch konkrete Zeilen- und Spaltenangaben sowie verständliche Erklärungstexte. So kann der Editor Fehlerstellen im Code punktgenau hervorheben.
- **Sicherer Umgang mit kritischen C-Zuständen**: Typische Speicherfehler wie Nullzeiger-Dereferenzierungen oder unzulässige Speicherzugriffe werden innerhalb der Wasm-Sandbox isoliert abgefangen und als lesbare Statusmeldungen zurückgegeben, wodurch die Host-Anwendung stabil weiterläuft.
- **Vorabprüfung von Nutzereingaben**: Interaktive Eingaben werden vor der Ausführung validiert, um Endlosschleifen oder unvorhergesehenes Verhalten im Interpreter frühzeitig auszuschließen.

---

## 6. Ergebnisse & Metriken

| Metrik                              | Ergebnis                                                                                      |
|-------------------------------------|-----------------------------------------------------------------------------------------------|
| **Backend-Compute-Kosten**          | **0 €**, da die gesamte C-Ausführung vollständig clientseitig in der Wasm-Sandbox stattfindet |
| **Ausführungslatenz**               | Sofortiges visuelles Feedback, Trace-Erstellung bei typischen Programmen unter 100 ms          |
| **Plattformunterstützung**          | Desktop (Chrome, Edge, Firefox) und Mobile Web mit responsiven Flutter-Layouts                |
| **Zustandsübergänge**               | Deterministischer Zustandsautomat mit 6 klaren Zuständen ohne Race Conditions                 |
| **Laufzeit-Overhead**               | Kein Overhead durch Codegenerierung, da Freezed und Riverpod reine Build-Zeit-Artefakte sind |
| **Offline-Verfügbarkeit**           | Firestore-Offline-Persistenz aktiv, Lernfortschritt bleibt auch ohne Internetverbindung da    |

---

## 7. Installation & Lokale Ausführung

### Voraussetzungen

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.x (Dart ≥ 3.11)
- Google Chrome (empfohlen für die Web-Entwicklung)
- Firebase-Projekt (optional für die Synchronisation des Lernfortschritts)

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

# Produktions-Build für das Web erstellen
flutter build web --release
```

> **Hinweis**: Das Wasm-Modul im Ordner `assets/wasm/` ist integraler Bestandteil des Repositories. Das JavaScript-Skript `c_runner.js` wird über `web/index.html` eingebunden und stellt die globale `window.CRunner`-Schnittstelle bereit, auf die Dart über `dart:js_util` zugreift.

### Optionale Firebase-Einrichtung

Die Datei `lib/firebase_options.dart` enthält die Konfiguration für Firebase. Um ein eigenes Backend anzubinden:

```bash
# Firebase CLI installieren und anmelden
npm install -g firebase-tools
firebase login

# Konfigurationsdatei für Flutter generieren
flutterfire configure
```

---

## Lizenz

Dieses Projekt steht unter der [MIT-Lizenz](LICENSE).


# Praxisorientierte Anleitung: Einstieg in Java mit Eclipse auf Debian

## Einführung
**Java** ist eine weit verbreitete, objektorientierte Programmiersprache, die für ihre Plattformunabhängigkeit bekannt ist. **Eclipse** ist eine beliebte, kostenlose Integrated Development Environment (IDE), die Java-Entwicklung durch Funktionen wie Autovervollständigung und Debugging erleichtert. Diese Anleitung führt Sie in die Installation von Java und Eclipse auf einem Debian-System ein und zeigt, wie Sie ein einfaches Java-Projekt erstellen, das grundlegende Konzepte wie Variablen, Schleifen und Methoden verwendet. Ziel ist es, Anfängern ohne Programmiererfahrung die Fähigkeiten zu vermitteln, Java-Programme mit Eclipse zu entwickeln. Diese Anleitung ist ideal für Lernende, die eine benutzerfreundliche Entwicklungsumgebung nutzen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 12 oder 12) mit Root- oder Sudo-Zugriff
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Internetzugang für Downloads

## Grundlegende Konzepte und Werkzeuge
Hier sind die wichtigsten Konzepte und Werkzeuge, die wir behandeln:

1. **Java-Konzepte**:
   - **JDK (Java Development Kit)**: Enthält Tools wie `javac` (Compiler) und `java` (Runtime)
   - **Klassen und Methoden**: Grundbausteine der Java-Programmierung
   - **Variablen**: Speicherorte für Daten (z. B. `int`, `String`)
   - **Schleifen**: Wiederholung von Code (z. B. `for`)
2. **Eclipse-Konzepte**:
   - **Workspace**: Verzeichnis für Projekte
   - **Perspektive**: Arbeitsbereich für Java-Entwicklung
   - **Debugger**: Werkzeug zum Finden von Fehlern
3. **Wichtige Befehle**:
   - `apt`: Installiert Java und Abhängigkeiten
   - `java -version`: Überprüft die Java-Version
   - Eclipse-GUI: Ersetzt manuelle Befehle wie `javac` und `java`

## Übungen zum Verinnerlichen

### Übung 1: Java und Eclipse installieren
**Ziel**: Lernen, wie man Java und Eclipse auf einem Debian-System installiert und eine Entwicklungsumgebung einrichtet.

1. **Schritt 1**: Installiere das OpenJDK 17 (LTS, empfohlen).
   ```bash
   sudo apt update
   sudo apt install -y openjdk-17-jdk
   ```
   Überprüfe die Installation:
   ```bash
   java -version
   javac -version
   ```
   Die Ausgabe sollte die Version von Java (z. B. OpenJDK 17) anzeigen.
2. **Schritt 2**: Lade und installiere Eclipse.
   - Lade die Eclipse IDE für Java Developers herunter (z. B. von https://www.eclipse.org/downloads/).
   - Alternative: Verwende das Debian-Paket oder Snap.
     ```bash
     sudo snap install eclipse --classic
     ```
   - Starte Eclipse:
     ```bash
     eclipse
     ```
   - Wähle einen Workspace (z. B. `~/eclipse-workspace`) und starte die IDE.
3. **Schritt 3**: Konfiguriere die Java-Umgebung in Eclipse.
   - Gehe zu **Window** > **Preferences** > **Java** > **Installed JREs**.
   - Stelle sicher, dass OpenJDK 17 (z. B. `/usr/lib/jvm/java-17-openjdk-amd64`) ausgewählt ist.
4. **Schritt 4**: Erstelle ein erstes Java-Projekt.
   - In Eclipse: **File** > **New** > **Java Project**.
   - Projektname: `HelloWorldProject`.
   - Klicke auf **Finish**.
   - Erstelle eine neue Klasse: Rechtsklick auf `src` > **New** > **Class**.
   - Name: `HelloWorld`, aktiviere `public static void main(String[] args)`.
   - Füge folgenden Code ein:
   ```java
   public class HelloWorld {
       public static void main(String[] args) {
           System.out.println("Hallo aus Eclipse!");
       }
   }
   ```
   - Führe das Programm aus: Rechtsklick auf `HelloWorld.java` > **Run As** > **Java Application**.
   - Die Ausgabe in der Eclipse-Konsole sollte sein: `Hallo aus Eclipse!`.

**Reflexion**: Warum erleichtert Eclipse die Java-Entwicklung im Vergleich zur Kommandozeile, und welche Rolle spielt das JDK?

### Übung 2: Variablen und Schleifen in Eclipse
**Ziel**: Verstehen, wie man Variablen und Schleifen in einem Eclipse-Projekt verwendet, um einfache Berechnungen durchzuführen.

1. **Schritt 1**: Erstelle ein neues Projekt in Eclipse.
   - **File** > **New** > **Java Project**, Name: `CalculatorProject`.
   - Erstelle eine neue Klasse: Rechtsklick auf `src` > **New** > **Class**, Name: `SumCalculator`, aktiviere `main`-Methode.
   - Füge folgenden Code ein:
   ```java
   public class SumCalculator {
       public static void main(String[] args) {
           int start = 1;
           int end = 10;
           int sum = 0;

           for (int i = start; i <= end; i++) {
               sum += i;
           }

           System.out.println("Die Summe von " + start + " bis " + end + " ist: " + sum);
       }
   }
   ```
2. **Schritt 2**: Führe das Programm aus.
   - Rechtsklick auf `SumCalculator.java` > **Run As** > **Java Application**.
   - Die Ausgabe in der Konsole sollte sein: `Die Summe von 1 bis 10 ist: 55`.
3. **Schritt 3**: Erweitere das Programm um Benutzereingaben.
   - Erstelle eine neue Klasse: `SumCalculatorInput`.
   - Füge folgenden Code ein:
   ```java
   import java.util.Scanner;

   public class SumCalculatorInput {
       public static void main(String[] args) {
           Scanner scanner = new Scanner(System.in);

           System.out.print("Geben Sie die Startzahl ein: ");
           int start = scanner.nextInt();
           System.out.print("Geben Sie die Endzahl ein: ");
           int end = scanner.nextInt();

           int sum = 0;
           for (int i = start; i <= end; i++) {
               sum += i;
           }

           System.out.println("Die Summe von " + start + " bis " + end + " ist: " + sum);

           scanner.close();
       }
   }
   ```
   - Führe das Programm aus: Rechtsklick > **Run As** > **Java Application**.
   - Gib z. B. `1` und `5` in der Konsole ein; die Ausgabe sollte sein: `Die Summe von 1 bis 5 ist: 15`.

**Reflexion**: Wie hilft die Autovervollständigung in Eclipse bei der Eingabe von Klassen wie `Scanner`, und warum ist es wichtig, den `Scanner` zu schließen?

### Übung 3: Debugging in Eclipse
**Ziel**: Lernen, wie man den Eclipse-Debugger verwendet, um Fehler in einem Java-Programm zu finden.

1. **Schritt 1**: Erstelle ein Programm mit einem potenziellen Fehler.
   - In `CalculatorProject`, erstelle eine neue Klasse: `AverageCalculator`.
   - Füge folgenden Code ein:
   ```java
   public class AverageCalculator {
       public static void main(String[] args) {
           int[] numbers = {10, 20, 30, 40, 50};
           int sum = 0;

           for (int i = 0; i <= numbers.length; i++) { // Fehler: <= führt zu ArrayIndexOutOfBoundsException
               sum += numbers[i];
           }

           double average = sum / numbers.length;
           System.out.println("Durchschnitt: " + average);
       }
   }
   ```
2. **Schritt 2**: Setze einen Breakpoint und starte den Debugger.
   - Doppelklicke in der linken Spalte von Eclipse auf Zeile `sum += numbers[i];`, um einen Breakpoint zu setzen (blauer Punkt erscheint).
   - Rechtsklick auf `AverageCalculator.java` > **Debug As** > **Java Application**.
   - Eclipse wechselt zur Debug-Perspektive. Der Code hält am Breakpoint.
   - Nutze **Step Over (F6)**, um den Code Zeile für Zeile auszuführen.
   - Beobachte die Variable `i` im **Variables**-Fenster: Bei `i = 5` tritt eine `ArrayIndexOutOfBoundsException` auf.
3. **Schritt 3**: Behebe den Fehler und teste erneut.
   - Ändere die Schleifenbedingung zu `i < numbers.length`:
   ```java
   public class AverageCalculator {
       public static void main(String[] args) {
           int[] numbers = {10, 20, 30, 40, 50};
           int sum = 0;

           for (int i = 0; i < numbers.length; i++) {
               sum += numbers[i];
           }

           double average = (double) sum / numbers.length;
           System.out.println("Durchschnitt: " + average);
       }
   }
   ```
   - Führe das Programm aus: Rechtsklick > **Run As** > **Java Application**.
   - Die Ausgabe sollte sein: `Durchschnitt: 30.0`.

**Reflexion**: Wie hilft der Eclipse-Debugger, Fehler wie `ArrayIndexOutOfBoundsException` zu finden, und warum ist die Debug-Perspektive nützlich?

## Tipps für den Erfolg
- Nutze die Eclipse-Autovervollständigung (Strg+Leerzeichen) für schnelleres Codieren.
- Verwende **Ctrl+Shift+O**, um Imports automatisch zu organisieren.
- Speichere regelmäßig (Strg+S), da Eclipse nicht automatisch speichert.
- Erkunde die **Package Explorer**-Ansicht, um die Projektstruktur zu verstehen.
- Teste kleine Programme, bevor du komplexere Logik implementierst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Java und Eclipse auf einem Debian-System installieren, ein einfaches Java-Projekt erstellen und den Eclipse-Debugger verwenden. Durch die Übungen haben Sie praktische Erfahrung mit grundlegenden Java-Konzepten und der Eclipse-IDE gesammelt. Diese Fähigkeiten sind die Grundlage für die Java-Entwicklung mit einer professionellen IDE. Üben Sie weiter, um fortgeschrittene Themen wie Maven-Integration oder Unit-Tests in Eclipse zu meistern!

**Nächste Schritte**:
- Integrieren Sie Maven in Eclipse für die Verwaltung größerer Projekte.
- Erkunden Sie Eclipse-Plugins (z. B. für Git oder JUnit).
- Lernen Sie fortgeschrittene Java-Konzepte wie Vererbung oder Lambda-Ausdrücke.

**Quellen**:
- Offizielle Eclipse-Dokumentation: https://www.eclipse.org/documentation/
- Oracle Java Tutorials: https://docs.oracle.com/javase/tutorial/
- DigitalOcean Java-Installation: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian
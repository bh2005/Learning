# Praxisorientierte Anleitung: Erkundung fortgeschrittener Java-Konzepte – Lambda-Ausdrücke, Streams und Enums auf Debian

## Einführung
Java hat sich mit modernen Konzepten wie **Lambda-Ausdrücke**, **Streams** und **Enums** weiterentwickelt, um funktionale Programmierung, effiziente Datenverarbeitung und strukturierte Konstanten zu ermöglichen. **Lambda-Ausdrücke** bieten eine prägnante Syntax für funktionale Schnittstellen, **Streams** vereinfachen die Verarbeitung von Datenkollektionen, und **Enums** definieren benannte Konstanten mit zusätzlicher Funktionalität. Diese Anleitung zeigt, wie Sie diese Konzepte in Java auf einem Debian-System anwenden. Ziel ist es, Lernenden mit Grundkenntnissen die Fähigkeiten zu vermitteln, moderne Java-Programme zu schreiben. Diese Anleitung ist ideal für Anfänger, die ihre Java-Kenntnisse vertiefen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (z. B. OpenJDK 11 oder höher, wie in der vorherigen Java-Anleitung)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Java (z. B. Klassen, Interfaces, Generics)
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA Community Edition)

## Grundlegende Java-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Lambda-Ausdrücke**:
   - Kompakte Syntax für funktionale Interfaces (mit einer abstrakten Methode)
   - Syntax: `(Parameter) -> Ausdruck` oder `(Parameter) -> { Anweisungen; }`
   - Beispiel: `(x, y) -> x + y` für eine Addition
2. **Streams**:
   - API zur funktionalen Verarbeitung von Datenkollektionen (z. B. Listen)
   - Operationen: `filter`, `map`, `reduce`, `collect`
   - Ermöglicht deklarative Datenverarbeitung
3. **Enums**:
   - Spezielle Klassen zur Definition benannter Konstanten
   - Können Felder, Konstruktoren und Methoden enthalten
   - Beispiel: `enum Day { MONDAY, TUESDAY, ... }`
4. **Wichtige Befehle**:
   - `javac`: Kompiliert Java-Quellcode
   - `java`: Führt Java-Programme aus

## Übungen zum Verinnerlichen

### Übung 1: Lambda-Ausdrücke verwenden
**Ziel**: Verstehen, wie man Lambda-Ausdrücke für funktionale Programmierung einsetzt.

1. **Schritt 1**: Erstelle ein Programm mit Lambda-Ausdrücken für einfache Operationen.
   ```bash
   nano LambdaDemo.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.function.Function;

   public class LambdaDemo {
       public static void main(String[] args) {
           // Lambda für Addition
           Function<Integer, Integer> square = x -> x * x;

           // Lambda für Großschreibung
           Function<String, String> toUpper = s -> s.toUpperCase();

           // Teste Lambdas
           System.out.println("Quadrat von 5: " + square.apply(5));
           System.out.println("Großschreibung: " + toUpper.apply("Hallo"));

           // Lambda in einer Liste
           java.util.List<String> names = java.util.Arrays.asList("Anna", "Bob", "Charlie");
           names.forEach(name -> System.out.println("Name: " + name));
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac LambdaDemo.java
   java LambdaDemo
   ```
   Die Ausgabe sollte sein:
   ```
   Quadrat von 5: 25
   Großschreibung: HALLO
   Name: Anna
   Name: Bob
   Name: Charlie
   ```
3. **Schritt 3**: Erstelle ein benutzerdefiniertes funktionales Interface mit Lambda.
   ```bash
   nano LambdaCustom.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   @FunctionalInterface
   interface MathOperation {
       int operate(int a, int b);
   }

   public class LambdaCustom {
       public static void main(String[] args) {
           // Lambda für Addition
           MathOperation addition = (a, b) -> a + b;

           // Lambda für Multiplikation
           MathOperation multiplication = (a, b) -> a * b;

           // Teste Operationen
           System.out.println("Addition: 3 + 4 = " + addition.operate(3, 4));
           System.out.println("Multiplikation: 3 * 4 = " + multiplication.operate(3, 4));
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac LambdaCustom.java
   java LambdaCustom
   ```
   Die Ausgabe sollte sein:
   ```
   Addition: 3 + 4 = 7
   Multiplikation: 3 * 4 = 12
   ```

**Reflexion**: Wie vereinfachen Lambda-Ausdrücke die Implementierung funktionaler Interfaces, und wann sind sie gegenüber anonymen Klassen vorzuziehen?

### Übung 2: Streams für Datenverarbeitung
**Ziel**: Lernen, wie man die Stream-API verwendet, um Datenkollektionen effizient zu verarbeiten.

1. **Schritt 1**: Erstelle ein Programm, das eine Liste mit Streams filtert und transformiert.
   ```bash
   nano StreamDemo.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.Arrays;
   import java.util.List;
   import java.util.stream.Collectors;

   public class StreamDemo {
       public static void main(String[] args) {
           List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

           // Filtere gerade Zahlen und verdopple sie
           List<Integer> evenDoubled = numbers.stream()
               .filter(n -> n % 2 == 0) // Nur gerade Zahlen
               .map(n -> n * 2)         // Verdopple
               .collect(Collectors.toList());

           // Ausgabe
           System.out.println("Gerade Zahlen, verdoppelt: " + evenDoubled);

           // Berechne Summe
           int sum = numbers.stream()
               .reduce(0, (a, b) -> a + b);
           System.out.println("Summe aller Zahlen: " + sum);
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac StreamDemo.java
   java StreamDemo
   ```
   Die Ausgabe sollte sein:
   ```
   Gerade Zahlen, verdoppelt: [4, 8, 12, 16, 20]
   Summe aller Zahlen: 55
   ```
3. **Schritt 3**: Erweitere das Programm um eine komplexere Stream-Verarbeitung.
   ```bash
   nano StreamAdvanced.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.Arrays;
   import java.util.List;
   import java.util.stream.Collectors;

   public class StreamAdvanced {
       public static void main(String[] args) {
           List<String> names = Arrays.asList("Anna", "Bob", "Charlie", "David", "Eve");

           // Filtere Namen mit mehr als 3 Zeichen, konvertiere zu Großbuchstaben
           List<String> filteredNames = names.stream()
               .filter(name -> name.length() > 3)
               .map(String::toUpperCase) // Methodenreferenz
               .sorted()
               .collect(Collectors.toList());

           // Ausgabe
           System.out.println("Gefilterte und sortierte Namen: " + filteredNames);

           // Zähle lange Namen
           long count = names.stream()
               .filter(name -> name.length() > 3)
               .count();
           System.out.println("Anzahl langer Namen: " + count);
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac StreamAdvanced.java
   java StreamAdvanced
   ```
   Die Ausgabe sollte sein:
   ```
   Gefilterte und sortierte Namen: [CHARLIE, DAVID]
   Anzahl langer Namen: 2
   ```

**Reflexion**: Wie erleichtert die Stream-API die Datenverarbeitung im Vergleich zu traditionellen Schleifen, und warum ist die deklarative Programmierung nützlich?

### Übung 3: Enums definieren und verwenden
**Ziel**: Verstehen, wie man Enums erstellt und erweitert, um strukturierte Konstanten zu nutzen.

1. **Schritt 1**: Erstelle ein einfaches Enum für Wochentage.
   ```bash
   nano Day.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public enum Day {
       MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
   }

   class DayDemo {
       public static void main(String[] args) {
           // Enum-Werte verwenden
           Day today = Day.TUESDAY;
           System.out.println("Heute ist: " + today);

           // Alle Enum-Werte ausgeben
           System.out.println("Alle Tage:");
           for (Day day : Day.values()) {
               System.out.println(day);
           }
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac Day.java
   java DayDemo
   ```
   Die Ausgabe sollte sein:
   ```
   Heute ist: TUESDAY
   Alle Tage:
   MONDAY
   TUESDAY
   WEDNESDAY
   THURSDAY
   FRIDAY
   SATURDAY
   SUNDAY
   ```
3. **Schritt 3**: Erstelle ein erweitertes Enum mit Feldern und Methoden.
   ```bash
   nano WorkSchedule.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public enum WorkSchedule {
       MONDAY("Arbeitstag", 8),
       TUESDAY("Arbeitstag", 8),
       WEDNESDAY("Arbeitstag", 8),
       THURSDAY("Arbeitstag", 8),
       FRIDAY("Arbeitstag", 6),
       SATURDAY("Frei", 0),
       SUNDAY("Frei", 0);

       private final String type;
       private final int hours;

       WorkSchedule(String type, int hours) {
           this.type = type;
           this.hours = hours;
       }

       public String getType() {
           return type;
       }

       public int getHours() {
           return hours;
       }

       public static void main(String[] args) {
           // Teste Enum
           WorkSchedule today = WorkSchedule.TUESDAY;
           System.out.println("Heute: " + today + ", Typ: " + today.getType() + ", Stunden: " + today.getHours());

           // Ausgabe aller Tage mit Stream
           System.out.println("\nArbeitsplan:");
           java.util.Arrays.stream(WorkSchedule.values())
               .filter(day -> day.getHours() > 0)
               .forEach(day -> System.out.println(day + ": " + day.getType() + ", " + day.getHours() + " Stunden"));
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac WorkSchedule.java
   java WorkSchedule
   ```
   Die Ausgabe sollte sein:
   ```
   Heute: TUESDAY, Typ: Arbeitstag, Stunden: 8

   Arbeitsplan:
   MONDAY: Arbeitstag, 8 Stunden
   TUESDAY: Arbeitstag, 8 Stunden
   WEDNESDAY: Arbeitstag, 8 Stunden
   THURSDAY: Arbeitstag, 8 Stunden
   FRIDAY: Arbeitstag, 6 Stunden
   ```

**Reflexion**: Warum sind Enums besser als einfache Konstanten, und wie können sie mit Streams kombiniert werden, um Daten zu verarbeiten?

## Tipps für den Erfolg
- Überprüfe die Ausgabe von `javac`, um Syntaxfehler zu finden.
- Verwende `System.out.println` für Debugging, um Stream-Ergebnisse oder Enum-Werte zu inspizieren.
- Stelle sicher, dass der Dateiname mit dem Klassennamen oder Enum-Namen übereinstimmt (z. B. `WorkSchedule.java` für `public enum WorkSchedule`).
- Teste mit kleinen Beispielen, bevor du komplexere Streams oder Lambdas schreibst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Lambda-Ausdrücke, Streams und Enums in Java auf einem Debian-System anwenden. Durch die Übungen haben Sie praktische Erfahrung mit funktionaler Programmierung, deklarativer Datenverarbeitung und strukturierten Konstanten gesammelt. Diese Fähigkeiten sind essenziell für moderne Java-Entwicklung. Üben Sie weiter, um fortgeschrittene Themen wie Multithreading oder die Java Module System zu meistern!

**Nächste Schritte**:
- Erkunden Sie Java-Konzepte wie Multithreading, Concurrency oder das Java Module System.
- Integrieren Sie Java mit Maven, um größere Projekte mit Abhängigkeiten zu verwalten.
- Verwenden Sie eine IDE wie IntelliJ IDEA, um die Entwicklung mit Autovervollständigung und Debugging zu vereinfachen.

**Quellen**:
- Offizielle Java-Dokumentation: https://docs.oracle.com/en/java/
- Oracle Java Tutorials (Lambda Expressions): https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html
- Oracle Java Tutorials (Streams): https://docs.oracle.com/javase/tutorial/collections/streams/
- Oracle Java Tutorials (Enums): https://docs.oracle.com/javase/tutorial/java/javaOO/enum.html
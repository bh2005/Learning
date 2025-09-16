# Praxisorientierte Anleitung: Erkundung von Java-Konzepten – Arrays, Methodenüberladung und Exception-Handling auf Debian

## Einführung
Java ist eine leistungsstarke Programmiersprache, die fortgeschrittene Konzepte wie **Arrays**, **Methodenüberladung** und **Exception-Handling** bietet, um strukturierte, flexible und robuste Programme zu entwickeln. **Arrays** ermöglichen die Speicherung mehrerer Werte in einer einzigen Variable, **Methodenüberladung** erlaubt mehrere Methoden mit demselben Namen, aber unterschiedlichen Parametern, und **Exception-Handling** hilft, Fehler zu behandeln, ohne dass Programme abstürzen. Diese Anleitung zeigt, wie Sie diese Konzepte in Java auf einem Debian-System anwenden. Ziel ist es, Anfängern die Fähigkeiten zu vermitteln, komplexere Java-Programme zu schreiben. Diese Anleitung ist ideal für Lernende mit Grundkenntnissen in Java.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (z. B. OpenJDK 11, wie in der vorherigen Java-Anleitung)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Java (z. B. Klassen, Variablen, Schleifen)
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA Community Edition)

## Grundlegende Java-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Arrays**:
   - Ein Array ist eine Datenstruktur, die mehrere Werte desselben Typs speichert
   - Syntax: `int[] array = new int[5];`
   - Zugriff: Über Indizes (beginnend bei 0)
2. **Methodenüberladung**:
   - Mehrere Methoden mit demselben Namen, aber unterschiedlichen Parametern (Anzahl oder Typ)
   - Erhöht die Flexibilität und Lesbarkeit von Code
3. **Exception-Handling**:
   - Verwendung von `try`, `catch`, `finally`, um Fehler abzufangen
   - Exceptions sind z. B. `NullPointerException` oder `ArithmeticException`
4. **Wichtige Befehle**:
   - `javac`: Kompiliert Java-Quellcode
   - `java`: Führt Java-Programme aus

## Übungen zum Verinnerlichen

### Übung 1: Arbeiten mit Arrays
**Ziel**: Verstehen, wie man Arrays erstellt, füllt und manipuliert, um Daten zu verarbeiten.

1. **Schritt 1**: Erstelle ein Programm, das ein Array verwendet, um Noten zu speichern und den Durchschnitt zu berechnen.
   ```bash
   nano GradeCalculator.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class GradeCalculator {
       public static void main(String[] args) {
           // Array für Noten
           double[] grades = new double[5];

           // Array befüllen
           grades[0] = 1.0;
           grades[1] = 2.3;
           grades[2] = 1.7;
           grades[3] = 3.0;
           grades[4] = 2.0;

           // Summe und Durchschnitt berechnen
           double sum = 0;
           for (int i = 0; i < grades.length; i++) {
               sum += grades[i];
           }
           double average = sum / grades.length;

           // Ausgabe
           System.out.println("Noten: ");
           for (double grade : grades) {
               System.out.print(grade + " ");
           }
           System.out.printf("\nDurchschnitt: %.2f\n", average);
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac GradeCalculator.java
   java GradeCalculator
   ```
   Die Ausgabe sollte sein:
   ```
   Noten: 
   1.0 2.3 1.7 3.0 2.0 
   Durchschnitt: 2.00
   ```
3. **Schritt 3**: Erweitere das Programm um Benutzereingaben.
   ```bash
   nano GradeCalculatorInput.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.Scanner;

   public class GradeCalculatorInput {
       public static void main(String[] args) {
           Scanner scanner = new Scanner(System.in);

           // Array-Größe festlegen
           System.out.print("Wie viele Noten möchten Sie eingeben? ");
           int size = scanner.nextInt();
           double[] grades = new double[size];

           // Array befüllen
           for (int i = 0; i < size; i++) {
               System.out.print("Geben Sie Note " + (i + 1) + " ein: ");
               grades[i] = scanner.nextDouble();
           }

           // Summe und Durchschnitt berechnen
           double sum = 0;
           for (double grade : grades) {
               sum += grade;
           }
           double average = sum / grades.length;

           // Ausgabe
           System.out.println("Noten: ");
           for (double grade : grades) {
               System.out.print(grade + " ");
           }
           System.out.printf("\nDurchschnitt: %.2f\n", average);

           scanner.close();
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac GradeCalculatorInput.java
   java GradeCalculatorInput
   ```
   Beispiel-Eingabe: `3`, `1.5`, `2.0`, `3.0`. Ausgabe:
   ```
   Noten: 
   1.5 2.0 3.0 
   Durchschnitt: 2.17
   ```

**Reflexion**: Warum sind Arrays nützlich für die Speicherung mehrerer Werte, und wie unterscheidet sich die `for-each`-Schleife von einer normalen `for`-Schleife?

### Übung 2: Methodenüberladung implementieren
**Ziel**: Verstehen, wie man Methoden überlädt, um flexiblere Programme zu schreiben.

1. **Schritt 1**: Erstelle ein Programm mit überladenen Methoden für Berechnungen.
   ```bash
   nano Calculator.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Calculator {
       // Methode 1: Addiere zwei Ganzzahlen
       public int add(int a, int b) {
           return a + b;
       }

       // Methode 2: Addiere drei Ganzzahlen
       public int add(int a, int b, int c) {
           return a + b + c;
       }

       // Methode 3: Addiere zwei Gleitkommazahlen
       public double add(double a, double b) {
           return a + b;
       }

       public static void main(String[] args) {
           Calculator calc = new Calculator();

           // Teste überladene Methoden
           System.out.println("Summe von 2 + 3: " + calc.add(2, 3));
           System.out.println("Summe von 2 + 3 + 4: " + calc.add(2, 3, 4));
           System.out.println("Summe von 2.5 + 3.7: " + calc.add(2.5, 3.7));
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac Calculator.java
   java Calculator
   ```
   Die Ausgabe sollte sein:
   ```
   Summe von 2 + 3: 5
   Summe von 2 + 3 + 4: 9
   Summe von 2.5 + 3.7: 6.2
   ```
3. **Schritt 3**: Erweitere das Programm um eine weitere überladene Methode.
   ```bash
   nano Calculator.java
   ```
   Füge eine Methode hinzu, die ein Array von Ganzzahlen addiert:
   ```java
   public class Calculator {
       public int add(int a, int b) {
           return a + b;
       }

       public int add(int a, int b, int c) {
           return a + b + c;
       }

       public double add(double a, double b) {
           return a + b;
       }

       // Neue überladene Methode
       public int add(int[] numbers) {
           int sum = 0;
           for (int num : numbers) {
               sum += num;
           }
           return sum;
       }

       public static void main(String[] args) {
           Calculator calc = new Calculator();

           // Teste überladene Methoden
           System.out.println("Summe von 2 + 3: " + calc.add(2, 3));
           System.out.println("Summe von 2 + 3 + 4: " + calc.add(2, 3, 4));
           System.out.println("Summe von 2.5 + 3.7: " + calc.add(2.5, 3.7));
           int[] array = {1, 2, 3, 4};
           System.out.println("Summe des Arrays: " + calc.add(array));
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac Calculator.java
   java Calculator
   ```
   Die Ausgabe sollte sein:
   ```
   Summe von 2 + 3: 5
   Summe von 2 + 3 + 4: 9
   Summe von 2.5 + 3.7: 6.2
   Summe des Arrays: 10
   ```

**Reflexion**: Wie verbessert Methodenüberladung die Lesbarkeit und Wiederverwendbarkeit von Code, und wie wählt Java die richtige Methode basierend auf den Parametern aus?

### Übung 3: Exception-Handling implementieren
**Ziel**: Lernen, wie man Exceptions abfängt, um Programme robuster zu machen.

1. **Schritt 1**: Erstelle ein Programm, das eine Exception behandelt.
   ```bash
   nano DivideNumbers.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.Scanner;

   public class DivideNumbers {
       public static void main(String[] args) {
           Scanner scanner = new Scanner(System.in);

           try {
               System.out.print("Geben Sie den Zähler ein: ");
               int numerator = scanner.nextInt();
               System.out.print("Geben Sie den Nenner ein: ");
               int denominator = scanner.nextInt();

               int result = numerator / denominator;
               System.out.println("Ergebnis: " + result);
           } catch (ArithmeticException e) {
               System.out.println("Fehler: Division durch Null ist nicht erlaubt!");
           } catch (Exception e) {
               System.out.println("Ein anderer Fehler ist aufgetreten: " + e.getMessage());
           } finally {
               System.out.println("Programm beendet.");
               scanner.close();
           }
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac DivideNumbers.java
   java DivideNumbers
   ```
   Teste mit Eingaben:
   - Normal: `10`, `2` → `Ergebnis: 5`, `Programm beendet.`
   - Fehler: `10`, `0` → `Fehler: Division durch Null ist nicht erlaubt!`, `Programm beendet.`
3. **Schritt 3**: Erweitere das Programm um eine benutzerdefinierte Exception.
   ```bash
   nano DivideNumbersAdvanced.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.Scanner;

   // Benutzerdefinierte Exception
   class NegativeNumberException extends Exception {
       public NegativeNumberException(String message) {
           super(message);
       }
   }

   public class DivideNumbersAdvanced {
       public static void divide(int numerator, int denominator) throws NegativeNumberException {
           if (numerator < 0 || denominator < 0) {
               throw new NegativeNumberException("Negative Zahlen sind nicht erlaubt!");
           }
           System.out.println("Ergebnis: " + (numerator / denominator));
       }

       public static void main(String[] args) {
           Scanner scanner = new Scanner(System.in);

           try {
               System.out.print("Geben Sie den Zähler ein: ");
               int numerator = scanner.nextInt();
               System.out.print("Geben Sie den Nenner ein: ");
               int denominator = scanner.nextInt();

               divide(numerator, denominator);
           } catch (NegativeNumberException e) {
               System.out.println("Fehler: " + e.getMessage());
           } catch (ArithmeticException e) {
               System.out.println("Fehler: Division durch Null ist nicht erlaubt!");
           } catch (Exception e) {
               System.out.println("Ein anderer Fehler ist aufgetreten: " + e.getMessage());
           } finally {
               System.out.println("Programm beendet.");
               scanner.close();
           }
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac DivideNumbersAdvanced.java
   java DivideNumbersAdvanced
   ```
   Teste mit Eingaben:
   - Normal: `10`, `2` → `Ergebnis: 5`, `Programm beendet.`
   - Fehler: `10`, `0` → `Fehler: Division durch Null ist nicht erlaubt!`, `Programm beendet.`
   - Fehler: `-10`, `2` → `Fehler: Negative Zahlen sind nicht erlaubt!`, `Programm beendet.`

**Reflexion**: Warum ist Exception-Handling wichtig für die Robustheit eines Programms, und wie hilft `finally`, Ressourcen wie Scanner sauber zu schließen?

## Tipps für den Erfolg
- Überprüfe die Ausgabe von `javac`, um Syntaxfehler zu finden.
- Verwende `System.out.println` für Debugging, um Array-Inhalte oder Exceptions zu inspizieren.
- Stelle sicher, dass der Dateiname mit dem Klassennamen übereinstimmt (z. B. `Calculator.java` für `public class Calculator`).
- Teste mit kleinen Eingaben, bevor du komplexere Programme schreibst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Arrays, Methodenüberladung und Exception-Handling in Java auf einem Debian-System anwenden. Durch die Übungen haben Sie praktische Erfahrung mit der Speicherung und Verarbeitung von Daten, der Erstellung flexibler Methoden und der Behandlung von Fehlern gesammelt. Diese Fähigkeiten sind essenziell für die Entwicklung robuster Java-Programme. Üben Sie weiter, um fortgeschrittene Konzepte wie Vererbung oder Generics zu meistern!

**Nächste Schritte**:
- Erkunden Sie weitere Java-Konzepte wie Vererbung, Interfaces oder Generics.
- Integrieren Sie Java mit Maven, um Abhängigkeiten zu verwalten.
- Verwenden Sie eine IDE wie IntelliJ IDEA, um die Entwicklung zu vereinfachen.

**Quellen**:
- Offizielle Java-Dokumentation: https://docs.oracle.com/en/java/
- Oracle Java Tutorials (Arrays): https://docs.oracle.com/javase/tutorial/java/nutsandbolts/arrays.html
- Oracle Java Tutorials (Exceptions): https://docs.oracle.com/javase/tutorial/essential/exceptions/
- DigitalOcean Java-Installation: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian
# Praxisorientierte Anleitung: Einstieg in Java für Anfänger auf Debian

## Einführung
Java ist eine weit verbreitete, objektorientierte Programmiersprache, die für ihre Plattformunabhängigkeit und Vielseitigkeit bekannt ist. Sie wird in Webanwendungen, mobilen Apps und Big-Data-Tools wie Apache Spark eingesetzt. Diese Anleitung führt Anfänger in die Installation von Java auf einem Debian-System ein und zeigt, wie man einfache Programme schreibt, die grundlegende Konzepte wie Variablen, Schleifen und Klassen verwenden. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, erste Java-Programme zu entwickeln und die Grundlagen der Programmierung zu verstehen. Diese Anleitung ist ideal für Anfänger ohne Programmiererfahrung, die Java lernen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA Community Edition)

## Grundlegende Java-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Java-Konzepte**:
   - **JDK (Java Development Kit)**: Enthält Tools wie `javac` (Compiler) und `java` (Runtime)
   - **Klassen und Objekte**: Grundbausteine der objektorientierten Programmierung
   - **Variablen**: Speicherorte für Daten (z. B. `int`, `String`)
   - **Schleifen**: Wiederholung von Code (z. B. `for`, `while`)
2. **Wichtige Befehle**:
   - `javac`: Kompiliert Java-Quellcode in Bytecode
   - `java`: Führt Java-Programme aus
   - `apt`: Installiert Java auf Debian
3. **Wichtige Dateien**:
   - `.java`: Quellcode-Dateien
   - `.class`: Kompilierte Bytecode-Dateien

## Übungen zum Verinnerlichen

### Übung 1: Java installieren und konfigurieren
**Ziel**: Lernen, wie man das Java Development Kit (JDK) auf einem Debian-System installiert und eine einfache Entwicklungsumgebung einrichtet.

1. **Schritt 1**: Installiere das OpenJDK 11.
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   ```
2. **Schritt 2**: Überprüfe die Java-Installation.
   ```bash
   java -version
   javac -version
   ```
   Die Ausgabe sollte die Version von Java (z. B. OpenJDK 11) anzeigen.
3. **Schritt 3**: Konfiguriere die Umgebungsvariable `JAVA_HOME`.
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende folgende Zeile hinzu:
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```
   Aktiviere die Änderungen:
   ```bash
   source ~/.bashrc
   echo $JAVA_HOME
   ```
4. **Schritt 4**: Teste die Entwicklungsumgebung mit einem einfachen Programm.
   ```bash
   nano HelloWorld.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class HelloWorld {
       public static void main(String[] args) {
           System.out.println("Hallo, Welt!");
       }
   }
   ```
   Kompiliere und führe das Programm aus:
   ```bash
   javac HelloWorld.java
   java HelloWorld
   ```
   Die Ausgabe sollte sein: `Hallo, Welt!`.

**Reflexion**: Warum ist das JDK für die Java-Entwicklung notwendig, und was bedeutet die `main`-Methode in einem Java-Programm?

### Übung 2: Variablen und Schleifen in Java verwenden
**Ziel**: Verstehen, wie man Variablen und Schleifen verwendet, um einfache Berechnungen durchzuführen.

1. **Schritt 1**: Erstelle ein Programm mit Variablen und einer Schleife.
   ```bash
   nano SumCalculator.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class SumCalculator {
       public static void main(String[] args) {
           // Variablen
           int start = 1;
           int end = 10;
           int sum = 0;

           // For-Schleife zur Summenberechnung
           for (int i = start; i <= end; i++) {
               sum += i;
           }

           // Ausgabe
           System.out.println("Die Summe von " + start + " bis " + end + " ist: " + sum);
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac SumCalculator.java
   java SumCalculator
   ```
   Die Ausgabe sollte sein: `Die Summe von 1 bis 10 ist: 55`.
3. **Schritt 3**: Modifiziere das Programm, um Benutzereingaben zu akzeptieren.
   ```bash
   nano SumCalculatorInput.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.Scanner;

   public class SumCalculatorInput {
       public static void main(String[] args) {
           // Scanner für Benutzereingaben
           Scanner scanner = new Scanner(System.in);
           System.out.print("Geben Sie die Startzahl ein: ");
           int start = scanner.nextInt();
           System.out.print("Geben Sie die Endzahl ein: ");
           int end = scanner.nextInt();

           // Summe berechnen
           int sum = 0;
           for (int i = start; i <= end; i++) {
               sum += i;
           }

           // Ausgabe
           System.out.println("Die Summe von " + start + " bis " + end + " ist: " + sum);

           // Scanner schließen
           scanner.close();
       }
   }
   ```
   Kompiliere und führe das Programm aus:
   ```bash
   javac SumCalculatorInput.java
   java SumCalculatorInput
   ```
   Gib z. B. `1` und `5` ein; die Ausgabe sollte sein: `Die Summe von 1 bis 5 ist: 15`.

**Reflexion**: Wie helfen Variablen und Schleifen, Programme flexibler zu gestalten, und warum ist es wichtig, den `Scanner` zu schließen?

### Übung 3: Klassen und Objekte erstellen
**Ziel**: Lernen, wie man Klassen und Objekte definiert, um strukturierte Programme zu schreiben.

1. **Schritt 1**: Erstelle eine Klasse für ein einfaches Objekt (z. B. ein Auto).
   ```bash
   nano Car.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Car {
       // Instanzvariablen
       String brand;
       int speed;

       // Konstruktor
       public Car(String brand, int speed) {
           this.brand = brand;
           this.speed = speed;
       }

       // Methode
       public void displayInfo() {
           System.out.println("Auto: " + brand + ", Geschwindigkeit: " + speed + " km/h");
       }

       // Hauptmethode
       public static void main(String[] args) {
           // Objekte erstellen
           Car car1 = new Car("BMW", 200);
           Car car2 = new Car("Tesla", 250);

           // Methoden aufrufen
           car1.displayInfo();
           car2.displayInfo();
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac Car.java
   java Car
   ```
   Die Ausgabe sollte sein:
   ```
   Auto: BMW, Geschwindigkeit: 200 km/h
   Auto: Tesla, Geschwindigkeit: 250 km/h
   ```
3. **Schritt 3**: Erweitere die Klasse um eine Methode.
   ```bash
   nano Car.java
   ```
   Füge eine Methode `accelerate` hinzu:
   ```java
   public class Car {
       String brand;
       int speed;

       public Car(String brand, int speed) {
           this.brand = brand;
           this.speed = speed;
       }

       public void displayInfo() {
           System.out.println("Auto: " + brand + ", Geschwindigkeit: " + speed + " km/h");
       }

       public void accelerate(int increase) {
           speed += increase;
           System.out.println(brand + " beschleunigt auf " + speed + " km/h");
       }

       public static void main(String[] args) {
           Car car = new Car("BMW", 200);
           car.displayInfo();
           car.accelerate(20);
           car.displayInfo();
       }
   }
   ```
   Kompiliere und führe erneut aus:
   ```bash
   javac Car.java
   java Car
   ```
   Die Ausgabe sollte sein:
   ```
   Auto: BMW, Geschwindigkeit: 200 km/h
   BMW beschleunigt auf 220 km/h
   Auto: BMW, Geschwindigkeit: 220 km/h
   ```

**Reflexion**: Warum sind Klassen und Objekte zentral für die objektorientierte Programmierung, und wie hilft der Konstruktor bei der Initialisierung?

## Tipps für den Erfolg
- Überprüfe die Ausgabe von `javac`, um Syntaxfehler zu finden.
- Stelle sicher, dass der Dateiname mit dem Klassennamen übereinstimmt (z. B. `HelloWorld.java` für `public class HelloWorld`).
- Verwende `System.out.println` für Debugging, um Variablenwerte zu überprüfen.
- Teste mit kleinen Programmen, bevor du komplexere Logik implementierst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Java auf einem Debian-System installieren, einfache Programme mit Variablen und Schleifen schreiben und Klassen und Objekte verwenden. Durch die Übungen haben Sie praktische Erfahrung mit grundlegenden Java-Konzepten gesammelt. Diese Fähigkeiten sind die Grundlage für die Java-Entwicklung. Üben Sie weiter, um fortgeschrittene Themen wie Methodenüberladung oder Vererbung zu meistern!

**Nächste Schritte**:
- Installieren Sie eine IDE wie IntelliJ IDEA Community Edition für eine bessere Entwicklungserfahrung.
- Erkunden Sie Java-Konzepte wie Arrays, Methodenüberladung oder Exception-Handling.
- Integrieren Sie Java mit Tools wie Maven für Projektmanagement.

**Quellen**:
- Offizielle Java-Dokumentation: https://docs.oracle.com/en/java/
- Oracle Java Tutorials: https://docs.oracle.com/javase/tutorial/
- DigitalOcean Java-Installation: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian
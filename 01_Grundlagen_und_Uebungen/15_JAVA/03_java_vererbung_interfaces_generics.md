# Praxisorientierte Anleitung: Erkundung fortgeschrittener Java-Konzepte – Vererbung, Interfaces und Generics auf Debian

## Einführung
Java ist eine objektorientierte Programmiersprache, die fortgeschrittene Konzepte wie **Vererbung**, **Interfaces** und **Generics** bietet, um strukturierte, wiederverwendbare und typensichere Programme zu entwickeln. **Vererbung** ermöglicht die Wiederverwendung von Code durch Hierarchien, **Interfaces** definieren Verträge für Klassen, und **Generics** sorgen für Typensicherheit bei Collections und Methoden. Diese Anleitung zeigt, wie Sie diese Konzepte in Java auf einem Debian-System anwenden. Ziel ist es, Anfängern mit Grundkenntnissen die Fähigkeiten zu vermitteln, komplexere Java-Programme zu schreiben. Diese Anleitung ist ideal für Lernende, die ihre Java-Kenntnisse vertiefen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (z. B. OpenJDK 11, wie in der vorherigen Java-Anleitung)
- Mindestens 2 GB RAM und ausreichend Festplattenspeicher (mindestens 5 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Java (z. B. Klassen, Methoden, Exception-Handling)
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA Community Edition)

## Grundlegende Java-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Vererbung**:
   - Ermöglicht einer Klasse, Eigenschaften und Methoden einer anderen Klasse zu erben
   - Schlüsselwörter: `extends`, `super`
   - Beispiel: Eine Klasse `Auto` erbt von einer Klasse `Fahrzeug`
2. **Interfaces**:
   - Definieren Methoden, die Klassen implementieren müssen
   - Schlüsselwort: `implements`
   - Ermöglichen Mehrfachvererbung und lose Kopplung
3. **Generics**:
   - Ermöglichen typensichere Klassen und Methoden
   - Syntax: `List<String>` statt `List` (ohne Typ)
   - Vermeiden ClassCastExceptions bei Collections
4. **Wichtige Befehle**:
   - `javac`: Kompiliert Java-Quellcode
   - `java`: Führt Java-Programme aus

## Übungen zum Verinnerlichen

### Übung 1: Vererbung implementieren
**Ziel**: Verstehen, wie man Vererbung verwendet, um Code wiederzuverwenden und Hierarchien zu erstellen.

1. **Schritt 1**: Erstelle eine Basisklasse und eine abgeleitete Klasse.
   ```bash
   nano Vehicle.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Vehicle {
       protected String brand;
       protected int speed;

       public Vehicle(String brand, int speed) {
           this.brand = brand;
           this.speed = speed;
       }

       public void displayInfo() {
           System.out.println("Fahrzeug: " + brand + ", Geschwindigkeit: " + speed + " km/h");
       }
   }
   ```
   Erstelle dann die abgeleitete Klasse:
   ```bash
   nano Car.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Car extends Vehicle {
       private int doors;

       public Car(String brand, int speed, int doors) {
           super(brand, speed); // Ruft den Konstruktor der Basisklasse auf
           this.doors = doors;
       }

       // Überschreibt die Methode der Basisklasse
       @Override
       public void displayInfo() {
           System.out.println("Auto: " + brand + ", Geschwindigkeit: " + speed + " km/h, Türen: " + doors);
       }

       public static void main(String[] args) {
           Vehicle vehicle = new Vehicle("Generic", 100);
           Car car = new Car("BMW", 200, 4);

           vehicle.displayInfo();
           car.displayInfo();
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac Vehicle.java Car.java
   java Car
   ```
   Die Ausgabe sollte sein:
   ```
   Fahrzeug: Generic, Geschwindigkeit: 100 km/h
   Auto: BMW, Geschwindigkeit: 200 km/h, Türen: 4
   ```
3. **Schritt 3**: Erweitere die Hierarchie um eine weitere Klasse.
   ```bash
   nano Motorcycle.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Motorcycle extends Vehicle {
       private boolean hasSidecar;

       public Motorcycle(String brand, int speed, boolean hasSidecar) {
           super(brand, speed);
           this.hasSidecar = hasSidecar;
       }

       @Override
       public void displayInfo() {
           System.out.println("Motorrad: " + brand + ", Geschwindigkeit: " + speed + " km/h, Beiwagen: " + (hasSidecar ? "Ja" : "Nein"));
       }

       public static void main(String[] args) {
           Vehicle vehicle = new Vehicle("Generic", 100);
           Car car = new Car("BMW", 200, 4);
           Motorcycle motorcycle = new Motorcycle("Harley", 150, true);

           vehicle.displayInfo();
           car.displayInfo();
           motorcycle.displayInfo();
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac Vehicle.java Car.java Motorcycle.java
   java Motorcycle
   ```
   Die Ausgabe sollte sein:
   ```
   Fahrzeug: Generic, Geschwindigkeit: 100 km/h
   Auto: BMW, Geschwindigkeit: 200 km/h, Türen: 4
   Motorrad: Harley, Geschwindigkeit: 150 km/h, Beiwagen: Ja
   ```

**Reflexion**: Wie fördert Vererbung die Wiederverwendbarkeit von Code, und warum ist das Schlüsselwort `super` wichtig?

### Übung 2: Interfaces implementieren
**Ziel**: Verstehen, wie man Interfaces definiert und implementiert, um Verträge für Klassen zu erstellen.

1. **Schritt 1**: Erstelle ein Interface und eine Klasse, die es implementiert.
   ```bash
   nano Drivable.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public interface Drivable {
       void drive(int distance);
       void stop();
   }
   ```
   Erstelle eine Klasse, die das Interface implementiert:
   ```bash
   nano Truck.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Truck implements Drivable {
       private String brand;
       private int loadCapacity;

       public Truck(String brand, int loadCapacity) {
           this.brand = brand;
           this.loadCapacity = loadCapacity;
       }

       @Override
       public void drive(int distance) {
           System.out.println(brand + " fährt " + distance + " km.");
       }

       @Override
       public void stop() {
           System.out.println(brand + " hält an.");
       }

       public void displayInfo() {
           System.out.println("LKW: " + brand + ", Ladekapazität: " + loadCapacity + " Tonnen");
       }

       public static void main(String[] args) {
           Truck truck = new Truck("Volvo", 20);
           truck.displayInfo();
           truck.drive(100);
           truck.stop();
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac Drivable.java Truck.java
   java Truck
   ```
   Die Ausgabe sollte sein:
   ```
   LKW: Volvo, Ladekapazität: 20 Tonnen
   Volvo fährt 100 km.
   Volvo hält an.
   ```
3. **Schritt 3**: Kombiniere Vererbung und Interfaces.
   ```bash
   nano Vehicle.java
   ```
   Aktualisiere `Vehicle.java`:
   ```java
   public abstract class Vehicle {
       protected String brand;
       protected int speed;

       public Vehicle(String brand, int speed) {
           this.brand = brand;
           this.speed = speed;
       }

       public abstract void displayInfo();
   }
   ```
   Erstelle eine neue Klasse, die `Vehicle` erbt und `Drivable` implementiert:
   ```bash
   nano Bus.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class Bus extends Vehicle implements Drivable {
       private int seats;

       public Bus(String brand, int speed, int seats) {
           super(brand, speed);
           this.seats = seats;
       }

       @Override
       public void displayInfo() {
           System.out.println("Bus: " + brand + ", Geschwindigkeit: " + speed + " km/h, Sitze: " + seats);
       }

       @Override
       public void drive(int distance) {
           System.out.println(brand + " fährt " + distance + " km.");
       }

       @Override
       public void stop() {
           System.out.println(brand + " hält an.");
       }

       public static void main(String[] args) {
           Bus bus = new Bus("Mercedes", 120, 50);
           bus.displayInfo();
           bus.drive(200);
           bus.stop();
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac Vehicle.java Drivable.java Bus.java
   java Bus
   ```
   Die Ausgabe sollte sein:
   ```
   Bus: Mercedes, Geschwindigkeit: 120 km/h, Sitze: 50
   Mercedes fährt 200 km.
   Mercedes hält an.
   ```

**Reflexion**: Wie fördern Interfaces lose Kopplung, und warum ist es nützlich, Vererbung und Interfaces zu kombinieren?

### Übung 3: Generics verwenden
**Ziel**: Lernen, wie man Generics für typensichere Klassen und Methoden verwendet.

1. **Schritt 1**: Erstelle eine generische Klasse.
   ```bash
   nano GenericBox.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   public class GenericBox<T> {
       private T content;

       public GenericBox(T content) {
           this.content = content;
       }

       public T getContent() {
           return content;
       }

       public void setContent(T content) {
           this.content = content;
       }

       public static void main(String[] args) {
           // Box für String
           GenericBox<String> stringBox = new GenericBox<>("Hallo, Generics!");
           System.out.println("Inhalt der Box: " + stringBox.getContent());

           // Box für Integer
           GenericBox<Integer> intBox = new GenericBox<>(42);
           System.out.println("Inhalt der Box: " + intBox.getContent());
       }
   }
   ```
2. **Schritt 2**: Kompiliere und führe das Programm aus.
   ```bash
   javac GenericBox.java
   java GenericBox
   ```
   Die Ausgabe sollte sein:
   ```
   Inhalt der Box: Hallo, Generics!
   Inhalt der Box: 42
   ```
3. **Schritt 3**: Verwende Generics mit einer Collection und einer generischen Methode.
   ```bash
   nano GenericListDemo.java
   ```
   Füge folgenden Inhalt ein:
   ```java
   import java.util.ArrayList;
   import java.util.List;

   public class GenericListDemo {
       // Generische Methode
       public static <T> void printList(List<T> list) {
           for (T item : list) {
               System.out.println("Element: " + item);
           }
       }

       public static void main(String[] args) {
           // Typensichere Liste für Strings
           List<String> stringList = new ArrayList<>();
           stringList.add("Java");
           stringList.add("Python");
           stringList.add("C++");
           System.out.println("String-Liste:");
           printList(stringList);

           // Typensichere Liste für Integers
           List<Integer> intList = new ArrayList<>();
           intList.add(10);
           intList.add(20);
           intList.add(30);
           System.out.println("\nInteger-Liste:");
           printList(intList);
       }
   }
   ```
   Kompiliere und führe aus:
   ```bash
   javac GenericListDemo.java
   java GenericListDemo
   ```
   Die Ausgabe sollte sein:
   ```
   String-Liste:
   Element: Java
   Element: Python
   Element: C++

   Integer-Liste:
   Element: 10
   Element: 20
   Element: 30
   ```

**Reflexion**: Wie verhindern Generics Laufzeitfehler wie `ClassCastException`, und warum sind sie besonders nützlich bei Collections wie `ArrayList`?

## Tipps für den Erfolg
- Überprüfe die Ausgabe von `javac`, um Syntaxfehler zu finden.
- Verwende `System.out.println` für Debugging, um den Zustand von Objekten oder Listen zu überprüfen.
- Stelle sicher, dass der Dateiname mit dem Klassennamen übereinstimmt (z. B. `Vehicle.java` für `public class Vehicle`).
- Teste mit kleinen Beispielen, bevor du komplexere Hierarchien oder generische Klassen erstellst.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Vererbung, Interfaces und Generics in Java auf einem Debian-System anwenden. Durch die Übungen haben Sie praktische Erfahrung mit Code-Wiederverwendung, Vertragsdefinitionen und typensicherem Programmieren gesammelt. Diese Fähigkeiten sind essenziell für die Entwicklung strukturierter und wartbarer Java-Programme. Üben Sie weiter, um fortgeschrittene Themen wie Lambda-Ausdrücke oder Streams zu meistern!

**Nächste Schritte**:
- Erkunden Sie Java-Konzepte wie Lambda-Ausdrücke, Streams oder Enums.
- Integrieren Sie Java mit Maven, um größere Projekte mit Abhängigkeiten zu verwalten.
- Verwenden Sie eine IDE wie IntelliJ IDEA, um die Entwicklung zu vereinfachen.

**Quellen**:
- Offizielle Java-Dokumentation: https://docs.oracle.com/en/java/
- Oracle Java Tutorials (Inheritance): https://docs.oracle.com/javase/tutorial/java/IandI/subclasses.html
- Oracle Java Tutorials (Interfaces): https://docs.oracle.com/javase/tutorial/java/IandI/createinterface.html
- Oracle Java Tutorials (Generics): https://docs.oracle.com/javase/tutorial/java/generics/
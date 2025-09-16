# Praxisorientierte Anleitung: Integration von Apache mit MySQL für dynamische Webseiten auf Debian

## Einführung
Die Integration von Apache mit einer MySQL-Datenbank ermöglicht die Erstellung dynamischer Webseiten, die Daten aus einer Datenbank abrufen und anzeigen. Diese Anleitung zeigt Ihnen, wie Sie Apache, MySQL und PHP auf einem Debian-System einrichten und eine einfache dynamische Webanwendung (eine To-Do-Liste) erstellen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Apache mit MySQL zu verbinden und dynamische Inhalte bereitzustellen. Diese Anleitung ist ideal für Anfänger und Entwickler, die dynamische Webseiten entwickeln möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit installiertem Apache Web Server (`apache2`)
- Root- oder Sudo-Zugriff
- Grundlegende Kenntnisse der Linux-Kommandozeile und von Webentwicklung
- Ein Terminal für die Ausführung von Befehlen
- Optional: Ein Texteditor (z. B. `nano` oder `vim`)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **Installation der Komponenten**:
   - `apache2`: Der Webserver für die Bereitstellung der Webseiten
   - `mysql-server`: Die Datenbank für die Speicherung der Daten
   - `php` und `libapache2-mod-php`: Ermöglicht die Verarbeitung von PHP-Skripten für dynamische Inhalte
2. **Datenbankzugriff in PHP**:
   - `mysqli` oder `PDO`: PHP-Erweiterungen für die Verbindung mit MySQL
   - SQL-Abfragen: Erstellen, Abrufen und Verwalten von Daten
3. **Apache-Konfiguration**:
   - `/etc/apache2/sites-available/`: Konfigurationsdateien für virtuelle Hosts
   - `/var/www/html/`: Standardverzeichnis für Webinhalte

## Übungen zum Verinnerlichen

### Übung 1: Installation von Apache, MySQL und PHP
**Ziel**: Lernen, wie man die LAMP-Umgebung (Linux, Apache, MySQL, PHP) einrichtet.

1. **Schritt 1**: Installiere Apache, MySQL und PHP.
   ```bash
   sudo apt update
   sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql
   sudo systemctl start apache2 mysql
   sudo systemctl enable apache2 mysql
   ```
2. **Schritt 2**: Sichere die MySQL-Installation und erstelle eine Datenbank.
   ```bash
   sudo mysql_secure_installation
   sudo mysql -u root -p
   ```
   Führe in der MySQL-Konsole folgendes aus:
   ```sql
   CREATE DATABASE todo_app;
   GRANT ALL PRIVILEGES ON todo_app.* TO 'todo_user'@'localhost' IDENTIFIED BY 'secure_password';
   FLUSH PRIVILEGES;
   EXIT;
   ```
3. **Schritt 3**: Teste die PHP-Installation, indem du eine Testseite erstellst.
   ```bash
   sudo nano /var/www/html/info.php
   ```
   Füge folgenden Inhalt ein:
   ```php
   <?php
   phpinfo();
   ?>
   ```
   Öffne `http://localhost/info.php` im Browser, um die PHP-Informationen zu sehen.

**Reflexion**: Warum ist es wichtig, die MySQL-Installation mit `mysql_secure_installation` abzusichern?

### Übung 2: Erstellen einer dynamischen To-Do-Liste
**Ziel**: Verstehen, wie man eine MySQL-Datenbank mit PHP verbindet, um eine einfache dynamische Webseite zu erstellen.

1. **Schritt 1**: Erstelle eine Tabelle für die To-Do-Liste in der Datenbank.
   ```bash
   sudo mysql -u root -p
   ```
   Führe in der MySQL-Konsole folgendes aus:
   ```sql
   USE todo_app;
   CREATE TABLE tasks (
       id INT AUTO_INCREMENT PRIMARY KEY,
       task VARCHAR(255) NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   INSERT INTO tasks (task) VALUES ('Erste Aufgabe');
   EXIT;
   ```
2. **Schritt 2**: Erstelle eine PHP-Datei, um die To-Do-Liste anzuzeigen.
   ```bash
   sudo nano /var/www/html/index.php
   ```
   Füge folgenden Inhalt ein:
   ```php
   <?php
   $conn = new mysqli("localhost", "todo_user", "secure_password", "todo_app");
   if ($conn->connect_error) {
       die("Verbindung fehlgeschlagen: " . $conn->connect_error);
   }
   $result = $conn->query("SELECT * FROM tasks");
   ?>
   <!DOCTYPE html>
   <html>
   <head>
       <title>To-Do-Liste</title>
   </head>
   <body>
       <h1>Meine To-Do-Liste</h1>
       <ul>
       <?php while ($row = $result->fetch_assoc()): ?>
           <li><?php echo htmlspecialchars($row['task']); ?> (Erstellt: <?php echo $row['created_at']; ?>)</li>
       <?php endwhile; ?>
       </ul>
       <?php $conn->close(); ?>
   </body>
   </html>
   ```
3. **Schritt 3**: Stelle sicher, dass die Dateiberechtigungen korrekt sind, und teste die Seite.
   ```bash
   sudo chown www-data:www-data /var/www/html/index.php
   sudo chmod 644 /var/www/html/index.php
   sudo systemctl restart apache2
   ```
   Öffne `http://localhost` im Browser, um die To-Do-Liste zu sehen.

**Reflexion**: Warum ist es wichtig, Benutzereingaben mit `htmlspecialchars` zu schützen?

### Übung 3: Hinzufügen einer Aufgabe über ein Formular
**Ziel**: Lernen, wie man ein Formular erstellt, um Daten in die MySQL-Datenbank einzufügen.

1. **Schritt 1**: Aktualisiere die `index.php`, um ein Formular hinzuzufügen.
   ```bash
   sudo nano /var/www/html/index.php
   ```
   Ersetze den Inhalt durch:
   ```php
   <?php
   $conn = new mysqli("localhost", "todo_user", "secure_password", "todo_app");
   if ($conn->connect_error) {
       die("Verbindung fehlgeschlagen: " . $conn->connect_error);
   }
   if ($_SERVER["REQUEST_METHOD"] == "POST" && !empty($_POST['task'])) {
       $task = $conn->real_escape_string($_POST['task']);
       $conn->query("INSERT INTO tasks (task) VALUES ('$task')");
   }
   $result = $conn->query("SELECT * FROM tasks");
   ?>
   <!DOCTYPE html>
   <html>
   <head>
       <title>To-Do-Liste</title>
   </head>
   <body>
       <h1>Meine To-Do-Liste</h1>
       <form method="post" action="">
           <input type="text" name="task" placeholder="Neue Aufgabe" required>
           <button type="submit">Hinzufügen</button>
       </form>
       <ul>
       <?php while ($row = $result->fetch_assoc()): ?>
           <li><?php echo htmlspecialchars($row['task']); ?> (Erstellt: <?php echo $row['created_at']; ?>)</li>
       <?php endwhile; ?>
       </ul>
       <?php $conn->close(); ?>
   </body>
   </html>
   ```
2. **Schritt 2**: Stelle sicher, dass die Dateiberechtigungen korrekt sind, und starte Apache neu.
   ```bash
   sudo chown www-data:www-data /var/www/html/index.php
   sudo chmod 644 /var/www/html/index.php
   sudo systemctl restart apache2
   ```
3. **Schritt 3**: Teste das Formular unter `http://localhost`. Füge eine neue Aufgabe hinzu und überprüfe, ob sie in der Liste erscheint.

**Reflexion**: Wie kann die Verwendung von `real_escape_string` SQL-Injection-Angriffe verhindern?

## Tipps für den Erfolg
- Sichere die Datenbankverbindung, indem du einen dedizierten Benutzer mit eingeschränkten Rechten verwendest.
- Verwende `certbot` und `mod_ssl`, um die Webseite mit HTTPS abzusichern (siehe vorherige Anleitung).
- Überprüfe die Apache- und MySQL-Logs (`/var/log/apache2/error.log`, `/var/log/mysql/error.log`) bei Problemen.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache mit MySQL und PHP integrieren, um dynamische Webseiten bereitzustellen. Durch die Übungen haben Sie eine einfache To-Do-Listen-Anwendung erstellt, die Daten in einer MySQL-Datenbank speichert und anzeigt. Diese Fähigkeiten sind die Grundlage für die Entwicklung komplexer Webanwendungen. Üben Sie weiter, um fortgeschrittene Funktionen wie Benutzerauthentifizierung oder komplexere Datenbankabfragen zu implementieren!

**Nächste Schritte**:
- Implementieren Sie Benutzerauthentifizierung für die To-Do-Liste.
- Nutzen Sie `mod_ssl` und Let’s Encrypt, um die Webseite mit HTTPS abzusichern.
- Erkunden Sie PHP-Frameworks wie Laravel oder Symfony für strukturierte Webanwendungen.

**Quellen**:
- Offizielle Apache-Dokumentation: https://httpd.apache.org/docs/
- MySQL-Dokumentation: https://dev.mysql.com/doc/
- PHP-Dokumentation: https://www.php.net/manual/en/
- DigitalOcean LAMP-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-debian-10
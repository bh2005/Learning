# Praxisorientierte Anleitung: FTP-Übungen mit Bash (FTP-Client, FTP-Befehle, SFTP-Einrichtung)

## Einführung
Das File Transfer Protocol (FTP) und das sichere Secure File Transfer Protocol (SFTP) sind weit verbreitete Methoden zum Übertragen von Dateien zwischen Systemen. Bash bietet Werkzeuge wie `ftp`, `sftp` und Kommandozeilen-Clients, um diese Aufgaben zu bewältigen. Diese Anleitung führt Anfänger durch praktische Übungen zu **FTP-Client-Verwendung**, **FTP-Befehlen** und **SFTP-Einrichtung**. Die Übungen konzentrieren sich auf das Hoch- und Herunterladen von Dateien, die Verwendung von FTP-Befehlen in der Kommandozeile und die Konfiguration eines SFTP-Servers. Eine **Spielerei** zeigt, wie du die Ergebnisse der Operationen in einer Markdown-Tabelle zusammenfasst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch diese Übungen lernst du, FTP und SFTP in einer Bash-Umgebung zu meistern.

**Voraussetzungen**:
- Ein System mit Linux (z. B. Ubuntu 22.04, Debian); Windows-Nutzer können WSL2 verwenden; macOS ist vollständig kompatibel.
- Ein Terminal (z. B. Bash unter Linux/macOS, PowerShell mit WSL2 unter Windows).
- FTP- und SFTP-Tools installiert:
  - Ubuntu/Debian: `sudo apt install ftp openssh-server`
  - macOS: FTP- und SFTP-Tools sind vorinstalliert (`ftp`, `sftp`).
- Zugriff auf einen FTP/SFTP-Server (z. B. ein Cloud-Server wie AWS EC2, ein lokales Gerät mit installiertem FTP/SFTP-Server oder ein öffentlicher Testserver wie `ftp.dlptest.com`).
- Grundkenntnisse in Bash (Befehle, Skripte) und Netzwerkkonzepten (IP-Adressen, Ports).
- Sichere Testumgebung (z. B. `$HOME/ftp_tests` oder `~/ftp_tests`).
- Internetzugriff und Root-Zugriff für Server-Konfiguration (via `sudo`).
- Optional: FileZilla für die grafische FTP-Client-Übung.

## Grundlegende Befehle
Hier sind die wichtigsten Bash-Befehle für die FTP-Übungen:

1. **FTP-Client-Verwendung**:
   - `ftp <host>`: Startet eine interaktive FTP-Sitzung.
   - `put <file>`: Lädt eine Datei auf den Server hoch.
   - `get <file>`: Lädt eine Datei vom Server herunter.
   - `bye`: Beendet die FTP-Sitzung.
2. **FTP-Befehle**:
   - `ls`: Listet Dateien auf dem Server.
   - `cd <directory>`: Wechselt das Verzeichnis auf dem Server.
   - `pwd`: Zeigt das aktuelle Verzeichnis auf dem Server.
   - `mput <files>`: Lädt mehrere Dateien hoch.
   - `mget <files>`: Lädt mehrere Dateien herunter.
3. **SFTP-Einrichtung**:
   - `sudo systemctl start sshd`: Startet den SSH-Server (SFTP basiert auf SSH).
   - `sftp user@host`: Startet eine interaktive SFTP-Sitzung.
   - `sudo nano /etc/ssh/sshd_config`: Konfiguriert den SSH/SFTP-Server.
   - `sudo systemctl reload sshd`: Lädt die SSH-Konfiguration neu.
4. **Nützliche Zusatzbefehle**:
   - `man ftp`: Zeigt die Dokumentation für `ftp`.
   - `man sftp`: Zeigt die Dokumentation für `sftp`.
   - `sudo systemctl status sshd`: Prüft den Status des SSH/SFTP-Servers.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: FTP-Client verwenden
**Ziel**: Verwende einen FTP-Client (z. B. FileZilla oder Kommandozeilen-`ftp`), um Dateien auf einen FTP-Server hoch- und herunterzuladen.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir ftp_tests
   cd ftp_tests
   ```

2. **Schritt 2**: Stelle sicher, dass der FTP-Client installiert ist:
   ```bash
   sudo apt install ftp  # Ubuntu/Debian
   # macOS: ftp ist vorinstalliert
   ```

3. **Schritt 3**: Erstelle eine Testdatei zum Hochladen:
   ```bash
   echo "Dies ist eine Testdatei" > testfile.txt
   ```

4. **Schritt 4**: Verwende den Kommandozeilen-`ftp`-Client (z. B. mit dem Testserver `ftp.dlptest.com`, Benutzer: `dlpuser`, Passwort: `rNrKYTX9g7z3RgJRmx`):
   ```bash
   ftp ftp.dlptest.com
   ```
   - Melde dich mit Benutzername `dlpuser` und Passwort `rNrKYTX9g7z3RgJRmx` an.
   - Führe folgende Befehle in der FTP-Sitzung aus:
     ```
     put testfile.txt
     get testfile.txt testfile_downloaded.txt
     ls
     bye
     ```
   - Überprüfe die heruntergeladene Datei:
     ```bash
     cat testfile_downloaded.txt
     ```

5. **Schritt 5 (optional)**: Verwende FileZilla (grafischer Client):
   - Installiere FileZilla:
     ```bash
     sudo apt install filezilla  # Ubuntu/Debian
     # oder: brew install filezilla  # macOS
     ```
   - Öffne FileZilla und verbinde dich mit `ftp.dlptest.com` (Host: `ftp.dlptest.com`, Benutzer: `dlpuser`, Passwort: `rNrKYTX9g7z3RgJRmx`, Port: 21).
   - Lade `testfile.txt` hoch und herunter, um die Funktionalität zu testen.

6. **Schritt 6**: Protokolliere die Operation:
   ```bash
   echo "FTP-Upload/Download zu ftp.dlptest.com am $(date)" > ftp_log.txt
   ls -l testfile* >> ftp_log.txt
   cat ftp_log.txt
   ```

**Reflexion**: Warum ist FTP unsicher im Vergleich zu SFTP? Nutze `man ftp` und überlege, wie du die Verbindung mit TLS (FTPS) sichern kannst.

### Übung 2: FTP-Befehle
**Ziel**: Nutze die Kommandozeile, um FTP-Befehle wie `put`, `get`, `ls` und `cd` auszuführen.

1. **Schritt 1**: Erstelle mehrere Testdateien:
   ```bash
   echo "Datei 1" > file1.txt
   echo "Datei 2" > file2.txt
   ```

2. **Schritt 2**: Verbinde dich mit einem FTP-Server (z. B. `ftp.dlptest.com`):
   ```bash
   ftp ftp.dlptest.com
   ```
   - Melde dich mit Benutzername `dlpuser` und Passwort `rNrKYTX9g7z3RgJRmx` an.
   - Führe folgende Befehle aus:
     ```
     cd uploads
     pwd
     ls
     mput file*.txt
     mget file*.txt
     bye
     ```

3. **Schritt 3**: Erstelle ein Skript, um FTP-Befehle zu automatisieren:
   ```bash
   nano ftp_commands.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript für automatisierte FTP-Befehle

   FTP_HOST="ftp.dlptest.com"
   FTP_USER="dlpuser"
   FTP_PASS="rNrKYTX9g7z3RgJRmx"
   OUTPUT_FILE="ftp_commands_log.txt"

   echo "FTP-Befehle für $FTP_HOST am $(date)" > $OUTPUT_FILE

   # Erstelle Testdateien
   echo "Testdatei 1" > file1.txt
   echo "Testdatei 2" > file2.txt

   # Führe FTP-Befehle aus
   ftp -n $FTP_HOST <<END_SCRIPT
   quote USER $FTP_USER
   quote PASS $FTP_PASS
   cd uploads
   pwd
   ls
   mput file*.txt
   mget file*.txt file_downloaded_*.txt
   bye
   END_SCRIPT

   echo "Verzeichnis auf Server: $(ftp -n $FTP_HOST <<END_SCRIPT | grep 'Working dir'
   quote USER $FTP_USER
   quote PASS $FTP_PASS
   pwd
   END_SCRIPT)" >> $OUTPUT_FILE

   echo "FTP-Befehle abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ls -l file_downloaded_*.txt >> $OUTPUT_FILE
   ```
   Speichere und schließe.

4. **Schritt 4**: Mache das Skript ausführbar und führe es aus:
   ```bash
   chmod +x ftp_commands.sh
   ./ftp_commands.sh
   ```

5. **Schritt 5**: Überprüfe die heruntergeladenen Dateien:
   ```bash
   cat file_downloaded_*.txt
   cat ftp_commands_log.txt
   ```

**Reflexion**: Wie vereinfachen automatisierte FTP-Skripte wiederkehrende Aufgaben? Nutze `man ftp` und überlege, wie du ASCII- oder Binärmodus (`ascii`, `binary`) für unterschiedliche Dateitypen nutzen kannst.

### Übung 3: SFTP einrichten und Spielerei
**Ziel**: Konfiguriere einen SFTP-Server und teste die Verbindung mit einem SFTP-Client, inklusive einer Markdown-Tabelle für die Ergebnisse.

1. **Schritt 1**: Stelle sicher, dass der SSH-Server installiert ist:
   ```bash
   sudo apt install openssh-server  # Ubuntu/Debian
   # macOS: SSH ist vorinstalliert
   sudo systemctl enable sshd
   sudo systemctl start sshd
   ```

2. **Schritt 2**: Konfiguriere den SFTP-Server:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
   Stelle sicher, dass die folgende Zeile enthalten oder nicht auskommentiert ist:
   ```
   Subsystem sftp /usr/lib/openssh/sftp-server
   ```
   Optional: Erlaube nur SFTP für einen bestimmten Benutzer (z. B. `sftpuser`):
   ```bash
   sudo adduser sftpuser
   ```
   Füge am Ende von `/etc/ssh/sshd_config` hinzu:
   ```
   Match User sftpuser
       ForceCommand internal-sftp
       ChrootDirectory /home/sftpuser
       AllowTCPForwarding no
       X11Forwarding no
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle ein Verzeichnis für den SFTP-Benutzer:
   ```bash
   sudo mkdir -p /home/sftpuser/upload
   sudo chown sftpuser:sftpuser /home/sftpuser/upload
   sudo chmod 755 /home/sftpuser
   sudo systemctl restart sshd
   ```

4. **Schritt 4**: Teste die SFTP-Verbindung:
   ```bash
   sftp sftpuser@localhost
   ```
   - Gib das Passwort für `sftpuser` ein.
   - Führe folgende Befehle in der SFTP-Sitzung aus:
     ```
     cd upload
     put testfile.txt
     ls
     get testfile.txt testfile_sftp.txt
     bye
     ```
   - Überprüfe die heruntergeladene Datei:
     ```bash
     cat testfile_sftp.txt
     ```

5. **Schritt 5**: Erstelle ein Skript, um FTP/SFTP-Operationen zu protokollieren und eine Markdown-Tabelle zu generieren:
   ```bash
   nano ftp_sftp_operations.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript für FTP/SFTP-Operationen und Markdown-Ausgabe

   OUTPUT_FILE="ftp_sftp_results.md"
   FTP_HOST="ftp.dlptest.com"
   FTP_USER="dlpuser"
   FTP_PASS="rNrKYTX9g7z3RgJRmx"
   SFTP_HOST="localhost"
   SFTP_USER="sftpuser"

   echo "# FTP/SFTP-Operationen Ergebnisse" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| Operation | Host | Status | Details |" >> $OUTPUT_FILE
   echo "|-----------|------|--------|---------|" >> $OUTPUT_FILE

   # Teste FTP
   echo "Testdatei für FTP" > ftp_test.txt
   ftp -n $FTP_HOST <<END_SCRIPT > ftp_output.txt 2>&1
   quote USER $FTP_USER
   quote PASS $FTP_PASS
   put ftp_test.txt
   bye
   END_SCRIPT
   if grep -q "Transfer complete" ftp_output.txt; then
       ftp_status="Erfolgreich"
       ftp_details="Datei ftp_test.txt hochgeladen"
   else
       ftp_status="Fehlgeschlagen"
       ftp_details="Upload fehlgeschlagen"
   fi
   echo "| FTP-Upload | $FTP_HOST | $ftp_status | $ftp_details |" >> $OUTPUT_FILE

   # Teste SFTP
   echo "Testdatei für SFTP" > sftp_test.txt
   sftp $SFTP_USER@$SFTP_HOST <<END_SCRIPT > sftp_output.txt 2>&1
   cd upload
   put sftp_test.txt
   bye
   END_SCRIPT
   if grep -q "sftp_test.txt" sftp_output.txt; then
       sftp_status="Erfolgreich"
       sftp_details="Datei sftp_test.txt hochgeladen"
   else
       sftp_status="Fehlgeschlagen"
       sftp_details="Upload fehlgeschlagen"
   fi
   echo "| SFTP-Upload | $SFTP_HOST | $sftp_status | $sftp_details |" >> $OUTPUT_FILE

   echo "FTP/SFTP-Operationen abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

6. **Schritt 6**: Mache das Skript ausführbar und führe es aus (passe `SFTP_USER` und `SFTP_HOST` an, falls nötig):
   ```bash
   chmod +x ftp_sftp_operations.sh
   ./ftp_sftp_operations.sh
   ```

7. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat ftp_sftp_results.md
   ```
   Die Ausgabe könnte so aussehen (abhängig von deinem System):
   ```
   # FTP/SFTP-Operationen Ergebnisse
   Erstellt am: Fri Sep  5 10:51:00 CEST 2025

   | Operation   | Host              | Status      | Details                            |
   |-------------|-------------------|-------------|------------------------------------|
   | FTP-Upload  | ftp.dlptest.com   | Erfolgreich | Datei ftp_test.txt hochgeladen     |
   | SFTP-Upload | localhost         | Erfolgreich | Datei sftp_test.txt hochgeladen    |
   ```

**Reflexion**: Warum ist SFTP sicherer als FTP? Nutze `man sftp` und überlege, wie du den SFTP-Zugriff mit SSH-Schlüsseln statt Passwörtern konfigurieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um FTP- und SFTP-Konzepte in Bash zu verinnerlichen.
- **Sicheres Testen**: Verwende eine Testumgebung und vermeide Änderungen an produktiven Servern.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man ftp` oder `man sftp` für Details.
- **Effiziente Entwicklung**: Nutze Skripte für automatisierte Übertragungen, `sftp` für sichere Verbindungen und `~/.ssh/config` für vereinfachte SFTP-Verbindungen.
- **Kombiniere Tools**: Integriere `scp` für einfache Dateiübertragungen oder `rsync` für synchronisierte Backups.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Dateigrößen oder Übertragungszeiten in die Markdown-Tabelle.

## Fazit
Mit diesen Übungen hast du gelernt, einen FTP-Client zu verwenden, FTP-Befehle in der Kommandozeile auszuführen und einen SFTP-Server einzurichten. Die Spielerei zeigt, wie du Ergebnisse in einer Markdown-Tabelle zusammenfasst. Vertiefe dein Wissen, indem du fortgeschrittene Features (z. B. FTPS, SFTP mit Chroot-Jails) oder Tools wie `lftp` für erweiterte FTP-Funktionen ausprobierst. Wenn du ein spezifisches Thema (z. B. FTPS oder automatisierte Backups) vertiefen möchtest, lass es mich wissen!

# Praxisorientierte Anleitung: SSH-Übungen mit Bash (SSH-Verbindung, Schlüsselgenerierung, Tunneling)

## Einführung
Secure Shell (SSH) ist ein Protokoll für sichere Remote-Verbindungen und Datenübertragung. Bash bietet Werkzeuge wie `ssh`, `ssh-keygen` und `ssh-copy-id`, um SSH-Aufgaben zu bewältigen. Diese Anleitung führt Anfänger durch praktische Übungen zu **SSH-Verbindung**, **SSH-Schlüsselgenerierung** und **SSH-Tunneling**. Die Übungen konzentrieren sich auf das Herstellen von Verbindungen, das Erstellen und Konfigurieren von Schlüsselpaaren sowie das Einrichten von SSH-Tunneln für lokale Dienste. Eine **Spielerei** zeigt, wie du die Ergebnisse der SSH-Operationen in einer Markdown-Tabelle zusammenfasst, um die Verbindung zu vorherigen Themen (z. B. Markdown-Ausgabe) herzustellen. Durch diese Übungen lernst du, SSH in einer Bash-Umgebung zu meistern.

**Voraussetzungen**:
- Ein System mit Linux (z. B. Ubuntu 22.04, Debian); Windows-Nutzer können WSL2 verwenden; macOS ist vollständig kompatibel.
- Ein Terminal (z. B. Bash unter Linux/macOS, PowerShell mit WSL2 unter Windows).
- SSH-Tools installiert (vorinstalliert auf den meisten Linux/macOS-Systemen):
  - Ubuntu/Debian: `sudo apt install openssh-client openssh-server`
  - macOS: SSH-Tools sind vorinstalliert.
- Zugriff auf einen Remote-Server (z. B. eine VM, ein Cloud-Server wie AWS EC2 oder ein lokales Gerät mit SSH-Server).
- Grundkenntnisse in Bash (Befehle, Skripte) und Netzwerkkonzepten (IP-Adressen, Ports).
- Sichere Testumgebung (z. B. `$HOME/ssh_tests` oder `~/ssh_tests`).
- Internetzugriff und Root-Zugriff für SSH-Server-Konfiguration (via `sudo`).

## Grundlegende Befehle
Hier sind die wichtigsten Bash-Befehle für die SSH-Übungen:

1. **SSH-Verbindung**:
   - `ssh user@host`: Stellt eine SSH-Verbindung zu einem Remote-Server her.
   - `ssh user@host <command>`: Führt einen Befehl auf dem Remote-Server aus.
   - `exit`: Beendet die SSH-Sitzung.
2. **SSH-Schlüsselgenerierung**:
   - `ssh-keygen -t rsa`: Generiert ein RSA-Schlüsselpaar.
   - `ssh-copy-id user@host`: Kopiert den öffentlichen Schlüssel auf den Remote-Server.
   - `cat ~/.ssh/id_rsa.pub`: Zeigt den öffentlichen Schlüssel.
3. **SSH-Tunneling**:
   - `ssh -L local_port:remote_host:remote_port user@host`: Richtet einen lokalen Tunnel ein.
   - `ssh -fN -L ...`: Führt den Tunnel im Hintergrund aus.
   - `ps aux | grep ssh`: Überprüft laufende SSH-Prozesse.
4. **Nützliche Zusatzbefehle**:
   - `man ssh`: Zeigt die Dokumentation für `ssh`.
   - `man ssh-keygen`: Zeigt die Dokumentation für `ssh-keygen`.
   - `sudo systemctl status sshd`: Prüft den Status des SSH-Servers.
   - `date`: Fügt Zeitstempel in Protokollen hinzu.

## Übungen zum Verinnerlichen der Konzepte

### Übung 1: SSH-Verbindung herstellen
**Ziel**: Stelle eine SSH-Verbindung zu einem Remote-Server her und führe grundlegende Befehle aus.

1. **Schritt 1**: Erstelle ein Testverzeichnis:
   ```bash
   mkdir ssh_tests
   cd ssh_tests
   ```

2. **Schritt 2**: Stelle sicher, dass OpenSSH installiert ist:
   ```bash
   sudo apt install openssh-client  # Ubuntu/Debian
   # macOS: SSH ist vorinstalliert
   ```

3. **Schritt 3**: Stelle eine SSH-Verbindung zu einem Remote-Server her (ersetze `user` und `host` durch tatsächliche Werte, z. B. `ubuntu@192.168.1.100`):
   ```bash
   ssh user@host
   ```
   - Gib das Passwort ein, wenn gefordert.
   - Führe grundlegende Befehle aus, z. B.:
     ```bash
     whoami
     pwd
     ls -l
     exit
     ```

4. **Schritt 4**: Führe einen Befehl direkt aus, ohne interaktive Sitzung:
   ```bash
   ssh user@host "uptime"
   ```
   **Beispielausgabe**:
   ```
   10:50:00 up 1 day, 2:30, 1 user, load average: 0.10, 0.15, 0.20
   ```

5. **Schritt 5**: Protokolliere die Verbindung in einer Datei:
   ```bash
   echo "SSH-Verbindung zu user@host am $(date)" > ssh_log.txt
   ssh user@host "uptime" >> ssh_log.txt
   cat ssh_log.txt
   ```

**Reflexion**: Warum ist SSH für Remote-Administration sicher? Nutze `man ssh` und überlege, wie du die Verbindung mit spezifischen Ports (z. B. `-p 2222`) anpassen kannst.

### Übung 2: SSH-Schlüssel generieren
**Ziel**: Erstelle ein SSH-Schlüsselpaar und konfiguriere den öffentlichen Schlüssel für passwortlose Authentifizierung.

1. **Schritt 1**: Stelle sicher, dass OpenSSH installiert ist (siehe Übung 1, Schritt 2).

2. **Schritt 2**: Generiere ein RSA-Schlüsselpaar:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```
   - Drücke Enter für den Standardpfad (`~/.ssh/id_rsa`).
   - Optional: Gib eine Passphrase ein oder lasse das Feld leer.
   - **Ausgabe**:
     ```
     Generating public/private rsa key pair.
     Your identification has been saved in /home/user/.ssh/id_rsa
     Your public key has been saved in /home/user/.ssh/id_rsa.pub
     ```

3. **Schritt 3**: Kopiere den öffentlichen Schlüssel auf den Remote-Server:
   ```bash
   ssh-copy-id user@host
   ```
   - Gib das Passwort ein, wenn gefordert.
   - Alternativ (manuell):
     ```bash
     cat ~/.ssh/id_rsa.pub | ssh user@host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
     ```

4. **Schritt 4**: Teste die passwortlose Verbindung:
   ```bash
   ssh user@host "whoami"
   ```
   Du solltest ohne Passwortabfrage eingeloggt werden.

5. **Schritt 5**: Protokolliere die Schlüsselgenerierung:
   ```bash
   echo "SSH-Schlüssel generiert und kopiert zu user@host am $(date)" >> ssh_log.txt
   cat ssh_log.txt
   ```

**Reflexion**: Wie verbessert die schlüsselbasierte Authentifizierung die Sicherheit? Nutze `man ssh-keygen` und überlege, wie du ED25519-Schlüssel statt RSA verwenden kannst.

### Übung 3: SSH-Tunneling und Spielerei
**Ziel**: Richte einen SSH-Tunnel ein, um auf einen lokalen Dienst zuzugreifen, und erstelle eine Markdown-Tabelle mit den Ergebnissen.

1. **Schritt 1**: Stelle sicher, dass ein Dienst auf dem Remote-Server läuft (z. B. eine Datenbank wie MySQL auf Port 3306). Für diese Übung simulieren wir den Zugriff auf einen lokalen Webserver (Port 8080).

2. **Schritt 2**: Richte einen lokalen SSH-Tunnel ein:
   ```bash
   ssh -L 8080:localhost:8080 user@host -fN
   ```
   - **Erklärung**: `-L 8080:localhost:8080` leitet den lokalen Port 8080 an den Port 8080 des Remote-Servers weiter; `-fN` führt den Tunnel im Hintergrund aus.

3. **Schritt 3**: Teste den Tunnel:
   - Starte einen einfachen Webserver auf dem Remote-Server (falls nicht vorhanden, simuliere ihn):
     ```bash
     ssh user@host "python3 -m http.server 8080 &"
     ```
   - Greife lokal auf den Dienst zu:
     ```bash
     curl http://localhost:8080
     ```
   - Beende den Tunnel:
     ```bash
     pkill -f "ssh -L 8080"
     ```

4. **Schritt 4**: Erstelle ein Skript, um SSH-Operationen zu protokollieren und eine Markdown-Tabelle zu generieren:
   ```bash
   nano ssh_operations.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   # Skript für SSH-Operationen und Markdown-Ausgabe

   OUTPUT_FILE="ssh_results.md"
   HOSTS=("user@host")  # Ersetze user@host durch tatsächliche Werte
   OPERATIONS=("Verbindung" "Schlüssel-Auth" "Tunneling")

   echo "# SSH-Operationen Ergebnisse" > $OUTPUT_FILE
   echo "Erstellt am: $(date)" >> $OUTPUT_FILE
   echo "" >> $OUTPUT_FILE
   echo "| Operation | Host | Status | Details |" >> $OUTPUT_FILE
   echo "|-----------|------|--------|---------|" >> $OUTPUT_FILE

   for host in "${HOSTS[@]}"; do
       # Teste Verbindung
       ssh -o ConnectTimeout=5 $host "uptime" > /dev/null 2>&1
       if [ $? -eq 0 ]; then
           conn_status="Erfolgreich"
           conn_details=$(ssh $host "uptime")
       else
           conn_status="Fehlgeschlagen"
           conn_details="Keine Verbindung"
       fi
       echo "| Verbindung | $host | $conn_status | $conn_details |" >> $OUTPUT_FILE

       # Teste Schlüssel-Authentifizierung
       if [ -f ~/.ssh/id_rsa ]; then
           key_status="Schlüssel vorhanden"
           key_details=$(ssh -o ConnectTimeout=5 $host "whoami" 2>/dev/null || echo "Nicht authentifiziert")
       else
           key_status="Kein Schlüssel"
           key_details="N/A"
       fi
       echo "| Schlüssel-Auth | $host | $key_status | $key_details |" >> $OUTPUT_FILE

       # Teste Tunneling
       ssh -L 8080:localhost:8080 $host -fN
       sleep 2
       tunnel_result=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
       if [ "$tunnel_result" == "200" ]; then
           tunnel_status="Erfolgreich"
           tunnel_details="Webserver auf Port 8080 erreichbar"
       else
           tunnel_status="Fehlgeschlagen"
           tunnel_details="Port 8080 nicht erreichbar"
       fi
       echo "| Tunneling | $host | $tunnel_status | $tunnel_details |" >> $OUTPUT_FILE
       pkill -f "ssh -L 8080"
   done

   echo "SSH-Operationen abgeschlossen. Ergebnisse in $OUTPUT_FILE."
   cat $OUTPUT_FILE
   ```
   Speichere und schließe.

5. **Schritt 5**: Mache das Skript ausführbar und führe es aus (passe `user@host` an):
   ```bash
   chmod +x ssh_operations.sh
   ./ssh_operations.sh
   ```

6. **Spielerei**: Überprüfe die Markdown-Ausgabe:
   ```bash
   cat ssh_results.md
   ```
   Die Ausgabe könnte so aussehen (abhängig von deinem System):
   ```
   # SSH-Operationen Ergebnisse
   Erstellt am: Fri Sep  5 10:48:00 CEST 2025

   | Operation      | Host         | Status        | Details                                    |
   |----------------|--------------|---------------|--------------------------------------------|
   | Verbindung     | user@host    | Erfolgreich   | 10:48:00 up 1 day, 2:30, 1 user, ...      |
   | Schlüssel-Auth | user@host    | Schlüssel vorhanden | user                               |
   | Tunneling      | user@host    | Erfolgreich   | Webserver auf Port 8080 erreichbar         |
   ```

**Reflexion**: Wie schützt SSH-Tunneling lokale Dienste? Nutze `man ssh` und überlege, wie du Reverse-Tunneling (`-R`) für umgekehrte Szenarien einrichten kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um SSH-Konzepte in Bash zu verinnerlichen.
- **Sicheres Testen**: Verwende eine Testumgebung und vermeide Änderungen an produktiven Servern.
- **Fehler verstehen**: Lies Fehlermeldungen genau und nutze `man ssh` oder `man ssh-keygen` für Details.
- **Effiziente Entwicklung**: Nutze `ssh-copy-id` für einfache Schlüsselverteilung, Skripte für Automatisierung und `~/.ssh/config` für Verbindungsaliases.
- **Kombiniere Tools**: Integriere `scp` für Dateiübertragungen oder `rsync` für synchronisierte Backups.
- **Experimentiere**: Erweitere die Spielerei, z. B. durch Hinzufügen von Port- oder Benutzerinformationen in die Markdown-Tabelle.

## Fazit
Mit diesen Übungen hast du gelernt, SSH-Verbindungen herzustellen, Schlüsselpaare für passwortlose Authentifizierung zu konfigurieren und SSH-Tunnel für lokale Dienste einzurichten. Die Spielerei zeigt, wie du Ergebnisse in einer Markdown-Tabelle zusammenfasst. Vertiefe dein Wissen, indem du fortgeschrittene SSH-Features (z. B. ProxyJump, SSH-Agent) oder Tools wie `mosh` für stabile Verbindungen ausprobierst. Wenn du ein spezifisches Thema (z. B. SSH-Sicherheit oder Multi-Hop-Tunneling) vertiefen möchtest, lass es mich wissen!

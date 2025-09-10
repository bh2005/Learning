# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Netzwerkverwaltung, Firewall und SSH/SCP

## Einführung
Die Linux-Kommandozeile ist ein leistungsstarkes Werkzeug für die Verwaltung von Netzwerken, Firewalls und sicheren Verbindungen. Diese Anleitung konzentriert sich auf die Schwerpunkte **Netzwerkverwaltung**, **Firewall** und **SSH & SCP**, einschließlich der Nutzung des textbasierten Webbrowsers `links2`. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen, um Netzwerkaufgaben effektiv zu bewältigen.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für viele Befehle, insbesondere bei Netzwerk- und Firewall-Verwaltung.
- Zugriff auf ein zweites System (lokal oder remote) für SSH/SCP-Tests.
- Grundlegendes Verständnis von Netzwerken (z. B. IP-Adressen, Ports).
- Installation von `links2` für Übungen zur Netzwerkverwaltung (siehe Übung 1).

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Netzwerkverwaltung**:
   - `ip`: Zeigt und konfiguriert Netzwerkschnittstellen, Routen und Adressen.
   - `ping`: Testet die Erreichbarkeit eines Hosts.
   - `ss`: Zeigt Netzwerkverbindungen und Socket-Informationen an (moderne Alternative zu `netstat`).
   - `curl`: Sendet HTTP-Anfragen und zeigt Antworten an.
   - `wget`: Lädt Dateien aus dem Internet herunter.
   - `nslookup`: Fragt DNS-Server nach Hostinformationen.
   - `links2`: Textbasierter Webbrowser für das Surfen im Internet über die Kommandozeile.
2. **Firewall**:
   - `ufw`: Benutzerfreundliches Frontend für die Verwaltung von `iptables`-Firewall-Regeln.
   - `iptables`: Konfiguriert Firewall-Regeln auf Kernel-Ebene (fortgeschritten).
3. **SSH & SCP**:
   - `ssh`: Stellt eine sichere Remote-Verbindung zu einem anderen System her.
   - `scp`: Kopiert Dateien sicher zwischen Hosts über SSH.
   - `ssh-keygen`: Generiert SSH-Schlüsselpaare für passwortlose Authentifizierung.
4. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `sudo`: Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Netzwerkverwaltung
**Ziel**: Lerne, wie du Netzwerkverbindungen überprüfst, konfigurierst, testest und mit `links2` im Terminal surfst.

1. **Schritt 1**: Installiere den textbasierten Webbrowser `links2` (benötigt `sudo`):
   ```bash
   sudo apt install links2
   ```
2. **Schritt 2**: Zeige Informationen zu deinen Netzwerkschnittstellen:
   ```bash
   ip addr show
   ```
   Notiere die IP-Adresse deiner Hauptschnittstelle (z. B. `eth0` oder `wlan0`, oft unter `inet` zu finden, z. B. `192.168.1.100`).
3. **Schritt 3**: Teste die Erreichbarkeit von `google.com`:
   ```bash
   ping -c 4 google.com
   ```
   Die Option `-c 4` begrenzt die Anzahl der Pings auf 4.
4. **Schritt 4**: Zeige aktive Netzwerkverbindungen an:
   ```bash
   ss -tuln
   ```
   Die Optionen `-t` (TCP), `-u` (UDP), `-l` (lauschende Sockets), `-n` (numerische Ports) zeigen offene Ports und Verbindungen.
5. **Schritt 5**: Lade die Hauptseite von `example.com` herunter und zeige sie an:
   ```bash
   curl http://example.com
   ```
6. **Schritt 6**: Lade eine Datei aus dem Internet herunter (z. B. ein Textdokument):
   ```bash
   wget https://www.example.com/sample.txt
   ```
   Überprüfe, ob die Datei heruntergeladen wurde:
   ```bash
   ls
   ```
7. **Schritt 7**: Führe eine DNS-Abfrage für `google.com` durch:
   ```bash
   nslookup google.com
   ```
   Notiere die IP-Adressen, die zurückgegeben werden.
8. **Schritt 8**: Surfe mit `links2` auf einer Webseite:
   ```bash
   links2 http://example.com
   ```
   Navigiere mit den Pfeiltasten, wähle Links mit `Enter`, und verlasse `links2` mit `q` (drücke `y` zum Bestätigen). Probiere auch `links2 google.com`.

**Reflexion**: Wie unterscheidet sich die Nutzung von `links2` von `curl` oder `wget`? Wann wäre ein textbasierter Browser wie `links2` nützlich (z. B. auf Servern ohne GUI)? Schaue in der Manpage nach (`man links2`) für zusätzliche Optionen.

### Übung 2: Firewall-Verwaltung
**Ziel**: Lerne, wie du eine Firewall konfigurierst, um den Netzwerkverkehr zu steuern.

1. **Schritt 1**: Überprüfe den Status der `ufw`-Firewall (benötigt `sudo`):
   ```bash
   sudo ufw status
   ```
   Falls `ufw` nicht installiert ist, installiere es:
   ```bash
   sudo apt install ufw
   ```
2. **Schritt 2**: Aktiviere die Firewall (Warnung: Stelle sicher, dass du SSH-Zugriff erlaubst, wenn du remote arbeitest):
   ```bash
   sudo ufw allow ssh
   sudo ufw enable
   ```
   Überprüfe erneut den Status:
   ```bash
   sudo ufw status
   ```
3. **Schritt 3**: Erlaube eingehenden HTTP-Verkehr (Port 80):
   ```bash
   sudo ufw allow http
   ```
   Überprüfe die aktualisierte Regel.
4. **Schritt 4**: Entferne die HTTP-Regel wieder:
   ```bash
   sudo ufw delete allow http
   ```
   Überprüfe den Status.
5. **Schritt 5**: Zeige die aktuellen `iptables`-Regeln an (fortgeschritten, benötigt `sudo`):
   ```bash
   sudo iptables -L -n -v
   ```
   Die Optionen `-L` (Liste), `-n` (numerische Adressen), `-v` (ausführlich) zeigen die Firewall-Regeln.

**Reflexion**: Warum ist es wichtig, SSH-Zugriff zu erlauben, bevor du `ufw enable` ausführst? Was passiert, wenn du alle eingehenden Verbindungen blockierst (`sudo ufw default deny incoming`)?

### Übung 3: SSH und SCP
**Ziel**: Lerne, wie du sichere Verbindungen herstellst und Dateien zwischen Systemen überträgst.

1. **Schritt 1**: Generiere ein SSH-Schlüsselpaar für passwortlose Authentifizierung:
   ```bash
   ssh-keygen -t rsa -b 4096
   ```
   Drücke Enter, um Standardwerte zu akzeptieren (Speicherort: `~/.ssh/id_rsa`). Notiere, dass ein öffentlicher und privater Schlüssel erstellt wurden.
2. **Schritt 2**: Kopiere den öffentlichen Schlüssel auf ein Remote-System (ersetze `user` und `remote-host` durch Benutzername und IP-Adresse/Hostnamen des Zielsystems):
   ```bash
   ssh-copy-id user@remote-host
   ```
   Alternativ manuell:
   ```bash
   cat ~/.ssh/id_rsa.pub | ssh user@remote-host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
   ```
3. **Schritt 3**: Stelle eine SSH-Verbindung zum Remote-System her:
   ```bash
   ssh user@remote-host
   ```
   Führe einen Befehl aus (z. B. `ls`) und verlasse die Verbindung mit `exit`.
4. **Schritt 4**: Erstelle eine lokale Testdatei:
   ```bash
   echo "Dies ist eine Testdatei." > test.txt
   ```
5. **Schritt 5**: Kopiere die Datei `test.txt` auf das Remote-System mit `scp`:
   ```bash
   scp test.txt user@remote-host:/home/user/
   ```
   Melde dich per SSH an und überprüfe, ob die Datei übertragen wurde:
   ```bash
   ssh user@remote-host ls
   ```
6. **Schritt 6**: Kopiere eine Datei vom Remote-System zurück auf dein lokales System:
   ```bash
   scp user@remote-host:/home/user/test.txt ./test_kopie.txt
   ```
   Überprüfe:
   ```bash
   ls
   ```

**Reflexion**: Was ist der Vorteil der passwortlosen Authentifizierung mit SSH-Schlüsseln? Wie unterscheidet sich `scp` von `cp` in Bezug auf Sicherheit und Anwendung?

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste Firewall-Änderungen in einer sicheren Umgebung, um Verbindungsverluste zu vermeiden.
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `sudo`**: Befehle wie `ufw` oder `iptables` können den Netzwerkzugriff verändern. Stelle sicher, dass du wichtige Ports (z. B. SSH auf Port 22) offen hältst.
- **Netzwerkdiagnose**: Nutze `ping`, `ss`, `nslookup` und `links2` zur Fehlersuche bei Verbindungsproblemen.
- **Sichere Verbindungen**: Verwende immer SSH-Schlüssel für Remote-Zugriff, um die Sicherheit zu erhöhen.
- **Textbasierter Browser**: Nutze `links2` auf Systemen ohne GUI oder für schnelle Tests von Webseiteninhalten.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für die Netzwerkverwaltung, Firewall-Konfiguration und sichere Datenübertragung mit SSH/SCP angewendet, einschließlich der Nutzung des textbasierten Webbrowsers `links2`. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `ip route` für Routing, `ufw limit` für Schutz vor Brute-Force-Angriffen, `scp -r` für Verzeichnisübertragungen oder `links2 -dump` für Textausgabe von Webseiten), um deine Fähigkeiten weiter zu verbessern.
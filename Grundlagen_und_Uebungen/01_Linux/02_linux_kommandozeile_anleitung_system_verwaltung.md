# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle

## Einführung
Die Linux-Kommandozeile ist ein unverzichtbares Werkzeug für die Verwaltung eines Linux-Systems. Diese Anleitung konzentriert sich auf die Schwerpunkte **Festplatten prüfen**, **Filesystem**, **Dienste und Systemverwaltung**, **Paketverwaltung**, **Prozessverwaltung** und **Systemüberwachung und Leistungsanalyse**. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen, um ein Linux-System effektiv zu verwalten.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für viele Befehle, insbesondere bei Systemverwaltung und Paketverwaltung.
- Grundlegendes Verständnis von Dateien, Verzeichnissen und Prozessen.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Festplatten prüfen**:
   - `df`: Zeigt die Festplattennutzung und verfügbaren Speicherplatz an.
   - `du`: Ermittelt die Größe von Dateien und Verzeichnissen.
   - `fsck`: Prüft und repariert Dateisysteme.
2. **Filesystem**:
   - `lsblk`: Listet Blockgeräte (z. B. Festplatten, Partitionen) auf.
   - `mount`: Bindet Dateisysteme ein.
   - `umount`: Bindet Dateisysteme aus.
   - `mkfs`: Formatiert ein Dateisystem (z. B. `ext4`).
3. **Dienste und Systemverwaltung**:
   - `systemctl`: Verwaltet Systemdienste (starten, stoppen, aktivieren).
   - `ps`: Zeigt laufende Prozesse an.
   - `top`: Zeigt Systemressourcen und Prozesse in Echtzeit an.
   - `journalctl`: Zeigt Systemlogs an.
4. **Paketverwaltung** (am Beispiel von Debian/Ubuntu mit `apt`):
   - `apt update`: Aktualisiert die Paketlisten.
   - `apt upgrade`: Aktualisiert installierte Pakete.
   - `apt install`: Installiert neue Pakete.
   - `apt remove`: Entfernt Pakete.
5. **Prozessverwaltung**:
   - `kill`: Beendet einen Prozess anhand seiner Prozess-ID (PID).
   - `killall`: Beendet Prozesse anhand ihres Namens.
   - `nice`: Startet einen Prozess mit einer bestimmten Priorität.
   - `renice`: Ändert die Priorität eines laufenden Prozesses.
   - `bg`: Verschiebt einen Prozess in den Hintergrund.
   - `fg`: Holt einen Prozess in den Vordergrund.
6. **Systemüberwachung und Leistungsanalyse**:
   - `htop`: Interaktiver Prozess- und Ressourcenmonitor (erweiterte Alternative zu `top`).
   - `free`: Zeigt den Speicherverbrauch (RAM und Swap) an.
   - `vmstat`: Zeigt Informationen zu Prozessen, Speicher und CPU an.
   - `iostat`: Zeigt I/O-Statistiken für Festplatten an.
   - `uptime`: Zeigt die Systemlaufzeit und Lastdurchschnitt an.
7. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `sudo`: Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Festplatten prüfen
**Ziel**: Lerne, wie du den Speicherplatz und die Integrität von Festplatten überprüfst.

1. **Schritt 1**: Öffne dein Terminal und überprüfe die Festplattennutzung:
   ```bash
   df -h
   ```
   Die Option `-h` zeigt die Ausgabe in einem lesbaren Format (z. B. GB, MB).
2. **Schritt 2**: Ermittle die Größe des Verzeichnisses `/home`:
   ```bash
   du -sh /home
   ```
   Die Option `-s` fasst die Größe zusammen, `-h` sorgt für ein lesbares Format.
3. **Schritt 3**: Prüfe die Integrität eines ungemounteten Dateisystems (z. B. `/dev/sdb1`, nur in einer sicheren Umgebung wie einer virtuellen Maschine ausprobieren, benötigt `sudo`):
   ```bash
   sudo fsck /dev/sdb1
   ```
   **Warnung**: Stelle sicher, dass die Partition nicht gemountet ist (siehe Übung 2). Nutze `lsblk`, um verfügbare Partitionen zu sehen.
4. **Schritt 4**: Finde die größten Dateien in deinem Home-Verzeichnis:
   ```bash
   du -h ~/ | sort -hr | head -n 5
   ```
   Dies kombiniert `du` mit `sort` und `head`, um die fünf größten Dateien/Verzeichnisse anzuzeigen.

**Reflexion**: Was passiert, wenn du `df` ohne `-h` ausführst? Vergleiche die Ausgabe. Warum ist es wichtig, `fsck` nur auf ungemounteten Dateisystemen auszuführen?

### Übung 2: Filesystem verwalten
**Ziel**: Lerne, wie du Dateisysteme einbindest, formatierst und Blockgeräte überprüfst.

1. **Schritt 1**: Liste alle Blockgeräte auf deinem System auf:
   ```bash
   lsblk
   ```
   Notiere dir die Partitionen und Mountpunkte (z. B. `/dev/sda1` für `/`).
2. **Schritt 2**: Erstelle ein temporäres Verzeichnis als Mountpunkt:
   ```bash
   mkdir ~/mnt_tmp
   ```
3. **Schritt 3**: Binde ein USB-Laufwerk oder eine Partition ein (z. B. `/dev/sdb1`, benötigt `sudo`, stelle sicher, dass ein Gerät verfügbar ist):
   ```bash
   sudo mount /dev/sdb1 ~/mnt_tmp
   ```
   Überprüfe mit `lsblk`, ob das Gerät eingebunden ist.
4. **Schritt 4**: Liste den Inhalt des eingebundenen Geräts auf:
   ```bash
   ls ~/mnt_tmp
   ```
5. **Schritt 5**: Binde das Gerät sicher aus:
   ```bash
   sudo umount ~/mnt_tmp
   ```
   Überprüfe mit `lsblk`, ob das Gerät ausgebunden ist.
6. **Schritt 6**: Formatiere eine Partition (z. B. `/dev/sdb1`) als `ext4` (nur in einer sicheren Umgebung ausführen, da Daten gelöscht werden, benötigt `sudo`):
   ```bash
   sudo mkfs.ext4 /dev/sdb1
   ```
   **Warnung**: Dies löscht alle Daten auf der Partition.

**Reflexion**: Was passiert, wenn du versuchst, ein bereits eingebundenes Dateisystem auszubinden, während du es verwendest? Probiere `mount` ohne Argumente, um alle eingebundenen Dateisysteme zu sehen.

### Übung 3: Dienste und Systemverwaltung
**Ziel**: Lerne, wie du Dienste startest, stoppst und Systeminformationen überprüfst.

1. **Schritt 1**: Liste alle laufenden Dienste auf (benötigt `sudo`):
   ```bash
   sudo systemctl list-units --type=service --state=running
   ```
2. **Schritt 2**: Starte einen Dienst (z. B. `ssh`, falls installiert):
   ```bash
   sudo systemctl start ssh
   ```
   Überprüfe den Status:
   ```bash
   sudo systemctl status ssh
   ```
3. **Schritt 3**: Stoppe den Dienst:
   ```bash
   sudo systemctl stop ssh
   ```
   Überprüfe erneut den Status.
4. **Schritt 4**: Zeige laufende Prozesse an:
   ```bash
   ps aux
   ```
   Die Optionen `aux` zeigen alle Prozesse aller Benutzer an.
5. **Schritt 5**: Überwache Systemressourcen in Echtzeit:
   ```bash
   top
   ```
   Verlasse `top` mit der Taste `q`.
6. **Schritt 6**: Zeige die letzten Systemlogs an:
   ```bash
   journalctl -n 10
   ```
   Die Option `-n 10` zeigt die letzten 10 Zeilen.

**Reflexion**: Welche Informationen zeigt `top` im Vergleich zu `ps`? Wann würdest du `journalctl` verwenden, um Probleme zu diagnostizieren?

### Übung 4: Paketverwaltung
**Ziel**: Lerne, wie du Software mit dem Paketmanager `apt` (Debian/Ubuntu) installierst, aktualisierst und entfernst.

1. **Schritt 1**: Aktualisiere die Paketlisten (benötigt `sudo`):
   ```bash
   sudo apt update
   ```
2. **Schritt 2**: Aktualisiere alle installierten Pakete (benötigt `sudo`):
   ```bash
   sudo apt upgrade -y
   ```
   Die Option `-y` bestätigt automatisch.
3. **Schritt 3**: Installiere das Paket `htop` (ein erweiterter Systemmonitor):
   ```bash
   sudo apt install htop
   ```
   Starte `htop`:
   ```bash
   htop
   ```
   Verlasse mit `q`.
4. **Schritt 4**: Entferne das Paket `htop`:
   ```bash
   sudo apt remove htop
   ```
5. **Schritt 5**: Bereinige nicht mehr benötigte Pakete:
   ```bash
   sudo apt autoremove
   ```

**Reflexion**: Was ist der Unterschied zwischen `apt remove` und `apt purge`? Schaue in der Manpage nach (`man apt`) und überlege, wann du `autoremove` verwenden würdest.

### Übung 5: Prozessverwaltung
**Ziel**: Lerne, wie du Prozesse startest, beendest, priorisierst und im Hintergrund ausführst.

1. **Schritt 1**: Starte einen Prozess, der einige Zeit läuft, z. B. `sleep`:
   ```bash
   sleep 100
   ```
   Beende ihn mit `Ctrl + C`.
2. **Schritt 2**: Starte `sleep` im Hintergrund:
   ```bash
   sleep 100 &
   ```
   Die `&`-Option versetzt den Prozess in den Hintergrund. Liste laufende Prozesse auf:
   ```bash
   ps
   ```
   Notiere die Prozess-ID (PID) von `sleep`.
3. **Schritt 3**: Beende den `sleep`-Prozess mit seiner PID (ersetze `PID` durch die tatsächliche ID):
   ```bash
   kill PID
   ```
   Überprüfe mit `ps`, ob der Prozess beendet wurde.
4. **Schritt 4**: Starte mehrere Instanzen eines Programms, z. B. `gedit` (falls installiert):
   ```bash
   gedit &
   gedit &
   ```
   Beende alle `gedit`-Instanzen mit einem Befehl:
   ```bash
   killall gedit
   ```
5. **Schritt 5**: Starte einen Prozess mit niedriger Priorität:
   ```bash
   nice -n 10 sleep 100 &
   ```
   Die Option `-n 10` setzt eine niedrige Priorität. Überprüfe mit:
   ```bash
   ps -l
   ```
   Achte auf die `NI`-Spalte (Nice-Wert).
6. **Schritt 6**: Ändere die Priorität eines laufenden Prozesses (ersetze `PID` durch die tatsächliche ID von `sleep`):
   ```bash
   renice 15 -p PID
   ```
   Überprüfe erneut mit `ps -l`.
7. **Schritt 7**: Starte einen Prozess, pausiere ihn und hole ihn in den Vordergrund:
   ```bash
   sleep 100
   ```
   Drücke `Ctrl + Z`, um den Prozess zu pausieren. Verschiebe ihn in den Hintergrund:
   ```bash
   bg
   ```
   Hole ihn zurück in den Vordergrund:
   ```bash
   fg
   ```
   Beende mit `Ctrl + C`.

**Reflexion**: Was passiert, wenn du `kill -9 PID` statt `kill PID` verwendest? Schaue in der Manpage nach (`man kill`) und überlege, wann du `killall` statt `kill` nutzen würdest.

### Übung 6: Systemüberwachung und Leistungsanalyse
**Ziel**: Lerne, wie du Systemressourcen überwachst und Leistungsprobleme erkennst.

1. **Schritt 1**: Installiere `htop`, falls nicht bereits geschehen (benötigt `sudo`):
   ```bash
   sudo apt install htop
   ```
   Starte `htop`:
   ```bash
   htop
   ```
   Navigiere mit den Pfeiltasten und verlasse mit `q`. Achte auf CPU-, RAM- und Swap-Nutzung.
2. **Schritt 2**: Zeige den verfügbaren und genutzten Speicher an:
   ```bash
   free -h
   ```
   Die Option `-h` zeigt die Ausgabe in einem lesbaren Format.
3. **Schritt 3**: Überwache Systemressourcen mit `vmstat`:
   ```bash
   vmstat 2 5
   ```
   Dies zeigt Statistiken alle 2 Sekunden, 5 Mal lang. Achte auf Spalten wie `si`/`so` (Swap) und `us`/`sy` (CPU).
4. **Schritt 4**: Zeige Festplatten-I/O-Statistiken an (benötigt das Paket `sysstat`, falls nicht installiert):
   ```bash
   sudo apt install sysstat
   iostat -d 2 5
   ```
   Dies zeigt Festplattenaktivität alle 2 Sekunden, 5 Mal lang.
5. **Schritt 5**: Überprüfe die Systemlaufzeit und Lastdurchschnitt:
   ```bash
   uptime
   ```
   Notiere die drei Lastdurchschnittswerte (für 1, 5 und 15 Minuten).

**Reflexion**: Wie unterscheiden sich `htop` und `top` in der Darstellung? Wann würdest du `vmstat` oder `iostat` nutzen, um Leistungsprobleme zu analysieren?

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste gefährliche Befehle wie `fsck` oder `mkfs` in einer virtuellen Maschine.
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `sudo`**: Befehle wie `fsck`, `mkfs`, `systemctl`, `apt` oder `kill` können das System verändern. Überprüfe immer, was du tust.
- **Logs und Statistiken nutzen**: Verwende `journalctl`, `vmstat` oder `iostat` zur Fehlersuche und Leistungsanalyse.
- **Prozessmanagement verstehen**: Sei vorsichtig mit `kill -9`, da es Prozesse erzwungen beendet und Datenverlust verursachen kann.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für die Verwaltung von Festplatten, Dateisystemen, Diensten, Paketen, Prozessen und Systemressourcen angewendet. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `df -T` für Dateisystemtypen, `systemctl enable` für Autostart von Diensten oder `htop --filter` für gezielte Prozesssuche), um deine Fähigkeiten weiter zu verbessern.
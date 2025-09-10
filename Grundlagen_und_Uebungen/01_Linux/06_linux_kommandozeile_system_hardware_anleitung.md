# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Systeminformationen, Hardware und Kernel-Diagnose

## Einführung
Die Linux-Kommandozeile bietet leistungsstarke Werkzeuge, um Informationen über das System, die Hardware und den Kernel abzurufen sowie Diagnosen bei Problemen durchzuführen. Diese Anleitung konzentriert sich auf die Schwerpunkte **Systeminformationen und Hardware** sowie **Kernel- und Systemdiagnose**, um dir zu helfen, dein System besser zu verstehen und Fehler zu beheben. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für einige Befehle, insbesondere bei Hardware- und Kernel-Diagnose.
- Grundlegendes Verständnis von Linux-Systemen.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Diagnosebefehle risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Systeminformationen und Hardware**:
   - `lscpu`: Zeigt Informationen über die CPU.
   - `lsusb`: Listet angeschlossene USB-Geräte auf.
   - `lspci`: Listet PCI-Geräte (z. B. Grafikkarten, Netzwerkkarten) auf.
   - `dmidecode`: Zeigt detaillierte Hardwareinformationen (z. B. BIOS, RAM).
   - `uname`: Zeigt Systeminformationen (z. B. Kernel-Version, Architektur).
   - `free`: Zeigt Speicherverbrauch (RAM und Swap).
   - `df`: Zeigt Festplattennutzung.
2. **Kernel- und Systemdiagnose**:
   - `dmesg`: Zeigt Kernel-Logs für Hardware- und Systemereignisse.
   - `journalctl`: Zeigt Systemlogs, einschließlich Kernel- und Dienstinformationen.
   - `top`: Zeigt Systemressourcen und Prozesse in Echtzeit.
   - `vmstat`: Zeigt Informationen zu Prozessen, Speicher und CPU.
   - `lsblk`: Listet Blockgeräte (z. B. Festplatten, Partitionen).
3. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `sudo`: Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Systeminformationen und Hardware
**Ziel**: Lerne, wie du Informationen über CPU, USB, PCI-Geräte, Speicher und Festplatten abrufst.

1. **Schritt 1**: Zeige Informationen über die CPU deines Systems:
   ```bash
   lscpu
   ```
   Notiere Details wie CPU-Modell, Kerne und Taktfrequenz.
2. **Schritt 2**: Liste alle angeschlossenen USB-Geräte auf (benötigt oft `sudo`):
   ```bash
   sudo lsusb
   ```
   Überprüfe, ob angeschlossene Geräte (z. B. Tastatur, Maus) erkannt werden.
3. **Schritt 3**: Liste PCI-Geräte auf (z. B. Grafikkarte, Netzwerkkarte):
   ```bash
   lspci
   ```
   Suche nach Geräten wie `VGA` (Grafik) oder `Ethernet`.
4. **Schritt 4**: Zeige detaillierte Hardwareinformationen mit `dmidecode` (benötigt `sudo`):
   ```bash
   sudo dmidecode -t memory
   ```
   Die Option `-t memory` zeigt RAM-Details. Probiere auch `-t bios` für BIOS-Informationen.
5. **Schritt 5**: Zeige die Kernel-Version und Systemarchitektur an:
   ```bash
   uname -a
   ```
   Notiere die Kernel-Version (z. B. `5.15.0`) und Architektur (z. B. `x86_64`).
6. **Schritt 6**: Überprüfe den Speicherverbrauch:
   ```bash
   free -h
   ```
   Die Option `-h` zeigt die Ausgabe in einem lesbaren Format (z. B. GB, MB).
7. **Schritt 7**: Zeige die Festplattennutzung:
   ```bash
   df -h
   ```
   Notiere den verfügbaren Speicherplatz für die Root-Partition (`/`).

**Reflexion**: Welche Informationen aus `lscpu` könnten bei der Fehlersuche nützlich sein? Schaue in `man dmidecode` und überlege, wann du `lsusb` oder `lspci` verwenden würdest.

### Übung 2: Kernel- und Systemdiagnose
**Ziel**: Lerne, wie du Kernel-Logs und Systemzustände analysierst, um Probleme zu diagnostizieren.

1. **Schritt 1**: Zeige die letzten Kernel-Meldungen an:
   ```bash
   dmesg | tail -n 10
   ```
   Die Option `tail -n 10` zeigt die letzten 10 Zeilen. Suche nach Fehlern (z. B. `error` oder `failed`).
2. **Schritt 2**: Filtere `dmesg` nach USB-Ereignissen:
   ```bash
   dmesg | grep usb
   ```
   Stecke ein USB-Gerät ein/aus und führe den Befehl erneut aus, um Änderungen zu sehen.
3. **Schritt 3**: Zeige Systemlogs mit `journalctl`:
   ```bash
   journalctl -n 10
   ```
   Die Option `-n 10` zeigt die letzten 10 Zeilen. Verwende `journalctl -b` für Logs seit dem letzten Boot.
4. **Schritt 4**: Überwache Systemressourcen in Echtzeit:
   ```bash
   top
   ```
   Achte auf CPU- und Speicherauslastung. Verlasse mit `q`.
5. **Schritt 5**: Zeige Speicher- und CPU-Statistiken mit `vmstat`:
   ```bash
   vmstat 2 5
   ```
   Dies zeigt Statistiken alle 2 Sekunden, 5 Mal lang. Achte auf Spalten wie `us` (User-CPU) und `swpd` (Swap).
6. **Schritt 6**: Liste Blockgeräte auf, um Festplatten und Partitionen zu überprüfen:
   ```bash
   lsblk
   ```
   Notiere die Mountpunkte (z. B. `/` oder `/home`).

**Reflexion**: Wie unterscheiden sich `dmesg` und `journalctl` in ihrer Ausgabe? Wann würdest du `vmstat` statt `top` verwenden? Schaue in `man journalctl` für weitere Filteroptionen.

### Übung 3: Kombination von Systeminformationen und Diagnose
**Ziel**: Lerne, wie du Befehle kombinierst, um ein Systemproblem zu analysieren.

1. **Schritt 1**: Erstelle eine Datei mit Systeminformationen:
   ```bash
   echo "Systeminfo $(date)" > system_info.txt
   uname -a >> system_info.txt
   lscpu >> system_info.txt
   free -h >> system_info.txt
   ```
   Überprüfe den Inhalt:
   ```bash
   cat system_info.txt
   ```
2. **Schritt 2**: Speichere die Liste der PCI-Geräte in einer Datei:
   ```bash
   lspci > pci_geräte.txt
   ```
   Überprüfe:
   ```bash
   cat pci_geräte.txt
   ```
3. **Schritt 3**: Filtere Kernel-Logs nach Fehlern und speichere sie:
   ```bash
   dmesg | grep -i error > kernel_fehler.txt
   ```
   Überprüfe:
   ```bash
   cat kernel_fehler.txt
   ```
4. **Schritt 4**: Erstelle ein Skript, das Systeminformationen sammelt:
   ```bash
   nano system_check.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   OUTPUT_FILE="system_diagnose.txt"
   echo "Systemdiagnose am $(date)" > "$OUTPUT_FILE"
   echo "=== Kernel-Version ===" >> "$OUTPUT_FILE"
   uname -r >> "$OUTPUT_FILE"
   echo "=== Speicherverbrauch ===" >> "$OUTPUT_FILE"
   free -h >> "$OUTPUT_FILE"
   echo "=== Letzte Kernel-Fehler ===" >> "$OUTPUT_FILE"
   dmesg | grep -i error | tail -n 5 >> "$OUTPUT_FILE"
   echo "Diagnose in $OUTPUT_FILE gespeichert."
   ```
   Speichere und schließe.
5. **Schritt 5**: Mache das Skript ausführbar und führe es aus:
   ```bash
   chmod +x system_check.sh
   ./system_check.sh
   ```
   Überprüfe das Ergebnis:
   ```bash
   cat system_diagnose.txt
   ```

**Reflexion**: Wie kannst du das Skript anpassen, um weitere Informationen (z. B. `lsblk` oder `lspci`) aufzunehmen? Schaue in `man dmesg` und überlege, wie du spezifische Hardwareprobleme (z. B. Festplattenfehler) finden könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste Diagnosebefehle in einer sicheren Umgebung.
- **Fehler sind normal**: Lies Fehlermeldungen in `dmesg` oder `journalctl` sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `sudo`**: Befehle wie `dmidecode` oder `dmesg` können Administratorrechte erfordern. Überprüfe immer, was du tust.
- **Logs filtern**: Nutze `grep` mit `dmesg` oder `journalctl`, um gezielt nach Problemen zu suchen.
- **Automatisierung**: Verwende Skripte wie in Übung 3, um Diagnosen regelmäßig zu sammeln.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für Systeminformationen, Hardware und Kernel-Diagnose angewendet. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `journalctl -k` für Kernel-Logs, `lspci -v` für detaillierte Geräteinformationen oder `vmstat -d` für Festplattenstatistiken), um deine Fähigkeiten weiter zu verbessern.
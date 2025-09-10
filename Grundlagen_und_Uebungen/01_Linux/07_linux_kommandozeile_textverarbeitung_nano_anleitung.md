# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Textverarbeitung, Skripting und Umgang mit nano

## Einführung
Die Linux-Kommandozeile bietet leistungsstarke Werkzeuge für die Bearbeitung von Textdateien, die Erstellung von Shell-Skripten und die effiziente Nutzung des Texteditors `nano`. Diese Anleitung konzentriert sich auf die Schwerpunkte **Textverarbeitung und Skripting** sowie **Umgang mit nano**, um Text zu filtern, transformieren und automatisierte Aufgaben zu erstellen. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Grundlegendes Verständnis von Dateien und Verzeichnissen.
- Installation von `nano` und Standard-Tools (`sed`, `awk`, `cut`, `sort`, `uniq`), die in den meisten Linux-Distributionen vorhanden sind.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Skripte und Textbearbeitungen auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Textverarbeitung und Skripting**:
   - `sed`: Stream-Editor für Texttransformationen (z. B. Suchen/Ersetzen).
   - `awk`: Verarbeitet und analysiert strukturierte Textdaten.
   - `cut`: Extrahiert Abschnitte aus Textzeilen.
   - `sort`: Sortiert Zeilen in Textdateien.
   - `uniq`: Entfernt oder zählt doppelte Zeilen.
   - `bash`: Shell für die Erstellung und Ausführung von Skripten.
   - `chmod +x`: Macht Skripte ausführbar.
2. **Umgang mit nano**:
   - `nano`: Texteditor für die Kommandozeile mit Funktionen wie Suchen, Ersetzen, Navigation (z. B. Springen zu Zeilen), Markieren, Kopieren und Einfügen.
3. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `cat`: Zeigt den Inhalt einer Datei an.
   - `echo`: Gibt Text oder Variablen aus (nützlich in Skripten).

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Textverarbeitung
**Ziel**: Lerne, wie du Textdateien mit `sed`, `awk`, `cut`, `sort` und `uniq` bearbeitest.

1. **Schritt 1**: Erstelle eine Testdatei `daten.txt` mit folgendem Inhalt:
   ```bash
   echo -e "Anna,25,F\nBen,30,M\nClara,25,F\nAnna,28,F" > daten.txt
   ```
   Überprüfe den Inhalt:
   ```bash
   cat daten.txt
   ```
2. **Schritt 2**: Verwende `sed`, um alle Vorkommen von `Anna` durch `Anne` zu ersetzen:
   ```bash
   sed 's/Anna/Anne/g' daten.txt
   ```
   Speichere das Ergebnis in eine neue Datei:
   ```bash
   sed 's/Anna/Anne/g' daten.txt > daten_mod.txt
   ```
   Überprüfe:
   ```bash
   cat daten_mod.txt
   ```
3. **Schritt 3**: Extrahiere mit `cut` die erste Spalte (Namen) aus `daten.txt`:
   ```bash
   cut -d',' -f1 daten.txt
   ```
   Die Option `-d','` setzt das Trennzeichen auf Komma, `-f1` wählt die erste Spalte.
4. **Schritt 4**: Sortiere die Zeilen in `daten.txt` alphabetisch nach der ersten Spalte:
   ```bash
   sort daten.txt
   ```
   Speichere das Ergebnis:
   ```bash
   sort daten.txt > daten_sortiert.txt
   ```
5. **Schritt 5**: Entferne doppelte Zeilen mit `uniq` (sortiere zuerst, da `uniq` auf sortierten Eingaben arbeitet):
   ```bash
   sort daten.txt | uniq
   ```
   Speichere das Ergebnis:
   ```bash
   sort daten.txt | uniq > daten_einzigartig.txt
   ```
6. **Schritt 6**: Verwende `awk`, um nur Zeilen mit Alter 25 auszugeben:
   ```bash
   awk -F',' '$2 == 25' daten.txt
   ```
   Die Option `-F','` setzt das Komma als Trennzeichen, `$2 == 25` filtert nach der zweiten Spalte.

**Reflexion**: Wie unterscheiden sich `sed` und `awk` in ihrer Funktionalität? Schaue in `man sed` und `man awk` und überlege, wann du `cut` statt `awk` verwenden würdest.

### Übung 2: Umgang mit nano
**Ziel**: Lerne, wie du Textdateien mit `nano` bearbeitest, navigierst, suchst, ersetzt, markierst, kopierst und einfügst.

1. **Schritt 1**: Öffne `daten.txt` in `nano`:
   ```bash
   nano daten.txt
   ```
2. **Schritt 2**: Springe zu einer bestimmten Zeile (z. B. Zeile 3):
   - Drücke `Ctrl + _` (Unterstrich), gib `3` ein und drücke `Enter`.
   - Überprüfe, dass der Cursor in Zeile 3 steht.
3. **Schritt 3**: Suche nach dem Wort `Anna`:
   - Drücke `Ctrl + W`, gib `Anna` ein und drücke `Enter`.
   - Navigiere zu weiteren Treffern mit `Alt + W`.
4. **Schritt 4**: Ersetze `Anna` durch `Anne`:
   - Drücke `Ctrl + \`, gib `Anna` als Suchbegriff und `Anne` als Ersatz ein.
   - Bestätige jeden Ersatz mit `Y` oder alle mit `A`.
5. **Schritt 5**: Markiere und kopiere Text:
   - Bewege den Cursor zur ersten Zeile (z. B. mit `Ctrl + ^` für Dateianfang).
   - Drücke `Alt + ^` (oder `Alt + A` in manchen Versionen), um die Markierung zu starten.
   - Bewege den Cursor mit den Pfeiltasten, um die erste Zeile zu markieren.
   - Drücke `Alt + 6` (oder `Ctrl + K` in älteren Versionen), um den markierten Text zu kopieren.
6. **Schritt 6**: Füge den kopierten Text ein:
   - Bewege den Cursor ans Dateiende (`Ctrl + E`).
   - Drücke `Ctrl + U`, um den kopierten Text einzufügen.
7. **Schritt 7**: Speichere die Datei und verlasse `nano`:
   - Drücke `Ctrl + O`, dann `Enter` zum Speichern.
   - Drücke `Ctrl + X` zum Verlassen.
   Überprüfe den Inhalt:
   ```bash
   cat daten.txt
   ```
8. **Schritt 8**: Öffne `nano` mit Syntaxhervorhebung für ein Bash-Skript und aktivierten Zeilennummern:
   ```bash
   nano --syntax=sh --linenumbers myscript.sh
   ```
   Füge ein einfaches Skript ein:
   ```bash
   #!/bin/bash
   echo "Hallo, Welt!"
   ```
   Springe zu Zeile 2 (`Ctrl + _`, dann `2`), füge eine neue Zeile ein:
   ```bash
   echo "Testzeile"
   ```
   Speichere und verlasse.

**Reflexion**: Welche Vorteile bietet die Navigation mit `Ctrl + _` in großen Dateien? Wie unterscheiden sich Kopieren/Einfügen in `nano` von anderen Editoren wie `vim`? Drücke `Ctrl + G` in `nano`, um weitere Funktionen zu erkunden.

### Übung 3: Skriptautomatisierung
**Ziel**: Lerne, wie du Bash-Skripte erstellst, um Textverarbeitung zu automatisieren.

1. **Schritt 1**: Erstelle ein Bash-Skript, das `daten.txt` verarbeitet:
   ```bash
   nano process_data.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   INPUT_FILE="daten.txt"
   OUTPUT_FILE="verarbeitete_daten.txt"

   if [ -f "$INPUT_FILE" ]; then
       echo "Verarbeite $INPUT_FILE..."
       # Ersetze Anna durch Anne, sortiere und entferne Duplikate
       sed 's/Anna/Anne/g' "$INPUT_FILE" | sort | uniq > "$OUTPUT_FILE"
       echo "Ergebnis in $OUTPUT_FILE gespeichert."
   else
       echo "Fehler: $INPUT_FILE existiert nicht."
   fi
   ```
   Speichere und schließe.
2. **Schritt 2**: Mache das Skript ausführbar:
   ```bash
   chmod +x process_data.sh
   ```
3. **Schritt 3**: Führe das Skript aus:
   ```bash
   ./process_data.sh
   ```
   Überprüfe das Ergebnis:
   ```bash
   cat verarbeitete_daten.txt
   ```
4. **Schritt 4**: Erweitere das Skript, um nur Namen mit `awk` auszugeben. Bearbeite:
   ```bash
   nano process_data.sh
   ```
   Ändere es wie folgt:
   ```bash
   #!/bin/bash
   INPUT_FILE="daten.txt"
   OUTPUT_FILE="verarbeitete_daten.txt"
   NAME_FILE="namen.txt"

   if [ -f "$INPUT_FILE" ]; then
       echo "Verarbeite $INPUT_FILE..."
       # Ersetze Anna durch Anne, sortiere und entferne Duplikate
       sed 's/Anna/Anne/g' "$INPUT_FILE" | sort | uniq > "$OUTPUT_FILE"
       echo "Ergebnis in $OUTPUT_FILE gespeichert."
       # Extrahiere nur Namen
       awk -F',' '{print $1}' "$INPUT_FILE" > "$NAME_FILE"
       echo "Namen in $NAME_FILE gespeichert."
   else
       echo "Fehler: $INPUT_FILE existiert nicht."
   fi
   ```
   Speichere und schließe.
5. **Schritt 5**: Führe das Skript erneut aus:
   ```bash
   ./process_data.sh
   ```
   Überprüfe die neuen Dateien:
   ```bash
   cat verarbeitete_daten.txt
   cat namen.txt
   ```

**Reflexion**: Wie kannst du das Skript anpassen, um andere Texttransformationen durchzuführen (z. B. nur bestimmte Altersgruppen filtern)? Schaue in `man awk` und `man sed` für weitere Optionen.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste Skripte in einer sicheren Umgebung.
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Effiziente Skripte**: Verwende Variablen und Bedingungen in Skripten, um sie robust und wiederverwendbar zu machen.
- **Nano-Tastenkombinationen**: Merke dir wichtige Shortcuts wie `Ctrl + W` (Suchen), `Ctrl + \` (Ersetzen), `Ctrl + _` (zu Zeile springen), `Alt + ^` (Markieren), `Alt + 6` (Kopieren) und `Ctrl + U` (Einfügen).
- **Kombiniere Werkzeuge**: Nutze `sed`, `awk`, `cut`, `sort` und `uniq` in Pipelines, um komplexe Texttransformationen zu erstellen.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für Textverarbeitung, Skripting und die erweiterte Nutzung von `nano` angewendet, einschließlich Navigation, Markieren, Kopieren und Einfügen. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `sed -i` für direkte Dateibearbeitung, `awk` für komplexe Muster oder `nano --linenumbers` für Zeilennummern), um deine Fähigkeiten weiter zu verbessern.
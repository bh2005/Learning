# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Bash-Skripting und Umgang mit nano

## Einführung
Die Linux-Kommandozeile bietet leistungsstarke Werkzeuge für die Automatisierung von Aufgaben durch Bash-Skripting und die effiziente Nutzung des Texteditors `nano`. Diese Anleitung konzentriert sich auf die Schwerpunkte **Einstieg in Bash-Skripting** sowie **Umgang mit nano**, um Skripte zu erstellen, Text zu bearbeiten und Prozesse zu automatisieren. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Grundlegendes Verständnis von Dateien und Verzeichnissen.
- Installation von `nano` und Standard-Tools (`sed`, `awk`, `cut`, `sort`, `uniq`), die in den meisten Linux-Distributionen vorhanden sind.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Skripte und Textbearbeitungen auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Einstieg in Bash-Skripting**:
   - `bash`: Shell für die Erstellung und Ausführung von Skripten.
   - `chmod +x`: Macht Skripte ausführbar.
   - `echo`: Gibt Text oder Variablen aus.
   - `test`: Prüft Bedingungen (z. B. Existenz von Dateien, Vergleiche).
   - `sed`: Stream-Editor für Texttransformationen (z. B. Suchen/Ersetzen).
   - `awk`: Verarbeitet und analysiert strukturierte Textdaten.
   - `cut`: Extrahiert Abschnitte aus Textzeilen.
   - `sort`: Sortiert Zeilen in Textdateien.
   - `uniq`: Entfernt oder zählt doppelte Zeilen.
2. **Umgang mit nano**:
   - `nano`: Texteditor für die Kommandozeile mit Funktionen wie Suchen, Ersetzen, Navigation (z. B. Springen zu Zeilen), Markieren, Kopieren und Einfügen.
3. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `cat`: Zeigt den Inhalt einer Datei an.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Einstieg in Bash-Skripting
**Ziel**: Lerne, wie du Bash-Skripte erstellst, Variablen, Schleifen und Bedingungen nutzt und Textverarbeitung integrierst.

1. **Schritt 1**: Erstelle eine Testdatei `daten.txt` mit folgendem Inhalt:
   ```bash
   echo -e "Anna,25,F\nBen,30,M\nClara,25,F\nAnna,28,F" > daten.txt
   ```
   Überprüfe den Inhalt:
   ```bash
   cat daten.txt
   ```
2. **Schritt 2**: Erstelle ein Bash-Skript, das grundlegende Variablen und Bedingungen verwendet:
   ```bash
   nano basics.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   INPUT_FILE="daten.txt"
   OUTPUT_FILE="namen.txt"

   if [ -f "$INPUT_FILE" ]; then
       echo "Verarbeite $INPUT_FILE..."
       cut -d',' -f1 "$INPUT_FILE" > "$OUTPUT_FILE"
       echo "Namen in $OUTPUT_FILE gespeichert."
   else
       echo "Fehler: $INPUT_FILE existiert nicht."
       exit 1
   fi
   ```
   Speichere und schließe.
3. **Schritt 3**: Mache das Skript ausführbar und führe es aus:
   ```bash
   chmod +x basics.sh
   ./basics.sh
   ```
   Überprüfe das Ergebnis:
   ```bash
   cat namen.txt
   ```
4. **Schritt 4**: Erweitere das Skript mit einer Schleife, um jede Zeile von `daten.txt` zu verarbeiten:
   ```bash
   nano basics.sh
   ```
   Ändere es wie folgt:
   ```bash
   #!/bin/bash
   INPUT_FILE="daten.txt"
   OUTPUT_FILE="namen.txt"

   if [ -f "$INPUT_FILE" ]; then
       echo "Verarbeite $INPUT_FILE..."
       > "$OUTPUT_FILE"
       while IFS=',' read -r name age gender; do
           echo "Verarbeite: $name, Alter: $age, Geschlecht: $gender"
           echo "$name" >> "$OUTPUT_FILE"
       done < "$INPUT_FILE"
       echo "Namen in $OUTPUT_FILE gespeichert."
   else
       echo "Fehler: $INPUT_FILE existiert nicht."
       exit 1
   fi
   ```
   Speichere und schließe.
5. **Schritt 5**: Führe das Skript erneut aus:
   ```bash
   ./basics.sh
   ```
   Überprüfe das Ergebnis:
   ```bash
   cat namen.txt
   ```
6. **Schritt 6**: Integriere `sed` und `awk` in ein Skript, um Text zu transformieren:
   ```bash
   nano transform.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   INPUT_FILE="daten.txt"
   OUTPUT_FILE="transformierte_daten.txt"

   if [ -f "$INPUT_FILE" ]; then
       echo "Verarbeite $INPUT_FILE..."
       sed 's/Anna/Anne/g' "$INPUT_FILE" | awk -F',' '$2 == 25 {print $1}' | sort | uniq > "$OUTPUT_FILE"
       echo "Ergebnis in $OUTPUT_FILE gespeichert."
   else
       echo "Fehler: $INPUT_FILE existiert nicht."
       exit 1
   fi
   ```
   Speichere, mache ausführbar und führe aus:
   ```bash
   chmod +x transform.sh
   ./transform.sh
   cat transformierte_daten.txt
   ```

**Reflexion**: Wie verbessert die `while`-Schleife die Verarbeitung von `daten.txt` im Vergleich zu `cut`? Schaue in `man bash` und überlege, wie du Funktionen in das Skript einbauen könntest.

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

### Übung 3: Erweitertes Bash-Skripting
**Ziel**: Lerne, wie du Bash-Skripte mit Schleifen, Funktionen und Benutzereingaben erstellst.

1. **Schritt 1**: Erstelle ein Bash-Skript mit einer Funktion zur Textverarbeitung:
   ```bash
   nano advanced_script.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   process_file() {
       local input_file="$1"
       local output_file="$2"
       if [ -f "$input_file" ]; then
           echo "Verarbeite $input_file..."
           sed 's/Anna/Anne/g' "$input_file" | sort | uniq > "$output_file"
           echo "Ergebnis in $output_file gespeichert."
       else
           echo "Fehler: $input_file existiert nicht."
           exit 1
       fi
   }

   INPUT_FILE="daten.txt"
   OUTPUT_FILE="verarbeitete_daten.txt"
   process_file "$INPUT_FILE" "$OUTPUT_FILE"
   ```
   Speichere und schließe.
2. **Schritt 2**: Mache das Skript ausführbar und führe es aus:
   ```bash
   chmod +x advanced_script.sh
   ./advanced_script.sh
   ```
   Überprüfe das Ergebnis:
   ```bash
   cat verarbeitete_daten.txt
   ```
3. **Schritt 3**: Erweitere das Skript mit Benutzereingaben und einer Schleife:
   ```bash
   nano advanced_script.sh
   ```
   Ändere es wie folgt:
   ```bash
   #!/bin/bash
   process_file() {
       local input_file="$1"
       local output_file="$2"
       if [ -f "$input_file" ]; then
           echo "Verarbeite $input_file..."
           sed 's/Anna/Anne/g' "$input_file" | sort | uniq > "$output_file"
           echo "Ergebnis in $output_file gespeichert."
       else
           echo "Fehler: $input_file existiert nicht."
           exit 1
       fi
   }

   echo "Gib den Namen der Eingabedatei ein (Standard: daten.txt):"
   read user_input
   INPUT_FILE=${user_input:-daten.txt}
   OUTPUT_FILE="verarbeitete_daten.txt"

   process_file "$INPUT_FILE" "$OUTPUT_FILE"

   echo "Inhalt von $OUTPUT_FILE:"
   for line in $(cat "$OUTPUT_FILE"); do
       echo "Zeile: $line"
   done
   ```
   Speichere und schließe.
4. **Schritt 4**: Führe das Skript aus und teste es mit einer Eingabe:
   ```bash
   ./advanced_script.sh
   ```
   Gib `daten.txt` ein oder drücke `Enter` für den Standardwert. Überprüfe die Ausgabe.
5. **Schritt 5**: Teste das Skript mit einer nicht existierenden Datei:
   ```bash
   ./advanced_script.sh
   ```
   Gib `falsche_datei.txt` ein und überprüfe die Fehlermeldung.

**Reflexion**: Wie verbessern Funktionen die Wartbarkeit von Skripten? Warum ist die Verwendung von `local` in Funktionen wichtig? Schaue in `man bash` für weitere Schleifenarten (z. B. `for` mit Zahlen).

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste Skripte in einer sicheren Umgebung.
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Effiziente Skripte**: Verwende Variablen, Funktionen und Bedingungen, um Skripte robust und wiederverwendbar zu machen.
- **Nano-Tastenkombinationen**: Merke dir wichtige Shortcuts wie `Ctrl + W` (Suchen), `Ctrl + \` (Ersetzen), `Ctrl + _` (zu Zeile springen), `Alt + ^` (Markieren), `Alt + 6` (Kopieren) und `Ctrl + U` (Einfügen).
- **Kombiniere Werkzeuge**: Nutze `sed`, `awk`, `cut`, `sort` und `uniq` in Skripten, um komplexe Texttransformationen zu erstellen.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für Bash-Skripting und die erweiterte Nutzung von `nano` angewendet, einschließlich Navigation, Markieren, Kopieren und Einfügen. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `sed -i` für direkte Dateibearbeitung, `awk` für komplexe Muster, `bash` mit `case`-Anweisungen oder `nano --linenumbers` für Zeilennummern), um deine Fähigkeiten weiter zu verbessern.
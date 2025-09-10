# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Datei- und Verzeichnisverwaltung, Ein-/Ausgabeumleitungen und Textanzeige

## Einführung
Die Linux-Kommandozeile ist ein essenzielles Werkzeug für die Navigation im Dateisystem, die Verarbeitung von Datenströmen und die Arbeit mit Textdateien. Diese Anleitung konzentriert sich auf die Schwerpunkte **Datei- und Verzeichnisverwaltung**, **Ein-/Ausgabeumleitungen und Pipelines** sowie **Grundlegende Textanzeige und -manipulation**, um Anfängern grundlegende Fähigkeiten zu vermitteln. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Grundlegendes Verständnis von Dateien und Verzeichnissen.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Operationen risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Datei- und Verzeichnisverwaltung**:
   - `ls`: Listet den Inhalt eines Verzeichnisses auf.
   - `cd`: Wechselt das aktuelle Verzeichnis.
   - `mkdir`: Erstellt ein neues Verzeichnis.
   - `rm`: Entfernt Dateien oder Verzeichnisse.
   - `cp`: Kopiert Dateien oder Verzeichnisse.
   - `mv`: Verschiebt oder benennt Dateien/Verzeichnisse um.
   - `touch`: Erstellt leere Dateien oder aktualisiert Zeitstempel.
   - `find`: Sucht Dateien und Verzeichnisse im Dateisystem.
   - `ln`: Erstellt symbolische oder harte Links.
2. **Ein-/Ausgabeumleitungen und Pipelines**:
   - `>`: Leitet Ausgabe in eine Datei um (überschreibt).
   - `>>`: Leitet Ausgabe in eine Datei um (hängt an).
   - `<`: Liest Eingabe aus einer Datei.
   - `|`: Leitet Ausgabe eines Befehls als Eingabe an einen anderen (Pipeline).
   - `tee`: Leitet Ausgabe in eine Datei und zeigt sie gleichzeitig an.
3. **Grundlegende Textanzeige und -manipulation**:
   - `cat`: Zeigt den Inhalt einer Datei an oder verkettet Dateien.
   - `less`: Zeigt Dateien seitenweise an (navigierbar).
   - `more`: Zeigt Dateien seitenweise an (einfacher als `less`).
   - `head`: Zeigt die ersten Zeilen einer Datei.
   - `tail`: Zeigt die letzten Zeilen einer Datei.
   - `wc`: Zählt Zeilen, Wörter und Zeichen in Dateien.
4. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `echo`: Gibt Text oder Variablen aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Datei- und Verzeichnisverwaltung
**Ziel**: Lerne, wie du dich im Dateisystem bewegst und Dateien/Verzeichnisse verwaltest.

1. **Schritt 1**: Liste den Inhalt deines aktuellen Verzeichnisses auf:
   ```bash
   ls -l
   ```
   Die Option `-l` zeigt Details wie Berechtigungen und Eigentümer.
2. **Schritt 2**: Erstelle ein neues Verzeichnis `test_dir`:
   ```bash
   mkdir test_dir
   ```
   Wechsle in das Verzeichnis:
   ```bash
   cd test_dir
   ```
3. **Schritt 3**: Erstelle zwei leere Dateien:
   ```bash
   touch datei1.txt datei2.txt
   ```
   Überprüfe:
   ```bash
   ls
   ```
4. **Schritt 4**: Kopiere `datei1.txt` nach `datei1_kopie.txt`:
   ```bash
   cp datei1.txt datei1_kopie.txt
   ```
   Überprüfe:
   ```bash
   ls
   ```
5. **Schritt 5**: Verschiebe `datei2.txt` in ein neues Unterverzeichnis `unter_dir`:
   ```bash
   mkdir unter_dir
   mv datei2.txt unter_dir/
   ```
   Überprüfe:
   ```bash
   ls unter_dir
   ```
6. **Schritt 6**: Erstelle einen symbolischen Link zu `datei1.txt`:
   ```bash
   ln -s datei1.txt link_zu_datei1
   ```
   Überprüfe:
   ```bash
   ls -l
   ```
   Achte auf das `l` in der Ausgabe, das den Link anzeigt.
7. **Schritt 7**: Suche nach allen `.txt`-Dateien im Verzeichnis `test_dir`:
   ```bash
   find . -name "*.txt"
   ```
8. **Schritt 8**: Entferne `datei1_kopie.txt`:
   ```bash
   rm datei1_kopie.txt
   ```
   Überprüfe:
   ```bash
   ls
   ```

**Reflexion**: Was ist der Unterschied zwischen `cp` und `mv`? Schaue in `man ln` und überlege, warum symbolische Links nützlich sind.

### Übung 2: Ein-/Ausgabeumleitungen und Pipelines
**Ziel**: Lerne, wie du Datenströme umleitest und Befehle kombinierst.

1. **Schritt 1**: Erstelle eine Datei mit einer Liste von Dateien im aktuellen Verzeichnis:
   ```bash
   ls > liste.txt
   ```
   Überprüfe den Inhalt:
   ```bash
   cat liste.txt
   ```
2. **Schritt 2**: Hänge die Ausgabe von `ls -l` an `liste.txt` an:
   ```bash
   ls -l >> liste.txt
   ```
   Überprüfe:
   ```bash
   cat liste.txt
   ```
3. **Schritt 3**: Erstelle eine Datei `eingabe.txt` mit Inhalt:
   ```bash
   echo -e "Zeile 1\nZeile 2\nZeile 3" > eingabe.txt
   ```
4. **Schritt 4**: Verwende eine Pipeline, um die Zeilen von `eingabe.txt` zu sortieren und in `sortiert.txt` zu speichern:
   ```bash
   cat eingabe.txt | sort > sortiert.txt
   ```
   Überprüfe:
   ```bash
   cat sortiert.txt
   ```
5. **Schritt 5**: Verwende `tee`, um die Ausgabe von `ls` gleichzeitig anzuzeigen und in eine Datei zu schreiben:
   ```bash
   ls | tee ausgabe.txt
   ```
   Überprüfe:
   ```bash
   cat ausgabe.txt
   ```
6. **Schritt 6**: Lies Eingaben aus einer Datei für einen Befehl:
   ```bash
   grep "Zeile" < eingabe.txt
   ```

**Reflexion**: Was passiert, wenn du `>` statt `>>` verwendest? Schaue in `man tee` und überlege, wie Pipelines die Effizienz erhöhen.

### Übung 3: Grundlegende Textanzeige und -manipulation
**Ziel**: Lerne, wie du Textdateien anzeigst und analysierst.

1. **Schritt 1**: Zeige den Inhalt von `eingabe.txt` an:
   ```bash
   cat eingabe.txt
   ```
2. **Schritt 2**: Zeige `eingabe.txt` seitenweise mit `less` an:
   ```bash
   less eingabe.txt
   ```
   Navigiere mit den Pfeiltasten, suche mit `/Zeile` und verlasse mit `q`.
3. **Schritt 3**: Zeige nur die ersten zwei Zeilen von `eingabe.txt`:
   ```bash
   head -n 2 eingabe.txt
   ```
   Die Option `-n 2` begrenzt auf zwei Zeilen.
4. **Schritt 4**: Zeige die letzten zwei Zeilen von `eingabe.txt`:
   ```bash
   tail -n 2 eingabe.txt
   ```
5. **Schritt 5**: Zähle Zeilen, Wörter und Zeichen in `eingabe.txt`:
   ```bash
   wc eingabe.txt
   ```
   Beachte die Ausgabe: Zeilen, Wörter, Zeichen.
6. **Schritt 6**: Kombiniere Befehle in einer Pipeline, um die Anzahl eindeutiger Dateien in `test_dir` zu zählen:
   ```bash
   ls test_dir | sort | uniq | wc -l
   ```

**Reflexion**: Wie unterscheiden sich `less` und `more`? Schaue in `man wc` und überlege, wann du `head` oder `tail` für Logdateien verwenden würdest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst. Teste `rm` und ähnliche Befehle in einer sicheren Umgebung.
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `rm`**: Nutze `rm -i`, um versehentliches Löschen zu vermeiden.
- **Pipelines effektiv nutzen**: Kombiniere Befehle wie `ls`, `grep` und `wc` in Pipelines, um komplexe Aufgaben zu lösen.
- **Textanzeige optimieren**: Verwende `less` für große Dateien und `tail -f` für Echtzeit-Logs.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für Datei- und Verzeichnisverwaltung, Ein-/Ausgabeumleitungen und grundlegende Textanzeige angewendet. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `find -type f` für Dateisuche, `tee -a` für Anhängen oder `tail -f` für Live-Logs), um deine Fähigkeiten weiter zu verbessern.
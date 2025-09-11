# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle

## Einführung
Die Linux-Kommandozeile ist ein mächtiges Werkzeug zur Interaktion mit dem Betriebssystem. Diese Anleitung führt dich durch die grundlegenden Befehle und bietet praktische Übungen, um sie direkt anzuwenden und zu verinnerlichen. Ziel ist es, dir Vertrauen im Umgang mit der Kommandozeile zu geben, indem du die Befehle in realistischen Szenarien übst.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Grundlegendes Verständnis von Dateien und Verzeichnissen.
- Für einige Befehle (`useradd`, `groupadd`, `chown`) sind Administratorrechte (`sudo`) erforderlich.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln:

1. **Navigationsbefehle**:
   - `pwd`: Zeigt das aktuelle Arbeitsverzeichnis an.
   - `ls`: Listet Dateien und Verzeichnisse im aktuellen Verzeichnis auf.
   - `cd`: Wechselt das Verzeichnis.
2. **Datei- und Verzeichnisverwaltung**:
   - `mkdir`: Erstellt ein neues Verzeichnis.
   - `touch`: Erstellt eine neue leere Datei.
   - `rm`: Löscht Dateien oder Verzeichnisse.
   - `cp`: Kopiert Dateien oder Verzeichnisse.
   - `mv`: Verschiebt oder benennt Dateien/Verzeichnisse.
   - `chmod`: Ändert die Berechtigungen von Dateien oder Verzeichnissen.
   - `chown`: Ändert den Eigentümer oder die Gruppe von Dateien/Verzeichnissen.
   - `useradd`: Erstellt einen neuen Benutzer.
   - `groupadd`: Erstellt eine neue Gruppe.
3. **Dateiinhalte anzeigen und bearbeiten**:
   - `cat`: Zeigt den Inhalt einer Datei an.
   - `less`: Ermöglicht das Durchscrollen langer Dateien.
   - `tee`: Liest von der Standardeingabe und schreibt gleichzeitig in Dateien und die Standardausgabe.
4. **Suche und Filterung**:
   - `grep`: Durchsucht Text in Dateien nach Mustern.
   - `find`: Sucht Dateien und Verzeichnisse im Dateisystem.
5. **Ein- und Ausgabeumleitungen & Pipes**:
   - `>`: Leitet die Ausgabe in eine Datei um (überschreibt).
   - `>>`: Leitet die Ausgabe in eine Datei um (hängt an).
   - `|`: Leitet die Ausgabe eines Befehls als Eingabe an einen anderen Befehl weiter.
6. **Dateikomprimierung und -archivierung**:
   - `tar`: Archiviert Dateien in ein Tar-Archiv oder entpackt sie.
   - `gzip`: Komprimiert Dateien oder entpackt `.gz`-Dateien.
   - `zip`: Erstellt ZIP-Archive.
   - `unzip`: Entpackt ZIP-Archive.
7. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `clear`: Löscht die Terminalanzeige.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Navigation im Dateisystem
**Ziel**: Verstehe, wo du dich im Dateisystem befindest und wie du dich bewegst.

1. **Schritt 1**: Öffne dein Terminal.
2. **Schritt 2**: Finde heraus, in welchem Verzeichnis du dich befindest:
   ```bash
   pwd
   ```
   Notiere dir das angezeigte Verzeichnis (z. B. `/home/user`).
3. **Schritt 3**: Liste alle Dateien und Verzeichnisse im aktuellen Verzeichnis auf:
   ```bash
   ls
   ```
   Probiere auch `ls -l` für eine detaillierte Liste und `ls -a` für versteckte Dateien.
4. **Schritt 4**: Wechsle in das Verzeichnis `Documents` (falls vorhanden):
   ```bash
   cd Documents
   ```
   Überprüfe mit `pwd`, ob du im richtigen Verzeichnis bist.
5. **Schritt 5**: Kehre zurück in dein Home-Verzeichnis:
   ```bash
   cd ~
   ```

**Reflexion**: Was passiert, wenn du `cd ..` eingibst? Probiere es aus und überprüfe mit `pwd`.

### Übung 2: Verzeichnisse, Dateien und Berechtigungen verwalten
**Ziel**: Lerne, wie du Verzeichnisse, Dateien, Berechtigungen und Benutzer/Gruppen verwaltest.

1. **Schritt 1**: Erstelle ein neues Verzeichnis namens `uebung`:
   ```bash
   mkdir uebung
   ```
2. **Schritt 2**: Wechsle in das neue Verzeichnis:
   ```bash
   cd uebung
   ```
3. **Schritt 3**: Erstelle eine leere Datei namens `notizen.txt`:
   ```bash
   touch notizen.txt
   ```
4. **Schritt 4**: Überprüfe, ob die Datei erstellt wurde:
   ```bash
   ls
   ```
5. **Schritt 5**: Kopiere die Datei `notizen.txt` zu `notizen_kopie.txt`:
   ```bash
   cp notizen.txt notizen_kopie.txt
   ```
6. **Schritt 6**: Benenne `notizen_kopie.txt` in `backup.txt` um:
   ```bash
   mv notizen_kopie.txt backup.txt
   ```
7. **Schritt 7**: Ändere die Berechtigungen von `notizen.txt`, um nur dem Eigentümer Lese- und Schreibrechte zu geben:
   ```bash
   chmod 600 notizen.txt
   ```
   Überprüfe die Berechtigungen mit:
   ```bash
   ls -l
   ```
   Du solltest `-rw-------` für `notizen.txt` sehen.
8. **Schritt 8**: Erstelle eine neue Gruppe namens `team` (benötigt `sudo`):
   ```bash
   sudo groupadd team
   ```
9. **Schritt 9**: Erstelle einen neuen Benutzer namens `testuser` (benötigt `sudo`):
   ```bash
   sudo useradd -m -g team testuser
   ```
   Die Option `-m` erstellt ein Home-Verzeichnis, `-g team` weist den Benutzer der Gruppe `team` zu.
10. **Schritt 10**: Ändere den Eigentümer von `notizen.txt` zu `testuser` und der Gruppe `team` (benötigt `sudo`):
    ```bash
    sudo chown testuser:team notizen.txt
    ```
    Überprüfe mit:
    ```bash
    ls -l
    ```
11. **Schritt 11**: Lösche die Datei `backup.txt`:
    ```bash
    rm backup.txt
    ```

**Reflexion**: Was bedeuten die Zahlen in `chmod 600`? Schaue in der Manpage nach (`man chmod`) und überlege, wie du die Berechtigungen für eine Gruppe ändern würdest.

### Übung 3: Dateiinhalte anzeigen und bearbeiten
**Ziel**: Lerne, wie du Dateiinhalte anzeigst, navigierst und gleichzeitig in Dateien schreibst, sowie Ein- und Ausgabeumleitungen verwendest.

1. **Schritt 1**: Erstelle eine Textdatei mit Inhalt. Schreibe folgenden Befehl, um Text in `notizen.txt` zu schreiben, und leite die Ausgabe um:
   ```bash
   echo "Das ist ein Test für die Linux-Kommandozeile." > notizen.txt
   ```
2. **Schritt 2**: Zeige den Inhalt der Datei an:
   ```bash
   cat notizen.txt
   ```
3. **Schritt 3**: Verwende `tee`, um Text in eine neue Datei `ausgabe.txt` zu schreiben und gleichzeitig auf dem Bildschirm anzuzeigen (benötigt `sudo` für Schreibrechte in manchen Kontexten):
   ```bash
   echo "Dieser Text wird gespeichert und angezeigt." | tee ausgabe.txt
   ```
   Überprüfe den Inhalt von `ausgabe.txt`:
   ```bash
   cat ausgabe.txt
   ```
4. **Schritt 4**: Füge Text an `ausgabe.txt` an, ohne die Datei zu überschreiben:
   ```bash
   echo "Dies ist eine weitere Zeile." >> ausgabe.txt
   ```
   Überprüfe den Inhalt:
   ```bash
   cat ausgabe.txt
   ```
5. **Schritt 5**: Erstelle eine längere Datei, indem du mehrere Zeilen hinzufügst:
   ```bash
   echo -e "Zeile 1\nZeile 2\nZeile 3\nZeile 4" > lange_datei.txt
   ```
6. **Schritt 6**: Schaue dir die Datei mit `less` an:
   ```bash
   less lange_datei.txt
   ```
   Navigiere mit den Pfeiltasten, und verlasse `less` mit der Taste `q`.
7. **Schritt 7**: Kombiniere `cat` und `tee` mit einer Pipe, um den Inhalt von `notizen.txt` in eine neue Datei `kombiniert.txt` zu schreiben und anzuzeigen:
   ```bash
   cat notizen.txt | tee kombiniert.txt
   ```

**Reflexion**: Wie unterscheidet sich `tee` von `>`? Probiere `echo "Test" | tee -a ausgabe.txt` und überprüfe, wie sich die Datei verändert. Was bewirkt die Pipe (`|`) in Schritt 7?

### Übung 4: Hilfe und Dokumentation
**Ziel**: Lerne, wie du Hilfe zu Befehlen findest.

1. **Schritt 1**: Schaue dir die Dokumentation für den Befehl `ls` an:
   ```bash
   man ls
   ```
   Navigiere mit den Pfeiltasten und verlasse mit `q`.
2. **Schritt 2**: Finde heraus, was die Option `-R` für `ls` bewirkt, indem du die Manpage durchsuchst.
3. **Schritt 3**: Probiere den Befehl mit der Option aus:
   ```bash
   ls -R
   ```

**Reflexion**: Welche anderen Optionen für `ls` findest du in der Manpage, die nützlich sein könnten?

### Übung 5: Suche mit `grep` und `find`
**Ziel**: Lerne, wie du Dateien und Inhalte mit `grep` und `find` suchst und Pipes sowie Umleitungen kombinierst.

1. **Schritt 1**: Erstelle mehrere Textdateien für die Suche:
   ```bash
   echo "Hallo Welt" > datei1.txt
   echo "Linux ist großartig" > datei2.txt
   echo "Hallo Linux" > datei3.txt
   ```
2. **Schritt 2**: Suche nach dem Wort `Hallo` in allen `.txt`-Dateien im aktuellen Verzeichnis:
   ```bash
   grep "Hallo" *.txt
   ```
   Notiere, welche Dateien Treffer enthalten.
3. **Schritt 3**: Suche nach dem Wort `Linux` und leite die Ausgabe in eine Datei `ergebnisse.txt` um:
   ```bash
   grep "Linux" *.txt > ergebnisse.txt
   ```
   Überprüfe den Inhalt:
   ```bash
   cat ergebnisse.txt
   ```
4. **Schritt 4**: Verwende `find`, um alle `.txt`-Dateien im aktuellen Verzeichnis zu finden:
   ```bash
   find . -type f -name "*.txt"
   ```
   Die Option `-type f` sucht nach Dateien, `-name "*.txt"` filtert nach Dateien mit der Endung `.txt`.
5. **Schritt 5**: Kombiniere `find` und `grep` mit einer Pipe, um nach Dateien zu suchen, die das Wort `Hallo` enthalten:
   ```bash
   find . -type f -name "*.txt" -exec grep "Hallo" {} \;
   ```
   Alternativ mit einer Pipe:
   ```bash
   find . -type f -name "*.txt" | xargs grep "Hallo"
   ```
6. **Schritt 6**: Speichere die Namen aller `.txt`-Dateien in einer Datei `dateiliste.txt`:
   ```bash
   find . -type f -name "*.txt" > dateiliste.txt
   ```
   Überprüfe:
   ```bash
   cat dateiliste.txt
   ```

**Reflexion**: Was ist der Unterschied zwischen `grep` und `find`? Wann würdest du `grep` allein verwenden und wann in Kombination mit `find`?

### Übung 6: Dateikomprimierung und -archivierung
**Ziel**: Lerne, wie du Dateien archivieren und komprimieren kannst, und wie du Archive entpackst.

1. **Schritt 1**: Stelle sicher, dass du im Verzeichnis `uebung` bist, und erstelle einige Testdateien, falls nicht bereits vorhanden:
   ```bash
   echo "Testdaten 1" > test1.txt
   echo "Testdaten 2" > test2.txt
   echo "Testdaten 3" > test3.txt
   ```
2. **Schritt 2**: Erstelle ein Tar-Archiv mit den `.txt`-Dateien:
   ```bash
   tar -cvf texte.tar *.txt
   ```
   Die Optionen bedeuten: `-c` (create), `-v` (verbose, zeigt Dateien an), `-f` (Dateiname des Archivs).
3. **Schritt 3**: Komprimiere das Tar-Archiv mit `gzip`:
   ```bash
   gzip texte.tar
   ```
   Überprüfe, dass `texte.tar.gz` erstellt wurde:
   ```bash
   ls
   ```
4. **Schritt 4**: Entpacke das komprimierte Archiv wieder:
   ```bash
   gunzip texte.tar.gz
   ```
   Überprüfe, dass `texte.tar` wiederhergestellt wurde:
   ```bash
   ls
   ```
5. **Schritt 5**: Extrahiere die Dateien aus dem Tar-Archiv:
   ```bash
   tar -xvf texte.tar
   ```
   Die Option `-x` bedeutet extract. Überprüfe, dass die ursprünglichen `.txt`-Dateien wiederhergestellt wurden:
   ```bash
   ls
   ```
6. **Schritt 6**: Erstelle ein ZIP-Archiv mit den `.txt`-Dateien:
   ```bash
   zip texte.zip *.txt
   ```
   Überprüfe, dass `texte.zip` erstellt wurde:
   ```bash
   ls
   ```
7. **Schritt 7**: Entpacke das ZIP-Archiv in ein neues Verzeichnis `entpackt`:
   ```bash
   mkdir entpackt
   unzip texte.zip -d entpackt
   ```
   Wechsle in das Verzeichnis und überprüfe den Inhalt:
   ```bash
   cd entpackt
   ls
   ```
8. **Schritt 8**: Kombiniere `find` und `tar`, um alle `.txt`-Dateien in ein komprimiertes Archiv zu packen:
   ```bash
   cd ..
   find . -type f -name "*.txt" | xargs tar -czvf texte_kombiniert.tar.gz
   ```
   Die Option `-z` komprimiert das Archiv direkt mit `gzip`. Überprüfe:
   ```bash
   ls
   ```

**Reflexion**: Was ist der Unterschied zwischen `tar` und `zip`? Wann würdest du `gzip` zusätzlich zu `tar` verwenden? Probiere `tar -tzvf texte_kombiniert.tar.gz`, um den Inhalt des Archivs ohne Entpacken anzuzeigen.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Verwende `man <befehl>`, um Optionen zu verstehen, bevor du sie ausprobierst.
- **Fehler sind normal**: Wenn ein Befehl nicht funktioniert, lies die Fehlermeldung und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `sudo`**: Befehle wie `useradd`, `groupadd` und `chown` verändern das System. Teste sie in einer sicheren Umgebung (z. B. virtuelle Maschine).
- **Kombiniere Befehle**: Pipes und Umleitungen sind mächtig, um komplexe Aufgaben zu lösen. Experimentiere mit verschiedenen Kombinationen.
- **Archivierung verstehen**: Übe verschiedene Komprimierungsformate, um die Vor- und Nachteile von `tar`, `gzip` und `zip` zu verstehen.

## Fazit
Durch diese Übungen hast du die grundlegenden Linux-Kommandozeilenbefehle angewendet, einschließlich Suchwerkzeugen wie `grep` und `find`, fortgeschrittenen Techniken wie Pipes und Umleitungen sowie Dateikomprimierung und -archivierung mit `tar`, `gzip`, `zip` und `unzip`. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `grep -r`, `find -mtime` oder `tar --exclude`), um deine Fähigkeiten weiter zu verbessern.
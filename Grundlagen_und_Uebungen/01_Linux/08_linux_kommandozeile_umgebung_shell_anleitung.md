# Praxisorientierte Anleitung: Grundlegende Linux-Kommandozeilenbefehle für Umgebungsvariablen, Shell-Konfiguration und Aliases

## Einführung
Die Linux-Kommandozeile ermöglicht es, die Shell-Umgebung durch Umgebungsvariablen, Konfigurationsdateien und Aliases individuell anzupassen, um Arbeitsabläufe zu optimieren. Diese Anleitung konzentriert sich auf die Schwerpunkte **Umgebungsvariablen und Shell-Konfiguration** sowie **Aliases und Shell-Funktionen**, um dir zu helfen, die Shell effizient zu gestalten. Durch praktische Übungen lernst du, die wichtigsten Befehle direkt anzuwenden und zu verinnerlichen, mit einem besonderen Fokus auf die vielfältigen Möglichkeiten der `.bashrc`.

Voraussetzungen:
- Ein Linux-System (z. B. Ubuntu, Debian oder eine virtuelle Maschine).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Grundlegendes Verständnis von Linux-Befehlen und der Shell (`bash` wird in dieser Anleitung verwendet).
- Sichere Testumgebung (z. B. virtuelle Maschine), um Konfigurationsänderungen risikofrei auszuprobieren.

## Grundlegende Befehle
Hier sind die wichtigsten Linux-Befehle, die wir in dieser Anleitung behandeln, aufgeteilt nach den Schwerpunkten:

1. **Umgebungsvariablen und Shell-Konfiguration**:
   - `env`: Zeigt alle Umgebungsvariablen an oder führt Befehle in einer modifizierten Umgebung aus.
   - `export`: Exportiert Umgebungsvariablen für Subprozesse.
   - `set`: Zeigt Shell-Variablen und deren Werte an.
   - `unset`: Entfernt eine Umgebungsvariable.
   - `source` oder `.`: Lädt Konfigurationsdateien (z. B. `.bashrc`) in die aktuelle Shell.
   - `echo`: Gibt den Wert einer Variable aus (z. B. `echo $PATH`).
   - `PS1`: Anpassen des Shell-Prompts in der `.bashrc`.
2. **Aliases und Shell-Funktionen**:
   - `alias`: Erstellt oder zeigt Aliases (Abkürzungen für Befehle).
   - `unalias`: Entfernt Aliases.
   - `function`: Definiert Shell-Funktionen in der `.bashrc` oder in Skripten.
3. **Sonstige nützliche Befehle**:
   - `man`: Zeigt die Hilfeseite eines Befehls an.
   - `nano`: Texteditor zum Bearbeiten von Konfigurationsdateien wie `.bashrc`.
   - `cat`: Zeigt den Inhalt von Dateien an.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Umgebungsvariablen und Shell-Konfiguration
**Ziel**: Lerne, wie du Umgebungsvariablen anzeigst, setzt und die `.bashrc` für verschiedene Anpassungen wie Prompts, Pfade, automatische Befehle und externe Skripte konfigurierst.

1. **Schritt 1**: Zeige alle Umgebungsvariablen an:
   ```bash
   env
   ```
   Suche nach bekannten Variablen wie `PATH`, `HOME` oder `USER`.
2. **Schritt 2**: Zeige den Wert der `PATH`-Variable:
   ```bash
   echo $PATH
   ```
   Notiere die Verzeichnisse, die durch `:` getrennt sind.
3. **Schritt 3**: Setze eine temporäre Umgebungsvariable `MY_VAR`:
   ```bash
   export MY_VAR="Hallo, Welt!"
   ```
   Überprüfe:
   ```bash
   echo $MY_VAR
   ```
4. **Schritt 4**: Entferne die Variable `MY_VAR`:
   ```bash
   unset MY_VAR
   ```
   Überprüfe, dass sie entfernt wurde:
   ```bash
   echo $MY_VAR
   ```
   (Die Ausgabe sollte leer sein.)
5. **Schritt 5**: Füge eine dauerhafte Umgebungsvariable zur `.bashrc` hinzu:
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende der Datei hinzu:
   ```bash
   export MY_VAR="Hallo, Welt!"
   ```
   Speichere und schließe (`Ctrl + O`, `Enter`, `Ctrl + X`).
   Lade die `.bashrc`:
   ```bash
   source ~/.bashrc
   ```
   Überprüfe:
   ```bash
   echo $MY_VAR
   ```
6. **Schritt 6**: Passe den Shell-Prompt an, um Benutzer und Verzeichnis farbig anzuzeigen:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   export PS1='\[\e[32m\]\u@\h:\[\e[34m\]\w\[\e[0m\]\$ '
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Beachte den neuen Prompt (z. B. grüner Benutzername und blaues Verzeichnis).
7. **Schritt 7**: Füge ein Verzeichnis für benutzerdefinierte Skripte zu `PATH` hinzu:
   ```bash
   mkdir ~/scripts
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   export PATH="$PATH:$HOME/scripts"
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Überprüfe:
   ```bash
   echo $PATH
   ```
8. **Schritt 8**: Führe einen Befehl automatisch beim Shell-Start aus:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   echo "Willkommen, $USER! Systemzeit: $(date)"
   ```
   Speichere, schließe und öffne ein neues Terminal, um die Nachricht zu sehen.
9. **Schritt 9**: Lade eine externe Konfigurationsdatei in die `.bashrc`:
   ```bash
   nano ~/.my_custom_config
   ```
   Füge hinzu:
   ```bash
   export MY_CUSTOM_VAR="Meine Konfiguration"
   ```
   Speichere und schließe. Bearbeite die `.bashrc`:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   if [ -f ~/.my_custom_config ]; then
       source ~/.my_custom_config
   fi
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Überprüfe:
   ```bash
   echo $MY_CUSTOM_VAR
   ```

**Reflexion**: Wie verbessert ein angepasster Prompt die Produktivität? Warum ist das Laden externer Konfigurationsdateien nützlich? Schaue in `man bash` für weitere `PS1`-Optionen (z. B. `\t` für Zeit).

### Übung 2: Aliases und Shell-Funktionen
**Ziel**: Lerne, wie du Aliases und Shell-Funktionen erstellst, um Befehle zu vereinfachen.

1. **Schritt 1**: Zeige alle definierten Aliases an:
   ```bash
   alias
   ```
   Notiere, ob Aliases wie `ll` (oft für `ls -l`) existieren.
2. **Schritt 2**: Erstelle einen temporären Alias für `ls -l`:
   ```bash
   alias ll='ls -l'
   ```
   Teste den Alias:
   ```bash
   ll
   ```
3. **Schritt 3**: Entferne den Alias `ll`:
   ```bash
   unalias ll
   ```
   Überprüfe, dass der Alias entfernt wurde:
   ```bash
   ll
   ```
   (Dies sollte einen Fehler erzeugen.)
4. **Schritt 4**: Füge einen dauerhaften Alias zu `.bashrc` hinzu:
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende hinzu:
   ```bash
   alias ll='ls -l'
   ```
   Speichere und schließe. Lade die `.bashrc`:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   ll
   ```
5. **Schritt 5**: Erstelle eine Shell-Funktion in der `.bashrc`:
   ```bash
   nano ~/.bashrc
   ```
   Füge am Ende hinzu:
   ```bash
   function welcome() {
       echo "Willkommen, $USER! Heutiges Datum: $(date)"
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste die Funktion:
   ```bash
   welcome
   ```
6. **Schritt 6**: Erstelle eine Funktion, die einen Befehl mit einer Umgebungsvariable kombiniert:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function show_path() {
       echo "Dein PATH ist: $PATH"
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   show_path
   ```

**Reflexion**: Wann ist ein Alias nützlicher als eine Funktion? Schaue in `man bash` und überlege, wie Funktionen komplexere Aufgaben automatisieren können.

### Übung 3: Kombination von Umgebungsvariablen, Aliases und Funktionen
**Ziel**: Lerne, wie du Umgebungsvariablen, Aliases und Funktionen kombinierst, um Aufgaben zu automatisieren.

1. **Schritt 1**: Erstelle ein Skript, das die Umgebungsvariable aus Übung 1 verwendet:
   ```bash
   nano ~/scripts/check_custom.sh
   ```
   Füge folgenden Inhalt ein:
   ```bash
   #!/bin/bash
   echo "Benutzer: $USER"
   echo "Custom Variable: $MY_CUSTOM_VAR"
   alias ll='ls -l'
   ll
   ```
   Speichere und schließe.
2. **Schritt 2**: Mache das Skript ausführbar und teste es:
   ```bash
   chmod +x ~/scripts/check_custom.sh
   check_custom.sh
   ```
   Beachte, dass der Alias `ll` nur im Skript funktioniert.
3. **Schritt 3**: Erweitere das Skript mit einer Funktion:
   ```bash
   nano ~/scripts/check_custom.sh
   ```
   Ändere es wie folgt:
   ```bash
   #!/bin/bash
   check_info() {
       echo "Benutzer: $USER"
       echo "Custom Variable: $MY_CUSTOM_VAR"
       echo "Systemzeit: $(date)"
   }

   alias ll='ls -l'
   echo "Starte Systemprüfung..."
   check_info
   ll
   ```
   Speichere, schließe und teste:
   ```bash
   check_custom.sh
   ```
4. **Schritt 4**: Erstelle einen Alias für das Skript in der `.bashrc`:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   alias checksys='~/scripts/check_custom.sh'
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   checksys
   ```

**Reflexion**: Wie kannst du die `.bashrc` nutzen, um komplexere Skripte oder Funktionen zu organisieren? Überlege, wie du Konfigurationsdateien in `~/.config/` strukturieren könntest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Befehle zu verinnerlichen.
- **Experimentiere sicher**: Sichere `.bashrc` vor Änderungen (z. B. `cp ~/.bashrc ~/.bashrc.bak`). Teste Änderungen mit `source ~/.bashrc`, bevor du die Shell neu startest.
- **Fehler sind normal**: Lies Fehlermeldungen sorgfältig und nutze `man` oder Online-Ressourcen.
- **Vorsicht bei `.bashrc`**: Vermeide Endlosschleifen oder Konflikte (z. B. durch doppelte Aliases). Überprüfe Änderungen schrittweise.
- **Effiziente Aliases**: Erstelle Aliases für häufig verwendete Befehle, aber vermeide Konflikte mit bestehenden Befehlen.
- **Funktionen modularisieren**: Schreibe Funktionen, die wiederverwendbar sind, und lagere komplexe Konfigurationen in separate Dateien aus.

## Fazit
Durch diese Übungen hast du grundlegende Linux-Kommandozeilenbefehle für Umgebungsvariablen, Shell-Konfiguration und Aliases/Funktionen angewendet, mit einem Schwerpunkt auf die vielfältigen Möglichkeiten der `.bashrc`. Wiederhole die Übungen und experimentiere mit weiteren Optionen (z. B. `PS1` mit Git-Status, `export -f` für Funktionen in Subshells oder komplexe Funktionen mit Parameterübergabe), um deine Fähigkeiten weiter zu verbessern.
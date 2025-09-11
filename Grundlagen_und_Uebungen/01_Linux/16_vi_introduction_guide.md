# Praxisorientierte Anleitung: Einstieg in vi – Grundlagen und Shell-Integration

## Einführung zu vi/vim
`vi` (oder `vim`, Vi Improved) ist ein modusbasiertes Texteditor-Tool, das für seine Effizienz und Allgegenwart bekannt ist. Es arbeitet in drei Hauptmodi:
- **Normalmodus**: Für Navigation und Befehle (Standard beim Öffnen).
- **Einfügemodus**: Für das Schreiben und Bearbeiten von Text (`i` zum Eintreten).
- **Befehlszeilenmodus**: Für komplexe Befehle wie Speichern, Suchen oder Beenden (`:`).

Diese Anleitung führt dich in die grundlegenden Befehle ein, zeigt, wie du `vi` konfigurierst, und integriert es mit der `.bashrc` für Workflows in der HomeLab-Umgebung (z. B. Bearbeitung von Papermerge-Konfigurationen).

## Grundlegende vi-Befehle
- **Starten**: `vi <datei>` oder `vim <datei>`.
- **Modi**:
  - Normalmodus: Standard, für Navigation (`Esc` zum Zurückkehren).
  - Einfügemodus: `i` (vor Cursor), `a` (nach Cursor), `o` (neue Zeile unten).
  - Befehlszeilenmodus: `:` (z. B. `:w` zum Speichern, `:q` zum Beenden).
- **Navigation** (Normalmodus):
  - `h`, `j`, `k`, `l`: Links, unten, oben, rechts.
  - `w` / `b`: Zum nächsten/vorherigen Wort.
  - `0` / `$`: Zeilenanfang/Ende.
  - `gg` / `G`: Dokumentanfang/Ende.
  - `:n`: Gehe zu Zeile `n` (z. B. `:10`).
- **Bearbeitung** (Normalmodus):
  - `x`: Zeichen löschen.
  - `dd`: Zeile löschen.
  - `yy`: Zeile kopieren.
  - `p` / `P`: Einfügen nach/vor Cursor.
  - `u`: Rückgängig.
  - `Ctrl+r`: Wiederherstellen.
- **Suchen und Ersetzen**:
  - `/muster`: Suche nach `muster` (vorwärts), `n` für nächster Treffer.
  - `?muster`: Suche rückwärts.
  - `:%s/alt/neu/g`: Ersetze `alt` mit `neu` im gesamten Dokument.
- **Speichern und Beenden**:
  - `:w`: Speichern.
  - `:q`: Beenden.
  - `:wq` oder `ZZ`: Speichern und beenden.
  - `:q!`: Beenden ohne Speichern.

## Vorbereitung: Umgebung prüfen
1. **Verbinde dich mit dem Debian-Container**:
   ```bash
   ssh root@192.168.30.120
   ```
2. **Prüfe vi/vim-Version**:
   ```bash
   vim --version
   ```
   - Erwartete Ausgabe: `VIM - Vi IMproved <version>` (z. B. `9.0`).
   - Falls nicht installiert: `apt update && apt install -y vim`.
3. **Sichere Konfigurationen**:
   ```bash
   cp ~/.bashrc ~/.bashrc.bak
   cp ~/.vimrc ~/.vimrc.bak  # Falls vorhanden
   ```
4. **Prüfe Shell-Konfiguration**:
   ```bash
   env
   alias
   ```
   - Überprüfe `PATH`, `HOME`, `USER`.

**Tipp**: Arbeite auf dem Debian-Container (`192.168.30.120`) und nutze TrueNAS (`192.168.30.100`) für Backups.

## Übung 1: Grundlegende Nutzung und Konfiguration von vi
**Ziel**: Lerne die Grundlagen von `vi`, konfiguriere `~/.vimrc` für Benutzerfreundlichkeit und teste einfache Bearbeitung.

1. **Starte vi und teste Grundbefehle**:
   ```bash
   vi test.txt
   ```
   - **Einfügemodus**: Drücke `i`, schreibe `Hallo, HomeLab!`, drücke `Esc`.
   - **Speichern und Beenden**: `:w`, dann `:q`.
   - **Prüfe**: `cat test.txt`.
   - Erwartete Ausgabe: `Hallo, HomeLab!`.
   - **Navigation**:
     - Öffne erneut: `vi test.txt`.
     - Gehe ans Zeilenende: `$`.
     - Füge Text hinzu: `a`, schreibe ` Willkommen!`, `Esc`.
     - Speichere und beende: `:wq`.
     - Prüfe: `cat test.txt` → `Hallo, HomeLab! Willkommen!`.

2. **Erstelle eine Basis-.vimrc**:
   ```bash
   vi ~/.vimrc
   ```
   Füge hinzu:
   ```
   " Aktiviere Syntax-Highlighting
   syntax on

   " Zeilennummern anzeigen
   set number

   " Mausunterstützung (falls verfügbar)
   set mouse=a

   " Tab-Größe auf 4 setzen
   set tabstop=4
   set shiftwidth=4
   set expandtab

   " Backup-Dateien erstellen
   set backup
   set backupdir=~/.vim/backup
   set directory=~/.vim/swap

   " Suche verbessern
   set incsearch  " Inkrementelle Suche
   set hlsearch   " Suchtreffer hervorheben

   " Farbschema
   colorscheme desert
   ```
   Speichere und beende (`:wq`). Erstelle Verzeichnisse:
   ```bash
   mkdir -p ~/.vim/backup ~/.vim/swap
   ```

3. **Teste die Konfiguration**:
   ```bash
   vi ~/.bashrc
   ```
   - Erwartete Ausgabe: Zeilennummern, Syntax-Highlighting für Bash, Mausunterstützung.
   - Suche nach `alias`: `/alias`, `n` für nächster Treffer.
   - Ersetze `alias` durch `ALIAS`: `:%s/alias/ALIAS/g`, speichere mit `:w`.
   - Beende: `:q`.

4. **Sichere die .vimrc auf TrueNAS**:
   ```bash
   scp ~/.vimrc root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
   ```

**Reflexion**: Wie unterscheidet sich der modale Ansatz von `vi` von `nano`? Überlege, wie Zeilennummern und Syntax-Highlighting die Bearbeitung erleichtern.

## Übung 2: Integration von vi in die .bashrc
**Ziel**: Erstelle Aliases, Funktionen und Umgebungsvariablen in der `.bashrc`, um `vi`-Workflows zu automatisieren.

1. **Erstelle Aliases für vi**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   alias v='vim'
   alias vs='vim -O'  # Öffne Dateien in vertikalen Splits
   alias vn='vim -c "set number"'  # Zeilennummern erzwingen
   alias vbackup='vim -b'  # Binärmodus für Binärdateien
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   v ~/.bashrc
   vs ~/.bashrc ~/.vimrc
   ```
   - Erwartete Ausgabe: `vim` startet, `vs` öffnet beide Dateien nebeneinander.

2. **Erstelle eine vi-Funktion für Papermerge-Konfiguration**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   function vi_papermerge() {
       if [ $# -eq 0 ]; then
           echo "Usage: vi_papermerge <file> [options]"
           return 1
       fi
       if [ ! -f "$1" ]; then
           echo "Fehler: Datei $1 existiert nicht"
           return 1
       fi
       vim -c "set number" -c "syntax on" "$1"
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   vi_papermerge /opt/papermerge/papermerge.conf.py
   ```
   - Erwartete Ausgabe: `vim` öffnet die Datei mit Zeilennummern und Syntax-Highlighting.

3. **Umgebungsvariablen für vi**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   export VIM_CONFIG="$HOME/.vim"
   if [ -d "$VIM_CONFIG" ]; then
       export VIMRC="$VIM_CONFIG/vimrc"
       echo "Custom vi-Konfiguration geladen: $VIMRC"
   fi
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   mkdir ~/.vim
   mv ~/.vimrc ~/.vim/vimrc
   ```
   Teste:
   ```bash
   echo $VIMRC
   ```
   - Erwartete Ausgabe: `/root/.vim/vimrc`.

4. **Konditionale vi-Konfiguration**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   if command -v vim >/dev/null 2>&1; then
       alias edit='vim'
       export EDITOR='vim'
       echo "vim ist verfügbar, Editor gesetzt auf vim"
   else
       alias edit='vi'
       export EDITOR='vi'
       echo "vim nicht installiert, verwende vi"
   fi
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   edit ~/.bashrc
   ```
   - Erwartete Ausgabe: `vim` (oder `vi`) startet.

**Reflexion**: Wie können Aliases und Funktionen `vi`-Workflows für HomeLab-Konfigurationen optimieren? Überlege, wie `EDITOR` in Tools wie `git` hilft.

## Übung 3: vi-Workflows für die HomeLab-Umgebung
**Ziel**: Erstelle `vi`-Workflows für Papermerge, kombiniere mit `tmux`, und sichere Konfigurationen.

1. **Erstelle eine vi-Funktion für Papermerge-Monitoring mit tmux**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   function vi_papermerge_monitor() {
       SESSION_NAME="papermerge_vi"
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           tmux attach -t "$SESSION_NAME"
           return
       fi
       tmux new -s "$SESSION_NAME"
       tmux split-window -h
       tmux send-keys -t "$SESSION_NAME":1.0 'vim /opt/papermerge/papermerge.conf.py' C-m
       tmux send-keys -t "$SESSION_NAME":1.1 'tail -f /var/log/nginx/error.log' C-m
       tmux select-pane -t "$SESSION_NAME":1.0
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   vi_papermerge_monitor
   ```
   - Erwartete Ausgabe: tmux-Sitzung mit `vim` für Konfiguration und Log-Tail.

2. **Sichere Konfigurationen auf TrueNAS**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   function backup_configs() {
       trap 'echo "Backup unterbrochen"; exit 1' INT TERM
       tar -czf /tmp/config-backup-$(date +%Y-%m-%d).tar.gz ~/.bashrc ~/.tmux.conf ~/.vimrc ~/.vim
       scp /tmp/config-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
       echo "Konfigurationen gesichert auf TrueNAS"
       trap - INT TERM
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   backup_configs
   ```
   - Erwartete Ausgabe: `.bashrc`, `.tmux.conf`, `.vimrc` und `.vim` werden auf TrueNAS gesichert.

3. **Erstelle eine vi-Funktion für Suche und Ersetzen**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   function vi_replace() {
       if [ $# -lt 3 ]; then
           echo "Usage: vi_replace <file> <search> <replace>"
           return 1
       fi
       FILE="$1"
       SEARCH="$2"
       REPLACE="$3"
       if [ ! -f "$FILE" ]; then
           echo "Fehler: Datei $FILE existiert nicht"
           return 1
       fi
       vim -c ":%s/$SEARCH/$REPLACE/g" -c "w" "$FILE"
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   echo "Hallo Welt" > test.txt
   vi_replace test.txt "Welt" "Linux"
   cat test.txt
   ```
   - Erwartete Ausgabe: `Hallo Linux`.

4. **Kombiniere vi mit Git-Status im Prompt**:
   ```bash
   vi ~/.bashrc
   ```
   Füge hinzu:
   ```
   function git_branch() {
       git branch 2>/dev/null | grep -E "\*" | sed -E "s/^\* (.+)$/\1/"
   }
   export PS1='\[\e[32m\]\u@\h:\[\e[34m\]\w\[\e[33m\]($(git_branch))\[\e[0m\]\$ '
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   mkdir ~/projects/testproject
   cd ~/projects/testproject
   git init
   vi README.md
   ```
   - Erwartete Ausgabe: Prompt zeigt Git-Branch (z. B. `(main)`), `vi` öffnet `README.md`.

**Reflexion**: Wie erleichtert der modale Ansatz von `vi` präzise Bearbeitung? Überlege, wie du `vi` für komplexe Dateien (z. B. YAML, Python) optimieren kannst.

## Tipps für den Erfolg
- **Lernkurve**: Übe `vi` mit `vimtutor` (starte: `vimtutor`).
- **Modularität**: Lagere `vi`-Konfigurationen in `~/.vim/vimrc`:
  ```bash
  if [ -f ~/.vim/vimrc ]; then
      export VIMRC=~/.vim/vimrc
  fi
  ```
- **Erweiterte .vimrc**: Füge Plugins hinzu (z. B. `vim-plug`):
  ```bash
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ```
  In `~/.vimrc`:
  ```
  call plug#begin('~/.vim/plugged')
  Plug 'preservim/nerdtree'
  call plug#end()
  ```
  Installiere Plugins: `:PlugInstall`.
- **Fehlerbehandlung**: Nutze `trap` in Funktionen:
  ```bash
  function vi_papermerge() {
      trap 'echo "Bearbeitung unterbrochen"; exit 1' INT TERM
      vim /opt/papermerge/papermerge.conf.py
      trap - INT TERM
  }
  ```
- **Sicherheit**: Sichere Konfigurationen:
  ```bash
  chmod 600 ~/.bashrc ~/.vimrc
  ```
- **Backup**: Automatisiere Backups mit einem Cronjob:
  ```bash
  crontab -e
  ```
  Füge hinzu:
  ```
  0 3 * * * /bin/bash -c "source ~/.bashrc && backup_configs" >> /var/log/config-backup.log 2>&1
  ```

## Fazit
Durch diese Übungen hast du die Grundlagen von `vi` gelernt, eine `~/.vimrc` konfiguriert und `vi` mit `.bashrc` für HomeLab-Workflows integriert. Du hast Navigation, Bearbeitung, Suche/Ersetzen und Aliases/Funktionen kombiniert, um effiziente Workflows zu erstellen. Wiederhole die Übungen, um `vi` zu meistern, und experimentiere mit Plugins oder erweiterten Befehlen (z. B. `:map` für Tastenkombinationen).

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten `vi`-Funktionen (z. B. Plugins, Makros), Integration mit `tmux`, oder einem anderen Editor (z. B. `emacs`)?

**Quellen**:
- Vim-Dokumentation: `man vim`, https://www.vim.org/docs.php
- Bash-Dokumentation: `man bash`, https://www.gnu.org/software/bash/manual/
- Webquellen: https://vimhelp.org/, https://www.openvim.com/, https://www.man7.org/linux/man-pages/man1/vim.1.html
```
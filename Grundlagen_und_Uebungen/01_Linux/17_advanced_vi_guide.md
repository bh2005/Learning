# Praxisorientierte Anleitung: Fortgeschrittene vi/vim-Konfiguration

## Fortgeschrittene vim-Funktionen
- **Makros**: Aufzeichnen und Wiedergeben von Befehlssequenzen (`q` zum Aufzeichnen, `@` zur Wiedergabe).
- **Regex-Suche/Ersetzen**: Erweiterte Muster mit `:%s` (z. B. `:%s/\v<alt>/neu/g`).
- **Buffer und Fenster**:
  - `:ls` / `:buffers`: Liste offene Buffer.
  - `:b <number>`: Wechsle zu Buffer.
  - `:split` / `:vsplit`: Horizontale/vertikale Fensterteilung.
  - `Ctrl+w` (z. B. `Ctrl+w w`): Zwischen Fenstern navigieren.
- **Plugins**: Verwende `vim-plug` für Plugins wie `NERDTree` (Dateibaum), `fzf.vim` (Suche).
- **Mappings**: Eigene Tastenkombinationen mit `:map` oder `:noremap`.
- **Folds**: Code falten mit `zf`, `zo`, `zc`.
- **Autocommands**: Automatische Aktionen für Dateitypen (z. B. `autocmd FileType python setlocal tabstop=4`).

## Vorbereitung: Umgebung prüfen
1. **Verbinde dich mit dem Debian-Container**:
   ```bash
   ssh root@192.168.30.120
   ```
2. **Prüfe vim-Version**:
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
4. **Installiere git und tmux**:
   ```bash
   apt install -y git tmux
   ```

**Tipp**: Arbeite auf dem Debian-Container (`192.168.30.120`) und nutze TrueNAS (`192.168.30.100`) für Backups.

## Übung 1: Fortgeschrittene vim-Konfiguration mit .vimrc
**Ziel**: Konfiguriere `~/.vimrc` für Makros, Syntax-Highlighting, Plugins und Autocommands.

1. **Erweitere die .vimrc**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```
   " Erweiterte Konfiguration
   syntax on
   set number
   set mouse=a
   set tabstop=4 shiftwidth=4 expandtab
   set backup backupdir=~/.vim/backup directory=~/.vim/swap
   set incsearch hlsearch
   colorscheme desert

   " Plugin-Verwaltung mit vim-plug
   call plug#begin('~/.vim/plugged')
   Plug 'preservim/nerdtree'  " Dateibaum
   Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
   Plug 'junegunn/fzf.vim'    " Fuzzy-Suche
   call plug#end()

   " NERDTree-Konfiguration
   autocmd VimEnter * NERDTree | wincmd p  " Öffne NERDTree beim Start
   autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('t:NERDTreeBufName') | quit | endif

   " Mappings
   nnoremap <C-t> :NERDTreeToggle<CR>
   nnoremap <C-p> :Files<CR>  " fzf.vim für Dateisuche
   nnoremap <leader>w :w<CR>  " Schnell speichern

   " Autocommands
   autocmd FileType python setlocal tabstop=4 shiftwidth=4
   autocmd FileType yaml setlocal tabstop=2 shiftwidth=2

   " Folds
   set foldmethod=indent
   set foldlevelstart=99  " Alle Folds offen beim Start
   ```
   Speichere und beende (`:wq`). Erstelle Verzeichnisse:
   ```bash
   mkdir -p ~/.vim/backup ~/.vim/swap ~/.vim/plugged
   ```

2. **Installiere vim-plug und Plugins**:
   ```bash
   curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
   ```
   Öffne `vim` und installiere Plugins:
   ```bash
   vim
   :PlugInstall
   ```
   - Erwartete Ausgabe: `NERDTree`, `fzf`, `fzf.vim` werden installiert.

3. **Teste die Konfiguration**:
   ```bash
   vim /opt/papermerge/papermerge.conf.py
   ```
   - **NERDTree**: `Ctrl+t` öffnet/schließt den Dateibaum.
   - **fzf.vim**: `Ctrl+p` öffnet Fuzzy-Suche für Dateien.
   - **Folds**: `zf` faltet Code, `zo` öffnet ihn.
   - **Suche**: `/^def` sucht Python-Funktionen, `n` für nächster Treffer.
   - **Speichern**: `<leader>w` (Standard: `\w`).

4. **Sichere die .vimrc auf TrueNAS**:
   ```bash
   scp ~/.vimrc root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
   ```

**Reflexion**: Wie verbessern Plugins wie `NERDTree` die Navigation? Überlege, wie Autocommands Dateityp-spezifische Einstellungen ermöglichen.

## Übung 2: Fortgeschrittene vim-Workflows mit Makros und Regex
**Ziel**: Nutze Makros, Regex und Buffer-Management für komplexe Bearbeitungen.

1. **Erstelle ein Makro für wiederkehrende Änderungen**:
   ```bash
   vim /opt/papermerge/papermerge.conf.py
   ```
   - Starte Aufzeichnung: `qa` (Makro in Register `a`).
   - Führe Aktionen aus: `0` (Zeilenanfang), `i# ` (Kommentar einfügen), `Esc`, `j` (nächste Zeile).
   - Beende Aufzeichnung: `q`.
   - Wende Makro an: `@a` (einmal), `5@a` (fünfmal).
   - Speichere: `:w`.
   - Erwartete Ausgabe: Mehrere Zeilen werden kommentiert.

2. **Erweiterte Regex-Suche/Ersetzen**:
   ```bash
   vim test.txt
   ```
   Schreibe: `user1=admin user2=guest user3=manager`.
   - Ersetze `user[0-9]` mit `account[0-9]`:
     ```vim
     :%s/\vuser([0-9])/account\1/g
     ```
   - Speichere: `:w`.
   - Prüfe: `:w !cat`.
   - Erwartete Ausgabe: `account1=admin account2=guest account3=manager`.

3. **Buffer- und Fenster-Management**:
   ```bash
   vim /opt/papermerge/papermerge.conf.py
   ```
   - Öffne zweiten Buffer: `:e /var/log/nginx/error.log`.
   - Liste Buffer: `:ls`.
   - Wechsle: `:b 1`.
   - Teile Fenster: `:vsplit /var/log/nginx/error.log`.
   - Navigiere: `Ctrl+w w`.
   - Schließe Fenster: `Ctrl+w c`.
   - Erwartete Ausgabe: Zwei Dateien in Splits, einfaches Wechseln.

**Reflexion**: Wie sparen Makros Zeit bei repetitiven Aufgaben? Probiere `:g/^#/d` zum Löschen kommentierter Zeilen.

## Übung 3: Integration von vim in .bashrc und tmux
**Ziel**: Erstelle komplexe `vim`-Workflows mit `.bashrc` und `tmux` für die HomeLab-Umgebung.

1. **Erstelle Aliases und Funktionen für vim**:
   ```bash
   vim ~/.bashrc
   ```
   Füge hinzu:
   ```
   alias v='vim'
   alias vs='vim -O'  # Vertikale Splits
   alias vp='vim -c "NERDTree"'  # Mit NERDTree
   function vim_papermerge() {
       if [ $# -eq 0 ]; then
           echo "Usage: vim_papermerge <file> [options]"
           return 1
       fi
       if [ ! -f "$1" ]; then
           echo "Fehler: Datei $1 existiert nicht"
           return 1
       fi
       vim -c "set number" -c "syntax on" -c "NERDTree" "$1"
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   vim_papermerge /opt/papermerge/papermerge.conf.py
   ```
   - Erwartete Ausgabe: `vim` öffnet mit `NERDTree`, Zeilennummern und Syntax.

2. **vim- und tmux-Workflow für Papermerge**:
   ```bash
   vim ~/.bashrc
   ```
   Füge hinzu:
   ```
   function vim_papermerge_monitor() {
       SESSION_NAME="papermerge_vim"
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           tmux attach -t "$SESSION_NAME"
           return
       fi
       tmux new -s "$SESSION_NAME"
       tmux split-window -h
       tmux send-keys -t "$SESSION_NAME":1.0 'vim /opt/papermerge/papermerge.conf.py' C-m
       tmux send-keys -t "$SESSION_NAME":1.1 'tail -f /var/log/nginx/error.log' C-m
       tmux split-window -v -t "$SESSION_NAME":1.0
       tmux send-keys -t "$SESSION_NAME":1.2 'vim /var/log/postgresql/postgresql-15-main.log' C-m
       tmux select-pane -t "$SESSION_NAME":1.0
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   vim_papermerge_monitor
   ```
   - Erwartete Ausgabe: tmux-Sitzung mit `vim` für Konfiguration und Log, plus Log-Tail.

3. **Sichere Konfigurationen auf TrueNAS**:
   ```bash
   vim ~/.bashrc
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
   - Erwartete Ausgabe: Konfigurationen werden auf TrueNAS gesichert.

4. **Erweiterte Regex-Funktion in .bashrc**:
   ```bash
   vim ~/.bashrc
   ```
   Füge hinzu:
   ```
   function vim_regex_replace() {
       if [ $# -lt 3 ]; then
           echo "Usage: vim_regex_replace <file> <search_regex> <replace>"
           return 1
       fi
       FILE="$1"
       SEARCH="$2"
       REPLACE="$3"
       if [ ! -f "$FILE" ]; then
           echo "Fehler: Datei $FILE existiert nicht"
           return 1
       fi
       vim -c ":%s/\v$SEARCH/$REPLACE/g" -c "w" "$FILE"
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   echo "user1=admin user2=guest" > test.txt
   vim_regex_replace test.txt "user([0-9])" "account\1"
   cat test.txt
   ```
   - Erwartete Ausgabe: `account1=admin account2=guest`.

**Reflexion**: Wie können Plugins und Makros komplexe Workflows vereinfachen? Überlege, wie `fzf.vim` mit `tmux` kombiniert werden kann.

## Tipps für den Erfolg
- **Lernressourcen**: Nutze `:help` in `vim` oder `vimtutor` für interaktives Lernen.
- **Modularität**: Organisiere Plugins in `~/.vim/plugged` und Konfigurationen in `~/.vim/vimrc`:
  ```bash
  if [ -f ~/.vim/vimrc ]; then
      export VIMRC=~/.vim/vimrc
  fi
  ```
- **Erweiterte Plugins**:
  - Installiere `ale` für Linting: `Plug 'dense-analysis/ale'`.
  - Konfiguriere: `let g:ale_linters = {'python': ['flake8']}`.
- **Fehlerbehebung**:
  - Prüfe `.vimrc`: `vim -u ~/.vimrc`.
  - Bereinige Swap-Dateien: `rm ~/.vim/swap/*`.
  - Debugge Plugins: `:messages`.
- **Sicherheit**: Sichere Konfigurationen:
  ```bash
  chmod 600 ~/.bashrc ~/.vimrc
  ```
- **Backup**: Automatisiere Backups mit Cron:
  ```bash
  crontab -e
  ```
  Füge hinzu:
  ```
  0 3 * * * /bin/bash -c "source ~/.bashrc && backup_configs" >> /var/log/config-backup.log 2>&1
  ```

## Fazit
Durch diese Übungen hast du fortgeschrittene `vim`-Funktionen (Makros, Regex, Plugins, Buffer) gemeistert und mit `.bashrc` und `tmux` für HomeLab-Workflows integriert. Du hast komplexe Bearbeitungen automatisiert und die Produktivität gesteigert. Wiederhole die Übungen, um `vim` weiter anzupassen (z. B. mit `ale` für Linting oder `coc.nvim` für Autovervollständigung).

**Nächste Schritte**: Möchtest du eine Anleitung zu `vim`-Scripting, weiteren Plugins (z. B. `coc.nvim`), oder Integration mit `zsh`?

**Quellen**:
- Vim-Dokumentation: `man vim`, https://www.vim.org/docs.php
- Bash-Dokumentation: `man bash`, https://www.gnu.org/software/bash/manual/
- Webquellen: https://vimhelp.org/, https://learnvimscriptthehardway.stevelosh.com/, https://www.man7.org/linux/man-pages/man1/vim.1.html
```
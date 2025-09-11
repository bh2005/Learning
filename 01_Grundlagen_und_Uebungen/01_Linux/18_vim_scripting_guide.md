# Praxisorientierte Anleitung: Einstieg in Vim-Scripting

## Grundlagen von Vim-Script
Vim-Script ist die Skriptsprache von `vim`, die in `~/.vimrc`, `~/.vim`-Skripten oder Plugins verwendet wird. Wichtige Konzepte:
- **Variablen**:
  - `let g:var = "value"`: Globale Variable.
  - `let b:var = "value"`: Buffer-lokale Variable.
  - `let &option = value`: Vim-Option setzen (z. B. `let &tabstop = 4`).
- **Funktionen**: Definieren mit `function`/`endfunction`, aufrufen mit `:call`.
  - Beispiel: `function! MyFunc() ... endfunction`.
- **Benutzerdefinierte Befehle**: Mit `:command` erstellen (z. B. `:command MyCmd echo "Hallo"`).
- **Autocommands**: Automatische Aktionen bei Ereignissen (z. B. `autocmd BufRead *.py setlocal tabstop=4`).
- **Mappings**: Tastenkombinationen mit `:noremap` (z. B. `nnoremap <leader>x :call MyFunc()<CR>`).
- **Konditionen**: `if`/`else`/`endif` für Logik.
- **Schleifen**: `for`/`while` für Iterationen.

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
   cp ~/.vimrc ~/.vimrc.bak
   ```
4. **Installiere git und tmux**:
   ```bash
   apt install -y git tmux
   ```

**Tipp**: Arbeite auf dem Debian-Container (`192.168.30.120`) und nutze TrueNAS (`192.168.30.100`) für Backups.

## Übung 1: Erste Schritte mit Vim-Script in .vimrc
**Ziel**: Erstelle grundlegende Vim-Skripte für benutzerdefinierte Befehle, Funktionen und Autocommands.

1. **Erweitere die .vimrc mit Vim-Script**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```
   " Grundkonfiguration
   syntax on
   set number
   set mouse=a
   set tabstop=4 shiftwidth=4 expandtab
   set backup backupdir=~/.vim/backup directory=~/.vim/swap
   set incsearch hlsearch
   colorscheme desert

   " Benutzerdefinierte Variable
   let g:homelab_config = "/opt/papermerge/papermerge.conf.py"

   " Benutzerdefinierte Funktion
   function! PapermergeOpen()
       execute "edit " . g:homelab_config
       setlocal filetype=python
       echo "Opened Papermerge configuration"
   endfunction

   " Benutzerdefinierter Befehl
   command! Papermerge call PapermergeOpen()

   " Autocommand für Papermerge-Konfiguration
   autocmd BufRead,BufNewFile papermerge.conf.py setlocal tabstop=4 shiftwidth=4 filetype=python

   " Mapping
   nnoremap <leader>p :Papermerge<CR>
   ```
   Speichere und beende (`:wq`). Erstelle Verzeichnisse:
   ```bash
   mkdir -p ~/.vim/backup ~/.vim/swap
   ```

2. **Teste die Skripte**:
   ```bash
   vim
   ```
   - Führe Befehl aus: `:Papermerge`.
   - Nutze Mapping: `\p` (Standard `<leader>` ist `\`).
   - Erwartete Ausgabe: Öffnet `/opt/papermerge/papermerge.conf.py` mit Python-Syntax.
   - Prüfe Autocommand: `:set tabstop?` → `tabstop=4`.

3. **Sichere die .vimrc auf TrueNAS**:
   ```bash
   scp ~/.vimrc root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
   ```

**Reflexion**: Wie vereinfachen benutzerdefinierte Befehle und Mappings den Zugriff auf häufig verwendete Dateien? Überlege, wie Autocommands Dateityp-spezifische Einstellungen automatisieren.

## Übung 2: Fortgeschrittene Vim-Script-Funktionen
**Ziel**: Erstelle komplexe Funktionen mit Parametern, Konditionen und Schleifen.

1. **Funktion mit Parametern für Log-Analyse**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```
   function! AnalyzeLog(logfile, pattern)
       if !filereadable(a:logfile)
           echoerr "Fehler: Datei " . a:logfile . " existiert nicht"
           return
       endif
       execute "edit " . a:logfile
       execute "vimgrep /" . a:pattern . "/j %"
       copen  " Öffne Quickfix-Liste
       echo "Log-Analyse für " . a:pattern . " abgeschlossen"
   endfunction

   command! -nargs=+ AnalyzeLog call AnalyzeLog(<f-args>)
   nnoremap <leader>l :AnalyzeLog /var/log/nginx/error.log error<CR>
   ```
   Speichere und beende (`:wq`).

2. **Teste die Funktion**:
   ```bash
   vim
   ```
   - Führe Befehl aus: `:AnalyzeLog /var/log/nginx/error.log error`.
   - Nutze Mapping: `\l`.
   - Erwartete Ausgabe: Öffnet `error.log`, zeigt Treffer für `error` in der Quickfix-Liste.
   - Navigiere: `:cnext` / `:cprev` für Treffer.

3. **Schleifen für Batch-Bearbeitung**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```
   function! CommentLines(pattern)
       for line in getline(1, '$')
           if line =~ a:pattern
               execute "normal! I# "
           endif
           normal! j
       endfor
       echo "Kommentierte Zeilen mit " . a:pattern
   endfunction

   command! -nargs=1 CommentLines call CommentLines(<q-args>)
   ```
   Speichere und beende.

4. **Teste die Schleife**:
   ```bash
   echo -e "user1=admin\nuser2=guest\nadmin=super" > test.txt
   vim test.txt
   ```
   - Führe aus: `:CommentLines user`.
   - Erwartete Ausgabe: `# user1=admin`, `# user2=guest`, `admin=super`.

**Reflexion**: Wie können Funktionen mit `vimgrep` Log-Analysen automatisieren? Probiere `:copen` für Quickfix-Listen.

## Übung 3: Integration von Vim-Script mit .bashrc und tmux
**Ziel**: Erstelle Vim-Skripte, integriere sie mit `.bashrc` und `tmux`, und sichere Konfigurationen.

1. **Vim-Skript für Papermerge-Workflow**:
   ```bash
   mkdir -p ~/.vim/scripts
   vim ~/.vim/scripts/papermerge.vim
   ```
   Füge hinzu:
   ```
   function! PapermergeSetup()
       vsplit /var/log/nginx/error.log
       split /var/log/postgresql/postgresql-15-main.log
       wincmd h
       edit /opt/papermerge/papermerge.conf.py
       setlocal filetype=python
       autocmd BufWritePost <buffer> echo "Papermerge config saved at " . strftime("%Y-%m-%d %H:%M")
   endfunction

   command! PapermergeSetup call PapermergeSetup()
   ```
   In `~/.vimrc`:
   ```
   source ~/.vim/scripts/papermerge.vim
   nnoremap <leader>ps :PapermergeSetup<CR>
   ```
   Speichere und beende.

2. **Teste das Skript**:
   ```bash
   vim
   ```
   - Führe aus: `:PapermergeSetup` oder `\ps`.
   - Erwartete Ausgabe: Drei Fenster (`papermerge.conf.py`, `error.log`, PostgreSQL-Log), Python-Syntax, Speicher-Benachrichtigung.

3. **Integriere mit .bashrc und tmux**:
   ```bash
   vim ~/.bashrc
   ```
   Füge hinzu:
   ```
   function vim_papermerge_workflow() {
       SESSION_NAME="papermerge_vim"
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           tmux attach -t "$SESSION_NAME"
           return
       fi
       tmux new -s "$SESSION_NAME"
       tmux send-keys -t "$SESSION_NAME":1.0 'vim -c "PapermergeSetup"' C-m
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   vim_papermerge_workflow
   ```
   - Erwartete Ausgabe: tmux-Sitzung mit `vim` und Papermerge-Setup.

4. **Sichere Konfigurationen auf TrueNAS**:
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
   - Erwartete Ausgabe: Konfigurationen auf TrueNAS gesichert.

**Reflexion**: Wie können Vim-Skripte mit `tmux` komplexe Workflows vereinfachen? Überlege, wie `:source` Skripte dynamisch lädt.

## Tipps für den Erfolg
- **Lernressourcen**: Lies `:help usr_41` oder https://learnvimscriptthehardway.stevelosh.com/.
- **Modularität**: Organisiere Skripte in `~/.vim/scripts`:
  ```bash
  for script in glob('~/.vim/scripts/*.vim')
      execute 'source ' . script
  endfor
  ```
- **Fehlerbehebung**:
  - Prüfe Skripte: `vim -u ~/.vimrc`.
  - Debugge: `:messages` oder `:echom "Debug: " . variable`.
  - Swap-Dateien: `rm ~/.vim/swap/*`.
- **Sicherheit**: Sichere Konfigurationen:
  ```bash
  chmod 600 ~/.bashrc ~/.vimrc ~/.vim/scripts/*
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
Durch diese Übungen hast du Vim-Script gelernt, benutzerdefinierte Befehle, Funktionen und Autocommands erstellt, und sie mit `.bashrc` und `tmux` für HomeLab-Workflows integriert. Wiederhole die Übungen, um Skripte für andere Aufgaben (z. B. Log-Analyse, Code-Linting) anzupassen.

**Nächste Schritte**: Möchtest du eine Anleitung zu erweiterten Plugins (z. B. `coc.nvim`), `zsh`-Integration, oder anderen Tools (z. B. `emacs`)?

**Quellen**:
- Vim-Dokumentation: `:help usr_41`, `:help script`, https://www.vim.org/docs.php
- Bash-Dokumentation: `man bash`, https://www.gnu.org/software/bash/manual/
- Webquellen: https://learnvimscriptthehardway.stevelosh.com/, https://vim.fandom.com/wiki/Vim_Tips_Wiki
```
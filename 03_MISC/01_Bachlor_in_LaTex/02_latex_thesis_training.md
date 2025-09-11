# Praxisorientierte Anleitung: Grundlagentraining für LaTeX in einem Debian LXC-Container

## Einführung
Diese Anleitung bietet einen praxisnahen Einstieg in LaTeX für die Erstellung einer Bachelorarbeit, basierend auf der Struktur aus deiner Anfrage (siehe `vim_scripting_thesis_guide.md`, Artifact ID: `53986cf3-6ace-4cd8-9176-33c3ec8fc23f`). Wir nutzen einen Debian 13 LXC-Container (IP `192.168.30.121`, `thesis.homelab.local`) in der HomeLab-Umgebung und zeigen, wie du LaTeX installierst, eine Bachelorarbeit gemäß der vorgegebenen Gliederung erstellst, und LaTeX mit `vim`, Vim-Script, `.bashrc` und `tmux` integrierst. Die Übungen sind für Anfänger geeignet, die LaTeX für wissenschaftliche Dokumente lernen möchten, und bauen auf die HomeLab-Umgebung auf, einschließlich TrueNAS-Backups (`192.168.30.100`).

**Voraussetzungen**:
- Ein Debian 13 LXC-Container (`thesis.homelab.local`, IP `192.168.30.121`) in Proxmox VE (`https://192.168.30.2:8006`).
- OPNsense-Router (`192.168.30.1`) mit Unbound DNS für Namensauflösung.
- Grundkenntnisse in `vim` (Modi, `.vimrc`, Vim-Script) und Bash.
- Internetzugang für Debian-Paketquellen.
- Sichere die `.bashrc` und `~/.vimrc` vor Änderungen: `cp ~/.bashrc ~/.bashrc.bak; cp ~/.vimrc ~/.vimrc.bak`.
- Optional: TrueNAS (`192.168.30.100`) für Backups unter `/mnt/tank/backups/thesis`.
- **Hinweis**: Wir verwenden PDFLaTeX (ohne `fontspec`, da XeLaTeX/LuaLaTeX nicht erforderlich sind) mit Paketen aus `texlive-full` und `texlive-fonts-extra`. Die Bachelorarbeit wird in LaTeX erstellt, mit Vim-Skripten für Automatisierung und `tmux` für parallele Bearbeitung.

**Ziele**:
- Installiere und konfiguriere LaTeX in einem Debian LXC-Container.
- Erstelle eine LaTeX-Vorlage für die Bachelorarbeit gemäß der vorgegebenen Gliederung.
- Integriere LaTeX mit `vim`, Vim-Script, `.bashrc` und `tmux` für effiziente Workflows.

**Quellen**:
- LaTeX-Dokumentation: https://www.latex-project.org/help/documentation/
- Vim-Dokumentation: `:help usr_41`, https://www.vim.org/docs.php
- Debian-Dokumentation: https://www.debian.org/releases/trixie/
- Webquellen: https://www.overleaf.com/learn, https://www.tug.org/, https://learnvimscriptthehardway.stevelosh.com/

## Aufbau und Gliederung der Bachelorarbeit
Die folgende Struktur basiert auf deiner Anfrage und wird in LaTeX umgesetzt.

1. **Deckblatt**: Titel, Hochschul-Logo, Name, Matrikelnummer, Betreuer, Studiengang (1 Seite).
2. **Abstract**: Thema, Untersuchung, Ergebnisse, Bedeutung (max. 1 Seite).
3. **Vorwort**: Persönlicher Hintergrund (max. 1 Seite).
4. **Danksagung**: Dank an Unterstützer (max. 1 Seite, optional im Vorwort).
5. **Inhaltsverzeichnis**: Kapitelübersicht, Literatur, Anhang.
6. **Abbildungs-/Tabellenverzeichnis**: Automatisch generierte Listen.
7. **Abkürzungsverzeichnis**: Alphabetisch sortierte Abkürzungen.
8. **Einleitung**: Thema, Ziel, Relevanz (10 % der Arbeit).
9. **Theoretischer Teil**: Schlüsselbegriffe, Theorien (30–40 %).
10. **Methodik**: Forschungsmethoden (z. B. Literatur-Review, Umfragen; 10 %).
11. **Ergebnisse**: Untersuchung, Zuordnung zu Hypothesen (10–20 %).
12. **Diskussion**: Analyse, Limitationen, Zukunftsempfehlungen (5–20 %).
13. **Fazit**: Wichtigste Ergebnisse, Bezug zur Einleitung (5–10 %).
14. **Nachwort**: Reflexion (optional).
15. **Literaturverzeichnis**: Vollständig, übersichtlich, einheitlich (z. B. APA).
16. **Anhang**: Ergänzende Informationen (optional).
17. **Eidesstattliche Erklärung**: Eigenständigkeitserklärung (0,5 Seite).

## Übung 1: Einrichtung von LaTeX und Erstellung der Bachelorarbeit-Vorlage
**Ziel**: Installiere LaTeX, erstelle die Bachelorarbeit-Vorlage in LaTeX und konfiguriere `vim` für LaTeX-Bearbeitung.

1. **Verbinde dich mit dem Debian LXC-Container**:
   ```bash
   ssh root@192.168.30.121
   ```

2. **Installiere LaTeX und Tools**:
   ```bash
   apt update
   apt install -y texlive-full texlive-fonts-extra vim git tmux zathura
   ```
   - **Hinweis**: `texlive-full` enthält alle notwendigen Pakete; `zathura` ist ein PDF-Viewer.

3. **Erstelle die LaTeX-Vorlage**:
   ```bash
   mkdir -p ~/thesis
   vim ~/thesis/thesis.tex
   ```
   Füge die folgende LaTeX-Vorlage ein:

   ```latex
   % Setting up the document class and essential packages
   \documentclass[a4paper,12pt]{article}

   % Including standard LaTeX packages for encoding, fonts, and formatting
   \usepackage[utf8]{inputenc}
   \usepackage[T1]{fontenc}
   \usepackage{lmodern}
   \usepackage[ngerman,english]{babel}
   \usepackage{csquotes}
   \usepackage{tocloft}
   \usepackage{geometry}
   \geometry{a4paper, margin=2.5cm}
   \usepackage{setspace}
   \onehalfspacing
   \usepackage{graphicx}
   \usepackage{caption}
   \usepackage{acronym}
   \usepackage{bibentry}
   \nobibliography*

   % Configuring the table of contents
   \setlength{\cftsecindent}{0em}
   \setlength{\cftsubsecindent}{2em}

   % Setting reliable font (Latin Modern for Latin characters)
   \usepackage{lmodern}

   \begin{document}

   % Creating the title page
   \begin{titlepage}
       \centering
       \vspace*{1cm}
       {\huge \textbf{[Titel der Arbeit]}}
       \vspace{0.5cm}
       \newline
       {\Large Bachelorarbeit}
       \vspace{1cm}
       \newline
       Hochschule: [Name der Hochschule]\\
       Studiengang: [Name des Studiengangs]\\
       Name: [Dein Name]\\
       Matrikelnummer: [Deine Matrikelnummer]\\
       Betreuer: [Name des Betreuers]\\
       Datum: \today
   \end{titlepage}

   % Adding abstract
   \section*{Abstract}
   \selectlanguage{english}
   [Hier beschreibst du Thema, Untersuchung, Ergebnisse und Bedeutung in max. 1 Seite.]

   % Adding Vorwort
   \section*{Vorwort}
   \selectlanguage{ngerman}
   [Persönlicher Hintergrund der Arbeit.]

   % Adding Danksagung
   \section*{Danksagung}
   [Dank an Familie, Betreuer, Kollegen, etc.]

   % Generating table of contents
   \tableofcontents
   \clearpage

   % Generating list of figures
   \listoffigures
   \clearpage

   % Generating list of tables
   \listoftables
   \clearpage

   % Adding Abkürzungsverzeichnis
   \section*{Abkürzungsverzeichnis}
   \begin{acronym}[API]
       \acro{API}{Application Programming Interface}
       \acro{VIM}{Vi Improved}
   \end{acronym}
   \clearpage

   % Starting main content
   \section{Einleitung}
   [Vorstellung des Themas, Ziel, Relevanz.]

   \section{Theoretischer Teil}
   [Schlüsselbegriffe, Theorien, Literaturübersicht.]

   \section{Methodik}
   [Beschreibung der Forschungsmethoden, z. B. Literatur-Review.]

   \section{Ergebnisse}
   [Untersuchungsergebnisse, Zuordnung zu Hypothesen.]

   \section{Diskussion}
   [Analyse, Limitationen, Zukunftsempfehlungen.]

   \section{Fazit}
   [Zusammenfassung der Ergebnisse, Bezug zur Einleitung.]

   % Adding Nachwort
   \section*{Nachwort}
   [Reflexion über die Arbeit, optional.]

   % Adding Literaturverzeichnis
   \section*{Literaturverzeichnis}
   \begin{thebibliography}{9}
       \bibentry{doe2023}
       \bibitem{doe2023}
           Doe, John (2023). \emph{Introduction to Vim}. Tech Press.
   \end{thebibliography}

   % Adding Anhang
   \appendix
   \section{Anhang}
   [Ergänzende Materialien, optional.]

   % Adding eidesstattliche Erklärung
   \section*{Eidesstattliche Erklärung}
   Hiermit erkläre ich, dass ich die vorliegende Arbeit selbstständig verfasst und keine anderen als die angegebenen Quellen verwendet habe.

   \end{document}
   ```
   Speichere und beende (`:wq`).

4. **Kompiliere die Vorlage**:
   ```bash
   cd ~/thesis
   latexmk -pdf thesis.tex
   ```
   - Erwartete Ausgabe: `thesis.pdf` wird erstellt.
   - Öffne die PDF: `zathura thesis.pdf`.

5. **Konfiguriere .vimrc für LaTeX**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```vim
   " Grundkonfiguration
   syntax on
   set number
   set mouse=a
   set tabstop=4 shiftwidth=4 expandtab
   set backup backupdir=~/.vim/backup directory=~/.vim/swap
   set incsearch hlsearch
   colorscheme desert

   " Plugin-Verwaltung
   call plug#begin('~/.vim/plugged')
   Plug 'preservim/nerdtree'
   Plug 'lervag/vimtex'
   call plug#end()

   " Vimtex-Konfiguration
   let g:vimtex_view_method = 'zathura'
   let g:vimtex_compiler_method = 'latexmk'

   " Thesis-spezifische Variablen
   let g:thesis_dir = "~/thesis"
   let g:thesis_file = "~/thesis/thesis.tex"

   " Funktion zum Öffnen der Arbeit
   function! ThesisOpen()
       if !isdirectory(g:thesis_dir)
           call mkdir(g:thesis_dir, "p")
       endif
       execute "edit " . g:thesis_file
       setlocal filetype=tex
       setlocal spell spelllang=de,en
       echo "Bachelorarbeit geöffnet: " . g:thesis_file
   endfunction

   command! Thesis call ThesisOpen()
   nnoremap <leader>t :Thesis<CR>

   " Autocommand für LaTeX
   autocmd FileType tex setlocal tabstop=2 shiftwidth=2 wrap linebreak
   autocmd FileType tex nnoremap <leader>c :VimtexCompile<CR>
   ```
   Speichere und beende. Installiere Plugins:
   ```bash
   mkdir -p ~/.vim/backup ~/.vim/swap ~/.vim/plugged
   curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
   vim -c "PlugInstall | q"
   ```

6. **Teste die Konfiguration**:
   ```bash
   vim
   :Thesis
   ```
   - Erwartete Ausgabe: Öffnet `thesis.tex` mit LaTeX-Syntax und Rechtschreibprüfung.
   - Kompiliere: `\c` (führt `latexmk` aus).
   - Öffne `NERDTree`: `Ctrl+t`.

7. **Sichere auf TrueNAS**:
   ```bash
   scp ~/thesis/thesis.tex ~/.vimrc root@192.168.30.100:/mnt/tank/backups/thesis/
   ```

**Reflexion**: Wie erleichtert `vimtex` die LaTeX-Bearbeitung? Überlege, wie Rechtschreibprüfung die Qualität verbessert.

## Übung 2: Vim-Skript für Literatur und Abkürzungen
**Ziel**: Erstelle Vim-Skripte zur Verwaltung von Literaturverzeichnis und Abkürzungsverzeichnis.

1. **Funktion für Literaturverzeichnis**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```vim
   function! AddBibentry(author, title, year, publisher)
       let bib = printf("\\bibitem{%s%s}\n    %s (%s). \\emph{%s}. %s.", a:author, a:year, a:author, a:year, a:title, a:publisher)
       let bib_section = search('\\section*{Literaturverzeichnis}', 'n')
       if bib_section == 0
           call append(line('$'), ["\\section*{Literaturverzeichnis}", "\\begin{thebibliography}{9}", bib, "\\end{thebibliography}"])
       else
           call append(bib_section + 1, bib)
       endif
       echo "Referenz hinzugefügt: " . bib
   endfunction

   command! -nargs=+ AddBib call AddBibentry(<f-args>)
   nnoremap <leader>r :AddBib<Space>
   ```
   Speichere und beende.

2. **Teste die Funktion**:
   ```bash
   vim ~/thesis/thesis.tex
   :AddBib "Doe, John" "Introduction to LaTeX" 2023 "Tech Press"
   ```
   - Erwartete Ausgabe: Im Literaturverzeichnis wird hinzugefügt:
     ```latex
     \bibitem{Doe, John2023}
         Doe, John (2023). \emph{Introduction to LaTeX}. Tech Press.
     ```

3. **Funktion für Abkürzungsverzeichnis**:
   ```bash
   vim ~/.vimrc
   ```
   Füge hinzu:
   ```vim
   function! AddAcronym(abbrev, meaning)
       let acro = printf("\\acro{%s}{%s}", a:abbrev, a:meaning)
       let acro_section = search('\\section*{Abkürzungsverzeichnis}', 'n')
       if acro_section == 0
           call append(line('$'), ["\\section*{Abkürzungsverzeichnis}", "\\begin{acronym}[API]", acro, "\\end{acronym}"])
       else
           call append(acro_section + 1, acro)
       endif
       echo "Abkürzung hinzugefügt: " . acro
   endfunction

   command! -nargs=+ AddAcro call AddAcronym(<f-args>)
   nnoremap <leader>a :AddAcro<Space>
   ```
   Speichere und beende.

4. **Teste die Funktion**:
   ```bash
   vim ~/thesis/thesis.tex
   :AddAcro "LATEX" "LaTeX Typesetting System"
   ```
   - Erwartete Ausgabe: Im Abkürzungsverzeichnis wird hinzugefügt:
     ```latex
     \acro{LATEX}{LaTeX Typesetting System}
     ```

**Reflexion**: Wie automatisieren diese Funktionen die Verwaltung von Literatur und Abkürzungen? Probiere `:sort` im Abkürzungsabschnitt.

## Übung 3: Integration mit .bashrc und tmux
**Ziel**: Integriere LaTeX-Workflows mit `.bashrc` und `tmux` für parallele Bearbeitung und Vorschau.

1. **Erstelle .bashrc-Funktionen**:
   ```bash
   vim ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   alias vt='vim -c "Thesis"'
   function thesis_workflow() {
       SESSION_NAME="thesis"
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           tmux attach -t "$SESSION_NAME"
           return
       fi
       tmux new -s "$SESSION_NAME"
       tmux split-window -h
       tmux send-keys -t "$SESSION_NAME":1.0 'vim -c "Thesis"' C-m
       tmux send-keys -t "$SESSION_NAME":1.1 'cd ~/thesis && latexmk -pdf -pvc thesis.tex' C-m
       tmux select-pane -t "$SESSION_NAME":1.0
   }
   function backup_thesis() {
       trap 'echo "Backup unterbrochen"; exit 1' INT TERM
       tar -czf /tmp/thesis-backup-$(date +%Y-%m-%d).tar.gz ~/thesis ~/.vimrc ~/.bashrc
       scp /tmp/thesis-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/thesis/
       echo "Bachelorarbeit gesichert auf TrueNAS"
       trap - INT TERM
   }
   function add_thesis_bib() {
       if [ $# -lt 4 ]; then
           echo "Usage: add_thesis_bib <author> <title> <year> <publisher>"
           return 1
       fi
       vim -c "AddBib $1 \"$2\" $3 \"$4\"" -c "w" ~/thesis/thesis.tex
   }
   function add_thesis_acro() {
       if [ $# -lt 2 ]; then
           echo "Usage: add_thesis_acro <abbrev> <meaning>"
           return 1
       fi
       vim -c "AddAcro $1 \"$2\"" -c "w" ~/thesis/thesis.tex
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```

2. **Teste den Workflow**:
   ```bash
   thesis_workflow
   ```
   - Erwartete Ausgabe: tmux-Sitzung mit `vim` (thesis.tex) und automatischer PDF-Kompilierung (`latexmk -pvc`).

3. **Teste Literatur- und Abkürzungsfunktionen**:
   ```bash
   add_thesis_bib "Smith, Jane" "Advanced LaTeX" 2024 "Academic Press"
   add_thesis_acro "PDF" "Portable Document Format"
   ```
   - Erwartete Ausgabe: Referenz und Abkürzung werden in `thesis.tex` hinzugefügt.

4. **Teste das Backup**:
   ```bash
   backup_thesis
   ```
   - Erwartete Ausgabe: Dateien werden auf TrueNAS gesichert.

**Reflexion**: Wie verbessert `tmux` mit `latexmk -pvc` die Produktivität? Überlege, wie `vimtex` die LaTeX-Bearbeitung vereinfacht.

## Tipps für den Erfolg
- **LaTeX-Kompilierung**:
  - Nutze `latexmk -pdf -pvc` für automatische Neukompilierung bei Änderungen.
  - Prüfe Fehler: `cat thesis.log`.
- **Vimtex-Funktionen**:
  - Nutze `:VimtexTocOpen` für eine Inhaltsverzeichnis-Übersicht.
  - Navigiere mit `]]`/`[[` zwischen Abschnitten.
- **Fehlerbehebung**:
  - Prüfe `.vimrc`: `vim -u ~/.vimrc`.
  - Prüfe `.bashrc`: `bash -n ~/.bashrc`.
  - Debugge LaTeX: `latexmk -pdf -verbose thesis.tex`.
- **Sicherheit**:
  ```bash
  chmod 600 ~/.bashrc ~/.vimrc ~/thesis/*
  ```
- **Backup**:
  ```bash
  crontab -e
  ```
  Füge hinzu:
  ```bash
  0 3 * * * /bin/bash -c "source ~/.bashrc && backup_thesis" >> /var/log/thesis-backup.log 2>&1
  ```

## Fazit
Durch diese Übungen hast du LaTeX in einem Debian LXC-Container eingerichtet, eine Bachelorarbeit-Vorlage erstellt, und `vim`, Vim-Script, `.bashrc` und `tmux` für effiziente Workflows integriert. Die Skripte automatisieren Literatur- und Abkürzungsverwaltung, während `tmux` parallele Bearbeitung und Vorschau ermöglicht. Wiederhole die Übungen, um LaTeX für andere Abschnitte (z. B. Methodik, Ergebnisse) anzupassen.

**Nächste Schritte**: Möchtest du eine Anleitung zu fortgeschrittenen LaTeX-Techniken (z. B. BibLaTeX, komplexe Tabellen), `zsh`-Integration, oder anderen Tools (z. B. `pandoc` für Markdown)?

**Quellen**:
- LaTeX-Dokumentation: https://www.latex-project.org/help/documentation/
- Vim-Dokumentation: `:help usr_41`, https://www.vim.org/docs.php
- Debian-Dokumentation: https://www.debian.org/releases/trixie/
- Webquellen: https://www.overleaf.com/learn, https://www.tug.org/
```
# Emacs Cheat Sheet für DevOps

## Überblick
Dieses Cheat Sheet bietet eine Übersicht über grundlegende Emacs-Tastenkombinationen, Python-Entwicklung mit Elpy und Org-Mode für Literate DevOps. Es enthält ausführbaren Code für die Einrichtung auf Debian, ideal für HomeLab-Workflows.

### Kernprinzipien
- **Emacs**: Leistungsstarker, anpassbarer Editor.
- **Elpy**: Python-IDE mit Autovervollständigung.
- **Org-Mode**: Interaktive Dokumentation mit ausführbarem Code.
- **Vorteile**: Effiziente Tastatursteuerung, Git-Integration, Literate DevOps.

## Schritt 1: Emacs und Abhängigkeiten installieren
**Beschreibung**: Installiere Emacs, Python und Elpy auf Debian.  
**Code**:
```bash
# Installiere Emacs, Python und Jedi
apt update
apt install -y emacs python3 python3-pip
pip3 install jedi
```

## Schritt 2: Emacs konfigurieren
**Beschreibung**: Konfiguriere Emacs für Python und Org-Mode.  
**Code**:
```bash
# Erstelle ~/.emacs.d/init.el
mkdir -p ~/.emacs.d
cat << 'EOF' > ~/.emacs.d/init.el
;; MELPA-Paketquelle
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Elpy für Python
(unless (package-installed-p 'elpy)
  (package-refresh-contents)
  (package-install 'elpy))
(elpy-enable)
(setq elpy-rpc-backend "jedi")

;; Org-Babel für Python/Shell
(require 'org)
(org-babel-do-load-languages
 'org-babel-load-languages
 '((python . t) (shell . t)))

;; Allgemeine Einstellungen
(global-display-line-numbers-mode 1)
(setq inhibit-startup-screen t)
EOF
```
**Erklärung**: Konfiguriert Elpy für Autovervollständigung, Org-Babel für interaktive Code-Blöcke und grundlegende Einstellungen.

## Cheat Sheet: Tastenkombinationen
### Grundlegende Navigation
- `C-x C-f`: Datei öffnen (`~/file.py`).
- `C-x C-s`: Speichern.
- `C-x C-c`: Emacs beenden.
- `C-g`: Befehl abbrechen.
- `C-h t`: Emacs-Tutorial starten.
- `M-x`: Befehl ausführen (z. B. `M-x eval-buffer`).

### Python mit Elpy
- `C-c C-c`: Code an Python-REPL senden.
- `TAB` oder `M-/`: Autovervollständigung (z. B. `pri` → `print`).
- `C-c C-v`: Syntax prüfen (via `flake8`).
- `M-x elpy-format-code`: Code formatieren (z. B. mit `black`).
- `C-c C-d`: Debugging starten.

### Org-Mode für Literate DevOps
- `C-c C-c`: Code-Block ausführen (z. B. Python, Bash).
- `C-c C-e m m`: Export als Markdown.
- `C-c C-e l p`: Export als PDF.
- `C-c C-v t`: Code extrahieren (tangle) in `.py` oder `.sh`.
- `C-c '`: Code-Block bearbeiten.

## Beispiel: Org-Mode Python-Skript
**Beschreibung**: Org-Dokument mit Python-Skript zur Container-Überwachung.  
**Anleitung**: Erstelle `monitor.org` in Emacs (`C-x C-f ~/monitor.org`):
```
#+TITLE: LXC-Monitoring
#+STARTUP: showall

* Überblick
Prüft den Status von =game-container=.

* Python-Skript
#+BEGIN_SRC python :results output
import subprocess
subprocess.run(["lxc-info", "-n", "game-container"], text=True)
#+END_SRC
```
**Ausführen**: Cursor in `#+BEGIN_SRC`, drücke `C-c C-c`. Ergebnisse unter `#+RESULTS:`.

## Tipps
- **Sicherheit**: `chmod 600 ~/.emacs.d/init.el`.
- **Fehlerbehebung**:
  - Prüfe Installation: `emacs --version`, `pip3 list | grep jedi`.
  - Debug: `emacs --debug-init`.
- **Erweiterungen**:
  - Versioniere: `git add ~/.emacs.d/init.el monitor.org`.
  - Füge `magit` hinzu: `M-x package-install RET magit`.
- **Best Practices**: Nutze `C-h k` für Tasten-Info, teste Blöcke einzeln.

## Reflexion
**Frage**: Wie unterstützt dieses Cheat Sheet HomeLab-Workflows?  
**Antwort**: Es bietet schnellen Zugriff auf Emacs-Befehle für Python und Org-Mode, ideal für automatisierte Skripte und Dokumentation.

## Nächste Schritte
- Erkunde Elpy-Debugging (`C-c C-d`).
- Integriere in HomeLab (z. B. TrueNAS-Skripte).
- Vertiefe Org-Mode für komplexe Workflows.

**Quellen**: Emacs Docs, Elpy Docs, Org-Mode Docs.
# Emacs Cheat Sheet für DevOps

### Wichtiger Tipp für Anfänger: Der Hilfemodus

Verzweifeln Sie nicht! Emacs hat ein umfassendes Hilfesystem direkt eingebaut. Wenn Sie sich unsicher sind, drücken Sie `C-h` gefolgt von einem weiteren Buchstaben:

* **`C-h t`**: Startet ein **Tutorial** für Einsteiger. Das ist der beste Weg, um die Grundlagen zu lernen.
* **`C-h k`**: Zeigt an, was ein bestimmter Tastaturbefehl tut. Drücken Sie `C-h k`, gefolgt von einem Befehl (z.B. `C-s`), um eine Erklärung zu erhalten.
* **`C-h f`**: Erklärt eine Funktion.

Mit diesen Befehlen sind Sie gut gerüstet, um die ersten Schritte in Emacs zu machen.

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
Die meisten Emacs-Befehle werden mit Tastenkombinationen ausgeführt, die oft mit zwei speziellen Tasten beginnen:

* **`C-`**: Steht für die **`Strg`**-Taste (Control). Drücken und halten Sie `Strg`, während Sie die nächste Taste drücken. Beispiel: `C-x` bedeutet `Strg` + `x`.
* **`M-`**: Steht für die **`Alt`**-Taste (Meta) auf den meisten Tastaturen. Drücken und halten Sie `Alt`, während Sie die nächste Taste drücken. Beispiel: `M-f` bedeutet `Alt` + `f`.

---

### Navigation & Bearbeitung

| Aktion | Befehl | Erklärung |
| :--- | :--- | :--- |
| **Öffnen** | `C-x C-f` | Öffnet eine Datei. (`C-x` drücken, loslassen, dann `C-f` drücken). |
| **Speichern** | `C-x C-s` | Speichert die aktuelle Datei. |
| **Speichern unter** | `C-x C-w` | Speichert die aktuelle Datei unter einem neuen Namen. |
| **Beenden** | `C-x C-c` | Schließt Emacs. |

### Cursor-Bewegung

| Aktion | Befehl | Erklärung |
| :--- | :--- | :--- |
| **Zeichen vor/zurück** | `C-f` / `C-b` | Bewegt den Cursor ein Zeichen vorwärts / rückwärts. |
| **Zeile rauf/runter** | `C-p` / `C-n` | Bewegt den Cursor eine Zeile nach oben / unten. |
| **Wort vor/zurück** | `M-f` / `M-b` | Bewegt den Cursor ein Wort vorwärts / rückwärts. |
| **Zeilenanfang/Ende** | `C-a` / `C-e` | Bewegt den Cursor an den Anfang / das Ende der aktuellen Zeile. |
| **Seitenanfang/Ende** | `M-<` / `M->` | Bewegt den Cursor an den Anfang / das Ende des Dokuments. |

### Textbearbeitung & Ausschneiden

| Aktion | Befehl | Erklärung |
| :--- | :--- | :--- |
| **Löschen** | `C-d` | Löscht das Zeichen unter dem Cursor. |
| **Zeile löschen** | `C-k` | Löscht den Rest der Zeile vom Cursor an. |
| **Ausschneiden** | `C-w` | Schneidet den ausgewählten Text aus (nachdem Sie ihn mit `C-Space` markiert haben). |
| **Kopieren** | `M-w` | Kopiert den ausgewählten Text. |
| **Einfügen** | `C-y` | Fügt den Text ein. |

### Suche und Ersetzen

| Aktion | Befehl | Erklärung |
| :--- | :--- | :--- |
| **Suche** | `C-s` | Startet eine inkrementelle Suche nach Text. |
| **Ersetzen** | `M-%` | Findet und ersetzt Text. |

### Fenster und Puffer

| Aktion | Befehl | Erklärung | |
| :--- | :--- | :--- | :--- |
| **Puffer anzeigen** | `C-x C-b` | Zeigt eine Liste aller geöffneten Puffer an (Dateien). |
| **Puffer wechseln** | `C-x b` | Wechselt zu einem anderen Puffer (Sie müssen den Namen eintippen). |
| **Puffer schließen** | `C-x k` | Schließt den aktuellen Puffer. |
| **Fenster teilen (vertikal)** | `C-x 2` | Teilt das Fenster in zwei vertikale Teile. |
| **Fenster teilen (horizontal)** | `C-x 3` | Teilt das Fenster in zwei horizontale Teile. |
| **Fenster wechseln** | `C-x o` | Wechselt zwischen den geteilten Fenstern. |

---

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
# Emacs für Python einrichten auf Debian

## Überblick
Diese Anleitung zeigt, wie man Emacs auf Debian für Python-Entwicklung einrichtet, inklusive Installation, Konfiguration und grundlegender Nutzung. Der Literate DevOps-Ansatz kombiniert narrative Dokumentation mit ausführbarem Code, um einen reproduzierbaren Python-Workflow zu schaffen.

### Kernprinzipien
- **Python-Umgebung**: Emacs als IDE mit Syntax-Highlighting, Autovervollständigung und Debugging.
- **Anpassbarkeit**: Konfiguriere Emacs für Python mit Paketen wie `elpy`.
- **Vorteile**:
  - Einheitliche Umgebung für Python-Coding und Dokumentation.
  - Effiziente Tastatursteuerung.
  - Git-Integration für HomeLab-Projekte.

## Schritt 1: Emacs und Python installieren
**Beschreibung**: Installiere Emacs und Python 3 auf Debian.  
**Code**:
```bash
# Installiere Emacs und Python
apt update
apt install -y emacs python3 python3-pip
```
**Erklärung**: Der Code installiert Emacs (Version ≥ 29.x in Debian Bookworm) und Python 3 mit `pip` für Paketverwaltung. Die Option `-y` automatisiert die Installation.

## Schritt 2: Emacs für Python konfigurieren
**Beschreibung**: Installiere und konfiguriere `elpy`, ein Python-Entwicklungspaket für Emacs.  
**Code**:
```bash
# Installiere Python-Abhängigkeiten für elpy
pip3 install jedi flake8 autopep8 black

# Erstelle ~/.emacs.d/init.el für Python-Konfiguration
mkdir -p ~/.emacs.d
cat << 'EOF' > ~/.emacs.d/init.el
;; Paketquellen hinzufügen
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Installiere und konfiguriere elpy
(unless (package-installed-p 'elpy)
  (package-refresh-contents)
  (package-install 'elpy))
(elpy-enable)

;; Aktiviere Zeilennummern und Syntax-Highlighting
(global-display-line-numbers-mode 1)
(setq inhibit-startup-screen t)
EOF
```
**Erklärung**: Der Code installiert Python-Pakete (`jedi` für Autovervollständigung, `flake8` für Linting, `autopep8`/`black` für Code-Formatierung). Die `init.el` aktiviert die MELPA-Paketquelle, installiert `elpy` und konfiguriert grundlegende Einstellungen wie Zeilennummern.

## Schritt 3: Emacs starten und Python testen
**Beschreibung**: Starte Emacs, öffne eine Python-Datei und teste die Entwicklungsumgebung.  
**Code**:
```bash
# Starte Emacs im Terminal
emacs -nw

# Erstelle eine Test-Python-Datei
cat << 'EOF' > test.py
def hello_world():
    name = input("Enter your name: ")
    print(f"Hello, {name}!")

if __name__ == "__main__":
    hello_world()
EOF
```
**Erklärung**: Der Code startet Emacs im Terminal (`-nw` für keine GUI). Die `test.py`-Datei enthält eine einfache Python-Funktion, die eine Eingabe verarbeitet und ausgibt.

**Anleitung in Emacs**:
1. Öffne `test.py`: Drücke `C-x C-f`, gib `~/test.py` ein, Enter.
2. Bearbeite: Nutze `elpy` für Autovervollständigung (z. B. tippe `pri`, drücke `TAB` für `print`).
3. Führe aus: Drücke `C-c C-c` (elpy sendet Code an Python-REPL).
4. Speichere: `C-x C-s`.
5. Beende: `C-x C-c`.

## Schritt 4: Python-Code formatieren und prüfen
**Beschreibung**: Nutze `elpy` für Code-Formatierung und Linting.  
**Anleitung**:
1. In `test.py`, prüfe Syntax: `C-c C-v` (elpy-check).
2. Formatiere Code: `M-x elpy-format-code` (nutzt `black` oder `autopep8`).
3. Ergebnisse: Fehler oder Formatierungen werden im Buffer angezeigt.

**Beispiel-Code in test.py nach Formatierung**:
```python
def hello_world():
    name = input("Enter your name: ")
    print(f"Hello, {name}!")
    
if __name__ == "__main__":
    hello_world()
```

## Tipps
- **Sicherheit**: Schütze Konfigurationsdatei: `chmod 600 ~/.emacs.d/init.el`.
- **Fehlerbehebung**:
  - Prüfe Emacs-Version: `emacs --version`.
  - Falls `elpy` fehlschlägt: Überprüfe Python-Pakete (`pip3 list | grep jedi`).
  - Emacs-Fehler: Starte mit `emacs --debug-init` für Diagnose.
- **Erweiterungen**:
  - Versioniere `init.el` in Git: `git add ~/.emacs.d/init.el`.
  - Füge `magit` hinzu für Git-Integration: `M-x package-install RET magit`.
- **Best Practices**: Lerne Tastenkombinationen (`C-h t` für Tutorial), halte `init.el` modular.

## Reflexion
**Frage**: Wie erleichtert Emacs Python-Entwicklung im HomeLab?  
**Antwort**: Emacs mit `elpy` bietet Autovervollständigung, Linting und REPL-Integration in einer einheitlichen Umgebung, ideal für Skripte oder Automatisierung in deinem HomeLab.

## Nächste Schritte
- Erkunde `elpy`-Features (z. B. Debugging mit `C-c C-d`).
- Integriere mit HomeLab (z. B. Python-Skripte für LXC-Container).
- Füge Org-Mode für Literate DevOps hinzu.

**Quellen**: Emacs Docs, Elpy Docs, Python Docs.
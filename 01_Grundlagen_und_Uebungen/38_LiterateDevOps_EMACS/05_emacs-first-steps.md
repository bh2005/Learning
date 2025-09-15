# Erste Schritte mit Emacs auf Debian

## Überblick
Emacs ist ein leistungsstarker, anpassbarer Texteditor, ideal für DevOps-Workflows. Diese Anleitung zeigt die Installation auf Debian und die grundlegende Nutzung des Editors. Der Literate DevOps-Ansatz kombiniert klare Dokumentation mit ausführbarem Code für eine reproduzierbare Einrichtung.

### Kernprinzipien
- **Editor-Fokus**: Bearbeite Text, Code und Konfigurationen direkt im Editor.
- **Anpassbarkeit**: Emacs ist durch Konfigurationsdateien erweiterbar.
- **Vorteile**:
  - Einheitliche Umgebung für Coding und Dokumentation.
  - Tastaturzentrierte Bedienung für Effizienz.
  - Offline-fähig, Git-integrierbar.

## Schritt 1: Emacs installieren
**Beschreibung**: Installiere Emacs auf einem Debian-System.  
**Code**:
```bash
# Aktualisiere Paketquellen und installiere Emacs
apt update
apt install -y emacs
```
**Erklärung**: Der Code aktualisiert die Paketquellen und installiert die neueste Emacs-Version (z. B. 29.x in Debian Bookworm). Die Option `-y` automatisiert die Bestätigung.

## Schritt 2: Emacs starten
**Beschreibung**: Starte Emacs und mache dich mit der Oberfläche vertraut.  
**Code**:
```bash
# Starte Emacs im Terminal
emacs -nw
```
**Erklärung**: Die Option `-nw` startet Emacs im Terminal (ohne GUI), ideal für Server oder LXC-Container. Die Benutzeroberfläche zeigt eine Willkommensseite.

## Schritt 3: Grundlegende Bedienung
**Beschreibung**: Lerne grundlegende Tastenkombinationen für die Navigation und Bearbeitung.  
**Anleitung**:
1. **Datei öffnen**:
   - Drücke `C-x C-f` (Halte `Ctrl`, drücke `x`, dann `f`), gib `~/test.txt` ein, Enter.
   - Erstelle oder bearbeite die Datei.
2. **Text eingeben**:
   - Tippe beliebigen Text, z. B. `Testdokument für Emacs`.
3. **Speichern**:
   - Drücke `C-x C-s` zum Speichern.
4. **Beenden**:
   - Drücke `C-x C-c` zum Verlassen von Emacs.
**Erklärung**: Emacs verwendet Tastenkombinationen (`C` = Ctrl). `C-x C-f` öffnet eine Datei, `C-x C-s` speichert, `C-x C-c` beendet Emacs. Diese Befehle sind die Grundlage für die Editor-Nutzung.

## Schritt 4: Konfiguration anpassen
**Beschreibung**: Erstelle eine Basis-Konfigurationsdatei für Emacs.  
**Code**:
```bash
# Erstelle ~/.emacs.d/init.el
mkdir -p ~/.emacs.d
cat << 'EOF' > ~/.emacs.d/init.el
;; Deaktiviere die Willkommensseite
(setq inhibit-startup-screen t)

;; Aktiviere Zeilennummern
(global-display-line-numbers-mode 1)
EOF
```
**Erklärung**: Der Code erstellt eine Konfigurationsdatei `init.el`, die die Willkommensseite deaktiviert und Zeilennummern aktiviert. Lade die Konfiguration nach Änderungen mit `M-x eval-buffer` (Alt+x, dann `eval-buffer`) oder starte Emacs neu.

## Tipps
- **Sicherheit**: Schütze die Konfigurationsdatei: `chmod 600 ~/.emacs.d/init.el`.
- **Fehlerbehebung**:
  - Prüfe Installation: `emacs --version`.
  - Falls Emacs nicht startet: Überprüfe Paketquellen (`apt update`).
- **Erweiterungen**:
  - Versioniere `init.el` in Git: `git add ~/.emacs.d/init.el`.
  - Erkunde später Org-Mode oder Pakete wie `magit` für Git-Integration.
- **Best Practices**: Lerne Tastenkombinationen schrittweise, nutze `C-h t` für das Tutorial.

## Reflexion
**Frage**: Wie erleichtert Emacs DevOps-Workflows?  
**Antwort**: Emacs bietet eine einheitliche, tastaturzentrierte Umgebung, die Dokumentation und Coding vereint. Die einfache Installation und Konfiguration machen es ideal für HomeLab-Setups.

## Nächste Schritte
- Erkunde Org-Mode für Literate DevOps.
- Passe `init.el` für spezifische Workflows an (z. B. Syntax-Highlighting).
- Integriere Emacs in dein HomeLab (z. B. für Skript-Bearbeitung).

**Quellen**: Emacs Docs, Debian Package Docs.
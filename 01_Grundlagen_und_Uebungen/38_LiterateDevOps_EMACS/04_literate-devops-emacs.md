# Interaktives Literate DevOps mit Emacs Org-Mode

## Überblick
Literate DevOps mit Emacs Org-Mode macht Dokumentation zur primären Quelle, in die ausführbarer Code eingebettet ist. Org-Mode ermöglicht interaktive Workflows durch Ausführung von Code-Blöcken direkt im Dokument, mit Ergebnissen, die inline angezeigt werden. Dies fördert Klarheit, Wartbarkeit und Teamzusammenarbeit in DevOps-Workflows.

### Kernprinzipien
- **Dokumentation zuerst**: Narrative Beschreibung des Prozesses, ergänzt durch Code.
- **Interaktivität**: Code-Blöcke ausführen mit `C-c C-c` (Org-Babel), Ergebnisse im Dokument anzeigen.
- **Einheitlichkeit**: Ein Org-Dokument kombiniert Erklärung, Code und Ergebnisse.
- **Vorteile**:
  - Offline-fähig, leichtgewichtig, Git-integrierbar.
  - Unterstützt mehrere Sprachen (Bash, Python, etc.).
  - Ideal für komplexe DevOps-Workflows.

## Vorbereitung
1. **Emacs und Org-Mode installieren**:
   ```bash
   # Installiere Emacs auf Debian
   apt update && apt install -y emacs
   ```
   Org-Mode ist in Emacs integriert (Version ≥ 9.1). Starte Emacs: `emacs`.

2. **Org-Babel für Bash aktivieren**:
   - Öffne Emacs, erstelle `~/.emacs` oder `~/.emacs.d/init.el`:
     ```emacs-lisp
     (require 'org)
     (org-babel-do-load-languages
      'org-babel-load-languages
      '((shell . t)))
     ```
   - Lade die Konfiguration: `M-x eval-buffer` oder starte Emacs neu.

3. **Erstelle ein Org-Dokument**:
   - Erstelle eine Datei, z. B. `devops.org`, mit `C-x C-f devops.org`.

## Quick Start: Beispiel in Org-Mode
**Beschreibung**: Richte einen LXC-Container ein, installiere `nudoku` und sichere Spielstände auf TrueNAS interaktiv in einem Org-Dokument.

### Org-Dokument Beispiel
1. **Erstelle `devops.org`**:
   Öffne Emacs, füge folgenden Inhalt ein:
   ```
   #+TITLE: Literate DevOps: LXC-Container mit Nudoku
   #+STARTUP: showall

   * Überblick
   Dieses Dokument richtet einen Debian LXC-Container ein, installiert =nudoku= und sichert Spielstände auf TrueNAS (192.168.30.100). Es zeigt interaktives Literate DevOps mit Org-Mode.

   * Schritt 1: LXC-Container einrichten
   Installiere LXC und erstelle einen Debian-Container.

   #+BEGIN_SRC sh :results output
   apt update && apt install -y lxc
   lxc-create -t download -n game-container -- -d debian -r bookworm -a amd64
   lxc-start -n game-container
   #+END_SRC

   * Schritt 2: Nudoku installieren
   Installiere =nudoku= im Container und teste die Installation.

   #+BEGIN_SRC sh :results output
   lxc-attach -n game-container -- bash -c "apt update && apt install -y nudoku"
   lxc-attach -n game-container -- nudoku --version
   #+END_SRC

   * Schritt 3: Spielstände sichern
   Sichere den Spielstand auf TrueNAS.

   #+BEGIN_SRC sh :results output
   lxc-attach -n game-container -- bash -c "mkdir -p /root/games && chmod 700 /root/games"
   lxc-attach -n game-container -- bash -c "[ -f /root/.nudoku ] && cp /root/.nudoku /root/games/nudoku.score"
   lxc-attach -n game-container -- bash -c "tar -czf /tmp/nudoku-backup-$(date +%Y-%m-%d).tar.gz /root/games"
   lxc-attach -n game-container -- bash -c "scp /tmp/nudoku-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/games/"
   #+END_SRC

   * Reflexion
   Wie verbessert Org-Mode die Wartbarkeit? Die narrative Struktur erklärt *warum* jeder Schritt erfolgt, und die interaktive Ausführung zeigt Ergebnisse direkt im Dokument.
   ```

2. **Interaktive Ausführung**:
   - Platziere den Cursor in einem `#+BEGIN_SRC`-Block.
   - Drücke `C-c C-c`, um den Code auszuführen. Ergebnisse erscheinen unter `#+RESULTS:`.
   - Beispiel-Ergebnis für Schritt 2:
     ```
     #+RESULTS:
     nudoku 2.0
     ```

3. **Exportieren**:
   - Exportiere als Markdown oder PDF: `C-c C-e m m` (Markdown) oder `C-c C-e l p` (PDF via LaTeX).
   - Extrahiere Code: `C-c C-v t` (tangle) erzeugt eine `.sh`-Datei.

## Tipps
- **Sicherheit**:
  - Schütze Spielstände: `chmod 600 /root/games/*`.
  - Nutze SSH-Schlüssel für SCP.
- **Fehlerbehebung**:
  - Prüfe Container-Status: `lxc-info -n game-container`.
  - Prüfe Org-Babel-Logs: `M-x org-babel-view-last-log`.
- **Erweiterungen**:
  - Versioniere `devops.org` in Git: `git add devops.org`.
  - Nutze Org-Mode für Python (z. B. Visualisierung von Spielständen):
    ```org
    #+BEGIN_SRC python :results output
    print("Analyse Spielstände")
    #+END_SRC
    ```
  - Integriere in CI/CD zur Validierung.
- **Best Practices**:
  - Strukturiere mit Überschriften (*, **).
  - Dokumentiere Annahmen klar.
  - Teste Code-Blöcke isoliert mit `C-c C-c`.

## Reflexion
**Frage**: Wie fördert Org-Mode interaktive DevOps-Workflows?  
**Antwort**: Durch direkte Code-Ausführung und inline-Ergebnisse wird Fehlersuche intuitiv. Die Textbasis ermöglicht Offline-Nutzung und Git-Integration, ideal für HomeLab-Setups.

## Nächste Schritte
- Erkunde Org-Mode für komplexe Workflows (z. B. TrueNAS-Automatisierung).
- Integriere mit Jupyter für Web-Zugang.
- Automatisiere Tests in CI/CD-Pipelines.

**Quellen**: Emacs Org-Mode Docs, LXC-Dokumentation, Literate Programming Konzepte.
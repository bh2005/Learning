# Praxisorientierte Anleitung: Export einer Slides-Präsentation als PDF, Erstellung eines Templates und Verwaltung mit Git

## Grundlagen
Diese Anleitung erweitert die Nutzung von **Slides** (https://github.com/maaslalani/slides) in einem Debian LXC-Container, indem wir:
- Eine Markdown-Präsentation mit **Pandoc** und **LaTeX** (Beamer) als PDF exportieren.
- Ein wiederverwendbares Markdown-Template für Präsentationen erstellen.
- Ein Git-Repository für Versionskontrolle initialisieren.
- Backups auf TrueNAS automatisieren.

### Wichtige Konzepte
- **Pandoc**: Konvertiert Markdown in verschiedene Formate, z. B. PDF (via LaTeX).
- **LaTeX (Beamer)**: LaTeX-Klasse für Präsentationen, erstellt professionelle PDFs.
- **Git**: Versionskontrollsystem zur Verwaltung von Präsentationen und Templates.
- **Einsatzmöglichkeiten**:
  - PDF-Export für Archivierung oder Weitergabe.
  - Templates für einheitliche Präsentationen.
  - Git für Zusammenarbeit und Nachverfolgbarkeit.
- **Sicherheitsaspekte**:
  - Schütze sensible Daten in Präsentationen.
  - Sichere Git-Repository-Zugangsdaten.
  - Automatisiere Backups.

## Vorbereitung
1. **Prüfe den LXC-Container**:
   - Verbinde dich: `ssh root@192.168.30.124`.
   - Überprüfe Slides und die Präsentation:
     ```bash
     slides /root/presentations/pki_presentation.md
     ```
   - Stelle sicher, dass `/root/presentations/pki_presentation.md` existiert.

2. **Installiere benötigte Pakete**:
   ```bash
   apt update
   apt install -y pandoc texlive texlive-latex-extra texlive-fonts-extra git
   ```

3. **Prüfe DNS-Eintrag**:
   - Auf OPNsense (`http://192.168.30.1`):
     - Gehe zu `Services > Unbound DNS > Overrides > Host`.
     - Prüfe: `slides.homelab.local` → `192.168.30.124`.
     - Teste: `nslookup slides.homelab.local 192.168.30.1`.

## Übung 1: Präsentation als PDF exportieren
**Ziel**: Exportiere `pki_presentation.md` als PDF mit Pandoc und LaTeX.

1. **Teste die Präsentation**:
   ```bash
   cd /root/presentations
   slides pki_presentation.md
   ```
   - Stelle sicher, dass die Präsentation korrekt gerendert wird.

2. **Exportiere als PDF**:
   ```bash
   pandoc -t beamer pki_presentation.md -o pki_presentation.pdf
   ```
   - **Hinweis**: `-t beamer` verwendet die LaTeX-Beamer-Klasse für Präsentationen.

3. **Prüfe das PDF**:
   ```bash
   apt install -y evince
   evince pki_presentation.pdf
   ```
   - Erwartete Ausgabe: PDF zeigt die Präsentation mit Folien (eine pro `---`-Trennung).

4. **Kopiere das PDF in ein Export-Verzeichnis**:
   ```bash
   mkdir -p /root/presentations/export
   mv pki_presentation.pdf /root/presentations/export/
   chmod 644 /root/presentations/export/pki_presentation.pdf
   ```

**Reflexion**: Warum ist ein PDF-Export nützlich? Überlege, wie Beamer die Präsentationsqualität verbessert.

## Übung 2: Erstellung eines Präsentations-Templates
**Ziel**: Erstelle ein wiederverwendbares Markdown-Template für Slides-Präsentationen.

1. **Erstelle das Template**:
   ```bash
   nano /root/presentations/templates/presentation_template.md
   ```
   Füge hinzu:
   ```markdown
   # [Titel der Präsentation]

   ## Willkommen
   - [Kurze Einführung]
   - Erstellt von: [Dein Name/Team]
   - Datum: [Datum]

   ---

   ## Überblick
   - [Ziel der Präsentation]
   - [Thema 1]
   - [Thema 2]

   ---

   ## Details
   - [Detail 1]
     - [Unterpunkt 1]
     - [Unterpunkt 2]
   - [Detail 2]
     ```bash
     [Beispielcode]
     ```

   ---

   ## Fazit
   - [Zusammenfassung]
   - **Nächste Schritte**:
     - [Aktion 1]
     - [Aktion 2]
   - Fragen?

   ---
   ```
   Speichere (Ctrl+O, Enter) und beende (Ctrl+X).

2. **Teste das Template**:
   ```bash
   cp /root/presentations/templates/presentation_template.md /root/presentations/test_presentation.md
   nano /root/presentations/test_presentation.md
   ```
   - Passe den Inhalt an, z. B.:
     ```markdown
     # HomeLab Netzwerkübersicht

     ## Willkommen
     - Überblick über das HomeLab-Netzwerk
     - Erstellt von: HomeLab Team
     - Datum: 11. September 2025

     ---
     ```
   - Speichere und teste:
     ```bash
     slides test_presentation.md
     ```

**Reflexion**: Wie erleichtert ein Template die Erstellung von Präsentationen? Überlege, wie es für verschiedene Themen angepasst werden kann.

## Übung 3: Git-Repository initialisieren und verwalten
**Ziel**: Initialisiere ein Git-Repository für Präsentationen und Templates.

1. **Initialisiere das Git-Repository**:
   ```bash
   cd /root/presentations
   git init
   ```

2. **Füge Dateien hinzu**:
   ```bash
   git add pki_presentation.md export/pki_presentation.pdf templates/presentation_template.md
   git commit -m "Initial commit: PKI-Präsentation, PDF und Template"
   ```

3. **Erstelle ein Remote-Repository (optional)**:
   - **Hinweis**: Wenn ein Git-Server verfügbar ist (z. B. auf TrueNAS oder einem Git-Dienst), konfiguriere ein Remote-Repository:
     ```bash
     git remote add origin ssh://root@192.168.30.100/mnt/tank/git/slides.git
     git push -u origin main
     ```
   - Alternativ: Lokal verwalten oder später ein Remote-Repository einrichten.

4. **Erstelle eine .gitignore-Datei**:
   ```bash
   nano /root/presentations/.gitignore
   ```
   Füge hinzu:
   ```
   *.tar.gz
   *.log
   ```
   Speichere und beende.

5. **Commit der .gitignore**:
   ```bash
   git add .gitignore
   git commit -m "Add .gitignore to exclude temporary files"
   ```

**Reflexion**: Wie unterstützt Git die Nachverfolgbarkeit von Präsentationen? Überlege, wie ein Remote-Repository die Zusammenarbeit verbessert.

## Übung 4: Backup und Automatisierung
**Ziel**: Sichere Präsentationen, PDFs und das Git-Repository auf TrueNAS.

1. **Erweitere das Backup-Skript**:
   ```bash
   nano /usr/local/bin/slides_backup.sh
   ```
   Aktualisiere:
   ```bash
   #!/bin/bash
   trap 'echo "Backup unterbrochen"; exit 1' INT TERM
   cd /root/presentations
   git add .
   git commit -m "Backup: $(date +%Y-%m-%d)" || true
   tar -czf /tmp/slides-backup-$(date +%Y-%m-%d).tar.gz /root/presentations
   scp /tmp/slides-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/slides/
   echo "Präsentationen, PDFs und Git-Repository gesichert auf TrueNAS"
   trap - INT TERM
   ```
   Ausführbar machen:
   ```bash
   chmod +x /usr/local/bin/slides_backup.sh
   ```

2. **Teste das Backup**:
   ```bash
   /usr/local/bin/slides_backup.sh
   ```
   - Erwartete Ausgabe: Präsentationen, PDFs und Git-Repository werden auf TrueNAS gesichert.

3. **Prüfe Cron**:
   ```bash
   nano /etc/crontab
   ```
   - Stelle sicher, dass die Zeile existiert:
     ```bash
     0 5 * * * root /usr/local/bin/slides_backup.sh >> /var/log/slides-backup.log 2>&1
     ```

**Reflexion**: Wie schützt das Backup die Präsentationen und das Git-Repository? Überlege, wie Git-Backups die Wiederherstellung vereinfachen.

## Tipps für den Erfolg
- **Sicherheit**:
  - Schütze das Git-Repository:
    ```bash
    chmod 700 /root/presentations/.git
    ```
  - Entferne sensible Daten aus Markdown-Dateien.
- **Fehlerbehebung**:
  - Prüfe Pandoc: `pandoc --version`.
  - Prüfe LaTeX: `pdflatex --version`.
  - Prüfe Git: `git --version`.
  - Prüfe Backup-Logs: `tail /var/log/slides-backup.log`.
- **Backup**:
  - Überprüfe Backups:
    ```bash
    ssh root@192.168.30.100 ls /mnt/tank/backups/slides/
    ```
- **Erweiterungen**:
  - Passe das Beamer-Template an:
    ```bash
    nano /root/presentations/beamer_template.tex
    ```
    ```latex
    \documentclass{beamer}
    \usetheme{Madrid}
    \usecolortheme{default}
    \usepackage[utf8]{inputenc}
    \begin{document}
    \input{pki_presentation.md}
    \end{document}
    ```
    ```bash
    pandoc -t beamer pki_presentation.md --template beamer_template.tex -o pki_presentation_custom.pdf
    ```
  - Richte ein Remote-Git-Repository auf TrueNAS oder GitLab ein.
  - Verwende Reveal.js für webbasierte Präsentationen.

## Fazit
Du hast die Slides-Präsentation `pki_presentation.md` als PDF exportiert, ein wiederverwendbares Markdown-Template erstellt, ein Git-Repository für Versionskontrolle initialisiert und Backups auf TrueNAS automatisiert. Das Template und Git ermöglichen eine effiziente Verwaltung von Präsentationen. Wiederhole die Übungen, um weitere Präsentationen zu erstellen, oder erweitere die Funktionalität.

**Nächste Schritte**: Möchtest du eine Anleitung zu Reveal.js für webbasierte Präsentationen, Integration mit anderen HomeLab-Diensten (z. B. Papermerge), oder weiteren Git-Funktionen?

**Quellen**:
- Pandoc-Dokumentation: https://pandoc.org/MANUAL.html
- LaTeX-Beamer-Dokumentation: https://ctan.org/pkg/beamer
- Git-Dokumentation: https://git-scm.com/doc
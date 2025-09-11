# Praxisorientierte Anleitung: Grundlagen von GitHub Branches

## Einführung
Branches in GitHub ermöglichen es, parallele Entwicklungslinien für Features, Bugfixes oder Experimente zu erstellen, ohne den Hauptcode zu beeinträchtigen. Diese Anleitung konzentriert sich auf die Schwerpunkte **Erstellung und Verwaltung von Branches**, **Zusammenarbeit mit Pull Requests** und **Konfliktlösung bei Merges**, um effiziente und kollaborative Workflows zu etablieren. Eine **Spielerei** zeigt, wie du einen Feature-Branch für eine Markdown-Dokumentation nutzt und in den Hauptbranch integrierst. Durch praktische Übungen lernst du, Branches zu erstellen, Pull Requests zu nutzen und Konflikte zu lösen.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Git installiert (prüfe mit `git --version`; installiere via `choco install git` auf Windows, `sudo apt install git` auf Ubuntu oder `brew install git` auf macOS).
- Ein GitHub-Konto mit einem bestehenden Repository.
- Grundkenntnisse in Git (z. B. Commits, Push, Pull).
- Sichere Testumgebung (z. B. `$HOME/branch_test` oder `~/branch_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Befehle für die Arbeit mit GitHub Branches, aufgeteilt nach den Hauptthemen:

1. **Erstellung und Verwaltung von Branches**:
   - `git branch <name>`: Erstellt einen neuen Branch.
   - `git checkout <name>`: Wechselt zu einem Branch.
   - `git checkout -b <name>`: Erstellt und wechselt direkt zu einem neuen Branch.
   - `git branch -d <name>`: Löscht einen Branch lokal.
   - `git push origin --delete <name>`: Löscht einen Branch auf GitHub.
2. **Zusammenarbeit mit Pull Requests**:
   - `git push origin <branch>`: Pusht einen Branch zu GitHub.
   - `git pull`: Synchronisiert Änderungen vom Remote-Repository.
   - Pull Requests: Erstellt über die GitHub-Oberfläche, um Änderungen zu prüfen und zu mergen.
3. **Konfliktlösung bei Merges**:
   - `git merge <branch>`: Führt einen Branch in den aktuellen Branch ein.
   - `git diff`: Zeigt Konflikte oder Änderungen an.
   - `git add`/`git commit`: Löst Konflikte nach Bearbeitung ab.
4. **Nützliche Zusatzbefehle**:
   - `git status`: Zeigt den Status des Arbeitsverzeichnisses.
   - `git log --oneline --graph`: Visualisiert die Branch-Historie.
   - `git config`: Konfiguriert Benutzername und E-Mail.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Erstellung und Verwaltung von Branches
**Ziel**: Erstelle und verwalte Branches in einem GitHub-Repository.

1. **Schritt 1**: Erstelle ein neues Projekt und initialisiere ein Git-Repository:
   ```bash
   mkdir branch_test
   cd branch_test
   git init
   echo "# Mein Projekt" > README.md
   git add README.md
   git commit -m "Initialer Commit: README hinzugefügt"
   ```

2. **Schritt 2**: Erstelle ein GitHub-Repository (ohne README, .gitignore oder Lizenz) und verbinde es:
   ```bash
   git remote add origin https://github.com/dein-benutzername/branch_test.git
   git push -u origin main
   ```
   Ersetze `dein-benutzername` durch deinen GitHub-Benutzernamen.

3. **Schritt 3**: Erstelle und wechsle zu einem neuen Branch:
   ```bash
   git checkout -b feature-1
   ```

4. **Schritt 4**: Füge eine Datei hinzu und committe sie:
   ```bash
   echo "Dies ist eine neue Funktion" > feature1.txt
   git add feature1.txt
   git commit -m "Feature 1: Neue Datei hinzugefügt"
   git push origin feature-1
   ```

5. **Schritt 5**: Wechsle zurück zum `main`-Branch und erstelle einen zweiten Branch:
   ```bash
   git checkout main
   git checkout -b feature-2
   echo "Eine weitere Funktion" > feature2.txt
   git add feature2.txt
   git commit -m "Feature 2: Neue Datei hinzugefügt"
   git push origin feature-2
   ```

6. **Schritt 6**: Überprüfe die Branch-Historie:
   ```bash
   git log --oneline --graph --all
   ```

**Reflexion**: Wie hilft die Branch-Struktur bei paralleler Entwicklung? Nutze `git help branch` und überlege, wie du Branches für verschiedene Aufgaben organisieren kannst.

### Übung 2: Zusammenarbeit mit Pull Requests
**Ziel**: Nutze Pull Requests, um Änderungen aus Branches zu überprüfen und zu mergen.

1. **Schritt 1**: Erstelle einen Pull Request für `feature-1`:
   - Öffne dein Repository auf GitHub.
   - Wähle den `feature-1`-Branch und klicke auf „New Pull Request“.
   - Gib einen Titel (z. B. „Feature 1 hinzufügen“) und eine Beschreibung ein.
   - Erstelle den Pull Request und merge ihn in den `main`-Branch.

2. **Schritt 2**: Synchronisiere den lokalen `main`-Branch:
   ```bash
   git checkout main
   git pull origin main
   ```

3. **Schritt 3**: Lösche den `feature-1`-Branch:
   ```bash
   git push origin --delete feature-1
   git branch -d feature-1
   ```

4. **Schritt 4**: Erstelle einen Pull Request für `feature-2` und füge einen Reviewer hinzu (falls du mit einem Team arbeitest):
   - Wiederhole den Prozess auf GitHub für den `feature-2`-Branch.
   - Merge den Pull Request nach Überprüfung.

5. **Schritt 5**: Überprüfe die aktualisierte Historie:
   ```bash
   git checkout main
   git pull origin main
   git log --oneline --graph
   ```

**Reflexion**: Warum sind Pull Requests für die Code-Qualität wichtig? Nutze die GitHub-Dokumentation (https://docs.github.com) und überlege, wie du Pull Request-Vorlagen nutzen kannst.

### Übung 3: Konfliktlösung bei Merges und Spielerei
**Ziel**: Löse Merge-Konflikte und erstelle eine Spielerei, bei der ein Feature-Branch eine Markdown-Dokumentation erweitert.

1. **Schritt 1**: Erstelle zwei Branches mit sich überschneidenden Änderungen:
   ```bash
   git checkout -b doc-update-1
   echo -e "# Mein Projekt\n## Dokumentation\nErste Version der Doku." > docs.md
   git add docs.md
   git commit -m "Dokumentation: Erste Version hinzugefügt"
   git push origin doc-update-1
   ```

2. **Schritt 2**: Erstelle einen zweiten Branch mit einer Änderung an derselben Datei:
   ```bash
   git checkout main
   git checkout -b doc-update-2
   echo -e "# Mein Projekt\n## Dokumentation\nZweite Version der Doku." > docs.md
   git add docs.md
   git commit -m "Dokumentation: Zweite Version hinzugefügt"
   git push origin doc-update-2
   ```

3. **Schritt 3**: Merge `doc-update-1` in `main`:
   ```bash
   git checkout main
   git merge doc-update-1
   git push origin main
   ```

4. **Schritt 4**: Versuche, `doc-update-2` zu mergen, und löse den Konflikt:
   ```bash
   git merge doc-update-2
   ```
   Git meldet einen Konflikt in `docs.md`. Öffne die Datei:
   ```bash
   nano docs.md
   ```
   Die Datei zeigt Konfliktmarker (`<<<<<<<`, `=======`, `>>>>>>>`). Kombiniere die Änderungen, z. B.:
   ```markdown
   # Mein Projekt
   ## Dokumentation
   Erste und zweite Version der Doku kombiniert.
   ```
   Speichere und schließe. Schließe den Merge ab:
   ```bash
   git add docs.md
   git commit -m "Konflikt in docs.md gelöst"
   git push origin main
   ```

5. **Spielerei**: Erstelle einen Feature-Branch, um die Dokumentation zu erweitern:
   ```bash
   git checkout -b doc-enhancement
   echo -e "# Mein Projekt\n## Dokumentation\nErste und zweite Version der Doku kombiniert.\n### Neue Funktionen\n- Unterstützung für Markdown-Tabellen\n- Links zu externen Ressourcen" > docs.md
   git add docs.md
   git commit -m "Dokumentation: Tabellen und Links hinzugefügt"
   git push origin doc-enhancement
   ```

6. **Schritt 5**: Erstelle einen Pull Request für `doc-enhancement`:
   - Öffne GitHub, erstelle einen Pull Request für den `doc-enhancement`-Branch und merge ihn in `main`.
   - Überprüfe die aktualisierte `docs.md` im `main`-Branch.

**Reflexion**: Wie hilft die manuelle Konfliktlösung bei der Zusammenarbeit? Nutze `git help merge` und überlege, wie du automatische Konfliktvermeidung (z. B. durch klare Branch-Regeln) umsetzen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Branch-Workflows zu verinnerlichen.
- **Sicheres Testen**: Nutze Test-Branches, um Fehler zu vermeiden.
- **Fehler verstehen**: Lies Merge-Fehlermeldungen genau und nutze `git diff` oder die GitHub-Dokumentation (https://docs.github.com).
- **Effiziente Workflows**: Verwende sprechende Branch-Namen (z. B. `feature/`, `bugfix/`), Pull Requests für Reviews und klare Commit-Nachrichten.
- **Git konfigurieren**: Stelle sicher, dass deine Einstellungen korrekt sind:
  ```bash
  git config --global user.name "Dein Name"
  git config --global user.email "deine.email@example.com"
  ```
- **Kombiniere Tools**: Nutze GitHub-Wikis für Dokumentation, VS Code für Bearbeitung (`code .`) und GitHub Actions für automatisierte Tests.

## Fazit
Mit diesen Übungen hast du die Grundlagen von GitHub Branches gemeistert, einschließlich Erstellung, Pull Requests und Konfliktlösung. Die Spielerei zeigt, wie du einen Feature-Branch für Dokumentation nutzen kannst. Vertiefe dein Wissen, indem du fortgeschrittene Branch-Strategien (z. B. Gitflow), protected Branches oder automatische Checks in Pull Requests ausprobierst. Wenn du ein spezifisches Thema (z. B. Gitflow oder Rebase mit Branches) vertiefen möchtest, lass es mich wissen!

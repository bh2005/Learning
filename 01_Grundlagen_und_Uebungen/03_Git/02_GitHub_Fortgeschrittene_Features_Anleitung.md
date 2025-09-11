# Praxisorientierte Anleitung: Fortgeschrittene GitHub-Features für CI/CD, Dokumentation und Commit-Historie

## Einführung
GitHub bietet weit mehr als grundlegende Versionskontrolle. Diese Anleitung konzentriert sich auf fortgeschrittene Features: **GitHub Actions für Continuous Integration/Continuous Deployment (CI/CD)**, **Wikis für Projekt-Dokumentation** und **`git rebase` für eine saubere Commit-Historie**. Durch praktische Übungen lernst du, automatisierte Workflows einzurichten, strukturierte Dokumentationen zu erstellen und die Commit-Historie zu optimieren, um professionelle Softwareentwicklungsprozesse zu unterstützen.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Git installiert (prüfe mit `git --version`; installiere via `choco install git` auf Windows, `sudo apt install git` auf Ubuntu oder `brew install git` auf macOS).
- Ein GitHub-Konto mit einem bestehenden Repository.
- Grundkenntnisse in Git und GitHub (z. B. Commits, Branches, Pull Requests).
- Sichere Testumgebung (z. B. `$HOME/github_advanced_test` oder `~/github_advanced_test`).
- Optional: Ein einfacher Webserver (z. B. Hugo oder Node.js) für CI/CD-Tests.

## Grundlegende Befehle
Hier sind die zentralen Befehle und Konzepte, aufgeteilt nach den Hauptthemen:

1. **GitHub Actions für CI/CD**:
   - `.github/workflows/*.yml`: Definiert Workflows für automatisierte Builds, Tests und Deployments.
   - `actions/checkout`: Klont das Repository in der CI/CD-Pipeline.
   - `actions/setup-<language>`: Richtet Laufzeitumgebungen (z. B. Node.js, Python) ein.
   - `git push`: Löst Workflows bei Änderungen aus.
2. **Wikis für Dokumentation**:
   - GitHub-Wiki: Ein Git-Repository für Markdown-basierte Dokumentation.
   - `git clone <wiki-url>`: Klont das Wiki-Repository lokal.
   - `git add`/`git commit`/`git push`: Veröffentlicht Wiki-Änderungen.
3. **git rebase für saubere Commit-Historie**:
   - `git rebase`: Ordnet Commits neu oder kombiniert sie für eine lineare Historie.
   - `git rebase -i`: Interaktives Rebase zum Bearbeiten, Zusammenfassen oder Löschen von Commits.
   - `git push --force`: Aktualisiert den Remote-Branch nach einem Rebase.
4. **Nützliche Zusatzbefehle**:
   - `git log --oneline --graph`: Visualisiert die Commit-Historie.
   - `git diff`: Zeigt Unterschiede vor einem Rebase.
   - `git config`: Konfiguriert Git-Einstellungen.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: GitHub Actions für CI/CD
**Ziel**: Richte einen automatisierten Workflow ein, um einen Hugo-Webserver zu bauen und zu deployen.

1. **Schritt 1**: Erstelle ein Hugo-Projekt als Test-Repository:
   ```bash
   mkdir github_advanced_test
   cd github_advanced_test
   hugo new site my-site
   cd my-site
   git init
   echo "# Mein Projekt" > content/posts/first-post.md
   ```

2. **Schritt 2**: Initialisiere ein GitHub-Repository und pushe die Hugo-Site:
   ```bash
   git add .
   git commit -m "Initiale Hugo-Site"
   git remote add origin https://github.com/dein-benutzername/my-site.git
   git push -u origin main
   ```
   Ersetze `dein-benutzername` durch deinen GitHub-Benutzernamen.

3. **Schritt 3**: Erstelle einen GitHub Actions-Workflow:
   ```bash
   mkdir -p .github/workflows
   nano .github/workflows/hugo-deploy.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   name: Build and Deploy Hugo Site
   on:
     push:
       branches: [ main ]
     workflow_dispatch:
   permissions:
     contents: read
     pages: write
     id-token: write
   concurrency:
     group: pages
     cancel-in-progress: false
   jobs:
     build:
       runs-on: ubuntu-latest
       env:
         HUGO_VERSION: 0.149.0
       steps:
         - name: Checkout
           uses: actions/checkout@v5
           with:
             submodules: recursive
             fetch-depth: 0
         - name: Setup Hugo
           run: |
             curl -sLJO "https://github.com/gohugoio/hugo/releases/download/v${{ env.HUGO_VERSION }}/hugo_extended_${{ env.HUGO_VERSION }}_linux-amd64.tar.gz"
             tar -xf "hugo_extended_${{ env.HUGO_VERSION }}_linux-amd64.tar.gz" hugo
             mv hugo /usr/local/bin/
         - name: Build Site
           run: hugo --minify
         - name: Upload Artifact
           uses: actions/upload-pages-artifact@v3
           with:
             path: ./public
     deploy:
       environment:
         name: github-pages
         url: ${{ steps.deployment.outputs.page_url }}
       runs-on: ubuntu-latest
       needs: build
       steps:
         - name: Deploy to GitHub Pages
           id: deployment
           uses: actions/deploy-pages@v4
   ```
   Speichere und schließe.

4. **Schritt 4**: Committe und pushe den Workflow:
   ```bash
   git add .github/workflows/hugo-deploy.yml
   git commit -m "GitHub Actions Workflow für Hugo hinzugefügt"
   git push
   ```

5. **Schritt 5**: Aktiviere GitHub Pages in den Repository-Einstellungen (Source: GitHub Actions) und überprüfe den Workflow unter „Actions“ auf GitHub.

**Reflexion**: Wie spart GitHub Actions Zeit bei Builds? Nutze `git help push` und überlege, wie du Tests (z. B. Linting) in den Workflow integrieren kannst.

### Übung 2: Wikis für Dokumentation
**Ziel**: Erstelle und verwalte ein GitHub-Wiki für strukturierte Projekt-Dokumentation.

1. **Schritt 1**: Aktiviere das Wiki in deinem GitHub-Repository unter „Settings“ > „Features“ > „Wikis“.

2. **Schritt 2**: Klone das Wiki-Repository lokal:
   ```bash
   git clone https://github.com/dein-benutzername/my-site.wiki.git
   cd my-site.wiki
   ```

3. **Schritt 3**: Erstelle eine Markdown-Seite für die Dokumentation:
   ```bash
   echo '# Projektübersicht
## Über dieses Projekt
Dies ist ein Hugo-basiertes Projekt für eine statische Webseite.
## Installation
1. Installiere Hugo: `hugo version`
2. Klone das Repository: `git clone <repo-url>`' > Home.md
   ```

4. **Schritt 4**: Committe und pushe die Wiki-Seite:
   ```bash
   git add Home.md
   git commit -m "Wiki-Seite Home erstellt"
   git push
   ```
   Öffne dein GitHub-Wiki, um die Seite zu überprüfen.

5. **Schritt 5**: Füge eine weitere Seite hinzu:
   ```bash
   echo '# Entwicklung
## Workflow
- Erstelle einen Branch: `git branch feature`
- Committe Änderungen: `git commit -m "Beschreibung"`' > Development.md
   git add Development.md
   git commit -m "Wiki-Seite Development hinzugefügt"
   git push
   ```

**Reflexion**: Wie unterstützt ein Wiki die Zusammenarbeit? Überlege, wie du Markdown-Features wie Tabellen oder Links im Wiki nutzen kannst.

### Übung 3: git rebase für saubere Commit-Historie
**Ziel**: Nutze `git rebase`, um die Commit-Historie zu bereinigen und zu optimieren.

1. **Schritt 1**: Erstelle mehrere Commits im `feature`-Branch:
   ```bash
   cd ../my-site
   git checkout -b feature-rebase
   echo "Erste Änderung" >> content/posts/first-post.md
   git add .
   git commit -m "Erste Änderung am ersten Post"
   echo "Zweite Änderung" >> content/posts/first-post.md
   git add .
   git commit -m "Zweite Änderung am ersten Post"
   ```

2. **Schritt 2**: Starte ein interaktives Rebase, um die Commits zusammenzufassen:
   ```bash
   git rebase -i main
   ```
   Im Editor ändere die zweite Zeile von `pick` zu `squash` (oder `s`), um die Commits zu kombinieren. Speichere und schließe den Editor.

3. **Schritt 3**: Bearbeite die Commit-Nachricht:
   - Im nächsten Editor kombiniere die Nachrichten, z. B.:
     ```
     Kombinierte Änderungen am ersten Post
     ```
   Speichere und schließe.

4. **Schritt 4**: Überprüfe die bereinigte Historie:
   ```bash
   git log --oneline --graph
   ```

5. **Schritt 5**: Pushe den bereinigten Branch zu GitHub:
   ```bash
   git push --force origin feature-rebase
   ```

**Reflexion**: Warum ist eine saubere Commit-Historie wichtig? Nutze `git help rebase` und überlege, wie du Rebase-Konflikte lösen kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um fortgeschrittene Workflows zu verinnerlichen.
- **Sicheres Testen**: Nutze Test-Branches und -Repositories, um Fehler zu vermeiden.
- **Fehler verstehen**: Lies GitHub Actions-Logs oder Rebase-Fehlermeldungen genau und nutze `git help` oder die GitHub-Dokumentation (https://docs.github.com).
- **Effiziente Workflows**: Verwende Actions für automatisierte Tests, Wikis für strukturierte Dokumentation und Rebase für klare Historien.
- **Git konfigurieren**: Stelle sicher, dass deine Einstellungen korrekt sind:
  ```bash
  git config --global user.name "Dein Name"
  git config --global user.email "deine.email@example.com"
  ```
- **Kombiniere Tools**: Nutze Markdown für Wiki-Seiten, VS Code für Bearbeitung (`code .`) und Actions für komplexe CI/CD-Pipelines.

## Fazit
Mit diesen Übungen hast du fortgeschrittene GitHub-Features gemeistert, einschließlich CI/CD mit GitHub Actions, strukturierten Wikis und sauberer Commit-Historien mit `git rebase`. Vertiefe dein Wissen, indem du komplexere Workflows (z. B. Tests in Actions), erweiterte Wiki-Features (z. B. Seitenverlinkung) oder interaktives Rebase mit mehreren Commits ausprobierst. Wenn du ein spezifisches Thema (z. B. komplexe Actions oder Rebase-Strategien) vertiefen möchtest, lass es mich wissen!

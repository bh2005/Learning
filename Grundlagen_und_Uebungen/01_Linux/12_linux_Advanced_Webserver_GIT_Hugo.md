# Praxisorientierte Anleitung: Erweiterte Installation und Konfiguration eines Webservers auf Debian mit Git, Hugo und GitHub Actions für CI/CD

## Einführung
Diese erweiterte Anleitung baut auf der grundlegenden Version auf und vertieft die Nutzung von Hugo für die Erstellung statischer Webseiten. Sie integriert GitHub Actions für Continuous Integration/Continuous Deployment (CI/CD), um Änderungen automatisch zu bauen und bereitzustellen. Die Schwerpunkte sind **erweiterte Hugo-Konfiguration**, **Integration mit Git und Webserver** sowie **CI/CD mit GitHub Actions**, um einen automatisierten Workflow für Webentwicklung zu schaffen. Du lernst, detaillierte Hugo-Features anzuwenden, den Server zu konfigurieren und Deployments zu automatisieren.

Voraussetzungen:
- Ein Debian-basiertes System (z. B. Debian 12 oder Ubuntu 22.04).
- Ein Terminal (z. B. über `Ctrl + T` oder ein Terminal-Programm wie `bash`).
- Administratorrechte (`sudo`) für Installation und Konfiguration.
- Internetzugang für Paketinstallationen und GitHub.
- Ein GitHub-Konto und Repository.
- Grundlegendes Verständnis von Linux-Befehlen, Git und Hugo aus der Basisanleitung.
- Sichere Testumgebung (z. B. virtuelle Maschine), um Konfigurationen risikofrei zu testen.

## Grundlegende Befehle
Hier sind die wichtigsten Befehle und Tools, erweitert um detaillierte Hugo-Optionen und CI/CD:

1. **Erweiterte Hugo-Konfiguration**:
   - `hugo new site`: Erstellt eine neue Hugo-Site.
   - `hugo new`: Erstellt Inhalte, Archetypes oder Shortcodes.
   - `hugo server`: Startet einen lokalen Entwicklungsserver mit Live-Reloading.
   - `hugo --minify`: Baut die Site mit Minifizierung für Produktion.
   - `hugo config`: Zeigt die Site-Konfiguration.
   - Shortcodes: Benutzerdefinierte Vorlagen für wiederverwendbaren Inhalt.
2. **Integration mit Git und Webserver**:
   - `git submodule`: Verwalten von Themes als Submodule.
   - `rsync`: Synchronisiert generierte Dateien zum Server-Verzeichnis.
   - `nginx`: Webserver für statische Inhalte.
3. **CI/CD mit GitHub Actions**:
   - YAML-Dateien in `.github/workflows`: Definieren Workflows für Build und Deployment.
   - Actions wie `actions/checkout`, `actions/setup-go`: Installieren Abhängigkeiten.
   - Deployment zu GitHub Pages oder per SSH/rsync zu einem Server.
4. **Sonstige nützliche Befehle**:
   - `man <befehl>`: Zeigt die Hilfeseite eines Befehls an.
   - `sudo`: Führt Befehle mit Administratorrechten aus.
   - `curl`: Testet den Webserver.
   - `git push`: Pusht Änderungen, um CI/CD auszulösen.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Erweiterte Hugo-Konfiguration
**Ziel**: Lerne detaillierte Hugo-Setup-Schritte, einschließlich Themes, Archetypes, Shortcodes und Konfiguration.

1. **Schritt 1**: Installiere Hugo (falls nicht vorhanden) und erstelle eine neue Site:
   ```bash
   sudo snap install hugo --channel=extended
   hugo new site meineseite --format=toml
   cd meineseite
   ```
   Die Option `--format=toml` setzt die Konfigurationsdatei auf TOML (alternativ YAML oder JSON).

2. **Schritt 2**: Füge ein Theme als Git-Submodule hinzu und konfiguriere es:
   ```bash
   git init
   git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
   echo "theme = 'ananke'" >> hugo.toml
   ```
   Überprüfe die Konfiguration:
   ```bash
   hugo config
   ```

3. **Schritt 3**: Erstelle Archetypes für benutzerdefinierte Inhaltsvorlagen:
   ```bash
   hugo new archetypes/posts.md
   nano archetypes/posts.md
   ```
   Füge Vorlageninhalt hinzu (z. B. Frontmatter-Variablen):
   ```markdown
   ---
   title: "{{ replace .Name "-" " " | title }}"
   date: {{ .Date }}
   draft: true
   tags: []
   ---
   ```

4. **Schritt 4**: Erstelle Inhalt mit Archetypes und Shortcodes:
   ```bash
   hugo new posts/erster-post.md
   nano content/posts/erster-post.md
   ```
   Füge Inhalt hinzu, inklusive eines Shortcodes (z. B. für YouTube):
   ```markdown
   ---
   title: "Erster Post"
   date: 2025-09-03
   ---
   Hier ist ein Video: {{% youtube "video-id" %}}
   ```
   Erstelle einen benutzerdefinierten Shortcode:
   ```bash
   mkdir layouts/shortcodes
   nano layouts/shortcodes/alert.html
   ```
   Inhalt:
   ```html
   <div class="alert">{{ .Inner }}</div>
   ```

5. **Schritt 5**: Baue und teste die Site lokal mit erweiterten Optionen:
   ```bash
   hugo server -D --watch --verbose
   ```
   Öffne `http://localhost:1313` im Browser. Die Optionen: `-D` inkludiert Drafts, `--watch` für Live-Reloading, `--verbose` für detaillierte Logs.

6. **Schritt 6**: Baue die Produktionsversion:
   ```bash
   hugo --minify --environment production
   ```
   Überprüfe das `public`-Verzeichnis:
   ```bash
   ls public
   ```

**Reflexion**: Warum sind Archetypes nützlich? Schaue in `hugo help new` und überlege, wie Shortcodes die Inhaltswiederverwendung verbessern.

### Übung 2: Integration mit Git und Webserver (Erweitert)
**Ziel**: Vertiefe die Integration, inklusive Submodules und automatisierter Kopien.

1. **Schritt 1**: Committe und pushe die Hugo-Site zu GitHub:
   ```bash
   git add .
   git commit -m "Initiale Hugo-Site mit Theme"
   git remote add origin <deine-github-repo-url>
   git push -u origin main
   ```

2. **Schritt 2**: Konfiguriere Nginx für die Site (aus Basisanleitung erweitert):
   ```bash
   sudo nano /etc/nginx/sites-available/default
   ```
   Füge Caching für statische Assets hinzu:
   ```
   server {
       listen 80;
       root /var/www/meineseite/html;
       index index.html;
       location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
           expires 30d;
       }
   }
   ```
   Teste und reload:
   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   ```

3. **Schritt 3**: Deploye manuell mit rsync, inklusive Löschung alter Dateien:
   ```bash
   rsync -av --delete public/ /var/www/meineseite/html/
   ```

**Reflexion**: Wie handhabt `git submodule` Themes? Schaue in `man git-submodule` und überlege Sicherheitsaspekte für den Webserver.

### Übung 3: CI/CD mit GitHub Actions
**Ziel**: Integriere GitHub Actions für automatisches Bauen und Deployen der Hugo-Site.

1. **Schritt 1**: Erstelle ein GitHub-Repository (falls nicht vorhanden) und pushe deine lokale Site.

2. **Schritt 2**: Konfiguriere GitHub Pages in den Repository-Einstellungen: Setze Source auf "GitHub Actions".

3. **Schritt 3**: Erstelle den Workflow-Datei auf GitHub oder lokal:
   ```bash
   mkdir -p .github/workflows
   nano .github/workflows/hugo-deploy.yaml
   ```
   Füge eine erweiterte YAML-Konfiguration ein (basierend auf Best Practices und Docs):
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
   Committe und pushe die Datei.

4. **Schritt 4**: Teste den Workflow: Mache eine Änderung, pushe und überprüfe unter "Actions" auf GitHub.

5. **Schritt 5**: Für Deployment zu deinem Debian-Server (anstatt GitHub Pages): Erweitere den Workflow mit SSH-Deployment. Generiere SSH-Schlüssel, füge den öffentlichen Schlüssel zu `~/.ssh/authorized_keys` auf dem Server hinzu und speichere den privaten als GitHub Secret (`DEPLOY_KEY`).
   Ersetze den Deploy-Job durch:
   ```yaml
   deploy:
     runs-on: ubuntu-latest
     needs: build
     steps:
       - name: Download Artifact
         uses: actions/download-artifact@v4
         with:
           name: pages-artifact
           path: ./public
       - name: Deploy to Server
         uses: appleboy/scp-action@v0.1.7
         with:
           host: ${{ secrets.SERVER_HOST }}
           username: ${{ secrets.SERVER_USER }}
           key: ${{ secrets.DEPLOY_KEY }}
           source: ./public/*
           target: /var/www/meineseite/html/
           strip_components: 1
   ```

6. **Schritt 6**: Überprüfe das Deployment: Pushe eine Änderung und prüfe den Server.

**Reflexion**: Warum ist Caching in Actions wichtig? Schaue in die GitHub Docs und überlege, wie du Tests in den Workflow integrierst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Experimentiere mit Hugo-Modulen und Shortcodes.
- **Best Practices**: Verwende Submodules für Themes, cache Abhängigkeiten in Actions, und minifiziere für Performance.
- **Fehlerbehebung**: Überwache Action-Logs auf GitHub; nutze `hugo --debug` für Hugo-Fehler.
- **Sicherheit**: Verwende Secrets für SSH-Schlüssel; aktiviere HTTPS auf Nginx.
- **Erweiterungen**: Integriere Hugo-Module statt Themes, oder AWS/Netlify für alternatives Hosting.

## Fazit
Diese erweiterte Anleitung hat Hugo detailliert behandelt und GitHub Actions für CI/CD integriert. Experimentiere mit komplexen Workflows und Features wie Hugo-Pipes für Asset-Verarbeitung.
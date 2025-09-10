# Praxisorientierte Anleitung: Erweiterte Installation und Konfiguration eines Webservers auf Windows mit Git, Hugo und GitHub Actions für CI/CD

## Einführung
Diese erweiterte Anleitung baut auf der grundlegenden Version auf und vertieft die Nutzung von Hugo für die Erstellung statischer Webseiten. Sie integriert GitHub Actions für Continuous Integration/Continuous Deployment (CI/CD), um Änderungen automatisch zu bauen und bereitzustellen. Die Schwerpunkte sind **erweiterte Hugo-Konfiguration**, **Integration mit Git und Webserver** sowie **CI/CD mit GitHub Actions**, um einen automatisierten Workflow für Webentwicklung zu schaffen. Du lernst, detaillierte Hugo-Features anzuwenden, den Server zu konfigurieren und Deployments zu automatisieren.
Wo nötig, wird WSL für Linux-spezifische Tools wie `nginx` oder `rsync` verwendet.

## Voraussetzungen
- Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Optional: WSL2 mit einer Linux-Distribution (z. B. Ubuntu) für Linux-Tools wie `nginx` oder `rsync`.
  - Installiere WSL: `wsl --install`.
  - Installiere Ubuntu: `wsl --install -d Ubuntu`.
- Chocolatey für einfache Installation von Tools: `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`.
- GitHub-Konto und ein Repository.
- Git für Windows: `choco install git`.
- Grundlegendes Verständnis von Hugo, Git und PowerShell.
- Sichere Testumgebung (z. B. `$HOME\test_webserver` oder eine VM).
- Optional: Administratorrechte für bestimmte Aktionen (z. B. Webserver-Installation).

## Grundlegende Befehle
Die folgenden Befehle und Tools sind die Windows-Äquivalente der Linux-Befehle, angepasst an die Schwerpunkte:

1. **Erweiterte Hugo-Konfiguration**:
   - `hugo new site`: Erstellt eine neue Hugo-Site.
   - `hugo new`: Erstellt Inhalte, Archetypes oder Shortcodes.
   - `hugo server`: Startet einen lokalen Entwicklungsserver mit Live-Reloading.
   - `hugo --minify`: Baut die Site mit Minifizierung für Produktion.
   - `hugo config`: Zeigt die Site-Konfiguration.
   - Shortcodes: Benutzerdefinierte Vorlagen für wiederverwendbaren Inhalt.
2. **Integration mit Git und Webserver**:
   - `git submodule`: Verwalten von Themes als Submodule.
   - `robocopy` (ähnlich `rsync`): Synchronisiert Dateien zum Server-Verzeichnis.
   - IIS (Internet Information Services) oder `nginx` (via WSL): Webserver für statische Inhalte.
3. **CI/CD mit GitHub Actions**:
   - YAML-Dateien in `.github/workflows`: Definieren Workflows für Build und Deployment.
   - Actions wie `actions/checkout`, `actions/setup-go`: Installieren Abhängigkeiten.
   - Deployment zu GitHub Pages oder per SSH/`robocopy` zu einem Windows-Server.
4. **Sonstige nützliche Befehle**:
   - `Get-Help <cmdlet>`: Zeigt die Hilfeseite eines PowerShell-Cmdlets.
   - `Start-Process -Verb RunAs`: Führt Befehle mit Administratorrechten aus.
   - `curl`: Testet den Webserver (vorinstalliert oder via `choco install curl`).
   - `git push`: Pusht Änderungen, um CI/CD auszulösen.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Erweiterte Hugo-Konfiguration
**Ziel**: Lerne detaillierte Hugo-Setup-Schritte, einschließlich Themes, Archetypes, Shortcodes und Konfiguration.

1. **Schritt 1**: Installiere Hugo und erstelle eine neue Site:
   ```powershell
   choco install hugo-extended
   hugo new site meineseite --format=toml
   Set-Location meineseite
   ```
   Die Option `--format=toml` setzt die Konfigurationsdatei auf TOML.

2. **Schritt 2**: Füge ein Theme als Git-Submodule hinzu und konfiguriere es:
   ```powershell
   git init
   git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
   Add-Content -Path hugo.toml -Value "theme = 'ananke'"
   ```
   Überprüfe die Konfiguration:
   ```powershell
   hugo config
   ```

3. **Schritt 3**: Erstelle Archetypes für benutzerdefinierte Inhaltsvorlagen:
   ```powershell
   hugo new archetypes/posts.md
   notepad archetypes/posts.md
   ```
   Füge Vorlageninhalt hinzu:
   ```markdown
   ---
   title: "{{ replace .Name "-" " " | title }}"
   date: {{ .Date }}
   draft: true
   tags: []
   ---
   ```

4. **Schritt 4**: Erstelle Inhalt mit Archetypes und Shortcodes:
   ```powershell
   hugo new posts/erster-post.md
   notepad content/posts/erster-post.md
   ```
   Füge Inhalt hinzu, inklusive eines Shortcodes:
   ```markdown
   ---
   title: "Erster Post"
   date: 2025-09-03
   ---
   Hier ist ein Video: {{% youtube "video-id" %}}
   ```
   Erstelle einen benutzerdefinierten Shortcode:
   ```powershell
   New-Item -ItemType Directory -Path layouts/shortcodes
   @"
   <div class="alert">{{ .Inner }}</div>
   "@ | Out-File layouts/shortcodes/alert.html
   ```

5. **Schritt 5**: Baue und teste die Site lokal mit erweiterten Optionen:
   ```powershell
   hugo server -D --watch --verbose
   ```
   Öffne `http://localhost:1313` im Browser. Die Optionen: `-D` inkludiert Drafts, `--watch` für Live-Reloading, `--verbose` für detaillierte Logs.

6. **Schritt 6**: Baue die Produktionsversion:
   ```powershell
   hugo --minify --environment production
   Get-ChildItem public
   ```

**Reflexion**: Warum sind Archetypes nützlich? Schaue in `hugo help new` (in PowerShell oder WSL) und überlege, wie Shortcodes die Inhaltswiederverwendung verbessern.

### Übung 2: Integration mit Git und Webserver (Erweitert)
**Ziel**: Vertiefe die Integration, inklusive Submodules und automatisierter Kopien.

1. **Schritt 1**: Committe und pushe die Hugo-Site zu GitHub:
   ```powershell
   git add .
   git commit -m "Initiale Hugo-Site mit Theme"
   git remote add origin <deine-github-repo-url>
   git push -u origin main
   ```

2. **Schritt 2**: Konfiguriere einen Webserver.
   - **Option 1: IIS (nativ unter Windows)**:
     - Aktiviere IIS: `Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole`.
     - Kopiere die Site in das IIS-Verzeichnis:
       ```powershell
       robocopy public C:\inetpub\wwwroot\meineseite /MIR
       ```
     - Öffne `http://localhost/meineseite` im Browser.
   - **Option 2: Nginx (via WSL)**:
     - Installiere Nginx in WSL:
       ```powershell
       wsl -- sudo apt update && sudo apt install nginx
       ```
     - Konfiguriere Nginx:
       ```powershell
       wsl -- sudo nano /etc/nginx/sites-available/default
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
     - Teste und starte Nginx:
       ```powershell
       wsl -- sudo nginx -t
       wsl -- sudo systemctl reload nginx
       ```

3. **Schritt 3**: Deploye manuell mit `robocopy` (ähnlich `rsync`):
   ```powershell
   robocopy public C:\inetpub\wwwroot\meineseite /MIR
   ```
   Oder in WSL mit `rsync`:
   ```powershell
   wsl -- rsync -av --delete public/ /var/www/meineseite/html/
   ```

**Reflexion**: Wie unterscheidet sich `robocopy` von `rsync`? Schaue in `robocopy /?` und überlege Sicherheitsaspekte für den Webserver.

### Übung 3: CI/CD mit GitHub Actions
**Ziel**: Integriere GitHub Actions für automatisches Bauen und Deployen der Hugo-Site.

1. **Schritt 1**: Erstelle ein GitHub-Repository (falls nicht vorhanden) und pushe deine lokale Site.

2. **Schritt 2**: Konfiguriere GitHub Pages in den Repository-Einstellungen: Setze Source auf "GitHub Actions".

3. **Schritt 3**: Erstelle die Workflow-Datei:
   ```powershell
   New-Item -ItemType Directory -Path .github/workflows
   @"
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
   "@ | Out-File .github/workflows/hugo-deploy.yaml
   ```

4. **Schritt 4**: Committe und pushe die Workflow-Datei:
   ```powershell
   git add .github/workflows/hugo-deploy.yaml
   git commit -m "GitHub Actions Workflow hinzugefügt"
   git push
   ```

5. **Schritt 5**: Für Deployment zu einem Windows-Server (anstatt GitHub Pages):
   - Generiere SSH-Schlüssel: `ssh-keygen -t rsa -b 4096 -f $HOME\.ssh\deploy_key`.
   - Füge den öffentlichen Schlüssel (`deploy_key.pub`) zu `~/.ssh/authorized_keys` auf dem Zielserver hinzu (z. B. via WSL oder einem Remote-Server).
   - Speichere den privaten Schlüssel als GitHub Secret (`DEPLOY_KEY`).
   - Ersetze den Deploy-Job in `hugo-deploy.yaml`:
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

6. **Schritt 6**: Überprüfe das Deployment: Pushe eine Änderung und prüfe die GitHub Actions-Logs oder den Server (z. B. `http://<server-ip>/meineseite`).

**Reflexion**: Warum ist Caching in Actions wichtig? Schaue in die GitHub Actions-Dokumentation und überlege, wie du Tests (z. B. HTML-Validierung) in den Workflow integrieren kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Experimentiere mit Hugo-Modulen, Shortcodes und Pipelines.
- **Best Practices**: Nutze Submodules für Themes, cache Abhängigkeiten in Actions, minifiziere für Performance.
- **Fehlerbehebung**: Überwache GitHub Actions-Logs; nutze `hugo --debug` für Hugo-Fehler.
- **Sicherheit**: Verwende Secrets für SSH-Schlüssel; aktiviere HTTPS in IIS (`Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect`) oder Nginx.
- **Erweiterungen**: Erkunde Hugo-Module (`hugo mod init`) oder alternative Hosting-Optionen wie Netlify.
- **WSL für Linux-Tools**: Nutze WSL für `nginx` oder `rsync`, wenn IIS nicht ausreicht.

## Fazit
Die beschriebene Anleitung ist unter Windows umsetzbar, entweder nativ mit PowerShell, IIS und `robocopy` oder via WSL für Linux-Tools wie `nginx` und `rsync`. Du hast gelernt, Hugo detailliert zu konfigurieren, einen Webserver einzurichten und CI/CD mit GitHub Actions zu automatisieren. Wiederhole die Übungen und experimentiere mit Hugo-Pipes oder Netlify-Integration, um deine Fähigkeiten zu vertiefen. Wenn du ein spezifisches Thema (z. B. Nginx in WSL oder komplexe Hugo-Workflows) vertiefen möchtest, lass es mich wissen! 😄

</xaiArtifact>
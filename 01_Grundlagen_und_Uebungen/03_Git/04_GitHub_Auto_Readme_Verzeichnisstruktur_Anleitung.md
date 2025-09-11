# Praxisorientierte Anleitung: Automatische Verzeichnisstruktur in README.md

## Einführung
Eine Verzeichnisstruktur in der `README.md` eines GitHub-Repositorys bietet einen schnellen Überblick über die Organisation des Projekts. Diese Anleitung konzentriert sich auf die Schwerpunkte **Erstellung eines Skripts zur Generierung der Verzeichnisstruktur**, **Integration in ein GitHub-Repository** und **Automatisierung mit GitHub Actions**, um die Struktur dynamisch zu aktualisieren. Eine **Spielerei** zeigt, wie ein Python-Skript die Verzeichnisstruktur generiert und in die `README.md` einfügt, wobei bestimmte Ordner (z. B. `.git`) ausgeschlossen werden. Durch praktische Übungen lernst du, ein Skript zu erstellen, es in ein Repository zu integrieren und die Aktualisierung zu automatisieren.

**Voraussetzungen**:
- Ein System mit Windows, macOS oder Linux (z. B. Windows 11, Ubuntu 22.04, macOS Ventura).
- Ein Terminal (PowerShell für Windows, Terminal für macOS/Linux).
- Python 3 installiert (prüfe mit `python3 --version` oder `python --version`; installiere via `choco install python` auf Windows, `sudo apt install python3` auf Ubuntu oder `brew install python3` auf macOS).
- Git installiert (prüfe mit `git --version`; installiere via `choco install git`, `sudo apt install git` oder `brew install git`).
- Ein GitHub-Konto mit einem bestehenden Repository.
- Grundkenntnisse in Python, Git und GitHub.
- Sichere Testumgebung (z. B. `$HOME/readme_tree_test` oder `~/readme_tree_test`).

## Grundlegende Befehle
Hier sind die wichtigsten Befehle und Konzepte, aufgeteilt nach den Hauptthemen:

1. **Erstellung eines Skripts zur Generierung der Verzeichnisstruktur**:
   - `python3 <script>.py`: Führt ein Python-Skript aus, das die Verzeichnisstruktur generiert.
   - `os.walk`: Listet Dateien und Ordner in einem Verzeichnisbaum (Python-Modul `os`).
   - `pathlib`: Vereinfacht die Arbeit mit Dateipfaden in Python.
2. **Integration in ein GitHub-Repository**:
   - `git add`: Fügt das Skript und die aktualisierte `README.md` zum Repository hinzu.
   - `git commit`: Speichert Änderungen im Repository.
   - `git push`: Lädt Änderungen zu GitHub hoch.
3. **Automatisierung mit GitHub Actions**:
   - `.github/workflows/*.yml`: Definiert Workflows für automatische Ausführung des Skripts.
   - `actions/checkout`: Klont das Repository in der Pipeline.
   - `actions/setup-python`: Richtet eine Python-Umgebung ein.
4. **Nützliche Zusatzbefehle**:
   - `git status`: Zeigt den Status des Arbeitsverzeichnisses.
   - `git diff`: Zeigt Änderungen in der `README.md`.
   - `cat README.md`: Zeigt den Inhalt der `README.md` an.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Erstellung eines Skripts zur Generierung der Verzeichnisstruktur
**Ziel**: Erstelle ein Python-Skript, das die Verzeichnisstruktur generiert und in die `README.md` einfügt.

1. **Schritt 1**: Erstelle ein neues Projektverzeichnis und initialisiere ein Git-Repository:
   ```bash
   mkdir readme_tree_test
   cd readme_tree_test
   git init
   echo "# Mein Projekt" > README.md
   git add README.md
   git commit -m "Initialer Commit: README hinzugefügt"
   ```

2. **Schritt 2**: Erstelle ein Python-Skript zur Generierung der Verzeichnisstruktur:
   ```bash
   nano generate_tree.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   import os
   from pathlib import Path

   def generate_tree(directory='.', ignore=['.git', '__pycache__', 'venv']):
       """Generiert eine Verzeichnisstruktur und gibt sie als String zurück."""
       tree = ['## Verzeichnisstruktur\n```tree']
       for root, dirs, files in os.walk(directory):
           # Ignoriere bestimmte Ordner
           dirs[:] = [d for d in dirs if d not in ignore]
           level = root.replace(directory, '').count(os.sep)
           indent = '  ' * level
           tree.append(f'{indent}{os.path.basename(root)}/')
           for file in sorted(files):
               tree.append(f'{indent}  {file}')
       tree.append('```')
       return '\n'.join(tree)

   def update_readme():
       """Aktualisiert die README.md mit der Verzeichnisstruktur."""
       readme_path = Path('README.md')
       current_readme = readme_path.read_text() if readme_path.exists() else '# Mein Projekt\n'
       tree = generate_tree()
       # Teile die README.md in zwei Teile: vor und nach der Verzeichnisstruktur
       parts = current_readme.split('## Verzeichnisstruktur')
       if len(parts) > 1:
           new_readme = parts[0].rstrip() + '\n\n' + tree
       else:
           new_readme = current_readme.rstrip() + '\n\n' + tree
       readme_path.write_text(new_readme)

   if __name__ == '__main__':
       update_readme()
   ```
   Speichere und schließe.

3. **Schritt 3**: Erstelle einige Testdateien und -ordner:
   ```bash
   mkdir src docs
   echo "print('Hallo')" > src/main.py
   echo "Dokumentation" > docs/guide.md
   ```

4. **Schritt 4**: Führe das Skript aus, um die Verzeichnisstruktur zu generieren:
   ```bash
   python3 generate_tree.py
   cat README.md
   ```
   Die `README.md` sollte nun eine Struktur wie diese enthalten:
   ```
   # Mein Projekt

   ## Verzeichnisstruktur
   ```tree
   ./
     docs/
       guide.md
     src/
       main.py
     generate_tree.py
     README.md
   ```
   ```

**Reflexion**: Warum ist es wichtig, bestimmte Ordner wie `.git` auszuschließen? Nutze `man python3` und überlege, wie du das Skript für andere Dateitypen anpassen kannst.

### Übung 2: Integration in ein GitHub-Repository
**Ziel**: Integriere das Skript in ein GitHub-Repository und aktualisiere die `README.md` manuell.

1. **Schritt 1**: Erstelle ein GitHub-Repository (ohne README, .gitignore oder Lizenz) und verbinde es:
   ```bash
   echo -e "*.pyc\n__pycache__/\nvenv/" > .gitignore
   git add .
   git commit -m "Skript und Testdateien hinzugefügt"
   git remote add origin https://github.com/dein-benutzername/readme_tree_test.git
   git push -u origin main
   ```
   Ersetze `dein-benutzername` durch deinen GitHub-Benutzernamen.

2. **Schritt 2**: Erstelle einen neuen Branch für eine Änderung:
   ```bash
   git checkout -b add-file
   echo "Neue Datei" > docs/new.md
   python3 generate_tree.py
   ```

3. **Schritt 3**: Überprüfe die Änderungen in der `README.md`:
   ```bash
   git diff README.md
   ```
   Die `README.md` sollte nun `docs/new.md` in der Verzeichnisstruktur enthalten.

4. **Schritt 4**: Committe und pushe den Branch:
   ```bash
   git add .
   git commit -m "Neue Datei und aktualisierte Verzeichnisstruktur"
   git push origin add-file
   ```

5. **Schritt 5**: Erstelle einen Pull Request auf GitHub:
   - Öffne dein Repository auf GitHub.
   - Wähle den `add-file`-Branch und erstelle einen Pull Request.
   - Merge den Pull Request in den `main`-Branch.

**Reflexion**: Wie hilft die Versionskontrolle bei der Verwaltung der `README.md`? Nutze `git help diff` und überlege, wie du Änderungen in der Struktur validieren kannst.

### Übung 3: Automatisierung mit GitHub Actions und Spielerei
**Ziel**: Automatisiere die Aktualisierung der Verzeichnisstruktur mit GitHub Actions und füge eine Spielerei hinzu, bei der nur bestimmte Dateitypen (z. B. `.md`) angezeigt werden.

1. **Schritt 1**: Erstelle eine GitHub Actions-Workflow-Datei:
   ```bash
   mkdir -p .github/workflows
   nano .github/workflows/update-readme.yml
   ```
   Füge folgenden Inhalt ein:
   ```yaml
   name: Update README with Directory Tree
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   jobs:
     update-readme:
       runs-on: ubuntu-latest
       steps:
         - name: Checkout
           uses: actions/checkout@v5
         - name: Setup Python
           uses: actions/setup-python@v5
           with:
             python-version: '3.x'
         - name: Run Tree Generation Script
           run: python3 generate_tree.py
         - name: Commit and Push Changes
           run: |
             git config --global user.name "GitHub Actions"
             git config --global user.email "actions@github.com"
             git add README.md
             git commit -m "Update README with directory tree" || echo "No changes to commit"
             git push
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```
   Speichere und schließe.

2. **Schritt 2**: Committe und pushe den Workflow:
   ```bash
   git add .github/workflows/update-readme.yml
   git commit -m "GitHub Actions Workflow für README-Aktualisierung hinzugefügt"
   git push
   ```

3. **Spielerei**: Erweitere das Skript, um nur `.md`-Dateien in der Verzeichnisstruktur anzuzeigen:
   ```bash
   nano generate_tree.py
   ```
   Ersetze den Inhalt durch:
   ```python
   import os
   from pathlib import Path

   def generate_tree(directory='.', ignore=['.git', '__pycache__', 'venv'], file_extension='.md'):
       """Generiert eine Verzeichnisstruktur mit bestimmten Dateitypen und gibt sie als String zurück."""
       tree = ['## Verzeichnisstruktur\n```tree']
       for root, dirs, files in os.walk(directory):
           # Ignoriere bestimmte Ordner
           dirs[:] = [d for d in dirs if d not in ignore]
           level = root.replace(directory, '').count(os.sep)
           indent = '  ' * level
           tree.append(f'{indent}{os.path.basename(root)}/')
           # Filtere Dateien nach Endung
           for file in sorted(f for f in files if f.endswith(file_extension)):
               tree.append(f'{indent}  {file}')
       tree.append('```')
       return '\n'.join(tree)

   def update_readme():
       """Aktualisiert die README.md mit der Verzeichnisstruktur."""
       readme_path = Path('README.md')
       current_readme = readme_path.read_text() if readme_path.exists() else '# Mein Projekt\n'
       tree = generate_tree()
       # Teile die README.md in zwei Teile: vor und nach der Verzeichnisstruktur
       parts = current_readme.split('## Verzeichnisstruktur')
       if len(parts) > 1:
           new_readme = parts[0].rstrip() + '\n\n' + tree
       else:
           new_readme = current_readme.rstrip() + '\n\n' + tree
       readme_path.write_text(new_readme)

   if __name__ == '__main__':
       update_readme()
   ```
   Speichere und schließe.

4. **Schritt 3**: Teste das Skript lokal:
   ```bash
   python3 generate_tree.py
   cat README.md
   ```
   Die `README.md` sollte nun nur `.md`-Dateien anzeigen, z. B.:
   ```
   # Mein Projekt

   ## Verzeichnisstruktur
   ```tree
   ./
     docs/
       guide.md
       new.md
     README.md
   ```
   ```

5. **Schritt 4**: Committe und pushe die Änderungen:
   ```bash
   git add generate_tree.py README.md
   git commit -m "Spielerei: Nur .md-Dateien in Verzeichnisstruktur anzeigen"
   git push
   ```

6. **Schritt 5**: Überprüfe den Workflow unter „Actions“ auf GitHub. Bei jedem Push wird die `README.md` automatisch aktualisiert.

**Reflexion**: Wie verbessert die Automatisierung die Wartung der `README.md`? Nutze die GitHub Actions-Dokumentation und überlege, wie du andere Dateitypen (z. B. `.py`) filtern kannst.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um Python-Skripte und GitHub-Workflows zu verinnerlichen.
- **Sicheres Testen**: Nutze ein Test-Repository, um Fehler zu vermeiden.
- **Fehler verstehen**: Lies GitHub Actions-Logs oder Python-Fehlermeldungen genau und nutze `git help` oder die GitHub-Dokumentation (https://docs.github.com).
- **Effiziente Workflows**: Verwende klare Commit-Nachrichten und teste Skripte lokal, bevor du sie automatisierst.
- **Git konfigurieren**: Stelle sicher, dass deine Einstellungen korrekt sind:
  ```bash
  git config --global user.name "Dein Name"
  git config --global user.email "deine.email@example.com"
  ```
- **Kombiniere Tools**: Nutze Python für dynamische Skripte, VS Code für Bearbeitung (`code .`) und GitHub Actions für Automatisierung.

## Fazit
Mit diesen Übungen hast du gelernt, wie du die Verzeichnisstruktur eines Repositorys automatisch in die `README.md` einfügst, sowohl manuell mit einem Python-Skript als auch automatisiert mit GitHub Actions. Die Spielerei zeigt, wie du die Ausgabe auf bestimmte Dateitypen beschränken kannst. Vertiefe dein Wissen, indem du erweiterte Funktionen wie rekursive Ausschlüsse, Baumformatierungen oder Integration mit anderen Tools (z. B. `tree`-CLI) ausprobierst. Wenn du ein spezifisches Thema (z. B. erweiterte Formatierung oder komplexe Actions) vertiefen möchtest, lass es mich wissen!

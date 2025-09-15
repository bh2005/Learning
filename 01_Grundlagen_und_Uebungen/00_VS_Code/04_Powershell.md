## Intro

Während die VS Code GUI eine fantastische Einführung in Git bietet, bevorzugen viele Profis die Geschwindigkeit und Kontrolle der Kommandozeile. Das integrierte Terminal mit PowerShell ist dafür das perfekte Werkzeug.

---

### Grundlagen: Git in der Powershell

Die grundlegenden Git-Befehle sind in jeder Kommandozeile gleich, sei es in Bash, Zsh oder PowerShell. Der Vorteil in VS Code liegt darin, dass du nahtlos zwischen deinem Code und dem Terminal wechseln kannst.

Bevor du startest, stelle sicher, dass Git auf deinem System installiert ist. Die VS Code-Integration nutzt die lokale Git-Installation im Hintergrund.

| Befehl | Erklärung |
| :--- | :--- |
| `git status` | Zeigt dir den aktuellen Status deines Projekts an: Welche Dateien wurden geändert, welche sind neu und welche sind vorgemerkt. |
| `git add <dateiname>` | Fügt eine bestimmte Datei zum Staging-Bereich hinzu. |
| `git add .` | Fügt alle geänderten und neuen Dateien zum Staging-Bereich hinzu. |
| `git commit -m "<Nachricht>"` | Erstellt einen neuen Commit mit der angegebenen Nachricht. |
| `git push` | Lädt deine Commits in das verbundene Remote-Repository hoch. |
| `git pull` | Lädt neue Commits von deinem Remote-Repository herunter. |

---

### Übungen zum Verinnerlichen

### Übung 1: Den Status abrufen und Dateien hinzufügen 🔎
**Ziel**: Deinen Projektstatus direkt im Terminal überprüfen.

1.  **Schritt 1**: Öffne dein Projekt in VS Code.
2.  **Schritt 2**: Öffne das integrierte Terminal mit **`Strg` + `Ö`** (`Ctrl` + `` ` ``).
3.  **Schritt 3**: Tippe **`git status`** und drücke Enter. Du siehst eine detaillierte Liste deiner geänderten Dateien.
4.  **Schritt 4**: Erstelle oder bearbeite eine Datei. Führe dann **`git status`** erneut aus.
5.  **Schritt 5**: Füge die Änderungen zum Staging-Bereich hinzu, indem du **`git add .`** eingibst.
6.  **Schritt 6**: Überprüfe den Status erneut mit **`git status`**. Die Dateien sollten jetzt grün erscheinen.

**Reflexion**: Wie unterscheidet sich die visuelle Rückmeldung der GUI von der Textausgabe von `git status`? Welche ist für dich intuitiver?

---

### Übung 2: Committen und Pushen ⏫
**Ziel**: Einen Commit direkt in der Kommandozeile erstellen und hochladen.

1.  **Schritt 1**: Stelle sicher, dass du Dateien mit **`git add .`** vorgemerkt hast.
2.  **Schritt 2**: Erstelle einen Commit mit einer Nachricht: **`git commit -m "Füge neue Dateien hinzu"`**.
3.  **Schritt 3**: Lade deine lokalen Commits in dein Remote-Repository hoch: **`git push`**.
4.  **Schritt 4**: Simuliere eine Änderung von woanders. Führe dann **`git pull`** aus, um diese Änderungen herunterzuladen und in dein lokales Repository zu übernehmen.

**Reflexion**: Warum bevorzugen erfahrene Nutzer oft die Kommandozeile, obwohl VS Code die gleichen Aktionen mit der GUI ermöglicht?

---

### Fazit
Die Kommandozeile in VS Code ist der nächste logische Schritt für jeden, der die Git-Grundlagen beherrscht. Sie bietet dir die volle Kontrolle, Geschwindigkeit und Flexibilität, die für fortgeschrittene Git-Workflows unerlässlich sind. Sobald du dich mit den Kernbefehlen vertraut gemacht hast, wird die Kommandozeile dein wichtigstes Werkzeug für die Versionskontrolle.

**Nächste Schritte**:
- **Aliases**: Lerne, wie du in PowerShell Aliase erstellst (z.B. `git config alias.co checkout`), um Befehle zu verkürzen.
- **Branches**: Erstelle und wechsle zwischen Branches direkt im Terminal mit `git branch` und `git checkout`.
- **Git-Log**: Nutze `git log`, um die komplette Commit-Historie deines Projekts zu sehen.
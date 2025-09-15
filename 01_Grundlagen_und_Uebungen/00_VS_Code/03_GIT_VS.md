## Intro

Die **Git-Integration** in VS Code ist eines seiner mächtigsten und beliebtesten Features. Sie macht die Versionskontrolle so einfach, dass du sie nahtlos in deinen täglichen Workflow integrieren kannst, ohne jemals die Kommandozeile verlassen zu müssen. Git zu beherrschen ist eine der wichtigsten Fähigkeiten für jeden Entwickler.

---

### Grundlagen: Git in VS Code verstehen

VS Code hat eine integrierte Benutzeroberfläche für Git, die die komplexesten Befehle in einfache Schaltflächen umwandelt. Das Herzstück der Integration ist die **Quellcodeverwaltung (Source Control View)**.

* **Drei Dateistatus**: Git unterscheidet hauptsächlich drei Zustände für deine Dateien:
    1.  **Unverfolgt (Untracked)**: Neue Dateien, die Git noch nicht kennt.
    2.  **Geändert (Modified)**: Bekannte Dateien, die du bearbeitet hast.
    3.  **Vorgemerkt (Staged)**: Geänderte Dateien, die für den nächsten **Commit** bereitstehen.

* **Die Statusleiste**: Am unteren Rand deines Editors findest du Informationen über deinen aktuellen Git-Status, wie den Namen deines aktuellen **Branches** und den Status deiner Remote-Verbindung.

---

### Übungen zum Verinnerlichen

### Übung 1: Git-Repository initialisieren 🚀
**Ziel**: Deinen Projektordner in ein Git-Repository verwandeln.

1.  **Schritt 1**: Öffne deinen Ordner "MeinErstesProjekt" in VS Code.
2.  **Schritt 2**: Klicke in der Aktivitätsleiste auf das Icon für die **Quellcodeverwaltung** (sieht aus wie ein Baum). VS Code erkennt, dass der Ordner noch kein Repository ist.
3.  **Schritt 3**: Klicke auf die Schaltfläche "**Repository initialisieren**". VS Code initialisiert ein Git-Repository im Hintergrund und verfolgt nun die Dateien in deinem Projekt.

**Reflexion**: Was passiert mit deinen Dateien in der Quellcodeansicht, nachdem du das Repository initialisiert hast?

---

### Übung 2: Änderungen verfolgen und committen ✅
**Ziel**: Deine Änderungen speichern und mit einer aussagekräftigen Nachricht versehen.

1.  **Schritt 1**: Öffne deine Datei `hello.py` und füge eine neue Zeile hinzu, z. B.: `print("Meine erste Änderung!")`.
2.  **Schritt 2**: Klicke auf das Quellcodeverwaltungs-Icon. Du siehst, dass deine Datei jetzt unter **"Änderungen"** aufgelistet ist. Das bedeutet, dass Git die Änderung erkannt hat.
3.  **Schritt 3**: Bewege den Mauszeiger über den Dateinamen und klicke auf das **`+`**-Zeichen. Dies **merkt die Änderungen vor (staging)**. Die Datei wandert in den Bereich **"Vorgemerkte Änderungen"**.
4.  **Schritt 4**: Gib oben in das Textfeld eine aussagekräftige Nachricht ein, z. B. `"Füge eine erste Ausgabe hinzu"`. Eine gute Commit-Nachricht beschreibt kurz, was du geändert hast.
5.  **Schritt 5**: Klicke auf den **`✓`**-Button, um den Commit zu bestätigen.

**Reflexion**: Warum ist es sinnvoll, nur kleine, logische Änderungen in einem Commit zu bündeln?

---

### Übung 3: Mit einem Remote-Repository (GitHub) arbeiten ☁️
**Ziel**: Deinen lokalen Code online sichern und teilen.

1.  **Schritt 1**: Klicke in der Quellcodeansicht auf das `...`-Menü und wähle **"Push zu..."** oder **"In GitHub veröffentlichen"**. VS Code wird dich durch den Prozess führen, ein neues Repository auf GitHub zu erstellen und deinen Code dorthin zu pushen.
2.  **Schritt 2**: Sobald das Remote-Repository verbunden ist, kannst du mit den Pfeilen in der Statusleiste deine Änderungen hochladen (**Push**) oder die Änderungen von anderen Entwicklern herunterladen (**Pull**).

**Reflexion**: Wie unterscheidet sich ein `Push` von einem `Pull`, und warum sind beide für die Zusammenarbeit unerlässlich?

---

### Fazit
Mit der integrierten Git-Funktionalität von VS Code hast du die grundlegenden Konzepte der Versionskontrolle gemeistert. Du kannst jetzt Code sicher speichern, Änderungen nachverfolgen und mit anderen zusammenarbeiten, alles aus einer einzigen, vertrauten Umgebung heraus.

**Nächste Schritte**:
- **Branches**: Lerne, wie du neue Entwicklungszweige (Branches) erstellst und zusammenführst.
- **Merge-Konflikte**: Verstehe, wie man Konflikte löst, wenn zwei Entwickler dieselbe Datei bearbeiten.
- **GitLens-Erweiterung**: Installiere die beliebte **GitLens**-Erweiterung, um die Git-Geschichte deiner Dateien direkt im Editor zu sehen.
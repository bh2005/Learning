## Intro

Genau wie Google Cloud hat auch Amazon Web Services eine offizielle, leistungsstarke Erweiterung für VS Code: das **AWS Toolkit**. Es ist das zentrale Werkzeug, um die AWS-Cloud direkt aus deiner Entwicklungsumgebung zu steuern.

---

## Grundlagen: Das AWS Toolkit für VS Code ☁️

Das **AWS Toolkit** ist eine kostenlose Erweiterung, die VS Code mit den wichtigsten AWS-Diensten verbindet. Es bietet eine visuelle Schnittstelle, um deine Cloud-Ressourcen zu verwalten, serverseitige Anwendungen (wie AWS Lambda) zu erstellen, zu testen und bereitzustellen, ohne das Terminal oder die AWS-Konsole aufrufen zu müssen.

* **Vorteile**: Reduziert den Kontextwechsel, vereinfacht die Verwaltung deiner Cloud-Ressourcen und bietet einen optimierten Workflow für die serverless Entwicklung.
* **Voraussetzung**: Du benötigst ein AWS-Konto und die AWS CLI, die lokal auf deinem System installiert und konfiguriert ist.

---

### Übungen zum Verinnerlichen

### Übung 1: Installation und Verbindung herstellen 🔗
**Ziel**: Installiere das AWS Toolkit und verbinde es mit deinem AWS-Konto.

1.  **Schritt 1**: Öffne die Erweiterungs-Ansicht in VS Code (`Strg+Shift+X`).
2.  **Schritt 2**: Suche nach **"AWS Toolkit"** und klicke auf **"Installieren"**.
3.  **Schritt 3**: In der Aktivitätsleiste erscheint ein neues AWS-Icon. Klicke darauf, um den **AWS-Explorer** zu öffnen.
4.  **Schritt 4**: Klicke in der AWS-Explorer-Ansicht auf den Link **"Connect to AWS..."**. Du wirst aufgefordert, entweder deine Zugangsdaten einzugeben oder ein lokal konfiguriertes Profil zu verwenden. Der einfachste Weg ist, die AWS CLI zu konfigurieren, indem du im Terminal `aws configure` eingibst.

**Reflexion**: Warum ist es wichtig, separate Profile für verschiedene AWS-Umgebungen (z. B. Entwicklung und Produktion) zu verwenden?

---

### Übung 2: Ressourcen verwalten und Logs ansehen 🖥️
**Ziel**: Navigiere durch deine AWS-Ressourcen und sieh dir die Logs deiner Lambda-Funktionen an.

1.  **Schritt 1**: Klicke im AWS-Explorer auf den Pfeil neben **"Lambda"**, um alle in deiner Region verfügbaren Funktionen anzuzeigen.
2.  **Schritt 2**: Klicke mit der rechten Maustaste auf eine deiner Lambda-Funktionen und wähle **"Invoke Function"** aus, um sie auszuführen. Die Ausgabe siehst du direkt im "Output"-Panel von VS Code.
3.  **Schritt 3**: Klicke erneut mit der rechten Maustaste auf die Funktion und wähle **"View logs"** aus, um die neuesten Logs der Funktion zu sehen. Die Logs werden im Output-Panel angezeigt.

**Reflexion**: Wie spart dir die Log-Anzeige in VS Code Zeit im Vergleich zum Wechsel in die AWS Management Console?

---

### Übung 3: Eine Serverless-Anwendung bereitstellen 🚀
**Ziel**: Erstelle und deploye eine neue serverless Anwendung mit dem AWS Serverless Application Model (SAM).

1.  **Schritt 1**: Öffne die Befehlspalette (`Strg+Umschalt+P`) und suche nach **`AWS: Create new SAM Application`**. Wähle eine Runtime, z. B. Python 3.12, und einen Speicherort für dein Projekt aus.
2.  **Schritt 2**: VS Code generiert eine komplette Projektstruktur für eine serverless Anwendung, inklusive der Python-Funktion und der Konfigurationsdatei.
3.  **Schritt 3**: Klicke mit der rechten Maustaste auf die Projektdatei `template.yaml` in deinem Explorer und wähle **"Deploy Serverless Application"**.
4.  **Schritt 4**: Folge den Anweisungen in der Befehlspalette. Das AWS Toolkit automatisiert den gesamten Prozess: Es packt deinen Code, lädt ihn hoch und aktualisiert deine CloudFormation-Ressourcen.

**Reflexion**: Welchen Vorteil hat die Verwendung eines Frameworks wie SAM gegenüber der manuellen Erstellung jeder AWS-Ressource?

---

### Fazit
Mit dem **AWS Toolkit** hast du gelernt, AWS-Dienste direkt in deiner Entwicklungsumgebung zu verwalten. Du kannst Lambda-Funktionen aufrufen, Logs einsehen und serverless Anwendungen bereitstellen, ohne jemals deinen Editor zu verlassen. Das Toolkit optimiert deinen Workflow und lässt die Cloud nahtlos mit deiner lokalen Umgebung verschmelzen.

**Nächste Schritte**:
- **Lokales Debugging**: Richte das Toolkit so ein, dass du deine Lambda-Funktionen lokal debuggen kannst, bevor du sie bereitstellst.
- **Weitere Services**: Navigiere im AWS-Explorer zu Diensten wie S3, DynamoDB oder CloudWatch und lerne, wie du sie aus VS Code heraus verwalten kannst.
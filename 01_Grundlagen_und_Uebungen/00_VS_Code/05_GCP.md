## Intro

Die Google Cloud Platform (GCP) direkt aus VS Code zu steuern. Dafür gibt es die offizielle **Cloud Code**-Erweiterung.

Cloud Code ist die Brücke, die deine lokale Entwicklungsumgebung nahtlos mit den Diensten von GCP verbindet. Statt zwischen dem Code-Editor und der Cloud-Konsole oder der Kommandozeile zu wechseln, bringt Cloud Code die Cloud zu dir.

---

### Grundlagen: Cloud Code für VS Code ☁️

**Cloud Code** ist eine kostenlose Erweiterung, die es dir erlaubt, mit Diensten wie **Kubernetes**, **Cloud Run** und der **Google Cloud API** zu interagieren, ohne VS Code zu verlassen. Sie automatisiert sich wiederholende Aufgaben wie die Authentifizierung, das Deployment und die Protokollierung.

* **Vorteile**: Reduziert den Kontextwechsel, beschleunigt deinen Entwicklungs-Workflow und bietet eine einheitliche, visuelle Schnittstelle für deine Cloud-Ressourcen.
* **Voraussetzung**: Du benötigst das `gcloud`-Befehlszeilentool, das auf deinem System installiert und mit deinem GCP-Konto verbunden ist.

---

### Übungen zum Verinnerlichen

### Übung 1: Die Verbindung herstellen 🔗
**Ziel**: Installiere die Cloud Code-Erweiterung und verbinde dich mit deinem GCP-Projekt.

1.  **Schritt 1**: Öffne die Erweiterungs-Ansicht in VS Code (`Strg+Shift+X`).
2.  **Schritt 2**: Suche nach "Cloud Code" und klicke auf **"Installieren"**. Starte VS Code neu, wenn du dazu aufgefordert wirst.
3.  **Schritt 3**: In der Aktivitätsleiste siehst du nun neue Icons. Wähle das **"Cloud Code"**-Icon aus.
4.  **Schritt 4**: In der Seitenleiste siehst du nun die Cloud Code-Ansicht. Klicke oben auf **"GCP"** und wähle im Drop-down-Menü dein GCP-Projekt aus.

**Reflexion**: Was ist der Vorteil, alle deine Cloud-Ressourcen direkt in einer einzigen Ansicht zu haben?

---

### Übung 2: Kubernetes-Cluster verwalten 🖥️
**Ziel**: Verwalte einen Kubernetes-Cluster, ohne das Terminal zu benutzen.

1.  **Schritt 1**: Klicke in der Cloud Code-Ansicht auf das Icon für **"Kubernetes"**.
2.  **Schritt 2**: Du siehst nun alle deine Cluster, Namespaces und Workloads. Klicke dich durch die Hierarchie, um die Details deiner Dienste anzuzeigen.
3.  **Schritt 3**: Klicke mit der rechten Maustaste auf einen Container und wähle **"Logs anzeigen"**. Du kannst die Echtzeit-Logs direkt in VS Code sehen, ohne `kubectl` zu verwenden.

**Reflexion**: Wie vereinfacht die visuelle Darstellung die Überwachung von Microservices im Vergleich zur reinen Befehlszeile?

---

### Übung 3: Eine Cloud Run-Anwendung bereitstellen 🚀
**Ziel**: Lerne, eine Anwendung direkt aus VS Code auf Cloud Run bereitzustellen.

1.  **Schritt 1**: Öffne dein Projekt in VS Code.
2.  **Schritt 2**: Öffne die Befehlspalette (`Strg+Umschalt+P`) und suche nach **`Cloud Code: Deploy to Cloud Run`**.
3.  **Schritt 3**: Folge den Anweisungen in der Befehlspalette: Wähle dein Projekt, eine Region und einen Servicenamen.
4.  **Schritt 4**: Cloud Code übernimmt nun den gesamten Prozess: Es erstellt ein Container-Image deines Codes, pusht es in die Container Registry und stellt es auf Cloud Run bereit. Die Logs dieses Prozesses siehst du direkt im integrierten Terminal.

**Reflexion**: Wie verändert die Automatisierung durch Cloud Code den Deployment-Prozess im Vergleich zum manuellen `gcloud`-Befehl?

---

### Fazit
Mit der Cloud Code-Erweiterung hast du gelernt, GCP nicht nur als Ziel für deinen Code zu sehen, sondern als integralen Bestandteil deines VS Code-Workflows. Sie automatisiert Routineaufgaben und ermöglicht dir, dich auf die Entwicklung zu konzentrieren, während die Cloud im Hintergrund nahtlos mit deinem Editor interagiert.

**Nächste Schritte**:
- **Lokales Debugging**: Lerne, deine Cloud Run- oder Kubernetes-Anwendungen lokal in VS Code zu debuggen, bevor du sie bereitstellst.
- **API-Integration**: Nutze Cloud Code, um Google-APIs zu durchsuchen und direkt in deinen Code zu integrieren.
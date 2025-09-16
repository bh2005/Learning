# Praxisorientierte Anleitung: Integration von Maven mit Jenkins für Continuous Integration auf Debian

## Einführung
Die Integration von **Apache Maven** mit **Jenkins** ermöglicht eine automatisierte Continuous Integration (CI)-Pipeline, bei der Code-Änderungen automatisch gebaut, getestet und deployt werden. Maven übernimmt den Build-Prozess (z. B. Kompilierung, Tests), während Jenkins die Orchestrierung, Planung und Überwachung handhabt. Diese Anleitung zeigt, wie Sie Maven und Jenkins auf einem Debian-System einrichten und integrieren, um eine einfache CI-Pipeline für ein Java-Projekt zu erstellen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, CI-Prozesse für größere Java-Projekte zu automatisieren. Diese Anleitung ist ideal für Entwickler, die ihre Workflows effizienter gestalten möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Java Development Kit (JDK) installiert (z. B. OpenJDK 11, wie in der vorherigen Java-Anleitung)
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile, Java und Maven (z. B. aus der vorherigen Maven-Anleitung)
- Ein Git-Repository (z. B. auf GitHub) mit einem Java-Maven-Projekt
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie IntelliJ IDEA Community Edition)

## Grundlegende Konzepte und Techniken
Hier sind die wichtigsten Konzepte und Techniken, die wir behandeln:

1. **Maven-Jenkins-Integration**:
   - **Maven-Plugin**: Das Jenkins-Maven-Plugin automatisiert Maven-Builds (z. B. `mvn clean package`)
   - **Pipeline-as-Code**: Jenkinsfile im Repository definiert die CI-Pipeline
   - **Triggers**: Automatischer Build bei Git-Push
2. **Wichtige Konfigurationsdateien**:
   - `pom.xml`: Maven-Projektkonfiguration
   - `Jenkinsfile`: Pipeline-Definition für Jenkins
3. **Wichtige Befehle**:
   - `mvn clean package`: Maven-Build
   - `jenkins`: Jenkins-Dienst verwalten
   - `git clone`: Repository klonen

## Übungen zum Verinnerlichen

### Übung 1: Jenkins und Maven installieren
**Ziel**: Lernen, wie man Jenkins und Maven auf Debian installiert und die Grundkonfiguration durchführt.

1. **Schritt 1**: Installiere Jenkins und Maven.
   ```bash
   sudo apt update
   sudo apt install -y openjdk-11-jdk maven
   sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
       https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
   echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
       sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
   sudo apt update
   sudo apt install -y jenkins
   ```
2. **Schritt 2**: Starte und aktiviere Jenkins.
   ```bash
   sudo systemctl start jenkins
   sudo systemctl enable jenkins
   ```
   Überprüfe den Status:
   ```bash
   sudo systemctl status jenkins
   ```
3. **Schritt 3**: Konfiguriere Jenkins initial.
   - Öffne `http://localhost:8080` im Browser.
   - Hole den initialen Admin-Passwort:
     ```bash
     sudo cat /var/lib/jenkins/secrets/initialAdminPassword
     ```
   - Installiere die vorgeschlagenen Plugins (inklusive Maven-Integration).
   - Erstelle einen Admin-Benutzer (z. B. `admin` / `adminpass`).
4. **Schritt 4**: Installiere das Maven-Plugin.
   - Gehe zu **Manage Jenkins** > **Plugins** > **Available Plugins**.
   - Suche nach "Maven Integration" und installiere es.
   - Starte Jenkins neu: **Manage Jenkins** > **Restart Safely**.

**Reflexion**: Warum ist das Maven-Plugin essenziell, und wie erleichtert es die Automatisierung von Builds in Jenkins?

### Übung 2: Ein Java-Maven-Projekt in Jenkins integrieren
**Ziel**: Verstehen, wie man ein Git-Repository mit einem Maven-Projekt in Jenkins einbindet und einen Freestyle-Job erstellt.

1. **Schritt 1**: Erstelle ein Beispiel-Maven-Projekt (falls nicht vorhanden).
   ```bash
   cd ~
   mvn archetype:generate \
       -DgroupId=com.example \
       -DartifactId=sample-app \
       -DarchetypeArtifactId=maven-archetype-quickstart \
       -DinteractiveMode=false
   cd sample-app
   ```
   Füge eine einfache `App.java` hinzu:
   ```bash
   nano src/main/java/com/example/App.java
   ```
   Inhalt:
   ```java
   package com.example;

   public class App {
       public static void main(String[] args) {
           System.out.println("Hallo aus Jenkins-Maven-CI!");
       }
   }
   ```
   Pushe zu GitHub (angenommen, Sie haben ein Repository):
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/sample-app.git
   git push -u origin main
   ```
2. **Schritt 2**: Erstelle einen Freestyle-Job in Jenkins.
   - Gehe zu **New Item** > **Freestyle project** > Name: `maven-ci-job`.
   - **Source Code Management**: Git > Repository URL: `https://github.com/yourusername/sample-app.git`.
   - **Build Triggers**: "Poll SCM" (z. B. `H/5 * * * *` für alle 5 Minuten).
   - **Build Steps**: "Add build step" > "Invoke top-level Maven targets" > Goals: `clean package`.
   - Speichere und baue den Job.
3. **Schritt 3**: Teste den Build.
   - Klicke auf **Build Now**.
   - Überprüfe die Console Output: Der Maven-Build sollte erfolgreich sein.
   - Pushe eine Änderung zu Git (z. B. ändere `App.java`) und beobachte den automatischen Trigger.

**Reflexion**: Wie automatisiert Jenkins den Build-Prozess, und warum ist "Poll SCM" nützlich für CI?

### Übung 3: Pipeline-as-Code mit Jenkinsfile
**Ziel**: Lernen, wie man eine Pipeline mit einem `Jenkinsfile` definiert, um den CI-Prozess als Code zu verwalten.

1. **Schritt 1**: Erstelle ein `Jenkinsfile` im Projekt.
   ```bash
   nano Jenkinsfile
   ```
   Füge folgenden Inhalt ein:
   ```groovy
   pipeline {
       agent any
       tools {
           maven 'Maven' // Name der Maven-Installation in Jenkins
       }
       stages {
           stage('Checkout') {
               steps {
                   git 'https://github.com/yourusername/sample-app.git'
               }
           }
           stage('Build') {
               steps {
                   sh 'mvn clean compile'
               }
           }
           stage('Test') {
               steps {
                   sh 'mvn test'
               }
           }
           stage('Package') {
               steps {
                   sh 'mvn package'
               }
           }
       }
       post {
           always {
               archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
           }
           success {
               echo 'Build erfolgreich!'
           }
           failure {
               echo 'Build fehlgeschlagen!'
           }
       }
   }
   ```
   Committe und pushe:
   ```bash
   git add Jenkinsfile
   git commit -m "Add Jenkinsfile"
   git push
   ```
2. **Schritt 2**: Konfiguriere Maven in Jenkins.
   - Gehe zu **Manage Jenkins** > **Global Tool Configuration** > **Maven**.
   - Füge eine Maven-Installation hinzu: Name: `Maven`, Version: z. B. `3.9.6`, automatische Installation aktivieren.
   - Speichere die Konfiguration.
3. **Schritt 3**: Erstelle einen Pipeline-Job in Jenkins.
   - Gehe zu **New Item** > **Pipeline** > Name: `maven-pipeline-job`.
   - **Pipeline**: "Pipeline script from SCM" > Git > Repository URL: `https://github.com/yourusername/sample-app.git`.
   - Script Path: `Jenkinsfile`.
   - Speichere und baue den Job.
4. **Schritt 4**: Teste die Pipeline.
   - Klicke auf **Build Now**.
   - Überprüfe die Stages in der Weboberfläche: Checkout, Build, Test, Package.
   - Lade das Artefakt herunter: Gehe zu **Build History** > **Archive**.

**Reflexion**: Wie macht Pipeline-as-Code die CI-Prozesse reproduzierbar, und welche Vorteile bietet es gegenüber Freestyle-Jobs?

## Tipps für den Erfolg
- Überprüfe die Jenkins-Logs in der Console Output für Build-Fehler.
- Stelle sicher, dass `JAVA_HOME` korrekt gesetzt ist (`export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64`).
- Verwende Webhooks in GitHub für sofortige Triggers statt Polling: In GitHub unter **Settings** > **Webhooks** > URL: `http://<jenkins-ip>:8080/github-webhook/`.
- Teste mit kleinen Änderungen, bevor du komplexe Pipelines baust.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Maven mit Jenkins auf einem Debian-System integrieren, um Continuous Integration für Java-Projekte zu automatisieren. Durch die Übungen haben Sie praktische Erfahrung mit Freestyle-Jobs, Pipeline-as-Code und der Orchestrierung von Builds gesammelt. Diese Fähigkeiten sind essenziell für skalierbare Entwicklungsworkflows. Üben Sie weiter, um fortgeschrittene Features wie Deployment oder Multi-Branch-Pipelines zu meistern!

**Nächste Schritte**:
- Erkunden Sie Jenkins-Plugins für Deployment (z. B. zu Docker oder Kubernetes).
- Integrieren Sie SonarQube für Code-Qualität in die Pipeline.
- Verwenden Sie Jenkins Blue Ocean für eine visuelle Pipeline-Übersicht.

**Quellen**:
- Offizielle Jenkins-Dokumentation: https://www.jenkins.io/doc/
- Maven Integration Plugin: https://plugins.jenkins.io/maven-plugin/
- Pipeline Maven Integration: https://plugins.jenkins.io/pipeline-maven/
- DigitalOcean Jenkins-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-20-04
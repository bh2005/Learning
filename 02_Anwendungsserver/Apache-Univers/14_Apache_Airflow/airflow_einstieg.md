# Praxisorientierte Anleitung: Einstieg in Apache Airflow auf Debian

## Einführung
Apache Airflow ist ein Open-Source-Plattform zur Programmierung, Planung und Überwachung von Workflows. Es ermöglicht die Definition von DAGs (Directed Acyclic Graphs) für komplexe Datenpipelines und integriert sich nahtlos mit Big-Data-Tools wie Hadoop, Spark oder Kafka. Diese Anleitung führt Sie in die Installation und Konfiguration von Apache Airflow auf einem Debian-System in einer Einzelknoten-Konfiguration ein und zeigt Ihnen, wie Sie eine einfache DAG erstellen und ausführen. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Airflow für die Orchestrierung von Datenworkflows einzusetzen. Diese Anleitung ist ideal für Datenengineers und Entwickler, die automatisierte Pipelines aufbauen möchten.

Voraussetzungen:
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Python 3.8 oder höher installiert
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Grundlegende Kenntnisse der Linux-Kommandozeile und Python
- Ein Texteditor (z. B. `nano`, `vim` oder eine IDE wie VS Code)

## Grundlegende Apache Airflow-Konzepte und Befehle
Hier sind die wichtigsten Konzepte und Befehle, die wir behandeln:

1. **Airflow-Komponenten**:
   - **DAG**: Directed Acyclic Graph, definiert einen Workflow als Python-Skript
   - **Operator**: Bausteine für Tasks (z. B. `BashOperator`, `PythonOperator`)
   - **Scheduler**: Plant und triggert DAGs
   - **Webserver**: Weboberfläche zur Überwachung
2. **Wichtige Konfigurationsdateien**:
   - `airflow.cfg`: Haupt-Konfigurationsdatei für Airflow
   - `dags/`: Verzeichnis für DAG-Skripte
3. **Wichtige Befehle**:
   - `airflow db init`: Initialisiert die Metadaten-Datenbank
   - `airflow users create`: Erstellt Benutzer
   - `airflow webserver`: Startet den Webserver
   - `airflow scheduler`: Startet den Scheduler

## Übungen zum Verinnerlichen

### Übung 1: Apache Airflow installieren und konfigurieren
**Ziel**: Lernen, wie man Airflow auf einem Debian-System installiert und für eine Einzelknoten-Konfiguration einrichtet.

1. **Schritt 1**: Installiere Python und pip (falls nicht bereits vorhanden).
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip python3-venv
   ```
2. **Schritt 2**: Erstelle eine virtuelle Umgebung und installiere Airflow.
   ```bash
   python3 -m venv airflow_env
   source airflow_env/bin/activate
   pip install apache-airflow==2.9.3
   ```
3. **Schritt 3**: Initialisiere die Airflow-Datenbank und erstelle einen Admin-Benutzer.
   ```bash
   export AIRFLOW_HOME=~/airflow
   airflow db init
   airflow users create \
       --username admin \
       --firstname Admin \
       --lastname User \
       --role Admin \
       --email admin@example.com \
       --password admin
   ```
4. **Schritt 5**: Starte den Webserver und Scheduler.
   ```bash
   # In einem Terminal: Webserver
   airflow webserver --port 8080

   # In einem zweiten Terminal: Scheduler
   airflow scheduler
   ```
   Öffne `http://localhost:8080` im Browser und melde dich mit `admin`/`admin` an.

**Reflexion**: Warum ist die Initialisierung der Datenbank notwendig, und welche Rolle spielt der Scheduler in Airflow?

### Übung 2: Eine einfache DAG erstellen und ausführen
**Ziel**: Verstehen, wie man eine DAG mit Operatoren erstellt und in Airflow ausführt.

1. **Schritt 1**: Erstelle das `dags`-Verzeichnis und eine einfache DAG.
   ```bash
   mkdir -p ~/airflow/dags
   nano ~/airflow/dags/simple_dag.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from datetime import datetime
   from airflow import DAG
   from airflow.operators.bash import BashOperator
   from airflow.operators.python import PythonOperator

   def print_hello():
       print("Hallo, Airflow!")

   dag = DAG(
       'simple_dag',
       default_args={
           'owner': 'airflow',
           'start_date': datetime(2025, 9, 16),
       },
       schedule_interval='@daily',
       catchup=False
   )

   task1 = BashOperator(
       task_id='print_date',
       bash_command='date',
       dag=dag
   )

   task2 = PythonOperator(
       task_id='print_hello',
       python_callable=print_hello,
       dag=dag
   )

   task1 >> task2
   ```
2. **Schritt 2**: Überprüfe die DAG in der Weboberfläche.
   - Gehe zu `http://localhost:8080` und aktiviere die `simple_dag`.
   - Trigger die DAG manuell und überprüfe die Logs.
3. **Schritt 3**: Überprüfe die Ausführung.
   - In der Weboberfläche siehst du den DAG-Graph und Logs.
   - Die Ausgabe von `task1` zeigt das Datum, `task2` druckt "Hallo, Airflow!".

**Reflexion**: Wie ermöglicht die DAG-Definition die Orchestrierung von Tasks, und warum ist die `>>`-Syntax nützlich?

### Übung 3: Eine erweiterte DAG mit Hooks und Variablen erstellen
**Ziel**: Lernen, wie man Hooks (z. B. für E-Mails) und Airflow-Variablen in einer DAG verwendet.

1. **Schritt 1**: Erstelle eine erweiterte DAG mit E-Mail-Hook.
   ```bash
   nano ~/airflow/dags/advanced_dag.py
   ```
   Füge folgenden Inhalt ein:
   ```python
   from datetime import datetime
   from airflow import DAG
   from airflow.operators.bash import BashOperator
   from airflow.operators.email import EmailOperator
   from airflow.models import Variable

   dag = DAG(
       'advanced_dag',
       default_args={
           'owner': 'airflow',
           'start_date': datetime(2025, 9, 16),
       },
       schedule_interval='@daily',
       catchup=False
   )

   task1 = BashOperator(
       task_id='run_script',
       bash_command='echo "Workflow gestartet um $(date)"',
       dag=dag
   )

   email_task = EmailOperator(
       task_id='send_email',
       to='admin@example.com',
       subject='DAG abgeschlossen',
       html_content='<h3>Workflow erfolgreich beendet!</h3>',
       dag=dag
   )

   # Variable aus Airflow verwenden
   message = Variable.get("greeting_message", default_var="Hallo!")
   task2 = BashOperator(
       task_id='print_variable',
       bash_command=f'echo "{message}"',
       dag=dag
   )

   task1 >> task2 >> email_task
   ```
2. **Schritt 2**: Setze eine Airflow-Variable.
   ```bash
   airflow variables set greeting_message "Guten Tag, Airflow!"
   ```
3. **Schritt 3**: Aktiviere und trigger die DAG in der Weboberfläche.
   - Überprüfe die Logs: `task1` zeigt das Datum, `task2` die Variable, und `email_task` sendet eine E-Mail (konfiguriere SMTP in `airflow.cfg`, falls gewünscht).

**Reflexion**: Wie erweitern Hooks und Variablen die Flexibilität von DAGs, und in welchen Szenarien sind sie nützlich?

## Tipps für den Erfolg
- Überprüfe die Airflow-Logs in `~/airflow/logs/` bei Problemen mit DAGs.
- Stelle sicher, dass die virtuelle Umgebung aktiviert ist (`source airflow_env/bin/activate`).
- Verwende die Weboberfläche für die Überwachung und Fehlerbehebung.
- Teste DAGs mit `schedule_interval=None` für manuelle Ausführungen.

## Fazit
In dieser Anleitung haben Sie gelernt, wie Sie Apache Airflow auf einem Debian-System installieren, eine einfache und erweiterte DAG erstellen und ausführen. Durch die Übungen haben Sie praktische Erfahrung mit Operatoren, Hooks und Variablen gesammelt. Diese Fähigkeiten sind die Grundlage für die Orchestrierung komplexer Datenpipelines. Üben Sie weiter, um Integrationen mit externen Systemen zu meistern!

**Nächste Schritte**:
- Integrieren Sie Airflow mit Apache Spark oder Kafka für Datenpipelines.
- Erkunden Sie Airflow-Provider-Pakete für erweiterte Operatoren.
- Richten Sie einen Airflow-Mehrknoten-Cluster ein.

**Quellen**:
- Offizielle Apache Airflow-Dokumentation: https://airflow.apache.org/docs/
- Airflow Tutorials: https://airflow.apache.org/docs/apache-airflow/stable/tutorial.html
- DigitalOcean Airflow-Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-apache-airflow-on-ubuntu
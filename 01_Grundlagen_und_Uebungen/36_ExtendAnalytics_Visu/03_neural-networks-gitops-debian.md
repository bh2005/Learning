# Praxisorientierte Anleitung: Künstliche Neuronale Netze für Netzwerksicherheit mit GitOps im Debian-basierten HomeLab

## Einführung
Künstliche Neuronale Netze (KNN) sind leistungsstarke Modelle des maschinellen Lernens, die Muster in Daten erkennen, z. B. Anomalien im Netzwerkverkehr für Sicherheitszwecke. Diese Anleitung führt in die Grundlagen von KNN ein und zeigt, wie man ein einfaches neuronales Netz mit TensorFlow in einem Debian-basierten HomeLab (z. B. mit LXC-Containern) entwickelt, um Netzwerkanomalien zu erkennen. Konfigurationen und Modelle werden in einem Git-Repository gespeichert und über Ansible mit GitHub Actions angewendet, um Zero-Trust-Prinzipien wie kontinuierliche Überwachung zu gewährleisten. Ziel ist es, dir praktische Schritte zur Integration von KNN in Netzwerksicherheitsworkflows ohne Kubernetes zu vermitteln.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern (z. B. `game-container`).
- Installierte Tools: `ansible`, `git`, `python3`, `tensorflow`, `iptables`, `rsyslog`, `auditd`.
- Ein GitHub-Repository für Konfigurationen und Modelle.
- Grundkenntnisse in Python, Ansible, GitOps und Netzwerksicherheit.
- Testumgebung ohne Produktionsdaten; simulierte Netzwerkdaten (z. B. CSV-Dateien).

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für KNN und GitOps im Debian-Kontext:

1. **Künstliche Neuronale Netze (KNN)**:
   - **Funktion**: Bestehen aus Schichten (Input, Hidden, Output), die Daten durch Gewichte und Aktivierungsfunktionen verarbeiten.
   - **Anwendung**: Erkennen von Netzwerkanomalien (z. B. ungewöhnlicher Traffic) durch Klassifikation.
   - **Tool**: TensorFlow für Modelltraining und -ausführung auf Debian.
2. **GitOps-Integration**:
   - Speichere KNN-Modelle, Skripte und Konfigurationen (`iptables`, `rsyslog`) in Git.
   - Ansible wendet Konfigurationen aus dem Git-Repository auf LXC-Container an.
3. **Netzwerksicherheit im HomeLab**:
   - Nutze `iptables` für Firewall-Regeln und `rsyslog` für zentralisierte Logs.
   - Integriere KNN zur Analyse von Netzwerklogs für Zero-Trust-Überwachung.

## Übungen zum Verinnerlichen

### Übung 1: KNN für Anomalieerkennung entwickeln und in Git speichern
**Ziel**: Entwickle ein einfaches neuronales Netz zur Erkennung von Netzwerkanomalien.

1. **Schritt 1**: Erstelle ein Python-Skript für ein KNN-Modell im Git-Repository (`model/anomaly_detection.py`):
   ```python
   import tensorflow as tf
   import numpy as np
   import pandas as pd
   from sklearn.model_selection import train_test_split
   from sklearn.preprocessing import StandardScaler

   # Simulierte Netzwerkdaten laden
   data = pd.read_csv('/app/network_data.csv')  # Beispiel: IP, Port, Bytes
   X = data[['source_ip', 'port', 'bytes']].values
   y = data['anomaly'].values  # 0=Normal, 1=Anomalie

   # Daten vorbereiten
   scaler = StandardScaler()
   X_scaled = scaler.fit_transform(X)
   X_train, X_test, y_train, y_test = train_test_split(X_scaled, y, test_size=0.2)

   # KNN-Modell definieren
   model = tf.keras.Sequential([
       tf.keras.layers.Dense(64, activation='relu', input_shape=(3,)),
       tf.keras.layers.Dense(32, activation='relu'),
       tf.keras.layers.Dense(1, activation='sigmoid')
   ])
   model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])

   # Modell trainieren
   model.fit(X_train, y_train, epochs=10, batch_size=32)
   model.save('/app/anomaly_model.h5')

   # Modell testen
   loss, accuracy = model.evaluate(X_test, y_test)
   print(f"Test Accuracy: {accuracy}")
   ```
2. **Schritt 2**: Erstelle simulierte Netzwerkdaten (`model/network_data.csv`):
   ```csv
   source_ip,port,bytes,anomaly
   192.168.1.10,80,500,0
   192.168.1.11,22,200,0
   10.0.0.1,445,10000,1
   ```
3. **Schritt 3**: Erstelle ein Ansible-Playbook für die Installation und Ausführung (`deploy_model.yml`):
   ```yaml
   - name: Bereitstellen des KNN-Modells
     hosts: lxc_hosts
     tasks:
       - name: Installiere Python und TensorFlow
         ansible.builtin.apt:
           name: "{{ item }}"
           state: present
           update_cache: yes
         loop:
           - python3
           - python3-pip
       - name: Installiere Python-Abhängigkeiten
         ansible.builtin.pip:
           name: "{{ item }}"
           state: present
         loop:
           - tensorflow
           - pandas
           - scikit-learn
       - name: Erstelle Verzeichnis für Modell
         ansible.builtin.file:
           path: /app
           state: directory
           mode: '0755'
       - name: Kopiere Modell und Daten
         ansible.builtin.copy:
           src: "{{ item }}"
           dest: /app/
           mode: '0644'
         loop:
           - model/anomaly_detection.py
           - model/network_data.csv
       - name: Führe Modelltraining aus
         ansible.builtin.command: python3 /app/anomaly_detection.py
         args:
           chdir: /app
   ```
4. **Schritt 4**: Pushe ins Repository und teste:
   ```bash
   git add model/
   git commit -m "Add KNN anomaly detection model"
   git push
   ansible-playbook -i inventory.yml deploy_model.yml
   ```

**Reflexion**: Wie erkennt ein KNN Anomalien im Netzwerkverkehr? Warum ist Git für die Versionierung von Modellen und Daten wichtig?

### Übung 2: Netzwerksicherheit mit iptables über GitOps
**Ziel**: Konfiguriere `iptables` für den KNN-Service mit Least Privilege.

1. **Schritt 1**: Erstelle eine iptables-Konfiguration im Git-Repository (`iptables_rules.conf`):
   ```bash
   *filter
   :INPUT DROP [0:0]
   :FORWARD ACCEPT [0:0]
   :OUTPUT ACCEPT [0:0]
   -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
   -A INPUT -p tcp --dport 8080 -s 192.168.1.0/24 -j ACCEPT  # KNN-Service
   COMMIT
   ```
2. **Schritt 2**: Erstelle ein Ansible-Playbook für iptables (`deploy_iptables.yml`):
   ```yaml
   - name: Wende iptables-Regeln über GitOps an
     hosts: lxc_hosts
     tasks:
       - name: Installiere iptables
         ansible.builtin.apt:
           name: iptables
           state: present
           update_cache: yes
       - name: Kopiere iptables-Regeln
         ansible.builtin.copy:
           src: iptables_rules.conf
           dest: /etc/iptables/rules.v4
           mode: '0644'
       - name: Lade iptables-Regeln
         ansible.builtin.command: iptables-restore < /etc/iptables/rules.v4
   ```
3. **Schritt 3**: Integriere in GitHub Actions (`.github/workflows/iptables-gitops.yml`):
   ```yaml
   name: Deploy iptables via GitOps
   on:
     push:
       branches: [ main ]
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - name: Installiere Ansible
         run: pip install ansible
       - name: Führe Playbook aus
         run: ansible-playbook -i inventory.yml deploy_iptables.yml
   ```
4. **Schritt 4**: Pushe und teste:
   ```bash
   git add iptables_rules.conf deploy_iptables.yml
   git commit -m "Add iptables for KNN"
   git push
   ansible-playbook -i inventory.yml deploy_iptables.yml
   nc -zv 192.168.1.100 8080  # Sollte von 192.168.1.0/24 aus funktionieren
   ```

**Reflexion**: Wie unterstützt `iptables` das Zero-Trust-Prinzip für den KNN-Service? Warum ist GitOps für Firewall-Regeln vorteilhaft?

### Übung 3: Kontinuierliche Überwachung mit rsyslog und GitOps
**Ziel**: Implementiere zentralisiertes Logging für KNN und Netzwerksicherheit.

1. **Schritt 1**: Erstelle eine rsyslog-Konfiguration im Git-Repository (`rsyslog.conf`):
   ```bash
   *.* @your-log-server:514
   ```
2. **Schritt 2**: Erstelle ein Ansible-Playbook für Logging (`deploy_rsyslog.yml`):
   ```yaml
   - name: Konfiguriere rsyslog über GitOps
     hosts: lxc_hosts
     tasks:
       - name: Installiere rsyslog
         ansible.builtin.apt:
           name: rsyslog
           state: present
       - name: Kopiere rsyslog-Konfiguration
         ansible.builtin.copy:
           src: rsyslog.conf
           dest: /etc/rsyslog.conf
           mode: '0644'
       - name: Starte rsyslog
         ansible.builtin.service:
           name: rsyslog
           state: restarted
   ```
3. **Schritt 3**: Integriere in GitHub Actions (`.github/workflows/logging-gitops.yml`):
   ```yaml
   name: Deploy rsyslog via GitOps
   on:
     push:
       branches: [ main ]
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - name: Installiere Ansible
         run: pip install ansible
       - name: Führe Playbook aus
         run: ansible-playbook -i inventory.yml deploy_rsyslog.yml
   ```
4. **Schritt 4**: Pushe und teste:
   ```bash
   git add rsyslog.conf deploy_rsyslog.yml
   git commit -m "Add rsyslog for KNN"
   git push
   ansible-playbook -i inventory.yml deploy_rsyslog.yml
   logger "KNN Test: Network Access"
   tail -f /var/log/syslog  # Prüfe Logs
   ```

**Reflexion**: Wie stärkt zentralisiertes Logging die Überwachung von KNN-Anwendungen? Wie automatisiert GitOps die Log-Verwaltung?

## Tipps für den Erfolg
- **Least Privilege**: Beschränke `iptables` auf minimale IPs/Ports (z. B. 8080 für KNN).
- **Monitoring**: Nutze `rsyslog` und `auditd` für Sicherheitslogs; analysiere KNN-Ausgaben regelmäßig.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` und Python-Logs bei Problemen.
- **Best Practices**: Versioniere Modelle und Konfigurationen in Git, teste lokal vor CI/CD, nutze `ansible-lint`.
- **2025-Fokus**: Erkunde fortgeschrittene KNN-Modelle (z. B. Autoencoder) und OpenTelemetry für Tracing.

## Fazit
Du hast gelernt, ein Künstliches Neuronales Netz mit TensorFlow für Netzwerkanomalieerkennung zu entwickeln und über GitOps-Workflows mit Ansible in einem Debian-basierten HomeLab bereitzustellen, kombiniert mit `iptables` und `rsyslog` für Netzwerksicherheit. Diese Übungen stärken die Automatisierung und Sicherheit deines Setups. Wiederhole sie, um KNN und GitOps zu verinnerlichen.

**Nächste Schritte**:
- Erkunde fortgeschrittene KNN-Modelle (z. B. LSTM für Zeitreihen).
- Integriere OpenTelemetry für Tracing (z. B. mit Jaeger).
- Vertiefe dich in Sicherheits-Checks mit `checkov` für Konfigurationen.

**Quellen**: TensorFlow Docs, Ansible Docs, Debian Security Docs.
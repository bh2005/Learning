# Praxisorientierte Anleitung: Fortgeschrittene KNN (LSTM) für Zeitreihenanalyse und Netzwerksicherheit mit GitOps im Debian-basierten HomeLab

## Einführung
Long Short-Term Memory (LSTM) Netze sind fortgeschrittene Künstliche Neuronale Netze (KNN), die für Zeitreihenanalyse optimiert sind und Muster in sequenziellen Daten, wie Netzwerkverkehr, erkennen können. Diese Anleitung zeigt, wie man ein LSTM-Modell mit TensorFlow in einem Debian-basierten HomeLab (z. B. mit LXC-Containern) entwickelt, um Netzwerkanomalien (z. B. ungewöhnliche Traffic-Spitzen) zu detektieren. Konfigurationen und Modelle werden in einem Git-Repository gespeichert und über Ansible mit GitHub Actions angewendet, um Zero-Trust-Prinzipien wie kontinuierliche Überwachung zu gewährleisten. Ziel ist es, dir praktische Schritte zur Implementierung von LSTM für Netzwerksicherheit zu vermitteln.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern (z. B. `game-container`).
- Installierte Tools: `ansible`, `git`, `python3`, `tensorflow`, `iptables`, `rsyslog`, `auditd`.
- Ein GitHub-Repository für Konfigurationen und Modelle.
- Grundkenntnisse in Python, Ansible, GitOps, Zeitreihenanalyse und Netzwerksicherheit.
- Testumgebung ohne Produktionsdaten; simulierte Netzwerk-Zeitreihendaten (z. B. CSV-Dateien).
- Hardware: Mindestens 4 GB RAM und 2 CPU-Kerne für LSTM-Training.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für LSTM und GitOps im Debian-Kontext:

1. **LSTM für Zeitreihen**:
   - **Funktion**: LSTM-Netze speichern Kontextinformationen über längere Zeiträume, ideal für Zeitreihen wie Netzwerkverkehr.
   - **Anwendung**: Erkennung von Anomalien (z. B. plötzliche Traffic-Spitzen) durch Klassifikation oder Vorhersage.
   - **Tool**: TensorFlow für Modelltraining und -ausführung auf Debian.
2. **GitOps-Integration**:
   - Speichere LSTM-Modelle, Skripte und Konfigurationen (`iptables`, `rsyslog`) in Git.
   - Ansible wendet Konfigurationen aus dem Git-Repository auf LXC-Container an.
3. **Netzwerksicherheit im HomeLab**:
   - Nutze `iptables` für Firewall-Regeln und `rsyslog` für zentralisierte Logs.
   - Integriere LSTM zur Analyse von Netzwerklogs für Zero-Trust-Überwachung.

## Übungen zum Verinnerlichen

### Übung 1: LSTM-Modell für Zeitreihenanalyse entwickeln und in Git speichern
**Ziel**: Entwickle ein LSTM-Modell zur Erkennung von Netzwerkanomalien in Zeitreihen.

1. **Schritt 1**: Erstelle ein Python-Skript für ein LSTM-Modell im Git-Repository (`model/lstm_anomaly_detection.py`):
   ```python
   import tensorflow as tf
   import numpy as np
   import pandas as pd
   from sklearn.preprocessing import MinMaxScaler
   from sklearn.model_selection import train_test_split

   # Simulierte Zeitreihendaten laden
   data = pd.read_csv('/app/network_traffic.csv')  # Beispiel: Zeit, Bytes
   traffic = data['bytes'].values.reshape(-1, 1)

   # Daten vorbereiten (Zeitfenster erstellen)
   def create_sequences(data, seq_length):
       sequences = []
       labels = []
       for i in range(len(data) - seq_length):
           sequences.append(data[i:i + seq_length])
           labels.append(data[i + seq_length])
       return np.array(sequences), np.array(labels)

   seq_length = 10
   scaler = MinMaxScaler()
   traffic_scaled = scaler.fit_transform(traffic)
   X, y = create_sequences(traffic_scaled, seq_length)

   # Train-Test-Split
   X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

   # LSTM-Modell definieren
   model = tf.keras.Sequential([
       tf.keras.layers.LSTM(64, return_sequences=True, input_shape=(seq_length, 1)),
       tf.keras.layers.LSTM(32),
       tf.keras.layers.Dense(16, activation='relu'),
       tf.keras.layers.Dense(1)
   ])
   model.compile(optimizer='adam', loss='mse')

   # Modell trainieren
   model.fit(X_train, y_train, epochs=20, batch_size=32, validation_split=0.1)
   model.save('/app/lstm_model.h5')

   # Modell testen (Anomalieerkennung durch Abweichung)
   predictions = model.predict(X_test)
   mse = np.mean((predictions - y_test) ** 2, axis=1)
   threshold = np.percentile(mse, 95)  # Anomalien > 95. Perzentil
   anomalies = mse > threshold
   print(f"Detected anomalies: {np.sum(anomalies)}")
   ```
2. **Schritt 2**: Erstelle simulierte Zeitreihendaten (`model/network_traffic.csv`):
   ```csv
   time,bytes
   2025-09-15T00:00:00,500
   2025-09-15T00:01:00,510
   2025-09-15T00:02:00,10000  # Anomalie
   2025-09-15T00:03:00,520
   ```
3. **Schritt 3**: Erstelle ein Ansible-Playbook für die Installation und Ausführung (`deploy_lstm.yml`):
   ```yaml
   - name: Bereitstellen des LSTM-Modells
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
           - model/lstm_anomaly_detection.py
           - model/network_traffic.csv
       - name: Führe Modelltraining aus
         ansible.builtin.command: python3 /app/lstm_anomaly_detection.py
         args:
           chdir: /app
   ```
4. **Schritt 4**: Pushe ins Repository und teste:
   ```bash
   git add model/
   git commit -m "Add LSTM anomaly detection model"
   git push
   ansible-playbook -i inventory.yml deploy_lstm.yml
   ```

**Reflexion**: Warum sind LSTM-Netze für Zeitreihenanalyse geeignet? Wie hilft Git bei der Verwaltung von Modellen und Daten?

### Übung 2: Netzwerksicherheit mit iptables über GitOps
**Ziel**: Konfiguriere `iptables` für den LSTM-Service mit Least Privilege.

1. **Schritt 1**: Erstelle eine iptables-Konfiguration im Git-Repository (`iptables_rules.conf`):
   ```bash
   *filter
   :INPUT DROP [0:0]
   :FORWARD ACCEPT [0:0]
   :OUTPUT ACCEPT [0:0]
   -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
   -A INPUT -p tcp --dport 8080 -s 192.168.1.0/24 -j ACCEPT  # LSTM-Service
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
   git commit -m "Add iptables for LSTM"
   git push
   ansible-playbook -i inventory.yml deploy_iptables.yml
   nc -zv 192.168.1.100 8080  # Sollte von 192.168.1.0/24 aus funktionieren
   ```

**Reflexion**: Wie unterstützt `iptables` die Absicherung des LSTM-Services? Warum ist GitOps für Firewall-Regeln vorteilhaft?

### Übung 3: Kontinuierliche Überwachung mit rsyslog und GitOps
**Ziel**: Implementiere zentralisiertes Logging für LSTM und Netzwerksicherheit.

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
   git commit -m "Add rsyslog for LSTM"
   git push
   ansible-playbook -i inventory.yml deploy_rsyslog.yml
   logger "LSTM Test: Network Anomaly Detected"
   tail -f /var/log/syslog  # Prüfe Logs
   ```

**Reflexion**: Wie stärkt zentralisiertes Logging die Überwachung von LSTM-Anwendungen? Wie automatisiert GitOps die Log-Verwaltung?

## Tipps für den Erfolg
- **Datenqualität**: Stelle sicher, dass Zeitreihendaten repräsentativ sind (z. B. echte Traffic-Logs sammeln).
- **Least Privilege**: Beschränke `iptables` auf minimale IPs/Ports (z. B. 8080 für LSTM).
- **Monitoring**: Nutze `rsyslog` und `auditd` für Sicherheitslogs; analysiere LSTM-Ausgaben regelmäßig.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` und Python-Logs bei Problemen.
- **Best Practices**: Versioniere Modelle und Konfigurationen in Git, teste lokal vor CI/CD, nutze `ansible-lint`.
- **2025-Fokus**: Erkunde weitere Zeitreihen-Modelle (z. B. Autoencoder) oder OpenTelemetry für Tracing.

## Fazit
Du hast gelernt, ein fortgeschrittenes LSTM-Modell mit TensorFlow für Zeitreihenbasierte Netzwerkanomalieerkennung zu entwickeln und über GitOps-Workflows mit Ansible in einem Debian-basierten HomeLab bereitzustellen, kombiniert mit `iptables` und `rsyslog` für Netzwerksicherheit. Diese Übungen stärken die Automatisierung und Sicherheit deines Setups. Wiederhole sie, um LSTM und GitOps zu verinnerlichen.

**Nächste Schritte**:
- Erkunde andere Zeitreihen-Modelle (z. B. Autoencoder, Transformer).
- Integriere OpenTelemetry für Tracing (z. B. mit Jaeger).
- Vertiefe dich in Sicherheits-Checks mit `checkov` für Konfigurationen.

**Quellen**: TensorFlow Docs, Ansible Docs, Debian Security Docs.
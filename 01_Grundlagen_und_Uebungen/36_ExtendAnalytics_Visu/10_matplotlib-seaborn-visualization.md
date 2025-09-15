# Praxisorientierte Anleitung: Datenvisualisierung mit Matplotlib und Seaborn für Netzwerksicherheitsdaten in Python im Debian-basierten HomeLab

## Einführung
Matplotlib und Seaborn sind leistungsstarke Python-Bibliotheken für Datenvisualisierung. Matplotlib bietet flexible, grundlegende Plotting-Funktionen, während Seaborn auf Matplotlib aufbaut und statistische Visualisierungen mit ansprechendem Design erleichtert. Diese Anleitung zeigt, wie man Matplotlib und Seaborn in einem Debian-basierten HomeLab (z. B. mit LXC-Containern) verwendet, um Netzwerksicherheitsdaten (z. B. Netzwerklogs) aus JSON-, YAML- und TOML-Dateien zu visualisieren. Die Visualisierungen umfassen Zeitreihenplots, Heatmaps und Verteilungen, um Anomalien zu identifizieren. Die Bereitstellung erfolgt lokal ohne GitOps, mit Fokus auf Python und Debian. Ziel ist es, dir praktische Schritte zur Erstellung aussagekräftiger Visualisierungen zu vermitteln.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern (z. B. `game-container`).
- Installierte Tools: `python3`, `iptables`, `rsyslog`.
- Python-Bibliotheken: `matplotlib`, `seaborn`, `pandas`, `pyyaml`, `toml`, `json`.
- Grundkenntnisse in Python und Netzwerksicherheit.
- Testumgebung ohne Produktionsdaten.
- Beispiel-Netzwerklogs in JSON, YAML und TOML.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für Matplotlib und Seaborn mit JSON, YAML und TOML:

1. **Matplotlib**:
   - **Funktion**: Erzeugt grundlegende Visualisierungen wie Liniendiagramme, Scatter-Plots und Balkendiagramme.
   - **Vorteile**: Flexibel, anpassbar, breite Unterstützung.
   - **Nachteile**: Erfordert mehr Code für komplexe Designs.
2. **Seaborn**:
   - **Funktion**: Bietet statistische Visualisierungen wie Heatmaps, Boxplots und Verteilungen.
   - **Vorteile**: Vereinfacht komplexe Plots, ansprechende Designs, Pandas-Integration.
   - **Nachteile**: Weniger flexibel als Matplotlib für benutzerdefinierte Anpassungen.
3. **JSON, YAML, TOML**:
   - **JSON**: Ideal für strukturierte Netzwerklogs (z. B. Zeitreihen).
   - **YAML**: Geeignet für Konfigurationen, lesbar, aber einrückungssensitiv.
   - **TOML**: Minimalistisch, für einfache Daten oder Einstellungen.
4. **Netzwerksicherheit**:
   - Visualisiere Netzwerklogs (z. B. Bytes pro Minute, Port-Verkehr) zur Anomalieerkennung.

## Übungen zum Verinnerlichen

### Übung 1: Visualisierung von JSON-Logs mit Matplotlib und Seaborn
**Ziel**: Erstelle Visualisierungen für Netzwerklogs in JSON.

1. **Schritt 1**: Erstelle eine JSON-Datei mit Netzwerklogs (`data/network_logs.json`):
   ```json
   [
       {"timestamp": "2025-09-15T07:51:00", "source_ip": "192.168.1.10", "port": 80, "bytes": 500},
       {"timestamp": "2025-09-15T07:52:00", "source_ip": "192.168.1.11", "port": 22, "bytes": 200},
       {"timestamp": "2025-09-15T07:53:00", "source_ip": "192.168.1.12", "port": 80, "bytes": 10000}
   ]
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für Visualisierungen (`scripts/visualize_json.py`):
   ```python
   import pandas as pd
   import matplotlib.pyplot as plt
   import seaborn as sns
   import json

   # JSON-Daten laden
   with open('/app/data/network_logs.json', 'r') as f:
       data = json.load(f)
   df = pd.DataFrame(data)
   df['timestamp'] = pd.to_datetime(df['timestamp'])

   # Matplotlib: Zeitreihenplot
   plt.figure(figsize=(10, 6))
   plt.plot(df['timestamp'], df['bytes'], marker='o')
   plt.title('Netzwerkverkehr (Bytes) über Zeit')
   plt.xlabel('Zeit')
   plt.ylabel('Bytes')
   plt.grid(True)
   plt.savefig('/app/plots/timeseries_json.png')
   plt.close()

   # Seaborn: Verteilung der Bytes
   plt.figure(figsize=(10, 6))
   sns.histplot(df['bytes'], kde=True)
   plt.title('Verteilung der Netzwerk-Bytes')
   plt.xlabel('Bytes')
   plt.ylabel('Häufigkeit')
   plt.savefig('/app/plots/distribution_json.png')
   plt.close()
   print("JSON Visualisierungen erstellt: timeseries_json.png, distribution_json.png")
   ```
3. **Schritt 3**: Installiere Abhängigkeiten und führe das Skript lokal aus:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip
   pip install pandas matplotlib seaborn
   mkdir -p /app/data /app/plots
   # Kopiere network_logs.json und visualize_json.py nach /app/data bzw. /app/scripts
   python3 /app/scripts/visualize_json.py
   # Überprüfe die Ausgabe
   ls /app/plots
   ```
   **Erwartete Ausgabe**: Zwei PNG-Dateien (`timeseries_json.png`, `distribution_json.png`) in `/app/plots`.

**Reflexion**: Warum ist JSON für Netzwerklogs geeignet? Wie helfen Zeitreihenplots und Verteilungen bei der Anomalieerkennung?

### Übung 2: Visualisierung von YAML-Logs mit Matplotlib und Seaborn
**Ziel**: Erstelle Visualisierungen für Netzwerklogs in YAML.

1. **Schritt 1**: Erstelle eine YAML-Datei mit Netzwerklogs (`data/network_logs.yaml`):
   ```yaml
   logs:
     - timestamp: 2025-09-15T07:51:00
       source_ip: 192.168.1.10
       port: 80
       bytes: 500
     - timestamp: 2025-09-15T07:52:00
       source_ip: 192.168.1.11
       port: 22
       bytes: 200
     - timestamp: 2025-09-15T07:53:00
       source_ip: 192.168.1.12
       port: 80
       bytes: 10000
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für Visualisierungen (`scripts/visualize_yaml.py`):
   ```python
   import pandas as pd
   import matplotlib.pyplot as plt
   import seaborn as sns
   import yaml

   # YAML-Daten laden
   with open('/app/data/network_logs.yaml', 'r') as f:
       data = yaml.safe_load(f)
   df = pd.DataFrame(data['logs'])
   df['timestamp'] = pd.to_datetime(df['timestamp'])

   # Matplotlib: Zeitreihenplot
   plt.figure(figsize=(10, 6))
   plt.plot(df['timestamp'], df['bytes'], marker='o', color='blue')
   plt.title('Netzwerkverkehr (Bytes) über Zeit (YAML)')
   plt.xlabel('Zeit')
   plt.ylabel('Bytes')
   plt.grid(True)
   plt.savefig('/app/plots/timeseries_yaml.png')
   plt.close()

   # Seaborn: Heatmap für Port-Bytes
   pivot = df.pivot_table(values='bytes', index='port', columns='source_ip', fill_value=0)
   plt.figure(figsize=(10, 6))
   sns.heatmap(pivot, annot=True, cmap='Blues')
   plt.title('Bytes nach Port und Source IP')
   plt.savefig('/app/plots/heatmap_yaml.png')
   plt.close()
   print("YAML Visualisierungen erstellt: timeseries_yaml.png, heatmap_yaml.png")
   ```
3. **Schritt 3**: Installiere Abhängigkeiten und führe das Skript lokal aus:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip
   pip install pandas matplotlib seaborn pyyaml
   mkdir -p /app/data /app/plots
   # Kopiere network_logs.yaml und visualize_yaml.py nach /app/data bzw. /app/scripts
   python3 /app/scripts/visualize_yaml.py
   # Überprüfe die Ausgabe
   ls /app/plots
   ```
   **Erwartete Ausgabe**: Zwei PNG-Dateien (`timeseries_yaml.png`, `heatmap_yaml.png`) in `/app/plots`.

**Reflexion**: Wie unterstützt YAML die Strukturierung von Netzwerklogs? Warum ist eine Heatmap nützlich für die Analyse von Port-Verkehr?

### Übung 3: Visualisierung von TOML-Logs mit Matplotlib und Seaborn
**Ziel**: Erstelle Visualisierungen für Netzwerklogs in TOML.

1. **Schritt 1**: Erstelle eine TOML-Datei mit Netzwerklogs (`data/network_logs.toml`):
   ```toml
   [[logs]]
   timestamp = "2025-09-15T07:51:00"
   source_ip = "192.168.1.10"
   port = 80
   bytes = 500

   [[logs]]
   timestamp = "2025-09-15T07:52:00"
   source_ip = "192.168.1.11"
   port = 22
   bytes = 200

   [[logs]]
   timestamp = "2025-09-15T07:53:00"
   source_ip = "192.168.1.12"
   port = 80
   bytes = 10000
   ```
2. **Schritt 2**: Erstelle ein Python-Skript für Visualisierungen (`scripts/visualize_toml.py`):
   ```python
   import pandas as pd
   import matplotlib.pyplot as plt
   import seaborn as sns
   import toml

   # TOML-Daten laden
   with open('/app/data/network_logs.toml', 'r') as f:
       data = toml.load(f)
   df = pd.DataFrame(data['logs'])
   df['timestamp'] = pd.to_datetime(df['timestamp'])

   # Matplotlib: Balkendiagramm
   plt.figure(figsize=(10, 6))
   plt.bar(df['source_ip'], df['bytes'])
   plt.title('Bytes pro Source IP (TOML)')
   plt.xlabel('Source IP')
   plt.ylabel('Bytes')
   plt.xticks(rotation=45)
   plt.savefig('/app/plots/bar_toml.png')
   plt.close()

   # Seaborn: Boxplot
   plt.figure(figsize=(10, 6))
   sns.boxplot(x='port', y='bytes', data=df)
   plt.title('Bytes-Verteilung nach Port')
   plt.savefig('/app/plots/boxplot_toml.png')
   plt.close()
   print("TOML Visualisierungen erstellt: bar_toml.png, boxplot_toml.png")
   ```
3. **Schritt 3**: Installiere Abhängigkeiten und führe das Skript lokal aus:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip
   pip install pandas matplotlib seaborn toml
   mkdir -p /app/data /app/plots
   # Kopiere network_logs.toml und visualize_toml.py nach /app/data bzw. /app/scripts
   python3 /app/scripts/visualize_toml.py
   # Überprüfe die Ausgabe
   ls /app/plots
   ```
   **Erwartete Ausgabe**: Zwei PNG-Dateien (`bar_toml.png`, `boxplot_toml.png`) in `/app/plots`.

**Reflexion**: Warum ist TOML für einfache Netzwerklogs geeignet? Wie helfen Balkendiagramme und Boxplots bei der Anomalieerkennung?

## Tipps für den Erfolg
- **Format-Auswahl**: Nutze JSON für strukturierte Logs, YAML für komplexe Daten, TOML für minimalistische Einstellungen.
- **Visualisierung**: Wähle Matplotlib für flexible Plots, Seaborn für statistische Visualisierungen.
- **Sicherheit**: Validiere Daten vor der Visualisierung, um fehlerhafte Plots zu vermeiden.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` und Python-Logs bei Problemen.
- **Best Practices**: Speichere Visualisierungen in `/app/plots`, teste lokal, nutze Pandas für Datenverarbeitung.
- **2025-Fokus**: Erkunde interaktive Visualisierungen mit Plotly oder Bokeh.

## Fazit
Du hast gelernt, Matplotlib und Seaborn zu nutzen, um Netzwerksicherheitsdaten aus JSON-, YAML- und TOML-Dateien in einem Debian-basierten HomeLab zu visualisieren. Die Übungen zeigen, wie Zeitreihenplots, Heatmaps, Balkendiagramme und Boxplots Anomalien aufdecken. Wiederhole sie, um die Techniken zu verinnerlichen.

**Nächste Schritte**:
- Integriere OpenTelemetry für Tracing-Datenvisualisierung.
- Erkunde interaktive Visualisierungen mit Plotly.
- Vertiefe dich in Sicherheits-Checks mit `checkov` für Datenquellen.

**Quellen**: Matplotlib Docs, Seaborn Docs, Pandas Docs, PyYAML Docs, TOML Docs.
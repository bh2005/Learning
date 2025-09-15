# Praxisorientierte Anleitung: CDP und LLDP-Daten (inklusive LLDP-TLVs) in TOML mit Python parsen und interaktive Netzwerkkarte mit Plotly erstellen

## Einführung
CDP (Cisco Discovery Protocol) und LLDP (Link Layer Discovery Protocol) sind Layer-2-Protokolle, die Geräte in einem Netzwerk entdecken und Informationen wie Gerätenamen, IP-Adressen, Ports und Capabilities austauschen. Diese Anleitung zeigt, wie man CDP- und LLDP-Pakete (inklusive LLDP-TLVs wie Capabilities) mit Python (Scapy) erfasst, die Daten in TOML speichert und daraus eine **interaktive Netzwerkkarte** mit Plotly erstellt. Der Fokus liegt auf einem Debian-basierten HomeLab (z. B. mit LXC-Containern), wo Pakete gesnifft, verarbeitet und interaktiv visualisiert werden. Ziel ist es, dir praktische Schritte zur Netzwerktopologie-Erfassung mit interaktiven Visualisierungen zu vermitteln, um Konfigurationen und Gerätefähigkeiten zu analysieren.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und Netzwerkzugriff (z. B. auf Switches/Router mit CDP/LLDP).
- Installierte Tools: `python3`, `scapy`, `networkx`, `plotly`, `toml`.
- Grundkenntnisse in Python und Netzwerksicherheit.
- Testumgebung: Verbinde dein HomeLab mit einem CDP/LLDP-fähigen Netzwerk (z. B. Cisco-Switch).
- Führe als Root aus (für Raw-Sockets): `sudo python3 script.py`.
- Browser für interaktive Plotly-Visualisierungen (HTML-Ausgabe).

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für CDP/LLDP, LLDP-TLVs, TOML und Plotly:

1. **CDP und LLDP**:
   - **CDP**: Cisco-proprietary, sendet alle 60 Sekunden, enthält Device-ID, IP, Port, Capabilities.
   - **LLDP**: Standard (IEEE 802.1AB), vendor-neutral; TLV-Struktur (Type-Length-Value) für flexible Daten.
   - **LLDP-TLVs**: Type-Length-Value-Felder, z. B. `Capabilities` (System Capabilities TLV) gibt an, ob ein Gerät Router, Switch, Host etc. ist.
   - **Erfassung**: Mit Scapy sniffen, filtern auf Multicast-MACs (CDP: 01:00:0c:cc:cc:cc, LLDP: 01:80:c2:00:00:0e).
2. **TOML**:
   - **Eignung**: Minimalistisch für hierarchische Daten (z. B. [devices] mit Capabilities); lesbar, kompakt.
   - **Vorteile**: Einfach zu parsen, unterstützt Tabellen und Arrays.
3. **Plotly**:
   - **Funktion**: Erstellt interaktive Visualisierungen (z. B. Graphen), die in HTML gerendert werden.
   - **Vorteile**: Interaktivität (Zoom, Hover, Klick), moderne Designs, browserbasiert.
   - **Nachteile**: Höherer Overhead als Matplotlib für einfache Plots.
4. **Netzwerkkarte**:
   - Graph mit NetworkX (Nodes: Geräte, Edges: Verbindungen), interaktiv mit Plotly visualisiert.

## Übungen zum Verinnerlichen

### Übung 1: CDP/LLDP-Pakete erfassen und LLDP-TLVs (Capabilities) parsen
**Ziel**: Erfasse Pakete mit Scapy und extrahiere LLDP-Capabilities.

1. **Schritt 1**: Installiere Abhängigkeiten:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip
   pip install scapy networkx plotly toml
   ```
2. **Schritt 2**: Erstelle ein Python-Skript zum Erfassen und Parsen (`scripts/cdp_lldp_sniffer_extended.py`):
   ```python
   from scapy.all import sniff, Ether
   from scapy.contrib.cdp import CDPHeader
   from scapy.contrib.lldp import LLDPDU, LLDPDUSystemCapabilities
   import toml

   discovered = {}  # Dict für Geräte

   def decode_capabilities(capabilities):
       """Dekodiert LLDP-Capabilities in lesbare Form."""
       caps = []
       if capabilities & 0x01: caps.append("Repeater")
       if capabilities & 0x02: caps.append("Bridge")
       if capabilities & 0x04: caps.append("Access Point")
       if capabilities & 0x08: caps.append("Router")
       if capabilities & 0x10: caps.append("Telephone")
       if capabilities & 0x20: caps.append("DOCSIS Cable Device")
       if capabilities & 0x40: caps.append("Station Only")
       if capabilities & 0x80: caps.append("Other")
       return caps if caps else ["None"]

   def process_packet(packet):
       if Ether in packet:
           if packet[Ether].dst == '01:00:0c:cc:cc:cc':  # CDP
               if CDPHeader in packet:
                   device_id = packet[CDPHeader].getlayer('CDPMsgDeviceID').val.decode('utf-8', errors='ignore') if 'CDPMsgDeviceID' in packet else 'Unknown'
                   ip = packet[CDPHeader].getlayer('CDPMsgAddr').addr[0] if 'CDPMsgAddr' in packet else 'Unknown'
                   port = packet[CDPHeader].getlayer('CDPMsgPortID').iface.decode('utf-8', errors='ignore') if 'CDPMsgPortID' in packet else 'Unknown'
                   discovered[device_id] = {'ip': ip, 'port': port, 'type': 'CDP', 'capabilities': ['Unknown']}
                   print(f"CDP: Device {device_id}, IP {ip}, Port {port}")
           elif packet[Ether].dst == '01:80:c2:00:00:0e':  # LLDP
               if LLDPDU in packet:
                   chassis_id = packet[LLDPDU].getlayer('LLDPDUChassisID').id.decode('utf-8', errors='ignore') if 'LLDPDUChassisID' in packet else 'Unknown'
                   port_id = packet[LLDPDU].getlayer('LLDPDUPortID').id.decode('utf-8', errors='ignore') if 'LLDPDUPortID' in packet else 'Unknown'
                   system_name = packet[LLDPDU].getlayer('LLDPDUSystemName').system_name.decode('utf-8', errors='ignore') if 'LLDPDUSystemName' in packet else chassis_id
                   capabilities = packet[LLDPDU].getlayer('LLDPDUSystemCapabilities')
                   caps = decode_capabilities(capabilities.capabilities) if capabilities else ['None']
                   discovered[system_name] = {'chassis': chassis_id, 'port': port_id, 'type': 'LLDP', 'capabilities': caps}
                   print(f"LLDP: Device {system_name}, Chassis {chassis_id}, Port {port_id}, Capabilities {caps}")

   # Sniff 10 Pakete
   packets = sniff(count=10, filter="ether dst 01:00:0c:cc:cc:cc or ether dst 01:80:c2:00:00:0e", prn=process_packet)
   print("Discovered devices:", discovered)
   ```
3. **Schritt 3**: Führe das Skript aus (als Root):
   ```bash
   sudo python3 /app/scripts/cdp_lldp_sniffer_extended.py
   ```
   **Erwartete Ausgabe**: Gedruckte Geräteinformationen, inklusive LLDP-Capabilities (z. B. "Bridge", "Router").

**Reflexion**: Wie helfen LLDP-Capabilities bei der Geräteidentifikation? Warum ist die TLV-Struktur flexibel?

### Übung 2: CDP/LLDP-Daten mit Capabilities in TOML speichern
**Ziel**: Speichere geparste Daten, inklusive Capabilities, in TOML.

1. **Schritt 1**: Erstelle ein Python-Skript zum Erfassen und Speichern in TOML (`scripts/cdp_lldp_to_toml_extended.py`):
   ```python
   from scapy.all import sniff, Ether
   from scapy.contrib.cdp import CDPHeader
   from scapy.contrib.lldp import LLDPDU, LLDPDUSystemCapabilities
   import toml

   discovered = {}

   def decode_capabilities(capabilities):
       """Dekodiert LLDP-Capabilities in lesbare Form."""
       caps = []
       if capabilities & 0x01: caps.append("Repeater")
       if capabilities & 0x02: caps.append("Bridge")
       if capabilities & 0x04: caps.append("Access Point")
       if capabilities & 0x08: caps.append("Router")
       if capabilities & 0x10: caps.append("Telephone")
       if capabilities & 0x20: caps.append("DOCSIS Cable Device")
       if capabilities & 0x40: caps.append("Station Only")
       if capabilities & 0x80: caps.append("Other")
       return caps if caps else ["None"]

   def process_packet(packet):
       if Ether in packet:
           if packet[Ether].dst == '01:00:0c:cc:cc:cc':  # CDP
               if CDPHeader in packet:
                   device_id = packet[CDPHeader].getlayer('CDPMsgDeviceID').val.decode('utf-8', errors='ignore') if 'CDPMsgDeviceID' in packet else 'Unknown'
                   ip = packet[CDPHeader].getlayer('CDPMsgAddr').addr[0] if 'CDPMsgAddr' in packet else 'Unknown'
                   port = packet[CDPHeader].getlayer('CDPMsgPortID').iface.decode('utf-8', errors='ignore') if 'CDPMsgPortID' in packet else 'Unknown'
                   discovered[device_id] = {'ip': ip, 'port': port, 'type': 'CDP', 'capabilities': ['Unknown']}
           elif packet[Ether].dst == '01:80:c2:00:00:0e':  # LLDP
               if LLDPDU in packet:
                   chassis_id = packet[LLDPDU].getlayer('LLDPDUChassisID').id.decode('utf-8', errors='ignore') if 'LLDPDUChassisID' in packet else 'Unknown'
                   port_id = packet[LLDPDU].getlayer('LLDPDUPortID').id.decode('utf-8', errors='ignore') if 'LLDPDUPortID' in packet else 'Unknown'
                   system_name = packet[LLDPDU].getlayer('LLDPDUSystemName').system_name.decode('utf-8', errors='ignore') if 'LLDPDUSystemName' in packet else chassis_id
                   capabilities = packet[LLDPDU].getlayer('LLDPDUSystemCapabilities')
                   caps = decode_capabilities(capabilities.capabilities) if capabilities else ['None']
                   discovered[system_name] = {'chassis': chassis_id, 'port': port_id, 'type': 'LLDP', 'capabilities': caps}

   # Sniff 10 Pakete
   packets = sniff(count=10, filter="ether dst 01:00:0c:cc:cc:cc or ether dst 01:80:c2:00:00:0e", prn=process_packet)

   # Speichere in TOML
   toml_data = {'devices': discovered}
   with open('/app/network_map.toml', 'w') as f:
       toml.dump(toml_data, f)
   print("TOML-Datei erstellt: /app/network_map.toml")
   ```
2. **Schritt 2**: Führe das Skript aus:
   ```bash
   sudo python3 /app/scripts/cdp_lldp_to_toml_extended.py
   cat /app/network_map.toml
   ```
   **Erwartete Ausgabe**: TOML-Datei mit Gerätedaten, inklusive Capabilities, z. B.:
   ```
   [devices.Switch1]
   ip = "192.168.1.1"
   port = "GigabitEthernet0/1"
   type = "CDP"
   capabilities = ["Unknown"]

   [devices.Router1]
   chassis = "00:11:22:33:44:55"
   port = "Eth0/1"
   type = "LLDP"
   capabilities = ["Router", "Bridge"]
   ```

**Reflexion**: Wie verbessern Capabilities die Netzwerkdokumentation? Warum ist TOML für hierarchische Daten geeignet?

### Übung 3: Interaktive Netzwerkkarte aus TOML mit Plotly erstellen
**Ziel**: Erstelle einen interaktiven Graph aus TOML-Daten mit Capabilities-Labels.

1. **Schritt 1**: Erstelle ein Python-Skript für die interaktive Netzwerkkarte (`scripts/create_network_map_plotly.py`):
   ```python
   import toml
   import networkx as nx
   import plotly.graph_objects as go

   # Lade TOML
   with open('/app/network_map.toml', 'r') as f:
       data = toml.load(f)

   G = nx.Graph()

   # Nodes und Edges hinzufügen
   for device, info in data['devices'].items():
       capabilities = info.get('capabilities', ['Unknown'])
       label = f"{device}<br>{', '.join(capabilities)}<br>{info.get('ip', info.get('chassis', 'Unknown'))}"
       G.add_node(device, label=label, ip=info.get('ip', info.get('chassis', 'Unknown')))
       if 'port' in info:
           neighbor = f"{device}_neighbor"  # Platzhalter; erweitere mit realen Daten
           G.add_edge(device, neighbor, port=info['port'])

   # Plotly Graph erstellen
   pos = nx.spring_layout(G)
   edge_x = []
   edge_y = []
   edge_text = []
   for edge in G.edges(data=True):
       x0, y0 = pos[edge[0]]
       x1, y1 = pos[edge[1]]
       edge_x.extend([x0, x1, None])
       edge_y.extend([y0, y1, None])
       edge_text.append(edge[2].get('port', ''))

   edge_trace = go.Scatter(
       x=edge_x, y=edge_y,
       line=dict(width=0.5, color='#888'),
       hoverinfo='text',
       text=edge_text,
       mode='lines')

   node_x = []
   node_y = []
   node_text = []
   for node in G.nodes(data=True):
       x, y = pos[node[0]]
       node_x.append(x)
       node_y.append(y)
       node_text.append(node[1]['label'])

   node_trace = go.Scatter(
       x=node_x, y=node_y,
       mode='markers+text',
       hoverinfo='text',
       text=node_text,
       textposition='top center',
       marker=dict(size=20, color='lightblue'))

   fig = go.Figure(data=[edge_trace, node_trace],
                   layout=go.Layout(
                       title='Interaktive Netzwerkkarte aus CDP/LLDP-Daten',
                       showlegend=False,
                       hovermode='closest',
                       margin=dict(b=20, l=5, r=5, t=40),
                       xaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
                       yaxis=dict(showgrid=False, zeroline=False, showticklabels=False)))

   fig.write_html('/app/network_map_plotly.html')
   print("Interaktive Netzwerkkarte erstellt: /app/network_map_plotly.html")
   ```
2. **Schritt 2**: Führe das Skript aus:
   ```bash
   pip install networkx plotly toml
   python3 /app/scripts/create_network_map_plotly.py
   # Öffne /app/network_map_plotly.html in einem Browser
   ```
   **Erwartete Ausgabe**: HTML-Datei (`/app/network_map_plotly.html`) mit interaktivem Graph (Nodes: Geräte mit Capabilities und IP/Chassis, Edges: Verbindungen mit Port-Labels). Du kannst zoomen, schweben (Hover) für Details und klicken.

**Reflexion**: Wie verbessert Plotly die Interaktivität gegenüber Matplotlib? Warum eignet sich HTML für Netzwerkkarten?

## Tipps für den Erfolg
- **Erfassung**: Verwende `sudo` für Scapy; filtere auf Multicast-MACs, um Overhead zu minimieren.
- **LLDP-TLVs**: Erweitere für weitere TLVs (z. B. Management Address, VLAN ID).
- **TOML**: Nutze Arrays für Capabilities; validiere mit Pydantic für Robustheit.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` bei Sniffing-Problemen; teste mit Wireshark.
- **Best Practices**: Speichere TOML und HTML in `/app/`, teste lokal, öffne HTML im Browser.
- **2025-Fokus**: Integriere OpenTelemetry für Tracing von CDP/LLDP-Daten.

## Fazit
Du hast gelernt, CDP- und LLDP-Pakete (inklusive LLDP-Capabilities) mit Scapy zu erfassen, in TOML zu speichern und eine interaktive Netzwerkkarte mit Plotly zu erstellen. Die Übungen ermöglichen eine detaillierte Topologie-Erfassung in deinem HomeLab mit interaktiver Visualisierung. Wiederhole sie, um die Techniken zu verinnerlichen.

**Nächste Schritte**:
- Erweitere mit weiteren LLDP-TLVs (z. B. Management Address).
- Integriere OpenTelemetry für Tracing.
- Erkunde Plotly-Dash für dynamische Dashboards.

**Quellen**: Scapy Docs, NetworkX Docs, Plotly Docs, TOML Docs.
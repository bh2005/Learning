# Praxisorientierte Anleitung: CDP und LLDP-Daten (inklusive LLDP-TLVs) in TOML mit Python parsen und dynamisches Dashboard mit Plotly-Dash und Klick-Events erstellen

## Einführung
CDP (Cisco Discovery Protocol) und LLDP (Link Layer Discovery Protocol) sind Layer-2-Protokolle, die Geräte in einem Netzwerk entdecken und Informationen wie Gerätenamen, IP-Adressen, Ports und Capabilities austauschen. Diese Anleitung zeigt, wie man CDP- und LLDP-Pakete (inklusive LLDP-TLVs wie Capabilities) mit Python (Scapy) erfasst, die Daten in TOML speichert und ein **dynamisches Dashboard** mit Plotly-Dash erstellt, das erweiterte Interaktionen durch Dash-Callbacks (z. B. Klick-Events zur Anzeige von Gerätedetails) unterstützt. Der Fokus liegt auf einem Debian-basierten HomeLab (z. B. mit LXC-Containern), wo Pakete gesnifft, verarbeitet und interaktiv visualisiert werden. Ziel ist es, dir praktische Schritte zur Netzwerktopologie-Erfassung mit einem interaktiven Dashboard zu vermitteln, das Filter, Tooltips und Klick-Events für detaillierte Analysen bietet.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und Netzwerkzugriff (z. B. auf Switches/Router mit CDP/LLDP).
- Installierte Tools: `python3`, `scapy`, `networkx`, `plotly`, `dash`, `toml`.
- Grundkenntnisse in Python, Netzwerksicherheit und Webentwicklung.
- Testumgebung: Verbinde dein HomeLab mit einem CDP/LLDP-fähigen Netzwerk (z. B. Cisco-Switch).
- Führe als Root aus (für Raw-Sockets): `sudo python3 script.py`.
- Browser für Dash-Dashboard (http://127.0.0.1:8050).
- Port 8050 offen für Dash-Server.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für CDP/LLDP, LLDP-TLVs, TOML und Plotly-Dash:

1. **CDP und LLDP**:
   - **CDP**: Cisco-proprietary, sendet alle 60 Sekunden, enthält Device-ID, IP, Port, Capabilities.
   - **LLDP**: Standard (IEEE 802.1AB), vendor-neutral; TLV-Struktur (Type-Length-Value) für flexible Daten.
   - **LLDP-TLVs**: Type-Length-Value-Felder, z. B. `Capabilities` gibt an, ob ein Gerät Router, Switch, Host etc. ist.
   - **Erfassung**: Mit Scapy sniffen, filtern auf Multicast-MACs (CDP: 01:00:0c:cc:cc:cc, LLDP: 01:80:c2:00:00:0e).
2. **TOML**:
   - **Eignung**: Minimalistisch für hierarchische Daten (z. B. [devices] mit Capabilities); lesbar, kompakt.
   - **Vorteile**: Einfach zu parsen, unterstützt Tabellen und Arrays.
3. **Plotly-Dash**:
   - **Funktion**: Framework für interaktive, webbasierte Dashboards mit Plotly-Visualisierungen.
   - **Dash-Callbacks**: Ermöglichen dynamische Updates basierend auf Benutzerinteraktionen (z. B. Klick-Events).
   - **Vorteile**: Interaktivität (Filter, Dropdowns, Tooltips, Klicks), browserbasiert, Python-basiert.
   - **Nachteile**: Erfordert lokalen Server (z. B. Port 8050), höherer Overhead als statische Plots.
4. **Netzwerkkarte**:
   - Graph mit NetworkX (Nodes: Geräte, Edges: Verbindungen), dynamisch mit Dash visualisiert.

## Übungen zum Verinnerlichen

### Übung 1: CDP/LLDP-Pakete erfassen und LLDP-TLVs (Capabilities) parsen
**Ziel**: Erfasse Pakete mit Scapy und extrahiere LLDP-Capabilities.

1. **Schritt 1**: Installiere Abhängigkeiten:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip
   pip install scapy networkx plotly dash toml
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

### Übung 3: Dynamisches Dashboard mit Plotly-Dash und Klick-Events erstellen
**Ziel**: Erstelle ein interaktives Dashboard mit Klick-Events zur Anzeige von Gerätedetails.

1. **Schritt 1**: Erstelle ein Python-Skript für das Dash-Dashboard (`scripts/create_network_dashboard_dash_click.py`):
   ```python
   import toml
   import networkx as nx
   import plotly.graph_objects as go
   from dash import Dash, dcc, html, Input, Output

   # Lade TOML
   with open('/app/network_map.toml', 'r') as f:
       data = toml.load(f)

   # Erstelle Graph
   G = nx.Graph()
   for device, info in data['devices'].items():
       capabilities = info.get('capabilities', ['Unknown'])
       label = f"Device: {device}<br>Capabilities: {', '.join(capabilities)}<br>{info.get('ip', info.get('chassis', 'Unknown'))}"
       G.add_node(device, label=label, ip=info.get('ip', info.get('chassis', 'Unknown')), details=info)
       if 'port' in info:
           neighbor = f"{device}_neighbor"  # Platzhalter; erweitere mit realen Daten
           G.add_edge(device, neighbor, port=info['port'])

   # Erstelle Plotly-Graph
   def create_plotly_graph(selected_type=None):
       filtered_G = nx.Graph()
       for node, attrs in G.nodes(data=True):
           if selected_type is None or data['devices'][node]['type'] == selected_type:
               filtered_G.add_node(node, **attrs)
       for edge in G.edges(data=True):
           if selected_type is None or (data['devices'][edge[0]]['type'] == selected_type and data['devices'].get(edge[1], {}).get('type') == selected_type):
               filtered_G.add_edge(edge[0], edge[1], **edge[2])

       pos = nx.spring_layout(filtered_G)
       edge_x = []
       edge_y = []
       edge_text = []
       for edge in filtered_G.edges(data=True):
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
       node_customdata = []
       for node in filtered_G.nodes(data=True):
           x, y = pos[node[0]]
           node_x.append(x)
           node_y.append(y)
           node_text.append(node[1]['label'])
           node_customdata.append(node[0])  # Device-ID für Klick-Events

       node_trace = go.Scatter(
           x=node_x, y=node_y,
           mode='markers+text',
           hoverinfo='text',
           text=node_text,
           textposition='top center',
           customdata=node_customdata,
           marker=dict(size=20, color='lightblue'))

       return [edge_trace, node_trace]

   # Dash-App
   app = Dash(__name__)
   app.layout = html.Div([
       html.H1("Netzwerk-Dashboard: CDP/LLDP-Topologie mit Klick-Events"),
       dcc.Dropdown(
           id='type-filter',
           options=[
               {'label': 'Alle Geräte', 'value': 'all'},
               {'label': 'CDP Geräte', 'value': 'CDP'},
               {'label': 'LLDP Geräte', 'value': 'LLDP'}
           ],
           value='all',
           style={'width': '50%'}
       ),
       dcc.Graph(id='network-graph'),
       html.Div(id='device-details', style={'marginTop': 20, 'padding': 10, 'border': '1px solid #ddd'})
   ])

   @app.callback(
       [Output('network-graph', 'figure'), Output('device-details', 'children')],
       [Input('type-filter', 'value'), Input('network-graph', 'clickData')]
   )
   def update_graph_and_details(selected_type, click_data):
       if selected_type == 'all':
           selected_type = None
       traces = create_plotly_graph(selected_type)
       figure = {
           'data': traces,
           'layout': go.Layout(
               title='Interaktive Netzwerkkarte',
               showlegend=False,
               hovermode='closest',
               margin=dict(b=20, l=5, r=5, t=40),
               xaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
               yaxis=dict(showgrid=False, zeroline=False, showticklabels=False)
           )
       }

       # Gerätedetails bei Klick
       details = "Klicke auf ein Gerät, um Details anzuzeigen."
       if click_data:
           device_id = click_data['points'][0]['customdata']
           if device_id in data['devices']:
               info = data['devices'][device_id]
               details = [
                   html.H3(f"Gerätedetails: {device_id}"),
                   html.P(f"Typ: {info['type']}"),
                   html.P(f"IP/Chassis: {info.get('ip', info.get('chassis', 'Unknown'))}"),
                   html.P(f"Port: {info.get('port', 'Unknown')}"),
                   html.P(f"Capabilities: {', '.join(info.get('capabilities', ['Unknown']))}")
               ]

       return figure, details

   if __name__ == '__main__':
       app.run_server(debug=True, host='0.0.0.0', port=8050)
   print("Dash-Dashboard gestartet: http://127.0.0.1:8050")
   ```
2. **Schritt 2**: Führe das Skript aus:
   ```bash
   pip install networkx plotly dash toml
   python3 /app/scripts/create_network_dashboard_dash_click.py
   # Öffne http://127.0.0.1:8050 in einem Browser
   ```
   **Erwartete Ausgabe**: Ein webbasiertes Dashboard mit einer interaktiven Netzwerkkarte (Nodes: Geräte mit Capabilities und IP/Chassis, Edges: Verbindungen mit Port-Labels). Nutze das Dropdown, um nach CDP/LLDP zu filtern, schwebe über Nodes/Edges für Tooltips und klicke auf Nodes, um Gerätedetails (Typ, IP/Chassis, Port, Capabilities) anzuzeigen.

**Reflexion**: Wie verbessern Klick-Events die Benutzerinteraktion? Warum sind Dash-Callbacks für dynamische Dashboards nützlich?

## Tipps für den Erfolg
- **Erfassung**: Verwende `sudo` für Scapy; filtere auf Multicast-MACs, um Overhead zu minimieren.
- **LLDP-TLVs**: Erweitere für weitere TLVs (z. B. Management Address, VLAN ID).
- **TOML**: Nutze Arrays für Capabilities; validiere mit Pydantic für Robustheit.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` bei Sniffing-Problemen; teste mit Wireshark. Stelle sicher, dass Port 8050 offen ist.
- **Best Practices**: Speichere TOML in `/app/`, teste lokal, öffne Dashboard im Browser.
- **2025-Fokus**: Integriere OpenTelemetry für Echtzeit-Tracing in Dash.

## Fazit
Du hast gelernt, CDP- und LLDP-Pakete (inklusive LLDP-Capabilities) mit Scapy zu erfassen, in TOML zu speichern und ein dynamisches Dashboard mit Plotly-Dash zu erstellen, das Klick-Events zur Anzeige von Gerätedetails unterstützt. Die Übungen ermöglichen eine detaillierte Topologie-Erfassung mit interaktiven Filtern, Tooltips und Klick-Interaktionen in deinem HomeLab. Wiederhole sie, um die Techniken zu verinnerlichen.

**Nächste Schritte**:
- Erweitere mit weiteren LLDP-TLVs (z. B. Management Address).
- Integriere OpenTelemetry für Echtzeit-Tracing.
- Erkunde weitere Dash-Features (z. B. Echtzeit-Updates mit Intervallen).

**Quellen**: Scapy Docs, NetworkX Docs, Plotly Docs, Dash Docs, TOML Docs.
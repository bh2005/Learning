# Praxisorientierte Anleitung: CDP und LLDP-Daten (inklusive LLDP-TLVs) in TOML mit Python parsen und eine Netzwerkkarte erstellen

## Einführung
CDP (Cisco Discovery Protocol) und LLDP (Link Layer Discovery Protocol) sind Layer-2-Protokolle, die Geräte in einem Netzwerk entdecken und Informationen wie Gerätenamen, IP-Adressen, Ports und Capabilities austauschen. Diese Anleitung zeigt, wie man CDP- und LLDP-Pakete (inklusive LLDP-TLVs wie Capabilities) mit Python (Scapy) erfasst, die Daten in TOML speichert und daraus eine Netzwerkkarte (Graph) erstellt. Der Fokus liegt auf einem Debian-basierten HomeLab (z. B. mit LXC-Containern), wo Pakete gesnifft, verarbeitet und visualisiert werden. Ziel ist es, dir praktische Schritte zur Netzwerktopologie-Erfassung zu vermitteln, um Konfigurationen und Gerätefähigkeiten zu analysieren.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und Netzwerkzugriff (z. B. auf Switches/Router mit CDP/LLDP).
- Installierte Tools: `python3`, `scapy`, `networkx`, `matplotlib`, `toml`.
- Grundkenntnisse in Python und Netzwerksicherheit.
- Testumgebung: Verbinde dein HomeLab mit einem CDP/LLDP-fähigen Netzwerk (z. B. Cisco-Switch).
- Führe als Root aus (für Raw-Sockets): `sudo python3 script.py`.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für CDP/LLDP, LLDP-TLVs und TOML:

1. **CDP und LLDP**:
   - **CDP**: Cisco-proprietary, sendet alle 60 Sekunden, enthält Device-ID, IP, Port, Capabilities.
   - **LLDP**: Standard (IEEE 802.1AB), vendor-neutral; TLV-Struktur (Type-Length-Value) für flexible Daten.
   - **LLDP-TLVs**: Type-Length-Value-Felder, z. B. `Capabilities` (System Capabilities TLV) gibt an, ob ein Gerät Router, Switch, Host etc. ist.
   - **Erfassung**: Mit Scapy sniffen, filtern auf Multicast-MACs (CDP: 01:00:0c:cc:cc:cc, LLDP: 01:80:c2:00:00:0e).
2. **TOML**:
   - **Eignung**: Minimalistisch für hierarchische Daten (z. B. [devices] mit Capabilities); lesbar, kompakt.
   - **Vorteile**: Einfach zu parsen, unterstützt Tabellen und Arrays.
3. **Netzwerkkarte**:
   - Graph mit NetworkX (Nodes: Geräte, Edges: Verbindungen), visualisiert mit Matplotlib.

## Übungen zum Verinnerlichen

### Übung 1: CDP/LLDP-Pakete erfassen und LLDP-TLVs (Capabilities) parsen
**Ziel**: Erfasse Pakete mit Scapy und extrahiere LLDP-Capabilities.

1. **Schritt 1**: Installiere Abhängigkeiten:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip
   pip install scapy networkx matplotlib toml
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

### Übung 3: Netzwerkkarte aus TOML erstellen (mit Capabilities)
**Ziel**: Erstelle einen Graph aus TOML-Daten mit Capabilities-Labels.

1. **Schritt 1**: Erstelle ein Python-Skript für die Netzwerkkarte (`scripts/create_network_map_extended.py`):
   ```python
   import toml
   import networkx as nx
   import matplotlib.pyplot as plt

   # Lade TOML
   with open('/app/network_map.toml', 'r') as f:
       data = toml.load(f)

   G = nx.Graph()

   # Nodes und Edges hinzufügen
   for device, info in data['devices'].items():
       capabilities = info.get('capabilities', ['Unknown'])
       label = f"{device}\n{', '.join(capabilities)}"
       G.add_node(device, label=label, ip=info.get('ip', info.get('chassis', 'Unknown')))
       if 'port' in info:
           neighbor = f"{device}_neighbor"  # Platzhalter; erweitere mit realen Daten
           G.add_edge(device, neighbor, port=info['port'])

   # Visualisiere
   plt.figure(figsize=(12, 8))
   pos = nx.spring_layout(G)
   labels = nx.get_node_attributes(G, 'label')
   nx.draw(G, pos, with_labels=True, labels=labels, node_color='lightblue', edge_color='gray', node_size=2000, font_size=10)
   edge_labels = nx.get_edge_attributes(G, 'port')
   nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels)
   plt.title('Netzwerkkarte aus CDP/LLDP-Daten mit Capabilities')
   plt.savefig('/app/network_map_extended.png')
   plt.show()
   print("Netzwerkkarte erstellt: /app/network_map_extended.png")
   ```
2. **Schritt 2**: Führe das Skript aus:
   ```bash
   pip install networkx matplotlib toml
   python3 /app/scripts/create_network_map_extended.py
   # Öffne /app/network_map_extended.png
   ```
   **Erwartete Ausgabe**: PNG-Datei mit Graph (Nodes: Geräte mit Capabilities, Edges: Verbindungen mit Port-Labels).

**Reflexion**: Wie verbessern Capabilities-Labels die Lesbarkeit der Netzwerkkarte? Warum ist NetworkX für Topologie-Visualisierung geeignet?

## Tipps für den Erfolg
- **Erfassung**: Verwende `sudo` für Scapy; filtere auf Multicast-MACs, um Overhead zu minimieren.
- **LLDP-TLVs**: Erweitere für weitere TLVs (z. B. Management Address, VLAN ID).
- **TOML**: Nutze Arrays für Capabilities; validiere mit Pydantic für Robustheit.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` bei Sniffing-Problemen; teste mit Wireshark.
- **Best Practices**: Speichere TOML in `/app/`, teste lokal, erweitere mit realen Nachbardaten.
- **2025-Fokus**: Integriere OpenTelemetry für Tracing von CDP/LLDP-Daten.

## Fazit
Du hast gelernt, CDP- und LLDP-Pakete (inklusive LLDP-Capabilities) mit Scapy zu erfassen, in TOML zu speichern und eine Netzwerkkarte mit NetworkX und Matplotlib zu erstellen. Die Übungen ermöglichen eine detaillierte Topologie-Erfassung in deinem HomeLab. Wiederhole sie, um die Techniken zu verinnerlichen.

**Nächste Schritte**:
- Erweitere mit weiteren LLDP-TLVs (z. B. Management Address).
- Integriere OpenTelemetry für Tracing.
- Erkunde interaktive Visualisierungen mit Plotly.

**Quellen**: Scapy Docs, NetworkX Docs, TOML Docs.
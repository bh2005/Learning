# Praxisorientierte Anleitung: CDP und LLDP-Daten (inklusive LLDP-TLVs) in TOML mit Python parsen und interaktive Netzwerkkarte mit Godot erstellen

## Einführung
CDP (Cisco Discovery Protocol) und LLDP (Link Layer Discovery Protocol) sind Layer-2-Protokolle, die Geräte in einem Netzwerk entdecken und Informationen wie Gerätenamen, IP-Adressen, Ports und Capabilities austauschen. Diese Anleitung zeigt, wie man CDP- und LLDP-Pakete (inklusive LLDP-TLVs wie Capabilities) mit Python (Scapy) erfasst, die Daten in TOML speichert und daraus eine **interaktive Netzwerkkarte mit Godot** erstellt. Godot ist eine Open-Source-Game-Engine, die sich für 2D-Visualisierungen eignet und Interaktionen wie Klick-Events und Tooltips unterstützt. Der Fokus liegt auf einem Debian-basierten HomeLab (z. B. mit LXC-Containern), wo Pakete gesnifft, verarbeitet und in Godot visualisiert werden. Ziel ist es, dir praktische Schritte zur Netzwerktopologie-Erfassung mit einer interaktiven Godot-Anwendung zu vermitteln, die Filter, Klick-Events und Tooltips bietet.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und Netzwerkzugriff (z. B. auf Switches/Router mit CDP/LLDP).
- Installierte Tools: `python3`, `scapy`, `toml`, `godot` (Godot Engine).
- Grundkenntnisse in Python, GDScript (Godot-Scripting) und Netzwerksicherheit.
- Testumgebung: Verbinde dein HomeLab mit einem CDP/LLDP-fähigen Netzwerk (z. B. Cisco-Switch).
- Führe als Root aus (für Raw-Sockets): `sudo python3 script.py`.
- Godot Engine installiert (z. B. via `sudo apt install godot3` oder Download von godotengine.org).
- Erwartete Ausgabe: Eine Godot-Anwendung mit interaktiver Netzwerkkarte, exportierbar als HTML5.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für CDP/LLDP, LLDP-TLVs, TOML und Godot:

1. **CDP und LLDP**:
   - **CDP**: Cisco-proprietary, sendet alle 60 Sekunden, enthält Device-ID, IP, Port, Capabilities.
   - **LLDP**: Standard (IEEE 802.1AB), vendor-neutral; TLV-Struktur (Type-Length-Value) für flexible Daten.
   - **LLDP-TLVs**: Type-Length-Value-Felder, z. B. `Capabilities` gibt an, ob ein Gerät Router, Switch, Host etc. ist.
   - **Erfassung**: Mit Scapy sniffen, filtern auf Multicast-MACs (CDP: 01:00:0c:cc:cc:cc, LLDP: 01:80:c2:00:00:0e).
2. **TOML**:
   - **Eignung**: Minimalistisch für hierarchische Daten (z. B. [devices] mit Capabilities); lesbar, kompakt.
   - **Vorteile**: Einfach zu parsen, unterstützt Tabellen und Arrays.
3. **Godot**:
   - **Funktion**: Open-Source-Engine für 2D/3D-Anwendungen, mit GDScript für Skripting.
   - **Vorteile**: Interaktivität (Nodes, Signals für Klicks/Hover), exportierbar als HTML5, leichtgewichtig.
   - **Nachteile**: Lernkurve für GDScript, weniger datenfokussiert als Plotly-Dash.
   - **Netzwerkkarte**: Nodes als Geräte (Sprite2D), Lines als Verbindungen (Line2D), Signals für Interaktionen.
4. **Netzwerkkarte**:
   - Graph mit Python (NetworkX), exportiert als TOML für Godot-Import.

## Übungen zum Verinnerlichen

### Übung 1: CDP/LLDP-Pakete erfassen und LLDP-TLVs (Capabilities) parsen
**Ziel**: Erfasse Pakete mit Scapy und extrahiere LLDP-Capabilities.

1. **Schritt 1**: Installiere Abhängigkeiten:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip godot3
   pip install scapy toml
   ```
2. **Schritt 2**: Erstelle ein Python-Skript zum Erfassen und Speichern in TOML (`scripts/cdp_lldp_sniffer_godot.py`):
   ```python
   from scapy.all import sniff, Ether
   from scapy.contrib.cdp import CDPHeader
   from scapy.contrib.lldp import LLDPDU, LLDPDUSystemCapabilities
   import toml
   import networkx as nx

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

   # Erstelle Netzwerkgraph
   G = nx.Graph()
   for device, info in discovered.items():
       G.add_node(device, **info)
       if 'port' in info:
           neighbor = f"{device}_neighbor"  # Platzhalter
           G.add_edge(device, neighbor, port=info['port'])

   # Speichere in TOML
   toml_data = {
       'devices': discovered,
       'edges': [{'source': edge[0], 'target': edge[1], 'port': G.edges[edge].get('port', 'Unknown')} for edge in G.edges]
   }
   with open('/app/network_map.toml', 'w') as f:
       toml.dump(toml_data, f)
   print("TOML-Datei erstellt: /app/network_map.toml")
   ```
3. **Schritt 3**: Führe das Skript aus (als Root):
   ```bash
   sudo python3 /app/scripts/cdp_lldp_sniffer_godot.py
   cat /app/network_map.toml
   ```
   **Erwartete Ausgabe**: TOML-Datei mit Gerätedaten und Kanten, z. B.:
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

   [[edges]]
   source = "Switch1"
   target = "Switch1_neighbor"
   port = "GigabitEthernet0/1"
   ```

**Reflexion**: Wie helfen LLDP-Capabilities bei der Geräteidentifikation? Warum ist TOML für Godot-Integration geeignet?

### Übung 2: Interaktive Netzwerkkarte mit Godot erstellen
**Ziel**: Erstelle eine Godot-Anwendung mit einer interaktiven Netzwerkkarte, die Klick-Events und Tooltips unterstützt.

1. **Schritt 1**: Erstelle ein Godot-Projekt:
   - Öffne Godot und erstelle ein neues Projekt (`/app/godot_network_map`).
   - Erstelle eine Hauptszene (`Main.tscn`) und ein GDScript (`Main.gd`).

2. **Schritt 2**: Erstelle das GDScript für die Netzwerkkarte (`Main.gd`):
   ```gdscript
   extends Node2D

   var device_sprite = preload("res://DeviceSprite.tscn")
   var tooltip_label
   var selected_label
   var devices = {}
   var edges = []

   func _ready():
 eclips    # Initialisierung
       var file = FileAccess.open("res://network_map.toml", FileAccess.READ)
       var data = parse_toml(file.get_as_text())
       file.close()
       devices = data["devices"]
       edges = data["edges"]
       create_network()

   func parse_toml(text):
       # Einfaches TOML-Parsing (für Demo; für komplexe TOML, verwende ein Plugin)
       var result = {"devices": {}, "edges": []}
       var lines = text.split("\n")
       var current_section = ""
       for line in lines:
           line = line.strip()
           if line.begins_with("[devices."):
               current_section = "devices"
               var device_name = line.substr(1, line.find("]")-1).split(".")[1]
               result["devices"][device_name] = {}
           elif line.begins_with("["):
               current_section = line.substr(1, line.find("]")-1)
           elif line.contains("="):
               var key_value = line.split(" = ")
               var key = key_value[0].strip()
               var value = key_value[1].strip().replace('["', '["').replace('"]', '"]').replace('"', '')
               if current_section.begins_with("devices"):
                   result["devices"][current_section.split(".")[1]][key] = value
               elif current_section == "edges":
                   if key == "source":
                       result["edges"].append({})
                       result["edges"][-1]["source"] = value
                   else:
                       result["edges"][-1][key] = value
       return result

   func create_network():
       # Erstelle Nodes
       var index = 0
       for device in devices.keys():
           var sprite = device_sprite.instantiate()
           sprite.position = Vector2(100 + index * 100, 100 + index * 50)
           sprite.device_name = device
           sprite.device_info = devices[device]
           sprite.connect("input_event", Callable(self, "_on_device_input").bind(device))
           sprite.connect("mouse_entered", Callable(self, "_on_device_mouse_entered").bind(device))
           sprite.connect("mouse_exited", Callable(self, "_on_device_mouse_exited").bind(device))
           add_child(sprite)
           index += 1

       # Erstelle Edges
       for edge in edges:
           var line = Line2D.new()
           line.points = [
               get_node(edge["source"]).position,
               get_node(edge["target"]).position
           ]
           line.width = 2
           line.default_color = Color(0.5, 0.5, 0.5)
           add_child(line)

       # Erstelle Tooltip-Label
       tooltip_label = Label.new()
       tooltip_label.visible = false
       add_child(tooltip_label)

       # Erstelle Selected-Label
       selected_label = Label.new()
       selected_label.position = Vector2(10, 10)
       add_child(selected_label)

   func _on_device_input(viewport, event, shape_idx, device):
       if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
           var info = devices[device]
           var text = "Device: %s\nType: %s\nIP/Chassis: %s\nPort: %s\nCapabilities: %s" % [
               device, info["type"], info.get("ip", info.get("chassis", "Unknown")),
               info.get("port", "Unknown"), ", ".join(info.get("capabilities", ["Unknown"]))
           ]
           selected_label.text = text

   func _on_device_mouse_entered(device):
       var info = devices[device]
       tooltip_label.text = "Device: %s\n%s" % [device, info.get("ip", info.get("chassis", "Unknown"))]
       tooltip_label.position = get_viewport().get_mouse_position() + Vector2(10, 10)
       tooltip_label.visible = true

   func _on_device_mouse_exited(device):
       tooltip_label.visible = false
   ```

3. **Schritt 3**: Erstelle die DeviceSprite-Szene (`DeviceSprite.tscn`):
   - Erstelle eine neue Szene mit einem `Sprite2D`-Node.
   - Füge eine `CollisionShape2D` mit einem `CircleShape2D` (Radius: 20) hinzu.
   - Füge ein GDScript (`DeviceSprite.gd`) hinzu:
   ```gdscript
   extends Area2D

   var device_name = ""
   var device_info = {}

   func _ready():
       var sprite = Sprite2D.new()
       sprite.texture = preload("res://icon.png")  # Ersetze durch ein Gerät-Symbol
       sprite.scale = Vector2(0.5, 0.5)
       add_child(sprite)
       var collision = CollisionShape2D.new()
       var shape = CircleShape2D.new()
       shape.radius = 20
       collision.shape = shape
       add_child(collision)
   ```

4. **Schritt 4**: Speichere die TOML-Datei aus Übung 1 unter `res://network_map.toml` im Godot-Projektverzeichnis.

5. **Schritt 5**: Führe das Godot-Projekt aus:
   - Öffne Godot, lade das Projekt und starte die Hauptszene (`Main.tscn`).
   - **Erwartete Ausgabe**: Eine 2D-Netzwerkkarte, bei der Geräte als Sprites dargestellt werden, verbunden durch Linien. Klicke auf Geräte für Details, schwebe für Tooltips.

**Reflexion**: Wie verbessert Godot die Benutzererfahrung im Vergleich zu Plotly-Dash? Warum ist Godot für interaktive Visualisierungen geeignet?

## Tipps für den Erfolg
- **Erfassung**: Verwende `sudo` für Scapy; filtere auf Multicast-MACs, um Overhead zu minimieren.
- **TOML-Parsing**: Das einfache TOML-Parsing im Beispiel ist begrenzt; für komplexe TOML-Dateien verwende ein Godot-Plugin wie `godot-toml`.
- **Godot**: Nutze `Sprite2D` für Geräte, `Line2D` für Verbindungen und `Area2D` für Interaktionen.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` bei Sniffing-Problemen; teste mit Wireshark.
- **Best Practices**: Speichere TOML in `/app/` (Python) und `res://` (Godot); teste lokal.
- **2025-Fokus**: Exportiere die Godot-Anwendung als HTML5 für browserbasierte Bereitstellung.

## Fazit
Du hast gelernt, CDP- und LLDP-Pakete (inklusive LLDP-Capabilities) mit Scapy zu erfassen, in TOML zu speichern und eine interaktive Netzwerkkarte mit Godot zu erstellen, die Klick-Events und Tooltips unterstützt. Die Übungen ermöglichen eine detaillierte Topologie-Erfassung mit interaktiven Visualisierungen in deinem HomeLab. Wiederhole sie, um die Techniken zu verinnerlichen.

**Nächste Schritte**:
- Erweitere mit weiteren LLDP-TLVs (z. B. Management Address).
- Integriere Echtzeit-Updates durch regelmäßiges Sniffing in Python.
- Erkunde Godot-Features wie Animationen oder 3D-Visualisierungen.

**Quellen**: Scapy Docs, NetworkX Docs, Godot Docs, TOML Docs.
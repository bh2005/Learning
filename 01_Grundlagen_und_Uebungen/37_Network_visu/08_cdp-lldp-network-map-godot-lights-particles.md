# Praxisorientierte Anleitung: CDP und LLDP-Daten (inklusive LLDP-TLVs) in TOML mit Python parsen und interaktive 3D-Netzwerkkarte mit Godot, Animationen, Lichteffekten und Partikeln für Alerts erstellen

## Einführung
CDP (Cisco Discovery Protocol) und LLDP (Link Layer Discovery Protocol) sind Layer-2-Protokolle, die Geräte in einem Netzwerk entdecken und Informationen wie Gerätenamen, IP-Adressen, Ports und Capabilities austauschen. Diese Anleitung zeigt, wie man CDP- und LLDP-Pakete (inklusive LLDP-TLVs wie Capabilities) mit Python (Scapy) erfasst, die Daten in TOML speichert und daraus eine **interaktive 3D-Netzwerkkarte mit Godot** erstellt. Godot bietet erweiterte Features wie **Animationen** (pulsierende Nodes), **Lichteffekte** (SpotLight für hervorgehobene Geräte) und **Partikel** (für Alerts bei neuen Geräten). Der Fokus liegt auf einem Debian-basierten HomeLab (z. B. mit LXC-Containern), wo Pakete gesnifft, verarbeitet und in Godot visualisiert werden. Ziel ist es, dir praktische Schritte zur Netzwerktopologie-Erfassung mit einer erweiterten Godot-Anwendung zu vermitteln, die Klick-Events, Tooltips, Animationen, 3D-Navigation, Lichteffekte und Partikel für Alerts unterstützt.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern und Netzwerkzugriff (z. B. auf Switches/Router mit CDP/LLDP).
- Installierte Tools: `python3`, `scapy`, `toml`, `godot` (Godot Engine, Version 4 empfohlen).
- Grundkenntnisse in Python, GDScript (Godot-Scripting) und Netzwerksicherheit.
- Testumgebung: Verbinde dein HomeLab mit einem CDP/LLDP-fähigen Netzwerk (z. B. Cisco-Switch).
- Führe als Root aus (für Raw-Sockets): `sudo python3 script.py`.
- Godot Engine installiert (z. B. via `sudo apt install godot3` oder Download von godotengine.org).
- Erwartete Ausgabe: Eine Godot-Anwendung mit interaktiver 3D-Netzwerkkarte, Animationen, Lichteffekten und Partikeln.

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
   - **Animationen**: `AnimationPlayer` für Eigenschaftsanimationen (z. B. Skalierung für Alerts).
   - **3D-Visualisierungen**: 3D-Nodes (`MeshInstance3D`, `Camera3D`) für räumliche Graphen mit Navigation.
   - **Lichteffekte**: `SpotLight3D` für dynamische Beleuchtung (z. B. Hervorheben von Geräten).
   - **Partikel**: `GPUParticles3D` für visuelle Alerts (z. B. bei neuen Geräten).
   - **Vorteile**: Interaktivität (Signals für Klicks/Hover), exportierbar als HTML5/Desktop-App, visuell ansprechend.
   - **Nachteile**: Lernkurve für GDScript, weniger datenfokussiert als Plotly-Dash.
   - **Netzwerkkarte**: Nodes als Geräte (`MeshInstance3D`), Verbindungen als Zylinder (`MultiMeshInstance3D`), Signals für Interaktionen.
4. **Netzwerkkarte**:
   - Graph mit Python (NetworkX), exportiert als TOML für Godot-Import.

## Übungen zum Verinnerlichen

### Übung 1: CDP/LLDP-Pakete erfassen und LLDP-TLVs (Capabilities) parsen
**Ziel**: Erfasse Pakete mit Scapy und extrahiere LLDP-Capabilities.

1. **Schritt 1**: Installiere Abhängigkeiten:
   ```bash
   sudo apt update
   sudo apt install -y python3 python3-pip godot3
   pip install scapy toml networkx
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
                   discovered[device_id] = {'ip': ip, 'port': port, 'type': 'CDP', 'capabilities': ['Unknown'], 'new': True}
                   print(f"CDP: Device {device_id}, IP {ip}, Port {port}")
           elif packet[Ether].dst == '01:80:c2:00:00:0e':  # LLDP
               if LLDPDU in packet:
                   chassis_id = packet[LLDPDU].getlayer('LLDPDUChassisID').id.decode('utf-8', errors='ignore') if 'LLDPDUChassisID' in packet else 'Unknown'
                   port_id = packet[LLDPDU].getlayer('LLDPDUPortID').id.decode('utf-8', errors='ignore') if 'LLDPDUPortID' in packet else 'Unknown'
                   system_name = packet[LLDPDU].getlayer('LLDPDUSystemName').system_name.decode('utf-8', errors='ignore') if 'LLDPDUSystemName' in packet else chassis_id
                   capabilities = packet[LLDPDU].getlayer('LLDPDUSystemCapabilities')
                   caps = decode_capabilities(capabilities.capabilities) if capabilities else ['None']
                   discovered[system_name] = {'chassis': chassis_id, 'port': port_id, 'type': 'LLDP', 'capabilities': caps, 'new': True}
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
   new = true

   [devices.Router1]
   chassis = "00:11:22:33:44:55"
   port = "Eth0/1"
   type = "LLDP"
   capabilities = ["Router", "Bridge"]
   new = true

   [[edges]]
   source = "Switch1"
   target = "Switch1_neighbor"
   port = "GigabitEthernet0/1"
   ```

**Reflexion**: Wie helfen LLDP-Capabilities bei der Geräteidentifikation? Warum ist TOML für Godot-Integration geeignet?

### Übung 2: Interaktive 3D-Netzwerkkarte mit Animationen, Lichteffekten und Partikeln in Godot
**Ziel**: Erstelle eine Godot-Anwendung mit einer interaktiven 3D-Netzwerkkarte, pulsierenden Animationen, SpotLight-Effekten und Partikeln für Alerts.

1. **Schritt 1**: Erstelle ein Godot-Projekt:
   - Öffne Godot und erstelle ein neues Projekt (`/app/godot_network_map`).
   - Erstelle eine Hauptszene (`Main.tscn`), eine Device-Szene (`Device.tscn`) und eine Tooltip-Szene (`Tooltip.tscn`).

2. **Schritt 2**: Erstelle die Device-Szene (`Device.tscn`):
   - Erstelle eine Szene mit einem `MeshInstance3D`-Node (Mesh: `SphereMesh`, Radius 0.5).
   - Füge einen `CollisionShape3D`-Node mit einem `SphereShape3D` (Radius 0.5) hinzu.
   - Füge einen `AnimationPlayer`-Node für Pulsier-Animationen hinzu.
   - Füge einen `SpotLight3D`-Node für Lichteffekte hinzu.
   - Füge einen `GPUParticles3D`-Node für Alerts hinzu.
   - Erstelle ein GDScript (`Device.gd`):
   ```gdscript
   extends Area3D

   var device_name = ""
   var device_info = {}

   func _ready():
       # Mesh für Gerät
       $MeshInstance3D.mesh = SphereMesh.new()
       $MeshInstance3D.mesh.radius = 0.5
       $MeshInstance3D.mesh.height = 1.0
       var material = StandardMaterial3D.new()
       material.albedo_color = Color(0.2, 0.6, 1.0)
       $MeshInstance3D.mesh.material = material
       $CollisionShape3D.shape = SphereShape3D.new()
       $CollisionShape3D.shape.radius = 0.5

       # Pulsier-Animation
       var anim_player = $AnimationPlayer
       var anim = Animation.new()
       anim.length = 1.0
       var track_index = anim.add_track(Animation.TYPE_VALUE)
       anim.track_set_path(track_index, "MeshInstance3D:scale")
       anim.track_insert_key(track_index, 0.0, Vector3(1, 1, 1))
       anim.track_insert_key(track_index, 0.5, Vector3(1.2, 1.2, 1.2))
       anim.track_insert_key(track_index, 1.0, Vector3(1, 1, 1))
       anim_player.add_animation("pulse", anim)
       anim_player.play("pulse")

       # SpotLight für Hervorhebung
       $SpotLight3D.light_energy = 0.0  # Standardmäßig aus
       $SpotLight3D.spot_angle = 30.0
       $SpotLight3D.translation = Vector3(0, 2, 0)

       # Partikel für Alerts
       $GPUParticles3D.emitting = device_info.get("new", false)
       $GPUParticles3D.amount = 50
       var particle_material = ParticleProcessMaterial.new()
       particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
       particle_material.emission_sphere_radius = 0.3
       particle_material.spread = 45.0
       particle_material.initial_velocity_min = 1.0
       particle_material.initial_velocity_max = 2.0
       $GPUParticles3D.process_material = particle_material
       var particle_mesh = SphereMesh.new()
       particle_mesh.radius = 0.05
       particle_mesh.height = 0.1
       $GPUParticles3D.draw_pass_1 = particle_mesh

   func highlight(state):
       $SpotLight3D.light_energy = 5.0 if state else 0.0
   ```

3. **Schritt 3**: Erstelle die Tooltip-Szene (`Tooltip.tscn`):
   - Erstelle eine Szene mit einem `Label3D`-Node.
   - Füge ein GDScript (`Tooltip.gd`) hinzu:
   ```gdscript
   extends Label3D

   func _ready():
       visible = false
       pixel_size = 0.005
       modulate = Color(1, 1, 1, 0.8)
   ```

4. **Schritt 4**: Erstelle das Hauptskript (`Main.gd`):
   ```gdscript
   extends Node3D

   var device_scene = preload("res://Device.tscn")
   var tooltip_scene = preload("res://Tooltip.tscn")
   var devices = {}
   var edges = []
   var tooltip
   var selected_label
   var camera

   func _ready():
       # Lade TOML-Daten
       var file = FileAccess.open("res://network_map.toml", FileAccess.READ)
       var data = parse_toml(file.get_as_text())
       file.close()
       devices = data["devices"]
       edges = data["edges"]
       create_network()

       # Erstelle Kamera
       camera = Camera3D.new()
       camera.translation = Vector3(0, 0, 10)
       camera.fov = 75
       add_child(camera)

       # Erstelle Tooltip
       tooltip = tooltip_scene.instantiate()
       add_child(tooltip)

       # Erstelle Selected-Label (2D-Overlay)
       selected_label = Label.new()
       selected_label.position = Vector2(10, 10)
       var canvas = CanvasLayer.new()
       canvas.add_child(selected_label)
       add_child(canvas)

   func parse_toml(text):
       # Einfaches TOML-Parsing (für Demo; für komplexe TOML, verwende ein Plugin)
       var result = {"devices": {}, "edges": []}
       var lines = text.split("\n")
       var current_section = ""
       var current_device = ""
       for line in lines:
           line = line.strip_edges()
           if line.begins_with("[devices."):
               current_section = "devices"
               current_device = line.substr(9, line.find("]")-9)
               result["devices"][current_device] = {}
           elif line.begins_with("[[edges]]"):
               current_section = "edges"
               result["edges"].append({})
           elif line.contains("="):
               var key_value = line.split(" = ")
               var key = key_value[0].strip_edges()
               var value = key_value[1].strip_edges()
               if value.begins_with('["') and value.ends_with('"]'):
                   value = value.substr(2, value.length()-4).split('", "')
               elif value.begins_with('"') and value.ends_with('"'):
                   value = value.substr(1, value.length()-2)
               elif value == "true":
                   value = true
               elif value == "false":
                   value = false
               if current_section == "devices":
                   result["devices"][current_device][key] = value
               elif current_section == "edges":
                   result["edges"][-1][key] = value
       return result

   func create_network():
       # Erstelle Nodes
       var index = 0
       for device in devices.keys():
           var node = device_scene.instantiate()
           node.name = device
           node.device_name = device
           node.device_info = devices[device]
           node.position = Vector3(index * 2, index * 1, 0)
           node.connect("input_event", Callable(self, "_on_device_input").bind(device))
           node.connect("mouse_entered", Callable(self, "_on_device_mouse_entered").bind(device))
           node.connect("mouse_exited", Callable(self, "_on_device_mouse_exited").bind(device))
           add_child(node)
           index += 1

       # Erstelle Edges
       for edge in edges:
           var source_pos = get_node(edge["source"]).position
           var target_pos = get_node(edge["target"]).position if edge["target"] in devices else source_pos + Vector3(2, 0, 0)
           var line = MeshInstance3D.new()
           var mesh = CylinderMesh.new()
           mesh.height = source_pos.distance_to(target_pos)
           mesh.top_radius = 0.1
           mesh.bottom_radius = 0.1
           line.mesh = mesh
           line.position = (source_pos + target_pos) / 2
           line.look_at_from_position(line.position, target_pos, Vector3.UP)
           add_child(line)

   func _on_device_input(camera, event, position, normal, shape_idx, device):
       if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
           var info = devices[device]
           var text = "Device: %s\nType: %s\nIP/Chassis: %s\nPort: %s\nCapabilities: %s" % [
               device, info["type"], info.get("ip", info.get("chassis", "Unknown")),
               info.get("port", "Unknown"), ", ".join(info.get("capabilities", ["Unknown"]))
           ]
           selected_label.text = text
           # Aktiviere SpotLight für Hervorhebung
           for node in get_tree().get_nodes_in_group("devices"):
               node.highlight(false)
           get_node(device).highlight(true)

   func _on_device_mouse_entered(device):
       var info = devices[device]
       tooltip.text = "Device: %s\n%s" % [device, info.get("ip", info.get("chassis", "Unknown"))]
       tooltip.position = get_node(device).position + Vector3(0.5, 0.5, 0)
       tooltip.visible = true

   func _on_device_mouse_exited(device):
       tooltip.visible = false

   func _input(event):
       # Kamera-Navigation
       if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_RIGHT:
           camera.rotate_y(-event.relative.x * 0.005)
           camera.rotate_x(-event.relative.y * 0.005)
       if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
           camera.translate(Vector3(0, 0, -0.5))
       if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
           camera.translate(Vector3(0, 0, 0.5))
   ```

5. **Schritt 5**: Speichere die TOML-Datei aus Übung 1 unter `res://network_map.toml` im Godot-Projektverzeichnis.

6. **Schritt 6**: Führe das Godot-Projekt aus:
   - Öffne Godot, lade das Projekt und starte die Hauptszene (`Main.tscn`).
   - **Erwartete Ausgabe**: Eine 3D-Netzwerkkarte mit:
     - Geräten als pulsierende Kugeln (`MeshInstance3D`) mit Partikeln für neue Geräte (`new = true`).
     - Verbindungen als Zylinder (`CylinderMesh`).
     - SpotLight-Effekt beim Klicken auf ein Gerät.
     - Tooltips (`Label3D`) beim Hover.
     - Gerätedetails bei Klick (2D-Overlay).
     - Kamera-Navigation (rechte Maustaste: Rotieren, Mausrad: Zoomen).

**Reflexion**: Wie verbessern Lichteffekte und Partikel die Netzwerkvisualisierung? Warum ist Godot für solche interaktiven Features geeignet?

## Tipps für den Erfolg
- **Erfassung**: Verwende `sudo` für Scapy; filtere auf Multicast-MACs, um Overhead zu minimieren.
- **TOML-Parsing**: Das einfache TOML-Parsing im Beispiel ist begrenzt; für komplexe TOML-Dateien verwende ein Godot-Plugin wie `godot-toml`.
- **Godot**: Nutze `MeshInstance3D` für Geräte, `SpotLight3D` für Beleuchtung, `GPUParticles3D` für Alerts, `AnimationPlayer` für Animationen und `Camera3D` für Navigation.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` bei Sniffing-Problemen; teste mit Wireshark.
- **Best Practices**: Speichere TOML in `/app/` (Python) und `res://` (Godot); teste lokal.
- **2025-Fokus**: Exportiere die Godot-Anwendung als HTML5 für browserbasierte Bereitstellung.

## Fazit
Du hast gelernt, CDP- und LLDP-Pakete (inklusive LLDP-Capabilities) mit Scapy zu erfassen, in TOML zu speichern und eine interaktive 3D-Netzwerkkarte mit Godot zu erstellen, die pulsierende Animationen, SpotLight-Effekte, Partikel für Alerts, Klick-Events, Tooltips und Kamera-Navigation unterstützt. Die Übungen ermöglichen eine detaillierte Topologie-Erfassung mit ansprechenden Visualisierungen in deinem HomeLab. Wiederhole sie, um die Techniken zu verinnerlichen.

**Nächste Schritte**:
- Erweitere mit weiteren LLDP-TLVs (z. B. Management Address).
- Integriere Echtzeit-Updates durch regelmäßiges Sniffing in Python.
- Erkunde Godot-Features wie Shader für erweiterte Lichteffekte oder Benutzeroberflächen (Control-Nodes).

**Quellen**: Scapy Docs, NetworkX Docs, Godot Docs, TOML Docs.
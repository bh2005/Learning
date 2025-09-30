# Visualisierung einer CDP/LLDP-Netzwerkkarte mit Godot UI-Controls

Basierend auf der Anleitung ["CDP/LLDP Network Map Godot UI Controls"](https://github.com/bh2005/Learning/blob/main/01_Grundlagen_und_Uebungen/37_Network_visu/10_cdp-lldp-network-map-godot-ui-controls.md) beschreibt dieser Artikel, wie eine interaktive, dynamische und ästhetisch ansprechende Netzwerkkarte optisch gestaltet werden könnte. Die Visualisierung nutzt die Godot-Engine, insbesondere deren UI-Controls, um Netzwerkgeräte und deren Verbindungen übersichtlich darzustellen.

## Topologische Darstellung

- **Knoten (Nodes)**: Jedes Netzwerkgerät (z. B. Router, Switch, Access Point) wird als eigener Knoten dargestellt. Unterschiedliche Symbole oder Farben kennzeichnen den Gerätetyp:
  - Kreis für Switches
  - Dreieck für Router
  - Quadrat für Access Points
- **Verbindungen (Edges)**: CDP- und LLDP-Verbindungen werden als Linien zwischen den Knoten angezeigt. Diese können variieren in:
  - **Dicke**: Um die Link-Geschwindigkeit zu symbolisieren (z. B. dickere Linien für 10 Gbps).
  - **Farbe**: Um den Status anzuzeigen (z. B. Grün für aktiv, Rot für inaktiv oder Fehler).
- **Physikalische Anordnung**: Ein Force-Directed-Layout-Algorithmus positioniert Knoten automatisch, wobei stark vernetzte Geräte zentral platziert werden, um die Lesbarkeit zu verbessern.
- **Lichteffekte**: Leichte Glow- oder Pulse-Effekte heben aktive oder kürzlich aktualisierte Verbindungen hervor, um dynamische Änderungen im Netzwerk sichtbar zu machen.

## Interaktive Benutzeroberfläche (UI)

Die Benutzeroberfläche wird direkt in Godot gestaltet und in die Visualisierung integriert.

- **Seitenleiste oder Panel**: Ein Control-Panel (z. B. links oder rechts) enthält alle Steuerelemente.
- **Steuerelemente (Controls)**:
  - **Dropdown-Menü**: Ermöglicht die Auswahl verschiedener Visualisierungsmodi (z. B. Layer 2, Layer 3, Gesamtübersicht).
  - **Buttons**: Funktionen wie "Karte aktualisieren", "Snapshot speichern" oder "Ansicht zurücksetzen".
  - **Schieberegler (Sliders)**: Zur Anpassung der Knotendichte oder Zoomstufe.
  - **Textfelder**: Ein Suchfeld, um nach Hostnamen, IP-Adressen oder Geräte-IDs zu suchen.

## Detaillierte Informationsanzeige

- **Hover-Effekte**: Beim Überfahren eines Knotens mit der Maus erscheint ein Popup-Fenster mit grundlegenden Informationen (z. B. Gerätename, Modell, IP-Adresse).
- **Infopanel**: Ein Klick auf einen Knoten oder eine Verbindung öffnet ein detailliertes Panel mit Informationen wie:
  - Interface-Name
  - Port-ID
  - VLANs
  - Protokoll (CDP oder LLDP)
  - Gerätestatus

## Ästhetik und Stil

- **Farbpalette**: Eine dunkle Farbpalette mit leuchtenden Akzentfarben verbessert die Lesbarkeit und erzeugt einen modernen, "Sci-Fi"- oder "Cyberpunk"-Look:
  - Blau für Switches
  - Orange für Router
  - Grün für Access Points
- **Schriftarten**: Eine klare, technische Monospace-Schriftart (z. B. Fira Code) stellt Daten professionell dar.
- **Animationen**: Sanfte Animationen (z. B. beim Laden neuer Daten oder Verschieben von Knoten) sorgen für eine flüssige und ansprechende Benutzererfahrung.

![Beispiel Netzwerkkarte](images/network_map_example.png "Interaktive CDP/LLDP-Netzwerkkarte in Godot")

## Zusammenfassung

Die Visualisierung einer CDP/LLDP-Netzwerkkarte in Godot ist mehr als eine statische Darstellung – sie ist eine dynamische, interaktive Umgebung, die es Benutzern ermöglicht, das Netzwerk aktiv zu erkunden. Godot UI-Controls wie GraphEdit, Buttons und Popups bieten Werkzeuge, um Daten zu filtern, zu steuern und detaillierte Einblicke zu gewinnen. Die Kombination aus Force-Directed-Layouts, farbcodierten Verbindungen und ansprechender Ästhetik macht die Netzwerkkarte sowohl funktional als auch visuell ansprechend.
# Praxisorientierte Anleitung: Web-Scraping mit Requests und BeautifulSoup

## Einführung
Diese Anleitung bietet eine praxisorientierte Einführung in das **Web-Scraping** mit den Python-Bibliotheken **Requests** und **BeautifulSoup**. Ziel ist es, den Lesern zu zeigen, wie sie Daten von Webseiten extrahieren können, um sie für Analysen oder andere Anwendungen zu nutzen. Web-Scraping ist eine nützliche Technik, um Informationen aus dem Internet zu sammeln, die nicht in einer strukturierten Form vorliegen.

Voraussetzungen:
- **Python-Installation**: Die neueste Version von Python sollte auf dem Computer installiert sein.
- **Benötigte Bibliotheken**: Die Bibliotheken `requests` und `beautifulsoup4` müssen installiert sein. Dies kann über `pip` erfolgen.
- **Grundkenntnisse in Python**: Ein grundlegendes Verständnis von Python-Programmierung ist von Vorteil.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Requests**:
   - **GET-Anfrage**: Abrufen von Inhalten einer Webseite.
   - **POST-Anfrage**: Senden von Daten an eine Webseite.
2. **BeautifulSoup**:
   - **HTML-Parsing**: Analysieren und Navigieren durch HTML-Dokumente.
   - **Elementauswahl**: Finden von spezifischen HTML-Elementen.
3. **Datenextraktion**:
   - **Textinhalt**: Extrahieren von Text aus HTML-Elementen.
   - **Attribute**: Zugriff auf Attribute von HTML-Elementen, z. B. `href` von Links.

## Übungen zum Verinnerlichen

### Übung 1: Eine Webseite abrufen
**Ziel**: Lerne, wie man eine Webseite mit der Requests-Bibliothek abruft.

1. **Schritt 1**: Importiere die Requests-Bibliothek.
   ```python
   import requests
   ```
2. **Schritt 2**: Sende eine GET-Anfrage an eine Webseite.
   ```python
   url = 'https://example.com'
   response = requests.get(url)
   ```
3. **Schritt 3**: Überprüfe den Statuscode der Antwort.
   ```python
   print("Statuscode:", response.status_code)
   ```

**Reflexion**: Was bedeutet der Statuscode, und warum ist er wichtig?

### Übung 2: HTML-Inhalt analysieren
**Ziel**: Verwende BeautifulSoup, um den HTML-Inhalt zu analysieren.

1. **Schritt 1**: Importiere die BeautifulSoup-Bibliothek.
   ```python
   from bs4 import BeautifulSoup
   ```
2. **Schritt 2**: Erstelle ein BeautifulSoup-Objekt aus dem HTML-Inhalt.
   ```python
   soup = BeautifulSoup(response.text, 'html.parser')
   ```
3. **Schritt 3**: Finde den Titel der Webseite.
   ```python
   titel = soup.title.string
   print("Titel der Webseite:", titel)
   ```

**Reflexion**: Wie hilft dir BeautifulSoup, die Struktur von HTML-Dokumenten zu verstehen?

### Übung 3: Daten extrahieren
**Ziel**: Extrahiere spezifische Daten von einer Webseite.

1. **Schritt 1**: Finde alle Links auf der Webseite.
   ```python
   links = soup.find_all('a')
   ```
2. **Schritt 2**: Gib die URLs der gefundenen Links aus.
   ```python
   for link in links:
       print("Link:", link.get('href'))
   ```
3. **Schritt 3**: Experimentiere mit der Extraktion anderer Elemente, z. B. Überschriften oder Absätze.

**Reflexion**: Welche Herausforderungen hast du bei der Datenextraktion erlebt?

## Tipps für den Erfolg
- Achte darauf, die Nutzungsbedingungen der Webseite zu überprüfen, um sicherzustellen, dass Web-Scraping erlaubt ist.
- Verwende `time.sleep()`, um die Anzahl der Anfragen an die Webseite zu steuern und Überlastungen zu vermeiden.
- Nutze die Dokumentation von Requests und BeautifulSoup, um fortgeschrittene Funktionen zu entdecken.

## Fazit
In dieser Anleitung hast du die Grundlagen des Web-Scrapings mit Requests und BeautifulSoup kennengelernt. Du hast gelernt, wie man Webseiten abruft, den HTML-Inhalt analysiert und spezifische Daten extrahiert.

**Nächste Schritte**:
- Vertiefe dein Wissen über fortgeschrittene Techniken wie das Scraping von dynamischen Webseiten mit Selenium.
- Erkunde die Speicherung der extrahierten Daten in Formaten wie CSV oder JSON.
- Informiere dich über rechtliche Aspekte und ethische Überlegungen beim Web-Scraping.

**Quellen**: [Requests-Dokument
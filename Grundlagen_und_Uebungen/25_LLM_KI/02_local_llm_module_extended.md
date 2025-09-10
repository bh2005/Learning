# Lernprojekt: Zusätzliche Übungen zu lokalen LLMs in einer HomeLab

## Einführung

Diese zusätzlichen Übungen erweitern das Lernprojekt `01_local_llm_module.md`, das lokale Large Language Models (LLMs) wie **Llama 3.1 (8B)** und **Code Llama (7B)** mit **Ollama** auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) in einer HomeLab-Umgebung nutzt. Die Übungen sind für Lernende mit Grundkenntnissen in Linux, Python und Docker geeignet und integrieren die HomeLab-Infrastruktur mit Proxmox VE, TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement. Sie umfassen drei fortgeschrittene Anwendungen: einen interaktiven Programmier-Assistenten mit Code-Vervollständigung, ein lokales Wissensmanagementsystem mit Dokumentensuche und die Automatisierung von Textgenerierungsaufgaben mit einem Scheduler. Das Projekt bleibt lokal, kostenlos und datenschutzfreundlich, da keine Cloud-Dienste genutzt werden.

**Voraussetzungen** (wie in `01_local_llm_module.md`):
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), eingerichtet mit Ollama, Llama 3.1 (8B) und Code Llama (7B).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Docker, Python, PyPDF2 und sentence-transformers installiert:
  ```bash
  sudo apt install -y docker.io python3-pip
  pip3 install PyPDF2 sentence-transformers
  ```
- HomeLab mit TrueNAS (`192.168.30.100`) und OPNsense (`192.168.30.1`).
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Beispiel-PDF-Datei (z. B. `~/llm-project/sample.pdf`).
- Projektverzeichnis: `~/llm-project` auf der VM.

**Ziele**:
- Implementieren eines interaktiven Programmier-Assistenten mit Code-Vervollständigung.
- Erstellen eines lokalen Wissensmanagementsystems mit Dokumentensuche.
- Automatisieren von Textgenerierungsaufgaben mit einem Scheduler.

**Quellen**:
- Ollama-Dokumentation: https://ollama.com
- Llama-Dokumentation: https://github.com/meta-ai/llama
- Sentence-Transformers: https://sbert.net
- Webquellen:,,,,,

## Zusätzliche Übungen

### Übung 4: Interaktiver Programmier-Assistent mit Code-Vervollständigung

**Ziel**: Implementieren eines interaktiven Programmier-Assistenten, der Code-Vervollständigung und Debugging-Hilfe bietet.

**Aufgabe**: Erstelle ein Python-Skript, das Code Llama nutzt, um interaktiv Code zu vervollständigen und Fehler zu analysieren.

1. **Python-Skript für Code-Vervollständigung erstellen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     cd ~/llm-project
     ```
   - Erstelle das Skript:
     ```bash
     nano code_completer.py
     ```
     - Inhalt:
       ```python
       import requests
       import json

       def complete_code(prompt, model="codellama:7b"):
           url = "http://localhost:11434/api/generate"
           payload = {
               "model": model,
               "prompt": prompt,
               "stream": False
           }
           response = requests.post(url, json=payload)
           if response.status_code == 200:
               return json.loads(response.text)["response"]
           else:
               return f"Fehler: {response.status_code}"

       def debug_code(code, error):
           prompt = f"Analysiere den folgenden Code und den Fehler, und schlage eine Lösung vor:\n\nCode:\n{code}\n\nFehler:\n{error}"
           return complete_code(prompt)

       if __name__ == "__main__":
           while True:
               action = input("Wähle eine Aktion (complete/debug/exit): ")
               if action.lower() == "exit":
                   break
               elif action.lower() == "complete":
                   code_snippet = input("Gib den unvollständigen Code ein: ")
                   prompt = f"Vervollständige den folgenden Code:\n\n{code_snippet}"
                   result = complete_code(prompt)
                   print("Vervollständigter Code:")
                   print(result)
               elif action.lower() == "debug":
                   code_snippet = input("Gib den fehlerhaften Code ein: ")
                   error_message = input("Gib die Fehlermeldung ein: ")
                   result = debug_code(code_snippet, error_message)
                   print("Debugging-Vorschlag:")
                   print(result)
               print("-" * 50)
       ```
     - **Erklärung**:
       - `complete_code`: Sendet Prompts an Code Llama für Code-Vervollständigung oder Debugging.
       - `debug_code`: Analysiert Code und Fehlermeldungen.
       - Interaktive CLI mit Optionen für Vervollständigung oder Debugging.

2. **Skript ausführen**:
   ```bash
   python3 code_completer.py
   ```
   - Beispiel 1: Code-Vervollständigung
     ```
     Wähle eine Aktion (complete/debug/exit): complete
     Gib den unvollständigen Code ein: def factorial(n):
         if n == 0:
             return 1
         else:
             return n * 
     Vervollständigter Code:
     def factorial(n):
         if n == 0:
             return 1
         else:
             return n * factorial(n - 1)
     ```
   - Beispiel 2: Debugging
     ```
     Wähle eine Aktion (complete/debug/exit): debug
     Gib den fehlerhaften Code ein: def divide(a, b): return a / b
     Gib die Fehlermeldung ein: ZeroDivisionError: division by zero
     Debugging-Vorschlag:
     Der Fehler `ZeroDivisionError: division by zero` tritt auf, wenn `b` gleich 0 ist. Hier ist eine korrigierte Version:

     ```python
     def divide(a, b):
         if b == 0:
             raise ValueError("Division durch Null ist nicht erlaubt")
         return a / b
     ```
     ```

3. **Code speichern und testen**:
   ```bash
   echo -e 'def factorial(n):\n    if n == 0:\n        return 1\n    else:\n        return n * factorial(n - 1)' > factorial.py
   python3 factorial.py
   ```

**Erkenntnis**: Code Llama kann interaktiv Code vervollständigen und Debugging-Vorschläge liefern, was die Produktivität beim Programmieren steigert.

### Übung 5: Lokales Wissensmanagementsystem mit Dokumentensuche

**Ziel**: Implementieren eines Wissensmanagementsystems, das Dokumente (PDFs) durchsucht und Fragen beantwortet.

**Aufgabe**: Erstelle ein Python-Skript, das mehrere PDFs indexiert, semantische Suche mit Sentence-Transformers durchführt und Fragen mit Llama 3.1 beantwortet.

1. **Abhängigkeiten prüfen**:
   - Stelle sicher, dass `sentence-transformers` und `PyPDF2` installiert sind:
     ```bash
     pip3 install sentence-transformers PyPDF2
     ```

2. **Mehrere PDFs vorbereiten**:
   - Erstelle oder lade Beispiel-PDFs:
     ```bash
     mkdir ~/llm-project/docs
     echo -e "# Dokument 1\nLokale LLMs sind datenschutzfreundlich." > doc1.txt
     echo -e "# Dokument 2\nHomeLab-Umgebungen nutzen Proxmox und TrueNAS." > doc2.txt
     pandoc doc1.txt -o docs/doc1.pdf
     pandoc doc2.txt -o docs/doc2.pdf
     ```

3. **Python-Skript für Wissensmanagement erstellen**:
   ```bash
   nano knowledge_manager.py
   ```
   - Inhalt:
     ```python
     import os
     import PyPDF2
     from sentence_transformers import SentenceTransformer
     import requests
     import json

     model = SentenceTransformer('all-MiniLM-L6-v2')

     def extract_text_from_pdfs(directory):
         documents = []
         for filename in os.listdir(directory):
             if filename.endswith(".pdf"):
                 with open(os.path.join(directory, filename), 'rb') as file:
                     reader = PyPDF2.PdfReader(file)
                     text = ""
                     for page in reader.pages:
                         text += page.extract_text() + "\n"
                     documents.append({"filename": filename, "text": text})
         return documents

     def semantic_search(query, documents):
         texts = [doc["text"] for doc in documents]
         query_embedding = model.encode(query)
         doc_embeddings = model.encode(texts)
         similarities = model.similarity(query_embedding, doc_embeddings)[0]
         best_idx = similarities.argmax()
         return documents[best_idx], similarities[best_idx]

     def query_document(prompt, document_text):
         url = "http://localhost:11434/api/generate"
         full_prompt = f"Dokument: {document_text}\nFrage: {prompt}"
         payload = {
             "model": "llama3.1:8b",
             "prompt": full_prompt,
             "stream": False
         }
         response = requests.post(url, json=payload)
         if response.status_code == 200:
             return json.loads(response.text)["response"]
         else:
             return f"Fehler: {response.status_code}"

     if __name__ == "__main__":
         doc_dir = "docs"
         documents = extract_text_from_pdfs(doc_dir)
         while True:
             query = input("Frage (oder 'exit' zum Beenden): ")
             if query.lower() == "exit":
                 break
             best_doc, score = semantic_search(query, documents)
             print(f"Beste Übereinstimmung: {best_doc['filename']} (Score: {score:.2f})")
             answer = query_document(query, best_doc["text"])
             print("Antwort:")
             print(answer)
             print("-" * 50)
     ```
   - **Erklärung**:
     - `extract_text_from_pdfs`: Extrahiert Text aus allen PDFs in einem Verzeichnis.
     - `semantic_search`: Findet das relevanteste Dokument mit Sentence-Transformers.
     - `query_document`: Beantwortet Fragen basierend auf dem besten Dokument mit Llama 3.1.

4. **Skript ausführen**:
   ```bash
   python3 knowledge_manager.py
   ```
   - Beispiel:
     ```
     Frage (oder 'exit' zum Beenden): Was sind die Vorteile von lokalen LLMs?
     Beste Übereinstimmung: doc1.pdf (Score: 0.92)
     Antwort:
     Lokale LLMs sind datenschutzfreundlich, da sie keine Daten an externe Server senden.
     ```

**Erkenntnis**: Die Kombination von Sentence-Transformers für semantische Suche und Llama 3.1 für Frage-Antwort ermöglicht ein lokales Wissensmanagementsystem, ideal für Forschung oder Unternehmensdokumente.

### Übung 6: Automatisierte Textgenerierung mit Scheduler

**Ziel**: Automatisieren von Textgenerierungsaufgaben (z. B. tägliche E-Mail-Vorlagen) mit einem Scheduler.

**Aufgabe**: Erstelle ein Python-Skript, das E-Mails generiert und mit `cron` täglich ausführt.

1. **Python-Skript für automatisierte E-Mail-Generierung erstellen**:
   ```bash
   nano email_scheduler.py
   ```
   - Inhalt:
     ```python
     import requests
     import json
     from datetime import datetime
     import os

     def generate_email(prompt):
         url = "http://localhost:11434/api/generate"
         payload = {
             "model": "llama3.1:8b",
             "prompt": prompt,
             "stream": False
         }
         response = requests.post(url, json=payload)
         if response.status_code == 200:
             return json.loads(response.text)["response"]
         else:
             return f"Fehler: {response.status_code}"

     if __name__ == "__main__":
         date = datetime.now().strftime("%Y-%m-%d")
         prompt = f"Schreibe eine E-Mail für den täglichen Projektbericht vom {date}."
         email_content = generate_email(prompt)
         output_dir = "email_outputs"
         os.makedirs(output_dir, exist_ok=True)
         with open(f"{output_dir}/daily_report_{date}.txt", "w") as f:
             f.write(email_content)
         print(f"E-Mail gespeichert: {output_dir}/daily_report_{date}.txt")
     ```
   - **Erklärung**:
     - Generiert tägliche E-Mail-Vorlagen und speichert sie in `email_outputs`.

2. **Cron-Job einrichten**:
   ```bash
   crontab -e
   ```
   - Füge hinzu:
     ```
     0 8 * * * /usr/bin/python3 /home/ubuntu/llm-project/email_scheduler.py
     ```
   - **Erklärung**: Führt das Skript täglich um 08:00 Uhr aus.

3. **Skript testen**:
   ```bash
   python3 email_scheduler.py
   ```
   - Erwartete Ausgabe (Beispiel):
     ```
     E-Mail gespeichert: email_outputs/daily_report_2025-09-09.txt
     ```
   - Prüfe den Inhalt:
     ```bash
     cat email_outputs/daily_report_2025-09-09.txt
     ```
     - Beispiel:
       ```
       Betreff: Täglicher Projektbericht vom 2025-09-09

       Sehr geehrte Kolleginnen und Kollegen,

       hier ist der Projektbericht für den 9. September 2025:
       - Fortschritt: Aufgabe X abgeschlossen.
       - Nächste Schritte: Aufgabe Y planen.

       Mit freundlichen Grüßen,
       [Dein Name]
       ```

**Erkenntnis**: Llama 3.1 kann automatisierte Textgenerierungsaufgaben mit `cron` unterstützen, was für wiederkehrende Aufgaben wie Berichte oder E-Mails nützlich ist.

### Schritt 4: Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/llm-project-backup-$(date +%F).tar.gz ~/llm-project
     rsync -av ~/llm-project-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/llm/
     ```
   - Aktualisiere das Backup-Skript:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/llm-project-backup-$DATE.tar.gz ~/llm-project
       rsync -av /home/ubuntu/llm-project-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/llm/
       ```
2. **Netzwerkmanagement mit OPNsense**:
   - Aktualisiere die Firewall-Regel in OPNsense, um Zugriff auf `192.168.30.101:11434` (Ollama-API) und `192.168.30.101:80` (falls Apache installiert) von `192.168.30.0/24` zu erlauben.

### Schritt 5: Erweiterungsvorschläge
1. **REST-API für Programmier-Assistent**:
   - Erstelle eine Flask-API:
     ```bash
     pip3 install flask
     nano code_api.py
     ```
     - Inhalt:
       ```python
       from flask import Flask, request, jsonify
       import requests
       import json

       app = Flask(__name__)

       def complete_code(prompt):
           url = "http://localhost:11434/api/generate"
           payload = {"model": "codellama:7b", "prompt": prompt, "stream": False}
           response = requests.post(url, json=payload)
           return json.loads(response.text)["response"] if response.status_code == 200 else f"Fehler: {response.status_code}"

       @app.route("/complete", methods=["POST"])
       def complete():
           data = request.json
           prompt = data.get("prompt", "")
           result = complete_code(prompt)
           return jsonify({"completion": result})

       if __name__ == "__main__":
           app.run(host="0.0.0.0", port=5000)
       ```
   - Führe aus:
     ```bash
     python3 code_api.py
     ```
   - Teste:
     ```bash
     curl -X POST -H "Content-Type: application/json" -d '{"prompt":"def factorial(n):"}' http://192.168.30.101:5000/complete
     ```

2. **Dokumenten-Upload-Schnittstelle**:
   - Erweitere `knowledge_manager.py` um eine Upload-Funktion für neue PDFs via Flask oder Kommandozeile.

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Begrenze Ollama-Ressourcen:
    ```bash
    docker run -d --memory="6g" --cpus="4" -v ollama:/root/.ollama -p 11434:11434 ollama/ollama
    ```
  - Überwache:
    ```bash
    free -h
    df -h
    ```
- **Sicherheit**:
  - Schränke Ollama-API-Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 11434
    ```
  - Sichere Dateien:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Ollama-Logs:
    ```bash
    docker logs $(docker ps -q -f ancestor=ollama/ollama)
    ```
  - Teste API:
    ```bash
    curl http://localhost:11434
    ```

**Quelle**: https://ollama.com/docs, https://sbert.net

## Empfehlungen für Schüler

- **Setup**: Ollama mit Llama 3.1 und Code Llama, Ubuntu-VM, TrueNAS-Backups.
- **Workloads**: Interaktive Code-Vervollständigung, Dokumentensuche, automatisierte E-Mails.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Debugging eines Python-Skripts, Suche in PDFs, tägliche Berichte.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit kleinen Prompts und einzelnen PDFs.
- **Übung**: Teste verschiedene Modelle (z. B. `mistral`) mit `ollama pull`.
- **Fehlerbehebung**: Nutze `docker logs` und `curl` für Debugging.
- **Lernressourcen**: https://ollama.com/docs, https://sbert.net, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Diese Übungen erweitern die Nutzung lokaler LLMs für:
- **Programmierung**: Interaktive Code-Vervollständigung und Debugging.
- **Wissensmanagement**: Semantische Suche in Dokumenten.
- **Automatisierung**: Geplante Textgenerierung.

Sie sind ideal für Schüler, die lokale KI in einer HomeLab erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Monitoring (Zabbix/Prometheus), Integration mit Terraform/Ansible, oder größeren Modellen (z. B. Llama 3.2)?

**Quellen**:
- Ollama-Dokumentation: https://ollama.com
- Llama-Dokumentation: https://github.com/meta-ai/llama
- Sentence-Transformers: https://sbert.net
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,
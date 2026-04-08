# Lernprojekt: CI/CD-Pipeline mit GitHub Actions und Claude

## Einführung

Eine **CI/CD-Pipeline** (Continuous Integration / Continuous Delivery) automatisiert das Testen, Prüfen und Ausliefern von Code bei jedem Push oder Pull Request. Dieses Modul zeigt, wie man mit Claude eine GitHub Actions-Workflow-Datei für das `todo.py`-Projekt erstellt, versteht und iterativ verbessert. Das Ziel ist nicht nur eine funktionierende Pipeline – sondern ein tiefes Verständnis jeder Zeile der YAML-Konfiguration.

**Voraussetzungen**:
- Todo-Projekt aus Modul 3/4 mit funktionierenden Tests (`pytest test_todo.py`)
- Ein GitHub-Konto und ein Repository für das Projekt
- Grundkenntnisse von Git (`git add`, `commit`, `push`)
- Grundverständnis von YAML-Syntax

**Ziele**:
- Verstehen, wie GitHub Actions funktioniert (Trigger, Jobs, Steps, Runner).
- Mit Claude eine CI-Workflow-Datei generieren und jede Zeile erklären lassen.
- Die Pipeline iterativ erweitern: Tests → Linting → Coverage.
- Typische Fehler in GitHub Actions debuggen (mit Claude als Hilfe).

**Was die Pipeline am Ende tut**:
```
Bei jedem Push / Pull Request auf main:
  1. Python 3.12 einrichten
  2. Abhängigkeiten installieren
  3. Code mit flake8 auf Style-Fehler prüfen
  4. Tests mit pytest ausführen
  5. Test-Coverage-Bericht erstellen
```

**Quellen**:
- GitHub Actions Dokumentation: https://docs.github.com/en/actions
- pytest-cov: https://pytest-cov.readthedocs.io

---

## Grundlagen: GitHub Actions – Wie es funktioniert

### Kernkonzepte

```
Repository
└── .github/
    └── workflows/
        └── ci.yml          ← Workflow-Datei (YAML)

Workflow
├── Trigger (wann läuft er?)
│   └── push, pull_request, schedule, manual
├── Jobs (was läuft parallel/sequenziell?)
│   └── test-job
│       ├── runs-on: ubuntu-latest  (welcher Runner?)
│       └── steps:                  (welche Schritte?)
│           ├── checkout
│           ├── setup-python
│           ├── install deps
│           └── run tests
```

### Claude für YAML-Generierung nutzen

YAML-Syntax ist fehleranfällig (Einrückung, Sonderzeichen). Claude ist hier besonders nützlich – aber man muss jede Zeile verstehen:

```
"Erkläre mir Zeile für Zeile was dieser GitHub Actions Step macht:
- uses: actions/setup-python@v5
  with:
    python-version: '3.12'
    cache: 'pip'
"
```

---

## Übungen zum Verinnerlichen

### Übung 1: Ersten Workflow generieren und verstehen ⚙️

**Ziel**: Eine funktionierende CI-Workflow-Datei erstellen und jede Zeile verstehen.

1. **Schritt 1**: GitHub-Repository vorbereiten.
   ```bash
   cd ~/todo-projekt
   git init
   git remote add origin https://github.com/<dein-name>/todo-app.git
   # requirements.txt anlegen
   echo "pytest>=8.0" > requirements.txt
   echo "pytest-cov>=5.0" >> requirements.txt
   echo "flake8>=7.0" >> requirements.txt
   ```

2. **Schritt 2**: Workflow-Datei von Claude generieren lassen:
   ```
   Erstelle eine GitHub Actions Workflow-Datei (.github/workflows/ci.yml) für
   ein Python 3.12 Projekt mit folgenden Anforderungen:
   - Trigger: push und pull_request auf den main-Branch
   - Runner: ubuntu-latest
   - Steps: checkout, Python 3.12 einrichten (mit pip-Cache),
     pip install -r requirements.txt,
     flake8 auf todo.py und test_todo.py ausführen (max. Zeilenlänge 100),
     pytest mit Coverage-Bericht (Schwellwert: 80%)
   Füge nach jedem Step einen Kommentar ein, der erklärt was der Step tut.
   ```

3. **Schritt 3**: Die generierte YAML-Datei Zeile für Zeile lesen.
   Für alle Stellen die unklar sind:
   ```
   Was bedeutet "cache: 'pip'" in actions/setup-python? Was wird gecacht und warum?
   ```
   ```
   Was passiert wenn pytest-cov den 80%-Schwellwert nicht erreicht?
   Schlägt der Job fehl oder gibt es nur eine Warnung?
   ```

4. **Schritt 4**: Verzeichnisstruktur anlegen und pushen:
   ```bash
   mkdir -p .github/workflows
   # ci.yml erstellen (manuell abtippen, nicht copy-pasten!)
   git add .github/workflows/ci.yml requirements.txt
   git commit -m "ci: add GitHub Actions workflow"
   git push -u origin main
   ```

5. **Schritt 5**: Auf GitHub unter **Actions** den Workflow beobachten.
   - Läuft er durch?
   - Wo schlägt er ggf. fehl?

**Reflexion**: Warum ist es wichtig, die YAML-Datei selbst abzutippen statt zu kopieren? Was lernst du dabei über die Syntax?

---

### Übung 2: Fehler in der Pipeline debuggen 🐛

**Ziel**: Lernen, wie man GitHub-Actions-Fehler liest und mit Claude analysiert.

1. **Schritt 1**: Einen bekannten Fehler provozieren – `flake8` absichtlich fehlschlagen lassen.
   Füge in `todo.py` eine Zeile mit zu langen Zeichen ein (> 100 Zeichen):
   ```python
   # Diese Zeile ist absichtlich sehr lang und wird flake8 zum Fehler bringen, weil sie die maximale Zeilenlänge überschreitet
   ```
   Pushe und beobachte den Fehler in GitHub Actions.

2. **Schritt 2**: Den Fehler-Output von GitHub Actions kopieren und an Claude übergeben:
   ```
   Mein GitHub Actions Job schlägt fehl mit folgendem Output:
   [Log-Output hier einfügen]
   Was ist der konkrete Fehler und wie behebe ich ihn?
   ```

3. **Schritt 3**: Fehler beheben, pushen, Pipeline grün bekommen.

4. **Schritt 4**: Coverage-Schwellwert als Fehlerquelle testen.
   Reduziere den Schwellwert auf 95% im Workflow:
   ```yaml
   run: pytest --cov=todo --cov-fail-under=95
   ```
   Hat dein Projekt 95% Coverage? Falls nicht:
   ```
   Mein pytest-cov Output zeigt 72% Coverage. Welche Bereiche in todo.py
   sind wahrscheinlich nicht getestet? [Code einfügen]
   ```

**Reflexion**: Welche Arten von Fehlern kann GitHub Actions finden, die dir lokal nicht auffallen würden? (Denke an unterschiedliche Python-Versionen, fehlende Dependencies, etc.)

---

### Übung 3: Pipeline mit Matrix-Strategy erweitern 🔢

**Ziel**: Die Pipeline so erweitern, dass sie auf mehreren Python-Versionen gleichzeitig testet.

1. **Schritt 1**: Konzept verstehen – Claude fragen:
   ```
   Erkläre mir das Konzept der Matrix-Strategy in GitHub Actions.
   Wann ist es sinnvoll und wann übertrieben?
   Beispiel: Ich möchte auf Python 3.11 und 3.12 testen.
   ```

2. **Schritt 2**: Bestehenden Workflow anpassen.
   Claude zeigt das Muster, du implementierst es:
   ```yaml
   strategy:
     matrix:
       python-version: ["3.11", "3.12"]
   ```
   Passe alle Python-Versionsreferenzen im Workflow entsprechend an.

3. **Schritt 3**: `.github/workflows/ci.yml` aktualisieren, pushen.
   In GitHub Actions sollten nun **zwei parallele Jobs** laufen.

4. **Schritt 4**: Optional – einen zweiten Job für Sicherheitsprüfungen hinzufügen:
   ```
   Wie füge ich einen zweiten Job "security-check" hinzu, der pip-audit ausführt
   und nach bekannten Sicherheitslücken in den Dependencies sucht?
   Der Job soll nach dem test-Job laufen (needs: test).
   ```

**Abschlussprojekt-Checkliste**:
- [ ] `.github/workflows/ci.yml` liegt im Repository
- [ ] Pipeline läuft bei Push auf main automatisch
- [ ] flake8 prüft Code-Style
- [ ] pytest läuft mit Coverage-Report
- [ ] Jede Zeile der YAML-Datei wurde verstanden (ggf. mit Claudes Hilfe erklärt)
- [ ] Pipeline schlägt bei Test-Fehlern korrekt fehl (getestet)
- [ ] Matrix-Strategy für mehrere Python-Versionen eingerichtet

**Reflexion**: Was kostet eine CI-Pipeline (Zeit, Ressourcen)? Wann lohnt sich der Aufwand und wann ist er für ein kleines Projekt übertrieben?

---

## Häufige GitHub Actions Fallstricke

| Problem | Ursache | Lösung |
|---|---|---|
| `ModuleNotFoundError` im Job | Requirements nicht installiert | `pip install -r requirements.txt` vor Tests |
| YAML-Syntax-Fehler | Falsche Einrückung | Online-YAML-Validator oder `yamllint` nutzen |
| Tests lokal grün, CI rot | Unterschiedliche Python-Version | Matrix-Strategy mit exakter Version |
| Workflow startet nicht | Falscher Branch-Name (`master` vs. `main`) | Trigger-Konfiguration prüfen |
| Secrets im Log sichtbar | Passwort direkt im YAML | GitHub Secrets (`${{ secrets.NAME }}`) nutzen |

---

## Fazit

GitHub Actions automatisiert die Qualitätssicherung und gibt sofortiges Feedback bei jedem Code-Push. Claude ist beim Generieren und Erklären von YAML-Konfigurationen sehr hilfreich – aber das Verstehen der Pipeline ist unerlässlich, um Fehler eigenständig debuggen zu können.

**Nächste Schritte**:
- **Modul 6**: Migration zu SQLite – wenn die JSON-Datei an ihre Grenzen stößt.

# Praxisorientierte Anleitung: Ansible-Rollen, Vault und automatisiertes Testen

## Einführung
Der [Einstieg in Ansible](01_Ansible_Einstieg_Linux_Updates.md) und die Checkmk-`HowTo`-Anleitungen in diesem Ordner zeigen einzelne, flache Playbooks (`hosts: localhost`, alle Tasks in einer Datei). Das funktioniert für kleine Aufgaben, ist aber **nicht der Stand der Technik für produktiven Ansible-Einsatz**. Diese Anleitung schließt die Lücke zwischen "Playbook, das einmal läuft" und "wartbare, testbare Automatisierung": Rollen statt Einzeldateien, sauberer Umgang mit Secrets über Ansible Vault, automatisierte Qualitätsprüfung mit `ansible-lint`, Idempotenz- und Funktionstests mit Molecule sowie echte dynamische Inventare statt statischer Host-Listen.

**Voraussetzungen**:
- Ein Linux-System (z. B. Debian 12/13) mit Python 3 und Docker (für Molecule und die Inventar-Übung).
- Ansible installiert (siehe [01_Ansible_Einstieg_Linux_Updates.md](01_Ansible_Einstieg_Linux_Updates.md)).
- Grundkenntnisse aus der Einstiegs-Anleitung (Inventar, Playbooks, Module).
- Installation der zusätzlichen Werkzeuge:
  ```bash
  pip3 install ansible-lint molecule molecule-plugins[docker]
  ansible-galaxy collection install community.docker
  ```

## Grundlegende Konzepte

- **Rolle**: Eine standardisierte Verzeichnisstruktur (`tasks/`, `handlers/`, `defaults/`, `vars/`, `templates/`, `files/`, `meta/`), die eine Automatisierungsaufgabe wiederverwendbar und in sich abgeschlossen macht – statt eines Playbooks, das nur an einer Stelle funktioniert.
- **Collection**: Ein Paket aus Rollen, Modulen und Plugins (z. B. `checkmk.general`, `community.docker`), das über `ansible-galaxy` installiert und über `requirements.yml` versioniert wird – wichtig, damit ein Playbook auch Monate später noch reproduzierbar läuft.
- **ansible-lint**: Ein statischer Codeprüfer speziell für Ansible-Inhalte (nicht nur YAML-Syntax, sondern Ansible-Best-Practices wie fehlende `name`-Attribute, unsichere Module, veraltete Syntax).
- **Idempotenz**: Ein Playbook ist idempotent, wenn ein zweiter Lauf ohne zwischenzeitliche Änderungen am Zielsystem **keine** Änderungen mehr meldet (`changed=0`). Das ist keine Behauptung, die man einfach in die Dokumentation schreibt – man muss sie testen.
- **Ansible Vault**: Verschlüsselt sensible Daten (Passwörter, API-Tokens) innerhalb von YAML-Dateien. `ansible-vault create vault.yml` verschlüsselt eine **ganze Datei** – praktikabler ist oft, nur einzelne Werte mit `ansible-vault encrypt_string` zu verschlüsseln und direkt in eine sonst lesbare `vars`-Datei einzubetten.
- **Molecule**: Ein Test-Framework für Ansible-Rollen. Es erstellt Testinstanzen (z. B. Docker-Container), führt die Rolle darauf aus, prüft das Ergebnis und testet Idempotenz automatisiert – statt manuell "einmal laufen lassen und hoffen".
- **Dynamisches Inventar**: Statt Hosts von Hand in eine `inventory.yml` zu schreiben, liefert ein Inventar-Plugin die Hosts automatisch aus einer Quelle (Cloud-API, Docker-Daemon, CMDB, Checkmk). Das ist der Normalfall in echten, sich ändernden Umgebungen.

## Übungen zum Verinnerlichen

### Übung 1: Vom Playbook zur Rolle
**Ziel**: Das Update-Playbook aus der Einstiegs-Anleitung in eine wiederverwendbare Rolle mit versionierten Collection-Abhängigkeiten umwandeln.

1. Projektstruktur anlegen und Rolle generieren:
   ```bash
   mkdir -p ansible_rollen_projekt/roles
   cd ansible_rollen_projekt
   ansible-galaxy init roles/system_update
   ```
   Das erzeugt die Standardstruktur `roles/system_update/{tasks,handlers,defaults,vars,templates,files,meta,tests}`.
2. Die Update-Logik aus dem Playbook der Einstiegs-Anleitung in `roles/system_update/tasks/main.yml` verschieben (die `apt`/`dnf`/`zypper`-Tasks mit den `when`-Bedingungen aus Übung 2 dort).
3. Variable Werte (z. B. `cache_valid_time`) nach `roles/system_update/defaults/main.yml` auslagern, statt sie fest im Task zu verdrahten:
   ```yaml
   # roles/system_update/defaults/main.yml
   apt_cache_valid_time: 3600
   ```
4. Ein schlankes Playbook erstellt, das nur noch die Rolle referenziert:
   ```yaml
   # site.yml
   ---
   - name: Systeme aktualisieren
     hosts: all
     become: true
     roles:
       - system_update
   ```
5. Externe Collection-Abhängigkeiten explizit und versioniert deklarieren:
   ```yaml
   # requirements.yml
   collections:
     - name: community.docker
       version: ">=3.10.0"
     - name: checkmk.general
       version: ">=5.0.0"
   ```
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

**Reflexion**: Was ändert sich praktisch, wenn `system_update` nicht mehr fest im Playbook steht, sondern als eigenständige Rolle vorliegt – z. B. wenn dieselbe Update-Logik in drei verschiedenen Projekten gebraucht wird?

### Übung 2: ansible-lint und Idempotenz nachweisen
**Ziel**: Die Rolle automatisiert auf Ansible-Best-Practices prüfen und Idempotenz nicht nur behaupten, sondern belegen.

1. Rolle linten:
   ```bash
   ansible-lint roles/system_update
   ```
   Typische Fundstellen: fehlende `name`-Attribute auf Tasks, `changed_when` fehlt bei `command`/`shell`-Tasks, unsichere Standardwerte. Behebe die gemeldeten Punkte.
2. Playbook einmal ausführen und danach ein zweites Mal mit `--check --diff`, um zu sehen, ob noch Änderungen anfallen würden, ohne sie tatsächlich anzuwenden:
   ```bash
   ansible-playbook -i inventory.yml site.yml
   ansible-playbook -i inventory.yml site.yml --check --diff
   ```
3. Baue eine einfache Idempotenz-Prüfung in ein Shell-Skript, die den zweiten Lauf automatisch auswertet:
   ```bash
   ansible-playbook -i inventory.yml site.yml > /dev/null
   OUTPUT=$(ansible-playbook -i inventory.yml site.yml)
   echo "$OUTPUT" | grep -q "changed=0" && echo "Idempotent!" || echo "NICHT idempotent - Playbook aendert bei jedem Lauf etwas."
   ```

**Reflexion**: Ein Playbook meldet beim zweiten Lauf `changed=2`, obwohl sich am Zielsystem nichts geändert hat. Was sagt dir das über die Qualität der verwendeten Tasks/Module, und wo würdest du in `roles/system_update/tasks/main.yml` nachsehen?

### Übung 3: Ansible Vault richtig einsetzen
**Ziel**: Secrets granular verschlüsseln, statt ganze Dateien im Klartext-Vault-Muster zu verwalten, und mit mehreren Umgebungen (z. B. dev/prod) arbeiten.

1. Statt einer kompletten Vault-Datei nur einen einzelnen Wert verschlüsseln:
   ```bash
   ansible-vault encrypt_string 'mein-geheimes-passwort' --name 'api_password'
   ```
   Das Ergebnis (ein `!vault`-Block) direkt in eine ansonsten lesbare Variablendatei einfügen, z. B. `group_vars/all/vars.yml`:
   ```yaml
   api_user: automation
   api_password: !vault |
     $ANSIBLE_VAULT;1.1;AES256
     653965386239...
   ```
   Vorteil gegenüber `ansible-vault create vault.yml`: Die Datei bleibt lesbar und versionierbar (Git-Diff zeigt, welche *unverschlüsselten* Variablen sich ändern), nur der eigentliche Geheimwert ist verschlüsselt.
2. Ein Passwort in eine Datei auslagern, statt es bei jedem Aufruf einzutippen (Datei nicht ins Git-Repo einchecken, z. B. via `.gitignore`):
   ```bash
   echo "mein-vault-passwort" > ~/.vault_pass
   chmod 600 ~/.vault_pass
   ansible-playbook -i inventory.yml site.yml --vault-password-file ~/.vault_pass
   ```
3. Mehrere Vault-IDs für unterschiedliche Umgebungen nutzen, z. B. getrennte Passwörter für `dev` und `prod`:
   ```bash
   ansible-vault encrypt_string 'dev-secret' --name 'api_password' --vault-id dev@prompt
   ansible-vault encrypt_string 'prod-secret' --name 'api_password' --vault-id prod@~/.vault_pass_prod
   ansible-playbook -i inventory.yml site.yml --vault-id dev@prompt --vault-id prod@~/.vault_pass_prod
   ```

**Reflexion**: Warum ist das Muster "eine Vault-Datei mit Klartext-Variablen darin" (wie in den Checkmk-`HowTo`-Anleitungen dieses Ordners verwendet) funktional korrekt, aber für einen Git-Verlauf mit mehreren Mitwirkenden weniger praktikabel als verschlüsselte Einzelwerte?

### Übung 4: Die Rolle mit Molecule testen
**Ziel**: Automatisiert prüfen, dass die Rolle tut, was sie soll – und zwar idempotent, ohne manuelles Nachschauen.

1. Molecule-Testszenario für die Rolle initialisieren:
   ```bash
   cd roles/system_update
   molecule init scenario -d docker
   ```
   Das legt `molecule/default/molecule.yml`, `converge.yml` und `verify.yml` an.
2. In `molecule/default/molecule.yml` eine Debian-Testinstanz als Docker-Container definieren:
   ```yaml
   platforms:
     - name: debian-test
       image: debian:12
       pre_build_image: false
       command: /sbin/init
       privileged: true
   ```
3. In `molecule/default/verify.yml` prüfen, dass ein erwartetes Ergebnis der Rolle zutrifft, z. B. dass das Paket-Cache-Update tatsächlich stattgefunden hat:
   ```yaml
   ---
   - name: Verify
     hosts: all
     tasks:
       - name: Pruefe, dass apt-Cache aktuell ist
         ansible.builtin.command: apt list --upgradable
         register: upgradable
         changed_when: false
       - name: Ausgabe anzeigen
         ansible.builtin.debug:
           var: upgradable.stdout_lines
   ```
4. Kompletten Testlauf inklusive automatischem Idempotenz-Check starten:
   ```bash
   molecule test
   ```
   Molecule führt die Rolle zweimal aus und schlägt fehl, wenn der zweite Lauf `changed` meldet – der manuelle Idempotenz-Check aus Übung 2 wird damit fester Teil der Testpipeline.

**Reflexion**: Was ist der Unterschied zwischen "ich habe das Playbook einmal manuell gegen einen Testserver laufen lassen" und "`molecule test` läuft in der CI-Pipeline bei jedem Commit"?

### Übung 5: Echtes dynamisches Inventar
**Ziel**: Hosts nicht mehr von Hand in eine `inventory.yml` eintragen, sondern automatisch aus einer laufenden Quelle beziehen.

1. Ein paar Test-Container starten, die als "Zielsysteme" dienen:
   ```bash
   docker run -d --name web1 -l ansible_group=webserver debian:12 sleep infinity
   docker run -d --name db1 -l ansible_group=datenbank debian:12 sleep infinity
   ```
2. Ein dynamisches Inventar über das `community.docker.docker_containers`-Plugin konfigurieren:
   ```yaml
   # docker_containers.yml
   plugin: community.docker.docker_containers
   compose:
     ansible_connection: "'docker'"
   groups:
     webserver: "'ansible_group' in docker_container.Config.Labels and docker_container.Config.Labels['ansible_group'] == 'webserver'"
     datenbank: "'ansible_group' in docker_container.Config.Labels and docker_container.Config.Labels['ansible_group'] == 'datenbank'"
   ```
3. Das Inventar anzeigen und mit einem Ad-hoc-Befehl gegen die automatisch erkannten Gruppen arbeiten:
   ```bash
   ansible-inventory -i docker_containers.yml --graph
   ansible webserver -i docker_containers.yml -m ansible.builtin.command -a "hostname"
   ```
4. Einen weiteren Container mit passendem Label starten und das Inventar erneut abfragen – der neue Host erscheint automatisch, ohne dass irgendeine Datei manuell angepasst wurde.

**Reflexion**: Im Vergleich zur statischen `inventory.yml` aus der Einstiegs-Anleitung – was passiert dort, wenn ein Server hinzukommt oder wegfällt, und was passiert hier?

## Tipps für den Erfolg
- Rollen so schreiben, dass sie ohne Anpassung in einem zweiten Projekt wiederverwendbar sind – das ist der eigentliche Test, ob es wirklich eine Rolle ist oder nur ein umbenanntes Playbook.
- `requirements.yml` immer mit Versionsangaben committen, nie "neueste Version installieren" voraussetzen – sonst funktioniert ein Playbook heute anders als in einem Jahr.
- `ansible-lint` und `molecule test` in eine CI-Pipeline einbinden (siehe auch [HowTo_Integrate_Checkmk_Ansible_Playbooks_Into_CI_CD_Pipelines.md](HowTo_Integrate_Checkmk_Ansible_Playbooks_Into_CI_CD_Pipelines.md) für das grundsätzliche CI/CD-Muster in diesem Ordner), statt sie nur lokal von Hand auszuführen.
- Vault-Passwortdateien (`~/.vault_pass*`) niemals ins Repository einchecken – in `.gitignore` aufnehmen.

## Fazit
Der Weg von einem einzelnen, funktionierenden Playbook zu wartbarer Automatisierung führt über Rollen mit versionierten Abhängigkeiten, granulare statt pauschale Vault-Verschlüsselung, automatisierte Qualitäts- und Idempotenz-Prüfung mit `ansible-lint`/Molecule und dynamische statt statische Inventare. Alle bisherigen Checkmk-`HowTo`-Anleitungen in diesem Ordner lassen sich nach demselben Muster refactoren – das ist eine gute Übung, um das hier Gelernte zu vertiefen.

**Quellen**:
- Ansible-Dokumentation zu Rollen: https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html
- Ansible Vault: https://docs.ansible.com/ansible/latest/vault_guide/index.html
- ansible-lint-Dokumentation: https://ansible.readthedocs.io/projects/lint/
- Molecule-Dokumentation: https://ansible.readthedocs.io/projects/molecule/
- `community.docker.docker_containers`-Inventar-Plugin: https://docs.ansible.com/ansible/latest/collections/community/docker/docker_containers_inventory.html

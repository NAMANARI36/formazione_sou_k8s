# Ansible

Ansible è uno strumento che permette di scrivere e eseguire automazioni su un insieme di **Nodi**, con l'obiettivo di portare quest ultimi ad uno stato desiderato.


Ansible è uno strumento open source di automatizzazione IT, sviluppato da Red Hat. Ansible può essere utilizzato per varie cose, tra cui: 
- Provisioning di infrastrutture
- Configuration management
- Application deployment
- Orchestration

## Caratteristiche principali

**Agentless**: non richiede l'installazione di software dedicato sui **Managed Node**. Sfrutta componenti di norma già presenti sul target da configurare, per esempio un interprete Python e il metodo di connessione via SSH.

**Dichiarativo**: il codice scritto nelle automatizzazioni descrive lo stato che la macchina deve raggiungere ma non i passaggi procedurali per arrivarci.

**Idempotente**: applicare la stessa automazione più volte sulla stessa macchina produce sempre lo stesso stato, dato che le modifiche vengono applicate solo quando lo stato reale differisce da quello desiderato.

**Basato su YAML (YAML Ain't Markup Language)**: i file di automatizzazione sono scritti in YAML, facilmente leggibile e versionabile.

## Architettura

**Control Node**: host da cui vengono lanciate le automazioni.

**Managed Nodes**: sono gli host target delle automatizzazioni Ansible.

**Inventory**: insieme strutturato degli host, organizzati in gruppi, da cui il **Play** seleziona i target tramite la keyword `hosts`. Può essere statico (file INI o YAML) o dinamico (generato da un inventory plugin che interroga ad esempio un cloud provider). Le directory `group_vars/` e `host_vars/` sono la best practice per organizzare le variabili rispettivamente per gruppo e per singolo host.

**Playbook**: file YAML che contiene la lista ordinata di uno o più play.

**Play**: sezione all'interno del **Playbook** che mappa un gruppo di host, selezionati dall'**Inventory**, a una lista di **Task** o **Role**.

**Task**: singola azione da eseguire sul nodo target, realizzata attraverso un **Module**.

**Module**: unità di codice che implementa una singola azione. Nella maggior parte dei casi viene trasferito ed eseguito sul **Managed node**, ma alcune categorie (cloud, network) vengono eseguite sul **Control node**. La maggior parte è scritta in Python, ma il contratto richiede solo che il module produca output in formato JSON. <br> 
Best practice di nomenclatura: usare il **Fully Qualified Collection Name (FQCN)**, nel formato `namespace.collection.module` (es. `ansible.builtin.copy`), per evitare ambiguità tra collection diverse.

**Roles**: strutture per organizzare **Playbook** complessi in modo modulare e riutilizzabile.

**Plugins**: componenti scaricabili che estendono le funzionalità di Ansible


**Collections**: unità di distribuzione che può raggruppare **Module**, **Role** e **Plugin**.

## Come viene eseguito un module

1. Il **Control Node** assembla il codice del **Module** con gli argomenti passati dal **Task**.
2. Trasferisce il **Module** assemblato sul **Managed Node** via SSH, in una directory temporanea.
3. Esegue il **Module** sul target usando l'interprete Python presente **Managed Node**.
4. Il **Module** ritorna il risultato in formato JSON sullo standard output.
5. Ansible legge il JSON, elabora il risultato e rimuove il file temporaneo dal **Managed Node**.


## Task
I task sono composti da tre elementi fondamentali, il nome, la chiamata al modulo e le keyword di configurazione del task.

```
  - name: Install nginx web server   # Nome del task
  become: true                     # Keyword di configurazione del task
    ansible.builtin.apt:           # Modulo
      name: nginx                  # Parametro del modulo
      state: presentx              # Parametro del modulo
```

### Handlers

Task speciali eseguiti **solo quando notificati** e **solo se il task notificante ha prodotto un cambiamento** (`changed`):

1. Un task include la direttiva `notify` che punta al nome di un handler.
2. Se il task risulta `changed`, l'handler viene messo in coda.
3. Gli handler in coda vengono eseguiti **alla fine del play**, ciascuno una sola volta anche se notificato più volte.

## Parametrizzazione

**Variables**: parametrizzano **Playbook** e **Ruoli**. Il punto architetturalmente rilevante è la scala di priorità delle variabili, utile quando la stessa variabile è definita in più punti (**Inventory**, `group_vars/`, `host_vars/`, **Play**, **Role**, riga di comando), Ansible applica un ordine di precedenza preciso. In generale vincono quelle più vicine all'esecuzione; le **extra vars** (`-e` da CLI (Command Line Interface)) hanno la precedenza massima.

**Facts**: dati raccolti automaticamente dai **Managed Node** all'inizio dell'esecuzione, durante il **Fact Gathering**, eseguito dal module `ansible.builtin.setup`. Contengono informazioni sul target (sistema operativo, indirizzi IP, RAM, architettura CPU, dischi). Accessibili come variabili (es. `ansible_facts['os_family']`) e utili per la logica condizionale. Il gathering è disabilitabile con `gather_facts: false` per velocizzare l'esecuzione quando non serve.

##Templates

Un template è un file che contiene testo statico misto ad espressioni Jinja2(`{{ variabile }}`, `{% for %}`, `{% if %}`) che permettono la composizione del file in modo dinamico.

Quindi una formulazione più precisa: un template è un file sorgente (convenzionalmente con estensione .j2) che contiene testo statico misto a costrutti Jinja2 — expressions {{ }} per l'interpolazione di valori, statements {% %} per la logica di controllo — che, sottoposto a rendering dal templating engine Jinja2 tramite il module ansible.builtin.template, produce un file di output il cui contenuto dipende da variabili e facts del target.

vault
---

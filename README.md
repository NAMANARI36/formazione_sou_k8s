# formazione_sou_k8s

Descrizione generale relativa a quanto svolto nella Track 2. <br/>
**Obiettivo:** realizzare una pipeline CI/CD completa, partendo dal provisioning di una VM locale fino al deploy di una web app su un cluster Kubernetes, orchestrando l'infrastruttura con Ansible, la build/push delle immagini con Jenkins e il rilascio con Helm.

## Preview dell'infrastruttura

```
Host (macOS Intel)
 │
 ├─ Vagrant ──► VM Rocky Linux 9
 │                └─ Ansible (site.yml) provisiona 4 role:
 │                     ├─ podman
 │                     ├─ podman_network
 │                     ├─ jenkins_controller  ──► Quadlet + JCasC
 │                     └─ jenkins_agent        ──► Quadlet e build via socket Podman dell'host
 │
 ├─ Pipeline "flask-app-example-build"
 │     build immagine con Podman ──► push su Docker Hub
 │     tagging: git tag │ main → latest │ develop → develop-<sha7>
 │
 └─ Cluster kind "formazione-sou"
       Pipeline "helm-install" ──► helm upgrade --install ──► namespace formazione-sou
```


## Tecnologie utilizzate

| Funzione | Dettagli |
|---|---|
| Provisioning VM | Vagrant, Rocky Linux 9 |
| Configuration management | Ansible |
| Container runtime | Podman + Quadlet |
| CI/CD | Jenkins (Controller + Agent), pipeline dichiarative, JCasC (Jenkins Configuration as Code) |
| Applicazione | Flask (Python) |
| Registry immagini | Docker Hub |
| Packaging & deploy | Helm |
| Cluster Kubernetes | kind (Kubernetes IN Docker) |


## Struttura della repository

```
.
├─ vagrant/            Vagrantfile 
├─ ansible/            provisioning
│   ├─ site.yml        playbook principale (4 role in sequenza)
│   ├─ ansible.cfg     configurazione di progetto
│   ├─ inventory/      hosts, group_vars, host_vars e vault
│   └─ roles/          podman, podman_network, jenkins_controller, jenkins_agent
├─ app/                web app Flask (app.py e Dockerfile)
├─ scripts/            Script bash richiesto nello step 5
├─ charts/
│   └─ flask-app/      Helm chart per il deploy dell'immagine
├─ pipelines/
│   ├─ flask-app-example-build/   Jenkinsfile per build + push immagine sul registry Docker Hub
│   └─ helm-install/              Jenkinsfile per deploy con helm
└─ cluster-kind/
    └─ kind-config.yaml   File di configurazione del cluster kind

```

## Step principali

**1 — Provisioning (Vagrant + Ansible)** <br/>
Vagrant crea la VM Rocky Linux 9. <br/>
Il playbook **site.yml** applica in sequenza quattro role: 
- Installazione di Podman 
- Creazione della rete Podman con IP statici
- Deploy del Jenkins Controller (immagine custom + configurazione dichiarativa via JCasC)
- Deploy del Jenkins Agent (immagine custom con Helm e Kubectl) che si collega automaticamente al controller autenticandosi con il secret JNLP che Ansible recupera dal controller e inietta a runtime

**2 — Build & push (pipeline flask-app-example-build)** <br/>
Pipeline dichiarativa che builda l'immagine della web app Flask e la pusha su Docker Hub. La build usa **podman --remote** verso il socket dell'host. Il tag dell'immagine è derivato dal riferimento Git, che sarà uguale al git tag se buildata da tag, **latest** sul branch **main**, **develop-<sha7>** sul branch **develop** o altrimenti il nome del branch.

**3 — Helm chart (charts/flask-app).** <br/> 
Chart custom che deploya l'immagine prodotta dalla pipeline. Il tag da rilasciare è parametrizzabile dall'input. Genera un Deployment e un Service ClusterIP.

**4 — Deploy su Kubernetes (pipeline helm-install).** <br/> 
Pipeline dichiarativa che fa il checkout della repo, esegue **helm lint** sul chart e poi **helm upgrade --install** sul cluster kind, nel namespace **formazione-sou**. Il kubeconfig è fornito come credential Jenkins di tipo Secret file e il tag immagine è passato come parametro della build.

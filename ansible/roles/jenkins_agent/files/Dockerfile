# Dockerfile utilizzato per buildare l'immagine custom dell'Agent Jenkins, con l'obiettivo di renderlo capace di eseguire 
# build attraverso la podman CLI usata come client remoto verso il socket Podman dell'host.
# La build delle immagini avviene sull'host(via socket).
# Immagine custom basata su jenkins/inbound-agent:latest
FROM jenkins/inbound-agent:latest

# Passa a root per installare pacchetti
USER root

# Installa podman
RUN apt-get update \
    && apt-get install -y --no-install-recommends podman 

# Scarica il binario di kubectl e lo rende eseguibile
RUN curl -fsSL -o /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# Scarica lo script di download di helm e lo esegue per installare helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
        | bash

# Torna all'utente non privilegiato per l'esecuzione dell'agent.
USER jenkins
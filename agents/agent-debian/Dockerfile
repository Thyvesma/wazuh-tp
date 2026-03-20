# Agent Wazuh sur Debian 12 (Bookworm)
# Distribution Linux : Debian
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)

FROM debian:12-slim

# Métadonnées
LABEL maintainer="TP Wazuh"
LABEL description="Wazuh Agent - Debian 12"
LABEL wazuh.version="4.14.4"

# Variables pour l'installation
ARG WAZUH_AGENT_VERSION=4.14.4-1
ENV WAZUH_MANAGER=wazuh-manager

# Installation des dépendances et de l'agent Wazuh
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    apt-transport-https \
    ca-certificates \
    procps \
    && curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && WAZUH_MANAGER=${WAZUH_MANAGER} apt-get install -y --no-install-recommends wazuh-agent=${WAZUH_AGENT_VERSION} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copie du script d'entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# L'agent doit être enregistré manuellement ou via agent-auth
# Le script configure le manager et démarre l'agent
ENTRYPOINT ["/entrypoint.sh"]
CMD ["wazuh-agentd"]

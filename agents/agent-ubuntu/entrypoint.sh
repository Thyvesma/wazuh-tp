#!/bin/bash
# Script d'entrypoint pour l'agent Wazuh sur Ubuntu
# Configure l'adresse du manager et démarre l'agent

set -e

# Configuration du manager (depuis variable d'environnement ou valeur par défaut)
WAZUH_MANAGER="${WAZUH_MANAGER:-wazuh-manager}"
OSSEC_CONF="/var/ossec/etc/ossec.conf"

# Mise à jour de la configuration avec l'adresse du manager
if [ -f "$OSSEC_CONF" ]; then
    sed -i "s|<address>.*</address>|<address>${WAZUH_MANAGER}</address>|g" "$OSSEC_CONF"
fi

# Démarrer l'agent
if [ "$1" = "wazuh-agentd" ]; then
    exec /var/ossec/bin/wazuh-agentd -f
else
    exec "$@"
fi

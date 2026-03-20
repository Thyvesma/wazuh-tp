#!/bin/bash
# Procédure d'enrôlement des agents Wazuh
# Méthode 1: agent-auth (depuis l'agent)
# Méthode 2: manage_agents (depuis le manager)

echo "=== Enrôlement des agents Wazuh ==="
echo ""
echo "MÉTHODE 1 - agent-auth (depuis chaque conteneur agent):"
echo "  docker exec -it wazuh-agent-debian /var/ossec/bin/agent-auth -m wazuh-manager"
echo "  docker exec -it wazuh-agent-ubuntu /var/ossec/bin/agent-auth -m wazuh-manager"
echo ""
echo "MÉTHODE 2 - manage_agents (depuis le manager):"
echo "  1. Lister les agents en attente:"
echo "     docker exec -it wazuh-manager /var/ossec/bin/manage_agents -l"
echo ""
echo "  2. Ajouter un agent (génère une clé):"
echo "     docker exec -it wazuh-manager /var/ossec/bin/manage_agents -a"
echo ""
echo "  3. Importer la clé dans l'agent:"
echo "     docker exec -it wazuh-agent-debian /var/ossec/bin/manage_agents -i <CLE>"
echo ""
echo "  4. Valider l'agent sur le manager:"
echo "     docker exec -it wazuh-manager /var/ossec/bin/manage_agents -e <ID>"
echo ""

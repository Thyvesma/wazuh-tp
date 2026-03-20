#!/bin/bash
# Script de vérification de l'installation Wazuh Docker
# Exécuter : ./scripts/verifier-installation.sh

set -e

echo "=========================================="
echo "  Vérification environnement Wazuh      "
echo "  $(date)"
echo "=========================================="
echo ""

# 1. Conteneurs
echo "1. État des conteneurs :"
docker compose ps -a 2>/dev/null || docker-compose ps -a 2>/dev/null || echo "   Erreur: docker compose non disponible"
echo ""

# 2. Manager - statut des services
echo "2. Services Wazuh dans le manager :"
docker exec wazuh-manager /var/ossec/bin/ossec-control status 2>/dev/null || echo "   Manager non accessible (démarrer avec: docker compose up -d)"
echo ""

# 3. Agents connectés
echo "3. Agents enregistrés et connectés :"
docker exec wazuh-manager /var/ossec/bin/agent_control -l 2>/dev/null || echo "   Impossible de lister les agents"
echo ""

# 4. Dernières alertes
echo "4. Dernières lignes de alerts.json (si existant) :"
docker exec wazuh-manager tail -5 /var/ossec/logs/alerts/alerts.json 2>/dev/null || echo "   Fichier vide ou non accessible"
echo ""

# 5. Test de connexion
echo "5. Test API Manager (port 55000) :"
docker exec wazuh-manager curl -k -s -o /dev/null -w "%{http_code}" https://localhost:55000 2>/dev/null && echo " - OK" || echo "   Échec"
echo ""

echo "=========================================="
echo "  Vérification terminée"
echo "=========================================="

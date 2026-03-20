#!/bin/bash
# Génération de certificats SSL pour le Wazuh Manager (Filebeat)
# Requis par l'image Docker même sans indexer - évite les erreurs au démarrage
# Ces certificats sont utilisés pour la communication TLS (désactivée sans indexer)

set -e

CERT_DIR="$(cd "$(dirname "$0")/.." && pwd)/config/certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "Génération des certificats dans $CERT_DIR"

# CA racine
openssl genrsa -out root-ca.key 4096 2>/dev/null
openssl req -new -x509 -days 3650 -key root-ca.key -out root-ca.pem \
    -subj "/C=FR/ST=IDF/L=Paris/O=Wazuh-TP/CN=Root CA" 2>/dev/null

# Certificat manager (utilisé comme filebeat.pem)
openssl genrsa -out wazuh-manager.key 2048 2>/dev/null
openssl req -new -key wazuh-manager.key -out wazuh-manager.csr \
    -subj "/C=FR/ST=IDF/L=Paris/O=Wazuh-TP/CN=wazuh-manager" 2>/dev/null
openssl x509 -req -in wazuh-manager.csr -CA root-ca.pem -CAkey root-ca.key \
    -CAcreateserial -out wazuh-manager.pem -days 3650 2>/dev/null

# Copies pour le manager (noms attendus par l'image Docker)
cp root-ca.pem root-ca-manager.pem 2>/dev/null || true
cp wazuh-manager.pem filebeat.pem
cp wazuh-manager.key filebeat.key

# Nettoyage
rm -f wazuh-manager.csr root-ca.srl

echo "Certificats générés avec succès."
echo "Fichiers créés : root-ca.pem, root-ca-manager.pem, filebeat.pem, filebeat.key"

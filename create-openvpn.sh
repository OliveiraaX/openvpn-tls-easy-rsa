#!/bin/bash

# Função para coletar informações
get_input() {
    local prompt=$1
    local var_name=$2
    read -p "$prompt" $var_name
}

# Função para configurar o servidor OpenVPN
configure_server() {
    get_input "IP do servidor: " SERVER_IP
    get_input "Nome do servidor: " SERVER_NAME
    get_input "Rede virtual da VPN (ex: 10.8.0.0): " IPVPN
    get_input "País (ex: BR): " COUNTRY
    get_input "Estado/Província (ex: PR): " PROVINCE
    get_input "Cidade (ex: Londrina): " CITY
    get_input "Nome da organização (ex: TI): " ORG
    get_input "Email da organização: " EMAIL
    get_input "Unidade organizacional (ex: Suporte): " OU

    echo "[+] Instalando pacotes necessários..."
    sudo apt update && sudo apt install openvpn easy-rsa -y

    echo "[+] Preparando estrutura do Easy-RSA..."
    sudo cp -r /usr/share/easy-rsa /etc/openvpn
    sudo cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars

    sudo sed -i "s|set_var EASYRSA_REQ_COUNTRY.*|set_var EASYRSA_REQ_COUNTRY \"$COUNTRY\"|g" /etc/openvpn/easy-rsa/vars
    sudo sed -i "s|set_var EASYRSA_REQ_PROVINCE.*|set_var EASYRSA_REQ_PROVINCE \"$PROVINCE\"|g" /etc/openvpn/easy-rsa/vars
    sudo sed -i "s|set_var EASYRSA_REQ_CITY.*|set_var EASYRSA_REQ_CITY \"$CITY\"|g" /etc/openvpn/easy-rsa/vars
    sudo sed -i "s|set_var EASYRSA_REQ_ORG.*|set_var EASYRSA_REQ_ORG \"$ORG\"|g" /etc/openvpn/easy-rsa/vars
    sudo sed -i "s|set_var EASYRSA_REQ_EMAIL.*|set_var EASYRSA_REQ_EMAIL \"$EMAIL\"|g" /etc/openvpn/easy-rsa/vars
    sudo sed -i "s|set_var EASYRSA_REQ_OU.*|set_var EASYRSA_REQ_OU \"$OU\"|g" /etc/openvpn/easy-rsa/vars

    cd /etc/openvpn/easy-rsa
    sudo ./easyrsa init-pki
    sudo ./easyrsa build-ca nopass
    sudo ./easyrsa gen-req $SERVER_NAME nopass
    sudo ./easyrsa sign-req server $SERVER_NAME
    sudo ./easyrsa gen-dh

    sudo cp pki/ca.crt /etc/openvpn/
    sudo cp pki/issued/$SERVER_NAME.crt /etc/openvpn/
    sudo cp pki/private/$SERVER_NAME.key /etc/openvpn/
    sudo cp pki/dh.pem /etc/openvpn/dh2048.pem

    echo "[+] Criando configuração do servidor OpenVPN..."
    sudo tee /etc/openvpn/server.conf > /dev/null <<EOF
# ========================================
#   Arquivo de configuração OpenVPN
#   Criado por: Dhiones Santana
#   Data: 13/04/2025
# ========================================
port 1194
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/$SERVER_NAME.crt
key /etc/openvpn/$SERVER_NAME.key
dh /etc/openvpn/dh2048.pem
server $IPVPN 255.255.255.0
ifconfig-pool-persist ipp.txt
keepalive 10 120
persist-key
persist-tun
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3
user nobody
group nogroup
EOF

    sudo systemctl enable openvpn@server
    sudo systemctl start openvpn@server

    echo "[+] Servidor VPN configurado com sucesso!"

    # Agora configura o primeiro cliente
    configure_client
}

# Função para configurar o cliente OpenVPN
configure_client() {
    get_input "Nome do cliente: " CLIENT_NAME

    cd /etc/openvpn/easy-rsa
    sudo ./easyrsa gen-req $CLIENT_NAME nopass
    sudo ./easyrsa sign-req client $CLIENT_NAME

    sudo cp pki/ca.crt /etc/openvpn/client/
    sudo cp pki/issued/$CLIENT_NAME.crt /etc/openvpn/client/
    sudo cp pki/private/$CLIENT_NAME.key /etc/openvpn/client/

    sudo tee /etc/openvpn/client/$CLIENT_NAME.ovpn > /dev/null <<EOF
client
dev tun
proto udp
remote $(hostname -I | awk '{print $1}') 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert $CLIENT_NAME.crt
key $CLIENT_NAME.key
verb 3
EOF

    echo "[+] Cliente VPN '$CLIENT_NAME' criado em /etc/openvpn/client/$CLIENT_NAME.ovpn"
}

# Menu interativo
echo "Selecione uma opção:"
echo "1) Criar novo servidor VPN (com cliente inicial)"
echo "2) Criar novo cliente (usando servidor existente)"
read -p "Opção [1-2]: " choice

case "$choice" in
    1) configure_server ;;
    2) configure_client ;;
    *) echo "Opção inválida." ;;
esac

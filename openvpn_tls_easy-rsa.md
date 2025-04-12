# 🛡️ Como Criar uma VPN com OpenVPN + TLS + Easy-RSA (PASSO A PASSO)

🎥 _Por Dhiones Santana_  
📆 _Data: 12/04/2025_

---

## 📦 1. Instalando os pacotes necessários

```bash
apt update
apt install openvpn easy-rsa -y
```

---

## 🗂️ 2. Preparando a estrutura da autoridade certificadora (CA)

```bash
# Copie os arquivos do easy-rsa para o diretório do OpenVPN
cp -r /usr/share/easy-rsa/ /etc/openvpn
cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars
```

### ✍️ Agora edite o arquivo `vars` com as suas informações:

```bash
nano /etc/openvpn/easy-rsa/vars
```

**Altere essas linhas no final:**

```
set_var EASYRSA_REQ_COUNTRY    "BR"
set_var EASYRSA_REQ_PROVINCE   "PR"
set_var EASYRSA_REQ_CITY       "Londrina"
set_var EASYRSA_REQ_ORG        "Ipsolution"
set_var EASYRSA_REQ_EMAIL      "dhiones.oliveirax@gmail.com"
set_var EASYRSA_REQ_OU         "Suporte"
```

---

## 🔐 3. Inicializando a PKI e criando a CA

```bash
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca
```

📝 **Dica:** Vai pedir uma senha — escolha uma forte e guarde bem!

---

## 🖥️ 4. Criando certificado e chave do servidor

```bash
./easyrsa gen-req servidor nopass
./easyrsa sign-req server servidor
```

Confirme com `yes` quando solicitado.

---

## 👤 5. Criando certificado e chave do cliente

```bash
./easyrsa gen-req cliente1 nopass
./easyrsa sign-req client cliente1
```

---

## 📁 6. Gerando a chave Diffie-Hellman

```bash
./easyrsa gen-dh
```

---

## 📦 7. Movendo os arquivos para o OpenVPN

```bash
cp pki/dh.pem /etc/openvpn/
cp pki/ca.crt /etc/openvpn/
cp pki/issued/servidor.crt /etc/openvpn/
cp pki/private/servidor.key /etc/openvpn/
```

---

## ⚙️ 8. Configurando o servidor OpenVPN

```bash
nano /etc/openvpn/server.conf
```

**Conteúdo do arquivo:**

```
# ========================================
#   Arquivo de configuração OpenVPN
#   Criado por: Dhiones Santana
#   Data: 14/04/2025
# ========================================
port 1194
proto udp
dev tun

ca /etc/openvpn/ca.crt
cert /etc/openvpn/servidor.crt
key /etc/openvpn/servidor.key
dh /etc/openvpn/dh.pem

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt

push "route 10.8.0.0 255.255.255.0"

;push "dhcp-option DNS 8.8.8.8"
;push "dhcp-option DNS 1.1.1.1"

keepalive 10 120

;comp-lzo

persist-key
persist-tun

verb 3

status /var/log/openvpn-status.log
log-append /var/log/openvpn.log

user nobody
group nogroup
```

---

## 🧳 9. Arquivo de configuração do cliente

```bash
nano cliente1.conf
```

**Conteúdo do cliente:**

```
client
tls-client
dev tun
port 1194
proto udp
remote "IP DO SERVIDOR"
remote-random
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert cliente1.crt
key cliente1.key
;comp-lzo
status openvpn-status.log
log /var/log/openvpn.log
log-append /var/log/openvpn.log
verb 5
pull
tun-mtu 1500
```

---

## 📁 10. Organização dos arquivos do cliente

Coloque os arquivos abaixo na mesma pasta do `.ovpn`:

```
cliente1.ovpn
ca.crt
cliente1.crt
cliente1.key
```

---

## ➕ 11. Como adicionar mais clientes

```bash
cd /etc/openvpn/easy-rsa
./easyrsa gen-req cliente2 nopass
./easyrsa sign-req client cliente2
```

Depois, copie o arquivo `cliente1.conf` e altere as linhas:

```
cert cliente2.crt
key cliente2.key
```

Transfira os arquivos para o novo host:

```
cliente2.ovpn
ca.crt
cliente2.crt
cliente2.key
```

---

✅ **Pronto! Sua VPN OpenVPN com TLS está configurada e segura.**

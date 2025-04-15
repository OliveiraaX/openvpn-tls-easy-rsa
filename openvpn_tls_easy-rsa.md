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
set_var EASYRSA_REQ_ORG        "teste"
set_var EASYRSA_REQ_EMAIL      "teste@gmail.com"
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
port 1194                     # Porta para conexão
proto udp                     # Utiliza protocolo UDP
dev tun                       # Cria interface TUN (túnel IP - camada 3)

ca /etc/openvpn/ca.crt        # Certificado da autoridade certificadora (CA)
cert /etc/openvpn/servidor.crt  # Certificado do servidor
key /etc/openvpn/servidor.key   # Chave privada do servidor
dh /etc/openvpn/dh.pem          # Parâmetros de Diffie-Hellman para troca segura de chaves

server IP VPN 255.255.255.0   # Define rede virtual da VPN
ifconfig-pool-persist ipp.txt  # Salva IPs atribuídos para manter consistência nas conexões

push "route 10.8.0.0 255.255.255.0"  # Empurra rota da própria rede VPN

;push "dhcp-option DNS 8.8.8.8"     # Pode ser ativado para forçar uso do DNS Google
;push "dhcp-option DNS 1.1.1.1"     # Pode ser ativado para forçar uso do DNS Cloudflare

keepalive 10 120             # Envia ping a cada 10s, considera desconectado após 120s sem resposta

;comp-lzo                    # Compressão LZO desativada (por segurança - risco de ataque VORACLE)

persist-key                  # Mantém chave carregada entre reinicializações
persist-tun                  # Mantém interface TUN ativa entre reconexões

status /var/log/openvpn-status.log  # Arquivo de status da VPN em tempo real
log-append /var/log/openvpn.log     # Adiciona entradas no log principal

verb 3                       # Nível de verbosidade dos logs (3 é ideal para debug moderado)

user nobody                  # Após iniciar como root, troca para usuário com poucos privilégios
group nogroup                # Mesmo princípio acima, para o grupo

```

---

## 🧳 9. Arquivo de configuração do cliente

```bash
nano cliente1.conf
```

**Conteúdo do cliente:**

```
client                          # Modo cliente OpenVPN
dev tun                         # Usa interface TUN (camada 3 - IP)
proto udp                       # Protocolo de transporte (UDP é mais rápido e leve)
remote IP DO SERVIDOR            # IP ou domínio do servidor + porta da VPN (altere para seu IP real)
port 1194                       # configurar porta
remote-random                   # Tenta servidores remotos em ordem aleatória (se houver mais de um)
resolv-retry infinite           # Tenta reconectar indefinidamente se falhar em resolver o DNS
nobind                          # Não tenta vincular a uma porta específica no cliente
persist-key                     # Mantém as chaves entre reconexões
persist-tun                     # Mantém a interface TUN ativa entre reconexões

ca ca.crt                       # Caminho para o certificado da autoridade certificadora
cert cliente1.crt               # Certificado do cliente (autenticação TLS mútua)
key cliente1.key                # Chave privada do cliente

pull                            # Puxa configurações do servidor (como rotas, DNS, etc.)
tun-mtu 1500                    # Tamanho máximo da unidade de transmissão da TUN

verb 3                          # Nível de verbosidade do log (3 = recomendado para produção)

# Logs
status openvpn-status.log       # Arquivo de status da sessão VPN (conexões ativas, IPs, etc.)
log /var/log/openvpn.log        # Log principal (pode ver eventos, conexões, erros, etc.)
log-append /var/log/openvpn.log # Adiciona ao log em vez de sobrescrever

```

---

## 📁 10. Organização dos arquivos do cliente

Coloque os arquivos abaixo na mesma pasta do `.conf`:

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
cp easy-rsa/pki/issued/ca.crt  /etc/openvpn/ca.crt
cp easy-rsa/pki/issued/novocliente.crt /etc/openvpn/novocliente.crt
cp easy-rsa/pki/private/novocliente.key /etc/openvpn/novocliente.key
```

---

✅ **Pronto! Sua VPN OpenVPN com TLS está configurada e segura.**

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
cp -r /usr/share/easy-rsa/ /etc/openvpn && cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars
```

### ✍️ Adicionar informações no `vars`:

```bash
tee /etc/openvpn/easy-rsa/vars > /dev/null << 'EOF'
set_var EASYRSA_REQ_COUNTRY    "BR"
set_var EASYRSA_REQ_PROVINCE   "PR"
set_var EASYRSA_REQ_CITY       "Londrina"
set_var EASYRSA_REQ_ORG        "teste"
set_var EASYRSA_REQ_EMAIL      "teste@gmail.com"
set_var EASYRSA_REQ_OU         "Suporte"
EOF
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
./easyrsa gen-req **NOME DO SERVIDOR** nopass
./easyrsa sign-req server **NOME DO SERVIDOR** 

## 👤 5. Criando certificado e chave do cliente

./easyrsa gen-req **NOME DO CLIENTE** nopass
./easyrsa sign-req client **NOME DO CLIENTE**
```
---

## 📁 6. Gerando a chave Diffie-Hellman

```bash
./easyrsa gen-dh
```

---

## 📦 7. Movendo os arquivos para o OpenVPN

```bash
cp pki/dh.pem /etc/openvpn/server/
cp pki/ca.crt /etc/openvpn/server/
cp pki/issued/**NOME DO SERVIDOR**.crt /etc/openvpn/server/
cp pki/private/**NOME DO SERVIDOR**.key /etc/openvpn/server/
cp pki/ca.crt /etc/openvpn/client/
cp pki/issued/**NOME DO CLIENT**.crt /etc/openvpn/client/
cp pki/private/**NOME DO CLIENT**.key /etc/openvpn/client/

```

---

## ⚙️ 8. Configurando o servidor OpenVPN

```bash
nano /etc/openvpn/server/server.conf
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

ca /etc/openvpn/server/ca.crt        # Certificado da autoridade certificadora (CA)
cert /etc/openvpn/server/**NOME DO SERVIDOR**.crt  # Certificado do servidor
key /etc/openvpn/server/**NOME DO SERVIDOR**.key   # Chave privada do servidor
dh /etc/openvpn/server/dh.pem          # Parâmetros de Diffie-Hellman para troca segura de chaves

server *IP* 255.255.255.0   # Define rede virtual da VPN
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
nano client.conf
```

**Conteúdo do cliente:**

```
tls-client                          # Modo cliente OpenVPN
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
cert *nome_cliente*.crt               # Certificado do cliente (autenticação TLS mútua)
key *nome_cliente*.key                # Chave privada do cliente

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
**NOME DO CLIENTE**.conf
ca.crt
**NOME DO CLIENTE**.crt
**NOME DO CLIENTE**.key
```

---

## ➕ 11. Como adicionar mais clientes

```bash
cd /etc/openvpn/easy-rsa
./easyrsa gen-req **NOME DO CLIENTE2** nopass
./easyrsa sign-req client **NOME DO CLIENTE2**
```

Depois, copie o arquivo `**NOME DO CLIENTE2**.conf` e altere as linhas:

```
cert **NOME DO CLIENTE2**.crt
key **NOME DO CLIENTE2**.key
```

Transfira os arquivos para o novo host:

```
cp easy-rsa/pki/issued/ca.crt  /etc/openvpn/ca.crt
cp easy-rsa/pki/issued/novocliente.crt /etc/openvpn/**NOME DO CLIENTE2**.crt
cp easy-rsa/pki/private/novocliente.key /etc/openvpn/**NOME DO CLIENTE2**.key
```

---

✅ **Pronto! Sua VPN OpenVPN com TLS está configurada e segura.**

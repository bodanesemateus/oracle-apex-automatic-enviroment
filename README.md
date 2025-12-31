# Oracle Database 21c + APEX 24.2 + ORDS 25.4 - Docker Compose

[![Oracle](https://img.shields.io/badge/Oracle-21c_Enterprise-red?logo=oracle)](https://www.oracle.com/database/)
[![APEX](https://img.shields.io/badge/APEX-24.2-green)](https://apex.oracle.com/)
[![ORDS](https://img.shields.io/badge/ORDS-25.4-blue)](https://www.oracle.com/database/technologies/appdev/rest.html)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Automação completa para deploy de ambiente Oracle Database 21c Enterprise Edition com Oracle APEX e ORDS usando Docker Compose. Ideal para ambientes de desenvolvimento, homologação e estudos.

## 📋 Índice

- [Características](#-características)
- [Pré-requisitos](#-pré-requisitos)
- [Quick Start](#-quick-start)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Configuração](#-configuração)
- [Arquivos de Script](#-arquivos-de-script)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Acesso](#-acesso)
- [SSL/TLS](#-ssltls)
- [Reverse Proxy](#-reverse-proxy)
- [Troubleshooting](#-troubleshooting)
- [Manutenção](#-manutenção)
- [Contribuindo](#-contribuindo)

## ✨ Características

- **Oracle Database 21c Enterprise Edition** - Banco de dados Oracle completo
- **Oracle APEX 24.2** - Plataforma low-code para desenvolvimento de aplicações
- **Oracle ORDS 25.4** - REST Data Services para API REST e interface web do APEX
- **SSL/TLS automático** - Configuração automática de conexões seguras (porta 2484)
- **Instalação automatizada** - Scripts de setup executam automaticamente na primeira inicialização
- **Persistência de dados** - Volumes Docker para manter dados entre restarts
- **Healthcheck integrado** - Monitoramento automático da saúde do banco

## 📦 Pré-requisitos

### Sistema
- **Docker** 20.10+
- **Docker Compose** v2.0+
- **Memória RAM**: Mínimo 8GB (recomendado 16GB)
- **Disco**: Mínimo 30GB livres
- **CPU**: Mínimo 4 cores

### Conta Oracle Container Registry

Você precisa de uma conta no [Oracle Container Registry](https://container-registry.oracle.com/) para baixar as imagens oficiais:

1. Acesse https://container-registry.oracle.com/
2. Crie uma conta ou faça login
3. Aceite os termos de uso para:
   - `database/enterprise`
   - `database/ords`
4. Faça login no registry:

```bash
docker login container-registry.oracle.com
```

## 🚀 Instalação Rápida (One-Click Setup)
```bash
# Clone o repositório
git clone https://github.com/seu-usuario/oracle-apex-docker.git
cd oracle-apex-docker

# Execute o script de criação
chmod +x create_structure.sh
./create_structure.sh

# Suba o Oracle Database (aguarde ~15-25 min)
docker compose up -d oracle21

# Após "DATABASE IS READY TO USE!", suba o ORDS
docker compose up -d ords
```

O script `create_structure.sh` cria automaticamente toda a estrutura necessária:
- ✅ Valida Docker, Docker Compose e login no Oracle Container Registry
- ✅ Detecta estrutura existente e pergunta se deseja sobrescrever
- ✅ Configuração interativa ou via arquivo `settings.ini`
- ✅ Gera `docker-compose.yaml` personalizado
- ✅ Cria scripts de instalação do APEX e configuração SSL
- ✅ Configura permissões automaticamente

> 💡 **Dica**: Crie um arquivo `settings.ini` antes de executar o script para pular a configuração interativa. Use o `settings.ini.example` como base.

---

## 🚀 Quick Start

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/oracle-apex-docker.git
cd oracle-apex-docker
```

### 2. Configure as permissões

```bash
# Criar diretórios necessários
mkdir -p data containers restore ords/config/global scripts/setup scripts/startup

# Ajustar permissões (UID 54321 = usuário oracle no container)
sudo chown -R 54321:54321 data containers restore ords scripts
```

### 3. Inicie o Oracle Database

```bash
docker compose up -d oracle21

# Acompanhe os logs (aguarde "DATABASE IS READY TO USE!")
docker compose logs -f oracle21
```

> ⏱️ **Tempo estimado**: 15-25 minutos na primeira execução (criação do banco + instalação do APEX)

### 4. Inicie o ORDS

Após o banco estar pronto:

```bash
docker compose up -d ords

# Acompanhe os logs
docker compose logs -f ords
```

### 5. Acesse o APEX

- **URL**: http://localhost:8080/ords/apex
- **Workspace**: `INTERNAL`
- **Usuário**: `ADMIN`
- **Senha**: `OracleApex21!`

## 📁 Estrutura do Projeto

```
oracle-apex-docker/
├── docker-compose.yaml          # Definição dos serviços
├── README.md                    # Esta documentação
├── LICENSE                      # Licença do projeto
│
├── data/                        # Dados do Oracle Database (persistente)
│   └── apex-images/             # Imagens estáticas do APEX
│
├── containers/                  # Arquivos de PDBs
│
├── restore/                     # Diretório para imports/exports
│
├── ords/
│   └── config/
│       └── global/
│           └── settings.xml     # Configuração do ORDS
│
└── scripts/
    ├── setup/                   # Scripts executados apenas na 1ª inicialização
    │   ├── 01_create_directories.sh
    │   ├── 02_configure_pdb.sql
    │   ├── 03_create_tablespaces.sql
    │   ├── 04_create_user.sql
    │   ├── 05_install_apex.sql
    │   └── 06_install_apex.sh
    │
    └── startup/                 # Scripts executados em toda inicialização
        └── 01_enable_ssl.sh
```

## ⚙️ Configuração

### docker-compose.yaml

```yaml
services:
  oracle21:
    container_name: oracle-21.3.0-1
    image: container-registry.oracle.com/database/enterprise:21.3.0.0
    privileged: true
    shm_size: 6g
    hostname: oracle-db
    networks:
      - oraclenetwork
    ports:
      - 1521:1521      # SQL*Net (TCP)
      - 2484:2484      # SQL*Net (TCPS/SSL)
      - 5500:5500      # Enterprise Manager Express
    volumes:
      - ./data:/opt/oracle/oradata
      - ./restore:/opt/oracle/restore
      - ./containers:/opt/oracle/containers
      - ./scripts/setup:/opt/oracle/scripts/setup
      - ./scripts/startup:/opt/oracle/scripts/startup
    environment:
      - ORACLE_SID=EE
      - ORACLE_PDB=SE
      - ORACLE_PWD=OracleDb21
      - ORACLE_CHARACTERSET=AL32UTF8
      - TZ=America/Sao_Paulo
      - INIT_CPU_COUNT=4
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ["CMD", "sqlplus", "-L", "sys/OracleDb21@//localhost:1521/SE as sysdba", "@/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 10
      start_period: 600s

  ords:
    container_name: ords
    image: container-registry.oracle.com/database/ords:latest
    hostname: ords
    networks:
      - oraclenetwork
    ports:
      - 8080:8080      # HTTP
      - 8443:8443      # HTTPS
    volumes:
      - ./ords/config:/etc/ords/config
      - ./data/apex-images:/opt/oracle/apex/images:ro
    environment:
      - DBHOST=oracle-db
      - DBPORT=1521
      - DBSERVICENAME=SE
      - ORACLE_PWD=OracleDb21
      - ORACLE_USER_PWD=OracleDb21
      - IGNORE_APEX=false
    depends_on:
      oracle21:
        condition: service_healthy
    restart: unless-stopped

networks:
  oraclenetwork:
    name: oraclenetwork
```

## 📜 Arquivos de Script

### Scripts de Setup (executam apenas na primeira inicialização)

#### 01_create_directories.sh
Cria diretórios necessários para exports e imagens do APEX.

```bash
#!/bin/bash
mkdir -p /opt/oracle/restore
mkdir -p /opt/oracle/containers
mkdir -p /opt/oracle/oradata/apex-images
```

#### 02_configure_pdb.sql
Configura o PDB (Pluggable Database) criado automaticamente.

```sql
ALTER SESSION SET CONTAINER = SE;

ALTER SYSTEM SET open_cursors = 500 SCOPE=BOTH;
ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata/EE/SE' SCOPE=BOTH;

CREATE OR REPLACE DIRECTORY EXPORTS AS '/opt/oracle/restore';
GRANT READ, WRITE ON DIRECTORY EXPORTS TO PUBLIC;
```

#### 03_create_tablespaces.sql
Cria tablespaces para dados e índices.

```sql
ALTER SESSION SET CONTAINER = SE;

CREATE TABLESPACE ORACLE_DATA
DATAFILE SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ORACLE_INDEXES
DATAFILE SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL AUTOALLOCATE;
```

#### 04_create_user.sql
Cria usuário de aplicação com permissões adequadas.

```sql
ALTER SESSION SET CONTAINER = SE;

CREATE USER oracle IDENTIFIED BY OracleDb21
DEFAULT TABLESPACE ORACLE_DATA
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON ORACLE_DATA
QUOTA UNLIMITED ON ORACLE_INDEXES;

GRANT CREATE SESSION,
      CREATE PROCEDURE,
      CREATE VIEW,
      CREATE TABLE,
      CREATE SEQUENCE,
      CREATE TRIGGER,
      SELECT ANY DICTIONARY
TO oracle;
```

#### 05_install_apex.sql
Verifica se o APEX já está instalado.

```sql
ALTER SESSION SET CONTAINER = SE;

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_registry WHERE comp_id = 'APEX';
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('APEX já instalado - pulando');
    ELSE
        DBMS_OUTPUT.PUT_LINE('APEX não encontrado - será instalado pelo script shell');
    END IF;
END;
/
```

#### 06_install_apex.sh
Instala o Oracle APEX automaticamente.

```bash
#!/bin/bash
set -e

export ORACLE_SID=EE
export ORACLE_HOME=/opt/oracle/product/21c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

echo "--- [APEX SETUP] Verificando se APEX já está instalado..."

APEX_EXISTS=$(sqlplus -S / as sysdba <<EOSQL
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF
ALTER SESSION SET CONTAINER = SE;
SELECT COUNT(*) FROM dba_registry WHERE comp_id = 'APEX';
EXIT;
EOSQL
)

APEX_EXISTS=$(echo $APEX_EXISTS | tr -d '[:space:]')

if [ "$APEX_EXISTS" != "0" ]; then
    echo "--- [APEX SETUP] APEX já está instalado. Pulando instalação."
    exit 0
fi

echo "--- [APEX SETUP] Baixando APEX..."
cd /tmp
curl -o apex-latest.zip https://download.oracle.com/otn_software/apex/apex-latest.zip
unzip -o apex-latest.zip
cd apex

echo "--- [APEX SETUP] Instalando APEX no PDB SE (~15-20 minutos)..."

sqlplus / as sysdba <<EOSQL
ALTER SESSION SET CONTAINER = SE;
@apexins.sql SYSAUX SYSAUX TEMP /i/
EXIT;
EOSQL

echo "--- [APEX SETUP] Configurando REST..."

sqlplus / as sysdba <<EOSQL
ALTER SESSION SET CONTAINER = SE;
@apex_rest_config.sql OracleApex21 OracleApex21
EXIT;
EOSQL

echo "--- [APEX SETUP] Configurando usuários APEX..."

sqlplus / as sysdba <<EOSQL
ALTER SESSION SET CONTAINER = SE;

ALTER USER APEX_PUBLIC_USER IDENTIFIED BY "OracleApex21" ACCOUNT UNLOCK;

BEGIN
    APEX_UTIL.SET_SECURITY_GROUP_ID(10);
    APEX_UTIL.CREATE_USER(
        p_user_name       => 'ADMIN',
        p_email_address   => 'admin@local',
        p_web_password    => 'OracleApex21!',
        p_developer_privs => 'ADMIN',
        p_change_password_on_first_use => 'N'
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20001 THEN
            DBMS_OUTPUT.PUT_LINE('Admin já existe');
        ELSE
            RAISE;
        END IF;
END;
/

EXIT;
EOSQL

echo "--- [APEX SETUP] Copiando imagens do APEX..."
cp -r /tmp/apex/images/* /opt/oracle/oradata/apex-images/
chmod -R 755 /opt/oracle/oradata/apex-images

echo "--- [APEX SETUP] Limpando temporários..."
rm -rf /tmp/apex /tmp/apex-latest.zip

echo "=============================================="
echo "--- [APEX SETUP] INSTALAÇÃO FINALIZADA! ---"
echo "=============================================="
echo "Workspace: INTERNAL"
echo "Usuário:   ADMIN"
echo "Senha:     OracleApex21!"
echo "=============================================="
```

### Scripts de Startup (executam em toda inicialização)

#### 01_enable_ssl.sh
Configura SSL/TLS automaticamente.

```bash
#!/bin/bash

export ORACLE_SID=EE
export ORACLE_HOME=/opt/oracle/product/21c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export TNS_ADMIN=/opt/oracle/oradata/dbconfig/$ORACLE_SID
export WALLET_DIR=/opt/oracle/oradata/wallet

echo "--- [SSL] Verificando configuração SSL..."

if [ ! -f "$WALLET_DIR/cwallet.sso" ]; then
    echo "--- [SSL] Criando wallet..."
    mkdir -p $WALLET_DIR
    orapki wallet create -wallet $WALLET_DIR -pwd Oracle21 -auto_login
    orapki wallet add -wallet $WALLET_DIR -pwd Oracle21 \
        -dn "CN=oracle-db" \
        -keysize 2048 -self_signed -validity 3650
    orapki wallet export -wallet $WALLET_DIR -pwd Oracle21 \
        -dn "CN=oracle-db" \
        -cert $WALLET_DIR/server.crt
    chmod 755 $WALLET_DIR
    chmod 644 $WALLET_DIR/*
    echo "--- [SSL] Wallet criado."
else
    echo "--- [SSL] Wallet já existe."
fi

if grep -q "TCPS" "$TNS_ADMIN/listener.ora" 2>/dev/null; then
    echo "--- [SSL] SSL já configurado no listener."
    exit 0
fi

echo "--- [SSL] Configurando arquivos .ora..."

cat > $TNS_ADMIN/listener.ora <<'LISTENER'
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)))
    (DESCRIPTION = (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521)))
    (DESCRIPTION = (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = 2484)))
  )

SSL_CLIENT_AUTHENTICATION = FALSE

WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /opt/oracle/oradata/wallet)
    )
  )

USE_SID_AS_SERVICE_LISTENER = ON
DYNAMIC_REGISTRATION_LISTENER = ON
LISTENER

cat > $TNS_ADMIN/sqlnet.ora <<'SQLNET'
NAMES.DIRECTORY_PATH = (TNSNAMES, EZCONNECT)

WALLET_LOCATION =
  (SOURCE =
    (METHOD = FILE)
    (METHOD_DATA =
      (DIRECTORY = /opt/oracle/oradata/wallet)
    )
  )

SSL_CLIENT_AUTHENTICATION = FALSE
SSL_VERSION = 1.2
SSL_SERVER_DN_MATCH = NO
SQLNET

cat > $TNS_ADMIN/tnsnames.ora <<'TNSNAMES'
SE_TCP =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-db)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = se)
    )
  )

SE_TCPS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCPS)(HOST = oracle-db)(PORT = 2484))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = se)
    )
  )
TNSNAMES

echo "--- [SSL] Reiniciando listener..."
lsnrctl stop 2>/dev/null || true
sleep 2
lsnrctl start

sqlplus -S / as sysdba <<'EOSQL'
ALTER SYSTEM SET LOCAL_LISTENER='
  (DESCRIPTION_LIST=
    (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521)))
    (DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=0.0.0.0)(PORT=2484)))
  )' SCOPE=BOTH;
ALTER SYSTEM REGISTER;
ALTER SESSION SET CONTAINER = SE;
ALTER SYSTEM SET LOCAL_LISTENER='
  (DESCRIPTION_LIST=
    (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521)))
    (DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=0.0.0.0)(PORT=2484)))
  )' SCOPE=BOTH;
ALTER SYSTEM REGISTER;
EXIT;
EOSQL

echo "--- [SSL] Configuração finalizada!"
```

## 🔧 Variáveis de Ambiente

### Oracle Database

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `ORACLE_SID` | System Identifier | `EE` |
| `ORACLE_PDB` | Nome do Pluggable Database | `SE` |
| `ORACLE_PWD` | Senha do SYS/SYSTEM | `OracleDb21` |
| `ORACLE_CHARACTERSET` | Character set do banco | `AL32UTF8` |
| `TZ` | Timezone | `America/Sao_Paulo` |
| `INIT_CPU_COUNT` | Número de CPUs | `4` |

### ORDS

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `DBHOST` | Hostname do banco | `oracle-db` |
| `DBPORT` | Porta do banco | `1521` |
| `DBSERVICENAME` | Nome do serviço | `SE` |
| `ORACLE_PWD` | Senha do banco | `OracleDb21` |
| `IGNORE_APEX` | Ignorar APEX | `false` |

## 🌐 Acesso

### URLs

| Serviço | URL | Descrição |
|---------|-----|-----------|
| APEX Development | http://localhost:8080/ords/apex | Ambiente de desenvolvimento |
| APEX Administration | http://localhost:8080/ords/apex_admin | Administração do APEX |
| SQL Developer Web | http://localhost:8080/ords/sql-developer | Interface SQL |
| ORDS Landing | http://localhost:8080/ords/ | Página inicial do ORDS |
| EM Express | https://localhost:5500/em | Enterprise Manager Express |

### Credenciais Padrão

| Serviço | Usuário | Senha |
|---------|---------|-------|
| APEX Admin | `ADMIN` | `OracleApex21!` |
| Database SYS | `sys` | `OracleDb21` |
| Database SYSTEM | `system` | `OracleDb21` |
| App User | `oracle` | `OracleDb21` |

### Conexão SQL*Plus

```bash
# Via Docker
docker exec -it oracle-21.3.0-1 sqlplus sys/OracleDb21@//localhost:1521/SE as sysdba

# Via cliente externo (TCP)
sqlplus sys/OracleDb21@//localhost:1521/SE as sysdba

# Via cliente externo (TCPS/SSL)
sqlplus sys/OracleDb21@//localhost:2484/SE as sysdba
```

## 🔒 SSL/TLS

O ambiente configura automaticamente SSL/TLS na porta 2484:

- **Certificado auto-assinado** com validade de 10 anos
- **Wallet Oracle** para gerenciamento de certificados
- **TLS 1.2** habilitado

### Exportar certificado para clientes

```bash
# Copiar certificado do container
docker cp oracle-21.3.0-1:/opt/oracle/oradata/wallet/server.crt ./server.crt
```

## 🔄 Reverse Proxy

### Configuração ORDS para Reverse Proxy

Se você usa um reverse proxy (nginx, traefik, apache), crie o arquivo `ords/config/global/settings.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<entry key="security.externalSessionTrustedOrigins">https://seu-dominio.com</entry>
<entry key="security.httpsHeaderCheck">X-Forwarded-Proto</entry>
<entry key="security.forceHTTPS">false</entry>
<entry key="standalone.https.host">seu-dominio.com</entry>
</properties>
```

### Exemplo Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name seu-dominio.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
}
```

### Exemplo Traefik (labels Docker)

```yaml
services:
  ords:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ords.rule=Host(`seu-dominio.com`)"
      - "traefik.http.routers.ords.tls=true"
      - "traefik.http.services.ords.loadbalancer.server.port=8080"
```

## 🔍 Troubleshooting

### Erro: Permission denied

```bash
# Corrigir permissões
sudo chown -R 54321:54321 data containers restore ords scripts
```

### Erro: ORDS CORS/403 Forbidden

Verifique se o `settings.xml` está configurado corretamente:

```bash
cat ords/config/global/settings.xml
```

### Verificar se APEX está instalado

```bash
docker exec -it oracle-21.3.0-1 sqlplus sys/OracleDb21@//localhost:1521/SE as sysdba

SQL> SELECT comp_id, version, status FROM dba_registry WHERE comp_id = 'APEX';
SQL> SELECT version_no FROM apex_release;
```

### Verificar logs

```bash
# Oracle Database
docker compose logs -f oracle21

# ORDS
docker compose logs -f ords

# Alert log do Oracle
docker exec -it oracle-21.3.0-1 tail -f /opt/oracle/diag/rdbms/*/*/trace/alert*.log
```

### Reiniciar do zero

```bash
docker compose down -v
sudo rm -rf data/* containers/* restore/* ords/config/databases
docker compose up -d oracle21
# Aguardar DATABASE IS READY TO USE
docker compose up -d ords
```

## 🛠️ Manutenção

### Backup

```bash
# Export de schema
docker exec -it oracle-21.3.0-1 expdp system/OracleDb21@SE \
    directory=EXPORTS \
    dumpfile=backup_$(date +%Y%m%d).dmp \
    schemas=oracle

# Copiar para host
docker cp oracle-21.3.0-1:/opt/oracle/restore/backup_*.dmp ./backups/
```

### Import

```bash
# Copiar dump para container
docker cp ./backup.dmp oracle-21.3.0-1:/opt/oracle/restore/

# Import
docker exec -it oracle-21.3.0-1 impdp system/OracleDb21@SE \
    directory=EXPORTS \
    dumpfile=backup.dmp \
    schemas=oracle
```

### Atualizar APEX

```bash
docker exec -it oracle-21.3.0-1 bash

cd /tmp
curl -o apex-latest.zip https://download.oracle.com/otn_software/apex/apex-latest.zip
unzip -o apex-latest.zip
cd apex

sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = SE;
@apexins.sql SYSAUX SYSAUX TEMP /i/
EXIT;
EOF

cp -r /tmp/apex/images/* /opt/oracle/oradata/apex-images/
rm -rf /tmp/apex /tmp/apex-latest.zip
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request


## ⚠️ Disclaimer

- As imagens Oracle são proprietárias e requerem aceitação dos termos de uso
- Este projeto é para fins de desenvolvimento e estudo
- Para produção, consulte o licenciamento Oracle apropriado
- As senhas padrão devem ser alteradas em ambientes não locais

## 📚 Referências

- [Oracle Database Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/)
- [Oracle APEX Documentation](https://docs.oracle.com/en/database/oracle/apex/)
- [Oracle REST Data Services Documentation](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/)
- [Oracle Container Registry](https://container-registry.oracle.com/)

---

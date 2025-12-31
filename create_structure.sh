#!/bin/bash

# ============================================
# Oracle APEX Docker - Create Structure
# ============================================
# Este script cria toda a estrutura necessária para
# executar Oracle Database 21c + APEX + ORDS via Docker
# ============================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretório atual
WORK_DIR=$(pwd)
SETTINGS_FILE="$WORK_DIR/settings.ini"

# ============================================
# Funções utilitárias
# ============================================

print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       Oracle Database 21c + APEX + ORDS - Docker Setup     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# ============================================
# Validações
# ============================================

check_docker() {
    print_step "Verificando Docker..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado!"
        echo "       Instale o Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon não está rodando!"
        echo "       Inicie o Docker e tente novamente."
        exit 1
    fi
    
    print_success "Docker está instalado e rodando"
}

check_docker_compose() {
    print_step "Verificando Docker Compose..."
    
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose não está instalado!"
        echo "       Instale o Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_success "Docker Compose está instalado"
}

check_oracle_registry() {
    print_step "Verificando login no Oracle Container Registry..."
    
    # Tenta fazer pull de uma imagem pequena para verificar autenticação
    if ! docker pull container-registry.oracle.com/database/ords:latest &> /dev/null; then
        print_error "Não foi possível acessar o Oracle Container Registry!"
        echo ""
        echo -e "${YELLOW}Para resolver:${NC}"
        echo "  1. Acesse: https://container-registry.oracle.com/"
        echo "  2. Crie uma conta ou faça login"
        echo "  3. Aceite os termos de uso para 'database/enterprise' e 'database/ords'"
        echo "  4. Execute: docker login container-registry.oracle.com"
        echo "  5. Execute este script novamente"
        echo ""
        exit 1
    fi
    
    print_success "Login no Oracle Container Registry válido"
}

check_existing_structure() {
    print_step "Verificando estrutura existente..."
    
    local has_existing=false
    
    if [ -d "$WORK_DIR/data" ] || [ -d "$WORK_DIR/scripts" ] || [ -f "$WORK_DIR/docker-compose.yaml" ]; then
        has_existing=true
    fi
    
    if [ "$has_existing" = true ]; then
        print_warning "Estrutura existente detectada!"
        echo ""
        read -p "Deseja sobrescrever? Isso irá APAGAR dados existentes! (s/N): " confirm
        
        if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
            print_info "Operação cancelada pelo usuário."
            exit 0
        fi
        
        print_step "Removendo estrutura existente..."
        
        # Para containers se existirem
        if [ -f "$WORK_DIR/docker-compose.yaml" ]; then
            docker compose -f "$WORK_DIR/docker-compose.yaml" down -v 2>/dev/null || true
        fi
        
        # Remove diretórios
        sudo rm -rf "$WORK_DIR/data" "$WORK_DIR/containers" "$WORK_DIR/restore" "$WORK_DIR/ords" "$WORK_DIR/scripts" 2>/dev/null || true
        rm -f "$WORK_DIR/docker-compose.yaml" 2>/dev/null || true
        
        print_success "Estrutura anterior removida"
    else
        print_success "Nenhuma estrutura existente"
    fi
}

# ============================================
# Configuração interativa
# ============================================

read_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local is_password="$4"
    
    if [ "$is_password" = "true" ]; then
        read -sp "$prompt [$default]: " value
        echo ""
    else
        read -p "$prompt [$default]: " value
    fi
    
    if [ -z "$value" ]; then
        value="$default"
    fi
    
    eval "$var_name=\"$value\""
}

configure_interactive() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    CONFIGURAÇÃO INTERATIVA                     ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Pressione ENTER para aceitar o valor padrão entre colchetes."
    echo ""
    
    # Database
    echo -e "${YELLOW}── Configurações do Database ──${NC}"
    read_input "Oracle SID" "EE" "ORACLE_SID"
    read_input "Nome do PDB" "SE" "ORACLE_PDB"
    read_input "Senha do SYS/SYSTEM" "OracleDb21" "ORACLE_PWD" "true"
    read_input "Character Set" "AL32UTF8" "ORACLE_CHARACTERSET"
    read_input "Número de CPUs" "4" "INIT_CPU_COUNT"
    
    echo ""
    
    # APEX
    echo -e "${YELLOW}── Configurações do APEX ──${NC}"
    read_input "Senha do ADMIN do APEX" "OracleApex21!" "APEX_ADMIN_PWD" "true"
    read_input "Email do ADMIN" "admin@local" "APEX_ADMIN_EMAIL"
    
    echo ""
    
    # ORDS
    echo -e "${YELLOW}── Configurações do ORDS ──${NC}"
    read_input "Domínio (vazio para acesso local)" "" "ORDS_DOMAIN"
    read_input "Porta HTTP" "8080" "ORDS_HTTP_PORT"
    read_input "Porta HTTPS" "8443" "ORDS_HTTPS_PORT"
    
    echo ""
    
    # General
    echo -e "${YELLOW}── Configurações Gerais ──${NC}"
    read_input "Timezone" "America/Sao_Paulo" "TIMEZONE"
    read_input "Nome do container Oracle" "oracle-21.3.0-1" "ORACLE_CONTAINER_NAME"
    read_input "Nome do container ORDS" "ords" "ORDS_CONTAINER_NAME"
    read_input "Nome da rede Docker" "oraclenetwork" "DOCKER_NETWORK"
    
    echo ""
}

generate_settings_file() {
    print_step "Gerando arquivo settings.ini..."
    
    cat > "$SETTINGS_FILE" << EOF
# ============================================
# Oracle APEX Docker - Configurações
# ============================================
# Gerado automaticamente em $(date)
# ============================================

[database]
ORACLE_SID=$ORACLE_SID
ORACLE_PDB=$ORACLE_PDB
ORACLE_PWD=$ORACLE_PWD
ORACLE_CHARACTERSET=$ORACLE_CHARACTERSET
INIT_CPU_COUNT=$INIT_CPU_COUNT

[apex]
APEX_ADMIN_PWD=$APEX_ADMIN_PWD
APEX_ADMIN_EMAIL=$APEX_ADMIN_EMAIL

[ords]
ORDS_DOMAIN=$ORDS_DOMAIN
ORDS_HTTP_PORT=$ORDS_HTTP_PORT
ORDS_HTTPS_PORT=$ORDS_HTTPS_PORT

[general]
TIMEZONE=$TIMEZONE
ORACLE_CONTAINER_NAME=$ORACLE_CONTAINER_NAME
ORDS_CONTAINER_NAME=$ORDS_CONTAINER_NAME
DOCKER_NETWORK=$DOCKER_NETWORK
EOF
    
    print_success "Arquivo settings.ini criado"
}

load_settings_file() {
    print_step "Carregando configurações de settings.ini..."
    
    # Parser simples de INI
    while IFS='=' read -r key value; do
        # Ignora comentários e linhas vazias
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ "$key" =~ ^[[:space:]]*\[ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Remove espaços
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Exporta variável
        if [ -n "$key" ] && [ -n "$value" ]; then
            eval "$key=\"$value\""
        fi
    done < "$SETTINGS_FILE"
    
    print_success "Configurações carregadas"
}

# ============================================
# Criação da estrutura
# ============================================

create_directories() {
    print_step "Criando diretórios..."
    
    mkdir -p "$WORK_DIR/data"
    mkdir -p "$WORK_DIR/containers"
    mkdir -p "$WORK_DIR/restore"
    mkdir -p "$WORK_DIR/ords/config/global"
    mkdir -p "$WORK_DIR/scripts/setup"
    mkdir -p "$WORK_DIR/scripts/startup"
    
    print_success "Diretórios criados"
}

create_docker_compose() {
    print_step "Criando docker-compose.yaml..."
    
    cat > "$WORK_DIR/docker-compose.yaml" << EOF
services:
  oracle21:
    container_name: $ORACLE_CONTAINER_NAME
    image: container-registry.oracle.com/database/enterprise:21.3.0.0
    privileged: true
    shm_size: 6g
    hostname: oracle-db
    networks:
      - $DOCKER_NETWORK
    ports:
      - 1521:1521
      - 2484:2484
      - 5500:5500
    volumes:
      - ./data:/opt/oracle/oradata
      - ./restore:/opt/oracle/restore
      - ./containers:/opt/oracle/containers
      - ./scripts/setup:/opt/oracle/scripts/setup
      - ./scripts/startup:/opt/oracle/scripts/startup
    environment:
      - ORACLE_SID=$ORACLE_SID
      - ORACLE_PDB=$ORACLE_PDB
      - ORACLE_PWD=$ORACLE_PWD
      - ORACLE_CHARACTERSET=$ORACLE_CHARACTERSET
      - TZ=$TIMEZONE
      - INIT_CPU_COUNT=$INIT_CPU_COUNT
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ["CMD", "sqlplus", "-L", "sys/$ORACLE_PWD@//localhost:1521/$ORACLE_PDB as sysdba", "@/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 10
      start_period: 600s

  ords:
    container_name: $ORDS_CONTAINER_NAME
    image: container-registry.oracle.com/database/ords:latest
    hostname: ords
    networks:
      - $DOCKER_NETWORK
    ports:
      - $ORDS_HTTP_PORT:8080
      - $ORDS_HTTPS_PORT:8443
    volumes:
      - ./ords/config:/etc/ords/config
      - ./data/apex-images:/opt/oracle/apex/images:ro
    environment:
      - DBHOST=oracle-db
      - DBPORT=1521
      - DBSERVICENAME=$ORACLE_PDB
      - ORACLE_PWD=$ORACLE_PWD
      - ORACLE_USER_PWD=$ORACLE_PWD
      - IGNORE_APEX=false
    depends_on:
      oracle21:
        condition: service_healthy
    restart: unless-stopped

networks:
  $DOCKER_NETWORK:
    name: $DOCKER_NETWORK
EOF
    
    print_success "docker-compose.yaml criado"
}

create_ords_settings() {
    print_step "Criando configuração do ORDS..."
    
    if [ -n "$ORDS_DOMAIN" ]; then
        cat > "$WORK_DIR/ords/config/global/settings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<entry key="security.externalSessionTrustedOrigins">https://$ORDS_DOMAIN</entry>
<entry key="security.httpsHeaderCheck">X-Forwarded-Proto</entry>
<entry key="security.forceHTTPS">false</entry>
<entry key="standalone.https.host">$ORDS_DOMAIN</entry>
</properties>
EOF
        print_success "Configuração ORDS criada para domínio: $ORDS_DOMAIN"
    else
        cat > "$WORK_DIR/ords/config/global/settings.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<entry key="security.forceHTTPS">false</entry>
</properties>
EOF
        print_success "Configuração ORDS criada para acesso local"
    fi
}

create_setup_scripts() {
    print_step "Criando scripts de setup..."
    
    # 01_create_directories.sh
    cat > "$WORK_DIR/scripts/setup/01_create_directories.sh" << 'EOF'
#!/bin/bash
mkdir -p /opt/oracle/restore
mkdir -p /opt/oracle/containers
mkdir -p /opt/oracle/oradata/apex-images
EOF
    
    # 02_configure_pdb.sql
    cat > "$WORK_DIR/scripts/setup/02_configure_pdb.sql" << EOF
ALTER SESSION SET CONTAINER = $ORACLE_PDB;

-- Configurações do PDB
ALTER SYSTEM SET open_cursors = 500 SCOPE=BOTH;
ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata/$ORACLE_SID/$ORACLE_PDB' SCOPE=BOTH;

-- Directory para exports
CREATE OR REPLACE DIRECTORY EXPORTS AS '/opt/oracle/restore';
GRANT READ, WRITE ON DIRECTORY EXPORTS TO PUBLIC;
EOF
    
    # 03_create_tablespaces.sql
    cat > "$WORK_DIR/scripts/setup/03_create_tablespaces.sql" << EOF
ALTER SESSION SET CONTAINER = $ORACLE_PDB;

-- Usando db_create_file_dest, não precisa especificar caminho
CREATE TABLESPACE ORACLE_DATA
DATAFILE SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ORACLE_INDEXES
DATAFILE SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL AUTOALLOCATE;
EOF
    
    # 04_create_user.sql
    cat > "$WORK_DIR/scripts/setup/04_create_user.sql" << EOF
ALTER SESSION SET CONTAINER = $ORACLE_PDB;

CREATE USER oracle IDENTIFIED BY $ORACLE_PWD
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
EOF
    
    # 05_install_apex.sql
    cat > "$WORK_DIR/scripts/setup/05_install_apex.sql" << EOF
-- Instalação do APEX via SQL (setup roda como sysdba)
-- Este script apenas prepara - a instalação real é feita pelo shell script

ALTER SESSION SET CONTAINER = $ORACLE_PDB;

-- Verificar se APEX já existe
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
EOF
    
    # 06_install_apex.sh
    cat > "$WORK_DIR/scripts/setup/06_install_apex.sh" << EOF
#!/bin/bash
set -e

export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=/opt/oracle/product/21c/dbhome_1
export PATH=\$ORACLE_HOME/bin:\$PATH

echo "--- [APEX SETUP] Verificando se APEX já está instalado..."

APEX_EXISTS=\$(sqlplus -S / as sysdba <<EOSQL
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF
ALTER SESSION SET CONTAINER = $ORACLE_PDB;
SELECT COUNT(*) FROM dba_registry WHERE comp_id = 'APEX';
EXIT;
EOSQL
)

APEX_EXISTS=\$(echo \$APEX_EXISTS | tr -d '[:space:]')

if [ "\$APEX_EXISTS" != "0" ]; then
    echo "--- [APEX SETUP] APEX já está instalado. Pulando instalação."
    exit 0
fi

echo "--- [APEX SETUP] Baixando APEX..."
cd /tmp
curl -o apex-latest.zip https://download.oracle.com/otn_software/apex/apex-latest.zip
unzip -o apex-latest.zip
cd apex

echo "--- [APEX SETUP] Instalando APEX no PDB $ORACLE_PDB (~15-20 minutos)..."

sqlplus / as sysdba <<EOSQL
ALTER SESSION SET CONTAINER = $ORACLE_PDB;
@apexins.sql SYSAUX SYSAUX TEMP /i/
EXIT;
EOSQL

echo "--- [APEX SETUP] Configurando REST..."

sqlplus / as sysdba <<EOSQL
ALTER SESSION SET CONTAINER = $ORACLE_PDB;
@apex_rest_config.sql $ORACLE_PWD $ORACLE_PWD
EXIT;
EOSQL

echo "--- [APEX SETUP] Configurando usuários APEX..."

sqlplus / as sysdba <<EOSQL
ALTER SESSION SET CONTAINER = $ORACLE_PDB;

-- Desbloquear APEX_PUBLIC_USER
ALTER USER APEX_PUBLIC_USER IDENTIFIED BY "$ORACLE_PWD" ACCOUNT UNLOCK;

-- Criar admin do APEX
BEGIN
    APEX_UTIL.SET_SECURITY_GROUP_ID(10);
    APEX_UTIL.CREATE_USER(
        p_user_name       => 'ADMIN',
        p_email_address   => '$APEX_ADMIN_EMAIL',
        p_web_password    => '$APEX_ADMIN_PWD',
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

-- Configurar ACL para network
DECLARE
    l_apex_schema VARCHAR2(30);
BEGIN
    SELECT schema INTO l_apex_schema FROM dba_registry WHERE comp_id = 'APEX';
    
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => '*',
        ace  => xs\\\$ace_type(
            privilege_list => xs\\\$name_list('connect'),
            principal_name => l_apex_schema,
            principal_type => xs_acl.ptype_db
        )
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ACL warning: ' || SQLERRM);
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
echo "Senha:     $APEX_ADMIN_PWD"
echo "=============================================="
EOF
    
    print_success "Scripts de setup criados"
}

create_startup_scripts() {
    print_step "Criando scripts de startup..."
    
    # 01_enable_ssl.sh
    cat > "$WORK_DIR/scripts/startup/01_enable_ssl.sh" << EOF
#!/bin/bash

export ORACLE_SID=$ORACLE_SID
export ORACLE_HOME=/opt/oracle/product/21c/dbhome_1
export PATH=\$ORACLE_HOME/bin:\$PATH
export TNS_ADMIN=/opt/oracle/oradata/dbconfig/\$ORACLE_SID
export WALLET_DIR=/opt/oracle/oradata/wallet

echo "--- [SSL] Verificando configuração SSL..."

# Criar wallet apenas se não existir
if [ ! -f "\$WALLET_DIR/cwallet.sso" ]; then
    echo "--- [SSL] Criando wallet..."
    mkdir -p \$WALLET_DIR
    orapki wallet create -wallet \$WALLET_DIR -pwd Oracle21 -auto_login
    orapki wallet add -wallet \$WALLET_DIR -pwd Oracle21 \\
        -dn "CN=oracle-db" \\
        -keysize 2048 -self_signed -validity 3650
    orapki wallet export -wallet \$WALLET_DIR -pwd Oracle21 \\
        -dn "CN=oracle-db" \\
        -cert \$WALLET_DIR/server.crt
    chmod 755 \$WALLET_DIR
    chmod 644 \$WALLET_DIR/*
    echo "--- [SSL] Wallet criado."
else
    echo "--- [SSL] Wallet já existe."
fi

# Verificar se listener.ora já tem TCPS configurado
if grep -q "TCPS" "\$TNS_ADMIN/listener.ora" 2>/dev/null; then
    echo "--- [SSL] SSL já configurado no listener."
    exit 0
fi

echo "--- [SSL] Configurando arquivos .ora..."

cat > \$TNS_ADMIN/listener.ora <<'LISTENER'
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

cat > \$TNS_ADMIN/sqlnet.ora <<'SQLNET'
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

cat > \$TNS_ADMIN/tnsnames.ora <<TNSNAMES
${ORACLE_PDB}_TCP =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = oracle-db)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${ORACLE_PDB,,})
    )
  )

${ORACLE_PDB}_TCPS =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCPS)(HOST = oracle-db)(PORT = 2484))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${ORACLE_PDB,,})
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
ALTER SESSION SET CONTAINER = $ORACLE_PDB;
ALTER SYSTEM SET LOCAL_LISTENER='
  (DESCRIPTION_LIST=
    (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=0.0.0.0)(PORT=1521)))
    (DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=0.0.0.0)(PORT=2484)))
  )' SCOPE=BOTH;
ALTER SYSTEM REGISTER;
EXIT;
EOSQL

echo "--- [SSL] Configuração finalizada!"
EOF
    
    print_success "Scripts de startup criados"
}

set_permissions() {
    print_step "Configurando permissões..."
    
    # Permissão de execução nos scripts
    chmod +x "$WORK_DIR/scripts/setup/"*.sh 2>/dev/null || true
    chmod +x "$WORK_DIR/scripts/setup/"*.sql 2>/dev/null || true
    chmod +x "$WORK_DIR/scripts/startup/"*.sh 2>/dev/null || true
    
    # Ownership para usuário oracle (UID 54321)
    sudo chown -R 54321:54321 "$WORK_DIR/data"
    sudo chown -R 54321:54321 "$WORK_DIR/containers"
    sudo chown -R 54321:54321 "$WORK_DIR/restore"
    sudo chown -R 54321:54321 "$WORK_DIR/ords"
    sudo chown -R 54321:54321 "$WORK_DIR/scripts"
    
    print_success "Permissões configuradas"
}

print_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ESTRUTURA CRIADA COM SUCESSO!                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Estrutura criada:${NC}"
    echo "  ├── docker-compose.yaml"
    echo "  ├── settings.ini"
    echo "  ├── data/"
    echo "  ├── containers/"
    echo "  ├── restore/"
    echo "  ├── ords/config/global/settings.xml"
    echo "  └── scripts/"
    echo "      ├── setup/"
    echo "      │   ├── 01_create_directories.sh"
    echo "      │   ├── 02_configure_pdb.sql"
    echo "      │   ├── 03_create_tablespaces.sql"
    echo "      │   ├── 04_create_user.sql"
    echo "      │   ├── 05_install_apex.sql"
    echo "      │   └── 06_install_apex.sh"
    echo "      └── startup/"
    echo "          └── 01_enable_ssl.sh"
    echo ""
    echo -e "${CYAN}Próximos passos:${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Iniciar o Oracle Database:"
    echo -e "     ${GREEN}docker compose up -d oracle21${NC}"
    echo ""
    echo -e "  ${YELLOW}2.${NC} Acompanhar os logs (aguarde 'DATABASE IS READY TO USE!'):"
    echo -e "     ${GREEN}docker compose logs -f oracle21${NC}"
    echo ""
    echo -e "  ${YELLOW}3.${NC} Após o banco estar pronto, iniciar o ORDS:"
    echo -e "     ${GREEN}docker compose up -d ords${NC}"
    echo ""
    echo -e "${CYAN}Acesso ao APEX:${NC}"
    if [ -n "$ORDS_DOMAIN" ]; then
        echo -e "  URL:       ${GREEN}https://$ORDS_DOMAIN/ords/apex${NC}"
    else
        echo -e "  URL:       ${GREEN}http://localhost:$ORDS_HTTP_PORT/ords/apex${NC}"
    fi
    echo -e "  Workspace: ${GREEN}INTERNAL${NC}"
    echo -e "  Usuário:   ${GREEN}ADMIN${NC}"
    echo -e "  Senha:     ${GREEN}$APEX_ADMIN_PWD${NC}"
    echo ""
    echo -e "${CYAN}Conexão SQL*Plus:${NC}"
    echo -e "  ${GREEN}docker exec -it $ORACLE_CONTAINER_NAME sqlplus sys/$ORACLE_PWD@//localhost:1521/$ORACLE_PDB as sysdba${NC}"
    echo ""
}

# ============================================
# Main
# ============================================

main() {
    print_header
    
    # Validações
    check_docker
    check_docker_compose
    check_oracle_registry
    check_existing_structure
    
    # Configuração
    if [ -f "$SETTINGS_FILE" ]; then
        echo ""
        read -p "Arquivo settings.ini encontrado. Usar configurações existentes? (S/n): " use_existing
        
        if [[ "$use_existing" =~ ^[Nn]$ ]]; then
            configure_interactive
            generate_settings_file
        else
            load_settings_file
        fi
    else
        configure_interactive
        generate_settings_file
    fi
    
    # Criação
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    CRIANDO ESTRUTURA                          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    create_directories
    create_docker_compose
    create_ords_settings
    create_setup_scripts
    create_startup_scripts
    set_permissions
    
    print_summary
}

# Executa
main "$@"

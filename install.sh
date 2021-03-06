#!/bin/bash

set -e

getLogo() {
  echo "                             _____      _            _             "
  echo "                            / __  \    | |          | |            "
  echo " _ __ ___   __ _  __ _  ___ \`' / /'  __| | ___   ___| | _____ _ __ "
  echo "| '_ \` _ \ / _\` |/ _\` |/ _ \  / /   / _\` |/ _ \ / __| |/ / _ \ '__|"
  echo "| | | | | | (_| | (_| |  __/./ /___| (_| | (_) | (__|   <  __/ |   "
  echo "|_| |_| |_|\__,_|\__, |\___|\_____(_)__,_|\___/ \___|_|\_\___|_|   "
  echo "                  __/ |                                            "
  echo "                 |___/                                             "
}

createEnv() {
  if [[ ! -f ./.env ]]; then
    message "cp ./.env.template ./.env"
    cp ./.env.template ./.env
  else
    message ".env File exists already"
  fi
}

createHtdocs() {
  if [ ! -d htdocs ]; then
    mkdir htdocs;
  fi
}

duplicateEnv() {
  if [[ -f ./.env_"$1" ]]; then
    message "rm ./.env_$1"
    rm ./.env_"$1"
  fi

  message "cp ./.env ./.env_$1;"
  cp ./.env ./.env_"$1"
}

getLatestFromRepo() {
  message "git fetch && git pull;"
  git fetch && git pull
}

osxExtraPackages() {
  if [[ ! -x "$(command -v brew)" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
  if [[ ! -x "$(command -v unison)" ]]; then
    message "brew install unison"
    brew install unison
  fi
  if [[ ! -d /usr/local/opt/unox ]]; then
    message "brew install eugenmayer/dockersync/unox"
    brew install eugenmayer/dockersync/unox
  fi
  if [[ ! -x "$(command -v docker-sync)" ]]; then
    message "gem install docker-sync;"
    sudo gem install docker-syncÌ
  fi
}

osxDockerSync() {
  message "docker-sync start"
  docker-sync start
}

dockerRefresh() {
  if ! [[ -x "$(command -v docker-compose)" ]]; then
    message 'Error: docker-compose is not installed.' >&2
    exit 1
  fi

  if [[ $(uname -s) == "Darwin" ]]; then
    osxExtraPackages
    rePlaceInEnv "false" "SSL"
    osxDockerSync

    message "docker-compose -f docker-compose.osx.yml up -d"
    docker-compose -f docker-compose.osx.yml up -d
  else
    message "docker-compose up -d;"
    docker-compose up -d
  fi
}

deleteMagentoEnv() {
  path="$1/app/etc/env.php"
  if test -f "$path"; then
    message "rm $path"
    rm "$path"
  fi
}

magentoComposerJson() {
  JSON=$3/composer.json

  if [[ -f "$JSON" ]]; then
    message "Magento 2 composer.json found"
    if [[ $4 == *"local"* ]]; then
      message "docker exec -it -u $1 $2 composer install"
      docker exec -it -u "$1" "$2" composer install
    else
      message "docker exec -u $1 $2 composer install --no-dev"
      docker exec -it -u "$1" "$2" composer install --no-dev
    fi
  else
    message "Magento 2 Fresh Install"
    [[ -n $5 ]] && VERSION="=$5" || VERSION=""

    message "docker exec -it -u $1 $2 composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition${VERSION} ."
    docker exec -it -u "$1" "$2" composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"${VERSION}" .

    message "docker exec -it -u $1 $2 composer require magepal/magento2-gmailsmtpapp"
    docker exec -it -u "$1" "$2" composer require magepal/magento2-gmailsmtpapp

    if [[ $4 == *"local"* ]]; then
      message "docker exec -it -u $1 $2 composer require --dev vpietri/adm-quickdevbar mage2tv/magento-cache-clean allure-framework/allure-phpunit ~1.2.3"
      docker exec -it -u "$1" "$2" composer require --dev vpietri/adm-quickdevbar mage2tv/magento-cache-clean allure-framework/allure-phpunit ~1.2.3
    fi
  fi
}

installMagento() {
    message "docker exec -u $1 $3 chmod +x bin/magento"
    docker exec -u "$1" "$3" chmod +x bin/magento

    echo "docker exec -it -u $1 $3 php -dmemory_limit=-1 bin/magento setup:install \
    --db-host=db \
    --db-name=$4 \
    --db-user=$5 \
    --db-password=<see .env for password> \
    --backend-frontname=admin \
    --language=de_DE \
    --timezone=Europe/Berlin \
    --currency=EUR \
    --admin-lastname=mage2_admin \
    --admin-firstname=mage2_admin \
    --admin-email=admin@example.com \
    --admin-user=mage2_admin \
    --admin-password=mage2_admin123#T \
    --cleanup-database \
    --use-rewrites=1 \
    --session-save=redis \
    --session-save-redis-host=/var/run/redis/redis.sock \
    --session-save-redis-db=0 --session-save-redis-password='' \
    --cache-backend=redis \
    --cache-backend-redis-server=/var/run/redis/redis.sock \
    --cache-backend-redis-db=1 \
    --page-cache=redis \
    --page-cache-redis-server=/var/run/redis/redis.sock \
    --page-cache-redis-db=2 \
    --search-engine=elasticsearch7 \
    --elasticsearch-host=elasticsearch \
    --elasticsearch-port=9200"

    docker exec -it -u "$1" "$3" php -dmemory_limit=-1 bin/magento setup:install \
      --db-host=db \
      --db-name="$4" \
      --db-user="$5" \
      --db-password="$6" \
      --backend-frontname=admin \
      --language=de_DE \
      --timezone=Europe/Berlin \
      --currency=EUR \
      --admin-lastname=mage2_admin \
      --admin-firstname=mage2_admin \
      --admin-email=admin@example.com \
      --admin-user=mage2_admin \
      --admin-password=mage2_admin123#T \
      --cleanup-database \
      --use-rewrites=1 \
      --session-save=redis \
      --session-save-redis-host=/var/run/redis/redis.sock \
      --session-save-redis-db=0 --session-save-redis-password='' \
      --cache-backend=redis \
      --cache-backend-redis-server=/var/run/redis/redis.sock \
      --cache-backend-redis-db=1 \
      --page-cache=redis \
      --page-cache-redis-server=/var/run/redis/redis.sock \
      --page-cache-redis-db=2 \
      --search-engine=elasticsearch7 \
      --elasticsearch-host=elasticsearch \
      --elasticsearch-port=9200
}

setDomainAndCookieName() {
  SET_URL_SECURE="USE $1; INSERT INTO core_config_data(scope, value, path) VALUES('default', 'http://$5/', 'web/unsecure/base_url') ON DUPLICATE KEY UPDATE value='http://$5/', path='web/unsecure/base_url', scope='default';"
  SET_URL_UNSECURE="USE $1; INSERT INTO core_config_data(scope, value, path) VALUES('default', 'https://$5/', 'web/secure/base_url') ON DUPLICATE KEY UPDATE value='https://$5/', path='web/secure/base_url', scope='default';"
  SET_URL_COOKIE="USE $1; INSERT core_config_data(scope, value, path) VALUES('default', '$5', 'web/cookie/cookie_domain') ON DUPLICATE KEY UPDATE value='$5', path='web/cookie/cookie_domain', scope='default';"

  message "URL Settings and Cookie Domain"
  docker exec "$4" mysql -u "$2" -p"$3" -e "${SET_URL_SECURE}"
  docker exec "$4" mysql -u "$2" -p"$3" -e "${SET_URL_UNSECURE}"
  docker exec "$4" mysql -u "$2" -p"$3" -e "${SET_URL_COOKIE}"
}

setElasticsearchAfterDBImport() {
  SET_ELASTIC_1="USE $1; INSERT INTO core_config_data(scope, value, path) VALUES('default', 'elasticsearch7', 'catalog/search/engine') ON DUPLICATE KEY UPDATE value='elasticsearch7', path='catalog/search/engine', scope='default';"
  SET_ELASTIC_2="USE $1; INSERT INTO core_config_data(scope, value, path) VALUES('default', 'elasticsearch', 'catalog/search/elasticsearch7_server_hostname') ON DUPLICATE KEY UPDATE value='elasticsearch', path='catalog/search/elasticsearch7_server_hostname', scope='default';"
  SET_ELASTIC_3="USE $1; INSERT core_config_data(scope, value, path) VALUES('default', '9200', 'catalog/search/elasticsearch7_server_port') ON DUPLICATE KEY UPDATE value='9200', path='catalog/search/elasticsearch7_server_port', scope='default';"

  message "Elasticsearch DB Config "
  docker exec "$2" mysql -u "$3" -p"$4" -e "${SET_ELASTIC_1}"
  docker exec "$2" mysql -u "$3" -p"$4" -e "${SET_ELASTIC_2}"
  docker exec "$2" mysql -u "$3" -p"$4" -e "${SET_ELASTIC_3}"
}

setToHTTP() {
  message "Set to HTTP only"
  IS_SECURE_2="USE $1; INSERT INTO core_config_data(scope, value, path) VALUES('default', '0', 'web/secure/use_in_adminhtml') ON DUPLICATE KEY UPDATE value='0', path='web/secure/use_in_adminhtml', scope='default';"
  IS_SECURE_1="USE $1; INSERT INTO core_config_data(scope, value, path) VALUES('default', '0', 'web/secure/use_in_frontend') ON DUPLICATE KEY UPDATE value='0', path='web/secure/use_in_frontend', scope='default';"

  docker exec "$2" mysql -u "$3" -p"$4" -e "${IS_SECURE_1}"
  docker exec "$2" mysql -u "$3" -p"$4" -e "${IS_SECURE_2}"
}

mailHogConfig() {
  SET_URL_SSL="USE $1; INSERT INTO core_config_data(scope, path, value) VALUES('default', 'system/gmailsmtpapp/ssl', 'none') ON DUPLICATE KEY UPDATE scope='default', path='system/gmailsmtpapp/ssl', value='none';"
  SET_URL_HOST="USE $1; INSERT INTO core_config_data(scope, path, value) VALUES('default', 'system/gmailsmtpapp/smtphost', 'mailhog') ON DUPLICATE KEY UPDATE scope='default', path='system/gmailsmtpapp/smtphost', value='mailhog';"
  SET_URL_PORT="USE $1; INSERT INTO core_config_data(scope, path, value) VALUES('default', 'system/gmailsmtpapp/smtpport', '1025') ON DUPLICATE KEY UPDATE scope='default', path='system/gmailsmtpapp/smtpport', value='1025';"

  message "Mailhog Config"
  docker exec "$4" mysql -u "$2" -p"$3" -e "${SET_URL_SSL}"
  docker exec "$4" mysql -u "$2" -p"$3" -e "${SET_URL_HOST}"
  docker exec "$4" mysql -u "$2" -p"$3" -e "${SET_URL_PORT}"
}

magentoRefresh() {
  message "docker exec -u $1 $2 bin/magento se:up;"
  docker exec -u "$1" "$2" bin/magento se:up

  message "docker exec -u $1  $2 bin/magento c:c;"
  docker exec -u "$1" "$2" bin/magento c:c
}

getMagerun() {
  if [[ $3 == *"local"* ]]; then
    message "curl -L https://files.magerun.net/n98-magerun2.phar > n98-magerun2.phar"
    curl -L https://files.magerun.net/n98-magerun2.phar >n98-magerun2.phar

    message "chmod +x n98-magerun2.phar"
    chmod +x n98-magerun2.phar

    message "docker cp -a n98-magerun2.phar $2:/home/$1/html/n98-magerun2.phar"
    docker cp -a n98-magerun2.phar "$2":/home/"$1"/html/n98-magerun2.phar

    message "rm -rf ./n98-magerun2.phar;"
    rm -rf ./n98-magerun2.phar
  fi
}

workDirCreate() {
  if [[ ! -d "$1" ]]; then
    if ! mkdir -p "$1"; then
      message "Folder can not be created"
    else
      message "Folder created"
    fi
  else
    message "Folder already exits"
  fi
}

setAuthConfig() {
  if [[ "$1" == "true" ]]; then
    prompt "rePlaceInEnv" "Login User Name (current: $2)" "AUTH_USER"
    prompt "rePlaceInEnv" "Login User Password (current: $3)" "AUTH_PASS"
  fi
}

setComposerCache() {
  mkdir -p ~/.composer
}

DBDumpImport() {
  if [[ -n $1 && -f $1 ]]; then
    message "docker exec -i $2_db mysql -u $3 -p<see .env for password> $5 < $1;"
    docker exec -i "$2"_db mysql -u "$3" -p"$4" "$5" <"$1"
  else
    message "SQL File not found"
  fi
}

setConfigAfterDBImport() {
  path="$5/app/etc/env.php"

  cp .docker/config_blueprints/env.php "$path"

  if [[ $(uname -s) == "Darwin" ]]; then
    sed -i "" "s@__host@$1@" "$path"
    sed -i "" "s@__dbname@$2@" "$path"
    sed -i "" "s@__username@$3@" "$path"
    sed -i "" "s@__password@$4@" "$path"
  else
    sed -i "s@__host@$1@" "$path"
    sed -i "s@__dbname@$2@" "$path"
    sed -i "s@__username@$3@" "$path"
    sed -i "s@__password@$4@" "$path"
  fi
}

createAdminUser() {
    message "docker exec -u $1 $2 bin/magento admin:user:create \
      --admin-lastname=mage2_admin \
      --admin-firstname=mage2_admin \
      --admin-email=admin@example.com \
      --admin-user=mage2_admin \
      --admin-password=mage2_admin123#T"
    docker exec -u "$1" "$2" bin/magento admin:user:create \
      --admin-lastname=mage2_admin \
      --admin-firstname=mage2_admin \
      --admin-email=admin@example.com \
      --admin-user=mage2_admin \
      --admin-password=mage2_admin123#T
}

sampleDataInstall() {
  if [[ "$1" == "true" ]]; then
    chmod +x sample-data.sh
    ./sample-data.sh
  fi
}

specialPrompt() {
  if [[ -n "$1" ]]; then
    read -rp "$1" RESPONSE
    if [[ ${RESPONSE} == '' || ${RESPONSE} == 'n' || ${RESPONSE} == 'N' ]]; then
      rePlaceInEnv "false" "SAMPLE_DATA"
      rePlaceInEnv "" "DB_DUMP"
    elif [[ ${RESPONSE} == 's' || ${RESPONSE} == 'S' ]]; then
      rePlaceInEnv "true" "SAMPLE_DATA"
      rePlaceInEnv "" "DB_DUMP"
    elif [[ ${RESPONSE} == 'd' || ${RESPONSE} == 'D' ]]; then
      rePlaceInEnv "false" "SAMPLE_DATA"
      prompt "rePlaceInEnv" "Set Absolute Path to Project DB Dump (current: ${DB_DUMP})" "DB_DUMP"
    fi
  fi
}

rePlaceInEnv() {
  if [[ -n "$1" ]]; then
    rePlaceIn "$1" "$2" "./.env"
    if [[ $2 == "COMPOSE_PROJECT_NAME" ]]; then
      rePlaceIn "$1" "NAMESPACE" "./.env"
      rePlaceIn "$1" "MYSQL_DATABASE" "./.env"
      rePlaceIn "$1" "MYSQL_USER" "./.env"
    fi
  fi

  if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
    # shellcheck disable=SC2046
    rePlaceIn $(openssl rand -base64 12) "MYSQL_ROOT_PASSWORD" "./.env"
  fi

  if [[ "$MYSQL_PASSWORD" == "" ]]; then
    # shellcheck disable=SC2046
    rePlaceIn $(openssl rand -base64 12) "MYSQL_PASSWORD" "./.env"
  fi
}

rePlaceIn() {
  [[ "$1" == "yes" || "$1" == "y" ]] && value="true" || value=$1
  pattern=".*$2.*"
  replacement="$2=$value"
  envFile="$3"
  if [[ $(uname -s) == "Darwin" ]]; then
    sed -i "" "s@${pattern}@${replacement}@" "${envFile}"
  else
    sed -i "s@${pattern}@${replacement}@" "${envFile}"
  fi
}

prompt() {
  if [[ -n "$2" ]]; then
    read -rp "$2" RESPONSE
    [[ ${RESPONSE} == '' && $3 == 'WORKDIR' ]] && VALUE=${RESPONSE} || VALUE=${RESPONSE}
    # shellcheck disable=SC2091
    $($1 "${VALUE}" "$3")
  fi
}

message() {
  echo ""
  echo -e "$1"
  seq ${#1} | awk '{printf "-"}'
  echo ""
}

productionModeOnLive() {
  if [[ $3 != *"local"* ]]; then
    message "docker exec -u $1 $2 bin/magento c:e full_page;"
    docker exec -u "$1" "$2" bin/magento c:e full_page

    message "docker exec -u $1 $2 bin/magento c:c;"
    docker exec -u "$1" "$2" bin/magento c:c

    message "docker exec -u $1 $2 bin/magento deploy:mode:set production;"
    docker exec -u "$1" "$2" bin/magento deploy:mode:set production
  fi
}

composerOptimzerWithAPCu() {
  message "docker exec -u $1 $2 composer dump-autoload -o --apcu"
  docker exec -u "$1" "$2" composer dump-autoload -o --apcu
}

showSuccess() {
  if [ -n "$2" ]; then
    message "Yeah, You done !"
    message "Backend:\

http://$1/admin\

User: <Backend Users from Your DB Dump>\

Password: <Backend Users Passwords from Your DB Dump>\


Frontend:\

http://$1"
  else
    message "Backend:\

http://$1/admin\

User: mage2_admin\

Password: mage2_admin123#T\


Frontend:\

http://$1"
  fi

}

MagentoTwoFactorAuthDisable() {
  message "docker exec -u $1 $2 bin/magento module:disable -c Magento_TwoFactorAuth"
  docker exec -u "$1" "$2" bin/magento module:disable -c Magento_TwoFactorAuth
}

startAll=$(date +%s)

getLogo
createEnv

# shellcheck disable=SC1090
. "${PWD}"/.env
message "Press [ENTER] alone to keep the current values"
prompt "rePlaceInEnv" "Project Name (alphanumeric only) (current: ${COMPOSE_PROJECT_NAME})" "COMPOSE_PROJECT_NAME"
prompt "rePlaceInEnv" "Absolute path to empty folder(fresh install) or running project (current: ${WORKDIR})" "WORKDIR"
prompt "rePlaceInEnv" "Domain Name (current: ${SHOPURI})" "SHOPURI"
specialPrompt "Use Project DB [d]ump, [s]ample data or [n]one of the above?"
prompt "rePlaceInEnv" "Which PHP 7 Version? (7.1, 7.2, 7.3, 7.4) (current: ${PHP_VERSION_SET})" "PHP_VERSION_SET"
prompt "rePlaceInEnv" "Which MariaDB Version? (10.4) (current: ${MARIADB_VERSION})" "MARIADB_VERSION"
prompt "rePlaceInEnv" "Which Elasticsearch Version? (6.8.x, 7.6.x, 7.8.x, 7.9.x) (current: ${ELASTICSEARCH_VERSION})" "ELASTICSEARCH_VERSION"

. "${PWD}"/.env
if test ! -f "${WORKDIR}/composer.json"; then
  MAGE_LATEST="latest"
  read -rp "Which Magento 2 Version? (current: ${MAGE_LATEST})" MAGENTO_VERSION
fi

prompt "rePlaceInEnv" "Create a login screen? (current: ${AUTH_CONFIG})" "AUTH_CONFIG"

. "${PWD}"/.env
PHP="${NAMESPACE}_php"
DB="${NAMESPACE}_db"
MYSQL_SOCKET="db"

createHtdocs
setAuthConfig "$AUTH_CONFIG" "$AUTH_USER" "$AUTH_PASS"
setComposerCache
deleteMagentoEnv "$WORKDIR"
dockerRefresh
magentoComposerJson "$USER" "$PHP" "$WORKDIR" "$SHOPURI" "$MAGENTO_VERSION"
installMagento "$USER" "$SHOPURI" "$PHP" "$MYSQL_DATABASE" "$MYSQL_USER" "$MYSQL_PASSWORD" "$SSL" "$DB_DUMP"
DBDumpImport "$DB_DUMP" "$NAMESPACE" root "$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"
setElasticsearchAfterDBImport "$MYSQL_DATABASE" "$DB" "$MYSQL_USER" "$MYSQL_PASSWORD"
setToHTTP "$MYSQL_DATABASE" "$DB" "$MYSQL_USER" "$MYSQL_PASSWORD"
setConfigAfterDBImport "$MYSQL_SOCKET" "$MYSQL_DATABASE" "$MYSQL_USER" "$MYSQL_PASSWORD" "$WORKDIR"
setDomainAndCookieName "$NAMESPACE" "$MYSQL_USER" "$MYSQL_PASSWORD" "$DB" "$SHOPURI"
mailHogConfig "$NAMESPACE" "$MYSQL_USER" "$MYSQL_PASSWORD" "$DB"
sampleDataInstall "$SAMPLE_DATA"
MagentoTwoFactorAuthDisable "$USER" "$PHP"
createAdminUser "$USER" "$PHP" "$DUMP"
magentoRefresh "$USER" "$PHP" "$SHOPURI" "$SAMPLE_DATA"
productionModeOnLive "$USER" "$PHP" "$SHOPURI"
duplicateEnv "$COMPOSE_PROJECT_NAME"

endAll=$(date +%s)
runtimeAll=$((endAll - startAll))
message "Setup Time: ${runtimeAll} Sec"

showSuccess "$SHOPURI" "$DUMP"

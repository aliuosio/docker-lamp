#!/bin/bash

set -e

message() {
  echo ""
  echo -e "$1"
  seq ${#1} | awk '{printf "-"}'
  echo ""
}

addPathToBashProfile() {
  echo "export PATH=/home/$1/html/node_modules/.bin:\$PATH" >>/home/$1/.bash_profile
}

phpSettings() {
  sed -i "s#__user#$1#g" /usr/local/etc/php-fpm.d/zz-docker.conf
}

runWaitForIt() {
  wait-for-it.sh db:3306
}

setUser() {
  if [[ $(grep -c "$1" /etc/passwd) == 0 ]]; then
    addgroup -g 1000 "$1"
    adduser -D --uid 1000 --ingroup "$1" "$1"
    chown -R "$1":"$1" /home/"$1"
    chmod -R 755 /home/"$1"
    chmod 600 "/home/$1/.ssh/id_rsa"
    chmod 644 "/home/$1/.ssh/id_rsa.pub"
    # shellcheck disable=SC2117
    su "$1"
  fi
}

composerInstall() {
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer;
  chmod +x /usr/local/bin/composer;
  if [[ "$1" != "2.4.2" ]]; then
    composer self-update --1;
    composer global require hirak/prestissimo;
  fi
}

phpSettings "$USER"
setUser "$USER"
addPathToBashProfile "$USER"
chown -R "$USER":"$USER" /home/"$USER"
composerInstall "$MAGENTO_VERSION"
runWaitForIt
php-fpm -F
exec "$@"

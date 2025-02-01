#!/bin/bash

set -e;

# Only run the seeds if we're in local docker.
if [ "$ENV" == "development" ] || [ "$ENV" == "staging" ]; then
  # Wait for mysql
  while ! mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "SHOW DATABASES LIKE 'foo'" ; do
    echo "Waiting for mysql"
    sleep 1
  done

  if mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "SHOW DATABASES" | grep -q $MYSQL_DATABASE; then
    echo "$MYSQL_DATABASE exists"
  else
    echo "$MYSQL_DATABASE not found - fetching, creating, and seeding"

    cd /tmp

    curl https://s3.amazonaws.com/software-packages.wishpond.com/wordpress/wordpress.tgz --output /tmp/wordpress.tgz
    echo "97f7b6ec966b17437a46545121a0bc86  /tmp/wordpress.tgz" | md5sum -c -
    tar xzf wordpress.tgz

    mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "CREATE DATABASE \`$MYSQL_DATABASE\` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"

    if [ "$ENV" == "staging" ]; then
      sed 's|lvh\.me|staging.wishpond.com|g' wordpress.sql | mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOST $MYSQL_DATABASE
    else
      mysql -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -h $MYSQL_HOST $MYSQL_DATABASE < wordpress.sql
    fi

    rm wordpress*
  fi

  # Ensure we've got the right structure on /store for the symlinking
  mkdir -p /store/wp-content/{uploads,cache}
  if [ ! -d /store/wp-content/w3tc-config ]; then
    cp -vr /deployment/config_seeds/w3tc-config /store/wp-content/
  fi
  if [ ! -f /store/wp-content/advanced-cache.php ]; then
    cp -vr /deployment/config_seeds/advanced-cache.php /store/wp-content/
  fi
  if [ ! -f /store/wp-content/object-cache.php ]; then
    cp -vr /deployment/config_seeds/object-cache.php /store/wp-content/
  fi

  chown -R www-data:www-data /store/wp-content

  if [ "$ENV" == "staging" ]; then
    sed -i 's|lvh\.me|staging.wishpond.com|' /store/wp-content/w3tc-config/master.php
  fi

  # Start watching the css
  /usr/local/bin/build-css.sh watch &
fi

if [ -d /store/wp-content/cache/autoptimize ]; then
  echo "Removing outdated autoptimize assets"
  find /store/wp-content/cache/autoptimize -mtime +31 -exec rm -v {} \;
fi

echo "Heyo, let's start up."

# Make sure we symlink in all the configs/uploads
rm -rf /var/www/html/wp-content/{uploads,cache}
ln -nfs /store/wp-content/* /var/www/html/wp-content/

# And start everything
supervisord -n -c /etc/supervisord.conf

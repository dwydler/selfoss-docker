#!/bin/sh

########################################
# Generate configuration from templates
########################################

# Set cron period, attachment size limit and memory limit
sed -i "s/<CRON_PERIOD>/$CRON_PERIOD/g" /services/cron/run
sed -i "s/<UPLOAD_MAX_SIZE>/$UPLOAD_MAX_SIZE/g" /etc/php82/conf.d/99_custom.ini /etc/nginx/nginx.conf
sed -i "s/<MEMORY_LIMIT>/$MEMORY_LIMIT/g" /etc/php82/conf.d/99_custom.ini
sed -i "s#<DATE_TIMEZONE>#$TIMEZONE#g" /etc/php82/conf.d/99_custom.ini

# Set how many log files should be kept
sed -i "s#<LOGROTATE_RETENTION>#$LOGROTATE_RETENTION#g" /etc/logrotate.d/selfoss

########################################
# Selfoss configuration
########################################

rm -f /selfoss/config.ini

if [ ! -e /selfoss/data/config.ini ]; then
  cp "${SELFOSS_CONFIG_FILE:-/selfoss/config-example.ini}" /selfoss/data/config.ini

  sed -i "s/lkjl1289/`cat \/dev\/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1`/g" /selfoss/data/config.ini
fi

cp /selfoss/data/config.ini /selfoss/config.ini

########################################
# Ensure required directories exist
########################################

mkdir -p \
  /selfoss/data/cache \
  /selfoss/data/favicons \
  /selfoss/data/fulltextrss \
  /selfoss/data/logs \
  /selfoss/data/sqlite \
  /selfoss/data/thumbnails

########################################
# Logging to stdout (optional)
########################################

if [ "$LOG_TO_STDOUT" = true ]; then
  echo "[INFO] Logging to stdout activated"
  chmod o+w /dev/stdout
  sed -i "s/.*error_log.*$/error_log \/dev\/stdout warn;/" /etc/nginx/nginx.conf
  sed -i "s/.*error_log.*$/error_log = \/dev\/stdout/" /etc/php82/php-fpm.conf
fi

########################################
# Permissions (only where needed)
########################################

chown -R $UID:$GID /selfoss /services /var/log /var/lib/nginx
chown root:selfoss /etc/crontabs/selfoss
chmod 755 /etc/crontabs/selfoss

########################################
# Start s6
########################################
exec su-exec $UID:$GID /usr/bin/s6-svscan /services

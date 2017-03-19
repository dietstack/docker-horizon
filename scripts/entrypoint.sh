#!/bin/bash
set -e

# set debug
DEBUG_OPT=False
if [[ $DEBUG ]]; then
        set -x
        DEBUG_OPT=True
fi

# if horizon is not installed, quit
#which horizon-all &>/dev/null || exit 1

# define variable defaults

LOG_MESSAGE="Docker start script:"
CONF_DIR="/horizon/openstack_dashboard/local"
OVERRIDE_DIR="/horizon-override"
CONF_FILES="local_settings.py"

TIME_ZONE=${TIME_ZONE:-'Europe\/Bratislava'}
KEYSTONE_HOST=${KEYSTONE_HOST:-127.0.0.1}
MEMCACHED_SERVERS=${MEMCACHED_SERVERS:-127.0.0.1:11211}
MULTIDOMAIN=${MULTIDOMAIN:-False}
HORIZON_HTTP_PORT=${HORIZON_HTTP_PORT:-80}

for CONF in ${CONF_FILES[*]}; do
       echo "$LOG_MESSAGE generating $CONF file ..."
       sed -i "s/\b_DEBUG_OPT_\b/$DEBUG_OPT/" $CONF_DIR/$CONF
       sed -i "s/\b_KEYSTONE_HOST_\b/$KEYSTONE_HOST/" $CONF_DIR/$CONF
       sed -i "s/\b_MEMCACHED_SERVERS_\b/$MEMCACHED_SERVERS/" $CONF_DIR/$CONF
       sed -i "s/\b_TIME_ZONE_\b/$TIME_ZONE/" $CONF_DIR/$CONF
       sed -i "s/\b_MULTIDOMAIN_\b/$MULTIDOMAIN/" $CONF_DIR/$CONF
done
echo "$LOG_MESSAGE  ==> done"

# we need to change owner of local_settings.py config file
# because uwsgi is running under horizon user
chown horizon:horizon $CONF_DIR/local_settings.py

# configure port where horizon will listen
sed -i "s/\b_HORIZON_HTTP_PORT_\b/$HORIZON_HTTP_PORT/" /etc/nginx/sites-enabled/horizon.conf

# configure wsgi file for uwsgi server
# (kmadac )it used to be in Dockerfile, but I had to move it
# after variables replacement local_settings.py because manage.py
# raised exception
/horizon/manage.py make_web_conf --wsgi --force;

# generate statics
/horizon/manage.py collectstatic --noinput && chown -R horizon:www-data /horizon/openstack_dashboard/local /horizon/static;

echo "$LOG_MESSAGE starting horizon"
exec "$@"

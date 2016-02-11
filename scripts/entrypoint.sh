#!/bin/bash
set -e

exit 0

# set debug
[[ $DEBUG ]] && set -x

# if horizon is not installed, quit
#which horizon-all &>/dev/null || exit 1

# define variable defaults

LOG_MESSAGE="Docker start script:"
OVERRIDE=0
CONF_DIR="/horizon/openstack_dashboard"
OVERRIDE_DIR="/horizon-override"
CONF_FILE="local_settings.py"


# check if external config is provided
echo "$LOG_MESSAGE Checking if external config is provided.."
if [[ -f "$OVERRIDE_DIR/$CONF_FILE" ]]; then
        echo "$LOG_MESSAGE  ==> external config found!. Using it."
        OVERRIDE=1
        rm -f "$CONF_DIR/$CONF_FILE"
        ln -s "$OVERRIDE_DIR/$CONF_FILE" "$CONF_DIR/$CONF_FILE"
fi

if [[ $OVERRIDE -eq 0 ]]; then
fi

echo "$LOG_MESSAGE starting horizon"
exec "$@"

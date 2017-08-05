#!/bin/bash
# Placeholder for test script

DOCKER_PROJ_NAME=${DOCKER_PROJ_NAME:-''}
CONT_PREFIX=test
PORT=8082

. lib/functions.sh

cleanup() {
    echo "Clean up ..."
    docker stop ${CONT_PREFIX}_horizon
    docker rm ${CONT_PREFIX}_horizon
}

wait_for_horizon() {
    local timeout=$1
    local counter=0
    echo "Wait till horizon login responsds with 200 code ..."
    while [[ $counter -lt $timeout ]]; do
        local counter=$[counter + 5]
        local OUT=$(curl -s -L -w '%{http_code}' http://127.0.0.1:$PORT | tail -n 1)
        if [[ $OUT != '200' ]]; then
            echo -n ". "
        else
            break
        fi
        sleep 5
    done

    if [[ $timeout -eq $counter ]]; then
        exit 1
    fi
}

cleanup

./build.sh

echo "Starting horizon container ..."
docker run -d --net=host \
           -e DEBUG="true" \
           -e HORIZON_HTTP_PORT=$PORT \
           --name ${CONT_PREFIX}_horizon \
           ${DOCKER_PROJ_NAME}horizon:latest

wait_for_horizon 120

echo "======== Success :) ========="

if [[ "$1" != "noclean" ]]; then
    cleanup
fi

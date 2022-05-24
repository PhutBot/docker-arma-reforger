#!/bin/bash

if [[ -f "${DATA_DIR}/.env" ]]; then
    source <(cat ${DATA_DIR}/.env | grep -v "#" | sed 's/=\s*$/=""/g' | sed 's/\r$//' | sed 's/^/export /')
fi

if [[ -z "${ARS_ADMIN_PASSWORD}" ]]; then
    export ARS_ADMIN_PASSWORD=$(echo $RANDOM | md5sum | head -c 20)
fi

if [[ -z "${ARS_DEDICATED_SERVER_ID}" ]]; then
    export ARS_DEDICATED_SERVER_ID=$(echo $RANDOM | md5sum | head -c 32)
fi

printenv | grep "ARS_"

if [[ -z "${SERVER_IP}" ]]; then
    if [[ ! -z "${ECS_CONTAINER_METADATA_URI_V4}" ]]; then
        echo "ECS_CONTAINER_METADATA_URI_V4: '${ECS_CONTAINER_METADATA_URI_V4}'"
        wget -qO- ${ECS_CONTAINER_METADATA_URI_V4}/task | jq -c | tee ${DATA_DIR}/metadata.json
        AWS_ECS_TASK_ID=$(cat ${DATA_DIR}/metadata.json | jq '.TaskARN' | xargs)
    fi

    echo "AWS_ECS_TASK_ID: '$AWS_ECS_TASK_ID'"
    aws ecs describe-tasks --cluster $AWS_ECS_CLUSTER_ID --task $AWS_ECS_TASK_ID | jq -c | tee ${DATA_DIR}/tasks.json
    ENI_ID=$(cat ${DATA_DIR}/tasks.json | jq '.tasks[0].attachments[0].details[1].value' | xargs) 
    echo "ENI_ID: '$ENI_ID'"

    aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID | jq -c | tee ${DATA_DIR}/interfaces.json
    IP_ADDR=$(cat ${DATA_DIR}/interfaces.json | jq '.NetworkInterfaces[0].Association.PublicIp' | xargs)
    SERVER_IP=${SERVER_IP:=$(echo $IP_ADDR)}
fi

if [[ ! -f "${DATA_DIR}/config.json" ]]; then
    envsubst < "${DATA_DIR}/default-config.json.template" > "${DATA_DIR}/config.json"
fi
cat "${DATA_DIR}/config.json"

echo "DRY_RUN: $DRY_RUN"
echo "Starting server @$SERVER_IP:$SERVER_PORT"
if [[ -z "${DRY_RUN}" ]]; then
    if [[ ! -f "${GAME_DIR}/ArmaReforgerServer" ]]; then
        ./steamcmd/steamcmd.sh \
            +force_install_dir ${GAME_DIR} \
            +login anonymous \
            +app_update ${GAME_STEAMID} validate \
            +quit
    fi

    cd ${GAME_DIR}
    ./ArmaReforgerServer \
        -gproj ./addons/data/ArmaReforger.gproj \
        -config ${DATA_DIR}/config.json \
        -profile ${DATA_DIR}/profile \
        -addonsDir ${DATA_DIR}/addons \
        -backendlog -nothrow -maxFPS 60
fi

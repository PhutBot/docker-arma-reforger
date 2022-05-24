FROM cm2network/steamcmd:root

LABEL maintainer="PhutBot - https://github.com/PhutBot"

ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV AWS_DEFAULT_REGION="us-east-1"
ENV AWS_DEFAULT_OUTPUT="json"
ENV AWS_ECS_CLUSTER_ID=""
ENV AWS_ECS_TASK_ID=""

ENV GAME_STEAMID="1874900"
ENV GAME_NAME="arma-reforger"
ENV GAME_DIR="${HOMEDIR}/${GAME_NAME}"
ENV DATA_DIR="${HOMEDIR}/data"

ENV SERVER_IP=""
ENV SERVER_PORT="2001"

WORKDIR ${HOMEDIR}
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        libcurl4 \
        net-tools \
        libssl1.1 \
        unzip \
        less \
        wget \
        jq \
        gettext-base \
    && apt-get remove --purge -y \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

VOLUME ${GAME_DIR}
# VOLUME ${DATA_DIR}

RUN ./steamcmd/steamcmd.sh \
    +force_install_dir ${GAME_DIR} \
    +login anonymous \
    +app_update ${GAME_STEAMID} validate \
    +quit

RUN mkdir ${HOMEDIR}/profile

COPY . .
CMD [ "/bin/bash", "./entry.sh" ]

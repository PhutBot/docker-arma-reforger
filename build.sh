#!/bin/bash

read -r -d '' HELP_MSG << EOF
build.sh <args> [name]
    -v|--version <version>      * application version
    -h|--help                   display the help msg
    -p|--publish <url>          publish to <url>
    --is-latest                 also tags as latest
    --skip-build                skip build phase
EOF

require_arg() {
    NAME=$1
    MSG=$2
    echo "$NAME=${!NAME}"
    if [[ -z "${!NAME}" ]]; then
        if [[ -z "$MSG" ]]; then
            echo "Error: $MSG"
        else
           echo "Error: missing required arg [$NAME]"
        fi

        echo "$HELP_MSG"
        exit 1
    fi
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      NEED_HELP=1
      shift # past argument
      ;;
    -v|--version)
      VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--publish)
      PUBLISH=1
      REPO="$2"
      shift # past argument
      shift # past value
      ;;
    --run)
      RUN=1
      shift # past argument
      RUN_ARGS=$*
      break
      ;;
    --latest)
      IS_LATEST=1
      shift # past argument
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ ! -z "$NEED_HELP" ]]; then
    echo "$HELP_MSG"
    exit 0
fi

TAG_NAME=$1
require_arg TAG_NAME
require_arg VERSION "expected version number (--version <VERSION>)"
if [[ ! -z "$PUBLISH" ]]; then
    require_arg REPO "expected repo url (--publish <REPO>)"
fi

TAG=${TAG_NAME}:${VERSION}

if [[ -z "$SKIP_BUILD" ]]; then
    docker build . -t ${TAG}
fi

if [[ ! -z "$IS_LATEST" ]]; then
    docker tag ${TAG} ${TAG_NAME}:latest
fi

if [[ ! -z "$RUN" ]]; then
    docker run --rm -it $RUN_ARGS $TAG
    exit 0
fi

if [[ ! -z "${PUBLISH}" ]]; then
    docker tag ${TAG} ${REPO}/${TAG}
    docker push ${REPO}/${TAG}

   if [[ ! -z "$IS_LATEST" ]]; then
       docker tag ${TAG} ${REPO}/${TAG_NAME}:latest
       docker push ${REPO}/${TAG_NAME}:latest
   fi
fi

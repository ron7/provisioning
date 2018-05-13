#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -u|--user)
    USER="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

USER="${USER}"
DOMAIN="${DOMAIN}"
PUBLIC_HTML="/home/${USER}/www/${DOMAIN}/public_html"
PUBLIC_HTML_ESCAPED="\/home\/${USER}\/www\/${DOMAIN}\/public_html"

source ./create_user.sh

source ./create_domain.sh

source ./create_database.sh
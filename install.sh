#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# install needed packages with apt-get
source ./scripts/install/packages.sh

# compile nginx with pagespeed module
source ./scripts/install/nginx.sh




#!/usr/bin/env bash

PHP_VERSION="7.2"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# install needed packages with apt-get
source packages.sh

# compile nginx with pagespeed module
source nginx.sh




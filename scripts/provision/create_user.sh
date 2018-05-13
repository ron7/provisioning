#!/usr/bin/env bash

if [ ! $( getent passwd ${USER} ) ]; then
    groupadd ${USER}
    useradd -s /bin/false -d /home/${USER} -m -g ${USER} ${USER}

    chown -R ${USER}.${USER} /home/${USER}/.
fi

#!/bin/sh

# TODO: Later we can convert echo message into build status message

I_AM_ROOT=false

if [ `whoami` = "root" ]; then
    I_AM_ROOT=true
fi

smart_run () {
    if ! $I_AM_ROOT; then
        sudo $@
    else
        $@
    fi
}

# Create hab cache
while ! [ -d /opt/sd/hab ]
do
    sleep 1
done

smart_run mkdir -p /hab/pkgs/core  || echo 'Failed to create /hab/pkgs/core'
smart_run ln -s /opt/sd/hab/pkgs/core/* /hab/pkgs/core || echo 'Failed to symlink hab cache'

# Create workspace and log file
smart_run mkdir -p /sd || echo 'Failed to create /sd'
smart_run mkfifo -m 666 /sd/emitter || echo 'Failed to create /sd/emitter'

# Make sure everything is ready
while ! [ -p /sd/emitter ] || ! [ -f /opt/sd/launch ]
do
    sleep 1
done
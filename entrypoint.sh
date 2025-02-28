#!/bin/bash

# The entrypoint for this docker container. This script is responsible for
# configuring Tailscale within this container, and then starting the application.

echo "Starting Demo"

# Starting Tailscaled
./tailscaled \
    --state=$HOME/tailscale-storage/tailscale.state \
    --tun=userspace-networking \
    --socket=$HOME/tailscale-storage/tailscale.sock &

echo "Started Tailscaled"

# Authenticate
until ./tailscale --socket=$HOME/tailscale-storage/tailscale.sock \
    up \
    --authkey=$TAILSCALE_KEY --advertise-exit-node
do 
    echo "Waiting for Tailscale Authentication"
    sleep 5
done

echo "Authenticated with Tailscale"

# Run the application.
# Using 'exec' here should forward SIGINT & SIGTERM to program for cleanup.

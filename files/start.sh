#!/bin/sh
set -euo pipefail


# Configure server port and client keep-alive
SERVER_PORT="51820"
CLIENT_KEEP_ALIVE="20"


# Create config
function server_config() {
    # Print status
    echo "*> Configuring server..."

    # Test for network config
    if test -z "${SERVER:-}"; then
        echo "!> Missing required environment variable \$SERVER"
        exit 1
    fi

    # Create config with appropriate permissions
    touch "/etc/wg0.conf"
    chown root:root "/etc/wg0.conf"
    chmod u=rwX,g=,o= "/etc/wg0.conf"

    # Parse JSON
    SERVER_KEY=`echo "$SERVER" | jq -r ".secretKey"`
    SERVER_SUBNET=`echo "$SERVER" | jq -r ".address"`

    # Create config
    export SERVER_SUBNET
    export SERVER_KEY
    export SERVER_PORT
    cat "/etc/wg0.conf.server-template" | envsubst >> "/etc/wg0.conf"

    # Print server info
    SERVER_PUBKEY=`echo "$SERVER_KEY" | wg pubkey`
    echo "*> Server has been configured:"
    echo "    Address = $SERVER_SUBNET"
    echo "    ListenPort = $SERVER_PORT"
    echo "    PublicKey = $SERVER_PUBKEY"
    echo
}


# Client config
function client_config() {
    # Print status
    echo "*> Configuring clients..."

    # Test for clients 
    if test -z "${CLIENTS:-}"; then
        echo "!> Missing required environment variable \$CLIENTS"
        exit 1
    fi

    # Configure clients
    echo "$CLIENTS" | jq -c ".[]" | while read CLIENT; do
        # Parse JSON
        CLIENT_NAME=`echo "$CLIENT" | jq -r ".name"`
        CLIENT_PUBKEY=`echo "$CLIENT" | jq -r ".publicKey"`
        CLIENT_PSK=`echo "$CLIENT" | jq -r ".presharedKey"`
        CLIENT_SUBNET=`echo "$CLIENT" | jq -r ".address"`

        # Append client config
        export CLIENT_NAME
        export CLIENT_PUBKEY
        export CLIENT_SUBNET
        export CLIENT_PSK
        export CLIENT_KEEP_ALIVE
        cat "/etc/wg0.conf.client-template" | envsubst >> "/etc/wg0.conf"

        # Print client info
        echo "*> Client has been configured:"
        echo "    # $CLIENT_NAME"
        echo "    PublicKey = $CLIENT_PUBKEY"
        echo "    AllowedIPs = $CLIENT_SUBNET"
        echo "    PersistentKeepalive = $CLIENT_KEEP_ALIVE"
        echo
    done
}


# Starting server
function start_server() {
    # Print status
    echo "*> Starting server..."

    # Start server
    wg-quick up "/etc/wg0.conf" 2>&1 | sed "s/^/    /"
    echo

    # Runloop to print status
    while sleep 5; do
        # Clear screen and print info
        echo "*> Server is running:"
        wg show wg0 | sed "s/^/    /"
        echo
    done
}


# Build config and start server
server_config
client_config
start_server

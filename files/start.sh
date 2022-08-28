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
    if test -z "${SERVER_SUBNET:-}"; then
        echo "!> Missing required environment variable \$SERVER_SUBNET"
        exit 1
    fi

    # Test for required server secrets
    if test -z "${SERVER_KEY:-}"; then
        echo "!> Missing required environment variable \$SERVER_KEY"
        exit 1
    fi
    if test -z "${SERVER_PSK:-}"; then
        echo "!> Missing required environment variable \$SERVER_PSK"
        exit 1
    fi

    # Fix permissions
    touch "/etc/wg0.conf"
    chown root:root "/etc/wg0.conf"
    chmod u=rwX,g=,o= "/etc/wg0.conf"

    # Create config
    export SERVER_SUBNET
    export SERVER_PORT
    export SERVER_KEY
    export SERVER_PSK
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

    # Test for network config
    if test -z "${SERVER_SUBNET:-}"; then
        echo "!> Missing required environment variable \$SERVER_SUBNET"
        exit 1
    fi

    # Test for required clients
    if test -z "${CLIENTS:-}"; then
        echo "!> Missing required environment variable \$CLIENTS"
        exit 1
    fi

    # Configure clients
    echo "$CLIENTS" | while read CLIENT; do
        # Process if line is not empty
        if test -n "$CLIENT"; then
            # Parse client config
            CLIENT_PUBKEY=`echo "$CLIENT" | cut -d" " -f1`
            CLIENT_SUBNET=`echo "$CLIENT" | cut -d" " -f2`
            CLIENT_COMMENT=`echo "$CLIENT" | cut -d" " -f3-`

            # Append client config
            export CLIENT_PUBKEY
            export CLIENT_SUBNET
            export CLIENT_COMMENT
            export CLIENT_KEEP_ALIVE
            cat "/etc/wg0.conf.client-template" | envsubst >> "/etc/wg0.conf"

            # Print client info
            echo "*> Client has been configured:"
            echo "    # $CLIENT_COMMENT"
            echo "    PublicKey = $CLIENT_PUBKEY"
            echo "    AllowedIPs = $CLIENT_SUBNET"
            echo "    PersistentKeepalive = $CLIENT_KEEP_ALIVE"
            echo
        fi
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

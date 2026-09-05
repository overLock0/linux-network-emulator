#!/usr/bin/env bash
#
# Network Infrastructure Emulator using Linux Network Namespaces
# Features: Isolated namespaces, routing, NAT (iptables), and traffic control (tc)

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)" 1>&2
   exit 1
fi

log "1. Creating network namespaces (client-ns, router-ns, server-ns)..."
ip netns add client-ns
ip netns add router-ns
ip netns add server-ns

log "2. Creating veth pairs..."
# Pair between Client and Router
ip link add veth-cli type veth peer name veth-rtr1
ip link set veth-cli netns client-ns
ip link set veth-rtr1 netns router-ns

# Pair between Router and Server
ip link add veth-rtr2 type veth peer name veth-srv
ip link set veth-rtr2 netns router-ns
ip link set veth-srv netns server-ns

log "3. Configuring IP addresses..."
# Subnet 1: 192.168.10.0/24 (Client <-> Router)
ip -n client-ns addr add 192.168.10.2/24 dev veth-cli
ip -n router-ns addr add 192.168.10.1/24 dev veth-rtr1

# Subnet 2: 10.0.0.0/24 (Router <-> Server)
ip -n router-ns addr add 10.0.0.1/24 dev veth-rtr2
ip -n server-ns addr add 10.0.0.2/24 dev veth-srv

log "4. Bringing interfaces UP..."
ip -n client-ns link set dev lo up
ip -n client-ns link set dev veth-cli up

ip -n router-ns link set dev lo up
ip -n router-ns link set dev veth-rtr1 up
ip -n router-ns link set dev veth-rtr2 up

ip -n server-ns link set dev lo up
ip -n server-ns link set dev veth-srv up

log "5. Enabling IP Forwarding on Router..."
ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1 > /dev/null

log "6. Setting up default routes..."
ip -n client-ns route add default via 192.168.10.1
ip -n server-ns route add default via 10.0.0.1

log "7. Configuring NAT (MASQUERADE) on Router..."
ip netns exec router-ns iptables -t nat -A POSTROUTING -o veth-rtr2 -j MASQUERADE

log "8. Emulating network impairments via Traffic Control (tc)..."
# Adding 50ms latency (+/- 10ms jitter) and 2% packet loss on client egress
ip netns exec client-ns tc qdisc add dev veth-cli root netem delay 50ms 10ms loss 2%

log "Network topology setup completed successfully!"

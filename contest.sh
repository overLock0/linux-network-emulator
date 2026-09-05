#!/usr/bin/env bash
#
# Connectivity and latency verification script

set -euo pipefail

CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Testing Ping from Client (192.168.10.2) to Server (10.0.0.2) ===${NC}"
ip netns exec client-ns ping -c 5 10.0.0.2

echo -e "\n${CYAN}=== Testing Route Trace from Client ===${NC}"
ip netns exec client-ns traceroute -n 10.0.0.2 || true

echo -e "\n${CYAN}=== Active IPTables Rules on Router ===${NC}"
ip netns exec router-ns iptables -t nat -L -v -n


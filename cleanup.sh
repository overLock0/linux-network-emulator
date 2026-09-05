#!/usr/bin/env bash
#
# Tear down created network namespaces

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)" 1>&2
   exit 1
fi

echo "Cleaning up network namespaces..."
ip netns del client-ns 2>/dev/null || true
ip netns del router-ns 2>/dev/null || true
ip netns del server-ns 2>/dev/null || true

echo "Cleanup complete."

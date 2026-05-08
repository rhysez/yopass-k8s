#!/bin/bash

set -e

echo "Deleting kind cluster..."

kind delete cluster

echo "Cleanup complete."
#!/bin/bash

set -e

echo "Starting load test..."

hey -n 10000 -c 200 http://yopass.radioco.local
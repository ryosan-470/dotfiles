#!/bin/bash
#
# This script is pip installer
PIP_URL="https://bootstrap.pypa.io/get-pip.py"

echo "Install pip"
cd /tmp/
curl -L ${PIP_URL} | python3
echo "Finished installation."
exit 0

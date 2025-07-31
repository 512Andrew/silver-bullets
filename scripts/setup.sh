#!/bin/bash

# Setup script for Ubuntu modpack
sudo apt update && sudo apt install -y dkms build-essential curl
# setup.sh addition
echo "Installing Cinnamon desktop environment..."
apt update && apt install cinnamon-desktop-environment lightdm -y

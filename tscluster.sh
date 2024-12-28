#!/bin/bash

# Tool name
tool_name="tscluster"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Install script
install() {
  install_dir="/usr/local/bin"
  if ! sudo mkdir -p "$install_dir"; then
    error "Error creating directory $install_dir. Ensure you have sudo privileges."
  fi
  install_path="$install_dir/$tool_name"
  if ! sudo cp "$0" "$install_path" && ! sudo chmod +x "$install_path"; then
      error "Error installing $tool_name. Ensure you have sudo privileges."
  fi
  log "$tool_name installed to $install_path."
}

# Uninstall script
uninstall() {
  uninstall_path="/usr/local/bin/$tool_name"
  if [[ -f "$uninstall_path" ]]; then
    if ! sudo rm "$uninstall_path"; then
      error "Error uninstalling $tool_name. Ensure you have sudo privileges."
    fi
    log "$tool_name successfully uninstalled."
  else
    warn "$tool_name is not installed in /usr/local/bin."
  fi
}

# Function to install Tailscale
install_tailscale() {
    log "Updating package list..."
    if ! sudo apt update; then
        error "Failed to update package list. Ensure you have sudo privileges."
    fi

    log "Installing Tailscale..."
    if ! sudo curl -fsSL https://tailscale.com/install.sh | sudo bash; then
        error "Failed to install Tailscale. Ensure you have sudo privileges."
    fi

    log "Stopping Tailscale service (if running)..."
    sudo systemctl stop tailscaled

    log "Enabling and starting the Tailscale service..."
    if ! sudo systemctl enable tailscaled || ! sudo systemctl start tailscaled; then
        error "Failed to enable/start Tailscale service. Ensure you have sudo privileges."
    fi

    log "Checking Tailscale status..."
    status=$(sudo systemctl status tailscaled | grep 'Active: ')
    log "Tailscale daemon is: ${status##*Active: }"
}

# Set up node
setup_node() {
    local node_type="$1"
    local flags=""
    
    [[ "$node_type" == "managed" ]] && flags="--ssh"
    
    log "Setting up a ${node_type} node..."
    log "Follow the printed URL and authenticate to Tailscale if you are not logged in yet."
    if ! sudo tailscale up $flags; then
        error "Failed to start Tailscale in ${node_type} node mode. Check your Tailscale configuration."
    fi
    log "${node_type^} node setup complete."
}


# Main execution
case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        # Interactive menu
        echo
        echo -e "${GREEN}Welcome to the Tailscale cluster tool!${NC}"
        echo
        echo "Run this script on each managed node, then run it on the control node."
        echo

        while true; do
            echo "What would you like to do?"
            echo "1. Set a managed node"
            echo "2. Set a control node"
            echo "3. Exit"
            read -p "Please enter your choice [1-3]: " choice

            case $choice in
                1)
                    install_tailscale
                    setup_node "managed"
                    log "Setup for managed node for $tool_name is complete. Exiting..."
                    break
                    ;;
                2)
                    install_tailscale
                    setup_node "control"
                    log "Setup for control node for $tool_name is complete. Exiting..."
                    break
                    ;;
                3)
                    log "Exiting..."
                    break
                    ;;
                *)
                    warn "Invalid choice. Please enter a number between 1 and 3."
                    ;;
            esac
        done
        ;;
esac
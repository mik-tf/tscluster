#!/bin/bash

# Function to install Tailscale
install_tailscale() {
    # Update package list
    echo "Updating package list..."
    sudo apt update
    echo "Upgrading packages..."
    sudo apt upgrade -y

    # Install Tailscale
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sudo sh

    # Start Tailscale service
    echo "Enabling and starting the Tailscale service..."
    sudo systemctl enable tailscaled
    sudo systemctl start tailscaled
}

# Function to set managed node
set_managed_node() {
    # Authenticate the managed node with Tailscale
    echo "Add managed node with SSH access to Tailscale cluster..."
    echo "Please authenticate the node (follow the printed URL)..."
    sudo tailscale up --ssh
    echo "Tailscale managed node setup complete."
}

# Function to set control node
set_control_node() {
    echo "Setting up a control node..."
    echo "Please authenticate the control node (follow the printed URL)..."
    sudo tailscale up
    echo "Control node setup complete."
}

# Welcome message
echo "Welcome to the Tailscale 1-control node, many-managed nodes cluster tool."
echo
echo "Run this script on each managed node, then run it on the control node."
echo

# Main menu
while true; do
    echo "What would you like to do?"
    echo "1. Set a managed node"
    echo "2. Set a control node"
    echo "3. Exit"
    read -p "Please enter your choice [1-3]: " choice

    case $choice in
        1)
            install_tailscale
            set_managed_node
            echo "Setup for managed node is complete. Exiting..."
            break  # Exit the loop after completing managed node setup
            ;;
        2)
            install_tailscale
            set_control_node
            echo "Setup for control node is complete. Exiting..."
            break  # Exit the loop after completing control node setup
            ;;
        3)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 3."
            ;;
    esac
done
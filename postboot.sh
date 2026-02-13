#!/bin/bash
exec > /tmp/postboot_debug.log 2>&1  # Redirect STDOUT and STDERR to a file
set -x                               # Print each command before executing it

# 1. Update and Install Dependencies
sudo apt update
sudo apt upgrade -y
sudo apt install -y build-essential git m4 scons zlib1g zlib1g-dev \
    libprotobuf-dev protobuf-compiler libprotoc-dev libgoogle-perftools-dev \
    python3-dev libboost-all-dev pkg-config python3-tk clang-format-15 

# 2. Identify the CloudLab User
USERCLOUDLAB=$(geni-get user_urn | awk -F'+' '{print $NF}')
USER_HOME="/users/$USERCLOUDLAB"

# 3. Copy Configuration (Ensure the source file exists)
if [ -f "/local/repository/.tmux.conf" ]; then
    cp /local/repository/.tmux.conf "$USER_HOME/.tmux.conf"
    chown "$USERCLOUDLAB":"$USERCLOUDLAB" "$USER_HOME/.tmux.conf"
fi

# 4. Safely Append Environment Variables
# Using a check to avoid adding these lines every time the node reboots
BASHRC="$USER_HOME/.bashrc"

add_to_bashrc() {
    local line="$1"
    grep -qF "$line" "$BASHRC" || echo "$line" >> "$BASHRC"
}

add_to_bashrc "export GIT_ROOT=/proj/progstack-PG0/marco/gem5-dpdk-setup"
add_to_bashrc "export RTE_SDK=\$GIT_ROOT/buildroot/package/dpdk/dpdk-source"

# 5. Fix Permissions
# Ensure the user owns their bashrc so they can edit it later
chown "$USERCLOUDLAB":"$USERCLOUDLAB" "$BASHRC"
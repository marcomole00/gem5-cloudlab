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
# 2. Identify the CloudLab User and Group
USERCLOUDLAB=$(geni-get user_urn | awk -F'+' '{print $NF}')
USER_HOME="/users/$USERCLOUDLAB"
# Detect the group dynamically
USER_GROUP=$(id -gn "$USERCLOUDLAB")

# 3. Copy Configuration (Run as the user to bypass root-squash)
if [ -f "/local/repository/.tmux.conf" ]; then
    sudo -u "$USERCLOUDLAB" cp /local/repository/.tmux.conf "$USER_HOME/.tmux.conf"
fi

# 4. Safely Append Environment Variables
BASHRC="$USER_HOME/.bashrc"

add_to_bashrc() {
    local line="$1"
    # We use sudo -u to run the grep and the append as the user
    sudo -u "$USERCLOUDLAB" bash -c "grep -qF '$line' '$BASHRC' || echo '$line' >> '$BASHRC'"
}

add_to_bashrc "export GIT_ROOT=/proj/progstack-PG0/marco/gem5-dpdk-setup"
add_to_bashrc "export RTE_SDK=\$GIT_ROOT/buildroot/package/dpdk/dpdk-source"

# 5. Fix Permissions (Use the dynamic group we found)
# Note: Since we created/copied files as the user, this is technically 
# redundant now, but it's good insurance.
sudo chown "$USERCLOUDLAB:$USER_GROUP" "$USER_HOME/.tmux.conf" "$BASHRC
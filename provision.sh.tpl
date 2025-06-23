#!/bin/bash
set -e

echo "[*] Temporarily disabling SELinux to avoid passt installation issues"
# Temporarily set SELinux to permissive mode
sudo setenforce 0 || true
# Backup and modify SELinux config
sudo cp /etc/selinux/config /etc/selinux/config.backup
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

echo "[*] System update and desktop install"
sudo dnf -y update
sudo dnf install -y  wget nano tar unzip git make gcc gcc-c++ kernel-devel net-tools iproute rpm-build
sudo dnf groupinstall -y "Server with GUI"
sudo dnf install -y tigervnc-server

echo "[*] VNC setup"
mkdir -p /home/rocky/.vnc
echo "${vnc_password}" | vncpasswd -f > /home/rocky/.vnc/passwd
sudo chmod 600 /home/rocky/.vnc/passwd
sudo chown -R rocky:rocky /home/rocky/.vnc

cat <<EOF > /home/rocky/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec gnome-session &
EOF
sudo chmod +x /home/rocky/.vnc/xstartup
sudo chown rocky:rocky /home/rocky/.vnc/xstartup

sudo cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:1.service
sudo sed -i 's/<USER>/rocky/' /etc/systemd/system/vncserver@:1.service
echo ":1=rocky" | sudo tee /etc/tigervnc/vncserver.users
sudo systemctl enable vncserver@:1
sudo systemctl daemon-reload
sudo systemctl start vncserver@:1

cat << 'EOF' | bash
set -e 
echo "[*] Mounting EFS"

# Clone and build EFS utils
git clone https://github.com/aws/efs-utils.git
cd efs-utils
git checkout v1.35.0
make rpm
sudo dnf install -y build/amazon-efs-utils-*.rpm

# Return to original directory
cd ..

# Create EFS mount point
sudo mkdir -p /mnt/efs

# Mount EFS filesystem
echo "Mounting EFS filesystem ${efs_id}..."
sudo mount -t efs ${efs_id}:/ /mnt/efs

# Set proper permissions for write access
sudo chown rocky:rocky /mnt/efs
sudo chmod 755 /mnt/efs

# Add to fstab for persistent mounting
echo "${efs_id}.efs.us-west-2.amazonaws.com:/ /mnt/efs efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

echo "[*] EFS utils installation and mounting completed"
EOF

cat << 'EOF' | bash
set -e

echo "[*] Setting up S3 mounts"

# Check if required variables are set
if [[ -z "${access_key_id}" || -z "${secret_access_key}" || -z "${efs_id}" || -z "${s3_bucket}" ]]; then
    echo "Error: Required variables not set (access_key_id, secret_access_key, efs_id, s3_bucket)"
    exit 1
fi

# Install s3fs-fuse
sudo dnf install epel-release -y
sudo dnf install -y s3fs-fuse

# Create S3 credentials file
echo "[*] Creating S3 credentials file"
echo "${access_key_id}:${secret_access_key}" > ~/.passwd-s3fs
chmod 600 ~/.passwd-s3fs
echo "[*] S3 credentials file created"

# Create mount points
sudo mkdir -p /mnt/s3

# Mount S3 bucket
echo "Mounting S3 bucket..."
sudo s3fs ${s3_bucket} /mnt/s3 -o passwd_file=$HOME/.passwd-s3fs,allow_other

# Add to fstab for persistent mounting
echo "s3fs#${s3_bucket} /mnt/s3 fuse _netdev,allow_other,passwd_file=$HOME/.passwd-s3fs 0 0" | sudo tee -a /etc/fstab

echo "[*] Mount setup completed successfully"

echo "[*] Installing VS Code"
# Add Microsoft's GPG key and repository
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
# Install VS Code (skip check-update as it can return exit code 100)
sudo dnf install -y code

# echo "[*] Git Artifactory setup"
# git config --system url."https://my-artifactory.example.com/artifactory/".insteadOf "https://github.com/"

echo "[*] Sublime Text install"
# FIX: Add sudo for rpm command
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install -y sublime-text


echo "[*] Installing PyCharm Community"

# Download PyCharm Community (free version)
curl -L -o /tmp/pycharm.tar.gz "https://download.jetbrains.com/python/pycharm-community-2024.3.1.1.tar.gz"

# Extract to /opt
sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/

# Find the extracted directory
PYCHARM_DIR=$(find /opt -type d -name "pycharm-community-*" | head -1)
echo "PyCharm installed in: $PYCHARM_DIR"
sudo rm -f /usr/local/bin/pycharm
echo "Creating symlink from $PYCHARM_DIR/bin/pycharm.sh to /usr/local/bin/pycharm"
sudo ln -sf "$PYCHARM_DIR/bin/pycharm.sh" /usr/local/bin/pycharm

# Add verification
echo "Verifying symlink:"
ls -la /usr/local/bin/pycharm
readlink /usr/local/bin/pycharm

# Set proper ownership
sudo chown -R rocky:rocky "$PYCHARM_DIR"
sudo mkdir -p /home/rocky/Desktop && sudo chown rocky:rocky /home/rocky/Desktop

sudo mkdir -p /usr/share/applications
sudo tee /usr/share/applications/pycharm-community.desktop > /dev/null << EOF
[Desktop Entry]
Name=PyCharm Community
Comment=Python IDE for Professional Developers
Exec=$PYCHARM_DIR/bin/pycharm.sh
Icon=$PYCHARM_DIR/bin/pycharm.png
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=jetbrains-pycharm-ce
EOF

# Also create desktop shortcut
sudo mkdir -p /home/rocky/Desktop && sudo chown rocky:rocky /home/rocky/Desktop
sudo tee /home/rocky/Desktop/PyCharm.desktop > /dev/null << EOF
[Desktop Entry]
Name=PyCharm Community
Comment=Python IDE for Professional Developers
Exec=$PYCHARM_DIR/bin/pycharm.sh
Icon=$PYCHARM_DIR/bin/pycharm.png
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=jetbrains-pycharm-ce
EOF

# Set proper permissions
sudo chmod 644 /usr/share/applications/pycharm-community.desktop
sudo chown rocky:rocky /home/rocky/Desktop/PyCharm.desktop
sudo chmod +x /home/rocky/Desktop/PyCharm.desktop

# Update desktop database so the application appears immediately
sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true

sudo rm -f /tmp/pycharm.tar.gz

echo "PyCharm installed successfully!"
echo "You can launch it from the desktop shortcut"
echo "Or run: $PYCHARM_DIR/bin/pycharm.sh"

echo "[*] Conda & Jupyter Setup"
curl -o /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash /tmp/miniconda.sh -b -p /home/rocky/miniconda
echo 'export PATH="/home/rocky/miniconda/bin:$PATH"' >> /home/rocky/.bashrc

# Fix ownership of miniconda
sudo chown -R rocky:rocky /home/rocky/miniconda

echo "[*] Installing Jupyter + plugins"
# Install Jupyter directly, then fix ownership
/home/rocky/miniconda/bin/conda install -y jupyterlab ipywidgets jupytext

mkdir -p /home/rocky/.jupyter

sudo tee /home/rocky/.jupyter/jupyter_server_config.json > /dev/null <<EOF
{
  "ServerApp": {
    "ip": "0.0.0.0",
    "open_browser": false,
    "port": 8888,
    "allow_remote_access": true,
    "password_required": false,
    "token": ""
  }
}
EOF

# Fix all ownership after installation
sudo chown -R rocky:rocky /home/rocky/miniconda
sudo chown -R rocky:rocky /home/rocky/.jupyter

echo "[*] Creating Jupyter Lab systemd service"
# First, verify the jupyter executable exists and is executable
if [ ! -x "/home/rocky/miniconda/bin/jupyter" ]; then
    echo "ERROR: Jupyter executable not found or not executable at /home/rocky/miniconda/bin/jupyter"
    ls -la /home/rocky/miniconda/bin/jupyter || echo "File does not exist"
    exit 1
fi

# Create a wrapper script to ensure proper environment
sudo tee /usr/local/bin/jupyter-wrapper.sh > /dev/null <<'EOF'
#!/bin/bash
export HOME=/home/rocky
export USER=rocky
export PATH=/home/rocky/miniconda/bin:$PATH
cd /home/rocky
exec /home/rocky/miniconda/bin/jupyter lab --config=/home/rocky/.jupyter/jupyter_server_config.json
EOF

sudo chmod +x /usr/local/bin/jupyter-wrapper.sh

sudo tee /etc/systemd/system/jupyter.service > /dev/null <<EOF
[Unit]
Description=Jupyter Lab Server
After=network.target

[Service]
Type=simple
User=rocky
Group=rocky
WorkingDirectory=/home/rocky
ExecStart=/usr/local/bin/jupyter-wrapper.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Enabling and starting Jupyter Lab service"
sudo systemctl daemon-reload
sudo systemctl enable jupyter.service
sudo systemctl start jupyter.service

# Wait for Jupyter to start and be ready
echo "Waiting for Jupyter Lab to start..."
timeout=60
elapsed=0
while ! (ss -tulpn 2>/dev/null | grep -q ":8888 " || netstat -tulpn 2>/dev/null | grep -q ":8888 "); do
    if [ $elapsed -ge $timeout ]; then
        echo "Timeout waiting for Jupyter Lab to start"
        echo "Jupyter log contents:"
        cat /tmp/jupyter.log
        echo "Port check results:"
        ss -tulpn 2>/dev/null | grep 8888 || echo "No port 8888 found with ss"
        netstat -tulpn 2>/dev/null | grep 8888 || echo "No port 8888 found with netstat"  
        exit 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
    echo "Waiting... ($elapsed seconds)"
done

echo "Jupyter Lab is now running on port 8888"

echo "[*] Setting up firewall rules for VNC and Jupyter"

# Check if firewalld is installed and stop it if it is
if systemctl list-unit-files | grep -q firewalld.service; then
    echo "firewalld is present. Stopping it..."
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
else
    echo "firewalld is not installed. Skipping firewall configuration."
fi

echo "[*] Re-enabling SELinux after installation"
# Restore SELinux to enforcing mode
sudo cp /etc/selinux/config.backup /etc/selinux/config
# Note: SELinux will be enforcing on next boot, but we keep it permissive for the current session
# to avoid any issues during the remainder of the build process

echo "[*] Setup completed successfully"
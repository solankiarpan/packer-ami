#!/bin/bash
set -e

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
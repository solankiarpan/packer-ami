#!/bin/bash
set -e

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
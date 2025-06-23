#!/bin/bash
set -e

echo "[*] VNC setup"

# Install AWS CLI if not already installed
sudo dnf install -y awscli

# Retrieve VNC password from SSM Parameter Store
echo "[*] Retrieving VNC password from SSM Parameter Store"
VNC_PASSWORD=$(aws ssm get-parameter --name "${vnc_password_parameter}" --with-decryption --region ${aws_region} --query 'Parameter.Value' --output text)

if [[ -z "$VNC_PASSWORD" ]]; then
    echo "Error: Failed to retrieve VNC password from SSM Parameter Store"
    exit 1
fi

echo "[*] VNC password retrieved successfully from SSM"

mkdir -p /home/rocky/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /home/rocky/.vnc/passwd
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

# Clear the password variable for security
unset VNC_PASSWORD

echo "[*] VNC setup completed successfully"
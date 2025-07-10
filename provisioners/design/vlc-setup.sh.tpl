#!/bin/bash
set -e
echo "[*] Installing VLC Media Player"
sudo dnf install -y snapd
sudo systemctl enable --now snapd.socket

# Create snap symlink only if it doesn't exist
if [ ! -L /snap ]; then
   sudo ln -s /var/lib/snapd/snap /snap
fi

# Wait for snapd to seed
echo "Waiting for snapd to initialize..."
timeout=300
elapsed=0
while ! sudo snap wait system seed.loaded 2>/dev/null; do
   if [ $elapsed -ge $timeout ]; then
       echo "Timeout waiting for snapd to seed"
       exit 1
   fi
   sleep 5
   elapsed=$((elapsed + 5))
done

sudo snap install vlc 

# Add snap bin to PATH
echo 'export PATH=/snap/bin:$PATH' >> /home/rocky/.bashrc
export PATH=/snap/bin:$PATH

# Create application menu entry
sudo tee /usr/share/applications/vlc.desktop > /dev/null << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=VLC Media Player
Comment=VLC Media Player
Exec=/snap/bin/vlc %U
Icon=/snap/vlc/current/usr/share/icons/hicolor/256x256/apps/vlc.png
Terminal=false
Categories=AudioVideo;Player;Recorder;
MimeType=video/dv;video/mpeg;video/x-mpeg;video/msvideo;video/quicktime;video/x-anim;video/x-avi;video/x-ms-asf;video/x-ms-wmv;video/x-msvideo;video/x-nsv;video/x-flc;video/x-fli;application/ogg;application/x-ogg;application/x-matroska;audio/x-mp3;audio/x-mpeg;audio/mpeg;audio/x-wav;audio/x-mpegurl;audio/x-scpls;audio/x-m4a;audio/x-ms-asf;audio/x-ms-asx;audio/x-ms-wax;application/vnd.rn-realmedia;audio/x-real-audio;audio/x-pn-realaudio;application/x-flac;audio/x-flac;application/x-shockwave-flash;audio/ac3;audio/x-shorten;audio/x-wavpack;video/mp4;video/3gpp;video/x-matroska;audio/ogg;audio/vorbis;
StartupNotify=true
EOF

# Update desktop database
sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true

echo "[*] VLC Media Player installation completed successfully"
echo "[*] VLC should now appear in Applications menu"
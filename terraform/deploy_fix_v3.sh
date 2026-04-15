#!/bin/bash
# DEPLOY FIX V3 - HEADER PASS-THROUGH
set -e

# 1. Update app.py with Response object fix
cat > /home/azureuser/retailvault/app.py << 'EOF'
import os, sys
from flask import Flask, render_template, request, send_file, flash, redirect, url_for, make_response, Response
from werkzeug.utils import secure_filename
import io
from crypto_utils import encrypt_data, decrypt_data

app = Flask(__name__)
app.secret_key = os.urandom(24)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/encrypt', methods=['POST'])
def encrypt():
    if 'file' not in request.files:
        flash('No file part', 'danger')
        return redirect(url_for('index'))
    file = request.files['file']
    password = request.form.get('encryption_password')
    if file.filename == '' or not password:
        flash('File and encryption password required.', 'danger')
        return redirect(url_for('index'))
    
    data = file.read()
    try:
        encrypted_data = encrypt_data(data, password)
        
        base_name = secure_filename(file.filename)
        if not base_name:
            base_name = "vault_file"
        enc_filename = f"{base_name}.enc"
        
        print(f"ENCRYPT: File {file.filename} -> {enc_filename} ({len(encrypted_data)} bytes)", file=sys.stderr)
        
        # Use direct Response object for maximum header stability
        return Response(
            encrypted_data,
            mimetype='application/octet-stream',
            headers={"Content-Disposition": f"attachment; filename={enc_filename}"}
        )
    except Exception as e:
        print(f"ENCRYPT ERROR: {str(e)}", file=sys.stderr)
        flash(f'Encryption failed: {str(e)}', 'danger')
        return redirect(url_for('index'))

@app.route('/decrypt', methods=['GET', 'POST'])
def decrypt():
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No file provided.', 'danger')
            return redirect(url_for('decrypt'))
        file = request.files['file']
        password = request.form.get('password')
        if file.filename == '' or not password:
            flash('Missing file or password.', 'danger')
            return redirect(url_for('decrypt'))
        try:
            encrypted_data = file.read()
            decrypted_data = decrypt_data(encrypted_data, password)
            
            original_name = secure_filename(file.filename).replace('.enc', '')
            if not original_name or original_name == file.filename:
                original_name = "decrypted_file.dec"
            
            print(f"DECRYPT: File {file.filename} -> {original_name} ({len(decrypted_data)} bytes)", file=sys.stderr)
            
            return Response(
                decrypted_data,
                mimetype='application/octet-stream',
                headers={"Content-Disposition": f"attachment; filename={original_name}"}
            )
        except Exception as e:
            print(f"DECRYPT ERROR: {str(e)}", file=sys.stderr)
            flash('Decryption failed: Wrong password or tampered file.', 'danger')
            return redirect(url_for('decrypt'))
    return render_template('decrypt.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

# 2. Update Nginx Configuration to enforce header pass-through
cat > /tmp/nginx_site << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Explicitly pass Content-Disposition header
        proxy_pass_header Content-Disposition;
        proxy_set_header X-Content-Type-Options nosniff;
        
        # Increase timeouts for larger files
        proxy_read_timeout 120s;
        proxy_connect_timeout 120s;
    }
}
EOF

sudo mv /tmp/nginx_site /etc/nginx/sites-available/default
sudo systemctl restart nginx

# 3. Restart Gunicorn
sudo pkill -f gunicorn || true
cd /home/azureuser/retailvault
nohup gunicorn --timeout 60 --workers 2 --bind 127.0.0.1:5000 app:app > /home/azureuser/retailvault/app.log 2>&1 &

sleep 2
echo "FIX V3 APPLIED: WAF=DETECTION, NGINX=FORWARDING, FLASK=DIRECT_RESPONSE"

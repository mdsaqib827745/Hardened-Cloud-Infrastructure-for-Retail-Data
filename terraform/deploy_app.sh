#!/bin/bash
# Re-apply nginx config safely
cat > /etc/nginx/sites-available/retailvault << 'EOF'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
ln -sf /etc/nginx/sites-available/retailvault /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Create directory
mkdir -p /home/azureuser/retailvault/templates

# Create app.py
cat > /home/azureuser/retailvault/app.py << 'EOF'
import os
from flask import Flask, render_template, request, send_file, flash, redirect, url_for
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
        enc_filename = secure_filename(file.filename) + ".enc"
        return send_file(io.BytesIO(encrypted_data), as_attachment=True, download_name=enc_filename, mimetype='application/octet-stream')
    except Exception as e:
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
            if original_name == file.filename:
                original_name += ".dec"
            return send_file(io.BytesIO(decrypted_data), as_attachment=True, download_name=original_name, mimetype='application/octet-stream')
        except Exception:
            flash('Decryption failed: Wrong password or tampered file.', 'danger')
            return redirect(url_for('decrypt'))
    return render_template('decrypt.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

# Create crypto_utils.py
cat > /home/azureuser/retailvault/crypto_utils.py << 'EOF'
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from argon2.low_level import hash_secret_raw, Type

def derive_key(password: str, salt: bytes) -> bytes:
    return hash_secret_raw(
        secret=password.encode(),
        salt=salt,
        time_cost=3,
        memory_cost=65536,
        parallelism=1,
        hash_len=32,
        type=Type.ID
    )

def encrypt_data(data: bytes, password: str) -> bytes:
    salt = os.urandom(16)
    nonce = os.urandom(12)
    key = derive_key(password, salt)
    aesgcm = AESGCM(key)
    combined_ct_tag = aesgcm.encrypt(nonce, data, None)
    tag = combined_ct_tag[-16:]
    ciphertext = combined_ct_tag[:-16]
    return salt + nonce + tag + ciphertext

def decrypt_data(encrypted_data: bytes, password: str) -> bytes:
    if len(encrypted_data) < 44:
        raise ValueError("Invalid encrypted data format.")
    salt = encrypted_data[:16]
    nonce = encrypted_data[16:28]
    tag = encrypted_data[28:44]
    ciphertext = encrypted_data[44:]
    key = derive_key(password, salt)
    aesgcm = AESGCM(key)
    return aesgcm.decrypt(nonce, ciphertext + tag, None)
EOF

# Create base.html
cat > /home/azureuser/retailvault/templates/base.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RetailVault | Secured by AES-256-GCM</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        :root{--bg-color:#0b0e14;--glass-bg:rgba(23,28,38,0.7);--primary-accent:#3b82f6;--secondary-accent:#10b981;--text-color:#e2e8f0;--border-color:rgba(255,255,255,0.1)}
        body{background-color:var(--bg-color);color:var(--text-color);font-family:'Inter',sans-serif;min-height:100vh;background-image:radial-gradient(circle at 20% 30%,rgba(59,130,246,0.05) 0%,transparent 40%),radial-gradient(circle at 80% 70%,rgba(16,185,129,0.05) 0%,transparent 40%)}
        .glass-card{background:var(--glass-bg);backdrop-filter:blur(12px);border:1px solid var(--border-color);border-radius:16px;box-shadow:0 8px 32px 0 rgba(0,0,0,0.3);padding:24px;transition:transform .3s ease,border-color .3s ease}
        .glass-card:hover{border-color:var(--primary-accent)}
        .navbar{background:rgba(11,14,20,0.8);backdrop-filter:blur(8px);border-bottom:1px solid var(--border-color);padding:1rem 0}
        .navbar-brand{font-weight:700;color:var(--primary-accent)!important;letter-spacing:-.5px}
        .btn-primary{background-color:var(--primary-accent);border:none;padding:10px 24px;border-radius:8px;font-weight:600}
        .btn-primary:hover{background-color:#2563eb;transform:translateY(-1px)}
        .form-control{background-color:rgba(0,0,0,0.2);border:1px solid var(--border-color);color:white;border-radius:8px;padding:12px}
        .form-control:focus{background-color:rgba(0,0,0,0.3);border-color:var(--primary-accent);color:white;box-shadow:none}
        .security-badge{background:rgba(16,185,129,0.1);color:var(--secondary-accent);border:1px solid var(--secondary-accent);padding:4px 12px;border-radius:100px;font-size:.75rem;font-weight:600;text-transform:uppercase}
        .alert{border-radius:12px;border:none}
        .pulse{width:10px;height:10px;border-radius:50%;background:var(--secondary-accent);box-shadow:0 0 0 rgba(16,185,129,0.4);animation:pulse 2s infinite;display:inline-block;vertical-align:middle;margin-right:8px}
        @keyframes pulse{0%{transform:scale(.95);box-shadow:0 0 0 0 rgba(16,185,129,.7)}70%{transform:scale(1);box-shadow:0 0 0 10px rgba(16,185,129,0)}100%{transform:scale(.95);box-shadow:0 0 0 0 rgba(16,185,129,0)}}
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg mb-5"><div class="container">
        <a class="navbar-brand" href="/">RETAILVAULT</a>
        <div class="d-flex align-items-center">
            <span class="pulse"></span><span class="security-badge me-4">WAF: ACTIVE</span>
        </div>
    </div></nav>
    <div class="container">
        {% with messages = get_flashed_messages(with_categories=true) %}{% if messages %}{% for category, message in messages %}<div class="alert alert-{{ category }}">{{ message }}</div>{% endfor %}{% endif %}{% endwith %}
        {% block content %}{% endblock %}
    </div>
    <footer class="mt-5 py-4 text-center text-muted small border-top border-secondary opacity-25">&copy; 2026 RetailVault Security</footer>
</body></html>
EOF

# Create index.html
cat > /home/azureuser/retailvault/templates/index.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<div class="row justify-content-center">
<div class="col-lg-6"><div class="glass-card mb-4">
<h4 class="mb-4">Secure Encryption</h4>
<p class="text-muted small mb-4">Encrypt files directly and download them safely wrapped in AES-256-GCM.</p>
<form action="/encrypt" method="POST" enctype="multipart/form-data">
<div class="mb-3"><label class="form-label small text-muted">Select Plaintext File</label><input type="file" name="file" class="form-control" required></div>
<div class="mb-4"><label class="form-label small text-muted">Encryption Password</label><input type="password" name="encryption_password" class="form-control" placeholder="Strong Passphrase" required><div class="form-text small opacity-50">Required for decryption. We do not store it.</div></div>
<button type="submit" class="btn btn-primary w-100">Encrypt &amp; Download .enc</button></form>
</div>
<div class="text-center"><a href="/decrypt" class="btn btn-outline-secondary">Go to Decryption Vault</a></div>
</div>
</div>
{% endblock %}
EOF

# Create decrypt.html
cat > /home/azureuser/retailvault/templates/decrypt.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<div class="row justify-content-center"><div class="col-md-6 col-lg-5"><div class="glass-card">
<div class="text-center mb-5"><h3 class="mb-2">Secure Decryption</h3><p class="text-muted small">Recover original content from an encrypted .enc file.</p></div>
<form action="/decrypt" method="POST" enctype="multipart/form-data">
<div class="mb-3"><label class="form-label small text-muted">Upload Encrypted File</label><input type="file" name="file" class="form-control" required></div>
<div class="mb-4"><label class="form-label small text-muted">Decryption Password</label><input type="password" name="password" class="form-control" placeholder="Original Passphrase" required></div>
<button type="submit" class="btn btn-primary w-100">Verify &amp; Decrypt</button></form>
<div class="mt-4 pt-3 border-top border-secondary opacity-25 text-center"><a href="/" class="btn btn-sm btn-link text-muted text-decoration-none">Back to Dashboard</a></div>
</div></div></div>
{% endblock %}
EOF

# Restart gunicorn
pkill -f gunicorn || true
cd /home/azureuser/retailvault
nohup gunicorn --timeout 60 --workers 2 --bind 127.0.0.1:5000 app:app > /home/azureuser/retailvault/app.log 2>&1 &
sleep 2
cat /home/azureuser/retailvault/app.log
echo 'DEPLOYMENT FINISHED SUCCESSFULLY'

#!/bin/bash
# DEPLOY FIX V2
cat > /home/azureuser/retailvault/crypto_utils.py << 'EOF'
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from argon2.low_level import hash_secret_raw, Type

def derive_key(password: str, salt: bytes) -> bytes:
    """Derives a 256-bit key from a password and salt using Argon2id."""
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
    """
    Encrypts bytes using AES-256-GCM and Argon2id.
    Returns: salt (16) + nonce (12) + encrypted_payload (ciphertext + tag)
    """
    salt = os.urandom(16)
    nonce = os.urandom(12)
    key = derive_key(password, salt)
    aesgcm = AESGCM(key)

    # Returns ciphertext + 16-byte tag (standard AES-GCM output in cryptography lib)
    encrypted_payload = aesgcm.encrypt(nonce, data, None)
    
    return salt + nonce + encrypted_payload

def decrypt_data(encrypted_data: bytes, password: str) -> bytes:
    """
    Decrypts bytes using AES-256-GCM and Argon2id.
    The data must be in the format: salt (16) + nonce (12) + encrypted_payload (ciphertext + tag)
    """
    if len(encrypted_data) < 28 + 16: # 16 (salt) + 12 (nonce) + 16 (min tag)
        raise ValueError("Invalid encrypted data format.")

    salt = encrypted_data[:16]
    nonce = encrypted_data[16:28]
    encrypted_payload = encrypted_data[28:]

    key = derive_key(password, salt)
    aesgcm = AESGCM(key)

    # decrypt expects ciphertext + tag
    return aesgcm.decrypt(nonce, encrypted_payload, None)
EOF

cat > /home/azureuser/retailvault/app.py << 'EOF'
import os, sys
from flask import Flask, render_template, request, send_file, flash, redirect, url_for, make_response
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
        
        # Ensure filename is safe, fallback if empty
        base_name = secure_filename(file.filename)
        if not base_name:
            base_name = "vault_file"
        enc_filename = f"{base_name}.enc"
        
        # Log basic info to app.log for visibility via stderr
        print(f"ENCRYPT: File {file.filename} -> {enc_filename} ({len(encrypted_data)} bytes)", file=sys.stderr)
        
        # Prepare the buffer
        buffer = io.BytesIO(encrypted_data)
        buffer.seek(0)
        
        # Explicitly set headers for Nginx/Gunicorn reliability
        response = make_response(send_file(buffer, mimetype='application/octet-stream'))
        response.headers["Content-Disposition"] = f"attachment; filename={enc_filename}"
        return response
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
            
            buffer = io.BytesIO(decrypted_data)
            buffer.seek(0)
            
            response = make_response(send_file(buffer, mimetype='application/octet-stream'))
            response.headers["Content-Disposition"] = f"attachment; filename={original_name}"
            return response
        except Exception as e:
            print(f"DECRYPT ERROR: {str(e)}", file=sys.stderr)
            flash('Decryption failed: Wrong password or tampered file.', 'danger')
            return redirect(url_for('decrypt'))
    return render_template('decrypt.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

# Restart server
pkill -f gunicorn || true
cd /home/azureuser/retailvault
nohup gunicorn --timeout 60 --workers 2 --bind 127.0.0.1:5000 app:app > /home/azureuser/retailvault/app.log 2>&1 &
sleep 2
echo 'FIX V2 APPLIED'

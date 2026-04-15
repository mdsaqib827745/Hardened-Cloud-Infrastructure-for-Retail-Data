import os, sys
from flask import Flask, render_template, request, send_file, flash, redirect, url_for, make_response, Response
from werkzeug.utils import secure_filename
import io
from crypto_utils import encrypt_data, decrypt_data
# Remove auth entirely.

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
        
        # FIX V5: Dual-format Content-Disposition (RFC 8187) and Disable Browser Caching
        return Response(
            encrypted_data,
            mimetype='application/octet-stream',
            headers={
                "Content-Disposition": f"attachment; filename=\"{enc_filename}\"; filename*=UTF-8''{enc_filename}",
                "Cache-Control": "no-cache, no-store, must-revalidate",
                "Pragma": "no-cache",
                "Expires": "0",
                "Access-Control-Expose-Headers": "Content-Disposition",
                "X-Content-Type-Options": "nosniff"
            }
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
            
            buffer = io.BytesIO(decrypted_data)
            buffer.seek(0)
            
            # FIX V5: Dual-format Content-Disposition and Disable Caching
            return Response(
                decrypted_data,
                mimetype='application/octet-stream',
                headers={
                    "Content-Disposition": f"attachment; filename=\"{original_name}\"; filename*=UTF-8''{original_name}",
                    "Cache-Control": "no-cache, no-store, must-revalidate",
                    "Pragma": "no-cache",
                    "Expires": "0",
                    "Access-Control-Expose-Headers": "Content-Disposition",
                    "X-Content-Type-Options": "nosniff"
                }
            )
        except Exception as e:
            print(f"DECRYPT ERROR: {str(e)}", file=sys.stderr)
            flash('Decryption failed: Wrong password or tampered file.', 'danger')
            return redirect(url_for('decrypt'))
    return render_template('decrypt.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

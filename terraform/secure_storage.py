import sys
import os
from getpass import getpass
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from argon2 import PasswordHasher
from argon2.low_level import hash_secret_raw, Type

def derive_key(password: str, salt: bytes) -> bytes:
    """Derives a 256-bit key from a password and salt using Argon2id."""
    # Using argon2-cffi low_level for a 32-byte raw key
    return hash_secret_raw(
        secret=password.encode(),
        salt=salt,
        time_cost=3,
        memory_cost=65536,
        parallelism=1,
        hash_len=32,
        type=Type.ID
    )

def encrypt_file(file_path: str, password: str):
    """Encrypts a file using AES-256-GCM and Argon2id."""
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return

    salt = os.urandom(16)
    nonce = os.urandom(12)
    key = derive_key(password, salt)
    aesgcm = AESGCM(key)

    with open(file_path, "rb") as f:
        data = f.read()

    ciphertext = aesgcm.encrypt(nonce, data, None) # tag is appended to ciphertext in cryptography library

    # The user requested: salt (16) + nonce (12) + tag (16) + ciphertext
    # The cryptography library's AESGCM.encrypt returns ciphertext + tag (16 bytes)
    tag = ciphertext[-16:]
    actual_ciphertext = ciphertext[:-16]

    output_path = file_path + ".enc"
    with open(output_path, "wb") as f:
        f.write(salt)
        f.write(nonce)
        f.write(tag)
        f.write(actual_ciphertext)
    
    print(f"File encrypted successfully: {output_path}")

def decrypt_file(file_path: str, password: str):
    """Decrypts a file using AES-256-GCM and Argon2id."""
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        return

    with open(file_path, "rb") as f:
        salt = f.read(16)
        nonce = f.read(12)
        tag = f.read(16)
        ciphertext = f.read()

    key = derive_key(password, salt)
    aesgcm = AESGCM(key)

    try:
        # Reconstruct the combined ciphertext+tag for the cryptography library
        combined_data = ciphertext + tag
        plaintext = aesgcm.decrypt(nonce, combined_data, None)
        
        output_path = file_path.replace(".enc", ".dec")
        if output_path == file_path:
            output_path += ".dec"
            
        with open(output_path, "wb") as f:
            f.write(plaintext)
        print(f"File decrypted successfully: {output_path}")
    except Exception as e:
        print(f"Decryption failed: Authentication error (Wrong password or tampered file).")

def main():
    if len(sys.argv) < 3:
        print("Usage: python secure_storage.py <encrypt|decrypt> <file_path>")
        sys.exit(1)

    command = sys.argv[1].lower()
    file_path = sys.argv[2]
    
    # Handle non-interactive environments (like Azure Run-Command)
    if sys.stdin.isatty():
        password = getpass("Enter password: ")
    else:
        # Read from redirected stdin (the EOF block)
        password = sys.stdin.read().strip()

    if command == "encrypt":
        encrypt_file(file_path, password)
    elif command == "decrypt":
        decrypt_file(file_path, password)
    else:
        print(f"Unknown command: {command}")

if __name__ == "__main__":
    main()

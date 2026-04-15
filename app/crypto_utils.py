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

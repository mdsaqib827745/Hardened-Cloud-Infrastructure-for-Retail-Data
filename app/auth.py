import sqlite3
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

# Password hashing with Argon2id
ph = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=1,
    hash_len=32,
    salt_len=16
)

class AuthManager:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self._init_db()

    def _get_connection(self):
        return sqlite3.connect(self.db_path)

    def _init_db(self):
        with self._get_connection() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS metadata (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    filename TEXT NOT NULL,
                    blob_name TEXT UNIQUE NOT NULL,
                    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    user_id INTEGER,
                    FOREIGN KEY (user_id) REFERENCES users(id)
                )
            """)
            conn.commit()

    def register_user(self, username, password):
        """Registers a new user with a hashed password."""
        hashed_password = ph.hash(password)
        try:
            with self._get_connection() as conn:
                conn.execute(
                    "INSERT INTO users (username, password_hash) VALUES (?, ?)",
                    (username, hashed_password)
                )
                conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False

    def authenticate_user(self, username, password):
        """Authenticates a user and returns their ID if successful."""
        with self._get_connection() as conn:
            cursor = conn.execute(
                "SELECT id, password_hash FROM users WHERE username = ?",
                (username,)
            )
            row = cursor.fetchone()
            if row:
                user_id, hashed_password = row
                try:
                    ph.verify(hashed_password, password)
                    if ph.check_needs_rehash(hashed_password):
                        # Optionally rehash if parameters have changed
                        pass
                    return user_id
                except VerifyMismatchError:
                    return None
            return None

    def add_metadata(self, filename, blob_name, user_id):
        """Stores metadata for an uploaded file."""
        with self._get_connection() as conn:
            conn.execute(
                "INSERT INTO metadata (filename, blob_name, user_id) VALUES (?, ?, ?)",
                (filename, blob_name, user_id)
            )
            conn.commit()

    def get_user_files(self, user_id):
        """Retrieves file list for the specified user."""
        with self._get_connection() as conn:
            cursor = conn.execute(
                "SELECT id, filename, blob_name, upload_date FROM metadata WHERE user_id = ?",
                (user_id,)
            )
            return cursor.fetchall()

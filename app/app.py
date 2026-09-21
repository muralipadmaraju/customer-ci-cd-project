import os
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)
VERSION = os.getenv("APP_VERSION", "dev")
ENVIRONMENT = os.getenv("APP_ENVIRONMENT", "unknown")
DB_HOST = os.getenv("DB_HOST", "db")
DB_NAME = os.getenv("POSTGRES_DB", "customer")
DB_USER = os.getenv("POSTGRES_USER", "customer")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "customer123")

def db_connection():
    return psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=3)

@app.get("/")
def home():
    return jsonify(application="customer-app", version=VERSION, environment=ENVIRONMENT)

@app.get("/health")
def health():
    return jsonify(status="UP", version=VERSION, environment=ENVIRONMENT), 200

@app.get("/db")
def db_check():
    try:
        with db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT version()")
                db_version = cur.fetchone()[0]
        return jsonify(status="UP", database="reachable", db_version=db_version), 200
    except Exception as exc:
        return jsonify(status="DOWN", database="unreachable", error=str(exc)), 500

@app.get("/version")
def version():
    return jsonify(version=VERSION, environment=ENVIRONMENT)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

import firebase_admin
from firebase_admin import credentials, firestore

try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
except FileNotFoundError:
    print("WARNING: serviceAccountKey.json not found. Using MOCK FIREBASE DB.")
    db = None

def save_proof(data):
    if db is None:
        print("MOCK SAVED PROOF TO MOCK DB:", data)
        return
    db.collection("proofs").add(data)

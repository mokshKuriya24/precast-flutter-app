import firebase_admin
from firebase_admin import credentials, firestore
import qrcode
import os

# Initialize Firebase Admin SDK
cred = credentials.Certificate('D:/Projects/moksh-app/precast-flutter-app/python-app/firebase-key.json')
firebase_admin.initialize_app(cred)

# Firestore client
db = firestore.client()

def add_component_to_firestore(component_data):
    component_id = component_data['Component_ID']
    
    # Save to Firestore under Pre-Cast Components collection
    db.collection('Pre-Cast Components').document(component_id).set(component_data)
    print(f"✅ Component {component_id} uploaded to Firestore.")

def generate_qr_code(component_id):
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    
    qr.add_data(component_id)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")

    output_dir = "qr_codes"
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"{component_id}.png")
    
    img.save(output_path)
    print(f"✅ QR code saved as {output_path}.")

def main():
    # Example component data
    component_data = {
        "Component_ID": "COMP-00123",
        "Component_Type": "Column",
        "Manufacturing_Date": "2025-04-21",
        "Factory_Location": "Plant A",
        "Current_Status": "Manufactured",
        "Destination": "Site B"
    }

    add_component_to_firestore(component_data)
    generate_qr_code(component_data['Component_ID'])

if __name__ == "__main__":
    main()

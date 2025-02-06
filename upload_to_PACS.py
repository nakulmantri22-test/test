import os
import requests

# Orthanc server details (update the IP if needed)
ORTHANC_URL = "http://192.168.133.202:4242/studies" 

# DICOM file to send (update path)
DICOM_DIR = "/path/to/dicom/folder"
HEADERS = {"Content-Type": "multipart/related; type=application/dicom"}

# Function to send DICOM file using STOW-RS
def send_dicom_file(file_path):
    with open(file_path, "rb") as dicom_file:
        response = requests.post(ORTHANC_URL, headers=HEADERS, data=dicom_file)
        
        if response.status_code in [200, 204]:  # Success
            print(f"Successfully uploaded: {file_path}")
        else:
            print(f"Failed to upload {file_path}: {response.status_code} - {response.text}")

# Iterate over all DICOM files in the folder
if __name__ == "__main__":
    for file_name in os.listdir(DICOM_DIR):
        file_path = os.path.join(DICOM_DIR, file_name)
        if file_name.endswith(".dcm"):
            send_dicom_file(file_path)

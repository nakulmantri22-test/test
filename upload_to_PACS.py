# import os
# import requests

# # Orthanc server details (update the IP if needed)
# ORTHANC_URL = "http://10.194.185.233:4242/instances"  # Change to 8042 if needed

# # DICOM file to send (update path)
# DICOM_DIR = "/home/nakul/PROJECT(ORTHANC)/dicom/files"

# HEADERS = {"Content-Type": "multipart/related; type=application/dicom"}

# # Function to send DICOM file using STOW-RS
# def send_dicom_file(file_path):
#     with open(file_path, "rb") as dicom_file:
#         response = requests.post(ORTHANC_URL, headers=HEADERS, data=dicom_file)
        
#         if response.status_code in [200, 204]:  # Success
#             print(f"Successfully uploaded: {file_path}")
#         else:
#             print(f"Failed to upload {file_path}: {response.status_code} - {response.text}")

# # Iterate over all DICOM files in the folder
# if __name__ == "__main__":
#     for file_name in os.listdir(DICOM_DIR):
#         file_path = os.path.join(DICOM_DIR, file_name)
#         if file_name.endswith(".dcm"):
#             send_dicom_file(file_path)




import os
import subprocess

def send_dicom_to_pacs(dicom_file):
    PACS_IP = "10.194.185.233"  # Replace with actual PACS server IP
    PACS_PORT = "4242"  # PACS server port
    AETITLE = "ORTHANC"  # Orthanc's AET
    PACS_AETITLE = "PACS"  # PACS server's AET

    # Check if file exists
    if not os.path.exists(dicom_file):
        print(f"Error: DICOM file {dicom_file} does not exist.")
        return

    try:
        # Using storescu to send the DICOM file to PACS
        cmd = [
            "storescu", "-v", "-aec", PACS_AETITLE, PACS_IP, PACS_PORT, dicom_file
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"Successfully sent {dicom_file} to PACS.")
        else:
            print(f"Failed to send {dicom_file} to PACS. Error: {result.stderr}")
    except Exception as e:
        print(f"Exception occurred: {e}")

if __name__ == "__main__":
    dicom_file_path = "/home/nakul/PROJECT(ORTHANC)/dicom/files/case1_010.dcm"  # Update this
    send_dicom_to_pacs(dicom_file_path)


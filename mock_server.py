from flask import Flask, request, jsonify

app = Flask(__name__)

# Store uploaded instances
uploaded_instances = []

@app.route('/')
def home():
    """Render the HTML page to display uploaded instances."""
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Uploaded DICOM Instances</title>
        <style>
            body { font-family: Arial, sans-serif; background-color: #f4f4f4; text-align: center; padding: 20px; }
            table { width: 60%; margin: auto; border-collapse: collapse; background-color: white; }
            th, td { border: 1px solid #ddd; padding: 10px; text-align: center; }
            th { background-color: #4CAF50; color: white; }
        </style>
    </head>
    <body>
        <h1>Uploaded DICOM Instances</h1>
        <table>
            <tr>
                <th>Instance ID</th>
                <th>Orthanc URL</th>
            </tr>
    """

    for instance in uploaded_instances:
        html += f"""
            <tr>
                <td>{instance["instance_id"]}</td>
                <td>{instance["orthanc_url"]}</td>
            </tr>
        """

    html += """
        </table>
    </body>
    </html>
    """

    return html

@app.route('/upload', methods=['POST'])
def upload_instance():
    """Receive and store uploaded instance IDs."""
    data = request.json
    instance_id = data.get("instance_id")
    orthanc_url = data.get("orthanc_url")

    if instance_id:
        print(f"Received Instance ID: {instance_id} from {orthanc_url}")

        # Store instance details
        uploaded_instances.append({"instance_id": instance_id, "orthanc_url": orthanc_url})

        return jsonify({"status": "success", "message": "Instance uploaded to Flask"}), 200
    else:
        return jsonify({"status": "error", "message": "Missing instance_id"}), 400

@app.route('/run_study', methods=['POST'])
def run_study():
    """Trigger a study process for the uploaded instance."""
    data = request.json
    instance_id = data.get("instance_id")

    if not instance_id:
        return jsonify({"status": "error", "message": "Missing instance_id"}), 400

    # Simulate study processing
    print(f"Running study for Instance ID: {instance_id}")

    return jsonify({"status": "success", "message": f"Study started for instance {instance_id}"}), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

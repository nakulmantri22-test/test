-- Function to log with timestamp
function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print("[" .. timestamp .. "] " .. message)
end

-- Function to extract the latest Instance ID from Orthanc
function GetLatestInstanceID(orthancUrl)
    local command = string.format('curl -s -X GET %s/instances', orthancUrl)
    local response = io.popen(command):read("*a")
    log("Response from Orthanc: " .. response)
    local instanceId = response:match('"([a-f0-9%-]+)"')
    return instanceId
end

-- Function to upload the instance to Flask server
function UploadToFlask(instanceId, orthancUrl, flaskApiUrl)
    local jsonData = string.format('{"instance_id":"%s","orthanc_url":"%s"}', instanceId, orthancUrl)
    local command = string.format(
        'curl -s -X POST -H "Content-Type: application/json" -d \'%s\' %s/upload',
        jsonData,
        flaskApiUrl
    )
    local response = io.popen(command):read("*a")
    log("Response from Flask: " .. response)

    if response:match("success") then
        log("Instance successfully uploaded to Flask!")
        RunStudy(flaskApiUrl, instanceId) -- Trigger study after upload
    else
        log("Failed to upload to Flask. Retrying...")
        RetryFileUpload(orthancUrl, flaskApiUrl, instanceId)
    end
end

-- Function to trigger the study process on Flask server
function RunStudy(flaskApiUrl, instanceId)
    local jsonData = string.format('{"instance_id": "%s"}', instanceId)
    local command = string.format(
        'curl -s -X POST -H "Content-Type: application/json" -d \'%s\' %s/run_study',
        jsonData,
        flaskApiUrl
    )
    local response = io.popen(command):read("*a")
    log("Response from Run Study: " .. response)

    if response:match("success") then
        log("Study successfully triggered on Flask!")
    else
        log("Failed to trigger study on Flask.")
    end
end

-- Retry Logic with Backoff
function RetryFileUpload(orthancUrl, flaskApiUrl, instanceId)
    local retries = 5
    local delay = 10
    for attempt = 1, retries do
        log("Retry attempt " .. attempt .. " to upload to Flask...")
        UploadToFlask(instanceId, orthancUrl, flaskApiUrl)
        if attempt < retries then
            log("Waiting for " .. delay .. " seconds before retrying...")
            os.execute("sleep " .. delay)
            delay = delay * 2
        end
    end
    log("Failed to upload file after multiple attempts.")
end

-- Function to delete instance from Orthanc after successful upload
function DeleteFromOrthanc(orthancUrl, instanceId)
    local command = string.format('curl -s -X DELETE %s/instances/%s', orthancUrl, instanceId)
    io.popen(command):read("*a")
    log("Deleted instance " .. instanceId .. " from Orthanc.")
end

-- Function to process uploaded file
function ProcessUploadedFile(orthancUrl, flaskApiUrl)
    local instanceId = GetLatestInstanceID(orthancUrl)
    if not instanceId then
        log("Failed to extract Instance ID.")
        return
    end
    log("Extracted Instance ID: " .. instanceId)

    UploadToFlask(instanceId, orthancUrl, flaskApiUrl)
    DeleteFromOrthanc(orthancUrl, instanceId)
end

-- URLs for Orthanc and Flask server
local orthancApiUrl = "http://127.0.0.1:8042"  -- Orthanc server URL
local flaskApiUrl = "http://127.0.0.1:5000"  -- Flask server URL

-- Start processing the file
ProcessUploadedFile(orthancApiUrl, flaskApiUrl)

-- Function to check if the instance is already uploaded to AIH
function CheckForDuplicateAIH(instanceId, aihUrl)
    local command = string.format(
        'curl -s -X GET %s/check_duplicate/%s',
        aihUrl,
        instanceId
    )
    local response = io.popen(command):read("*a")
    print("Response from AIH check: " .. response)
    return response:match("duplicate") ~= nil
end

-- Function to extract the latest Instance ID from Orthanc
function GetLatestInstanceID(orthancUrl)
    local command = string.format('curl -s -X GET %s/instances', orthancUrl)
    local response = io.popen(command):read("*a")
    print("Response from Orthanc: " .. response)
    local instanceId = response:match('"([a-f0-9%-]+)"')
    return instanceId
end

-- Function to push the Instance ID to AIH Server using curl
-- Function to push the Instance ID to AIH Server using curl
function PushToAIH(instanceId, orthancUrl, aihUrl)
    -- Ensure AIH URL has a trailing slash
    if not aihUrl:match("/$") then
        aihUrl = aihUrl .. "/"
    end

    -- Construct JSON data
    local jsonData = string.format('{"instance_id":"%s","orthanc_url":"%s"}', instanceId, orthancUrl)
    
    -- Use -L to follow redirects
    local command = string.format(
        'curl -L -X POST -H "Content-Type: application/json" -d \'%s\' %supload',
        jsonData,
        aihUrl
    )
    
    -- Execute the curl command and capture the response
    local response = io.popen(command):read("*a")
    print("Response from AIH: " .. response)
    
    -- Check if the response from AIH indicates success
    if response:match("success") then
        print("Instance successfully pushed to AIH!")
        DeleteFileAfterDelay(orthancUrl, instanceId)
    else
        print("Failed to push to AIH. Retrying...")
        RetryFileUpload(orthancUrl, aihUrl, instanceId)
    end
end


-- Function to retry file upload if it fails
function RetryFileUpload(orthancUrl, aihUrl, instanceId)
    for attempt = 1, 5 do
        print("Retry attempt " .. attempt .. " to push the file to AIH...")
        if PushToAIH(instanceId, orthancUrl, aihUrl) then return true end
        os.execute("sleep 60")
    end
    print("Failed to upload file after multiple attempts.")
    return false
end

-- Function to delete instance from Orthanc
function DeleteFromOrthanc(orthancUrl, instanceId)
    local command = string.format('curl -s -X DELETE %s/instances/%s', orthancUrl, instanceId)
    io.popen(command):read("*a")
    print("Deleted instance " .. instanceId .. " from Orthanc.")
end

-- Function to process uploaded files
function ProcessUploadedFile(orthancUrl, aihUrl)
    local instanceId = GetLatestInstanceID(orthancUrl)
    if not instanceId then
        print("Failed to extract Instance ID.")
        return
    end
    print("Extracted Instance ID: " .. instanceId)

    if CheckForDuplicateAIH(instanceId, aihUrl) then
        print("Duplicate found. Deleting from Orthanc.")
        DeleteFromOrthanc(orthancUrl, instanceId)
    else
        if not PushToAIH(instanceId, orthancUrl, aihUrl) then
            RetryFileUpload(orthancUrl, aihUrl, instanceId)
        end
    end
end

-- URLs for Orthanc and AIH servers
local orthancApiUrl = "http://127.0.0.1:8042"
local aihApiUrl = "https://aih.cse.iitd.ac.in/swasth/"

-- Start processing the file
ProcessUploadedFile(orthancApiUrl, aihApiUrl)

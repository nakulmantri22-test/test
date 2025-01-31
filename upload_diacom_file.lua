local https = require("socket.http")
local ltn12 = require("ltn12")
local uuid = require("uuid")
local io = require("io")


math.randomseed(os.time())  -- Seed the random number generator
uuid.set_rng(function(len)
    local bytes = {}
    for i = 1, len do
        bytes[i] = string.char(math.random(0, 255))  -- Generate random bytes
    end
    return table.concat(bytes)
end)


-- Function to log messages
function log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print("[" .. timestamp .. "] " .. message)
end

function GetLatestInstanceID(orthancUrl)
        if type(orthancUrl) ~= "string" then
            log("Error: orthancUrl should be a string.")
            return nil
        end
    
        local command = string.format('curl -s -X GET "%s/instances"', orthancUrl)  -- Ensure orthancUrl is in quotes
        local response = io.popen(command):read("*a")
        log("Response from Orthanc: " .. response)
    
        local instanceId = response:match('"([a-f0-9%-]+)"')
        if not instanceId then
            log("No instance ID found in the Orthanc response.")
            return nil
        end
        return instanceId
    end



-- Function to authenticate with AIH
function GetAuthToken(email, password, authUrl)
    local jsonData = string.format('{"email": "%s", "password": "%s"}', email, password)
    local command = string.format(
        'curl -s -X POST -H "Content-Type: application/json" -d \'%s\' %s',
        jsonData,
        authUrl
    )

    local response = io.popen(command):read("*a")
    log("Response from AIH Auth: " .. response)

    local token = response:match('"access"%s*:%s*"([^"]+)"')
    if not token then
        log("Failed to authenticate with AIH. Check credentials.")
        return nil
    end

    log("Successfully authenticated with AIH.")
    return token
end


-- -- Function to delete instance from Orthanc after successful upload
function DeleteFromOrthanc(orthancUrl, instanceId)
    local command = string.format('curl -s -X DELETE %s/instances/%s', orthancUrl, instanceId)
    io.popen(command):read("*a")
    log("Deleted instance " .. instanceId .. " from Orthanc.")
end


-- Function to upload DICOM file to AIH using multipart/form-data

function UploadToAIH(instanceId, orthancUrl, aihApiUrl, email, password)
    if not instanceId then
        log("No instance ID found, skipping upload.")
        return
    end

    -- Authenticate and get access token
    local accessToken = GetAuthToken(email, password, aihApiUrl .. "/api/v1/auth/login/")
    if not accessToken then
        log("Failed to obtain access token, aborting upload.")
        return
    end

    -- Correct upload URL
    local uploadUrl = "https://aih.cse.iitd.ac.in/api/v1/dicom-web/wado-rs/studies"

    -- Retrieve the DICOM file from Orthanc and save it locally
    local dicomFilePath = "/tmp/" .. instanceId .. ".dcm"
    local retrieveCommand = string.format(
        'curl -s -X GET "%s/instances/%s/file" -o %s',
        orthancUrl,
        instanceId,
        dicomFilePath
    )
    os.execute(retrieveCommand)
    log("DICOM file saved locally: " .. dicomFilePath)

    -- Generate a unique boundary using uuid
    local boundary = uuid()

    -- Open the DICOM file in binary mode
    local dicomFile = io.open(dicomFilePath, "rb")
    local dicomData = dicomFile:read("*all")
    dicomFile:close()

    -- Construct the multipart/related body
    local body = string.format(
        "--%s\r\nContent-Type: application/dicom\r\nContent-Transfer-Encoding: binary\r\n\r\n%s\r\n--%s--\r\n",
        boundary, dicomData, boundary
    )

    -- Set the headers with the correct Content-Type, boundary, and Authorization token
    local headers = {
        ["Content-Type"] = string.format('multipart/related; type="application/dicom"; boundary="%s"', boundary),
        ["Authorization"] = "Bearer " .. accessToken
    }

    -- Prepare the request
    local responseBody = {}
    local res, code, responseHeaders, status = https.request{
        url = uploadUrl,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(responseBody)
    }

    -- Check the response status
    if code == 200 then
        log("DICOM file uploaded successfully.")
        -- RunStudy(aihApiUrl, instanceId, accessToken)
        DeleteFromOrthanc(orthancUrl, instanceId)
    else
        log(string.format("Failed to upload DICOM file. Status code: %d, Message: %s", code, table.concat(responseBody)))
        RetryFileUpload(orthancUrl, aihApiUrl, instanceId, email, password)
    end
end


local function RetryFileUpload(orthancUrl, aihApiUrl, instanceId, email, password)
        local retries = 5
        local delay = 10
        for attempt = 1, retries do
            log("Retry attempt " .. attempt .. " to upload to AIH...")
            UploadToAIH(instanceId, orthancUrl, aihApiUrl, email, password)
            if attempt < retries then
                log("Waiting for " .. delay .. " seconds before retrying...")
                os.execute("sleep " .. delay)
                delay = delay * 2
            end
        end
        log("Failed to upload file after multiple attempts.")
    end
    

-- Function to process uploaded file
function ProcessUploadedFile(orthancUrl, aihApiUrl, email, password)
    local instanceId = GetLatestInstanceID(orthancUrl)
    if not instanceId then
        log("Failed to extract Instance ID.")
        return
    end
    log("Extracted Instance ID: " .. instanceId)

    -- Upload the instance to AIH
    UploadToAIH(instanceId, orthancUrl, aihApiUrl, email, password)
end

-- URLs and credentials
local orthancApiUrl = "http://127.0.0.1:8042"
local aihApiUrl = "https://aih.cse.iitd.ac.in"
local email = "nakulmantri22@gmail.com"
local password = "swasth1234"

-- Start processing the file
ProcessUploadedFile(orthancApiUrl, aihApiUrl, email, password)

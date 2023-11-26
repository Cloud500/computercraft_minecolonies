local metadataFile = "https://raw.githubusercontent.com/Cloud500/computercraft_minecolonies/main/citizens/metadata.json"

local function downloadGit(path, file)
    print("Download " .. file .. "from Git")
    local repo = http.get(path)
    local data = repo.readAll()
    repo.close()

    local file = fs.open(file, "w")
    file.write(data)
    file.close()
end

local function downloadPastebin(id, file)
    print("Download " .. file .. "from Pastebin")
    shell.run("pastebin get " .. id .. " " .. file)
end

local function getMetadata(path)
    local repo = http.get(path)
    local data = repo.readAll()
    return json.decode(data)
end


local function loadJsonAPI()
    if not fs.exists("lib/json") then
        print("JSON API missing, Downloading JSON API")
        downloadPastebin("4nRg9CHU", "lib/json")
        print()
    end
end


local function downloadFiles(fileList)
    for fileNumber in pairs(fileList) do
        local fileData = fileList[fileNumber]
        if fileData.type == "git"then
            downloadGit(fileData.gitPath, fileData.localPath)
        elseif fileData.type == "pastebin" then
            downloadPastebin(fileData.id, fileData.localPath)
        end
        print(fileData.localPath)
    end
end


loadJsonAPI()
os.loadAPI("lib/json")

local metadata = getMetadata(metadataFile)

print("Installing " .. metadata.name)
print("Version " .. metadata.version)
print()

print("Downloading necessary files")
downloadFiles(metadata.files)
print()

print("Downloading dependencies files")
downloadFiles(metadata.dependencies)
print()

print(metadata.name .. " Version " .. metadata.version .. " installed.")
print("Run " .. metadata.command .. " to start")
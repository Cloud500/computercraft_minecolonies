local DEBUG = false
local fakePeripheralPath = ""

---@alias ItemJson {config: {chestPosition: string, colonyME: string, mainME: string, networkShare: boolean, logging: {enabled: boolean, logLevel: integer, path: string, outputToTerminal: boolean}}, items: {item: string, count: integer}[]}
---@alias MEBridge {importItemFromPeripheral: fun(table, string), exportItemToPeripheral: fun(table, string), getItem: fun(table):({name: string, amount: integer})}


---Helper Function for CraftOS Debugging/Testing
---@return nil
local function debugCreatePeripheral()
    mounter.mount("/lib", fakePeripheralPath .. "\\apis", "ro")
    mounter.mount("/", fakePeripheralPath .. "\\itemManager", "ro")
    mounter.mount("/", fakePeripheralPath .. "\\fakes", "ro")
end


---Class to transfer items from main ME system to the colony ME system
---@class ColonyItemManager The Class itself
---@field jsonObject ItemJson The loaded JSON Data
---@field colonyMEBridge MEBridge ME Bridge for the colony
---@field mainMEBridge MEBridge ME Bridge of the main network
---@field chestPosition string Position of the "Transfer Chest"
---@field logger Logger | nil Logger object
---@field timeBetweenRuns number Time between runs
local ColonyItemManager = {}
ColonyItemManager.__index = ColonyItemManager


---@param path string | nil Path of the json file
---@return ColonyItemManager ColonyItemManager New ColonyItemManager object
function ColonyItemManager:new(path)
    ---@type ColonyItemManager
    local o = {
        jsonObject = {},
        colonyMEBridge = {},
        mainMEBridge = {},
        chestPosition = "",
        logger = nil,
        timeBetweenRuns = 5
    }
    setmetatable(o, self)
    if path == nil then
        path = "items.json"
    end

    o.jsonObject = o:loadJsonFile(path)
    o.chestPosition = o:getChestPosition()
    o:loadColonyMEBride()
    o:loadMainMEBride()

    o.logger = o:getLogger()

    return o
end

---Try to load the JSON API
---@return nil
function ColonyItemManager.loadJsonAPI()
    if not fs.exists("lib/json") then
        error("JSON API not found.")
    end

    os.loadAPI("lib/json")
end

---Try to load the logger
---@return nil
function ColonyItemManager:getLogger()
    if not fs.exists("lib/logger.lua") then
        error("Logger not found.")
    else
        print("TEST")
    end

    ---@type Logger
    local logger = require("lib/logger")

    local logConfig = self:getLoggingInfo()

    return logger:new(logConfig.path,
        logConfig.logLevel,
        logConfig.outputToTerminal,
        logConfig.enabled)
end

---Try to load the colony ME Bridge,
---has some Debug options for CraftOS Debugging/Testing
---@return nil
function ColonyItemManager:loadColonyMEBride()
    if DEBUG then
        self.colonyMEBridge = require("fake_MEBridge")
    else
        self.colonyMEBridge = peripheral.wrap(self:getColonyMEBridgeName())
    end

    if not self.colonyMEBridge then
        error("Colony ME Bridge not found.")
    end
end

---Try to load the main network ME Bridge,
---has some Debug options for CraftOS Debugging/Testing
---@return nil
function ColonyItemManager:loadMainMEBride()
    if DEBUG then
        self.mainMEBridge = require("fake_MEBridge")
    else
        self.mainMEBridge = peripheral.wrap(self:getMainMEBridgeName())
    end

    if not self.mainMEBridge then
        error("Main ME Bridge not found.")
    end
end

---Get the position of the colony ME Bridge
---@return string colonyME Position of the ME Bridge
function ColonyItemManager:getColonyMEBridgeName()
    return self.jsonObject.config.colonyME
end

---Get the position of the main network ME Bridge
---@return string mainME Position of the ME Bridge
function ColonyItemManager:getMainMEBridgeName()
    return self.jsonObject.config.mainME
end

---Get the position of the "Transfer Chest"
---@return string chestPosition Position of the "Transfer Chest"
function ColonyItemManager:getChestPosition()
    return self.jsonObject.config.chestPosition
end

---Get the info if the main and colony network share the items
---@return boolean networkShare Network share condition
function ColonyItemManager:getNetworkShare()
    return self.jsonObject.config.networkShare
end

--- Get the logger information
---@return {enabled: boolean, logLevel: integer, path: string, outputToTerminal: boolean} logging Logging information
function ColonyItemManager:getLoggingInfo()
    return self.jsonObject.config.logging
end

---Read the content from the JSON file
---@param path string Path to the JSON file
---@return ItemJson jsonObject Content of the JSON file
function ColonyItemManager:loadJsonFile(path)
    os.loadAPI("lib/json")
    return json.decodeFromFile(path)
end

---Get the current colony amount from given item
---@param itemName string Name of the item
---@return integer amount Current colony item amount
function ColonyItemManager:getCurrentColonyAmount(itemName)
    local result = self.colonyMEBridge.getItem(
        { name = itemName }
    )

    local amount = result.amount
    if amount == nil then
        amount = 0
    end

    return amount
end

---Get the current main network amount from given item
---@param itemName string Name of the item
---@return integer amount Current main network item amount
function ColonyItemManager:getCurrentMainAmount(itemName)
    local result = self.mainMEBridge.getItem(
        { name = itemName }
    )
    local amount = result.amount
    if amount == nil then
        amount = 0
    end

    return amount
end

---Calc the item amount to transfer from main network to colony network
---@param itemName string Name of the item
---@param itemTargetAmount integer Target amount to be in the colony network
---@return integer transferAmount Amount to transfer
function ColonyItemManager:calcAmountToTransfer(itemName, itemTargetAmount)
    local colonyAmount = self:getCurrentColonyAmount(itemName)
    local mainAmount = self:getCurrentMainAmount(itemName)

    local transferAmount = 0

    if self:getNetworkShare() == true then
        if mainAmount == colonyAmount then
            return 0
        end
        mainAmount = mainAmount - colonyAmount
    end

    if colonyAmount < itemTargetAmount then
        transferAmount = itemTargetAmount - colonyAmount
    end

    if mainAmount < transferAmount then
        transferAmount = mainAmount
    end

    return transferAmount
end

---Transfer the given amount of item from main network to colony network
---@param itemName string Name of the item
---@param transferAmount integer Amount to transfer
---@return nil
function ColonyItemManager:transferItem(itemName, transferAmount)
    self.mainMEBridge.exportItemToPeripheral(
        {
            name = itemName,
            count = transferAmount
        },
        self.chestPosition
    )
    self.colonyMEBridge.importItemFromPeripheral(
        {
            name = itemName,
            count = transferAmount
        },
        self.chestPosition
    )
    self.logger:logInfo("Transfer " .. transferAmount .. " of " .. itemName)
end

---Iterate through the items from the JSON file and start a transfer if necessary
---@return nil
function ColonyItemManager:checkAndTransferItems()
    for itemNumber in pairs(self.jsonObject.items) do
        local itemData = self.jsonObject.items[itemNumber]
        local transferAmount = self:calcAmountToTransfer(itemData.item, itemData.count)
        if transferAmount > 0 then
            self:transferItem(itemData.item, transferAmount)
        end
    end
end

---Main loop for the Programm
---@return nil
function ColonyItemManager:init()
    self:checkAndTransferItems()
    local TIMER = os.startTimer(self.timeBetweenRuns)
    while true do
        local event = { os.pullEvent() }
        if event[1] == "timer" and event[2] == TIMER then
            self:checkAndTransferItems()
            TIMER = os.startTimer(self.timeBetweenRuns)
        end
    end
end

if DEBUG then
    debugCreatePeripheral()
end

local itemManager = ColonyItemManager:new()
itemManager:init()

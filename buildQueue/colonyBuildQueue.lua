local DEBUG = false
local SCALE = 0.5
local workspacePath = ""

local colonyManager = nil
local monitor = nil

--- Debug function to create the peripherals
local function debugCreatePeripheral()
    periphemu.create("left", "monitor")
    mounter.mount("/lib", workspacePath .. "\\fakes", "ro")
    mounter.mount("/lib", workspacePath .. "\\apis", "ro")
    print(textutils.serialize(fs.list("/lib")))
    colonyManager = require("/lib/fake_colony")
end

--- Class to get and show the colony requests
---@class ColonyItemManager
---@field colonyDisplayManager ColonyDisplayManager
---@field colonyManager table
---@field timeBetweenRuns number
---@field currentRun number
local ColonyBuildQueueData = {}
ColonyBuildQueueData.__index = ColonyBuildQueueData

--- Create a new ColonyRequestsData Object
---@return ColonyItemManager ColonyRequestsData New ColonyRequestsData object
function ColonyBuildQueueData:new()
    ---@type ColonyItemManager
    local o = {
        colonyDisplayManager = {},
        colonyManager = {},
        colonyOrders = {},
        timeBetweenRuns = 30,
        currentRun = 0
        
    }
    setmetatable(o, self)

    local colonyDisplayManager = require("lib/colonyDisplayManager")

    o.colonyDisplayManager = colonyDisplayManager:new(o.loadMonitor(), SCALE)
    o.colonyManager = o.loadColonyManager()
    return o
end

--- Load the connected monitor peripheral
---@return table monitor Monitor peripheral
function ColonyBuildQueueData.loadMonitor()
    if not monitor then
        monitor = peripheral.find("monitor")
    end
    if not monitor then
        error("Monitor not found.")
    end
    return monitor
end

--- Load the connected colony peripheral
---@return table monitor Colony peripheral
function ColonyBuildQueueData.loadColonyManager()
    if not colonyManager then
        colonyManager = peripheral.find("colony")
    end
    if not colonyManager then
        error("Colony Bridge not found.")
    end
    return colonyManager
end

--- Get the current time cycle
---@param currentTime number Current ingame Time
---@return number cycleColor Cycle color
function ColonyBuildQueueData.getTimeCycle(currentTime)
    local cycleColor = colors.orange

    if currentTime >= 4 and currentTime < 6 then
        cycleColor = colors.orange
    elseif currentTime >= 6 and currentTime < 18 then
        cycleColor = colors.yellow
    elseif currentTime >= 18 and currentTime < 19.5 then
        cycleColor = colors.orange
    elseif currentTime >= 19.5 or currentTime < 5 then
        cycleColor = colors.red
    end

    return cycleColor
end

--- Get the color for the refresh timer
---@return number refreshTimeColor Color for the refresh timer
function ColonyBuildQueueData:getRefreshTimeColor()
    local refreshTimeColor = colors.orange
    if self.currentRun < 15 then
        refreshTimeColor = colors.yellow
    end
    if self.currentRun < 5 then
        refreshTimeColor = colors.red
    end

    return refreshTimeColor
end

--- Check if the requests should be refreshed
---@return boolean isTimeToRun Should I run
function ColonyBuildQueueData.isTimeToRun()
    local currentTime = os.time()
    if currentTime >= 5 and currentTime < 19.5 then
        return true
    end
    return false
end


--- Load the requests for the colony
function ColonyBuildQueueData:getRequests()
    self.colonyOrders = self.colonyManager.getWorkOrders()
end

function ColonyBuildQueueData.roundPercent(value)
    if value <= 99 then
        return math.ceil(value)
    else
        return math.floor(value)
    end
end

function ColonyBuildQueueData:calcOrderResources(orderID)
    local resources = self.colonyManager.getWorkOrderResources(orderID)

    local maxCount = 0
    local currentCount = 0

    if resources  ~= nil then

        for resourceNumber in pairs(resources) do
            local resource = resources[resourceNumber]

            local available = resource.available
            local count = resource.item.count

            if available > count then
                available = count
            end
            maxCount = maxCount + count
            currentCount = currentCount + available
        end
    end

    return currentCount, maxCount
end

function ColonyBuildQueueData.formatName(rawName, sep)

    if sep == nil then
        sep = "/"
    end
    local tbl={}

    for str in string.gmatch(rawName, "([^"..sep.."]+)") do
        table.insert(tbl, str)
    end

    return tbl[#tbl]
end

function ColonyBuildQueueData:printRequest(currentRow, request)
    local upgradeLevel = string.format("%d -> %d", request.currentLevel, request.targetLevel)
    local currentCount, maxCount = self:calcOrderResources(request.id)

    local availablePercent = (100 / maxCount) * currentCount
    local buildPercent = (100 / request.amountOfResources) * (request.amountOfResources - maxCount)

    availablePercent = self.roundPercent(availablePercent)
    buildPercent = self.roundPercent(buildPercent)
    
    local infoString = ""

    local color = colors.gray

    -- if availablePercent ~= 100 then
    --     infoString = string.format("%s %03d%%", upgradeLevel, availablePercent)
    --     color = colors.blue
    -- else
    --     infoString = string.format("%s %03d%%", upgradeLevel, buildPercent)
    --     color = colors.green
    -- end

    local percentToDisplay = availablePercent
    if buildPercent > 0 then
        color = colors.green
        percentToDisplay = buildPercent
    elseif availablePercent > 0 then
        color = colors.blue
    end

    if request.requested == 0 then
        color = colors.gray
    end

    infoString = string.format("%s %03d%%", upgradeLevel, percentToDisplay)

    local name = ColonyBuildQueueData.formatName(request.translationKey)
    name = ColonyBuildQueueData.formatName(name, ".")
    name = name:gsub("_", " ")
    
    self.colonyDisplayManager:print(currentRow, "left", name, color)
    self.colonyDisplayManager:print(currentRow, "right", infoString, color)
end

--- Print the requests to the monitor
function ColonyBuildQueueData:printRequests()
    self.colonyDisplayManager:clear()
    self:getRequests()

    local currentRow = 4
    local activeBuild = {}
    local plannedBuild = {}

    for requestNumber in pairs(self.colonyOrders) do
        local request = self.colonyOrders[requestNumber]
        if request.type ~= "miner" then
            if request.requested == 1 then
                table.insert(activeBuild, request)
            else
                table.insert(plannedBuild, request)
            end
        end
    end

    self.colonyDisplayManager:print(3, "center", string.format("%d Orders", #activeBuild + #plannedBuild))

    for requestNumber in pairs(activeBuild) do
        local request = activeBuild[requestNumber]
        self:printRequest(currentRow, request)
        currentRow = currentRow + 1
    end

    for requestNumber in pairs(plannedBuild) do
        local request = plannedBuild[requestNumber]
        self:printRequest(currentRow, request)
        currentRow = currentRow + 1
    end

end

function ColonyBuildQueueData:printHeader()
    local currentTime = os.time()
    local timeToRun = self.currentRun
    local isTimeToRun = self.isTimeToRun()
    local timeColor = self.getTimeCycle(currentTime)
    local refreshTimeColor = self:getRefreshTimeColor()
    local pauseColor = colors.red

    self.colonyDisplayManager:printHeader(currentTime, timeToRun, isTimeToRun, timeColor, refreshTimeColor, pauseColor)

end


--- Initializes the program
function ColonyBuildQueueData:init()
    self.colonyDisplayManager:initMonitor()
    self.currentRun = self.timeBetweenRuns
    self:printHeader()
    self:printRequests()

    local TIMER = os.startTimer(1)

    while true do
        local event = { os.pullEvent() }
        if event[1] == "timer" and event[2] == TIMER then
            if self.isTimeToRun() then
                self.currentRun = self.currentRun - 1
                if self.currentRun <= 0 then
                    self:printRequests()
                    self.currentRun = self.timeBetweenRuns
                end
            else
                self.currentRun = 0
            end
            self:printHeader()
            TIMER = os.startTimer(1)
        elseif event[1] == "monitor_touch" then
            os.cancelTimer(TIMER)
            self:printRequests()
            if self.isTimeToRun() then
                self.currentRun = self.timeBetweenRuns
            else
                self.currentRun = 0
            end
            self:printHeader()
            TIMER = os.startTimer(1)
        end
    end
end

if DEBUG then
    debugCreatePeripheral()
end

local colonyQueue = ColonyBuildQueueData:new()
colonyQueue:init()

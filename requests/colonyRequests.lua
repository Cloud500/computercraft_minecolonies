local DEBUG = true
local SCALE = 0.5
local workspacePath = "C:\\Users\\chris\\IdeaProjects\\minecraft\\minecolony"

local colonyManager = nil
local monitor = nil

--- Debug function to create the peripherals
local function debugCreatePeripheral()
    periphemu.create("left", "monitor")
    mounter.mount("/lib", workspacePath .. "\\fakes", "ro")
    mounter.mount("/lib", workspacePath .. "\\apis", "ro")
    print(textutils.serialize(fs.list("/lib")))
    colonyManager = require("lib/fake_colony")
end

--- Class to get and show the colony requests
---@class ColonyData
---@field colonyDisplayManager ColonyDisplayManager
---@field colonyManager table
---@field colonyRequests table
---@field timeBetweenRuns number
---@field currentRun number
local ColonyRequestsData = {}
ColonyRequestsData.__index = ColonyRequestsData

--- Create a new ColonyRequestsData Object
---@return ColonyData ColonyRequestsData New ColonyRequestsData object
function ColonyRequestsData:new()
    ---@type ColonyData
    local o = {
        colonyDisplayManager = {},
        colonyManager = {},
        colonyRequests = {},
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
function ColonyRequestsData.loadMonitor()
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
function ColonyRequestsData.loadColonyManager()
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
---@return number cycle_color Cycle color
function ColonyRequestsData.getTimeCycle(currentTime)
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
function ColonyRequestsData:getRefreshTimeColor()
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
function ColonyRequestsData.isTimeToRun()
    local currentTime = os.time()
    if currentTime >= 5 and currentTime < 19.5 then
        return true
    end
    return false
end

--- Load the requests for the colony
function ColonyRequestsData:getRequests()
    self.colonyRequests = self.colonyManager.getRequests()
end

--- Print the requests to the monitor
function ColonyRequestsData:printRequests()
    self.colonyDisplayManager:clear()
    self:getRequests()
    self.colonyDisplayManager:print(3, "center", string.format("%d Requests", #self.colonyRequests))

    local currentRow = 4
    for requestNumber in pairs(self.colonyRequests) do
        local request = self.colonyRequests[requestNumber]
        self.colonyDisplayManager:print(currentRow, "center", request.name, colors.blue)
        currentRow = currentRow + 1
    end
end

function ColonyRequestsData:printHeader()
    local currentTime = os.time()
    local timeToRun = self.currentRun
    local isTimeToRun = self.isTimeToRun()
    local timeColor = self.getTimeCycle(currentTime)
    local refreshTimeColor = self:getRefreshTimeColor()
    local pauseColor = colors.red

    self.colonyDisplayManager:printHeader(currentTime, timeToRun, isTimeToRun, timeColor, refreshTimeColor, pauseColor)
end

--- Initializes the program
function ColonyRequestsData:init()
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

local colonyRequests = ColonyRequestsData:new()
colonyRequests:init()

local DEBUG = false
local SCALE = 0.5
local workspacePath = ""

local colonyManager = nil
local monitor = nil

local function debugCreatePeripheral()
    periphemu.create("left", "monitor")
    mounter.mount("/lib", workspacePath .. "\\fakes", "ro")
    mounter.mount("/lib", workspacePath .. "\\apis", "ro")
    print(textutils.serialize(fs.list("/lib")))
    colonyManager = require("lib/fake_colony")
end

---@class ColonyCitizenData
---@field colonyDisplayManager ColonyDisplayManager
---@field colonyManager table
---@field citizens number
---@field maxCitizens number
---@field unemployed number
---@field employed number
---@field military number
---@field knight number
---@field archer number
---@field druid number
---@field timeBetweenRuns number
---@field currentRun number
local ColonyCitizenData = {}
ColonyCitizenData.__index = ColonyCitizenData

---@return ColonyCitizenData ColonyCitizenData
function ColonyCitizenData:new()
    ---@type ColonyCitizenData
    local o = {
        colonyDisplayManager = {},
        colonyManager = {},
        citizens = 0,
        maxCitizens = 0,
        unemployed = 0,
        employed = 0,
        military = 0,
        knight = 0,
        archer = 0,
        druid = 0,
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
function ColonyCitizenData.loadMonitor()
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
function ColonyCitizenData.loadColonyManager()
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
function ColonyCitizenData.getTimeCycle(currentTime)
    local cycle = "day"
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
function ColonyCitizenData:getRefreshTimeColor()
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
function ColonyCitizenData.isTimeToRun()
    local currentTime = os.time()
    if currentTime >= 5 and currentTime < 19.5 then
        return true
    end
    return false
end


function ColonyCitizenData:getInfo()
    local infoData = self.colonyManager.getInfo()
    self.citizens = infoData.citizens
    self.maxCitizens = infoData.maxCitizens

end

function ColonyCitizenData:getCitizenJobs()
    local citizensData = self.colonyManager.getCitizens()
    self.unemployed = 0
    self.employed = 0
    self.knight = 0
    self.archer = 0
    self.druid = 0
    self.military = 0


    for citizenNumber in pairs(citizensData) do
        local job = citizensData[citizenNumber].job
        if job == nil then
            self.unemployed = self.unemployed + 1
        else
            self.employed = self.employed + 1
            if job == "Knight" then
                self.knight = self.knight + 1
                self.military = self.military + 1
            elseif job == "Archer" then
                self.archer = self.archer + 1
                self.military = self.military + 1
            elseif job == "Druid" then
                self.druid = self.druid + 1
                self.military = self.military + 1
            end
        end
    end
end


function ColonyCitizenData:getData()
    self:getInfo()
    self:getCitizenJobs()
end

function ColonyCitizenData:printData()
    self.colonyDisplayManager:clear()
    self:getData()

    local citizensString = string.format("Citizens:   %03d", self.citizens)
    local maxCitizensString = string.format("Max:        %03d", self.maxCitizens)
    local unemployedString = string.format("Unemployed: %03d", self.unemployed)
    local militaryString = string.format("Military:   %03d", self.military)
    local knightString = string.format("Knight:     %03d", self.knight)
    local archerString = string.format("Archer:     %03d", self.archer)
    local druidString = string.format("Druid:      %03d", self.druid)

    self.colonyDisplayManager:print(3, "center", citizensString, colors.white)
    self.colonyDisplayManager:print(4, "center", maxCitizensString, colors.blue)
    self.colonyDisplayManager:print(5, "center", unemployedString, colors.blue)

    self.colonyDisplayManager:print(7, "center", militaryString, colors.white)
    self.colonyDisplayManager:print(8, "center", knightString, colors.blue)
    self.colonyDisplayManager:print(9, "center", archerString, colors.blue)
    self.colonyDisplayManager:print(10, "center", druidString, colors.blue)
end

function ColonyCitizenData:printHeader()
    local currentTime = os.time()
    local timeToRun = self.currentRun
    local isTimeToRun = self.isTimeToRun()
    local timeColor = self.getTimeCycle(currentTime)
    local refreshTimeColor = self:getRefreshTimeColor()
    local pauseColor = colors.red

    self.colonyDisplayManager:printHeader(currentTime, timeToRun, isTimeToRun, timeColor, refreshTimeColor, pauseColor)

end

--- Initializes the program
function ColonyCitizenData:init()
    self.colonyDisplayManager:initMonitor()
    self.currentRun = self.timeBetweenRuns
    self:printHeader()
    self:printData()

    local TIMER = os.startTimer(1)

    while true do
        local event = { os.pullEvent() }
        if event[1] == "timer" and event[2] == TIMER then
            if self.isTimeToRun() then
                self.currentRun = self.currentRun - 1
                if self.currentRun <= 0 then
                    self:printData()
                    self.currentRun = self.timeBetweenRuns
                end
            else
                self.currentRun = 0
            end
            self:printHeader()
            TIMER = os.startTimer(1)
        elseif event[1] == "monitor_touch" then
            os.cancelTimer(TIMER)
            self:printData()
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

local colonyData = ColonyCitizenData:new()
colonyData:init()
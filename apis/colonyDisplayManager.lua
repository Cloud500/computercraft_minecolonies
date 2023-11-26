---@alias CCMonitor {clear: fun(), clearLine: fun(), setCursorPos: fun(number, number), setTextScale: fun(number), setCursorBlink: fun(boolean), getSize: fun():(number, number), getTextColor: fun():(number), getBackgroundColor: fun():(number), setTextColor: fun(number), setBackgroundColor: fun(number), write: fun(string)}


---@class ColonyDisplayManager
---@field monitor CCMonitor
---@field scale number
local ColonyDisplayManager = {}
ColonyDisplayManager.__index = ColonyDisplayManager


---@param monitor CCMonitor Monitor to show Data
---@param scale number | nil Sale of the Text, 0.5 default
---@return ColonyDisplayManager ColonyDisplayManager New ColonyDisplayManager object
function ColonyDisplayManager:new(monitor, scale)
    if scale == nil then
        scale = 0.5
    end

    ---@type ColonyDisplayManager
    local o = {
        monitor = monitor,
        scale = scale
    }
    setmetatable(o, self)

    return o
end

function ColonyDisplayManager:initMonitor()
    self.monitor.setTextScale(self.scale)
    self:clear()
    self.monitor.setCursorPos(1, 1)
    self.monitor.setCursorBlink(false)
    print("Monitor initialized.")
end

function ColonyDisplayManager:clear()
    self.monitor.clear()
end

--- Print text to monitor
---@param row number Row to display the text
---@param position string left, center or right
---@param text string Text to Display
---@param textColor number | nil Text color default: current color
---@param backgroundColor number | nil Background color default: current color
function ColonyDisplayManager:print(row, position, text, textColor, backgroundColor)
    local column = 0
    local width, height = self.monitor.getSize()
    local oldTextColor = self.monitor.getTextColor()
    local oldBackgroundColor = self.monitor.getBackgroundColor()

    textColor = textColor or self.monitor.getTextColor()
    backgroundColor = backgroundColor or self.monitor.getBackgroundColor()

    if position == "left" then column = 1 end
    if position == "center" then column = math.floor((width - #text) / 2) end
    if position == "right" then column = width - #text end

    self.monitor.setCursorPos(column, row)
    -- self.monitor.clearLine()
    -- self.monitor.setCursorPos(column, row)
    self.monitor.setTextColor(textColor)
    self.monitor.setBackgroundColor(backgroundColor)
    self.monitor.write(text)
    self.monitor.setTextColor(oldTextColor)
    self.monitor.setBackgroundColor(oldBackgroundColor)
end

--- Print the current time an the refresh time on the monitor
function ColonyDisplayManager:printHeader(currentTime, timeToRun, isTimeToRun, timeColor, refreshTimeColor, pauseColor)
    local timeString = string.format("%s", textutils.formatTime(currentTime, true))
    local refreshString = "Remaining"

    if isPaused == nil then
        isPaused = false
    end
    if timeColor == nil then
        timeColor = colors.white
    end
    if refreshTimeColor == nil then
        refreshTimeColor = colors.white
    end
    if pauseColor == nil then
        pauseColor = colors.red
    end

    self:print(1, "left", timeString, timeColor)

    if isTimeToRun then
        self:print(1, "right", string.format("%s: %02d", refreshString, timeToRun), refreshTimeColor)
    else
        self:print(1, "right", string.format("%s: %s", refreshString, "Paused"), pauseColor)
    end
end

return ColonyDisplayManager
---@class Logger
---@field active boolean
---@field file string
---@field level integer
---@field column integer
---@field printTerminal boolean
local Logger = {}
Logger.__index = Logger

---@param file string
---@return Logger Logger New Logger object
function Logger:new(file, level, printTerminal, enabled)
    ---@type Logger
    local o = {
        active = enabled,
        file = file,
        level = level,
        printTerminal = printTerminal,
        column = 0
    }
    setmetatable(o, self)

    if o.printTerminal and o.active then
        term.clear()
        term.setCursorPos(1, 1)
    end

    return o
end

function Logger.getColors(level)
    if level == 1 then
        return colors.red, nil
    elseif level == 2 then
        return colors.orange, nil
    elseif level == 3 then
        return colors.yellow, nil
    elseif level == 4 then
        return colors.white, nil
    elseif level >= 5 then
        return colors.gray, nil
    end
end

function Logger.levelToString(level)
    if level == 1 then
        return "CRITICAL"
    elseif level == 2 then
        return "ERROR"
    elseif level == 3 then
        return "WARNING"
    elseif level == 4 then
        return "INFO"
    elseif level >= 5 then
        return "DEBUG"
    end
end

function Logger.getTimeDate(short)
    if short == nil then
        short = false
    end

    local time = os.time()
    local daysTmp = os.day()
    local dateTimeString = ""

    local formattedTime = textutils.formatTime(time, true)
    if string.len(formattedTime) == 4 then
        formattedTime = "0" .. formattedTime
    end

    if short then
        dateTimeString = string.format("%s", formattedTime)
    else
        local year = math.ceil(daysTmp / 360)
        daysTmp = daysTmp - ((year - 1) * 360)

        local month = math.ceil(daysTmp / 30)
        daysTmp = daysTmp - ((month - 1) * 30)
        local days = daysTmp

        dateTimeString = string.format("%02d.%02d.%04d %s", days, month, year, formattedTime)
    end



    return dateTimeString
end

function Logger:logFile(msg, level)
    local dateTime = self.getTimeDate()
    local levelString = self.levelToString(level)

    local logString = dateTime .. " - " .. levelString .. " - " .. msg

    local file = fs.open(self.file, fs.exists(self.file) and "a" or "w")
    file.writeLine(logString)
    file.close()
end

function Logger:logTerminal(msg, level)
    local oldTextColor = term.getTextColor()
    local oldBackgroundColor = term.getBackgroundColor()

    local dateTime = self.getTimeDate(true)
    local textColor, backgroundColor = self.getColors(level)

    local logString = dateTime .. " - " .. msg

    term.setTextColor(textColor)
    if backgroundColor ~= nil then
        term.setBackgroundColor(backgroundColor)
    end
    print(logString)
    term.setTextColor(oldTextColor)
    term.setBackgroundColor(oldBackgroundColor)
    self.column = self.column + 1
end

function Logger:log(msg, level)
    if level <= self.level and self.active then
        self:logFile(msg, level)
        if self.printTerminal then
            self:logTerminal(msg, level)
        end
    end
end

function Logger:logCritical(msg)
    self:log(msg, 1)
end

function Logger:logError(msg)
    self:log(msg, 2)
end

function Logger:logWarning(msg)
    self:log(msg, 3)
end

function Logger:logInfo(msg)
    self:log(msg, 4)
end

function Logger:logDebug(msg)
    self:log(msg, 5)
end

return Logger

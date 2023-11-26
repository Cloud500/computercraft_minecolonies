local FakeColony = {}

function FakeColony.getRequests()
    local requests = {}

    for i = 1, math.random(1, 5) do
        table.insert(requests, { name = string.format("Test %02d", math.random(1, 99)) })
    end

    return requests
end

function FakeColony.getInfo()
    local maxCitizens = math.random(1, 999)

    return {
        maxCitizens = maxCitizens,
        citizens = math.random(1, maxCitizens - 10)

    }
end

function FakeColony.getCitizens()
    local citizens = {}
    local jobs = {
        "Knight",
        "Archer",
        "Druid",
        "Job 1",
        "Job 2",
        "Job 3",
        "Job 4",
        "Job 5",
    }

    local jobCount = math.random(1, 500)
    local unemployed = math.random(1, 50)

    for i = 1, jobCount do
        table.insert(citizens, { job = jobs[math.random(#jobs)] })
    end

    for i = 1, unemployed do
        table.insert(citizens, { job = nil })
    end

    return citizens
end

function FakeColony.getWorkOrders()
    local orders = {}

    local types = {
        "decoration",
        "miner",
        "type 1",
        "type 2",
        "type 3",
    }

    local level = math.random(0, 4)
    local nextLevel = level + 1

    for i = 1, math.random(1, 5) do
        table.insert(orders, {
            id = math.random(1, 500),
            translationKey = string.format("Test_%02d", math.random(1, 99)),
            requested = math.random(0, 1),
            amountOfResources = math.random(100, 200),
            type = types[math.random(#types)],
            currentLevel = level,
            targetLevel = nextLevel
        })
    end

    return orders

end

function FakeColony.getWorkOrderResources(orderID)
    local resources = {}

    for i = 1, math.random(1, 5) do
        table.insert(resources, {
            available = math.random(0, 100),
            item = {
                count = math.random(0, 100)
            }
        })
    end

    return resources
end


return FakeColony

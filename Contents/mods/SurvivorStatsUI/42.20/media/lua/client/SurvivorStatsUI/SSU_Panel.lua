require "ISUI/ISPanel"
require "ISUI/ISResizeWidget"
require "ISUI/ISContextMenu"
require "SurvivorStatsUI/SSU_Style"

SSU_Panel = ISPanel:derive("SSU_Panel")

local CONFIG_FILE = "SurvivorStatsUI.ini"
local EXPANDED_HEIGHT = 197
local COLLAPSED_HEIGHT = 28
local MIN_WIDTH = 220
local MIN_HEIGHT = 156
local MAX_WIDTH = 520
local MAX_HEIGHT = 320
local ICON_PATH = "media/ui/SurvivorStatsUI/"
local ICONS = {
    days = getTexture(ICON_PATH .. "days.png"),
    kills = getTexture(ICON_PATH .. "kills.png"),
    distance = getTexture(ICON_PATH .. "distance.png"),
    weight = getTexture(ICON_PATH .. "weight.png"),
    time = getTexture(ICON_PATH .. "time.png"),
}

local VISIBILITY_OPTIONS = {
    { key = "days", label = "Dia sobrevivido" },
    { key = "totalKills", label = "Zumbis abatidos" },
    { key = "dailyKills", label = "Zumbis mortos hoje" },
    { key = "killRate", label = "Taxa de abates por dia" },
    { key = "distance", label = "Distancia percorrida" },
    { key = "weight", label = "Peso corporal" },
    { key = "playTime", label = "Tempo de jogo" },
    { key = "dayProgress", label = "Barra de progresso do dia" },
}

local THEME_OPTIONS = {
    { key = "verde", label = "Verde" },
    { key = "laranja", label = "Laranja" },
    { key = "azul", label = "Azul" },
    { key = "vermelho", label = "Vermelho" },
    { key = "roxo", label = "Roxo" },
}

local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
end

local function gameplayIsPaused()
    local pauseScreen = type(MainScreen) == "table" and MainScreen.instance or nil
    if pauseScreen and pauseScreen.inGame == true then
        if pauseScreen.getIsVisible then
            local ok, visible = pcall(function() return pauseScreen:getIsVisible() end)
            if ok and visible then return true end
        elseif pauseScreen.isVisible then
            local ok, visible = pcall(function() return pauseScreen:isVisible() end)
            if ok and visible then return true end
        end
    end
    if type(isGamePaused) == "function" then
        local ok, paused = pcall(isGamePaused)
        if ok and paused then return true end
    end
    if type(getGameSpeed) == "function" then
        local ok, speed = pcall(getGameSpeed)
        if ok and tonumber(speed) and tonumber(speed) <= 0 then return true end
    end
    return false
end

local function getLiveWeightTrend(nutrition)
    if not nutrition then return 0, false end

    local hasTrendAPI = nutrition.isIncWeightLot or nutrition.isIncWeight or nutrition.isDecWeight
    if not hasTrendAPI then return 0, false end

    if nutrition.isIncWeightLot then
        local ok, active = pcall(function() return nutrition:isIncWeightLot() end)
        if ok and active then return 1, true end
    end
    if nutrition.isIncWeight then
        local ok, active = pcall(function() return nutrition:isIncWeight() end)
        if ok and active then return 1, true end
    end
    if nutrition.isDecWeight then
        local ok, active = pcall(function() return nutrition:isDecWeight() end)
        if ok and active then return -1, true end
    end

    return 0, true
end

function SSU_Panel:new(playerIndex, player)
    local width = 264
    local x = getCore():getScreenWidth() - width - 28
    local o = ISPanel:new(x, 160, width, EXPANDED_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex
    o.player = player
    o.moveWithMouse = true
    o.background = false
    o.borderColor.a = 0
    o.collapsed = false
    o.distance = 0
    o.lastX = nil
    o.lastY = nil
    o.headerHeight = COLLAPSED_HEIGHT
    o.expandedWidth = width
    o.expandedHeight = EXPANDED_HEIGHT
    o.minimumWidth = MIN_WIDTH
    o.minimumHeight = MIN_HEIGHT
    o.theme = "verde"
    o.visibleStats = {
        days = true,
        totalKills = true,
        dailyKills = true,
        killRate = true,
        distance = true,
        weight = true,
        playTime = true,
        dayProgress = true,
    }
    return o
end

function SSU_Panel:initialise()
    ISPanel.initialise(self)
    self:readConfig()
end

function SSU_Panel:createChildren()
    ISPanel.createChildren(self)
    local size = 13
    local widget = ISResizeWidget:new(self.width - size, self.height - size, size, size, self)
    widget.anchorLeft = false
    widget.anchorRight = true
    widget.anchorTop = false
    widget.anchorBottom = true
    widget:initialise()
    widget:setVisible(not self.collapsed)
    self:addChild(widget)
    self.resizeWidget = widget
end

function SSU_Panel:getPlayer()
    return self.player
end

function SSU_Panel:setPlayer(playerIndex, player)
    self.playerIndex = playerIndex
    self.player = player
    self.lastX = nil
    self.lastY = nil
end

function SSU_Panel:getCharacterData()
    if not self.player then return nil end
    local root = self.player:getModData()
    root.SurvivorStatsUI = root.SurvivorStatsUI or {
        distance = 0,
        playSeconds = 0,
        lastWeight = nil,
        weightTrend = 0,
        dailyKillBaseline = nil,
        dailyKillVersion = 2,
    }
    return root.SurvivorStatsUI
end

function SSU_Panel:resetDailyKills()
    if not self.player then return end
    local data = self:getCharacterData()
    if not data then return end
    data.dailyKillBaseline = math.max(0, tonumber(self.player:getZombieKills()) or 0)
    data.dailyKillVersion = 2
end

function SSU_Panel:setCollapsed(value)
    if value == true and not self.collapsed then
        self.expandedWidth = self.width
        self.expandedHeight = self.height
    end
    self.collapsed = value == true
    if self.collapsed then
        self:setHeight(COLLAPSED_HEIGHT)
    else
        self:setWidth(clamp(self.expandedWidth or self.width, MIN_WIDTH, MAX_WIDTH))
        self:setHeight(clamp(self.expandedHeight or EXPANDED_HEIGHT, MIN_HEIGHT, MAX_HEIGHT))
    end
    if self.resizeWidget then self.resizeWidget:setVisible(not self.collapsed) end
    self:writeConfig()
end

function SSU_Panel:onMouseDown(x, y)
    if x >= self.width - 31 and y <= self.headerHeight then
        self:setCollapsed(not self.collapsed)
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

function SSU_Panel:onMouseUp(x, y)
    local result = ISPanel.onMouseUp(self, x, y)
    self:keepOnScreen()
    self:writeConfig()
    return result
end

function SSU_Panel:toggleVisibility(key)
    if self.visibleStats[key] == nil then return end
    self.visibleStats[key] = not self.visibleStats[key]
    self:writeConfig()
end

function SSU_Panel:selectTheme(theme)
    if not SSU_Style.themes[theme] then return end
    self.theme = theme
    SSU_Style.setTheme(theme)
    self:writeConfig()
end

function SSU_Panel:onRightMouseUp(x, y)
    if not self:isMouseOver() then return false end

    local context = ISContextMenu.get(self.playerIndex or 0, getMouseX(), getMouseY())

    local visibilityOption = context:addOption("Estatisticas visiveis", nil)
    local visibilityMenu = ISContextMenu:getNew(context)
    context:addSubMenu(visibilityOption, visibilityMenu)
    for _, definition in ipairs(VISIBILITY_OPTIONS) do
        local option = visibilityMenu:addOption(definition.label, self, SSU_Panel.toggleVisibility, definition.key)
        option.tick = self.visibleStats[definition.key] == true
    end

    local colorOption = context:addOption("Cores do painel", nil)
    local colorMenu = ISContextMenu:getNew(context)
    context:addSubMenu(colorOption, colorMenu)
    for _, definition in ipairs(THEME_OPTIONS) do
        local option = colorMenu:addOption(definition.label, self, SSU_Panel.selectTheme, definition.key)
        option.tick = self.theme == definition.key
    end

    return true
end

function SSU_Panel:keepOnScreen()
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    self:setX(clamp(self:getX(), 0, math.max(0, sw - self.width)))
    self:setY(clamp(self:getY(), 0, math.max(0, sh - self.height)))
end

function SSU_Panel:update()
    ISPanel.update(self)
    local now = getTimestampMs()
    if self._playLastMs then
        local elapsed = math.max(0, now - self._playLastMs)
        if elapsed <= 5000 and not gameplayIsPaused() then
            local data = self:getCharacterData()
            if data then
                data.playSeconds = math.max(0, tonumber(data.playSeconds) or 0) + (elapsed / 1000)
            end
        end
    end
    self._playLastMs = now

    if self.collapsed then return end

    local width = clamp(self.width, MIN_WIDTH, math.min(MAX_WIDTH, getCore():getScreenWidth()))
    local height = clamp(self.height, MIN_HEIGHT, math.min(MAX_HEIGHT, getCore():getScreenHeight()))
    if width ~= self.width then self:setWidth(width) end
    if height ~= self.height then self:setHeight(height) end

    if width ~= self._lastWidth or height ~= self._lastHeight then
        self._lastWidth = width
        self._lastHeight = height
        self.expandedWidth = width
        self.expandedHeight = height
        self._saveSizeAt = getTimestampMs() + 500
    elseif self._saveSizeAt and getTimestampMs() >= self._saveSizeAt then
        self._saveSizeAt = nil
        self:writeConfig()
    end
end

function SSU_Panel:addMovementSample()
    if not self.player then return end
    local x, y = self.player:getX(), self.player:getY()
    if self.lastX then
        local dx, dy = x - self.lastX, y - self.lastY
        local delta = math.sqrt(dx * dx + dy * dy)
        if delta <= 4 then
            local data = self:getCharacterData()
            if data then
                data.distance = math.max(0, tonumber(data.distance) or 0) + delta
                self.distance = data.distance
            end
        end
    end
    self.lastX, self.lastY = x, y
end

function SSU_Panel:getRows()
    local player = self.player
    if not player then return {} end
    local data = self:getCharacterData()
    self.distance = data and math.max(0, tonumber(data.distance) or 0) or 0
    local hours = math.max(0, tonumber(player:getHoursSurvived()) or 0)
    local timeOfDay = tonumber(getGameTime():getTimeOfDay()) or 0
    local playSeconds = math.max(0, math.floor(tonumber(data and data.playSeconds) or 0))
    local playHours = math.floor(playSeconds / 3600)
    local playMinutes = math.floor((playSeconds % 3600) / 60)
    local playRemainingSeconds = playSeconds % 60
    local nutrition = player:getNutrition()
    local weight = nutrition and nutrition:getWeight() or 0
    local liveWeightTrend, hasLiveTrend = getLiveWeightTrend(nutrition)
    local totalKills = math.max(0, tonumber(player:getZombieKills()) or 0)
    local dailyKills = 0
    if data then
        -- Versao 2 usa Events.EveryDays: a virada ocorre a meia-noite,
        -- inclusive quando o relogio avanca rapidamente durante o sono.
        if tonumber(data.dailyKillVersion) ~= 2 then
            data.dailyKillBaseline = totalKills
            data.dailyKillVersion = 2
        elseif data.dailyKillBaseline == nil then
            data.dailyKillBaseline = totalKills
        end
        dailyKills = math.max(0, totalKills - (tonumber(data.dailyKillBaseline) or totalKills))

        if hasLiveTrend then
            data.weightTrend = liveWeightTrend
        else
            local previousWeight = tonumber(data.lastWeight)
            if previousWeight then
                local difference = weight - previousWeight
                if difference >= 0.01 then
                    data.weightTrend = 1
                    data.lastWeight = weight
                elseif difference <= -0.01 then
                    data.weightTrend = -1
                    data.lastWeight = weight
                end
            else
                data.lastWeight = weight
            end
        end
    end
    local elapsedDayHours = math.max(timeOfDay, 1 / 60)
    local killRate = dailyKills * 24 / elapsedDayHours
    local rows = {}
    if self.visibleStats.totalKills then
        table.insert(rows, { "Zumbis abatidos", tostring(totalKills), ICONS.kills })
    end
    if self.visibleStats.dailyKills then
        table.insert(rows, { "Zumbis mortos hoje", tostring(dailyKills), ICONS.kills })
    end
    if self.visibleStats.killRate then
        table.insert(rows, { "Taxa de abates/dia", string.format("%.1f", killRate), ICONS.kills })
    end
    if self.visibleStats.distance then
        table.insert(rows, { "Distancia percorrida", string.format("%.2f km", self.distance / 1000), ICONS.distance })
    end
    if self.visibleStats.weight then
        table.insert(rows, { "Peso corporal", string.format("%.1f kg", weight), ICONS.weight, data and tonumber(data.weightTrend) or 0 })
    end
    if self.visibleStats.playTime then
        table.insert(rows, { "Tempo de jogo", string.format("%02d:%02d:%02d", playHours, playMinutes, playRemainingSeconds), ICONS.time })
    end
    return rows, math.floor(hours / 24), timeOfDay / 24
end

function SSU_Panel:prerender()
    SSU_Style.drawWindow(self, self.width, self.height, self.headerHeight)
    local c = SSU_Style.colors
    local rows, survivedDays, dayProgress = self:getRows()
    local titleY = math.floor((self.headerHeight - getTextManager():getFontHeight(UIFont.Small)) / 2)
    if self.visibleStats.days and ICONS.days then self:drawTextureScaled(ICONS.days, 6, 4, 20, 20, 1, 1, 1, 1) end
    local titleX = self.visibleStats.days and 31 or 10
    self:drawText("ESTATISTICAS", titleX, titleY, c.text.r, c.text.g, c.text.b, 1, UIFont.Small)
    if self.visibleStats.days then
        self:drawTextRight("DIA " .. tostring(survivedDays or 0), self.width - 29, titleY, c.dim.r, c.dim.g, c.dim.b, 1, UIFont.Small)
    end
    self:drawTextCentre(self.collapsed and "+" or "-", self.width - 13, titleY - 1, c.accent.r, c.accent.g, c.accent.b, 1, UIFont.Medium)
    if self.collapsed then return end
    local top = self.headerHeight + 5
    local barY = self.visibleStats.dayProgress and (self.height - 14) or (self.height - 5)
    local rowH = math.max(18, math.floor((barY - top - 3) / math.max(1, #rows)))
    local iconSize = math.max(14, math.min(24, rowH - 6))
    for i, row in ipairs(rows) do
        local y = top + (i - 1) * rowH
        SSU_Style.drawRow(self, 6, y, self.width - 12, rowH - 1, i % 2 == 0)
        if row[3] then
            self:drawTextureScaled(row[3], 10, y + math.floor((rowH - iconSize) / 2), iconSize, iconSize, 1, 1, 1, 1)
        end
        local textY = y + math.floor((rowH - getTextManager():getFontHeight(UIFont.Small)) / 2) - 1
        self:drawText(row[1], 15 + iconSize, textY, c.dim.r, c.dim.g, c.dim.b, 1, UIFont.Small)
        if row[4] == 1 or row[4] == -1 then
            local valueWidth = getTextManager():MeasureStringX(UIFont.Small, row[2])
            SSU_Style.drawTrendArrow(self, self.width - 18 - valueWidth, y + math.floor((rowH - 11) / 2), row[4])
        end
        self:drawTextRight(row[2], self.width - 10, textY, c.text.r, c.text.g, c.text.b, 1, UIFont.Small)
    end
    if self.visibleStats.dayProgress then
        SSU_Style.drawProgressBar(self, 7, self.height - 14, self.width - 14, 8, dayProgress)
    end
end

function SSU_Panel:readConfig()
    local reader = getFileReader(CONFIG_FILE, false)
    if not reader then return end
    local values = {}
    local line = reader:readLine()
    while line do
        local key, value = string.match(line, "^([^=]+)=(.*)$")
        if key then values[key] = value end
        line = reader:readLine()
    end
    reader:close()
    self:setX(tonumber(values.x) or self:getX())
    self:setY(tonumber(values.y) or self:getY())
    self.expandedWidth = clamp(tonumber(values.width) or self.width, MIN_WIDTH, MAX_WIDTH)
    self.expandedHeight = clamp(tonumber(values.height) or EXPANDED_HEIGHT, MIN_HEIGHT, MAX_HEIGHT)
    self:setWidth(self.expandedWidth)
    self.collapsed = values.collapsed == "true"
    self.theme = SSU_Style.themes[values.theme] and values.theme or "verde"
    SSU_Style.setTheme(self.theme)
    for _, definition in ipairs(VISIBILITY_OPTIONS) do
        local stored = values["show_" .. definition.key]
        if stored ~= nil then self.visibleStats[definition.key] = stored == "true" end
    end
    self:setHeight(self.collapsed and COLLAPSED_HEIGHT or self.expandedHeight)
    self:keepOnScreen()
end

function SSU_Panel:writeConfig()
    local writer = getFileWriter(CONFIG_FILE, true, false)
    if not writer then return end
    writer:write("x=" .. tostring(math.floor(self:getX())) .. "\n")
    writer:write("y=" .. tostring(math.floor(self:getY())) .. "\n")
    writer:write("width=" .. tostring(math.floor(self.expandedWidth or self.width)) .. "\n")
    writer:write("height=" .. tostring(math.floor(self.expandedHeight or EXPANDED_HEIGHT)) .. "\n")
    writer:write("collapsed=" .. tostring(self.collapsed) .. "\n")
    writer:write("theme=" .. tostring(self.theme or "verde") .. "\n")
    for _, definition in ipairs(VISIBILITY_OPTIONS) do
        writer:write("show_" .. definition.key .. "=" .. tostring(self.visibleStats[definition.key] == true) .. "\n")
    end
    writer:close()
end

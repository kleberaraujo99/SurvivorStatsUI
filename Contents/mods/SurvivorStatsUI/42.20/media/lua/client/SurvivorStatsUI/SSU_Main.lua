require "SurvivorStatsUI/SSU_Panel"

SurvivorStatsUI = SurvivorStatsUI or {}
local panel = nil

local function onCreatePlayer(playerIndex, player)
    if panel then
        panel:setPlayer(playerIndex, player)
        return
    end
    panel = SSU_Panel:new(playerIndex, player)
    panel:initialise()
    panel:instantiate()
    panel:addToUIManager()
    SurvivorStatsUI.panel = panel
end

local function onPlayerMove(player)
    if panel and player == panel:getPlayer() then panel:addMovementSample() end
end

local function onSave()
    if panel then panel:writeConfig() end
end

local function onNewDay()
    if panel then panel:resetDailyKills() end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerMove.Add(onPlayerMove)
Events.OnSave.Add(onSave)
Events.EveryDays.Add(onNewDay)

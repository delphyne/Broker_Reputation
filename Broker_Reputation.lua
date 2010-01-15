local Factions = CreateFrame("Frame", "Broker_Reputation")
local FactionsMenu = CreateFrame("Frame", "FactionsMenu")

local rep_starting_value
local gender = UnitSex("player")

Factions.obj = LibStub("LibDataBroker-1.1"):NewDataObject("Broker_Reputation", {
	type = "data source",
	icon = "Interface\\WorldMap\\WorldMapPartyIcon",
	label = "Factions"
	}
)

-- converts floating point color components into their hex equivalent
-- example: 0.8 --> CD
local function colorFloatToHex(f)
    return string.format("%2x", floor(f * 256 + .5))
end

-- colors the text parameter using the stock UI colors for the rep
-- level provided
local function colorize(text, standingID)
    local color = FACTION_BAR_COLORS[standingID]
    if color then
        local r = colorFloatToHex(color.r)
        local g = colorFloatToHex(color.g)
        local b = colorFloatToHex(color.b)
        return "|cff" .. r .. g .. b .. text .. "|r"
    end
end

-- constructs the text to be displayed
local function getLabelText(name, standingID, barMin, barMax, barValue, full)
    local labelText = ""
    if name then
        if Broker_ReputationDB.show_faction_name or full then
            labelText = labelText .. name .. ": "
        end
        
        local current = barValue - barMin
        local goal = barMax - barMin
        
        if Broker_ReputationDB.show_rep_value or full then
            local calculated_text = current .. "/" .. goal
            if Broker_ReputationDB.show_colors or full then
                labelText = labelText .. colorize(calculated_text, standingID)
            else
                labelText = labelText .. calculated_text
            end
        end
        
        if Broker_ReputationDB.show_percentage or full then
           labelText = labelText .. " (" .. floor(((current / goal) + .005) * 100) .. "%)"
        end
        
        if Broker_ReputationDB.show_rep_level or full then
            calculated_text = " " .. GetText("FACTION_STANDING_LABEL" .. standingID, gender)
            if Broker_ReputationDB.show_colors or full then
                labelText = labelText .. colorize(calculated_text, standingID)
            else
                labelText = labelText .. calculated_text
            end
        end
        
        if Broker_ReputationDB.show_difference or full then
            local diff = barValue - rep_starting_value
            labelText = labelText .. " "
            if diff >= 0 then
                labelText = labelText .. "+"
            end
                
            labelText = labelText .. diff
        end
            
    else
        labelText = "Broker: Reputation"
    end
    return labelText
end

-- updates the label text
local function update()
    local name, standingID, barMin, barMax, barValue = GetWatchedFactionInfo()
    Factions.obj.text = getLabelText(name, standingID, barMin, barMax, barValue)
end

-- even handler, initializes the Saved Variables to defaults if they do not yet exist
-- and initializes the rep display to the currently watched faction on login
local function handleFactionEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "Broker_Reputation" then
            if Broker_ReputationDB == nil then
                Broker_ReputationDB = {
                    show_faction_name = true,
                    show_rep_value = true,
                    show_percentage = true,
                    show_rep_level = true,
                    show_difference = true,
                    show_colors = true
                }
            end
        end
    else 
        if event == "PLAYER_LOGIN" then
            local name, standingID, barMin, barMax, barValue = GetWatchedFactionInfo()
            rep_starting_value = barValue
        end
        update()
    end
end

-- mouse handler to show popup
function Factions.obj.OnClick(frame, button)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, FactionsMenu, frame)
	elseif button == "LeftButton" then
	    ToggleCharacter("ReputationFrame")
	end
end

function Factions.obj.OnTooltipShow(tip)
	if not tip or not tip.AddLine then return end
	
	local name, standingID, barMin, barMax, barValue = GetWatchedFactionInfo()
	local labelText = getLabelText(name, standingID, barMin, barMax, barValue, true)
	tip:AddLine(labelText)
end

FactionsMenu.displayMode = "MENU"
local info = {}
FactionsMenu.initialize = function(self, level) 
    if not level then 
        return 
    end
    
    wipe(info)
    if level == 1 then
        info.isTitle = 1
        info.text = "Broker: Reputation"
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info, level)
       
        info.disabled = nil
        info.isTitle = nil
        info.notCheckable = nil
       
        info.text = "Faction name"
        info.func = function()
            Broker_ReputationDB.show_faction_name = not Broker_ReputationDB.show_faction_name
            update()
        end
        info.checked = Broker_ReputationDB.show_faction_name
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Numbers"
        info.func = function()
            Broker_ReputationDB.show_rep_value = not Broker_ReputationDB.show_rep_value
            update()
        end
        info.checked = Broker_ReputationDB.show_rep_value
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Percentage"
        info.func = function()
            Broker_ReputationDB.show_percentage = not Broker_ReputationDB.show_percentage
            update()
        end
        info.checked = Broker_ReputationDB.show_percentage
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Reputation Level"
        info.func = function()
            Broker_ReputationDB.show_rep_level = not Broker_ReputationDB.show_rep_level
            update()
        end
        info.checked = Broker_ReputationDB.show_rep_level
        UIDropDownMenu_AddButton(info, level)
        
        info.text = "Show Gain/Loss"
        info.func = function()
            Broker_ReputationDB.show_difference = not Broker_ReputationDB.show_difference
            update()
        end
        info.checked = Broker_ReputationDB.show_difference
        UIDropDownMenu_AddButton(info, level)
    end
end

Factions:SetScript("OnEvent", handleFactionEvent)
Factions:RegisterEvent("UPDATE_FACTION")
Factions:RegisterEvent("PLAYER_LOGIN")
Factions:RegisterEvent("ADDON_LOADED")

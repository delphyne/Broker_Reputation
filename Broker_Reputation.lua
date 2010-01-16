local Factions = CreateFrame("Frame", "Broker_Reputation")
local FactionsMenu = CreateFrame("Frame", "FactionsMenu")

local rep_starting_value = 0
local init_done = false
local last_faction = nil
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
        if Broker_ReputationDB["Show Faction Name"] or full then
            labelText = labelText .. name .. ": "
        end
        
        local current = barValue - barMin
        local goal = barMax - barMin
        
        if Broker_ReputationDB["Show Progress"] or full then
            local calculated_text = current .. "/" .. goal
            if Broker_ReputationDB["Use Color"] or full then
                labelText = labelText .. colorize(calculated_text, standingID)
            else
                labelText = labelText .. calculated_text
            end
        end
        
        if Broker_ReputationDB["Show Percentage"] or full then
           labelText = labelText .. " (" .. floor(((current / goal) + .005) * 100) .. "%)"
        end
        
        if Broker_ReputationDB["Show Standing"] or full then
            calculated_text = " " .. GetText("FACTION_STANDING_LABEL" .. standingID, gender)
            if Broker_ReputationDB["Use Color"] or full then
                labelText = labelText .. colorize(calculated_text, standingID)
            else
                labelText = labelText .. calculated_text
            end
        end
        
        if Broker_ReputationDB["Show Gains/Losses"] or full then
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
    
    if not (name == last_faction) then
        rep_starting_value = barValue
        last_faction = name
    end

    Factions.obj.text = getLabelText(name, standingID, barMin, barMax, barValue)
end

-- even handler, initializes the Saved Variables to defaults if they do not yet exist
-- and initializes the rep display to the currently watched faction on login
local function handleFactionEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "Broker_Reputation" then
            if Broker_ReputationDB == nil then
                Broker_ReputationDB = {
                    ["Show Faction Name"] = true,
                    ["Show Progress"] = true,
                    ["Show Percentage"] = true,
                    ["Show Standing"] = true,
                    ["Show Gains/Losses"] = true,
                    ["Use Color"] = true
                }
            end
        end
    else
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
        
        -- build a menu item for each option
        for k,v in pairs(Broker_ReputationDB) do
            info.text = k
            info.func = function()
                Broker_ReputationDB[k] = not Broker_ReputationDB[k]
                update()
            end
            info.checked = Broker_ReputationDB[k]
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

Factions:SetScript("OnEvent", handleFactionEvent)
Factions:RegisterEvent("UPDATE_FACTION")
Factions:RegisterEvent("ADDON_LOADED")

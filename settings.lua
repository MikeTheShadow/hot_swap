local DISPLAY = require("hot_swap/display")
local SETTINGS = {}
local SettingsCanvas
local shown = false

local function is_empty_or_whitespace(str)
    return str == nil or str:match("^%s*$") ~= nil
end

local function addCreationButtons(x, y, settings)
    local name_input = W_CTRL.CreateEdit("nameEditbox", SettingsCanvas)
    name_input:AddAnchor("TOPLEFT", SettingsCanvas, x, y)
    name_input:SetExtent(150, 30)
    name_input:SetMaxTextLength(64)
    name_input:CreateGuideText("Enter Set Name")
    name_input:Show(true)
    local add_button = SettingsCanvas:CreateChildWidget("button","add_button", 0, true)
    add_button:Show(true)
    add_button:AddAnchor("TOPLEFT", SettingsCanvas, x, y + 40)
    add_button:SetText("Add")
    api.Interface:ApplyButtonSkin(add_button, BUTTON_BASIC.DEFAULT)
    local remove_button = SettingsCanvas:CreateChildWidget("button","add_button", 0, true)
    remove_button:Show(true)
    remove_button:AddAnchor("TOPLEFT", SettingsCanvas, x, y + 80)
    remove_button:SetText("Remove")
    api.Interface:ApplyButtonSkin(remove_button, BUTTON_BASIC.DEFAULT)
    if settings.show_creation_window ~= true then
        name_input:Show(false)
        add_button:Show(false)
        remove_button:Show(false)
    end
    add_button:SetHandler("OnClick", function()
        selected_name = name_input:GetText()
        if is_empty_or_whitespace(selected_name) then
            return
        end
        local items = {}
        local gear_pieces = {1, 3, 4, 8, 6, 9, 5, 7, 15, 2, 10, 11, 12, 13, 16, 17, 18, 19, 28}
        for _, i in ipairs(gear_pieces) do
            local item = api.Equipment:GetEquippedItemTooltipInfo(i)
            if item ~= nil then
                local new_item = {name = item.name, grade = item.itemGrade}
                if i == 13 or i == 11 or i == 17 then
                    new_item.alternative = true
                end
                table.insert(items, new_item)
            end
        end
--         Here it is
        local loadout = { name = selected_name, gear = items }

        local title_id = api.Player:GetShowingAppellation()[1]

        if title_id then
            loadout.title_id = title_id
        end
        local loadout_exists = false
        for i, v in ipairs(settings.gear_sets) do
            if v.name == selected_name then
                settings.gear_sets[i] = loadout
                loadout_exists = true
                break
            end
        end
        if not loadout_exists then
            table.insert(settings.gear_sets, loadout)
        end
        api.SaveSettings()
        DISPLAY.Destroy()
        DISPLAY.CreateMainDisplay(settings)
        name_input:SetText("")
        name_input:CreateGuideText("Enter Set Name")
    end)
    remove_button:SetHandler("OnClick", function()
        for i = 1, #settings.gear_sets do
            if settings.gear_sets[i].name == name_input:GetText() then
                table.remove(settings.gear_sets, i)
                api.SaveSettings()
                DISPLAY.Destroy()
                DISPLAY.CreateMainDisplay(settings)
                break
            end
        end
        name_input:SetText("")
        name_input:CreateGuideText("Enter Set Name")
    end)
end

function SETTINGS.CreateSettingsWindow(settings)
    local canvas_x = settings.settings_x or 500
    local canvas_y = settings.settings_y or 0
    SettingsCanvas = api.Interface:CreateEmptyWindow("hotSwapWindow", "UIParent")
    SettingsCanvas.bg = SettingsCanvas:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
    SettingsCanvas.bg:SetTextureInfo("bg_quest")
    SettingsCanvas.bg:SetColor(0, 0, 0, 0.5)
    SettingsCanvas.bg:AddAnchor("TOPLEFT", SettingsCanvas, 0, 0)
    SettingsCanvas.bg:AddAnchor("BOTTOMRIGHT", SettingsCanvas, 0, 0)
    SettingsCanvas:SetExtent(500,500)
    if canvas_x ~= 500 and canvas_y ~= 0 then
        SettingsCanvas:AddAnchor("TOPLEFT", "UIParent", canvas_x, canvas_y)
    else
        SettingsCanvas:AddAnchor("LEFT", "UIParent", canvas_x, canvas_y)
    end
    function SettingsCanvas:OnDragStart()
        if api.Input:IsShiftKeyDown() then
            SettingsCanvas:StartMoving()
            api.Cursor:ClearCursor()
            api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
        end
    end
    SettingsCanvas:SetHandler("OnDragStart", SettingsCanvas.OnDragStart)
    function SettingsCanvas:OnDragStop()
        current_x, current_y = SettingsCanvas:GetOffset()
        settings.settings_x = current_x
        settings.settings_y = current_y
        api.SaveSettings()
        SettingsCanvas:StopMovingOrSizing()
        api.Cursor:ClearCursor()
    end
    SettingsCanvas:SetHandler("OnDragStop", SettingsCanvas.OnDragStop)
    SettingsCanvas:EnableDrag(true)
    SettingsCanvas:Show(shown)
    addCreationButtons(50,50,settings)
end

function SETTINGS.Toggle()
    shown = not shown
    SettingsCanvas:Show(shown)
end

function SETTINGS.Destroy()
    if SettingsCanvas ~= nil then
        SettingsCanvas:Show(false)
    end
end

return SETTINGS

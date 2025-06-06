local DISPLAY = {}
local Canvas
local buttons = {}
local gear_to_process = {}
local gearset_name
local function SwitchTitle(title_id)
    api.Player:ChangeAppellation(title_id)
end
local function EquipItemFromSlot(slot,equip_alternate_slot)
    api.Bag:EquipBagItem(slot, equip_alternate_slot)
end
function DISPLAY.createButton(Canvas, set, x, y, last_button, settings)
    local button = Canvas:CreateChildWidget("button", set.name .. "_button", 0, true)
    table.insert(buttons, button)
    button:Show(true)
    button:AddAnchor("TOPLEFT", Canvas, x, y)
    button:SetText(set.name)
    api.Interface:ApplyButtonSkin(button, BUTTON_BASIC.DEFAULT)
    local button_width = button:GetWidth()
    local canvas_width = Canvas:GetWidth()
    local canvas_height = Canvas:GetHeight()
    if button_width > canvas_width - 50 then
        Canvas:SetExtent(button_width + 50, canvas_height)
    end
    if settings.hidden then
        button:Show(false)
    end
    button:SetHandler("OnClick", function()
        for i = 1, #buttons do
            local selected_button = buttons[i]
            if selected_button ~= button then
                local text = buttons[i]:GetText()
                if text:sub(1, 2) == "> " then
                    text = text:sub(3)
                    buttons[i]:SetText(text)
                end
            end
        end
        if button:GetText():sub(1, 2) ~= "> " then
            button:SetText("> " .. button:GetText())
        end

        if set.title_id ~= nil then
            SwitchTitle(set.title_id)
        end

        gear_to_process = {}
        local processed_bag_slots = {}

        for gear_pos = 1, #set.gear do
            local gear_item_needed = set.gear[gear_pos]
            local found_match_for_this_gear = false

            for slot_num = 1, 150 do
                local slot_already_processed = false
                for _, processed_slot in ipairs(processed_bag_slots) do
                    if slot_num == processed_slot then
                        slot_already_processed = true
                        break
                    end
                end

                if not slot_already_processed then
                    local item_in_bag = api.Bag:GetBagItemInfo(1, slot_num)
                    if item_in_bag ~= nil then
                        if item_in_bag.name == gear_item_needed.name and item_in_bag.itemGrade == gear_item_needed.grade then
                            table.insert(gear_to_process, {
                                gear_item = gear_item_needed,
                                pos = slot_num
                            })
                            table.insert(processed_bag_slots, slot_num)
                            found_match_for_this_gear = true
                            break
                        end
                    end
                end
            end
        end
    end)
    return button
end
local delay = 0
function DISPLAY.CreateDisplays(settings)
    CreateMainDisplay(settings)
end
function DISPLAY.CreateMainDisplay(settings)
    buttons = {}
    gear_to_process = {}
    local gear_sets = settings.gear_sets
    local base_height = 35
    local canvas_x = settings.x or 100
    local canvas_y = settings.y or 0
    Canvas = api.Interface:CreateEmptyWindow("hotSwapWindow", "UIParent")
    Canvas.bg = Canvas:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
    Canvas.bg:SetTextureInfo("bg_quest")
    Canvas.bg:SetColor(0, 0, 0, 0.5)
    Canvas.bg:AddAnchor("TOPLEFT", Canvas, 0, 0)
    Canvas.bg:AddAnchor("BOTTOMRIGHT", Canvas, 0, 0)
    if canvas_x ~= 100 and canvas_y ~= 0 then
        Canvas:AddAnchor("TOPLEFT", "UIParent", canvas_x * api.Interface:GetUIScale(), canvas_y * api.Interface:GetUIScale())
    else
        Canvas:AddAnchor("LEFT", "UIParent", canvas_x * api.Interface:GetUIScale(), canvas_y * api.Interface:GetUIScale())
    end
    if settings.hidden then
        Canvas:SetExtent(200, base_height)
    else
        Canvas:SetExtent(200, base_height + (#gear_sets * 50))
    end
    Canvas:Show(true)
    function Canvas:OnDragStart()
        if api.Input:IsShiftKeyDown() then
            Canvas:StartMoving()
            api.Cursor:ClearCursor()
            api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
        end
    end
    Canvas:SetHandler("OnDragStart", Canvas.OnDragStart)
    function Canvas:OnDragStop()
        local current_x, current_y = Canvas:GetOffset()
        settings.x = current_x
        settings.y = current_y
        api.SaveSettings()
        Canvas:StopMovingOrSizing()
        api.Cursor:ClearCursor()
    end
    Canvas:SetHandler("OnDragStop", Canvas.OnDragStop)
    Canvas:EnableDrag(true)
    local closeBtn = Canvas:CreateChildWidget("button", "hotSwap.closeBtn", 0, true)
    closeBtn:Show(true)
    closeBtn:AddAnchor("TOPRIGHT", Canvas, -10, 5)
    api.Interface:ApplyButtonSkin(closeBtn, BUTTON_BASIC.MINUS)
    local showBtn = Canvas:CreateChildWidget("button", "hotSwap.openBtn", 0, true)
    showBtn:Show(false)
    showBtn:AddAnchor("TOPRIGHT", Canvas, -10, 5)
    api.Interface:ApplyButtonSkin(showBtn, BUTTON_BASIC.PLUS)
    if settings.hidden then
        showBtn:Show(true)
        closeBtn:Show(false)
    else
        showBtn:Show(false)
        closeBtn:Show(true)
    end
    closeBtn:SetHandler("OnClick", function()
        closeBtn:Show(false)
        showBtn:Show(true)
        for button_num = 1, #buttons do
            buttons[button_num]:Show(false)
        end
        Canvas:SetExtent(200, 35)
        settings.hidden = true
        api.SaveSettings()
    end)
    showBtn:SetHandler("OnClick", function()
        closeBtn:Show(true)
        showBtn:Show(false)
        for button_num = 1, #buttons do
            buttons[button_num]:Show(true)
        end
        Canvas:SetExtent(200, base_height + (#buttons * 50))
        settings.hidden = false
        api.SaveSettings()
    end)
    local startX = 20
    local startY = 20
    local offset = 0
    for i = 1, #gear_sets do
        local set = gear_sets[i]
        local last_button = DISPLAY.createButton(Canvas, set, startX, startY + offset, nil, settings)
        offset = offset + 50
    end
end
function DISPLAY.Update()
    if #gear_to_process > 0 then
        for button_pos = 1, #buttons do
            buttons[button_pos]:Enable(false)
        end
        if delay == 25 then
            local item_to_equip = table.remove(gear_to_process, 1)
            if #gear_to_process == 0 then
                for i = 1, #buttons do
                    local button = buttons[i]
                    button:Enable(true)
                end
            end
            local gearItem = item_to_equip.gear_item
            EquipItemFromSlot(item_to_equip.pos, gearItem.alternative or false)
            delay = 0
        end
    end
    if delay < 25 then
        delay = delay + 1
    end
end
function DISPLAY.Destroy()
    for i = 1, #buttons do
        buttons[i]:Show(false)
    end
    if Canvas ~= nil then
        Canvas:Show(false)
        Canvas = nil
    end
end
return DISPLAY

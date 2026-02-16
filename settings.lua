local DISPLAY = require("hot_swap/display")
local SETTINGS = {}
local SettingsCanvas
local shown = false

local function is_empty_or_whitespace(str)
	return str == nil or str:match("^%s*$") ~= nil
end

local function updateDropdown(dropdown, settings)
	local names = {}
	for _, set in ipairs(settings.gear_sets) do
		table.insert(names, set.name)
	end
	dropdown.dropdownItem = names
	if #names > 0 then
		dropdown:Select(1)
	else
		dropdown:ClearSelection()
	end
end

local function refreshAll(dropdown, settings)
	updateDropdown(dropdown, settings)
	DISPLAY.Destroy()
	DISPLAY.CreateMainDisplay(settings, SETTINGS.Toggle)
end

local function saveCurrentGear(set_name, settings)
	local items = {}
	local gear_pieces = { 1, 3, 4, 8, 6, 9, 5, 7, 15, 2, 10, 11, 12, 13, 16, 17, 18, 19, 28 }

	for _, i in ipairs(gear_pieces) do
		local item = api.Equipment:GetEquippedItemTooltipInfo(i)
		if item ~= nil then
			local new_item = { name = item.name, grade = item.itemGrade }
			if i == 13 or i == 11 or i == 17 then
				new_item.alternative = true
			end
			table.insert(items, new_item)
		end
	end

	local loadout = { name = set_name, gear = items }
	local title_id = api.Player:GetShowingAppellation()[1]
	if title_id then
		loadout.title_id = title_id
	end

	local exists = false
	for i, v in ipairs(settings.gear_sets) do
		if v.name == set_name then
			settings.gear_sets[i] = loadout
			exists = true
			break
		end
	end

	if not exists then
		table.insert(settings.gear_sets, loadout)
	end

	api.SaveSettings()
end

local function addCreationButtons(startX, startY, settings)
	-- --- CREATE SECTION ---
	local create_label = SettingsCanvas:CreateChildWidget("label", "create_label", 0, true)
	create_label:SetText("Create New Set")
	create_label:SetExtent(200, 20)
	create_label:AddAnchor("TOPLEFT", SettingsCanvas, startX, startY)

	local name_input = W_CTRL.CreateEdit("nameEditbox", SettingsCanvas)
	name_input:AddAnchor("TOPLEFT", SettingsCanvas, startX, startY + 25)
	name_input:SetExtent(180, 30)
	name_input:CreateGuideText("Enter Set Name")

	local create_btn = SettingsCanvas:CreateChildWidget("button", "create_btn", 0, true)
	create_btn:SetText("Create")
	create_btn:SetExtent(80, 30)
	create_btn:AddAnchor("TOPLEFT", SettingsCanvas, startX + 190, startY + 25)
	api.Interface:ApplyButtonSkin(create_btn, BUTTON_BASIC.DEFAULT)

	-- --- EDIT SECTION ---
	local edit_label = SettingsCanvas:CreateChildWidget("label", "edit_label", 0, true)
	edit_label:SetText("Edit Existing Set")
	edit_label:SetExtent(200, 20)
	edit_label:AddAnchor("TOPLEFT", SettingsCanvas, startX, startY + 85)

	local set_dropdown = api.Interface:CreateComboBox(SettingsCanvas)
	set_dropdown:SetExtent(180, 30)
	set_dropdown:AddAnchor("TOPLEFT", SettingsCanvas, startX, startY + 110)

	-- Move Up Button
	local up_btn = SettingsCanvas:CreateChildWidget("button", "up_btn", 0, true)
	up_btn:SetExtent(25, 25)
	up_btn:AddAnchor("TOPLEFT", SettingsCanvas, startX + 190, startY + 112)
	api.Interface:ApplyButtonSkin(up_btn, BUTTON_BASIC.SLIDER_UP)

	-- Move Down Button
	local down_btn = SettingsCanvas:CreateChildWidget("button", "down_btn", 0, true)
	down_btn:SetExtent(25, 25)
	down_btn:AddAnchor("TOPLEFT", SettingsCanvas, startX + 220, startY + 112)
	api.Interface:ApplyButtonSkin(down_btn, BUTTON_BASIC.SLIDER_DOWN)

	-- Update and Remove below
	local update_btn = SettingsCanvas:CreateChildWidget("button", "update_btn", 0, true)
	update_btn:SetText("Update Gear")
	update_btn:SetExtent(110, 30)
	update_btn:AddAnchor("TOPLEFT", SettingsCanvas, startX, startY + 155)
	api.Interface:ApplyButtonSkin(update_btn, BUTTON_BASIC.DEFAULT)

	local remove_btn = SettingsCanvas:CreateChildWidget("button", "remove_btn", 0, true)
	remove_btn:SetText("Remove Set")
	remove_btn:SetExtent(110, 30)
	remove_btn:AddAnchor("TOPLEFT", SettingsCanvas, startX + 120, startY + 155)
	api.Interface:ApplyButtonSkin(remove_btn, BUTTON_BASIC.DEFAULT)

	updateDropdown(set_dropdown, settings)

	-- Handlers
	create_btn:SetHandler("OnClick", function()
		local val = name_input:GetText()
		if not is_empty_or_whitespace(val) then
			saveCurrentGear(val, settings)
			name_input:SetText("")
			refreshAll(set_dropdown, settings)
		end
	end)

	update_btn:SetHandler("OnClick", function()
		local idx = set_dropdown:GetSelectedIndex()
		if idx > 0 then
			local set_name = settings.gear_sets[idx].name
			saveCurrentGear(set_name, settings)
			refreshAll(set_dropdown, settings)
		end
	end)

	remove_btn:SetHandler("OnClick", function()
		local idx = set_dropdown:GetSelectedIndex()
		if idx > 0 then
			table.remove(settings.gear_sets, idx)
			api.SaveSettings()
			refreshAll(set_dropdown, settings)
		end
	end)

	up_btn:SetHandler("OnClick", function()
		local idx = set_dropdown:GetSelectedIndex()
		if idx > 1 then
			local item = table.remove(settings.gear_sets, idx)
			table.insert(settings.gear_sets, idx - 1, item)
			api.SaveSettings()
			refreshAll(set_dropdown, settings)
			set_dropdown:Select(idx - 1)
		end
	end)

	down_btn:SetHandler("OnClick", function()
		local idx = set_dropdown:GetSelectedIndex()
		if idx > 0 and idx < #settings.gear_sets then
			local item = table.remove(settings.gear_sets, idx)
			table.insert(settings.gear_sets, idx + 1, item)
			api.SaveSettings()
			refreshAll(set_dropdown, settings)
			set_dropdown:Select(idx + 1)
		end
	end)
end

function SETTINGS.CreateSettingsWindow(settings)
	local canvas_x = settings.settings_x or 500
	local canvas_y = settings.settings_y or 0
	SettingsCanvas = api.Interface:CreateEmptyWindow("hotSwapSettings", "UIParent")
	SettingsCanvas.bg = SettingsCanvas:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
	SettingsCanvas.bg:SetTextureInfo("bg_quest")
	SettingsCanvas.bg:SetColor(0, 0, 0, 0.7)
	SettingsCanvas.bg:AddAnchor("TOPLEFT", SettingsCanvas, 0, 0)
	SettingsCanvas.bg:AddAnchor("BOTTOMRIGHT", SettingsCanvas, 0, 0)
	SettingsCanvas:SetExtent(350, 240)

	if canvas_x ~= 500 and canvas_y ~= 0 then
		SettingsCanvas:AddAnchor("TOPLEFT", "UIParent", canvas_x, canvas_y)
	else
		SettingsCanvas:AddAnchor("LEFT", "UIParent", canvas_x, canvas_y)
	end

	local closeBtn = SettingsCanvas:CreateChildWidget("button", "settings.closeBtn", 0, true)
	closeBtn:AddAnchor("TOPRIGHT", SettingsCanvas, -10, 10)
	api.Interface:ApplyButtonSkin(closeBtn, BUTTON_BASIC.WINDOW_CLOSE)
	closeBtn:SetHandler("OnClick", function()
		SETTINGS.Toggle()
	end)

	SettingsCanvas:EnableDrag(true)
	SettingsCanvas:SetHandler("OnDragStart", function()
		if api.Input:IsShiftKeyDown() then
			SettingsCanvas:StartMoving()
			api.Cursor:ClearCursor()
			api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
		end
	end)
	SettingsCanvas:SetHandler("OnDragStop", function()
		local cx, cy = SettingsCanvas:GetOffset()
		settings.settings_x = cx
		settings.settings_y = cy
		api.SaveSettings()
		SettingsCanvas:StopMovingOrSizing()
		api.Cursor:ClearCursor()
	end)

	addCreationButtons(25, 30, settings)
	SettingsCanvas:Show(shown)
end

function SETTINGS.Toggle()
	shown = not shown
	if SettingsCanvas then
		SettingsCanvas:Show(shown)
	end
end

function SETTINGS.Destroy()
	if SettingsCanvas then
		SettingsCanvas:Show(false)
	end
end

return SETTINGS

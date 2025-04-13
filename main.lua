local api = require("api")
local DISPLAY = require("hot_swap/display")
local SETTINGS = require("hot_swap/settings")
local hot_swap = {
    name = "Hot Swap",
    version = "0.4.0",
    author = "MikeTheShadow",
    desc = "A plugin to hotswap gear and titles."
}
local function OnLoad()
    local settings = api.GetSettings("hot_swap")
    if settings.gear_sets == nil then
        settings.gear_sets = {}
        api.SaveSettings()
    end
    settings.show_creation_window = true
    DISPLAY.CreateMainDisplay(settings)
    SETTINGS.CreateSettingsWindow(settings)
end
hot_swap.OnLoad = OnLoad
local function OnUpdate()
    DISPLAY.Update()
end
api.On("UPDATE", OnUpdate)
local function OnUnload()
    DISPLAY.Destroy()
    SETTINGS.Destroy()
end
hot_swap.OnUnload = OnUnload
local function OnSettingToggle()
    SETTINGS.Toggle()
end
hot_swap.OnSettingToggle = OnSettingToggle
return hot_swap

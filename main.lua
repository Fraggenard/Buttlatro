local logging = require("logging")
local logger = logging.getLogger("Buttlatro")
local buttplug = nil

local isEnabled = false
local isConnected = false
local isPatched = false

local isMenuOpen = false

local function on_game_load(args)
    local patch = [[   
    play_sound(sound, 0.8+percent*0.2, volume)
        if (sound == 'chips1' or sound == 'multhit1' or sound == 'multhit2') then
            sendVibrateCmd(percent)
        end
    ]]
    local toPatch = "play_sound(sound, 0.8+percent*0.2, volume)"
    local patch2 = [[
    sendVibrateCmd(0.0)
    if not next(args) then return end
    ]]
    local toPatch2 = "if not next(args) then return end"
    balalib.inject("functions/common_events", "card_eval_status_text", toPatch, patch)
    balalib.inject("functions/common_events", "check_for_unlock", toPatch2, patch2)
    isPatched = true
end

local function on_enable()
    buttplug = require("Buttlatro/buttplug/buttplug")
    if isPatched and not isConnected then
        -- Ask for the device list after we connect
        table.insert(buttplug.cb.ServerInfo, function()
            buttplug.request_device_list()
        end)

        -- Start scanning if the device list was empty
        table.insert(buttplug.cb.DeviceList, function()
            if buttplug.count_devices() == 0 then
                buttplug.start_scanning()
            end
        end)

        -- Stop scanning after the first device is found
        table.insert(buttplug.cb.DeviceAdded, function()
            buttplug.stop_scanning()
        end)

        -- Start scanning if we lose a device
        table.insert(buttplug.cb.DeviceRemoved, function()
            buttplug.start_scanning()
        end)

        buttplug.connect("Buttlatro", "ws://127.0.0.1:12345")

        G.UIDEF.buttlatro_menu_ui_definition = function()
            return {
                n = G.UIT.ROOT,
                config = {
                    align = "cm",
                    padding = 0.1,
                    r = 2
                },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { 
                            align = "cm",
                            padding = 0.03,
                            r = 1
                        },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { 
                                    align = "cm",
                                    colour = G.C.ETERNAL,
                                    padding = 0.2,
                                    r = 2
                                },
                                nodes = {
                                    {
                                        n = G.UIT.T,
                                        config = { 
                                            text = "Buttlatro v1.0.0", 
                                            colour = G.C.WHITE,
                                            scale = 0.5,
                                            shadow = true 
                                        }
                                    }
                                }
                            },
                            {
                                n = G.UIT.R,
                                config = { 
                                    align = "cm",
                                    colour = G.C.UI.BACKGROUND_WHITE,
                                    r = 2 
                                },
                                nodes = {
                                    {
                                        n = G.UIT.C,
                                        config = {
                                            align = "cm", 
                                            padding = 0.5
                                        },
                                        nodes = {
                                            {
                                                n = G.UIT.C,
                                                config = {
                                                    align = "cm",
                                                    padding = 0.1,
                                                    minh = 0.7,
                                                    r = 0.1,
                                                    hover = true,
                                                    colour = G.C.RED,
                                                    button = "stopTestVibration",
                                                    shadow = true,
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            colour = G.C.UI.TEXT_LIGHT,
                                                            scale = 0.5,
                                                            text = "Stop Test Vibration"
                                                        }
                                                    }
                                                }
                                            },
                                            {
                                                n = G.UIT.C,
                                                config = {
                                                    align = "cm",
                                                    padding = 0.1,
                                                    minh = 0.7,
                                                    r = 0.1,
                                                    hover = true,
                                                    colour = G.C.GREEN,
                                                    button = "startTestVibration",
                                                    shadow = true,
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            colour = G.C.UI.TEXT_LIGHT,
                                                            scale = 0.5,
                                                            text = "Start Test Vibration"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } 
        end
        isConnected = true
    end
    isEnabled = true
end

function sendVibrateCmd(percent)
    if isConnected and isEnabled then
        buttplug.send_vibrate_cmd(0, { percent })
    end
end

G.FUNCS.startTestVibration = function()
    sendVibrateCmd(0.5)
end

G.FUNCS.stopTestVibration = function()
    sendVibrateCmd(0)
end

function openTestVibrationMenu()
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu({ definition = G.UIDEF.buttlatro_menu_ui_definition() })
    isMenuOpen = true
end

function closeTestVibrationMenu(fromDebugKey)
    G.FUNCS.stopTestVibration()
    isMenuOpen = false
    if fromDebugKey then
        G.FUNCS.exit_overlay_menu()
    end
end

local function on_disable()
    isEnabled = false
end

local function on_key_pressed(key)
    if key == "m" and isEnabled then
        if isMenuOpen then
            closeTestVibrationMenu(true)     
        else
            openTestVibrationMenu()
        end
    end
end

local function on_post_update(dt)
    if not G.OVERLAY_MENU and isMenuOpen then
        closeTestVibrationMenu(false)
    end
end

return {
    on_enable = on_enable,
    on_game_load = on_game_load,
    on_disable = on_disable,
    on_key_pressed = on_key_pressed,
    on_post_update = on_post_update
}

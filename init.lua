local version = "4.2.0-dev"
local modpath = minetest.get_modpath("arena_lib")

dofile(modpath .. "/api.lua")
dofile(modpath .. "/callbacks.lua")
dofile(modpath .. "/chat.lua")
dofile(modpath .. "/commands.lua")
dofile(modpath .. "/debug_utilities.lua")
dofile(modpath .. "/player_manager.lua")
dofile(modpath .. "/privs.lua")
dofile(modpath .. "/signs.lua")
dofile(modpath .. "/utils.lua")
dofile(modpath .. "/_dependencies/parties.lua")
dofile(modpath .. "/_editor/editor_main.lua")
dofile(modpath .. "/_editor/editor_icons.lua")
dofile(modpath .. "/_editor/tools_players.lua")
dofile(modpath .. "/_editor/tools_settings.lua")
dofile(modpath .. "/_editor/tools_sign.lua")
dofile(modpath .. "/_editor/tools_spawner.lua")
dofile(modpath .. "/_hud/hud_main.lua")
dofile(modpath .. "/_hud/hud_waypoints.lua")

minetest.log("action", "[ARENA_LIB] Mod initialised, running version " .. version)

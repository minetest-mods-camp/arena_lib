local version = "5.3.0-dev"
local modpath = minetest.get_modpath("arena_lib")
local srcpath = modpath .. "/src"

dofile(srcpath .. "/api/core.lua")
dofile(srcpath .. "/api/in_game.lua")
dofile(srcpath .. "/api/in_queue.lua")
dofile(srcpath .. "/api/misc.lua")
dofile(srcpath .. "/api/teams.lua")
dofile(srcpath .. "/callbacks.lua")
dofile(srcpath .. "/chat.lua")
dofile(srcpath .. "/commands.lua")
dofile(srcpath .. "/player_manager.lua")
dofile(srcpath .. "/privs.lua")
dofile(srcpath .. "/signs.lua")
dofile(srcpath .. "/dependencies/parties.lua")
dofile(srcpath .. "/editor/editor_main.lua")
dofile(srcpath .. "/editor/editor_icons.lua")
dofile(srcpath .. "/editor/tools_bgm.lua")
dofile(srcpath .. "/editor/tools_customise.lua")
dofile(srcpath .. "/editor/tools_lighting.lua")
dofile(srcpath .. "/editor/tools_players.lua")
dofile(srcpath .. "/editor/tools_settings.lua")
dofile(srcpath .. "/editor/tools_sign.lua")
dofile(srcpath .. "/editor/tools_sky.lua")
dofile(srcpath .. "/editor/tools_spawner.lua")
dofile(srcpath .. "/hud/hud_main.lua")
dofile(srcpath .. "/hud/hud_waypoints.lua")
dofile(srcpath .. "/spectate/spectate_dummy.lua")
dofile(srcpath .. "/spectate/spectate_main.lua")
dofile(srcpath .. "/spectate/spectate_hand.lua")
dofile(srcpath .. "/spectate/spectate_tools.lua")
dofile(srcpath .. "/utils/debug.lua")
dofile(srcpath .. "/utils/macros.lua")
dofile(srcpath .. "/utils/minigame_settings.lua")
dofile(srcpath .. "/utils/temp.lua")

dofile(modpath .. "/SETTINGS.lua")

minetest.log("action", "[ARENA_LIB] Mod initialised, running version " .. version)

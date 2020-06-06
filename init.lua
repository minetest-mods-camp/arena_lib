local version = "3.0.0"

dofile(minetest.get_modpath("arena_lib") .. "/api.lua")
dofile(minetest.get_modpath("arena_lib") .. "/callbacks.lua")
dofile(minetest.get_modpath("arena_lib") .. "/debug_utilities.lua")
dofile(minetest.get_modpath("arena_lib") .. "/hud.lua")
dofile(minetest.get_modpath("arena_lib") .. "/items.lua")
dofile(minetest.get_modpath("arena_lib") .. "/player_manager.lua")
dofile(minetest.get_modpath("arena_lib") .. "/signs.lua")
dofile(minetest.get_modpath("arena_lib") .. "/utils.lua")
dofile(minetest.get_modpath("arena_lib") .. "/_edit_tools/editor_main.lua")
dofile(minetest.get_modpath("arena_lib") .. "/_edit_tools/editor_icons.lua")
dofile(minetest.get_modpath("arena_lib") .. "/_edit_tools/tools_sign.lua")
dofile(minetest.get_modpath("arena_lib") .. "/_edit_tools/tools_spawner.lua")

minetest.log("action", "[ARENA_LIB] Mod initialised, version " .. version)

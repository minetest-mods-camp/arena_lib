-- The physics override to apply when a player leaves a match (whether by quitting,
-- winning etc). This comes in handy for hybrid servers (i.e. survival/creative
-- ones featuring some minigames). If you're aiming for a full minigame server,
-- ignore this parameter and let the mod hub_manager supersede it =>
-- https://gitlab.com/zughy-friends-minetest/hub-manager
arena_lib.SERVER_PHYSICS = {
  speed = 1,
  jump = 1,
  gravity = 1,
  sneak = true,
  sneak_glitch = false,
  new_move = true
}

-- for mods where `keep_inventory = false`.
-- It determines whether the inventory before entering an arena should be stored
-- and where. When stored, players will get it back either when the match ends or,
-- if they disconnect/the server crashes, next time they log in.
-- "none" = don't store
-- "mod_db" = store in the arena_lib mod database
-- "external_db" = store in an external database -TODO: NOT YET IMPLEMENTED
arena_lib.STORE_INVENTORY_MODE = "mod_db"

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

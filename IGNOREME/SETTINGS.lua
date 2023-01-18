-- The entrance type that is set by default to every new arena
arena_lib.DEFAULT_ENTRANCE = "sign"

-- The physics override to apply when a player leaves a match (whether by quitting,
-- winning etc). This comes in handy for hybrid servers (i.e. survival/creative
-- ones featuring some minigames). If you're aiming for a full minigame server,
-- ignore this parameter and let the mod Hub supersede it =>
-- https://gitlab.com/zughy-friends-minetest/hub
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
arena_lib.STORE_INVENTORY_MODE = "mod_db"

-- instead of letting modders put whatever colour they want in the sky settings,
-- arena_lib offers a curated palette to pick from. The palette is Zughy 32 (yes,
-- that's me) => https://lospec.com/palette-list/zughy-32. I invite you *not* to
-- edit it manually; instead, if you want to change it, pick your favourite from
-- Lospec: https://lospec.com/palette-list, edit the list and it'll be
-- automatically updated in game. Do not remove "_default" and keep all letters
-- uppercase
arena_lib.PALETTE = {
  _default = "",
  skin_cocoa = "#5E3643",
  skin_toffee = "#7A444A",
  skin_bronze = "#A05B5E",
  skin_almond = "#BF7958",
  skin_beige = "#EEA160",
  skin_vanilla = "#F4CCA1",
  green_light = "#B6D53C",
  green = "#71AA34",
  green_dark = "#397B44",
  green_deep = "#3C5956",
  black = "#302C2E",
  grey_dark = "#5A5353",
  grey = "#7D7071",
  grey_light = "#A0938E",
  grey_fog = "#CFC6B8",
  white = "#DFF6F5",
  celeste = "#8AEBF1",
  blue_sky = "#28CCDF",
  azure = "#3978A8",
  blue = "#394778",
  blue_dark = "#39314B",
  purple_dark = "#564064",
  purple = "#8E478C",
  magenta = "#CD6093",
  pink = "#FFAEB6",
  yellow = "#F4B41B",
  orange = "#F47E1B",
  red = "#E6482E",
  red_dark = "#A93B3B",
  purple_mauve = "#827094",
  blue_spruce = "#4F546B"
}

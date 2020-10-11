local S = minetest.get_translator("arena_lib")


minetest.register_tool("arena_lib:immunity", {

  description = S("You're immune!"),
  inventory_image = "arenalib_immunity.png",
  groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end

})

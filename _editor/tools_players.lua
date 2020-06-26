local S = minetest.get_translator("arena_lib")
local players_tools = {
  "arena_lib:players_min",
  "arena_lib:players_max",
  "arena_lib:players_change",
  "",
  "",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}



minetest.register_tool("arena_lib:players_min", {

    description = S("Players required"),
    inventory_image = "arenalib_tool_players_min.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local mod = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
      local players_amount = user:get_meta():get_int("arena_lib_editor.players_number")

      arena_lib.change_players_amount(user:get_player_name(), mod, arena_name, players_amount, nil)
    end
})



minetest.register_tool("arena_lib:players_max", {

    description = S("Players supported"),
    inventory_image = "arenalib_tool_players_max.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local mod = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
      local players_amount = user:get_meta():get_int("arena_lib_editor.players_number")

      arena_lib.change_players_amount(user:get_player_name(), mod, arena_name, nil, players_amount)
    end
})



minetest.register_tool("arena_lib:players_change", {

    description = S("Change the current number"),
    inventory_image = "arenalib_tool_players_change.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)
      change_players_number(user, true)
    end,

    on_place = function(itemstack, placer, pointed_thing)
      change_players_number(placer, false)
    end
})



function arena_lib.give_players_tools(player)
  player:get_inventory():set_list("main", players_tools)
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function change_players_number(player, decrease)
  local players_number = player:get_meta():get_int("arena_lib_editor.players_number")

  if not decrease then
    players_number = players_number +1
  else
    if players_number > 1 then
      players_number = players_number -1
    else return end
  end

  player:get_meta():set_int("arena_lib_editor.players_number", players_number)
  arena_lib.HUD_send_msg("hotbar", player:get_player_name(), S("Players | num to set: @1 (left/right click slot #3 to change)", players_number))
end

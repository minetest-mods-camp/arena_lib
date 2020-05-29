local S = minetest.get_translator("arena_lib")
local spawners_tools_team = {
  "arena_lib:spawner_add",
  "",
  "cambia team",
  "cancella per team",
  "arena_lib:spawner_deleteall",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}
local spawners_tools_noteam = {
  "arena_lib:spawner_add",
  "arena_lib:spawner_remove",
  "",
  "",
  "arena_lib:spawner_deleteall",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}


minetest.register_tool("arena_lib:spawner_add", {

  description = S("Add spawner"),
  inventory_image = "arenalib_tool_spawner_add.png",
  groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")

    arena_lib.set_spawner(user:get_player_name(), mod, arena_name)
  end

})



minetest.register_tool("arena_lib:spawner_remove", {

  description = S("Remove spawner"),
  inventory_image = "arenalib_tool_spawner_remove.png",
  groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local spawner_ID = user:get_meta():get_int("arena_lib_editor.spawner_ID")

    arena_lib.set_spawner(user:get_player_name(), mod, arena_name, "delete", spawner_ID)
  end,


  on_place = function(itemstack, placer, pointed_thing)

    local mod = placer:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = placer:get_meta():get_string("arena_lib_editor.arena")
    local spawner_ID = placer:get_meta():get_int("arena_lib_editor.spawner_ID")
    local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

    if spawner_ID >= #arena.spawn_points then
      spawner_ID = 1
    else
      spawner_ID = spawner_ID +1
    end

    placer:get_meta():set_int("arena_lib_editor.spawner_ID", spawner_ID)
    arena_lib.HUD_send_msg("hotbar", placer:get_player_name(), "Spawner | ID sel.: " .. spawner_ID .. " (Click dx su slot #2 per cambiare)")
  end

})



minetest.register_tool("arena_lib:spawner_deleteall", {

  description = "Cancella tutto",
  inventory_image = "arenalib_tool_spawner_deleteall.png",
  groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local p_name = user:get_player_name()

    arena_lib.set_spawner(p_name, mod, arena_name, "deleteall")
    minetest.chat_send_player(user:get_player_name(), "Tutti gli spawn point sono stati rimossi")
  end

})



function arena_lib.give_spawners_tools(player)

  local mod = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")
  local teams = arena_lib.mods[mod].teams

  if #teams > 0 then
    player:get_inventory():set_list("main", spawners_tools_team)
  else
    player:get_inventory():set_list("main", spawners_tools_noteam)
  end

end

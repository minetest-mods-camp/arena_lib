local S = minetest.get_translator("arena_lib")

local function change_spawner_ID() end

local spawners_tools_team = {
  "arena_lib:spawner_team_add",
  "arena_lib:spawner_team_remove",
  "arena_lib:spawner_team_switch",
  "",
  "arena_lib:spawner_deleteall",
  "arena_lib:spawner_team_deleteall",
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
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}


minetest.register_tool("arena_lib:spawner_add", {

  description = S("Add spawner"),
  inventory_image = "arenalib_tool_spawner_add.png",
  groups = {not_in_creative_inventory = 1},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")

    arena_lib.set_spawner(user:get_player_name(), mod, arena_name, nil, nil, nil, true)
  end

})



minetest.register_tool("arena_lib:spawner_remove", {

  description = S("Remove spawner"),
  inventory_image = "arenalib_tool_spawner_remove.png",
  groups = {not_in_creative_inventory = 1},
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local spawner_ID = user:get_meta():get_int("arena_lib_editor.spawner_ID")

    arena_lib.set_spawner(user:get_player_name(), mod, arena_name, nil, "delete", spawner_ID, true)
  end,

  on_secondary_use = function(itemstack, placer, pointed_thing)
    change_spawner_ID(placer)
  end,

  on_place = function(itemstack, user, pointed_thing)
    change_spawner_ID(user)
  end
})



minetest.register_tool("arena_lib:spawner_team_add", {

  description = S("Add team spawner"),
  inventory_image = "arenalib_tool_spawner_team_add.png",
  groups = {not_in_creative_inventory = 1},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local team_ID = user:get_meta():get_int("arena_lib_editor.team_ID")

    arena_lib.set_spawner(user:get_player_name(), mod, arena_name, team_ID, nil, nil, true)
  end

})



minetest.register_tool("arena_lib:spawner_team_remove", {

  description = S("Remove team spawner"),
  inventory_image = "arenalib_tool_spawner_team_remove.png",
  groups = {not_in_creative_inventory = 1},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local spawner_ID = user:get_meta():get_int("arena_lib_editor.spawner_ID")
    local team_ID = user:get_meta():get_int("arena_lib_editor.team_ID")

    arena_lib.set_spawner(user:get_player_name(), mod, arena_name, nil, "delete", spawner_ID, true)
  end,


  on_secondary_use = function(itemstack, placer, pointed_thing)
    change_spawner_ID(placer)
  end

})



minetest.register_tool("arena_lib:spawner_team_switch", {

  description = S("Switch team"),
  inventory_image = "arenalib_tool_spawner_team_switch.png",
  groups = {not_in_creative_inventory = 1},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local team_ID = user:get_meta():get_int("arena_lib_editor.team_ID")
    local mod_ref = arena_lib.mods[mod]

    if team_ID >= table.maxn(mod_ref.teams) then
      team_ID = 1
    else
      team_ID = team_ID +1
    end

    local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

    minetest.chat_send_player(user:get_player_name(), S("Selected team: @1", mod_ref.teams[team_ID]))

    user:get_meta():set_int("arena_lib_editor.team_ID", team_ID)
    user:get_meta():set_int("arena_lib_editor.spawner_ID", 1)
  end

})



minetest.register_tool("arena_lib:spawner_deleteall", {

  description = S("Delete all spawners"),
  inventory_image = "arenalib_tool_spawner_deleteall.png",
  groups = {not_in_creative_inventory = 1},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local p_name = user:get_player_name()

    arena_lib.set_spawner(p_name, mod, arena_name, nil, "deleteall", nil, true)
  end

})



minetest.register_tool("arena_lib:spawner_team_deleteall", {

  description = S("Delete all spawners of the team"),
  inventory_image = "arenalib_tool_spawner_team_deleteall.png",
  groups = {not_in_creative_inventory = 1},
  on_place = function() end,
  on_drop = function() end,

  on_use = function(itemstack, user, pointed_thing)

    local mod = user:get_meta():get_string("arena_lib_editor.mod")
    local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
    local team_ID = user:get_meta():get_int("arena_lib_editor.team_ID")
    local p_name = user:get_player_name()

    arena_lib.set_spawner(p_name, mod, arena_name, team_ID, "deleteall", nil, true)
  end

})



function arena_lib.give_spawners_tools(player)

  local mod = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if arena.teams_enabled then
    player:get_inventory():set_list("main", spawners_tools_team)
  else
    player:get_inventory():set_list("main", spawners_tools_noteam)
  end

end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function change_spawner_ID(player)
  local mod = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")
  local spawner_ID = player:get_meta():get_int("arena_lib_editor.spawner_ID")
  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if spawner_ID >= table.maxn(arena.spawn_points) then
    spawner_ID = 1
  else
    spawner_ID = spawner_ID +1
  end

  player:get_meta():set_int("arena_lib_editor.spawner_ID", spawner_ID)
  arena_lib.HUD_send_msg("hotbar", player:get_player_name(), S("Spawners | sel. ID: @1 (right click slot #2 to change)", spawner_ID))
end

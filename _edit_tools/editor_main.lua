local S = minetest.get_translator("arena_lib")
local arenas_in_edit_mode = {}      -- KEY: arena name; INDEX: name of the player inside the editor
local players_in_edit_mode = {}     -- KEY: player name; INDEX: player old inventory
local editor_tools = {
  "",
  "arena_lib:editor_spawners",
  "arena_lib:editor_signs",
  "",
  "",
  "arena_lib:editor_info",
  "arena_lib:editor_enable",
  "arena_lib:editor_quit"
}



function arena_lib.enter_editor(sender, mod, arena_name)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena, true) then return end

  -- se l'arena è abilitata, la disabilito
  if arena.enabled then
    arena_lib.disable_arena(sender, mod, arena_name)
  end

  arena_lib.teleport_in_arena(sender, mod, arena_name)

  local player = minetest.get_player_by_name(sender)

  -- imposto i metadati che porto a spasso per l'editor
  player:get_meta():set_string("arena_lib_editor.mod", mod)
  player:get_meta():set_string("arena_lib_editor.arena", arena_name)

  -- metto l'arena in edit mode e salvo l'inventario
  arenas_in_edit_mode[arena_name] = sender
  players_in_edit_mode[sender] = player:get_inventory():get_list("main")

  -- cambio l'inventario
  arena_lib.show_main_editor(player)

end



function arena_lib.quit_editor(player)

  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  if arena_name == "" then return end

  local p_name = player:get_player_name()
  local inv = players_in_edit_mode[p_name]

  arenas_in_edit_mode[arena_name] = nil
  players_in_edit_mode[p_name] = nil

  player:get_meta():set_string("arena_lib_editor.mod", "")
  player:get_meta():set_string("arena_lib_editor.arena", "")
  player:get_meta():set_string("arena_lib_editor.spawner_ID", "")

  minetest.after(0, function()
    player:get_inventory():set_list("main", inv)
  end)

  arena_lib.HUD_hide("hotbar", p_name)

end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.show_main_editor(player)

  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  player:get_inventory():set_list("main", editor_tools)
  arena_lib.HUD_send_msg("hotbar", player:get_player_name(), S("Arena_lib editor | Now editing: @1", arena_name))
end



function arena_lib.is_arena_in_edit_mode(arena_name)
  if arenas_in_edit_mode[arena_name] ~= nil then return true
  else return false end
end



function arena_lib.is_player_in_edit_mode(p_name)
  if players_in_edit_mode[p_name] ~= nil then return true
  else return false end
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_player_in_edit_mode(arena_name)
  return arenas_in_edit_mode[arena_name]
end

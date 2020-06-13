local S = minetest.get_translator("arena_lib")
local arenas_in_edit_mode = {}      -- KEY: arena name; INDEX: name of the player inside the editor
local players_in_edit_mode = {}     -- KEY: player name; INDEX: (placeholder, not relevant)
local editor_tools = {
  "",
  "arena_lib:editor_spawners",
  "arena_lib:editor_signs",
  "",
  "",
  "",
  "arena_lib:editor_info",
  "arena_lib:editor_quit"
}



function arena_lib.enter_editor(sender, mod, arena_name)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- se l'arena è abilitata, provo a disabilitarla (ARENA_LIB_EDIT_PRECHECKS_PASSED è già incluso in disable_arena: da qui l'if)
  if arena.enabled then
    if not arena_lib.disable_arena(sender, mod, arena_name) then return end
  else
    if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena, true) then return end
  end

  local player = minetest.get_player_by_name(sender)

  -- imposto i metadati che porto a spasso per l'editor
  player:get_meta():set_string("arena_lib_editor.mod", mod)
  player:get_meta():set_string("arena_lib_editor.arena", arena_name)

  -- cambio l'inventario
  arena_lib.show_main_editor(player)

  -- metto l'arena in edit mode
  arenas_in_edit_mode[arena_name] = sender
  players_in_edit_mode[sender] = true

end



function arena_lib.quit_editor(player)

  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  if arena_name == "" then return end

  arenas_in_edit_mode[arena_name] = nil
  players_in_edit_mode[player:get_player_name()] = nil

  player:get_meta():set_string("arena_lib_editor.mod", "")
  player:get_meta():set_string("arena_lib_editor.arena", "")
  player:get_meta():set_string("arena_lib_editor.spawner_ID", "")

  minetest.after(0, function()
    player:get_inventory():set_list("main", {})
  end)

  arena_lib.HUD_hide("hotbar", player:get_player_name())

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

local S = minetest.get_translator("arena_lib")
local in_edit_mode = {} -- arenas names
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

  -- controllo se esiste l'arena
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  -- se è abilitata, annullo
  if arena.enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You must disable the arena first!")))
    return end

  -- se sta già venendo modificata da qualcuno, annullo
  if in_edit_mode[arena_name] ~= nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] L'arena sta già venendo modificata da qualcun altro! (" .. in_edit_mode[arena_name] .. ")"))
    return end

  local player = minetest.get_player_by_name(sender)

  -- imposto i metadati che porto a spasso per l'editor
  player:get_meta():set_string("arena_lib_editor.mod", mod)
  player:get_meta():set_string("arena_lib_editor.arena", arena_name)

  -- cambio l'inventario
  arena_lib.show_main_editor(player)

  -- metto l'arena in edit mode
  in_edit_mode[arena_name] = sender

end



function arena_lib.quit_editor(player)

  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  if arena_name == "" then return end

  in_edit_mode[arena_name] = nil

  player:get_meta():set_string("arena_lib_editor.mod", "")
  player:get_meta():set_string("arena_lib_editor.arena", "")
  player:get_meta():set_string("arena_lib_editor.spawner_ID", "")

  minetest.after(0, function()
    player:get_inventory():set_list("main", {})
  end)

  arena_lib.HUD_hide("hotbar", player:get_player_name())

end



function arena_lib.show_main_editor(player)

  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  player:get_inventory():set_list("main", editor_tools)
  arena_lib.HUD_send_msg("hotbar", player:get_player_name(), "Arena_lib editor | Stai modificando: " .. arena_name)
end



function arena_lib.is_arena_in_edit_mode(arena_name, player_exception)

  if player_exception then
    if in_edit_mode[arena_name] == player_exception then return false end
  end

  if in_edit_mode[arena_name] ~= nil then return true
  else return false
  end

end

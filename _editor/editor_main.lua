local S = minetest.get_translator("arena_lib")
local arenas_in_edit_mode = {}      -- KEY: arena name; VALUE: name of the player inside the editor
local players_in_edit_mode = {}     -- KEY: player name; VALUE: {inv (player old inventory), pos (player old position)}
local editor_tools = {
  "arena_lib:editor_players",
  "arena_lib:editor_spawners",
  "arena_lib:editor_signs",
  "arena_lib:editor_settings",
  "",
  "arena_lib:editor_info",
  "arena_lib:editor_enable",
  "arena_lib:editor_quit"
}



function arena_lib.register_editor_section(mod, def)

  local name = def.name or "Rename me via `name = something`"
  local hotbar_msg = def.hotbar_message or "Rename me via `hotbar_message = something`"

  -- non posso tradurla perché chiamata all'avvio ¯\_(ツ)_/¯
  assert(type(def.give_items) == "function", "[ARENA_LIB] (" .. mod .. ") give_items function missing in register_editor_section!")

  minetest.register_tool(mod .. ":arenalib_editor_slot_custom", {

      description = name,
      inventory_image = def.icon,
      groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
      on_place = function() end,
      on_drop = function() end,

      on_use = function(itemstack, user)

        local mod = user:get_meta():get_string("arena_lib_editor.mod")
        local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
        local id, arena = arena_lib.get_arena_by_name(mod, arena_name)
        local item_list = def.give_items(itemstack, user, arena)

        if not item_list then return end

        arena_lib.HUD_send_msg("hotbar", user:get_player_name(), hotbar_msg)

        local inv = user:get_inventory()

        minetest.after(0, function()
          inv:set_list("main", item_list)
          inv:set_stack("main", 7, "arena_lib:editor_return")
          inv:set_stack("main", 8, "arena_lib:editor_quit")
        end)
      end
  })
end



function arena_lib.enter_editor(sender, mod, arena_name)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- (non uso ARENA_LIB_EDIT_PRECHECKS_PASSED perché sono più le eccezioni che altro)
  -- se l'arena non esiste, annullo
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  -- se c'è già qualcuno (sender incluso), annullo
  if arena_lib.is_arena_in_edit_mode(arena.name) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There must be no one inside the editor of the arena to perform this command! (now inside: @1)", arenas_in_edit_mode[arena_name])))
    return end

  -- se l'arena è abilitata, la disabilito
  if arena.enabled then
    arena_lib.disable_arena(sender, mod, arena_name)
  end

  local player = minetest.get_player_by_name(sender)

  -- imposto i metadati che porto a spasso per l'editor
  player:get_meta():set_string("arena_lib_editor.mod", mod)
  player:get_meta():set_string("arena_lib_editor.arena", arena_name)

  -- metto l'arena in edit mode e salvo l'inventario
  arenas_in_edit_mode[arena_name] = sender
  players_in_edit_mode[sender] = { inv = player:get_inventory():get_list("main"), pos = player:get_pos()}

  -- se c'è almeno uno spawner, teletrasporto
  if next(arena.spawn_points) then
    arena_lib.teleport_in_arena(sender, mod, arena_name)
  end

  arena_lib.show_waypoints(sender, arena)

  -- cambio l'inventario
  arena_lib.show_main_editor(player)

end



function arena_lib.quit_editor(player)

  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  if arena_name == "" then return end

  local p_name = player:get_player_name()
  local inv = players_in_edit_mode[p_name].inv
  local pos = players_in_edit_mode[p_name].pos

  arenas_in_edit_mode[arena_name] = nil
  players_in_edit_mode[p_name] = nil

  player:get_meta():set_string("arena_lib_editor.mod", "")
  player:get_meta():set_string("arena_lib_editor.arena", "")
  player:get_meta():set_int("arena_lib_editor.players_number", 0)
  player:get_meta():set_int("arena_lib_editor.spawner_ID", 0)
  player:get_meta():set_int("arena_lib_editor.team_ID", 0)

  arena_lib.remove_waypoints(p_name)
  arena_lib.HUD_hide("hotbar", p_name)

  -- teletrasporto
  player:set_pos(pos)

  -- restituisco l'inventario
  minetest.after(0, function()
    if not minetest.get_player_by_name(p_name) then return end
    player:get_inventory():set_list("main", inv)
  end)

end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.show_main_editor(player)

  local mod = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  player:get_inventory():set_list("main", editor_tools)
  if minetest.registered_items[mod .. ":arenalib_editor_slot_custom"] then
    player:get_inventory():set_stack("main", 5, mod .. ":arenalib_editor_slot_custom")
  end

  arena_lib.HUD_send_msg("hotbar", player:get_player_name(), S("Arena_lib editor | Now editing: @1", arena_name))
end



function arena_lib.is_arena_in_edit_mode(arena_name)
  return arenas_in_edit_mode[arena_name] ~= nil
end



function arena_lib.is_player_in_edit_mode(p_name)
  return players_in_edit_mode[p_name] ~= nil
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_player_in_edit_mode(arena_name)
  return arenas_in_edit_mode[arena_name]
end

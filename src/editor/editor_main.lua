local S = minetest.get_translator("arena_lib")

local arenas_in_edit_mode = {}      -- KEY: arena name; VALUE: name of the player inside the editor
local players_in_edit_mode = {}     -- KEY: player name; VALUE: {inv, pos, hotbar_slots, hotbar_bg, item_in_hand }
local editor_tools = {
  "arena_lib:editor_players",
  "arena_lib:editor_spawners",
  "",                               -- entrance
  "arena_lib:editor_customise",
  "arena_lib:editor_settings",
  "",                               -- optional additional editor section
  "arena_lib:editor_info",
  "arena_lib:editor_enable",
  "arena_lib:editor_quit"
}



----------------------------------------
-- VISUALIZZAZIONE NOMI OGGETTI SU GLOBALSTEP
--
minetest.register_globalstep(function(dtime)
  for pl_name, pl_data in pairs(players_in_edit_mode) do
    local item = minetest.get_player_by_name(pl_name):get_wielded_item()
    if item:get_name() ~= pl_data.item_in_hand then
      local i_name = item:get_description()
      arena_lib.HUD_send_msg("hotbar", pl_name, i_name)
      pl_data.item_in_hand = i_name
    end
  end
end)
----------------------------------------



function arena_lib.register_editor_section(mod, def)
  local name = def.name or "Rename me via `name = something`"

  -- non posso tradurla perché chiamata all'avvio ¯\_(ツ)_/¯
  assert(type(def.give_items) == "function", "[ARENA_LIB] (" .. mod .. ") give_items function missing in register_editor_section!")

  minetest.register_tool(mod .. ":arenalib_editor_slot_custom", {
      description = name,
      inventory_image = def.icon,
      groups = {not_in_creative_inventory = 1},
      on_place = function() end,
      on_drop = function() end,

      on_use = function(itemstack, user)

        local mod = user:get_meta():get_string("arena_lib_editor.mod")
        local arena_name = user:get_meta():get_string("arena_lib_editor.arena")
        local _, arena = arena_lib.get_arena_by_name(mod, arena_name)
        local item_list = def.give_items(itemstack, user, arena)

        if not item_list then return end

        local inv = user:get_inventory()

        inv:set_list("main", item_list)
        inv:set_stack("main", 8, "arena_lib:editor_return")
        inv:set_stack("main", 9, "arena_lib:editor_quit")
      end
  })
end



function arena_lib.enter_editor(sender, mod, arena_name)
  local _, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- se il giocatore sta già modificando un'arena
  if arena_lib.is_player_in_edit_mode(sender) then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You must leave the editor first!")))
    return end

  if not ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena, true) then return end

  local mod_ref = arena_lib.mods[mod]

  -- se l'arena è abilitata, provo a disabilitarla
  if arena.enabled then
    if not arena_lib.disable_arena(sender, mod, arena_name) then return end
  end

  local player = minetest.get_player_by_name(sender)
  local p_cvault = {}
  local p_lighting = {}

  -- salvo le info
  p_cvault.sky        = player:get_sky(true)
  p_cvault.sun        = player:get_sun()
  p_cvault.moon       = player:get_moon()
  p_cvault.stars      = player:get_stars()
  p_cvault.clouds     = player:get_clouds()
  p_lighting.light    = player:get_day_night_ratio()
  p_lighting.shaders  = player:get_lighting()

  players_in_edit_mode[sender] = {
    inv           = player:get_inventory():get_list("main"),
    pos           = player:get_pos(),
    celvault      = p_cvault,
    lighting      = p_lighting,
    hotbar_slots  = player:hud_get_hotbar_itemcount(),
    hotbar_bg     = player:hud_get_hotbar_image()
  }

  -- metto l'arena in modalità modifica, associandoci lə giocatorə
  arenas_in_edit_mode[arena_name] = sender

  -- imposto i metadati che porto a spasso per l'editor
  player:get_meta():set_string("arena_lib_editor.mod", mod)
  player:get_meta():set_string("arena_lib_editor.arena", arena_name)

  player:hud_set_hotbar_itemcount(9)
  player:hud_set_hotbar_image("arenalib_gui_hotbar9.png")

  -- imposto eventuale volta celeste, controllando ogni elemento onde evitare un ripristino causa passaggio zero argomenti
  if arena.celestial_vault then
    local celvault = arena.celestial_vault
    if celvault.sky    then player:set_sky(celvault.sky)       end
    if celvault.sun    then player:set_sun(celvault.sun)       end
    if celvault.moon   then player:set_moon(celvault.moon)     end
    if celvault.stars  then player:set_stars(celvault.stars)   end
    if celvault.clouds then player:set_clouds(celvault.clouds) end
  end

  -- imposto eventuale illuminazione e filtri
  if arena.lighting then
    local lighting = arena.lighting
    if lighting.light   then player:override_day_night_ratio(lighting.light)  end
    if lighting.shaders then player:set_lighting(lighting.shaders)            end
  end

  -- se c'è almeno un punto di rinascita, teletrasporto
  if arena_lib.get_arena_spawners_count(arena) > 0 then
    local spawner
    if not arena.teams_enabled then
      spawner = arena.spawn_points[1]
    else
      for i = 1, #arena.teams do
        if next(arena.spawn_points[i]) then
          spawner = arena.spawn_points[i][1]
          break
        end
      end
    end

    player:set_pos(spawner)
    minetest.chat_send_player(sender, S("Wooosh!"))
  end

  arena_lib.show_waypoints(sender, mod, arena)

  -- eventuale codice aggiuntivo dell'entrata
  if arena.entrance then
    arena_lib.entrances[arena.entrance_type].enter_editor(sender, mod, arena)
  end

  -- cambio l'inventario
  arena_lib.show_main_editor(player)

  -- richiami eventuali
  if mod_ref.on_join_editor then
    mod_ref.on_join_editor(sender, arena)
  end
end



function arena_lib.quit_editor(player)

  local mod = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")

  if arena_name == "" then return end

  local p_name = player:get_player_name()

  player:get_meta():set_string("arena_lib_editor.mod", "")
  player:get_meta():set_string("arena_lib_editor.arena", "")
  player:get_meta():set_int("arena_lib_editor.players_number", 0)
  player:get_meta():set_int("arena_lib_editor.team_ID", 0)

  arena_lib.remove_waypoints(p_name)
  arena_lib.HUD_hide("hotbar", p_name)

  local celvault = players_in_edit_mode[p_name].celvault

  -- ripristino volta celeste
  player:set_sky(celvault.sky)
  player:set_sun(celvault.sun)
  player:set_moon(celvault.moon)
  player:set_stars(celvault.stars)
  player:set_clouds(celvault.clouds)

  local lighting = players_in_edit_mode[p_name].lighting

  -- ripristino illuminazione
  player:override_day_night_ratio(lighting.light)
  player:set_lighting(lighting.shaders)

  -- teletrasporto
  player:set_pos(players_in_edit_mode[p_name].pos)

  -- ripristino l'inventario
  player:hud_set_hotbar_itemcount(players_in_edit_mode[p_name].hotbar_slots)
  player:hud_set_hotbar_image(players_in_edit_mode[p_name].hotbar_bg)
  player:get_inventory():set_list("main", players_in_edit_mode[p_name].inv)

  arenas_in_edit_mode[arena_name] = nil
  players_in_edit_mode[p_name] = nil

  local mod_ref = arena_lib.mods[mod]
  local _, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- richiami eventuali
  if mod_ref.on_leave_editor then
    mod_ref.on_leave_editor(p_name, arena)
  end
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.show_main_editor(player)

  local mod = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name = player:get_meta():get_string("arena_lib_editor.arena")
  local _, arena = arena_lib.get_arena_by_name(mod, arena_name)

  player:get_inventory():set_list("main", editor_tools)
  player:get_inventory():set_stack("main", 3, arena_lib.entrances[arena.entrance_type].mod .. ":editor_entrance")
  if minetest.registered_items[mod .. ":arenalib_editor_slot_custom"] then
    player:get_inventory():set_stack("main", 6, mod .. ":arenalib_editor_slot_custom")
  end
end



function arena_lib.update_arena_in_edit_mode_name(old_name, new_name)
  arenas_in_edit_mode[new_name] = arenas_in_edit_mode[old_name]
  arenas_in_edit_mode[old_name] = nil
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

minetest.register_on_joinplayer(function(player)

  arena_lib.HUD_add(player)

  if arena_lib.STORE_INVENTORY_MODE ~= "none" then
    arena_lib.restore_inventory(player:get_player_name())
  end

  local p_meta = player:get_meta()
  local p_inv  = player:get_inventory()

  -- nel caso qualcuno si fosse disconnesso da dentro all'editor o fosse crashato il server con qualcuno nell'editor
  if p_inv:contains_item("main", "arena_lib:editor_quit") then

    p_meta:set_string("arena_lib_editor.mod", "")
    p_meta:set_string("arena_lib_editor.arena", "")
    p_meta:set_int("arena_lib_editor.players_number", 0)
    p_meta:set_int("arena_lib_editor.spawner_ID", 0)
    p_meta:set_int("arena_lib_editor.team_ID", 0)

    if minetest.get_modpath("hub_manager") then return end          -- se c'è hub_manager, ci pensa quest'ultimo allo svuotamento dell'inventario

    p_inv:set_list("main", {})
    p_inv:set_list("craft", {})

  -- se invece era in spettatore
elseif p_inv:get_list("hand") and p_inv:contains_item("hand", "arena_lib:spectate_hand") then
    p_inv:set_stack("hand", 1, nil)
    p_inv:set_size("hand", 0)
  end

  p_meta:set_string("arenalib_infobox_mod", "")
  p_meta:set_int("arenalib_infobox_arenaID", 0)
end)



minetest.register_on_leaveplayer(function(player)

    local p_name = player:get_player_name()

    if arena_lib.is_player_in_arena(p_name) then
      arena_lib.remove_player_from_arena(p_name, 0)
    elseif arena_lib.is_player_in_queue(p_name) then
      arena_lib.remove_player_from_queue(p_name)
    elseif arena_lib.is_player_in_edit_mode(p_name) then
      arena_lib.quit_editor(player)
    elseif arena_lib.is_player_in_settings(p_name) then
      arena_lib.quit_minigame_settings(p_name)
    end

    arena_lib.HUD_remove(p_name)
end)



minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)

    local t_name = player:get_player_name()
    local p_name = hitter:get_player_name()
    local t_arena = arena_lib.get_arena_by_player(t_name)
    local p_arena = arena_lib.get_arena_by_player(p_name)

    -- se nessuno dei due è perlomeno in coda, lascio spazio agli altri eventuali on_punchplayer
    if not p_arena and not t_arena then
      return
    end

    local is_p_queuing = arena_lib.is_player_in_queue(p_name)
    local is_t_queuing = arena_lib.is_player_in_queue(t_name)
    local is_p_playing = arena_lib.is_player_in_arena(p_name)
    local is_t_playing = arena_lib.is_player_in_arena(t_name)

    -- se nessuno dei due è in partita, ma solo al massimo in coda, lascio spazio agli altri eventuali on_punchplayer
    if (is_p_queuing and not is_t_playing) or
       (is_t_queuing and not is_p_playing) then
      return
    end

    -- se uno è in partita e l'altro no, annullo
    if (is_p_playing and not is_t_playing) or
       (is_t_playing and not is_p_playing) then
      return true
    end

    -- se sono nella stessa partita e nella stessa squadra, annullo
    if p_arena.teams_enabled and arena_lib.is_player_in_same_team(p_arena, p_name, t_name) then
      return true
    end
end)



minetest.register_on_player_hpchange(function(player, hp_change, reason)

    local p_name = player:get_player_name()
    local mod = arena_lib.get_mod_by_player(p_name)

    -- se non è in partita, annullo
    if not mod then return hp_change end

    -- se è spettatore, annullo
    if arena_lib.is_player_spectating(p_name) and reason.type ~= "respawn" then
      return 0
    end

    -- se un tipo di danno è disabilitato, annullo
    for _, disabled_damage in pairs(arena_lib.mods[mod].disabled_damage_types) do
      if reason.type == disabled_damage then
        return 0
      end
    end

    return hp_change

end, true)



minetest.register_on_dieplayer(function(player, reason)

    local p_name = player:get_player_name()
    if not arena_lib.is_player_in_arena(p_name) then return end

    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(p_name)]
    local arena = arena_lib.get_arena_by_player(p_name)
    local p_stats = arena.players[p_name]
    p_stats.deaths = p_stats.deaths +1

    if mod_ref.on_death then
      mod_ref.on_death(arena, p_name, reason)
    end

  end)



minetest.register_on_respawnplayer(function(player)

    local p_name = player:get_player_name()

    if not arena_lib.is_player_in_arena(p_name) then return end

    local arena = arena_lib.get_arena_by_player(p_name)

    if not arena_lib.is_player_spectating(p_name) then
      player:set_pos(arena_lib.get_random_spawner(arena, arena.players[p_name].teamID))
    end
    return true
  end)

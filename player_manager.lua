minetest.register_on_joinplayer(function(player)

  arena_lib.HUD_add(player)

  -- nel caso qualcuno si fosse disconnesso da dentro all'editor o fosse crashato il server con qualcuno nell'editor
  if player:get_inventory():contains_item("main", "arena_lib:editor_quit") then

    local p_meta = player:get_meta()

    p_meta:set_string("arena_lib_editor.mod", "")
    p_meta:set_string("arena_lib_editor.arena", "")
    p_meta:set_int("arena_lib_editor.spawner_ID", 0)
    p_meta:set_int("arena_lib_editor.team_ID", 0)

    if minetest.get_modpath("hub_manager") then return end          -- se c'è hub_manager, ci pensa quest'ultimo allo svuotamento dell'inventario

    player:get_inventory():set_list("main", {})
  end

end)


minetest.register_on_leaveplayer(function(player)

    local p_name = player:get_player_name()

    arena_lib.remove_player_from_arena(p_name)
    arena_lib.quit_editor(player)
end)



minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)

    local target_name = player:get_player_name()
    local p_name = hitter:get_player_name()
    local arena = arena_lib.get_arena_by_player(p_name)

    if arena and arena.players[p_name].teamID and arena.players[p_name].teamID == arena.players[target_name].teamID then
      return true
    end

end)



minetest.register_on_player_hpchange(function(player, hp_change, reason)

    if player:get_inventory():contains_item("main", "arena_lib:immunity") and reason.type ~= "respawn" then
      return 0
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

    player:set_pos(arena_lib.get_random_spawner(arena, arena.players[p_name].teamID))
    arena_lib.immunity(player)
    return true

  end)



minetest.register_on_chat_message(function(p_name, message)

  if arena_lib.is_player_in_arena(p_name) then
    arena_lib.send_message_players_in_arena(arena_lib.get_arena_by_player(p_name), minetest.format_chat_message(p_name, message))
    return true
  else
    for _, pl_stats in pairs(minetest.get_connected_players()) do
      local pl_name = pl_stats:get_player_name()
      if not arena_lib.is_player_in_arena(pl_name) then
        minetest.chat_send_player(pl_name, minetest.format_chat_message(p_name, message))
      end
    end
  end

  return true
end)

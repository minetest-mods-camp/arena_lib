minetest.register_on_joinplayer(function(player)

  arena_lib.HUD_add(player)

  -- nel caso qualcuno si fosse disconnesso da dentro all'editor o fosse crashato il server con qualcuno nell'editor
  if player:get_inventory():contains_item("main", "arena_lib:editor_quit") then

    local p_meta = player:get_meta()

    p_meta:set_string("arena_lib_editor.mod", "")
    p_meta:set_string("arena_lib_editor.arena", "")
    p_meta:set_string("arena_lib_editor.spawner_ID", "")

    if minetest.get_modpath("hub_manager") then return end          -- se c'è hub_manager, ci pensa quest'ultimo allo svuotamento dell'inventario

    player:get_inventory():set_list("main", {})
  end

end)


minetest.register_on_leaveplayer(function(player)

    local p_name = player:get_player_name()

    arena_lib.remove_player_from_arena(p_name)
    arena_lib.quit_editor(player)
end)



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

    player:set_pos(arena_lib.get_random_spawner(arena))
    arena_lib.immunity(player)
    return true

  end)

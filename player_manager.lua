minetest.register_on_joinplayer(function(player)

  player:set_pos(arena_lib.get_hub_spawn_point())
  --arena_lib.register_player_inputs(player:get_player_name())

end)


minetest.register_on_leaveplayer(function(player)

    local p_name = player:get_player_name()

    arena_lib.remove_player_from_arena(p_name)
end)



minetest.register_on_dieplayer(function(player, reason)

    local p_name = player:get_player_name()
    if not arena_lib.is_player_in_arena(p_name) then return end

    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(p_name)]
    local arena = arena_lib.get_arena_by_player(p_name)
    local p_stats = arena.players[p_name]
    p_stats.deaths = p_stats.deaths +1
    p_stats.killstreak = 0

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

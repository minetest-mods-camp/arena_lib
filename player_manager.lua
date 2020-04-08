minetest.register_on_joinplayer(function(player)

  player:set_pos(arena_lib.get_hub_spawnpoint())

end)


minetest.register_on_leaveplayer(function(player)

    local p_name = player:get_player_name()
    if arena_lib.get_arenaID_by_player(p_name) == nil and arena_lib.get_queueID_by_player(p_name) == nil then return end

    minetest.chat_send_player("Zughy", "Vado sul remove player")

    arena_lib.remove_player_from_arena(p_name)
end)



minetest.register_on_dieplayer(function(player, reason)

    local p_name = player:get_player_name()
    if not arena_lib.is_player_in_arena(p_name) then return end

    local arena = arena_lib.arenas[arena_lib.get_arenaID_by_player(p_name)]
    local p_stats = arena.players[p_name]
    p_stats.deaths = p_stats.deaths +1
    p_stats.killstreak = 0

    arena_lib.on_death(arena, p_name)

  end)


function arena_lib.on_death(arena, p_name)
  --DO STUFF, override me if you need to
end



minetest.register_on_respawnplayer(function(player)

    local arenaID = arena_lib.get_arenaID_by_player(player:get_player_name())
    if arenaID == nil then return end

    player:set_pos(arena_lib.get_random_spawner(arenaID))
    arena_lib.immunity(player)
    return true

  end)

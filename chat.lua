minetest.register_on_chat_message(function(p_name, message)

  if arena_lib.is_player_in_arena(p_name) then

    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(p_name)]
    local arena = arena_lib.get_arena_by_player(p_name)

    if #arena.teams > 1 then
      if mod_ref.is_team_chat_default then
        arena_lib.send_message_players_in_arena(arena, minetest.colorize(mod_ref.chat_team_color, mod_ref.chat_team_prefix .. minetest.format_chat_message(p_name, message)), arena.players[p_name].teamID)
      else
        arena_lib.send_message_players_in_arena(arena, minetest.colorize(mod_ref.chat_team_color, mod_ref.chat_all_prefix .. minetest.format_chat_message(p_name, message)), arena.players[p_name].teamID)
        arena_lib.send_message_players_in_arena(arena, minetest.colorize("#ffdddd", mod_ref.chat_all_prefix .. minetest.format_chat_message(p_name, message)), arena.players[p_name].teamID, true)
      end
    else
      arena_lib.send_message_players_in_arena(arena, minetest.colorize(mod_ref.chat_all_color, mod_ref.chat_all_prefix .. minetest.format_chat_message(p_name, message)))
    end
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

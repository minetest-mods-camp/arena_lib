-- nel caso arena_lib venisse registrata prima di altre mod che interferiscono
-- con la chat (ponti IRC, chat di clan ecc.), i controlli che seguono verrebbero
-- eseguiti prima delle mod sopracitate, annullandole a priori (perché i controlli
-- vanno in ordine di registrazione). Evito ciò registrando i controlli della chat
-- delle arene solo dopo che tutte le mod sono già state caricate (e quindi registrate)
minetest.register_on_mods_loaded(function()
  minetest.register_on_chat_message(function(p_name, message)

    if arena_lib.is_player_in_arena(p_name) then

      local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(p_name)]
      local arena = arena_lib.get_arena_by_player(p_name)

      -- se è in celebrazione, tutti posson parlare con tutti
      if arena.in_celebration then
        local col, prefix
        if arena_lib.is_player_spectating(p_name) then
          col = mod_ref.chat_spectate_color
          prefix = mod_ref.chat_spectate_prefix
        else
          if arena.teams_enabled then
            col = mod_ref.chat_team_color
            prefix = mod_ref.chat_team_prefix
          else
            col = "#ffdddd"
            prefix = mod_ref.chat_all_prefix
          end
        end

        arena_lib.send_message_in_arena(arena, "both", minetest.colorize(col, prefix .. minetest.format_chat_message(p_name, message)))
        return true
      end


      if arena_lib.is_player_spectating(p_name) then
        arena_lib.send_message_in_arena(arena, "spectators", minetest.colorize(mod_ref.chat_spectate_color, mod_ref.chat_spectate_prefix .. minetest.format_chat_message(p_name, message)))
      else
        if arena.teams_enabled then
          if mod_ref.is_team_chat_default then
            arena_lib.send_message_in_arena(arena, "players", minetest.colorize(mod_ref.chat_team_color, mod_ref.chat_team_prefix .. minetest.format_chat_message(p_name, message)), arena.players[p_name].teamID)
          else
            arena_lib.send_message_in_arena(arena, "players", mod_ref.chat_all_prefix .. minetest.format_chat_message(p_name, message), arena.players[p_name].teamID)
            arena_lib.send_message_in_arena(arena, "players", minetest.colorize("#ffdddd", mod_ref.chat_all_prefix .. minetest.format_chat_message(p_name, message)), arena.players[p_name].teamID, true)
          end
        else
          arena_lib.send_message_in_arena(arena, "players", minetest.colorize(mod_ref.chat_all_color, mod_ref.chat_all_prefix .. minetest.format_chat_message(p_name, message)))
        end
        return true
      end
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
end)

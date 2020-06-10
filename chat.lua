local S = minetest.get_translator("arena_lib")



minetest.register_chatcommand("quit", {

  description = S("Quit an ongoing game"),

  func = function(name, param)
    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" ,S("[!] You're not in a match!")))
      return false end

    arena_lib.remove_player_from_arena(name, 3)
    return true
  end
})



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

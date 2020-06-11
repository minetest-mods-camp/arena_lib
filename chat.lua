local S = minetest.get_translator("arena_lib")



minetest.register_chatcommand("kick", {

  description = S("Kick a player from an ongoing game"),
  privs = {
        arenalib_admin = true,
    },

  func = function(sender, param)
    local p_name = string.match(param, "^([%a%d_-]+)$")

    -- se non è specificato niente, annullo
    if not p_name then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Unknown parameter!")))
      return false end

    -- se il giocatore non è online, annullo
    if not minetest.get_player_by_name(p_name) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This player is not online!")))
      return false end

    -- se il giocatore non è in partita, annullo
    if not arena_lib.is_player_in_arena(p_name) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e" ,S("[!] The player must be in a game to perform this action!")))
      return false end

    minetest.chat_send_player(sender, S("Player successfully kicked"))
    arena_lib.remove_player_from_arena(p_name, 2)
    return true
  end
})



minetest.register_chatcommand("quit", {

  description = S("Quit an ongoing game"),

  func = function(name, param)
    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    local arena = arena_lib.get_arena_by_player(name)

    -- se è l'ultimo giocatore rimasto, annullo
    if arena.players_amount == 1 then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e" ,S("[!] You can't perform this action if you're the only one left!")))
      return end

    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(name)]

    -- se uso /quit e on_prequit ritorna false, annullo
    if mod_ref.on_prequit then
      if mod_ref.on_prequit(arena, name) == false then
      return false end
    end

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

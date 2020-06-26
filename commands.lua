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



minetest.register_chatcommand("all", {

  description = S("Write a message in the arena global chat while in a game"),

  func = function(name, param)

    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    local msg = string.match(param, ".*")
    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(name)]
    local arena = arena_lib.get_arena_by_player(name)

    arena_lib.send_message_players_in_arena(arena, minetest.colorize(mod_ref.chat_all_color, mod_ref.chat_all_prefix .. minetest.format_chat_message(name, msg)))
    return true
  end
})



minetest.register_chatcommand("t", {

  description = S("Write a message in the arena team chat while in a game (if teams are enabled)"),

  func = function(name, param)

    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    local msg = string.match(param, ".*")
    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(name)]
    local arena = arena_lib.get_arena_by_player(name)
    local teamID = arena.players[name].teamID

    if not teamID then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] Teams are not enabled!")))
      return false end

    arena_lib.send_message_players_in_arena(arena, minetest.colorize(mod_ref.chat_team_color, mod_ref.chat_team_prefix .. minetest.format_chat_message(name, msg)), teamID)
    return true
  end
})

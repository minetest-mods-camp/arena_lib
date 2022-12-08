local S = minetest.get_translator("arena_lib")



----------------------------------------------
-----------------ADMINS ONLY------------------
----------------------------------------------

ChatCmdBuilder.new("arenas", function(cmd)
  cmd:sub("entrances :minigame", function(sender, minigame)
    arena_lib.enter_entrance_settings(sender, minigame)
  end)

  cmd:sub("settings :minigame", function(sender, minigame)
    arena_lib.enter_minigame_settings(sender, minigame)
  end)

  cmd:sub("kick :player", function(sender, p_name)
    -- se il giocatore non è online, annullo
    if not minetest.get_player_by_name(p_name) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This player is not online!")))
      return end

    -- se il giocatore non è in partita, annullo
    if not arena_lib.is_player_in_arena(p_name) then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e" ,S("[!] The player must be in a game to perform this action!")))
      return end

    arena_lib.remove_player_from_arena(p_name, 2, sender)
    minetest.chat_send_player(sender, S("Player successfully kicked"))
  end)

end, {
  params = "[entrances|kick|settings] <" .. S("minigame") .. "|" .. S("player") .. ">",
  description = S("Manage arena_lib arenas; it requires arenalib_admin") .. "\n"
    .. "/arenas entrances <" .. S("minigame") .. ">\n"
    .. "/arenas kick <" .. S("player") .. ">\n"
    .. "/arenas settings <" .. S("minigame") .. ">",
  privs = { arenalib_admin = true }
})


-- TODO: integrare in /arenas, "forceend", iterando per tutte le arene di tutti i minigiochi. Se trova doppioni, avvisa che va specificato anche il minigioco
minetest.register_chatcommand("forceend", {

  params = "<" .. S("minigame") .. "> <" .. S("arena name") .. ">",
  description = S("Forcibly ends an ongoing game"),
  privs = {
        arenalib_admin = true,
    },

  func = function(sender, param)

    local mod, arena_name = string.match(param, "^([%a%d_-]+) ([%a%d_-]+)$")

    -- se i parametri sono errati, annullo
    if not mod or not arena_name then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
      return end

    local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

    -- se è andata a buon fine, avviso chi ha eseguito il comando
    if arena_lib.force_arena_ending(mod, arena, sender) then
      minetest.chat_send_player(sender, S("Game in arena @1 successfully terminated", arena.name))
    end
  end

})


-- TODO: idem come il comando sopra, "flush"
minetest.register_chatcommand("flusharena", {

  params = "<" .. S("minigame") .. "> <" .. S("arena name") .. ">",
  description = S("DEBUG ONLY: reset the properties of a bugged arena"),
  privs = {
        arenalib_admin = true,
    },

  func = function(sender, param)
    local mod, arena_name = string.match(param, "^([%a%d_-]+) ([%a%d_-]+)$")

    -- se i parametri sono errati, annullo
    if not mod or not arena_name then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Parameters don't seem right!")))
      return end

    arena_lib.flush_arena(mod, arena_name, sender)
  end

})





----------------------------------------------
----------------FOR EVERYONE------------------
----------------------------------------------

minetest.register_chatcommand("quit", {

  description = S("Quits an ongoing game"),

  func = function(name, param)

    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    local arena = arena_lib.get_arena_by_player(name)

    -- se l'arena è in celebrazione, annullo
    if arena.in_celebration then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" ,S("[!] You can't perform this action during the celebration phase!")))
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

  params = "<" .. S("message") .. ">",
  description = S("Writes a message in the arena global chat while in a game"),

  func = function(name, param)

    -- se non è in arena, annullo
    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    -- se è spettatore, annullo
    if arena_lib.is_player_spectating(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    local msg = string.match(param, ".*")
    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(name)]
    local arena = arena_lib.get_arena_by_player(name)

    arena_lib.send_message_in_arena(arena, "players", minetest.colorize(mod_ref.chat_all_color, mod_ref.chat_all_prefix .. minetest.format_chat_message(name, msg)))
    return true
  end
})



minetest.register_chatcommand("t", {

  params = "<" .. S("message") .. ">",
  description = S("Writes a message in the arena team chat while in a game (if teams are enabled)"),

  func = function(name, param)

    -- se non è in arena, annullo
    if not arena_lib.is_player_in_arena(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    -- se è spettatore, annullo
    if arena_lib.is_player_spectating(name) then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] You must be in a game to perform this action!")))
      return false end

    local msg = string.match(param, ".*")
    local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(name)]
    local arena = arena_lib.get_arena_by_player(name)
    local teamID = arena.players[name].teamID

    if not teamID then
      minetest.chat_send_player(name, minetest.colorize("#e6482e" , S("[!] Teams are not enabled!")))
      return false end

    arena_lib.send_message_in_arena(arena, "players", minetest.colorize(mod_ref.chat_team_color, mod_ref.chat_team_prefix .. minetest.format_chat_message(name, msg)), teamID)
    return true
  end
})






----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

-- to remove in 7.0
minetest.register_chatcommand("arenakick", {
  params = "<" .. S("player") .. "> (deprecated)",
  description = "DEPRECATED, use '/arenas kick <nick>' instead",
  privs = {
        arenalib_admin = true,
    },
  func = function(sender, param)
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] DEPRECATED! Use '/arenas kick <nick>' instead!"))
  end
})

minetest.register_chatcommand("minigamesettings", {
  params = "<" ..S("minigame") .. "> (deprecated)",
  description = "DEPRECATED, use '/arenas settings <minigame>' instead",
  privs = {
    arenalib_admin = true,
  },
  func = function(sender, param)
    local mod = param
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] DEPRECATED! Use '/arenas settings <minigame>' instead!"))
  end
})

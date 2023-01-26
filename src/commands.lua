local S = minetest.get_translator("arena_lib")

local function get_minigames_by_arena() end



----------------------------------------------
-----------------ADMINS ONLY------------------
----------------------------------------------

ChatCmdBuilder.new("arenas", function(cmd)

  -- gestione arena
  cmd:sub("create :minigame :arena", function(sender, minigame, arena)
    arena_lib.create_arena(sender, minigame, arena)
  end)

  cmd:sub("create :minigame :arena :pmin:int :pmax:int", function(sender, minigame, arena, min, max)
    arena_lib.create_arena(sender, minigame, arena, min, max)
  end)

  cmd:sub("edit :minigame :arena", function(sender, minigame, arena)
    arena_lib.enter_editor(sender, minigame, arena)
  end)

  cmd:sub("edit :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

    arena_lib.enter_editor(sender, minigames[1], arena)
  end)

  cmd:sub("remove :minigame :arena", function(sender, minigame, arena)
    arena_lib.remove_arena(sender, minigame, arena)
  end)

  cmd:sub("remove :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

    arena_lib.remove_arena(sender, minigames[1], arena)
  end)

  -- abilita/disabilita
  cmd:sub("enable :minigame :arena", function(sender, minigame, arena)
    arena_lib.enable_arena(sender, minigame, arena)
  end)

  cmd:sub("enable :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

    arena_lib.enable_arena(sender, minigames[1], arena)
  end)

  cmd:sub("disable :minigame :arena", function(sender, minigame, arena)
    arena_lib.disable_arena(sender, minigame, arena)
  end)

  cmd:sub("disable :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

    arena_lib.disable_arena(sender, minigames[1], arena)
  end)

  -- utilità arene
  cmd:sub("info :minigame :arena", function(sender, minigame, arena)
    arena_lib.print_arena_info(sender, minigame, arena)
  end)

  cmd:sub("info :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

    arena_lib.print_arena_info(sender, minigames[1], arena)
  end)

  cmd:sub("list :minigame", function(sender, minigame)
    arena_lib.print_arenas(sender, minigame)
  end)

  cmd:sub("flush :minigame :arena", function(sender, minigame, arena)
    arena_lib.flush_arena(minigame, arena, sender)
  end)

  cmd:sub("flush :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

    arena_lib.flush_arena(minigames[1], arena, sender)
  end)

  cmd:sub("forceend :minigame :arena", function(sender, minigame, arena)
    local id, ar = arena_lib.get_arena_by_name(minigame, arena)

    if arena_lib.force_arena_ending(minigame, ar, sender) then
      minetest.chat_send_player(sender, S("Game in arena @1 successfully terminated", arena))
    end
  end)

  cmd:sub("forceend :arena", function(sender, arena)
    local minigames = get_minigames_by_arena(arena)
    if #minigames > 1 then
      minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There are more minigames having an arena called @1: please specify the name of the minigame before the name of the arena, separating them with a space", arena)))
      return end

      local id, ar = arena_lib.get_arena_by_name(minigames[1], arena)

    if arena_lib.force_arena_ending(minigames[1], ar, sender) then
      minetest.chat_send_player(sender, S("Game in arena @1 successfully terminated", arena))
    end
  end)

  -- gestione minigiochi
  cmd:sub("entrances :minigame", function(sender, minigame)
    arena_lib.enter_entrance_settings(sender, minigame)
  end)

  cmd:sub("settings :minigame", function(sender, minigame)
    arena_lib.enter_minigame_settings(sender, minigame)
  end)

  cmd:sub("glist", function(sender)
    arena_lib.print_minigames(sender)
  end)

  cmd:sub("gamelist", function(sender)
    arena_lib.print_minigames(sender)
  end)

  -- gestione utenti
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

  -- aiuto
  --[[ TODO: per elencare comandi con descrizione geolocalizzata e con sintassi colorata tipo World Edit. In /help è orribile, rimuovere da lì. !Alcune traduzioni stanno già nei file di localizzazione!
  cmd:sub("help", function(sender)
    minetest.chat_send_player(sender, "TUTTI I VARI COMANDI")
  end)
  ]]

end, {
  params = "[ create | disable | edit | enable | entrances | flush | forceend | gamelist | glist | info | kick | list | remove | settings ]",
  description = S("Manage arena_lib arenas; it requires arenalib_admin") .. "\n"
    .. "/arenas create <" .. S("minigame") .. "> <" .. S("arena") .. "> (<pmin> <pmax>)\n"
    .. "/arenas disable (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas edit (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas enable (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas entrances <" .. S("minigame") .. ">\n"
    .. "/arenas flush (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas forceend (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas gamelist \n"
    .. "/arenas glist \n"
    .. "/arenas info (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas kick <" .. S("player") .. ">\n"
    .. "/arenas list <" .. S("minigame") .. ">\n"
    .. "/arenas remove (<" .. S("minigame") .. ">) <" .. S("arena") .. ">\n"
    .. "/arenas settings <" .. S("minigame") .. ">",
  privs = { arenalib_admin = true }
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
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_minigames_by_arena(arena_name)
  local mgs = {}
  for mg, mg_data in pairs(arena_lib.mods) do
    for _, arena in pairs(mg_data.arenas) do
      if arena.name == arena_name then
        table.insert(mgs, mg)
        break
      end
    end
  end
  return mgs
end





----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

-- to remove in 7.0
minetest.register_chatcommand("arenakick", {
  params = "(deprecated)",
  description = "DEPRECATED, use '/arenas kick <nick>' instead",
  privs = {
        arenalib_admin = true,
    },
  func = function(sender, param)
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] DEPRECATED! Use '/arenas kick <nick>' instead!"))
  end
})

minetest.register_chatcommand("minigamesettings", {
  params = "(deprecated)",
  description = "DEPRECATED, use '/arenas settings <minigame>' instead",
  privs = {
    arenalib_admin = true,
  },
  func = function(sender, param)
    local mod = param
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] DEPRECATED! Use '/arenas settings <minigame>' instead!"))
  end
})

minetest.register_chatcommand("flusharena", {

  params = "(deprecated)",
  description = "DEPRECATED, use '/arenas flush (<minigame>) <arena>' instead",
  privs = {
        arenalib_admin = true,
  },
  func = function(sender, param)
    local mod = param
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] DEPRECATED! Use '/arenas flush (<minigame>) <arena>' instead!"))
  end
})

minetest.register_chatcommand("forceend", {
  params = "(deprecated)",
  description = "DEPRECATED, use '/arenas forceend (<minigame>) <arena>' instead",
  privs = {
        arenalib_admin = true,
  },
  func = function(sender, param)
    local mod = param
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] DEPRECATED! Use '/arenas forceend (<minigame>) <arena>' instead!"))
  end

})

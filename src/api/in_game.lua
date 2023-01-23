local S = minetest.get_translator("arena_lib")

local function assign_team_spawner() end
local function operations_before_entering_arena() end
local function operations_before_playing_arena() end
local function operations_before_leaving_arena() end
local function eliminate_player() end
local function handle_leaving_callbacks() end
local function victory_particles() end
local function show_victory_particles() end
local function time_start() end
local function deprecated_winning_team_celebration() end
local function deprecated_start_arena() end

local players_in_game = {}            -- KEY: player name, VALUE: {(string) minigame, (int) arenaID}
local players_temp_storage = {}       -- KEY: player_name, VALUE: {(int) hotbar_slots, (string) hotbar_background_image, (string) hotbar_selected_image,
                                      --                           (int) bgm_handle, (int) fov, (table) camera_offset, (table) armor_groups, (string) inventory_fs)}




-- per tutti i giocatori quando finisce la coda
function arena_lib.load_arena(mod, arena_ID)

  -- my child, let's talk about some black magic: in order to teleport players in their team spawners, first of all I need to
  -- sort them by team. Once it's done, I need to skip every spawner of that team if the maximum number of players is not reached:
  -- otherwise, people will find theirselves in the wrong team (and you don't want that to happen). So I use this int to prevent it,
  -- which increases by 1 or more every time I look for a spawner, comparing the 'team' spawner value to the player's. This happens
  -- in assign_team_spawner, which also returns the new value for team_count
  local team_count = 1

  local count = 1
  local mod_ref = arena_lib.mods[mod]
  local arena = mod_ref.arenas[arena_ID]

  arena.in_loading = true
  arena_lib.entrances[arena.entrance_type].update(mod, arena)

  local shuffled_spawners = table.copy(arena.spawn_points)
  local sorted_team_players = {}

  -- aggiungo eventuali proprietà temporanee
  for temp_property, v in pairs(mod_ref.temp_properties) do
    if type(v) == "table" then
      arena[temp_property] = table.copy(v)
    else
      arena[temp_property] = v
    end
  end

  -- randomizzo gli spawner se non è a squadre
  if not arena.teams_enabled then
    for i = #shuffled_spawners, 2, -1 do
      local j = math.random(i)
      shuffled_spawners[i], shuffled_spawners[j] = shuffled_spawners[j], shuffled_spawners[i]
    end
  -- sennò ordino i giocatori per squadra
  else
    local j = 1
    for i = 1, #arena.teams do
      for pl_name, pl_stats in pairs(arena.players) do
        if pl_stats.teamID == i then
          sorted_team_players[j] = {name = pl_name, teamID = pl_stats.teamID}
          j = j +1
        end
      end

      -- e aggiungo eventuali proprietà per ogni squadra
      for k, v in pairs(mod_ref.team_properties) do
        arena.teams[i][k] = v
      end
    end
  end

  -- per ogni giocatore...
  for pl_name, _ in pairs(arena.players) do

    operations_before_entering_arena(mod_ref, mod, arena, arena_ID, pl_name)

    -- teletrasporto i giocatori
    if not arena.teams_enabled then
      minetest.get_player_by_name(pl_name):set_pos(shuffled_spawners[count].pos)
    else
      team_count = assign_team_spawner(arena.spawn_points, team_count, sorted_team_players[count].name, sorted_team_players[count].teamID)
    end

    count = count +1
  end

  -- se supporta la spettatore, inizializzo le varie tabelle
  if mod_ref.spectate_mode then
    arena.spectate_entities_amount = 0
    arena.spectate_areas_amount = 0
    arena_lib.init_spectate_containers(mod, arena.name)
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_load then
    mod_ref.on_load(arena)
  end

  for _, callback in ipairs(arena_lib.registered_on_load) do
    callback(mod_ref, arena)
  end

  -- avvio la partita dopo tot secondi, se non è già stata avviata manualmente
  minetest.after(mod_ref.load_time, function()
    if not arena.in_loading then return end
    arena_lib.start_arena(mod, arena)
  end)

end



function arena_lib.start_arena(mod, arena)

  if type(mod) == "table" then
    mod = deprecated_start_arena(arena)
  end

  -- nel caso sia terminata durante la fase di caricamento
  if arena.in_celebration or not arena.in_game then return end

  -- se era già in corso
  if not arena.in_loading then
    minetest.log("error", debug.traceback("[" .. arena.name .. "] There has been an attempt to call the fighting phase whilst already in it. This shall not be done, aborting..."))
    return end

  arena.in_loading = false
  arena_lib.entrances[arena.entrance_type].update(mod, arena)

  local mod_ref = arena_lib.mods[mod]

  -- parte l'eventuale tempo
  if mod_ref.time_mode ~= "none" then
    arena.current_time = arena.initial_time
    minetest.after(1, function()
      time_start(mod_ref, arena)
    end)
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_start then
    mod_ref.on_start(arena)
  end

  for _, callback in ipairs(arena_lib.registered_on_start) do
    callback(mod_ref, arena)
  end
end



-- per chi entra a partita iniziata
function arena_lib.join_arena(mod, p_name, arena_ID, as_spectator)

  local mod_ref = arena_lib.mods[mod]
  local arena = mod_ref.arenas[arena_ID]

  -- se non è in corso
  if not arena.in_game then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] No ongoing game!")))
    return end

  local players -- potrebbe essere un gruppo
  local was_spectator = {}

  -- se prova a entrare come spettatore
  if as_spectator then
    -- se non supporta la spettatore
    if not arena_lib.mods[mod].spectate_mode then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Spectate mode not supported!")))
      return end

    -- se l'arena non è abilitata
    if not arena.enabled then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
      return end

    -- se si è attaccati a qualcosa
    if minetest.get_player_by_name(p_name):get_attach() then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must detach yourself from the entity you're attached to before entering!")))
      return end

    -- se non c'è niente da seguire
    if arena.players_amount == 0 and not next(arena_lib.get_spectate_entities(mod, arena.name)) and not next(arena_lib.get_spectate_areas(mod, arena.name)) then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is nothing to spectate!")))
      return end

    -- se si era in coda
    if arena_lib.is_player_in_queue(p_name) then
      if not arena_lib.remove_player_from_queue(p_name) then return end
    end

    players = {[1] = p_name}
    operations_before_entering_arena(mod_ref, mod, arena, arena_ID, p_name, true)
    arena_lib.enter_spectate_mode(p_name, arena)
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#cfc6b8", ">>> " .. p_name .. " (" .. S("spectator") .. ")"))

  -- se entra come giocatore
  else
    if not ARENA_LIB_JOIN_CHECKS_PASSED(arena, arena_ID, p_name) then return end

    -- se sta caricando o sta finendo
    if arena.in_loading or arena.in_celebration then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is loading, try again in a few seconds!")))
      return end

    -- se è in corso e non permette l'entrata
    if not mod_ref.join_while_in_progress then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] This minigame doesn't allow to join while in progress!")))
      return end

    -- se si era in coda
    if arena_lib.is_player_in_queue(p_name) then
      if not arena_lib.remove_player_from_queue(p_name) then return end
    end

    players = arena_lib.get_and_add_joining_players(mod_ref, arena, p_name)

    for i, pl_name in pairs(players) do
      -- se stava in spettatore..
      if arena_lib.is_player_spectating(pl_name) then
        local pl_arena = arena_lib.get_arena_by_player(pl_name)
        local pl_mg = arena_lib.get_mod_by_player(pl_name)

        -- ..controllo se stava seguendo la stessa arena in cui si sta entrando (in caso di gruppo sparso in più parti)
        if pl_arena.name == arena.name and pl_mg == mod then
          was_spectator[i] = true
          arena_lib.leave_spectate_mode(pl_name)
          minetest.get_player_by_name(pl_name):get_inventory():set_list("main", {}) -- rimuovo gli oggetti della spettatore
          operations_before_playing_arena(mod_ref, arena, pl_name)
        else
          arena_lib.remove_player_from_arena(pl_name, 3)
          operations_before_entering_arena(mod_ref, mod, arena, arena_ID, pl_name)
        end

      -- sennò entra normalmente
      else
        operations_before_entering_arena(mod_ref, mod, arena, arena_ID, pl_name)
      end
    end

    local teamID = arena.players[p_name].teamID

    -- notifico e teletrasporto
    for _, pl_name in pairs(players) do
      local player = minetest.get_player_by_name(pl_name)
      local random_spawner = arena_lib.get_random_spawner(arena, teamID)

      arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#c6f154", " >>> " .. pl_name))
      player:set_pos(random_spawner)
      -- TEMP: waiting for https://github.com/minetest/minetest/issues/12092 to be fixed. Forcing the teleport twice on two different steps. Necessary for whom was spectating
      minetest.after(0.1, function()
        player:set_pos(random_spawner)
      end)
    end
  end

  -- eventuale codice aggiuntivo
  for i, pl_name in pairs(players) do
    if mod_ref.on_join then
      mod_ref.on_join(pl_name, arena, as_spectator, was_spectator[i])
    end

    for _, callback in ipairs(arena_lib.registered_on_join) do
      callback(mod_ref, arena, pl_name, as_spectator, was_spectator[i])
    end
  end

  arena_lib.entrances[arena.entrance_type].update(mod, arena)
end



-- a partita finita
-- `winners` può essere stringa (giocatore singolo), intero (squadra) o tabella di uno di questi (più giocatori o squadre)
function arena_lib.load_celebration(mod, arena, winners)

  -- se era già in celebrazione
  if arena.in_celebration then
    minetest.log("error", debug.traceback("[" .. mod .. "] There has been an attempt to call the celebration phase whilst already in it. This shall not be done, aborting..."))
    return end

  arena.in_celebration = true
  arena_lib.entrances[arena.entrance_type].update(mod, arena)

  -- ripristino HP e visibilità nome di ogni giocatore
  for pl_name, stats in pairs(arena.players) do
    local player = minetest.get_player_by_name(pl_name)

    player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})
  end

  local winning_message = ""

  -- determino il messaggio da inviare
  -- se è stringa, è giocatore singolo
  if type(winners) == "string" then
      winning_message = S("@1 wins the game", winners)

  -- se è un ID è una squadra
  elseif type(winners) == "number" then
    winning_message = S("Team @1 wins the game", arena.teams[winners].name)

  -- se è una tabella, può essere o più giocatori singoli, o più squadre
  elseif type(winners) == "table" then

    -- v DEPRECATED, da rimuovere in 6.0 ----- v
    if arena.teams_enabled and type(winners[1]) == "string" then
      winning_message = deprecated_winning_team_celebration(mod, arena, winners)
    -- ^ -------------------------------------^

    elseif type(winners[1]) == "string" then
      for _, pl_name in pairs(winners) do
        winning_message = winning_message .. pl_name .. ", "
      end
      winning_message = S("@1 win the game", winning_message:sub(1, -3))

    else
      for _, team_ID in pairs(winners) do
        winning_message = winning_message .. arena.teams[team_ID].name .. ", "
      end
    winning_message = S("Teams @1 win the game", winning_message:sub(1, -3))
    end
  end

  local mod_ref = arena_lib.mods[mod]

  arena_lib.HUD_send_msg_all("title", arena, winning_message, mod_ref.celebration_time)
  arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#cfc6b8", "> " .. S("Players and spectators can now interact with each other")))

  -- eventuale codice aggiuntivo
  if mod_ref.on_celebration then
    mod_ref.on_celebration(arena, winners)
  end

  for _, callback in ipairs(arena_lib.registered_on_celebration) do
    callback(mod_ref, arena, winners)
  end

  -- l'arena finisce dopo tot secondi, a meno che non sia stata terminata forzatamente nel mentre
  minetest.after(mod_ref.celebration_time, function()
    if not arena.in_game then return end
    arena_lib.end_arena(mod_ref, mod, arena, winners)
  end)

end



function arena_lib.end_arena(mod_ref, mod, arena, winners, is_forced)

  -- copie da passare a on_end
  local spectators = {}
  local players = {}

  -- rimozione spettatori
  for sp_name, sp_stats in pairs(arena.spectators) do

    spectators[sp_name] = sp_stats
    arena_lib.leave_spectate_mode(sp_name)
    players_in_game[sp_name] = nil

    operations_before_leaving_arena(mod_ref, arena, sp_name)
  end

  -- rimozione giocatori
  for pl_name, stats in pairs(arena.players) do

    players[pl_name] = stats
    arena.players[pl_name] = nil
    players_in_game[pl_name] = nil

    operations_before_leaving_arena(mod_ref, arena, pl_name)
  end

  -- dealloca eventuale modalità spettatore
  if mod_ref.spectate_mode then
    arena.spectate_entities_amount = nil
    arena.spectate_areas_amount = nil
    arena_lib.unload_spectate_containers(mod, arena.name)
  end

  -- azzerramento giocatori e spettatori
  arena.past_present_players = {}
  arena.players_and_spectators = {}
  arena.past_present_players_inside = {}

  arena.players_amount = 0
  if arena.teams_enabled then
    for i = 1, #arena.teams do
      arena.players_amount_per_team[i] = 0
      if mod_ref.spectate_mode then
        arena.spectators_amount_per_team[i] = 0
      end
    end
  end

  -- azzero il timer
  arena.current_time = nil

  -- rimuovo eventuali proprietà temporanee
  for temp_property, v in pairs(mod_ref.temp_properties) do
    arena[temp_property] = nil
  end

  -- e quelle eventuali di squadra
  if arena.teams_enabled then
    for i = 1, #arena.teams do
      for t_property, _ in pairs(mod_ref.team_properties) do
        arena.teams[i][t_property] = nil
      end
    end
  end

  victory_particles(arena, players, winners)

  -- eventuale codice aggiuntivo
  if mod_ref.on_end then
    mod_ref.on_end(arena, players, winners, spectators, is_forced)
  end

  for _, callback in ipairs(arena_lib.registered_on_end) do
    callback(mod_ref, arena, players, winners, spectators, is_forced)
  end

  arena.in_loading = false                                                      -- nel caso venga forzata mentre sta caricando, sennò rimane a caricare all'infinito
  arena.in_celebration = false
  arena.in_game = false

  arena_lib.entrances[arena.entrance_type].update(mod, arena)
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

-- mod è opzionale
function arena_lib.is_player_in_arena(p_name, mod)

  if not players_in_game[p_name] then
    return false
  else

    -- se il campo mod è specificato, controllo che sia lo stesso
    if mod ~= nil then
      if players_in_game[p_name].minigame == mod then return true
      else return false
      end
    end

    return true
  end
end



function arena_lib.remove_player_from_arena(p_name, reason, executioner)
  -- reason 0 = has disconnected
  -- reason 1 = has been eliminated
  -- reason 2 = has been kicked
  -- reason 3 = has quit the arena
  assert(reason, "[ARENA_LIB] 'remove_player_from_arena': A reason must be specified!")

  -- se lə giocatorə non è in partita, annullo
  if not arena_lib.is_player_in_arena(p_name) then return end

  local mod = arena_lib.get_mod_by_player(p_name)
  local mod_ref = arena_lib.mods[mod]
  local arena = arena_lib.get_arena_by_player(p_name)

  -- se lə giocatorə era in spettatore
  if mod_ref.spectate_mode and arena_lib.is_player_spectating(p_name) then
    arena_lib.leave_spectate_mode(p_name)
    operations_before_leaving_arena(mod_ref, arena, p_name, reason)
    arena.players_and_spectators[p_name] = nil
    arena.past_present_players_inside[p_name] = nil

    handle_leaving_callbacks(mod_ref, arena, p_name, reason, executioner, true)
    players_in_game[p_name] = nil

  -- sennò...
  else

    -- rimuovo
    arena.players_amount = arena.players_amount - 1
    if arena.teams_enabled then
      local p_team_ID = arena.players[p_name].teamID
      arena.players_amount_per_team[p_team_ID] = arena.players_amount_per_team[p_team_ID] - 1
    end
    arena.players[p_name] = nil

    -- se ha abbandonato mentre aveva degli spettatori, li riassegno
    if arena_lib.is_player_spectated(p_name) then
      for sp_name, _ in pairs(arena_lib.get_player_spectators(p_name)) do
        arena_lib.find_and_spectate_player(sp_name)
      end
    end

    -- se è stato eliminato e c'è la spettatore, non va rimosso, bensì solo spostato in spettatore
    if reason == 1 and mod_ref.spectate_mode and arena.players_amount > 0 then
      eliminate_player(mod_ref, arena, p_name, executioner)
      arena_lib.enter_spectate_mode(p_name, arena)

    -- sennò procedo a rimuoverlo normalmente
    else
      operations_before_leaving_arena(mod_ref, arena, p_name, reason)
      arena.players_and_spectators[p_name] = nil
      arena.past_present_players_inside[p_name] = nil
      players_in_game[p_name] = nil

      handle_leaving_callbacks(mod_ref, arena, p_name, reason, executioner)
    end

    -- se è già in celebrazione, basta solo aggiornare il cartello
    if not arena.in_celebration then

      -- se l'ultimə rimastə abbandona, vai in celebrazione
      if arena.players_amount == 0 then
        arena_lib.load_celebration(mod, arena)

      -- se l'arena è a squadre e sono rimasti solo lɜ giocatorɜ di una squadra, la loro squadra vince
      elseif arena.teams_enabled and #arena_lib.get_active_teams(arena) == 1 then

        local winning_team_id = arena_lib.get_active_teams(arena)[1]

        arena_lib.send_message_in_arena(arena, "players", mod_ref.prefix .. S("There are no other teams left, you win!"))
        arena_lib.load_celebration(mod, arena, winning_team_id)

      -- se invece erano rimastɜ solo 2 giocatorɜ in partita, l'altrə vince
      elseif arena.players_amount == 1 then

        if reason == 1 then
          arena_lib.send_message_in_arena(arena, "players", mod_ref.prefix .. S("You're the last player standing: you win!"))
        else
          arena_lib.send_message_in_arena(arena, "players", mod_ref.prefix .. S("You win the game due to not enough players"))
        end

        for pl_name, stats in pairs(arena.players) do
          arena_lib.load_celebration(mod, arena, pl_name)
        end
      end
    end
  end

  arena_lib.entrances[arena.entrance_type].update(mod, arena)
end



function arena_lib.force_arena_ending(mod, arena, sender)

  local mod_ref = arena_lib.mods[mod]

  -- se il minigioco non esiste, annullo
  if not mod_ref then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This minigame doesn't exist!")))
    return end

  -- se l'arena non esiste, annullo
  if not arena then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  -- se l'arena non è in partita, annullo
  if not arena.in_game then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No ongoing game!")))
    return end

  arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#d69298", S("The arena has been forcibly terminated by @1", sender)))
  arena_lib.end_arena(mod_ref, mod, arena, nil, true)
  return true
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_mod_by_player(p_name)
  if arena_lib.is_player_in_arena(p_name) then
    return players_in_game[p_name].minigame
  elseif arena_lib.is_player_in_queue(p_name) then
    return arena_lib.get_mod_by_queuing_player(p_name)
  end
end



function arena_lib.get_arena_by_player(p_name)
  if arena_lib.is_player_in_arena(p_name) then      -- è in partita
    local mod = players_in_game[p_name].minigame
    local arenaID = players_in_game[p_name].arenaID

    return arena_lib.mods[mod].arenas[arenaID]
  elseif arena_lib.is_player_in_queue(p_name) then   -- è in coda
    return arena_lib.get_arena_by_queuing_player(p_name)
  end
end



function arena_lib.get_arenaID_by_player(p_name)
  if players_in_game[p_name] then
    return players_in_game[p_name].arenaID
  end
end



function arena_lib.get_players_in_game()
  return players_in_game
end



function arena_lib.get_players_in_minigame(mod, to_player)
  local players_in_minigame = {}

  if to_player then
    for pl_name, info in pairs(players_in_game) do
      if mod == info.minigame then
        table.insert(players_in_minigame, minetest.get_player_by_name(pl_name))
      end
    end
  else
    for pl_name, info in pairs(players_in_game) do
      if mod == info.minigame then
        table.insert(players_in_minigame, pl_name)
      end
    end
  end

  return players_in_minigame
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function assign_team_spawner(spawn_points, ID, p_name, p_team_ID)

  for i = ID, #spawn_points do
    if p_team_ID == spawn_points[i].teamID then
      minetest.get_player_by_name(p_name):set_pos(spawn_points[i].pos)
      return i+1
    end
  end
end



function operations_before_entering_arena(mod_ref, mod, arena, arena_ID, p_name, as_spectator)

  players_temp_storage[p_name] = {}

  -- applico eventuale musica di sottofondo
  if arena.bgm then
    players_temp_storage[p_name].bgm_handle = minetest.sound_play(arena.bgm.track, {
      gain = arena.bgm.gain,
      pitch = arena.bgm.pitch,
      to_player = p_name,
      loop = true,
    })
  end

  local player = minetest.get_player_by_name(p_name)

  -- cambio eventuale illuminazione
  if arena.lighting then
    players_temp_storage[p_name].lighting = {
      light = player:get_day_night_ratio()
    }

    local lighting = arena.lighting
    if lighting.light then
      player:override_day_night_ratio(lighting.light)
    end
  end

  -- cambio eventuale volta celeste
  if arena.celestial_vault then
    local celvault = arena.celestial_vault

    if celvault.sky then
      players_temp_storage[p_name].celvault_sky = player:get_sky(true)
      player:set_sky(celvault.sky)
    end

    if celvault.sun then
      players_temp_storage[p_name].celvault_sun = player:get_sun()
      player:set_sun(celvault.sun)
    end

    if celvault.moon then
      players_temp_storage[p_name].celvault_moon = player:get_moon()
      player:set_moon(celvault.moon)
    end

    if celvault.stars then
      players_temp_storage[p_name].celvault_stars = player:get_stars()
      player:set_stars(celvault.stars)
    end

    if celvault.clouds then
      players_temp_storage[p_name].celvault_clouds = player:get_clouds()
      player:set_clouds(celvault.clouds)
    end
  end

  -- nascondo i nomi se l'opzione è abilitata
  if not mod_ref.show_nametags then
    player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
  end

  -- disattivo eventualmente la minimappa
  if not mod_ref.show_minimap then
    player:hud_set_flags({minimap = false})
  end

  -- chiudo eventuali formspec
  minetest.close_formspec(p_name, "")

  -- svuoto eventualmente l'inventario, decidendo se e come salvarlo
  if not mod_ref.keep_inventory then
    arena_lib.store_inventory(player)
  end

  -- salvo la hotbar se c'è la spettatore o la hotbar personalizzata
  if mod_ref.spectate_mode or mod_ref.hotbar then
    players_temp_storage[p_name].hotbar_slots = player:hud_get_hotbar_itemcount()
    players_temp_storage[p_name].hotbar_background_image = player:hud_get_hotbar_image()
    players_temp_storage[p_name].hotbar_selected_image = player:hud_get_hotbar_selected_image()
  end

  if not as_spectator then
    operations_before_playing_arena(mod_ref, arena, p_name)
  end

  -- registro giocatori nella tabella apposita
  players_in_game[p_name] = {minigame = mod, arenaID = arena_ID}
end



function operations_before_playing_arena(mod_ref, arena, p_name)

  arena.past_present_players[p_name] = true
  arena.past_present_players_inside[p_name] = true

  -- aggiungo eventuale contenitore mod spettatore
  if mod_ref.spectate_mode then
    arena_lib.add_spectate_p_container(p_name)
  end

  local player = minetest.get_player_by_name(p_name)

  -- applico eventuale fov
  if mod_ref.fov then
    players_temp_storage[p_name].fov = player:get_fov()
    player:set_fov(mod_ref.fov)
  end

  -- applico eventuale scostamento camera
  if mod_ref.camera_offset then
    players_temp_storage[p_name].camera_offset = {player:get_eye_offset()}
    player:set_eye_offset(mod_ref.camera_offset[1], mod_ref.camera_offset[2])
  end

  -- cambio eventuale colore texture (richiede le squadre)
  if arena.teams_enabled and mod_ref.teams_color_overlay then
    local textures = player:get_properties().textures
    textures[1] = textures[1] .. "^[colorize:" .. mod_ref.teams_color_overlay[arena.players[p_name].teamID] .. ":85"
    player:set_properties({
      textures = textures
    })
  end

  -- disabilito eventualmente l'inventario
  if mod_ref.disable_inventory then
    players_temp_storage[p_name].inventory_fs = player:get_inventory_formspec()
    player:set_inventory_formspec("")
  end

  -- cambio l'eventuale hotbar
  if mod_ref.hotbar then
    local hotbar = mod_ref.hotbar

    if hotbar.slots then
      player:hud_set_hotbar_itemcount(hotbar.slots)
    end

    if hotbar.background_image then
      player:hud_set_hotbar_image(hotbar.background_image)
    end

    if hotbar.selected_image then
      player:hud_set_hotbar_selected_image(hotbar.selected_image)
    end
  end

  -- imposto eventuale fisica personalizzata
  if mod_ref.in_game_physics then
    player:set_physics_override(mod_ref.in_game_physics)
  end

  -- li sgancio da eventuali entità (non lo faccio agli spettatori perché sono già
  -- agganciati al giocatore, sennò cadono nel vuoto)
  player:set_detach()

  -- se il danno da caduta è disabilitato, disattivo il flash all'impatto
  if table.indexof(mod_ref.disabled_damage_types, "fall") > 0 then
    players_temp_storage[p_name].armor_groups = player:get_armor_groups()

    local armor_groups = player:get_armor_groups()

    armor_groups.fall_damage_add_percent = -100
    player:set_armor_groups(armor_groups)
  end

  -- li curo
  player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)

  -- assegno eventuali proprietà giocatori
  for k, v in pairs(mod_ref.player_properties) do
    if type(v) == "table" then
      arena.players[p_name][k] = table.copy(v)
    else
      arena.players[p_name][k] = v
    end
  end
end



-- reason parametro opzionale che passo solo quando potrebbe essersi disconnesso
function operations_before_leaving_arena(mod_ref, arena, p_name, reason)

  -- disattivo eventuale musica di sottofondo
  if arena.bgm then
    minetest.sound_stop(players_temp_storage[p_name].bgm_handle)
  end

  local player = minetest.get_player_by_name(p_name)

  -- reimposto eventuale illuminazione
  if arena.lighting then
    player:override_day_night_ratio(players_temp_storage[p_name].lighting.light)
  end

  -- reimposto eventuale volta celeste
  if arena.celestial_vault then
    local celvault = arena.celestial_vault

    if celvault.sky then
      player:set_sky(players_temp_storage[p_name].celvault_sky)
    end
    if celvault.sun then
      player:set_sun(players_temp_storage[p_name].celvault_sun)
    end
    if celvault.moon then
      player:set_moon(players_temp_storage[p_name].celvault_moon)
    end
    if celvault.stars then
      player:set_stars(players_temp_storage[p_name].celvault_stars)
    end
    if celvault.clouds then
      player:set_clouds(players_temp_storage[p_name].celvault_clouds)
    end
  end

  -- svuoto eventualmente l'inventario e ripristino gli oggetti
  if not mod_ref.keep_inventory then
    player:get_inventory():set_list("main", {})
    player:get_inventory():set_list("craft",{})

    if arena_lib.STORE_INVENTORY_MODE ~= "none" then
      arena_lib.restore_inventory(p_name)
    end
  end

  local armor_groups = players_temp_storage[p_name].armor_groups

  -- riassegno eventuali gruppi armatura  (per il flash da impatto caduta)
  if armor_groups then
    player:set_armor_groups(armor_groups)
  end

  -- ripristino gli HP
  player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)

  -- teletrasporto con un po' di rumore
  local clean_pos = mod_ref.settings.hub_spawn_point
  local noise_x = math.random(-1.5, 1.5)
  local noise_z = math.random(-1.5, 1.5)
  local noise_pos = {x = clean_pos.x + noise_x, y = clean_pos.y, z = clean_pos.z + noise_z}
  player:set_pos(noise_pos)
  -- TEMP: waiting for https://github.com/minetest/minetest/issues/12092 to be fixed. Forcing the teleport twice on two different steps
  minetest.after(0.1, function()
    if not minetest.get_player_by_name(p_name) then return end
    player:set_pos(noise_pos)
  end)

  -- se si è disconnesso, salta il resto
  if reason == 0 then
    players_temp_storage[p_name] = nil
    return
  end

  -- se ha partecipato come giocatore
  if arena.past_present_players_inside[p_name] then

    -- rimuovo eventuale contenitore mod spettatore
    if mod_ref.spectate_mode then
      arena_lib.remove_spectate_p_container(p_name)
    end

    -- ripristino eventuali texture
    if arena.teams_enabled and mod_ref.teams_color_overlay then
      local textures = player:get_properties().textures
      textures[1] = string.match(textures[1], "(.*)^%[") or textures[1] -- in case an external mod messed up filters. TODO just store the texture when the match starts and then reapply it here
      player:set_properties({
        textures = textures
      })
    end

    -- ripristino eventuale fov
    if mod_ref.fov then
      player:set_fov(players_temp_storage[p_name].fov)
    end

    -- riabilito eventualmente l'inventario
    if mod_ref.disable_inventory then
      player:set_inventory_formspec(players_temp_storage[p_name].inventory_fs)
    end

    -- ripristino eventuale camera
    if mod_ref.camera_offset then
      player:set_eye_offset(players_temp_storage[p_name].camera_offset[1], players_temp_storage[p_name].camera_offset[2])
    end
  end

  -- se c'è la spettatore o l'hotbar personalizzata, la ripristino
  if mod_ref.spectate_mode or mod_ref.hotbar then
    player:hud_set_hotbar_itemcount(players_temp_storage[p_name].hotbar_slots)
    player:hud_set_hotbar_image(players_temp_storage[p_name].hotbar_background_image)
    player:hud_set_hotbar_selected_image(players_temp_storage[p_name].hotbar_selected_image)
  end

  -- se ho Hub, restituisco gli oggetti e imposto fisica della lobby
  if minetest.get_modpath("hub_core") then
    hub.set_items(player)
    hub.set_hub_physics(player)
  else
    player:set_physics_override(arena_lib.SERVER_PHYSICS)
  end

  -- riattivo la minimappa eventualmente disattivata
  player:hud_set_flags({minimap = true})

  -- ripristino nomi
  player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})

  -- svuoto lo storage temporaneo
  players_temp_storage[p_name] = nil
end



function eliminate_player(mod_ref, arena, p_name, executioner)
  if executioner then
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#f16a54", "<<< " .. S("@1 has been eliminated by @2", p_name, executioner)))
  else
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#f16a54", "<<< " .. S("@1 has been eliminated", p_name)))
  end

  if mod_ref.on_eliminate then
    mod_ref.on_eliminate(arena, p_name)
  end

  for _, callback in ipairs(arena_lib.registered_on_eliminate) do
    callback(mod_ref, arena, p_name)
  end
end



function handle_leaving_callbacks(mod_ref, arena, p_name, reason, executioner, is_spectator)

  local msg_color = reason < 3 and "#f16a54" or "#d69298"
  local spect_str = ""

  if is_spectator then
    msg_color = "#cfc6b8"
    spect_str = " (" .. S("spectator") .. ")"
  end

  -- se si è disconnesso
  if reason == 0 then
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize(msg_color, "<<< " .. p_name .. spect_str))

    -- DEPRECATED: remove in 6.0
    if mod_ref.on_disconnect then
      minetest.log("warning", "[ARENA_LIB] (" .. mod_ref.name .. ") on_disconnect is deprecated. Please use on_quit with reason `0` instead")
      mod_ref.on_disconnect(arena, p_name, is_spectator)
    end

  -- se è stato eliminato (no spettatore, quindi viene rimosso dall'arena)
  elseif reason == 1 then
    eliminate_player(mod_ref, arena, p_name, executioner)

  -- se è stato cacciato
  elseif reason == 2 then
    if executioner then
      arena_lib.send_message_in_arena(arena, "both", minetest.colorize(msg_color, "<<< " .. S("@1 has been kicked by @2", p_name, executioner) .. spect_str))
    else
      arena_lib.send_message_in_arena(arena, "both", minetest.colorize(msg_color, "<<< " .. S("@1 has been kicked", p_name) .. spect_str))
    end

    -- DEPRECATED: remove in 6.0
    if mod_ref.on_kick then
      minetest.log("warning", "[ARENA_LIB] (" .. mod_ref.name .. ") on_kick is deprecated. Please use on_quit with reason `2` instead")
      mod_ref.on_kick(arena, p_name, is_spectator)
    end

  -- se ha abbandonato
  elseif reason == 3 then
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize(msg_color, "<<< " .. S("@1 has quit the match", p_name) .. spect_str))
  end

  if mod_ref.on_quit then
    mod_ref.on_quit(arena, p_name, is_spectator, reason)
  end

  for _, callback in ipairs(arena_lib.registered_on_quit) do
    callback(mod_ref, arena, p_name, is_spectator, reason)
  end
end



function victory_particles(arena, players, winners)
  -- singolo giocatore
  if type(winners) == "string" then
    local winner = minetest.get_player_by_name(winners)

    if winner then
      show_victory_particles(winner:get_pos())
    end

  -- singola squadra
  elseif type(winners) == "number" then
    for pl_name, pl_stats in pairs(players) do
      if pl_stats.teamID == winners then
        local winner = minetest.get_player_by_name(pl_name)

        if winner then
          show_victory_particles(winner:get_pos())
        end
      end
    end

  -- più vincitori
  elseif type(winners) == "table" then

    -- v DEPRECATED, da rimuovere in 6.0 ----- v
    if arena.teams_enabled and type(winners[1]) == "string" then
      local teamID = 0
      for pl_name, pl_stats in pairs(players) do
        if pl_name == winners[1] then
          teamID = pl_stats.teamID
          break
        end
      end

      for pl_name, pl_stats in pairs(players) do
        if pl_stats.teamID == winners then
          local winner = minetest.get_player_by_name(pl_name)

          if winner then
            show_victory_particles(winner:get_pos())
          end
        end
      end
    -- ^ -------------------------------------^
    -- singoli giocatori
    elseif type(winners[1]) == "string" then
      for _, pl_name in pairs(winners) do
        local winner = minetest.get_player_by_name(pl_name)

        if winner then
          show_victory_particles(winner:get_pos())
        end
      end

    -- squadre
    else
      for _, team_ID in pairs(winners) do
        local team = arena.teams[team_ID]
        for pl_name, pl_stats in pairs(players) do
          if pl_stats.teamID == team_ID then
            local winner = minetest.get_player_by_name(pl_name)

            if winner then
              show_victory_particles(winner:get_pos())
            end
          end
        end
      end
    end
  end
end



function show_victory_particles(p_pos)
  minetest.add_particlespawner({
    amount = 50,
    time = 0.6,
    minpos = p_pos,
    maxpos = p_pos,
    minvel = {x=-2, y=-2, z=-2},
    maxvel = {x=2, y=2, z=2},
    minsize = 1,
    maxsize = 3,
    texture = "arenalib_winparticle.png"
  })
end



function time_start(mod_ref, arena)

  if arena.on_celebration or not arena.in_game then return end

  if mod_ref.time_mode == "incremental" then
    arena.current_time = arena.current_time + 1
  else
    arena.current_time = arena.current_time - 1
  end

  if arena.current_time <= 0 then
    assert(mod_ref.on_timeout, "[ARENA_LIB] " .. S("[!] on_timeout callback must be declared to properly use a decreasing timer!"))
    mod_ref.on_timeout(arena)
    return
  elseif mod_ref.on_time_tick then
    mod_ref.on_time_tick(arena)
  end

  minetest.after(1, function()
    time_start(mod_ref, arena)
  end)
end





----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

-- to remove in 6.0
function deprecated_winning_team_celebration(mod, arena, winners)
  minetest.log("warning", debug.traceback("[ARENA_LIB - " .. mod .. "] passing a single winning team as a table made of one of its players is deprecated, "
    .. "please pass the (integer) team ID instead"))
  local winner = arena.players[winners[1]].teamID
  return S("Team @1 wins the game", arena.teams[winner].name)
end

-- to remove in 7.0
function deprecated_start_arena(arena)
  local mod
  for pl_name, _ in pairs(arena.players) do
    mod = arena_lib.get_mod_by_player(pl_name)
    break
  end
  minetest.log("warning", "[ARENA_LIB - " .. mod .. "] start_arena(mod_ref, arena) is deprecated. Please use start_arena(mod, arena) instead, where mod is the technical name of the minigame (and not its table)")
  return mod
end

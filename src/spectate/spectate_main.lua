local S = minetest.get_translator("arena_lib")

local function override_hotbar() end
local function set_spectator() end

local players_in_spectate_mode = {}         -- KEY: player name, VALUE: {(string) minigame, (int) arenaID, (string) type, (string) spectating}
local spectate_temp_storage = {}            -- KEY: player_name, VALUE: {(table) camera_offset}
local players_spectated = {}                -- KEY: player name, VALUE: {(string) spectator(s) = true}
local entities_spectated = {}               -- KEY: [mod][arena][entity name], VALUE: {(string) spectator(s) = true}
local areas_spectated = {}
local entities_storage = {}                 -- KEY: [mod][arena][entity_name], VALUE: entity



----------------------------------------------
--------------INTERNAL USE ONLY---------------
----------------------------------------------

-- init e unload servono esclusivamente per le eventuali entità e aree, e vengon
-- chiamate rispettivamente quando l'arena si avvia e termina. I contenitori dei
-- giocatori invece vengono creati/distrutti singolarmente ogni volta che un giocatore
-- entra/esce, venendo lanciati in operations_before_playing/leaving_arena

function arena_lib.init_spectate_containers(mod, arena_name)
  if not entities_spectated[mod] then
    entities_spectated[mod] = {}
  end
  if not areas_spectated[mod] then
    areas_spectated[mod] = {}
  end
  if not entities_storage[mod] then
    entities_storage[mod] = {}
  end

  entities_spectated[mod][arena_name] = {}
  areas_spectated[mod][arena_name] = {}
  entities_storage[mod][arena_name] = {}
end



function arena_lib.unload_spectate_containers(mod, arena_name)
  entities_spectated[mod][arena_name] = nil     -- non c'è bisogno di cancellare X[mod], al massimo rimangono vuote
  areas_spectated[mod][arena_name] = nil
  entities_storage[mod][arena_name] = nil
end



function arena_lib.add_spectate_p_container(p_name)
  players_spectated[p_name] = {}
end



function arena_lib.remove_spectate_p_container(p_name)
  players_spectated[p_name] = {}
end



----------------------------------------------
---------------------CORE---------------------
----------------------------------------------

function arena_lib.enter_spectate_mode(p_name, arena)

  local mod = arena_lib.get_mod_by_player(p_name)

  -- se non supporta la spettatore
  if not arena_lib.mods[mod].spectate_mode then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Spectate mode not supported!")))
    return end

  -- se l'arena non è abilitata
  if not arena.enabled then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
    return end

  -- se non è in corso
  if not arena.in_game then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] No ongoing game!")))
    return end

  local player = minetest.get_player_by_name(p_name)

  -- se si è attaccati a qualcosa
  if player:get_attach() then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must detach yourself from the entity you're attached to before entering!")))
    return end

  local arena_ID = arena_lib.get_arenaID_by_player(p_name)
  local team_ID  = #arena.teams > 1 and 1 or nil
  local hand     = player:get_inventory():get_list("hand")

  players_in_spectate_mode[p_name] = { minigame = mod, arenaID = arena_ID, teamID = team_ID, hand = hand}
  arena.spectators[p_name] = true
  arena.players_and_spectators[p_name] = true
  arena.spectators_amount = arena.spectators_amount + 1

  -- applico mano finta
  player:get_inventory():set_size("hand", 1)
  player:get_inventory():add_item("hand", "arena_lib:spectate_hand")

  -- se il giocatore non è mai entrato in partita, lo salvo nello spazio di archiviazione temporaneo
  if not arena.past_present_players_inside[p_name] then
    spectate_temp_storage[p_name] = {}
    spectate_temp_storage[p_name].camera_offset = {player:get_eye_offset()}
  end

  -- applicazione parametri vari
  local current_properties = table.copy(player:get_properties())
  players_in_spectate_mode[p_name].properties = current_properties

  player:set_properties({
    visual_size = {x = 0, y = 0},
    makes_footstep_sound = false,
    collisionbox = {0},
    pointable = false
  })

  player:set_eye_offset({x = 0, y = -2, z = -25}, {x=0, y=0, z=0})
  player:set_nametag_attributes({color = {a = 0}})

  -- assegno un ID al giocatore per ruotare chi/cosa sta seguendo, in quanto gli
  -- elementi seguibili non dispongono di un ID per orientarsi nella loro navigazione
  -- (cosa viene dopo l'elemento X? È il capolinea?). Lo uso essenzialmente come
  -- un i = 1 nei cicli for, per capire dove mi trovo e cosa verrebbe dopo
  -- (assegnarlo a 0 equivale ad azzerarlo, ma l'ho specificato per chiarezza nel codice)
  player:get_meta():set_int("arenalib_watchID", 0)

  -- inizia a seguire
  arena_lib.find_and_spectate_player(p_name)

  override_hotbar(player, mod, arena)
  return true
end



function arena_lib.leave_spectate_mode(p_name, to_join_match)

  local arena = arena_lib.get_arena_by_player(p_name)

  if to_join_match then
    --TODO-TEMP: 5.4, aspettare o dà problemi con after
    minetest.chat_send_player(p_name, "[!] SoonTM!")
    return

    --TODO: questi controlli ha senso ridurli in un luogo unico per quando si prova a entrare, dato che appaiono pure sui cartelli
    --[[
    -- se è piena
    if arena.players_amount == arena.max_players * #arena.teams then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is already full!")))
      return end

    -- se è in celebrazione
    if arena.in_celebration then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is loading, try again in a few seconds!")))
      return end
      ]]
  else
    arena.players_and_spectators[p_name] = nil
  end

  arena.spectators[p_name] = nil
  arena.spectators_amount = arena.spectators_amount -1

  local player = minetest.get_player_by_name(p_name)
  local p_inv = player:get_inventory()

  -- rimuovo mano finta e reimposto eventuale mano precedente
  p_inv:set_list("hand", players_in_spectate_mode[p_name].hand)

  if not players_in_spectate_mode[p_name].hand then
    p_inv:set_size("hand", 0)
  end

  -- se il giocatore non è mai entrato in partita, riassegno le proprietà salvate qui
  if not arena.past_present_players_inside[p_name] then
    player:set_eye_offset(spectate_temp_storage[p_name].camera_offset[1], spectate_temp_storage[p_name].camera_offset[2])
    spectate_temp_storage[p_name] = nil
  else
    player:set_eye_offset({x=0, y=0, z=0}, {x=0, y=0, z=0})
  end

  player:set_detach()
  player:set_properties(players_in_spectate_mode[p_name].properties)
  player:get_meta():set_int("arenalib_watchID", 0)

  arena_lib.HUD_hide("hotbar", p_name)

  local target = players_in_spectate_mode[p_name].spectating
  local type = players_in_spectate_mode[p_name].type

  -- rimuovo dal database locale
  if type == "player" then
    players_spectated[target][p_name] = nil
  else

    local mod = arena_lib.get_mod_by_player(p_name)
    local arena_name = arena.name

    if type == "entity" then
      entities_spectated[mod][arena_name][target][p_name] = nil
    elseif type == "area" then
      areas_spectated[mod][arena_name][target][p_name] = nil
    end
  end

  players_in_spectate_mode[p_name] = nil
end



function arena_lib.add_spectable_target(mod, arena_name, t_type, t_name, target)

  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not arena.in_game then return end

  if t_type == "entity" then
    local old_deact = target.on_deactivate

    -- aggiungo sull'on_deactivate la funzione per rimuoverla dalla spettatore
    target.on_deactivate = function(...)
      local ret = old_deact and old_deact(...)

      arena_lib.remove_spectable_target(mod, arena_name, t_type, t_name)

      return ret
    end

    -- la aggiungo
    entities_spectated[mod][arena_name][t_name] = {}
    entities_storage[mod][arena_name][t_name] = target

    -- se è l'unica entità registrata, aggiungo lo slot per seguire le entità
    if arena_lib.get_spectable_entities_amount(mod, arena_name) == 1 then
      for sp_name, _ in pairs(arena.spectators) do
        override_hotbar(minetest.get_player_by_name(sp_name), mod, arena)
      end
    end

  elseif t_type == "area" then
    -- TODO registrare aree
  end

end



function arena_lib.remove_spectable_target(mod, arena_name, t_type, t_name)

  local arenaID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- se l'entità viene rimossa quando la partita è già finita, interrompi o crasha
  if not arena.in_game then return end

  if t_type == "entity" then
    entities_storage[mod][arena_name][t_name] = nil

    -- se non ci sono più entità, fai sparire l'icona
    if not next(entities_storage[mod][arena_name]) then
      for sp_name, _ in pairs(arena.spectators) do
        local spectator = minetest.get_player_by_name(sp_name)
        override_hotbar(spectator, mod, arena)
      end
    end

    for sp_name, _ in pairs(entities_spectated[mod][arena_name][t_name]) do
      arena_lib.find_and_spectate_entity(mod, arena_name, sp_name)
    end
  elseif t_type == "area" then
    --TODO
  end
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.is_player_spectating(sp_name)
  return players_in_spectate_mode[sp_name] ~= nil
end



function arena_lib.is_player_spectated(p_name)
  return players_spectated[p_name] and next(players_spectated[p_name])
end



function arena_lib.is_entity_spectated(mod, arena_name, e_name)
  return entities_spectated[mod][arena_name][e_name] and next(entities_spectated[mod][arena_name][e_name])
end



function arena_lib.find_and_spectate_player(sp_name, change_team)

  local arena = arena_lib.get_arena_by_player(sp_name)

  -- se l'ultimo rimasto ha abbandonato (es. alt+f4), rispedisco subito fuori senza che cada all'infinito con rischio di crash
  if arena.players_amount == 0 then
    arena_lib.remove_player_from_arena(sp_name, 3)
    return end

  local prev_spectated = players_in_spectate_mode[sp_name].spectating

  -- se c'è rimasto solo un giocatore e già lo si seguiva, annullo
  if arena.players_amount == 1 and prev_spectated and arena.players[prev_spectated] then return end

  local spectator = minetest.get_player_by_name(sp_name)

  if players_in_spectate_mode[sp_name].type ~= "player" then
    spectator:get_meta():set_int("arenalib_watchID", 0)
  end

  local team_ID = players_in_spectate_mode[sp_name].teamID
  local players_amount

  -- calcolo giocatori massimi tra cui ruotare
  -- squadre:
  if #arena.teams > 1 then
    -- se è l'unico rimasto nella squadra e già lo si seguiva, annullo
    if arena.players_amount_per_team[team_ID] == 1 and not change_team and prev_spectated and arena.players[prev_spectated] then return end

    -- se il giocatore seguito era l'ultimo membro della sua squadra, la imposto da cambiare
    if arena.players_amount_per_team[team_ID] == 0 then
      change_team = true
    end

    -- eventuale cambio squadra sul quale eseguire il calcolo
    if change_team then
      arena.spectators_amount_per_team[team_ID] = arena.spectators_amount_per_team[team_ID] - 1

      local active_teams = arena_lib.get_active_teams(arena)

      if team_ID >= active_teams[#active_teams] then
        team_ID = active_teams[1]
      else
        for i = team_ID + 1, #arena.teams do
          if arena.players_amount_per_team[i] ~= 0 then
            team_ID = i
            break
          end
        end
      end
      players_in_spectate_mode[sp_name].teamID = team_ID
      arena.spectators_amount_per_team[team_ID] = arena.spectators_amount_per_team[team_ID] + 1
    end

    players_amount = arena.players_amount_per_team[team_ID]

  -- no squadre:
  else
    players_amount = arena.players_amount
  end

  local watching_ID = spectator:get_meta():get_int("arenalib_watchID")
  local new_ID = players_amount <= watching_ID and 1 or watching_ID + 1

  -- trovo il giocatore da seguire
  -- squadre:
  if #arena.teams > 1 then
    local players_team = arena_lib.get_players_in_team(arena, team_ID)
    for i = 1, #players_team do

      if i == new_ID then
        set_spectator(spectator, "player", players_team[i], i)
        return true
      end
    end

  -- no squadre:
  else
    local i = 1
    for pl_name, _ in pairs(arena.players) do

      if i == new_ID then
        set_spectator(spectator, "player", pl_name, i)
        return true
      end

      i = i + 1
    end
  end
end



function arena_lib.find_and_spectate_entity(mod, arena_name, sp_name)

  -- se non ci sono entità da seguire, segui un giocatore
  if not next(entities_storage[mod][arena_name]) then
    arena_lib.find_and_spectate_player(sp_name)
    return end

  local e_amount = arena_lib.get_spectable_entities_amount(mod, arena_name)
  local prev_spectated = players_in_spectate_mode[sp_name].spectating

  -- se è l'unica entità rimasta e la si stava già seguendo
  if e_amount == 1 and prev_spectated and next(entities_spectated[mod][arena_name])[sp_name] then
    return end

  local spectator = minetest.get_player_by_name(sp_name)

  if players_in_spectate_mode[sp_name].type ~= "entity" then
    spectator:get_meta():set_int("arenalib_watchID", 0)
  end

  local current_ID = spectator:get_meta():get_int("arenalib_watchID")
  local new_ID = e_amount <= current_ID and 1 or current_ID + 1
  local i = 1

  for en_name, _ in pairs(entities_spectated[mod][arena_name]) do

    if i == new_ID then
      set_spectator(spectator, "entity", en_name, i)
      return true
    end

    i = i +1
  end
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_player_spectators(p_name)
  return players_spectated[p_name]
end



function arena_lib.get_player_spectated(sp_name)
  if arena_lib.is_player_spectating(sp_name) then
    return players_in_spectate_mode[sp_name].spectating
  end
end



function arena_lib.get_spectable_entities(mod, arena_name)
  return entities_storage[mod][arena_name]
end



function arena_lib.get_spectable_entities_amount(mod, arena_name)
  local i = 0
  for k, v in pairs(entities_storage[mod][arena_name]) do
    i = i + 1
  end
  return i
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function set_spectator(spectator, type, name, i)

  local sp_name = spectator:get_player_name()
  local mod = arena_lib.get_mod_by_player(sp_name)
  local arena_name = arena_lib.get_arena_by_player(sp_name).name
  local prev_spectated = players_in_spectate_mode[sp_name].spectating

  -- se stava già seguendo qualcuno, lo rimuovo da questo
  if prev_spectated then
    local prev_type = players_in_spectate_mode[sp_name].type
    if prev_type == "player" then
      players_spectated[prev_spectated][sp_name] = nil
    elseif prev_type == "entity" then
      entities_spectated[mod][arena_name][prev_spectated][sp_name] = nil
    else
      areas_spectated[mod][arena_name][prev_spectated][sp_name] = nil
    end
  end

  local target = ""

  if type == "player" then
    players_spectated[name][sp_name] = true
    target = minetest.get_player_by_name(name)

    spectator:set_attach(target, "", {x=0, y=-5, z=-20}, {x=0, y=0, z=0})
    spectator:set_hp(target:get_hp() > 0 and target:get_hp() or 1)

  elseif type == "entity" then

    entities_spectated[mod][arena_name][name][sp_name] = true
    target = entities_storage[mod][arena_name][name].object

    spectator:set_attach(target, "", {x=0, y=-5, z=-20}, {x=0, y=0, z=0})
    spectator:set_hp(target:get_hp() > 0 and target:get_hp() or 1)
  elseif type == "area" then
    -- TODO
  end

  players_in_spectate_mode[sp_name].spectating = name
  players_in_spectate_mode[sp_name].type = type

  spectator:get_meta():set_int("arenalib_watchID", i)
  arena_lib.HUD_send_msg("hotbar", sp_name, S("Currently spectating: @1", name))

  local mod_ref = arena_lib.mods[players_in_spectate_mode[sp_name].minigame]

  -- eventuale codice aggiuntivo
  if mod_ref.on_change_spectated_target then
    local arena = arena_lib.get_arena_by_player(sp_name)
    target = name
    local prev_target = prev_spectated
    mod_ref.on_change_spectated_target(arena, sp_name, target, prev_target)
  end
end



function override_hotbar(player, mod, arena)

  player:get_inventory():set_list("main", {})
  player:get_inventory():set_list("craft",{})

  local mod_ref = arena_lib.mods[mod]
  local tools = {
    "arena_lib:spectate_changeplayer",
    "arena_lib:spectate_quit"
  }

  if #arena.teams > 1 then
    table.insert(tools, 2, "arena_lib:spectate_changeteam")
  end

  if next(arena_lib.get_spectable_entities(mod, arena.name)) then
    table.insert(tools, #tools, "arena_lib:spectate_changeentity")
  end

  if mod_ref.join_while_in_progress then
    table.insert(tools, #tools, "arena_lib:spectate_join")
  end

  minetest.after(0, function()
    player:hud_set_hotbar_image("arenalib_gui_hotbar" .. #tools .. ".png")
    player:hud_set_hotbar_itemcount(#tools)
    player:get_inventory():set_list("main", tools)
  end)
end

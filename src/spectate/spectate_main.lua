local S = minetest.get_translator("arena_lib")

local function override_hotbar() end
local function set_spectator() end

local players_in_spectate_mode = {}         -- KEY: player name, VALUE: {(string) minigame, (int) arenaID, (string) spectating}
local players_spectated = {}                -- KEY: player name, VALUE: {(string) spectator(s) = true}
local spectate_temp_storage = {}            -- KEY: player_name, VALUE: {(table) camera_offset}



----------------------------------------------
--------------INTERNAL USE ONLY---------------
----------------------------------------------

-- gestisco qui le tabelle che possono contenere i vari spettatori per ogni
-- giocatore, onde evitare di fare dei controlli ogni volta che si cambia giocatore
-- seguito (che rischierebbero di riempire/svuotare queste tabelle a ogni cambio)
function arena_lib.add_spectate_container(p_name)
  players_spectated[p_name] = {}
end



function arena_lib.remove_spectate_container(p_name)
  players_spectated[p_name] = nil
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
    spectate_temp_storage[p_name].camera_offset = player:get_eye_offset()
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

    --TODO: questi check ha senso ridurli in un luogo unico per quando si prova a entrare, dato che appaiono pure sui cartelli
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

  -- rimuovo dal database locale
  players_spectated[target][p_name] = nil
  players_in_spectate_mode[p_name] = nil
end





----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.is_player_spectating(sp_name)
  return players_in_spectate_mode[sp_name] ~= nil
end



function arena_lib.is_player_spectated(p_name)
  return next(players_spectated[p_name])
end



function arena_lib.find_and_spectate_player(sp_name, change_team)

  local spectator = minetest.get_player_by_name(sp_name)
  local arena = arena_lib.get_arena_by_player(sp_name)

  local prev_spectated = players_in_spectate_mode[sp_name].spectating
  local watching_ID = spectator:get_meta():get_int("arenalib_watchID")
  local team_ID = players_in_spectate_mode[sp_name].teamID
  local players_amount

  -- se l'ultimo rimasto ha abbandonato (es. alt+f4), rispedisco subito fuori senza che cada all'infinito con rischio di crash
  if arena.players_amount == 0 then
    arena_lib.remove_player_from_arena(sp_name, 3)
    return end

  -- se c'è rimasto solo un giocatore e già lo si seguiva, annullo
  if arena.players_amount == 1 and prev_spectated and arena.players[prev_spectated] then return end

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

  local new_ID = players_amount <= watching_ID and 1 or watching_ID + 1
  local i = 0

  -- trovo il giocatore da seguire
  -- squadre:
  if #arena.teams > 1 then
    for _, pl_name in pairs(arena_lib.get_players_in_team(arena, team_ID)) do
      i = i + 1

      if i == new_ID then
        set_spectator(spectator, pl_name, i, prev_spectated)
        return true
      end
    end

  -- no squadre:
  else
    for pl_name, _ in pairs(arena.players) do
      i = i + 1

      if i == new_ID then
        set_spectator(spectator, pl_name, i, prev_spectated)
        return true
      end
    end
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





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function set_spectator(spectator, p_name, i, prev_spectated)

  local sp_name = spectator:get_player_name()

  -- se stava già seguendo qualcuno, lo rimuovo da questo
  if prev_spectated then
    players_spectated[prev_spectated][sp_name] = nil
  end

  players_spectated[p_name][sp_name] = true
  players_in_spectate_mode[sp_name].spectating = p_name

  local target = minetest.get_player_by_name(p_name)

  spectator:set_attach(target, "", {x=0, y=-5, z=-20}, {x=0, y=0, z=0})
  spectator:set_hp(target:get_hp() > 0 and target:get_hp() or 1)
  spectator:get_meta():set_int("arenalib_watchID", i)

  arena_lib.HUD_send_msg("hotbar", sp_name, S("Currently spectating: @1", p_name))
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

  if mod_ref.join_while_in_progress then
    table.insert(tools, #tools, "arena_lib:spectate_join")
  end

  minetest.after(0, function()
    player:hud_set_hotbar_image("arenalib_gui_hotbar" .. #tools .. ".png")
    player:hud_set_hotbar_itemcount(#tools)
    player:get_inventory():set_list("main", tools)
  end)
end

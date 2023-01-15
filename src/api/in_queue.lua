local S = minetest.get_translator("arena_lib")

local function initialise_queue_container() end
local function increase_join_count() end
local function go_to_arena() end
local function queue_format() end

local players_in_queue = {}           -- KEY: player name, VALUE: {(string) minigame, (int) arenaID}
local active_queues = {}              -- KEY: [mod] arena_name, VALUE: {(table) arena, (int) time_left, (table) was_second_run}
local queue_joins = {}                -- KEY: player name, VALUE: (int) amount

-- inizializzo il contenitore delle code una volta che tutti i minigiochi sono stati caricati
minetest.after(0.1, function()
  initialise_queue_container()
end)

----------------------------------------
-- GESTIONE CONTO ALLA ROVESCIA SU GLOBALSTEP
--
-- se usassi un normale `after`, all'entrare e uscire ripetutamente da una coda
-- i giocatori riuscirebbero a impallarle, eseguendone due o più per la stessa
-- arena. Nonostante ciò non vada a fondere il server, dimezza comunque i tempi
-- d'attesa e riproduce il doppio dei suoni. Da qui il globalstep
minetest.register_globalstep(function(dtime)
  for mod, ar_name in pairs(active_queues) do
    for _, info in pairs(ar_name) do
      info.time_left = info.time_left - dtime

      local arena = info.arena
      local time_left = math.ceil(info.time_left)

      -- per eseguire queste chiamate solo una volta al secondo, utilizzo un booleano
      if not info.was_second_run[time_left] then

        if time_left <= 0 then
          go_to_arena(mod, arena)
        elseif time_left <= 5 then
          arena_lib.HUD_send_msg_all("broadcast", arena, S("Game begins in @1!", time_left), nil, "arenalib_countdown")
          arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("Get ready!")))
        else
          arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("@1 seconds for the match to start", time_left)))
        end

        info.was_second_run[time_left] = true
      end
    end
  end
end)

----------------------------------------


----------------------------------------------
--------------------CORPO---------------------
----------------------------------------------

function arena_lib.join_queue(mod, arena, p_name)
  local arena_name = arena.name
  local arenaID = arena_lib.get_arena_by_name(mod, arena_name)

  if not ARENA_LIB_JOIN_CHECKS_PASSED(arena, arenaID, p_name) then return end

  -- se il giocatore è già in coda
  if arena_lib.is_player_in_queue(p_name) then
    local queued_mod = arena_lib.get_mod_by_player(p_name)
    local queued_ID = arena_lib.get_queueID_by_player(p_name)

    -- se era in coda per la stessa arena, interrompo qua, sennò procedo per aggiungerlo nella nuova
    if queued_mod == mod and queued_ID == arenaID then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You're already queuing for this arena!")))
      return
    else
      arena_lib.remove_player_from_queue(p_name)
    end
  end

  -- se ha fatto dentro-fuori troppe volte (in qualsiasi coda)
  if queue_joins[p_name] and queue_joins[p_name] >= 3 then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You've been blocked from entering any queue for 10 seconds, due to joining and leaving repeatedly in a short amount of time!")))
    if queue_joins[p_name] == 3 then  -- to avoid using a 2nd bool parameter to run the after just once
      queue_joins[p_name] = 4
      minetest.after(10, function() queue_joins[p_name] = nil end)
    end
    return
  end

  local mod_ref = arena_lib.mods[mod]

  -- controlli aggiuntivi
  if mod_ref.on_prejoin_queue then
    if not mod_ref.on_prejoin_queue(arena, p_name) then return end
  end

  for _, callback in ipairs(arena_lib.registered_on_prejoin_queue) do
    if not callback(mod_ref, arena, p_name) then return end
  end

  local players_to_add = arena_lib.get_and_add_joining_players(mod_ref, arena, p_name)

  -- notifico i vari giocatori del nuovo giocatore
  for _, pl_name in pairs(players_to_add) do
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#c8d692", arena_name .. " > " ..  pl_name))
    players_in_queue[pl_name] = {minigame = mod, arenaID = arenaID}
  end

  increase_join_count(p_name)

  local arena_max_players = arena.max_players * #arena.teams
  local has_queue_status_changed = false      -- per il richiamo globale, o non hanno modo di saperlo (dato che viene chiamato all'ultimo)

  -- se la coda non è partita...
  if not arena.in_queue and not arena.in_game then

    local players_required = arena_lib.get_players_amount_left_to_start_queue(arena)

    -- ...e ci sono abbastanza giocatori, parte il timer d'attesa
    if players_required <= 0 then
      local timer = mod_ref.settings.queue_waiting_time

      arena.in_queue = true
      has_queue_status_changed = true
      active_queues[mod][arena_name] = { arena = arena, time_left = timer, was_second_run = {} }

    -- sennò aggiorno semplicemente la HUD
    else
      arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("Waiting for more players...")) ..
        " (" .. players_required .. ")")
    end
  end

  -- se raggiungo i giocatori massimi e la partita non è iniziata, accorcio eventualmente la durata
  if arena.players_amount == arena_max_players and arena.in_queue then
    if active_queues[mod][arena_name].time_left > 5 then
      active_queues[mod][arena_name].time_left = 5
    end
  end

  -- richiami eventuali
  if mod_ref.on_join_queue then
    mod_ref.on_join_queue(arena, p_name)
  end

  for _, callback in ipairs(arena_lib.registered_on_join_queue) do
    callback(mod_ref, arena, p_name, has_queue_status_changed)
  end

  arena_lib.entrances[arena.entrance_type].update(mod, arena)
  return true
end



function arena_lib.remove_player_from_queue(p_name)
  local mod = arena_lib.get_mod_by_player(p_name)
  local mod_ref = arena_lib.mods[mod]
  local arena = arena_lib.get_arena_by_player(p_name)

  if not arena then return end

  -- creo una tabella che andrò poi ad iterare, perché se parliamo di un gruppo, dovrò
  -- eseguire la rimozione per ogni singolo membro
  local players_to_remove = {}

  -- se è un gruppo
  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then

    -- (se non è il capogruppo, annullo)
    if not parties.is_player_party_leader(p_name) then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Only the party leader can leave the queue!")))
      return end

    local party_members = parties.get_party_members(p_name)

    for _, pl_name in pairs(party_members) do
      players_to_remove[pl_name] = true
    end

  -- sennò singolo utente
  else
    players_to_remove[p_name] = true
  end

  local arena_name = arena.name

  for pl_name, _ in pairs(players_to_remove) do
    arena_lib.HUD_hide("all", pl_name)
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#d69298", arena_name .. " < " .. pl_name))

    players_in_queue[pl_name] = nil
    arena.players_amount = arena.players_amount - 1
    if arena.teams_enabled then
      local p_team_ID = arena.players[pl_name].teamID
      arena.players_amount_per_team[p_team_ID] = arena.players_amount_per_team[p_team_ID] - 1
    end
    arena.players[pl_name] = nil
    arena.players_and_spectators[pl_name] = nil
  end

  local players_required = arena_lib.get_players_amount_left_to_start_queue(arena)
  local has_queue_status_changed = false      -- per il richiamo globale, o non hanno modo di saperlo (dato che viene chiamato all'ultimo)

  -- se l'arena era in coda e ora ci son troppi pochi giocatori, annullo la coda
  if arena.in_queue and players_required > 0 then

    local arena_max_players = arena.max_players * #arena.teams

    arena.in_queue = false
    has_queue_status_changed = true
    active_queues[mod][arena_name] = nil

    arena_lib.HUD_hide("broadcast", arena)
    arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("Waiting for more players...")) .. " (" .. players_required .. ")")
    arena_lib.send_message_in_arena(arena, "both", mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))

  -- se già non era in coda, aggiorno HUD
  elseif players_required > 0 then
    arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("Waiting for more players...")) .. " (" .. players_required .. ")")

  -- idem se è rimasta in coda
  else
    local seconds = math.ceil(active_queues[mod][arena_name].time_left)
    arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("@1 seconds for the match to start", seconds)))
  end

  -- richiami eventuali
  if mod_ref.on_leave_queue then
    mod_ref.on_leave_queue(arena, p_name)
  end

  for _, callback in ipairs(arena_lib.registered_on_leave_queue) do
    callback(mod_ref, arena, p_name, has_queue_status_changed)
  end

  arena_lib.entrances[arena.entrance_type].update(mod, arena)
  return true
end





----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_players_amount_left_to_start_queue(arena)
  if not arena or arena.in_game then return end

  local arena_min_players = arena.min_players * #arena.teams
  local players_required

  if arena.teams_enabled then
    players_required = 0

    for _, amount in pairs(arena.players_amount_per_team) do
      if arena.min_players - amount > 0 then
        players_required = players_required + (arena.min_players - amount)
      end
    end
  else
    players_required = arena_min_players - arena.players_amount
  end

  return math.max(0, players_required)
end



function arena_lib.get_queueID_by_player(p_name)
  if players_in_queue[p_name] then
    return players_in_queue[p_name].arenaID
  end
end



-- internal use only, don't use it. It makes the API smoother for modders
function arena_lib.get_mod_by_queuing_player(p_name)
  return players_in_queue[p_name].minigame
end



-- internal use only, don't use it. It makes the API smoother for modders
function arena_lib.get_arena_by_queuing_player(p_name)
  local mod = players_in_queue[p_name].minigame
  local arenaID = players_in_queue[p_name].arenaID

  return arena_lib.mods[mod].arenas[arenaID]
end



----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.is_player_in_queue(p_name, mod)
  if not players_in_queue[p_name] then
    return false
  else

    -- se il campo mod è specificato, controllo che sia lo stesso
    if mod then
      if players_in_queue[p_name].minigame == mod then return true
      else return false
      end
    end

    return true
  end
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function initialise_queue_container()
  for mod, _ in pairs(arena_lib.mods) do
    active_queues[mod] = {}
  end
end



function increase_join_count(p_name)
  if not queue_joins[p_name] then
    queue_joins[p_name] = 1
  else
    queue_joins[p_name] = queue_joins[p_name] + 1
  end

  local val = queue_joins[p_name]

  minetest.after(3, function()
    if queue_joins[p_name] and queue_joins[p_name] < 3 and queue_joins[p_name] <= val then
      queue_joins[p_name] = nil
    end
  end)
end



function go_to_arena(mod, arena)

  active_queues[mod][arena.name] = nil
  arena.in_queue = false
  arena.in_game = true
  arena_lib.entrances[arena.entrance_type].update(mod, arena)

  for pl_name, _ in pairs(arena.players) do
    players_in_queue[pl_name] = nil
  end

  local arena_ID = arena_lib.get_arena_by_name(mod, arena.name)

  arena_lib.HUD_hide("all", arena)
  arena_lib.load_arena(mod, arena_ID)
end



-- es. Foresta | 3/4 | Il match inizierà a breve
function queue_format(arena, msg)
  local arena_max_players = arena.max_players * #arena.teams
  return arena.name .. " | " .. arena.players_amount .. "/" .. arena_max_players  .. " | " .. msg
end

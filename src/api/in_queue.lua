local S = minetest.get_translator("arena_lib")

local function initialise_queue_container() end
local function assign_team() end
local function countdown() end
local function go_to_arena() end
local function queue_format() end

local players_in_queue = {}           -- KEY: player name, VALUE: {(string) minigame, (int) arenaID}
local active_queues = {}              -- KEY: [mod] arena_name, VALUE: (int) current timer

-- inizializzo il contenitore delle code una volta che tutti i minigiochi sono stati caricati
minetest.after(0.1, function()
  initialise_queue_container()
end)

----------------------------------------


function arena_lib.join_queue(mod, arena, p_name)
  -- se si è nell'editor
  if arena_lib.is_player_in_edit_mode(p_name) then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must leave the editor first!")))
    return end

  local arena_name = arena.name
  local arenaID = arena_lib.get_arena_by_name(mod, arena_name)

  -- se c'è `parties` e si è in gruppo...
  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) and arena_lib.get_queueID_by_player(p_name) ~= arenaID then

    -- se non si è il capo gruppo
    if not parties.is_player_party_leader(p_name) then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Only the party leader can enter the queue!")))
      return end

    local party_members = parties.get_party_members(p_name)

    -- per tutti i membri...
    for _, pl_name in pairs(party_members) do
      -- se uno è in partita
      if arena_lib.is_player_in_arena(pl_name) then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must wait for all your party members to finish their ongoing games before entering a new one!")))
        return end

      -- se uno è attaccato a qualcosa
      if minetest.get_player_by_name(pl_name):get_attach() then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Can't enter a game if some of your party members are attached to something! (e.g. boats, horses etc.)")))
        return end
    end

    --se non c'è spazio (no gruppo)
    if not arena.teams_enabled then
      if #party_members > arena.max_players - arena.players_amount then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is not enough space for the whole party!")))
        return end
    -- se non c'è spazio (gruppo)
    else

      local free_space = false
      for _, amount in pairs(arena.players_amount_per_team) do
        if #party_members <= arena.max_players - amount then
          free_space = true
          break
        end
      end

      if not free_space then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is no team with enough space for the whole party!")))
        return end
    end
  end

  local player = minetest.get_player_by_name(p_name)

  -- se si è attaccati a qualcosa
  if player:get_attach() then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must detach yourself from the entity you're attached to before entering!")))
    return end

  -- se non è abilitata
  if not arena.enabled then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
    return end

  -- se l'arena è piena
  if arena.players_amount == arena.max_players * #arena.teams and arena_lib.get_queueID_by_player(p_name) ~= arenaID then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is already full!")))
    return end

  -- se sta caricando o sta finendo
  if arena.in_loading or arena.in_celebration then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is loading, try again in a few seconds!")))
    return end

  local mod_ref = arena_lib.mods[mod]

  -- se è in corso e non permette l'entrata
  if arena.in_game and mod_ref.join_while_in_progress == false then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] This minigame doesn't allow to join while in progress!")))
    return end

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

  -- controlli aggiuntivi
  if mod_ref.on_prejoin_queue then
    if not mod_ref.on_prejoin_queue(arena, p_name) then return end
  end

  for _, callback in ipairs(arena_lib.registered_on_prejoin_queue) do
    if not callback(mod_ref, arena, p_name) then return end
  end

  local p_team_ID

  -- determino eventuale squadra giocatore
  if arena.teams_enabled then
    p_team_ID = assign_team(mod_ref, arena, p_name)
  end

  local players_to_add = {}

  -- potrei avere o un giocatore o un intero gruppo da aggiungere. Quindi per evitare mille if, metto a prescindere il/i giocatore/i in una tabella per iterare in alcune operazioni successive
  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then
    for k, v in pairs(parties.get_party_members(p_name)) do
      players_to_add[k] = v
    end
  else
    table.insert(players_to_add, p_name)
  end

  -- aggiungo il giocatore
  for _, pl_name in pairs(players_to_add) do
    arena.players[pl_name] = {kills = 0, deaths = 0, teamID = p_team_ID}
    arena.players_and_spectators[pl_name] = true
  end

  -- aumento il conteggio di giocatori in partita
  arena.players_amount = arena.players_amount + #players_to_add
  if arena.teams_enabled then
    arena.players_amount_per_team[p_team_ID] = arena.players_amount_per_team[p_team_ID] + #players_to_add
  end

  -- notifico i vari giocatori del nuovo giocatore
  if arena.in_game then
    for _, pl_name in pairs(players_to_add) do
      arena_lib.join_arena(mod, pl_name, arenaID)
      arena_lib.update_sign(arena)
    end
    return
  else
    for _, pl_name in pairs(players_to_add) do
      arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#c8d692", arena_name .. " > " ..  pl_name))
      players_in_queue[pl_name] = {minigame = mod, arenaID = arenaID}
    end
  end

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
      active_queues[mod][arena_name] = timer
      countdown(mod, arena)

    -- sennò aggiorno semplicemente la HUD
    else
      arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("Waiting for more players...")) ..
        " (" .. players_required .. ")")
    end
  end

  -- se raggiungo i giocatori massimi e la partita non è iniziata, accorcio eventualmente la durata
  if arena.players_amount == arena_max_players and arena.in_queue then
    if active_queues[mod][arena_name] > 5 then
      active_queues[mod][arena_name] = 5
    end
  end

  -- richiami eventuali
  if mod_ref.on_join_queue then
    mod_ref.on_join_queue(arena, p_name)
  end

  for _, callback in ipairs(arena_lib.registered_on_join_queue) do
    callback(mod_ref, arena, p_name, has_queue_status_changed)
  end

  arena_lib.update_sign(arena)
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
    players_in_queue[pl_name] = nil
    arena.players_amount = arena.players_amount - 1
    if arena.teams_enabled then
      local p_team_ID = arena.players[pl_name].teamID
      arena.players_amount_per_team[p_team_ID] = arena.players_amount_per_team[p_team_ID] - 1
    end
    arena.players[pl_name] = nil
    arena.players_and_spectators[pl_name] = nil

    arena_lib.HUD_hide("all", pl_name)
    arena_lib.send_message_in_arena(arena, "both", minetest.colorize("#d69298", arena_name .. " < " .. pl_name))
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
    local seconds = active_queues[mod][arena_name]
    arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("@1 seconds for the match to start", seconds)))
  end

  -- richiami eventuali
  if mod_ref.on_leave_queue then
    mod_ref.on_leave_queue(arena, p_name)
  end

  for _, callback in ipairs(arena_lib.registered_on_leave_queue) do
    callback(mod_ref, arena, p_name, has_queue_status_changed)
  end

  arena_lib.update_sign(arena)
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



function assign_team(mod_ref, arena, p_name)

  local assigned_team_ID = 1

  for i = 1, #arena.teams do
    if arena.players_amount_per_team[i] < arena.players_amount_per_team[assigned_team_ID] then
      assigned_team_ID = i
    end
  end

  local p_team = arena.teams[assigned_team_ID].name

  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then
    for _, pl_name in pairs(parties.get_party_members(p_name)) do
      minetest.chat_send_player(pl_name, mod_ref.prefix .. S("You've joined team @1", minetest.colorize("#eea160", p_team)))
    end
  else
    minetest.chat_send_player(p_name, mod_ref.prefix .. S("You've joined team @1", minetest.colorize("#eea160", p_team)))
  end

  return assigned_team_ID
end



function countdown(mod, arena)
  local seconds = active_queues[mod][arena.name]

  -- dai 5 secondi in giù il messaggio è stampato su broadcast e genero le squadre
  if seconds == 0 then
    go_to_arena(mod, arena)
  elseif seconds <= 5 then
    arena_lib.HUD_send_msg_all("broadcast", arena, S("Game begins in @1!", seconds), nil, "arenalib_countdown")
    arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("Get ready!")))
  else
    arena_lib.HUD_send_msg_all("hotbar", arena, queue_format(arena, S("@1 seconds for the match to start", seconds)))
  end

  minetest.after(1, function()
    -- i secondi potrebbero esser stati alterati dall'esterno, tipo se la coda si è riempita
    seconds = active_queues[mod][arena.name]

    if not arena.in_queue or not seconds then return end

    active_queues[mod][arena.name] = seconds -1
    countdown(mod, arena)
  end)
end



function go_to_arena(mod, arena)

  active_queues[mod][arena.name] = nil
  arena.in_queue = false
  arena.in_game = true
  arena_lib.update_sign(arena)

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

local storage = minetest.get_mod_storage()
storage:set_string("arenas", nil) -- PER RESETTARE LO STORAGE

arena_lib = { arenas = {} }

if minetest.deserialize(storage:get_string("arenas")) ~= nil then
  arena_lib.arenas = minetest.deserialize(storage:get_string("arenas"))
end

function arena_lib.update_storage()
  storage:set_string("arenas", minetest.serialize(arena_lib.arenas))
end

local function newArena() end
local function nextID() end

local arenasID
local players_in_game = {}    --KEY: player name, INDEX: arenaID
local players_in_queue = {}   --KEY: player name, INDEX: arenaID
local immunity_time = 3

local arena_default_max_players = 4
local arena_default_min_players = 2
local arena_default_kill_cap = 10

arena_lib.arena_default = {
  name = "",
  sign = {},
  players = {},               --KEY: player name, INDEX: kills, deaths, killstreak
  spawn_points = {},
  max_players = arena_default_max_players,
  min_players = arena_default_min_players,
  kill_cap = arena_default_kill_cap,
  kill_leader = "",
  in_queue = false,
  in_game = false,
  in_celebration = false
}

function arena_lib.create_arena(sender, arena_name)

  arenasID = nextID()

  -- controllo che non ci siano duplicati
  if arenasID > 1 and arena_lib.get_arena_by_name(arena_name) ~= nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Esiste già un'arena con quel nome!"))
    return end

  -- creo l'arena e la rinomino, aggiornando anche lo storage
  arena_lib.arenas[arenasID] = newArena(arena_lib.arena_default)
  arena_lib.arenas[arenasID].name = arena_name
  arena_lib.update_storage()
  minetest.chat_send_player(sender, "Arena " .. arena_name .. " creata con successo")

end



function arena_lib.remove_arena(sender, arena_name)

  local id, arena = arena_lib.get_arena_by_name(arena_name)

  if not arena then minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Non c'è nessun'arena chiamata " .. arena_name .. "!"))
    return end

  if arena.in_game then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Una partita è in corso nell'arena " .. arena_name .. ": impossibile rimuoverla"))
    return end

  --TODO: -chiedere conferma

  -- rimozione cartello coi rispettivi metadati
  if arena.sign ~= nil then
    minetest.set_node(arena.sign, {name = "air"}) end

  arena_lib.send_message_players_in_arena(id, "[Quake] L'arena per la quale eri in coda è stata rimossa... :(")

  -- rimozione arena e aggiornamento storage
  arena_lib.arenas[id] = nil
  arena_lib.update_storage()
  minetest.chat_send_player(sender, "Arena " .. arena_name .. " rimossa con successo")

end



function arena_lib.is_player_in_arena(p_name)

  if not players_in_game[p_name] then return false
  else return true end
end



function arena_lib.is_player_in_queue(p_name)

  if not players_in_queue[p_name] then return false
  else return true end
end


----------------------------------------------
---------------GESTIONE ARENA-----------------
----------------------------------------------

-- per tutti i giocatori quando finisce la coda
function arena_lib.load_arena(arena_ID)

  local count = 1
  local weapon = ItemStack("quake:railgun")
  local arena = arena_lib.arenas[arena_ID]

  -- teletrasporto giocatori e sostituisco l'inventario
  for pl_name, stats in pairs(arena.players) do

    local player = minetest.get_player_by_name(pl_name)

    player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
    player: set_physics_override({
              speed = 1.7,
              jump = 1.5,
              gravity = 1.15,
              })

    player:set_pos(arena.spawn_points[count])
    player:get_inventory():set_list("main",{})
    player:get_inventory():add_item("main", weapon)
    players_in_queue[pl_name] = nil
    players_in_game[pl_name] = arena_ID       -- registro giocatori nella tabella apposita

    count = count +1
  end
end


-- per il player singolo a match iniziato
function arena_lib.join_arena(arena_ID)
  --TODO
end


--a partita finita
function arena_lib.load_celebration(arena_ID, winner_name)

  local arena = arena_lib.arenas[arena_ID]
  arena.in_celebration = true

  arena_lib.update_sign(arena.sign, arena)
  arena_lib.update_storage()

  for pl_name, stats in pairs(arena.players) do

    local inv = minetest.get_player_by_name(pl_name):get_inventory()
    local weapon = inv:get_stack("main", 1)
    local meta = weapon:get_meta():set_int("immune", 1)
    inv:set_stack("main", 1, weapon)

    minetest.get_player_by_name(pl_name):set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})

    minetest.chat_send_player(pl_name, "[Quake] " .. winner_name .. " ha vinto la partita")
  end


  -- momento celebrazione
  minetest.after(3, function()
    arena_lib.end_arena(arena)
  end)

end



function arena_lib.end_arena(arena)

  for pl_name, stats in pairs(arena.players) do

    arena.players[pl_name] = nil
    players_in_game[pl_name] = nil

    arena.in_celebration = false
    arena.in_game = false
    arena_lib.update_sign(arena.sign, arena)
    arena_lib.update_storage()

    minetest.get_player_by_name(pl_name):set_physics_override({
            speed = 1,
            jump = 1,
            gravity = 1,
            })

    --TODO: teleport lobby, metti variabile locale
  end
end



function arena_lib.add_to_queue(p_name, arena_ID)
  players_in_queue[p_name] = arena_ID
end

function arena_lib.remove_from_queue(p_name)
  players_in_queue[p_name] = nil
end

----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------


function arena_lib.remove_player_from_arena(p_name)

  local arena_ID = players_in_game[p_name]

  arena_lib.arenas[arena_ID].players[p_name] = nil
  players_in_game[p_name] = nil
  players_in_queue[p_name] = nil
  arena_lib.send_message_players_in_arena(arena_ID, "[Quake] " .. p_name .. " ha abbandonato la partita")

  --TODO: se in arena è rimasto solo un giocatore, ha vinto e end arena
end


function arena_lib.send_message_players_in_arena(arena_ID, msg)
  for pl_name, stats in pairs(arena_lib.arenas[arena_ID].players) do
    minetest.chat_send_player(pl_name, msg) end
end


function arena_lib.calc_kill_leader(arena, killer)

  if arena.kill_leader == "" then arena.kill_leader = killer return end

  if arena.players[killer].kills > arena.players[arena.kill_leader].kills then
    arena.kill_leader = killer end
end


function arena_lib.immunity(player)

  local p_name = player:get_player_name()
  local weapon = player:get_inventory():get_stack("main", 1)

  weapon:get_meta():set_int("immune", 1)

  player:get_inventory():set_stack("main", 1, weapon)

  minetest.after(immunity_time, function()
    if player == nil then return end -- he may disconnect
    if player:get_inventory():get_stack("main", 1):get_meta():get_int("immune") == 1 then
      weapon:get_meta():set_int("immune", 0)
      player:get_inventory():set_stack("main", 1, weapon)
    end
  end)

end

----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_arena_by_name(arena_name)

  for id, arena in pairs(arena_lib.arenas) do
    if arena.name == arena_name then
      return id, arena end
  end
end


function arena_lib.get_arenaID_by_player(p_name)
  return players_in_game[p_name]
end


function arena_lib.get_queueID_by_player(p_name)
  return players_in_queue[p_name]
end


function arena_lib.get_arena_players_count(arena_ID)

  local count = 0
  local arena = arena_lib.arenas[arena_ID]

  for id, spawn in pairs(arena.players) do
    count = count+1
  end

  return count
end


function arena_lib.get_arena_spawners_count(arena_ID)
  return table.maxn(arena_lib.arenas[arena_ID].spawn_points)
end


function arena_lib.get_random_spawner(arena_ID)
  return arena_lib.arenas[arena_ID].spawn_points[math.random(1,arena_lib.get_arena_spawners_count(arena_ID))]
end



----------------------------------------------
-----------------SETTERS----------------------
----------------------------------------------

function arena_lib.set_immunity_time(time)
  immunity_time = time
end

----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

--[[ Dato che in Lua non è possibile istanziare le tabelle copiandole, bisogna istanziare ogni campo in una nuova tabella.
     Ricorsivo per le sottotabelle. Codice da => http://lua-users.org/wiki/CopyTable]]
function newArena(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[newArena(orig_key)] = newArena(orig_value)
        end
        setmetatable(copy, newArena(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


--[[ l'ID di base parte da 1 (n+1) per non generare errori, tipo "if arenaID == 0" al verificare se non esiste.
     In una sequenza 0, 1, 2, 3 se si rimuove "2" e si aggiunge un nuovo ID perciò si avrà 0, 1, 3, 4]]
function nextID()
  local n = 0
  for id, arena in pairs(arena_lib.arenas) do
    if id > n then n = id end
  end
  return n+1
end

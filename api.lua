arena_lib = {}
arena_lib.arenas = {}
arena_lib.mod_name = minetest.get_current_modname()

dofile(minetest.get_modpath("quake") .. "/arena_lib/debug_utilities.lua")
dofile(minetest.get_modpath("quake") .. "/arena_lib/items.lua")
dofile(minetest.get_modpath("quake") .. "/arena_lib/player_manager.lua")
dofile(minetest.get_modpath("quake") .. "/arena_lib/signs.lua")

----------------------------------------------
--------------GESTIONE STORAGE----------------
----------------------------------------------

local storage = minetest.get_mod_storage()
--storage:set_string("arenas", nil) -- PER RESETTARE LO STORAGE

if minetest.deserialize(storage:get_string("arenas")) ~= nil then
  arena_lib.arenas = minetest.deserialize(storage:get_string("arenas"))

  -- resetto lo stato delle arene, nel caso il server sia crashato o sia stato
  -- stoppato con partite in corso. L'alternativa è mettere una cosa simile in
  -- update_storage() copiando ricorsivamente la tabella e rimuovendo il tutto
  -- nella tabella copiata, ma è più pesante. E non posso metterlo in
  -- minetest.register_on_shutdown() perché se crasha non viene chiamato
  for id, arena in pairs(arena_lib.arenas) do
    arena.players = {}
    arena.kill_leader = ""
    arena.in_queue = false
    arena.in_loading = false
    arena.in_celebration = false

    minetest.after(0.01, function()
      arena_lib.update_sign(arena.sign, arena)
    end)
  end
end


----------------------------------------------
---------------DICHIARAZIONI------------------
----------------------------------------------

local function update_storage() end
local function new_arena() end
local function next_ID() end

local arenasID
local players_in_game = {}    --KEY: player name, INDEX: arenaID
local players_in_queue = {}   --KEY: player name, INDEX: arenaID

local arena_default_max_players = 4
local arena_default_min_players = 2
local arena_default_kill_cap = 10

local arena_default = {
  name = "",
  sign = {},
  players = {},               --KEY: player name, INDEX: kills, deaths, killstreak
  spawn_points = {},
  max_players = arena_default_max_players,
  min_players = arena_default_min_players,
  kill_cap = arena_default_kill_cap,
  kill_leader = "",
  in_queue = false,
  in_loading = false,
  in_game = false,
  in_celebration = false,
  enabled = false
}

local prefix = "[Arena_lib] "
local hub_spawn_point = { x = 0, y = 20, z = 0}
local load_time = 3
local celebration_time = 3
local immunity_time = 3
local immunity_slot = 9       --people may have tweaked the slots, hence the custom parameter


-- call this in your mod to override the last block of values
function arena_lib.settings(def)

  if def.prefix then
    prefix = def.prefix
  end

  if def.hub_spawn_point then
    hub_spawn_point = def.hub_spawn_point
  end

  if def.load_time then
    load_time = def.load_time
  end

  if def.celebration_time then
    celebration_time = def.celebration_time
  end

  if def.immunity_time then
    immunity_time = def.immunity_time
  end

  if def.immunity_slot then
    immunity_slot = def.immunity_slot
  end

end



----------------------------------------------
---------------GESTIONE ARENA-----------------
----------------------------------------------

function arena_lib.create_arena(sender, arena_name)

  arenasID = next_ID()

  -- controllo che non ci siano duplicati
  if arenasID > 1 and arena_lib.get_arena_by_name(arena_name) ~= nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Esiste già un'arena con quel nome!"))
    return end

  -- creo l'arena e la rinomino, aggiornando anche lo storage
  arena_lib.arenas[arenasID] = new_arena(arena_default)
  arena_lib.arenas[arenasID].name = arena_name
  update_storage()
  minetest.chat_send_player(sender, prefix .. "Arena " .. arena_name .. " creata con successo")

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

  arena_lib.send_message_players_in_arena(id, prefix .."L'arena per la quale eri in coda è stata rimossa... :(")

  -- rimozione arena e aggiornamento storage
  arena_lib.arenas[id] = nil
  update_storage()
  minetest.chat_send_player(sender, prefix .. "Arena " .. arena_name .. " rimossa con successo")

end



-- Gli spawn points si impostano prendendo la coordinata del giocatore che lancia il comando.
-- Non ci possono essere più spawn points del numero massimo di giocatori e non possono essere impostati in aria
-- Indicando lo spawner_ID, si andrà a sovrascrivere lo spawner con quell'ID se esiste
function arena_lib.set_spawner(sender, arena_name, spawner_ID)

  local id, arena = arena_lib.get_arena_by_name(arena_name)

  if arena == nil then minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Quest'arena non esiste!"))
    return end

  local spawn_points_count = arena_lib.get_arena_spawners_count(id)

  if spawn_points_count == arena.max_players and spawner_ID == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Gli spawn point non possono superare i giocatori massimi! Vuoi cancellarne alcuni con /quakeadmin delspawn <arena>?"))
  return end

  if spawner_ID ~= nil and spawner_ID > spawn_points_count then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Nessuno spawner con quell'ID da sovrascrivere!"))
  return end

  local pos = vector.floor(minetest.get_player_by_name(sender):get_pos())   --tolgo i decimali per storare un int
  local pos_Y_up = {x = pos.x, y = pos.y+1, z = pos.z}                    -- alzo Y di uno sennò tippa nel blocco
  local pos_feet = {x = pos.x, y = pos.y-1, z = pos.z}

  if minetest.get_node(pos_feet).name == "air" then minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Non puoi impostare spawn point nell'aria!"))
    return end

  for id, spawn in pairs(arena.spawn_points) do
    if minetest.serialize(pos_Y_up) == minetest.serialize(spawn) then minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] C'è già uno spawn in questo punto!"))
      return end
  end

  if spawner_ID ~= nil then
    arena.spawn_points[spawner_ID] = pos_Y_up
    minetest.chat_send_player(name, prefix .. "Spawn point " .. spawner_ID .. " sovrascritto con successo" )
  else
    arena.spawn_points[spawn_points_count +1] = pos_Y_up
    minetest.chat_send_player(name, prefix .. "Spawn point " .. spawn_points_count +1 .. " impostato con successo" )
  end

  update_storage()
end



function arena_lib.enable_arena(sender, arena_ID)

  local arena = arena_lib.arenas[arena_ID]

  if arena_lib.get_arena_spawners_count(arena_ID) < arena.max_players then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Spawner insufficienti, arena disabilitata!"))
    arena.enabled = false
  return end

  arena.enabled = true
  arena_lib.update_sign(arena.sign, arena)
  update_storage()
  minetest.chat_send_player(sender, prefix .. "Arena abilitata con successo")

end



----------------------------------------------
--------------GESTIONE PARTITA-----------------
----------------------------------------------

-- per tutti i giocatori quando finisce la coda
function arena_lib.load_arena(arena_ID)

  local count = 1
  local arena = arena_lib.arenas[arena_ID]

  arena.in_loading = true
  arena_lib.update_sign(arena.sign, arena)

  -- teletrasporto giocatori e sostituisco l'inventario
  for pl_name, stats in pairs(arena.players) do

    local player = minetest.get_player_by_name(pl_name)

    player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
    player: set_physics_override({
              speed = 0,
              })

    player:set_pos(arena.spawn_points[count])
    player:get_inventory():set_list("main",{})
    players_in_queue[pl_name] = nil
    players_in_game[pl_name] = arena_ID       -- registro giocatori nella tabella apposita

    count = count +1
  end

  arena_lib.on_load(arena)

  minetest.after(load_time, function()
    arena_lib.start_arena(arena)
  end)

end



-- per il player singolo a match iniziato
function arena_lib.join_arena(p_name, arena_ID)

  local player = minetest.get_player_by_name(p_name)

  player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
  player:get_inventory():set_list("main",{})
  player:set_pos(arena_lib.get_random_spawner(arena_ID))
  players_in_game[p_name] = arena_ID

  arena_lib.on_join(p_name, arena_ID)
end



function arena_lib.start_arena(arena)

  arena.in_loading = false
  arena.in_game = true
  arena_lib.update_sign(arena.sign, arena)

  for pl_name, stats in pairs(arena.players) do

    minetest.get_player_by_name(pl_name):set_physics_override({
            speed = 1,
            jump = 1,
            gravity = 1,
            })
  end

  arena_lib.on_start(arena)
end



--a partita finita
function arena_lib.load_celebration(arena_ID, winner_name)

  local arena = arena_lib.arenas[arena_ID]

  arena.in_celebration = true
  arena_lib.update_sign(arena.sign, arena)

  for pl_name, stats in pairs(arena.players) do

    local inv = minetest.get_player_by_name(pl_name):get_inventory()

    -- giocatori immortali
    if not inv:contains_item("main", arena_lib.mod_name .. ":immunity") then
      inv:set_stack("main", immunity_slot, arena_lib.mod_name .. ":immunity")
    end

    minetest.get_player_by_name(pl_name):set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})
    minetest.chat_send_player(pl_name, prefix  .. winner_name .. " ha vinto la partita")
  end

  arena_lib.on_celebration(arena_ID, winner_name)

  -- momento celebrazione
  minetest.after(celebration_time, function()
    arena_lib.end_arena(arena)
  end)

end



function arena_lib.end_arena(arena)

  arena.kill_leader = ""

  local players = {}

  for pl_name, stats in pairs(arena.players) do

    players[pl_name] = stats
    arena.players[pl_name] = nil
    players_in_game[pl_name] = nil
    arena.in_celebration = false
    arena.in_game = false

    local player = minetest.get_player_by_name (pl_name)

    player:get_inventory():set_list("main", {})
    player:set_pos(hub_spawn_point)
  end

  arena_lib.update_sign(arena.sign, arena)
  arena_lib.on_end(arena, players)
end



function arena_lib.add_to_queue(p_name, arena_ID)
  players_in_queue[p_name] = arena_ID
end



function arena_lib.remove_from_queue(p_name)
  players_in_queue[p_name] = nil
end



function arena_lib.on_load(arena)
 --[[override this function on your mod if you wanna add more!
 Just do: function arena_lib.on_load() yourstuff end]]
end



function arena_lib.on_join(p_name, arena_ID)
 --[[override this function on your mod if you wanna add more!
 Just do: function arena_lib.on_join() yourstuff end]]
end



function arena_lib.on_start(arena)
 --[[override this function on your mod if you wanna add more!
 Just do: function arena_lib.on_load() yourstuff end]]
end



function arena_lib.on_celebration(arena_ID, winner_name)
 --[[override this function on your mod if you wanna add more!
 Just do: function arena_lib.on_celebration() yourstuff end]]
end



function arena_lib.on_end(arena)
 --[[override this function on your mod if you wanna add more!
 Just do: function arena_lib.on_end() yourstuff end]]
end



----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

function arena_lib.is_player_in_arena(p_name)

  if not players_in_game[p_name] then return false
  else return true end
end



function arena_lib.is_player_in_queue(p_name)

  if not players_in_queue[p_name] then return false
  else return true end
end



function arena_lib.remove_player_from_arena(p_name)

  local arena_ID = players_in_game[p_name]
  local arena = arena_lib.arenas[arena_ID]

  if arena == nil then return end

  arena.players[p_name] = nil
  players_in_game[p_name] = nil
  players_in_queue[p_name] = nil

  arena_lib.update_sign(arena.sign, arena)
  arena_lib.send_message_players_in_arena(arena_ID, prefix .. p_name .. " ha abbandonato la partita")

  if arena_lib.get_arena_players_count(arena_ID) == 1 then
    arena_lib.send_message_players_in_arena(arena_ID, prefix .. "Hai vinto la partita per troppi pochi giocatori")
    for pl_name, stats in pairs(arena.players) do
      arena_lib.on_celebration(arena_ID, pl_name)
    end
  end
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

  local immunity_item = ItemStack(arena_lib.mod_name ..":immunity")
  local inv = player:get_inventory()

  inv:set_stack("main", immunity_slot, immunity_item)

  minetest.after(immunity_time, function()
    if player == nil then return end -- they may disconnect
    if inv:contains_item("main", immunity_item) then
      inv:remove_item("main", immunity_item)
    end
  end)

end



----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_hub_spawnpoint()
  return hub_spawn_point
end



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

  for pl_name, stats in pairs(arena.players) do
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



function arena_lib.get_immunity_slot()
  return immunity_slot
end


----------------------------------------------
-----------------SETTERS----------------------
----------------------------------------------

-- nothing to see here ¯\_(ツ)_/¯



----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function update_storage()
  storage:set_string("arenas", minetest.serialize(arena_lib.arenas))
end



--[[ Dato che in Lua non è possibile istanziare le tabelle copiandole, bisogna istanziare ogni campo in una nuova tabella.
     Ricorsivo per le sottotabelle. Codice da => http://lua-users.org/wiki/CopyTable]]
function new_arena(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[new_arena(orig_key)] = new_arena(orig_value)
        end
        setmetatable(copy, new_arena(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



--[[ l'ID di base parte da 1 (n+1) per non generare errori, tipo "if arenaID == 0" al verificare se non esiste.
     In una sequenza 0, 1, 2, 3 se si rimuove "2" e si aggiunge un nuovo ID perciò si avrà 0, 1, 3, 4]]
function next_ID()
  local n = 0
  for id, arena in pairs(arena_lib.arenas) do
    if id > n then n = id end
  end
  return n+1
end

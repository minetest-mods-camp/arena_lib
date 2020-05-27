arena_lib = {}
arena_lib.mods = {}

local S = minetest.get_translator("arena_lib")
local storage = minetest.get_mod_storage()



----------------------------------------------
---------------DICHIARAZIONI------------------
----------------------------------------------

local function init_storage() end
local function update_storage() end
local function new_arena() end
local function next_ID() end
local function timer_start() end

local players_in_game = {}    --KEY: player name, INDEX: {(string) minigame, (int) arenaID}
local players_in_queue = {}   --KEY: player name, INDEX: {(string) minigame, (int) arenaID}

local arena_default = {
  name = "",
  sign = {},
  players = {},               --KEY: player name, INDEX: kills, deaths, player_properties
  players_amount = 0,
  spawn_points = {},
  max_players = 4,
  min_players = 2,
  in_queue = false,
  in_loading = false,
  in_game = false,
  in_celebration = false,
  enabled = false
}

-- per inizializzare. Da lanciare all'inizio di ogni mod
function arena_lib.register_minigame(mod, def)

  local mod_ref = minetest.deserialize(storage:get_string(mod))

  -- se la mod non esiste nello storage, la creo da zero
  if not mod_ref then

    minetest.log("action", "[ARENA_LIB] new minigame found: " .. mod .. ". Initialising...")

    arena_lib.mods[mod] = {}
    arena_lib.mods[mod].arenas = {}      -- KEY: (int) arenaID , VALUE: (table) arena properties
    arena_lib.mods[mod].arenasID = 1     -- il contatore degli ID delle arene; inizia da 1

    mod_ref = arena_lib.mods[mod]
  end

  --default parameters
  mod_ref.prefix = "[Arena_lib] "
  mod_ref.hub_spawn_point = { x = 0, y = 20, z = 0}
  mod_ref.join_while_in_progress = false
  mod_ref.keep_inventory = false
  mod_ref.show_nametags = false
  mod_ref.show_minimap = false
  mod_ref.timer = -1
  mod_ref.is_timer_incrementing = false
  mod_ref.queue_waiting_time = 10
  mod_ref.load_time = 3           --time in the loading phase (the pre-match)
  mod_ref.celebration_time = 3    --time in the celebration phase
  mod_ref.immunity_time = 3
  mod_ref.immunity_slot = 8       --people may have tweaked the slots, hence the custom parameter
  mod_ref.properties = {}
  mod_ref.temp_properties = {}
  mod_ref.player_properties = {}

  if def.prefix then
    mod_ref.prefix = def.prefix
  end

  if def.hub_spawn_point then
    mod_ref.hub_spawn_point = def.hub_spawn_point
  end

  if def.join_while_in_progress == true then
    mod_ref.join_while_in_progress = def.join_while_in_progress
  end

  if def.keep_inventory == true then
    mod_ref.keep_inventory = def.keep_inventory
  end

  if def.show_nametags == true then
    mod_ref.show_nametags = def.show_nametags
  end

  if def.show_minimap == true then
    mod_ref.show_minimap = def.show_minimap
  end

  if def.timer then
    mod_ref.timer = def.timer
    if def.is_timer_incrementing == true then
      mod_ref.is_timer_incrementing = true
    end
  end

  if def.queue_waiting_time then
    mod_ref.queue_waiting_time = def.queue_waiting_time
  end

  if def.load_time then
    mod_ref.load_time = def.load_time
  end

  if def.celebration_time then
    mod_ref.celebration_time = def.celebration_time
  end

  if def.immunity_time then
    mod_ref.immunity_time = def.immunity_time
  end

  if def.immunity_slot then
    mod_ref.immunity_slot = def.immunity_slot
  end

  if def.properties then
    mod_ref.properties = def.properties
  end

  if def.temp_properties then
    mod_ref.temp_properties = def.temp_properties
  end

  if def.player_properties then
    mod_ref.player_properties = def.player_properties
  end

  storage:set_string(mod, minetest.serialize(mod_ref))
  init_storage(mod, mod_ref)

end


--[!!!] add this to your code only if you need to add some new property to your
-- old arenas
function arena_lib.update_properties(mod)

  minetest.log("action", "[ARENA_LIB] Updating properties for arenas in " .. mod)

  local mod_ref = arena_lib.mods[mod]

  if mod_ref == nil then
    minetest.log("error", "[ARENA_LIB] [!] There's no minigame called " .. mod .. ", properties update aborted")
  return end

  for id, arena in pairs(mod_ref.arenas) do

    for property, v in pairs(mod_ref.properties) do
      if arena[property] == nil then
        arena[property] = v
      end
    end

    update_storage(false, mod, id, arena)

    for temp_property, v in pairs(mod_ref.temp_properties) do
      arena[temp_property] = v
    end
  end

end



----------------------------------------------
---------------GESTIONE ARENA-----------------
----------------------------------------------

function arena_lib.create_arena(sender, mod, arena_name, min_players, max_players)

  local mod_ref = arena_lib.mods[mod]
  mod_ref.arenasID = next_ID(mod_ref)

  -- controllo che non ci siano duplicati
  if mod_ref.arenasID > 1 and arena_lib.get_arena_by_name(mod, arena_name) ~= nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] An arena with that name exists already!")))
  return end

  -- creo l'arena
  mod_ref.arenas[mod_ref.arenasID] = new_arena(arena_default)

  local arena = mod_ref.arenas[mod_ref.arenasID]

  -- sovrascrivo con i parametri della funzione
  arena.name = arena_name
  if min_players and max_players then
    arena.min_players = min_players
    arena.max_players = max_players
  end

  -- aggiungo le proprietà custom
  for property, value in pairs(mod_ref.properties) do
    arena[property] = value
  end

  -- e quelle temp custom
  for temp_property, value in pairs(mod_ref.temp_properties) do
    arena[temp_property] = value
  end

  -- aggiungo allo storage
  update_storage(false, mod, mod_ref.arenasID, arena)
  --aggiorno l'ID globale nello storage
  storage:set_string(mod, minetest.serialize(mod_ref))

  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 succesfully created", arena_name))

end



function arena_lib.remove_arena(sender, mod, arena_name)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if not arena then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is no arena named @1!", arena_name)))
  return end

  if arena.in_game then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is an ongoing match inside the arena @1: impossible to remove!", arena_name)))
  return end

  --TODO: -chiedere conferma

  -- rimozione cartello coi rispettivi metadati
  if arena.sign ~= nil then
    minetest.set_node(arena.sign, {name = "air"}) end

  local mod_ref = arena_lib.mods[mod]

  arena_lib.send_message_players_in_arena(arena, mod_ref.prefix ..S("The arena you were queueing for has been removed... :("))

  -- rimozione arena e aggiornamento storage
  mod_ref.arenas[id] = nil
  update_storage(true, mod, id, arena)
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully removed", arena_name))

end



-- Gli spawn points si impostano prendendo la coordinata del giocatore che lancia il comando.
-- Non ci possono essere più spawn points del numero massimo di giocatori e non possono essere impostati in aria
-- Indicando lo spawner_ID, si andrà a sovrascrivere lo spawner con quell'ID se esiste
function arena_lib.set_spawner(sender, mod, arena_name, spawner_ID)

  local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- controllo se esiste l'arena
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
  return end

  local spawn_points_count = arena_lib.get_arena_spawners_count(arena)

  -- se provo a settare uno spawn point di troppo, annullo
  if spawn_points_count == arena.max_players and spawner_ID == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Spawn points can't exceed the maximum number of players! If requested, you can overwrite them specifying the ID of the spawn as a parameter")))
  return end

  -- se l'ID dello spawner da sovrascrivere non corrisponde a nessun altro ID, annullo
  if spawner_ID ~= nil and spawner_ID > spawn_points_count then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] No spawner with that ID to overwrite!")))
  return end

  local pos = vector.floor(minetest.get_player_by_name(sender):get_pos())   --tolgo i decimali per storare un int
  local pos_Y_up = {x = pos.x, y = pos.y+1, z = pos.z}                    -- alzo Y di uno sennò tippa nel blocco
  local pos_feet = {x = pos.x, y = pos.y-1, z = pos.z}

  -- se il blocco sotto i piedi è aria, annullo
  if minetest.get_node(pos_feet).name == "air" then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't set the spawn point in the air!")))
  return end

  -- se c'è già uno spawner in quel punto, annullo
  for id, spawn in pairs(arena.spawn_points) do
    if minetest.serialize(pos_Y_up) == minetest.serialize(spawn) then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There's already a spawn in this point!")))
      return end
  end

  local mod_ref = arena_lib.mods[mod]

  -- sovrascrivo/creo lo spawnpoint
  if spawner_ID ~= nil then
    arena.spawn_points[spawner_ID] = pos_Y_up
    minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully overwritten", spawner_ID))
  else
    arena.spawn_points[spawn_points_count +1] = pos_Y_up
    minetest.chat_send_player(sender, mod_ref.prefix .. S("Spawn point #@1 successfully set", spawn_points_count +1))
  end

  update_storage(false, mod, id, arena)
end



function arena_lib.set_sign(itemstack, user, pos)

  local mod = itemstack:get_meta():get_string("mod")
  local arena_ID = itemstack:get_meta():get_int("arenaID")
  local arena = arena_lib.mods[mod].arenas[arena_ID]

  -- se l'arena è abilitata annullo
  if arena.enabled then
    minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", S("[!] You must disable the arena first!")))
    return end

  -- controllo se c'è già un cartello assegnato a quell'arena. Se è lo stesso lo rimuovo, sennò annullo
  if next(arena.sign) ~= nil then
    if minetest.serialize(pos) == minetest.serialize(arena.sign) then
      minetest.set_node(pos, {name = "air"})
      arena.sign = {}
      minetest.chat_send_player(user:get_player_name(), S("Sign of arena @1 successfully removed", arena.name))
      update_storage(false, mod, arena_ID, arena)
    else
      minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", S("[!] There is already a sign for this arena!")))
    end
  return end

  -- cambio la scritta
  arena_lib.update_sign(pos, arena)

  -- aggiungo il cartello ai cartelli dell'arena
  arena.sign = pos
  update_storage(false, mod, arena_ID, arena)

  -- salvo il nome della mod e l'ID come metadato nel cartello
  minetest.get_meta(pos):set_string("mod", mod)
  minetest.get_meta(pos):set_int("arenaID", arena_ID)
end



function arena_lib.enable_arena(sender, mod, arena_name)

  local mod_ref = arena_lib.mods[mod]
  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- controllo se esiste l'arena
  if not arena then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is no arena named @1!", arena_name)))
  return end

  -- se è già abilitata, annullo
  if arena.enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] The arena is already enabled")))
  return end

  -- check requisiti: spawner e cartello
  if arena_lib.get_arena_spawners_count(arena) < arena.max_players then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Insufficient spawners, the arena has been disabled!")))
    arena.enabled = false
  return end

  if not arena.sign.x then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] Sign not set, the arena has been disabled!")))
    arena.enabled = false
  return end

  -- abilito
  arena.enabled = true
  arena_lib.update_sign(arena.sign, arena)
  update_storage(false, mod, arena_ID, arena)
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully enabled", arena_name))

end



function arena_lib.disable_arena(sender, mod, arena_name)

  local mod_ref = arena_lib.mods[mod]
  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  -- controllo se esiste l'arena
  if not arena then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There is no arena named @1!", arena_name)))
  return end

  -- se è già disabilitata, annullo
  if not arena.enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] The arena is already disabled")))
  return end

  -- se una partita è in corso, annullo
  if arena.in_loading or arena.in_game or arena.in_celebration then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You can't disable an arena during an ongoing game!")))
  return end

  -- se c'è gente rimasta è in coda: annullo la coda e li avviso della disabilitazione
  for pl_name, stats in pairs(arena.players) do

    players_in_queue[pl_name] = nil
    arena.players[pl_name] = nil
    arena.in_queue = false
    minetest.chat_send_player(pl_name, minetest.colorize("#e6482e", S("[!] The arena you were queueing for has been disabled!")))

  end

  arena.players_amount = 0

  -- disabilito
  arena.enabled = false
  arena_lib.update_sign(arena.sign, arena)
  update_storage(false, mod, arena_ID, arena)
  minetest.chat_send_player(sender, mod_ref.prefix .. S("Arena @1 successfully disabled", arena_name))
end





----------------------------------------------
--------------GESTIONE PARTITA-----------------
----------------------------------------------

-- per tutti i giocatori quando finisce la coda
function arena_lib.load_arena(mod, arena_ID)

  local count = 1
  local mod_ref = arena_lib.mods[mod]
  local arena = mod_ref.arenas[arena_ID]

  arena.in_loading = true
  arena_lib.update_sign(arena.sign, arena)

  -- per ogni giocatore...
  for pl_name, _ in pairs(arena.players) do

    local player = minetest.get_player_by_name(pl_name)

    -- nascondo i nomi se l'opzione è abilitata
    if not mod_ref.show_nametags then
      player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
    end

    -- disattivo eventualmente la minimappa
    if not mod_ref.show_minimap then
      player:hud_set_flags({minimap = false})
    end

    -- li blocco sul posto
    player:set_physics_override({
              speed = 0,
              })

    -- teletrasporto i giocatori
    player:set_pos(arena.spawn_points[count])

    -- svuoto eventualmente l'inventario
    if not mod_ref.keep_inventory then
      player:get_inventory():set_list("main",{})
    end

    -- registro giocatori nella tabella apposita
    players_in_queue[pl_name] = nil
    players_in_game[pl_name] = {minigame = mod, arenaID = arena_ID}

    count = count +1
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_load then
    mod_ref.on_load(arena)
  end

  -- inizio l'arena dopo tot secondi
  minetest.after(mod_ref.load_time, function()
    arena_lib.start_arena(mod_ref, arena)
  end)

end



function arena_lib.start_arena(mod_ref, arena)

  arena.in_loading = false
  arena_lib.update_sign(arena.sign, arena)

  for pl_name, stats in pairs(arena.players) do

    minetest.get_player_by_name(pl_name):set_physics_override({
            speed = 1,
            jump = 1,
            gravity = 1,
            })
  end

  -- parte l'eventuale timer
  if mod_ref.timer ~= -1 then
    arena.timer_current = arena.timer
    minetest.after(1, function()
      timer_start(mod_ref, arena)
    end)
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_start then
    mod_ref.on_start(arena)
  end

end



-- per il player singolo a match iniziato
function arena_lib.join_arena(mod, p_name, arena_ID)

  local mod_ref = arena_lib.mods[mod]
  local player = minetest.get_player_by_name(p_name)
  local arena = mod_ref.arenas[arena_ID]

  -- nascondo i nomi se l'opzione è abilitata
  if not mod_ref.show_nametags then
    player:set_nametag_attributes({color = {a = 0, r = 255, g = 255, b = 255}})
  end

  -- disattivo eventualmente la minimappa
  if not mod_ref.show_minimap then
    player:hud_set_flags({minimap = false})
  end

  -- svuoto eventualmente l'inventario
  if not mod_ref.keep_inventory then
    player:get_inventory():set_list("main",{})
  end

  player:set_pos(arena_lib.get_random_spawner(arena))
  players_in_game[p_name] = {minigame = mod, arenaID = arena_ID}

  -- eventuale codice aggiuntivo
  if mod_ref.on_join then
    mod_ref.on_join(p_name, arena)
  end
end


--a partita finita
function arena_lib.load_celebration(mod, arena, winner_name)

  local mod_ref = arena_lib.mods[mod]

  arena.in_celebration = true
  arena_lib.update_sign(arena.sign, arena)

  for pl_name, stats in pairs(arena.players) do

    local inv = minetest.get_player_by_name(pl_name):get_inventory()

    -- giocatori immortali
    if not inv:contains_item("main", "arena_lib:immunity") then
      inv:set_stack("main", mod_ref.immunity_slot, "arena_lib:immunity")
    end

    minetest.get_player_by_name(pl_name):set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})
    minetest.chat_send_player(pl_name, mod_ref.prefix  .. S("@1 wins the game", winner_name))
  end

  -- eventuale codice aggiuntivo
  if mod_ref.on_celebration then
    mod_ref.on_celebration(arena, winner_name)
  end

  -- l'arena finisce dopo tot secondi
  minetest.after(mod_ref.celebration_time, function()
    arena_lib.end_arena(mod_ref, mod, arena)
  end)

end



function arena_lib.end_arena(mod_ref, mod, arena)

  -- copia da passare a on_end
  local players = {}

  for pl_name, stats in pairs(arena.players) do

    players[pl_name] = stats
    arena.players[pl_name] = nil
    players_in_game[pl_name] = nil
    arena.players_amount = 0
    arena.timer_current = nil

    local player = minetest.get_player_by_name(pl_name)

    -- svuoto eventualmente l'inventario
    if not mod_ref.keep_inventory then
      player:get_inventory():set_list("main", {})
    end

    -- teletrasporto nella lobby
    player:set_pos(mod_ref.hub_spawn_point)

    -- se ho hub_manager, restituisco gli oggetti
    if minetest.get_modpath("hub_manager") then
      hub_manager.set_items(player)
    end

    -- riattivo la minimappa eventualmente disattivata
    player:hud_set_flags({minimap = true})
  end

  -- resetto le proprietà temporanee
  for temp_property, v in pairs(mod_ref.temp_properties) do
    if type(v) == "string" then
      arena[temp_property] = ""
    elseif type(v) == "number" then
      arena[temp_property] = 0
    elseif type(v) == "boolean" then
      arena[temp_property] = false
    elseif type(v) == "table" then
      arena[temp_property] = {}
    end
  end

  local id = arena_lib.get_arena_by_name(mod, arena.name)

  -- eventuale codice aggiuntivo
  if mod_ref.on_end then
    mod_ref.on_end(arena, players)
  end

  arena.in_celebration = false
  arena.in_game = false

  -- aggiorno storage per le properties e cartello
  update_storage(false, mod, id, arena)
  arena_lib.update_sign(arena.sign, arena)

end



function arena_lib.add_to_queue(p_name, mod, arena_ID)
  players_in_queue[p_name] = {minigame = mod, arenaID = arena_ID}
end



function arena_lib.remove_from_queue(p_name)
  players_in_queue[p_name] = nil
end



----------------------------------------------
--------------------UTILS---------------------
----------------------------------------------

--TODO: rename_arena

-- (p_name, (mod))
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



function arena_lib.is_player_in_queue(p_name)

  if not players_in_queue[p_name] then
    return false
  else
    -- se il campo mod è specificato, controllo che sia lo stesso
    if mod ~= nil then
      if players_in_queue[p_name].minigame == mod then return true
      else return false
      end
    end

    return true

  end
end



function arena_lib.remove_player_from_arena(p_name, reason)
  -- reason 1 = has been eliminated
  -- reason 2 = has been kicked
  -- reason 3 = has quit the arena

  local mod, arena_ID

  -- se non è in partita né in coda, annullo
  if arena_lib.is_player_in_arena(p_name) then
    mod = players_in_game[p_name].minigame
    arena_ID = players_in_game[p_name].arenaID
  elseif arena_lib.is_player_in_queue(p_name) then
    mod = players_in_queue[p_name].minigame
    arena_ID = players_in_queue[p_name].arenaID
  else
    minetest.log("warning", "[ARENA_LIB] Can't remove player " .. p_name .. " from any arena")
    return end

  local mod_ref = arena_lib.mods[mod]
  local arena = mod_ref.arenas[arena_ID]

  if arena == nil then return end

  -- lo rimuovo
  arena.players[p_name] = nil
  players_in_game[p_name] = nil
  players_in_queue[p_name] = nil
  arena.players_amount = arena.players_amount - 1

  arena_lib.update_sign(arena.sign, arena)

  -- se una ragione è specificata
  if reason ~= nil then

    local player = minetest.get_player_by_name(p_name)

    -- svuoto eventualmente l'inventario
    if not mod_ref.keep_inventory then
      player:get_inventory():set_list("main",{})
    end

    -- lo teletrasporto fuori dall'arena e ripristino il nome
    player:set_pos(mod_ref.hub_spawn_point)
    player:set_nametag_attributes({color = {a = 255, r = 255, g = 255, b = 255}})

    -- se ho hub_manager, restituisco gli oggetti
    if minetest.get_modpath("hub_manager") then
      hub_manager.set_items(minetest.get_player_by_name(p_name))
    end

    -- resetto la minimappa eventualmente disattivata
    minetest.get_player_by_name(p_name):hud_set_flags({minimap = true})

    if reason == 1 then
      arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. S("@1 has been eliminated", p_name)))
      if mod_ref.on_eliminate then
        mod_ref.on_eliminate(arena, p_name)
      end
    elseif reason == 2 then
      arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. S("@1 has been kicked", p_name)))
      if mod_ref.on_kick then
        mod_ref.on_kick(arena, p_name)
      end
    elseif reason == 3 then
      arena_lib.send_message_players_in_arena(arena, minetest.colorize("#d69298", "<<< " .. S("@1 has quit the arena", p_name)))
      if mod_ref.on_quit then
        mod_ref.on_quit(arena, p_name)
      end
    end
  else
    --TODO: considerare se rimuovere questo avviso dato che il server avvisa di base i giocatori
    arena_lib.send_message_players_in_arena(arena, minetest.colorize("#f16a54", "<<< " .. p_name ))
  end

  -- se l'arena era in coda e ora ci son troppi pochi giocatori, annullo la coda
  if arena.in_queue then
    local timer = minetest.get_node_timer(arena.sign)

    if arena.players_amount < arena.min_players then
      timer:stop()
      arena.in_queue = false
      arena_lib.HUD_send_msg_all("hotbar", arena, arena.name .. " | " .. arena.players_amount .. "/" .. arena.max_players .. " | " ..
        S("Waiting for more players...") .. " (" .. arena.min_players - arena.players_amount .. ")")
      arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
    end

  -- se invece erano rimasti solo 2 giocatori in partita, l'altro vince
  elseif arena.players_amount == 1 then

    if is_eliminated then
      arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("You're the last player standing: you win!"))
    else
      arena_lib.send_message_players_in_arena(arena, mod_ref.prefix .. S("You win the game due to not enough players"))
    end

    for pl_name, stats in pairs(arena.players) do
      arena_lib.load_celebration(mod, arena, pl_name)
    end
  end

end



function arena_lib.send_message_players_in_arena(arena, msg)
  for pl_name, stats in pairs(arena.players) do
    minetest.chat_send_player(pl_name, msg) end
end



function arena_lib.immunity(player)

  local immunity_item = ItemStack("arena_lib:immunity")
  local inv = player:get_inventory()
  local p_name = player:get_player_name()
  local mod_ref = arena_lib.mods[arena_lib.get_mod_by_player(p_name)]

  inv:set_stack("main", mod_ref.immunity_slot, immunity_item)

  minetest.after(mod_ref.immunity_time, function()
    if player == nil then return end          -- they might have disconnected
    if inv:contains_item("main", immunity_item) then
      inv:remove_item("main", immunity_item)
    end
  end)

end



----------------------------------------------
-----------------GETTERS----------------------
----------------------------------------------

function arena_lib.get_arena_by_name(mod, arena_name)

  for id, arena in pairs(arena_lib.mods[mod].arenas) do
    if arena.name == arena_name then
      return id, arena end
  end
end



function arena_lib.get_players_in_game()
  return players_in_game
end



function arena_lib.get_mod_by_player(p_name)
  if arena_lib.is_player_in_arena(p_name) then
    return players_in_game[p_name].minigame
  else
    return players_in_queue[p_name].minigame
  end
end



function arena_lib.get_arena_by_player(p_name)

  local mod, arenaID

  if arena_lib.is_player_in_arena(p_name) then      -- è in partita
    mod = players_in_game[p_name].minigame
    arenaID = players_in_game[p_name].arenaID
  elseif arena_lib.is_player_in_queue(p_name) then   -- è in coda
    mod = players_in_queue[p_name].minigame
    arenaID = players_in_queue[p_name].arenaID
  else
    return end

  return arena_lib.mods[mod].arenas[arenaID]
end



function arena_lib.get_arenaID_by_player(p_name)
  if players_in_game[p_name] then
    return players_in_game[p_name].arenaID
  end
end



function arena_lib.get_queueID_by_player(p_name)
  if players_in_queue[p_name] then
    return players_in_queue[p_name].arenaID
  end
end



function arena_lib.get_arena_spawners_count(arena)
  return table.maxn(arena.spawn_points)
end



function arena_lib.get_random_spawner(arena)
  return arena.spawn_points[math.random(1,table.maxn(arena.spawn_points))]
end



function arena_lib.get_immunity_slot(mod)
  return arena_lib.mods[mod].immunity_slot
end


----------------------------------------------
-----------------SETTERS----------------------
----------------------------------------------

-- nothing to see here ¯\_(ツ)_/¯



----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------


function init_storage(mod, mod_ref)

  arena_lib.mods[mod] = mod_ref

  -- aggiungo le arene
  local i = 1
  for i = 1, arena_lib.mods[mod].arenasID do

    local arena_str = storage:get_string(mod .. "." .. i)

    -- se c'è una stringa con quell'ID, aggiungo l'arena e ne aggiorno l'eventuale cartello
    if arena_str ~= "" then
      local arena = minetest.deserialize(arena_str)

      --TEMP: to remove in 3.0
      arena.players_amount = 0

      -- controlli timer
      if mod_ref.timer == -1 and arena.timer then                   -- se avevo abilitato i timer e ora li ho rimossi, li tolgo dalle arene
        arena.timer = nil
      elseif mod_ref.timer ~= -1 and not arena.timer then           -- se li ho abilitati ora e le arene non ce li hanno, glieli aggiungo
        arena.timer = mod_ref.timer
      end

      arena_lib.mods[mod].arenas[i] = arena

      --signs_lib ha bisogno di un attimo per caricare sennò tira errore
      minetest.after(0.01, function()
        if arena.sign.x then                                        -- se non è ancora stato registrato nessun cartello per l'arena, evito il crash
          arena_lib.update_sign(arena.sign, arena)
        end
      end)
    else
      -- se un'arena è stata cancellata, è comunque rimasta in mod_ref (perché
      -- viene aggiornato solo all'avvio). Per ovviare a ciò, bisogna cancellarle
      -- all'avvio
      arena_lib.mods[mod].arenas[i] = nil
    end

  end
  minetest.log("action", "[ARENA_LIB] Mini-game " .. mod .. " loaded")
end



function update_storage(erase, mod, id, arena)

  -- ogni mod e ogni arena vengono salvate seguendo il formato mod.ID
  local entry = mod .."." .. id

  if erase then
    storage:set_string(entry, "")
  else
    storage:set_string(entry, minetest.serialize(arena))
  end
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
function next_ID(mod_ref)
  local n = 0
  for id, arena in pairs(mod_ref.arenas) do
    if id > n then n = id end
  end
  return n + 1
end



function timer_start(mod_ref, arena)

  if arena.on_celebration then return end

  if mod_ref.is_timer_incrementing then
    arena.timer_current = arena.timer_current + 1
  else
    arena.timer_current = arena.timer_current - 1
  end

  if arena.timer_current <= 0 then
    mod_ref.on_timeout(arena)
    return
  else
    mod_ref.on_timer_tick(arena)
  end

  minetest.after(1, function()
    timer_start(mod_ref, arena)
  end)
end




----------------------------------------------
------------------DEPRECATED------------------
----------------------------------------------

function arena_lib.initialize(mod)
    minetest.log("warning", "[ARENA_LIB] arena_lib.initialize is deprecated: you don't need it anymore")
end

function arena_lib.settings(mod, def)
  arena_lib.register_minigame(mod, def)
  minetest.log("warning", "[ARENA_LIB] arena_lib.settings is deprecated: rename it in arena_lib.register_minigame")
end

function arena_lib.get_arena_players_count(arena)
  minetest.log("warning", "[ARENA_LIB] arena_lib.get_arena_players_count is deprecated: use the arena parameter 'players_amount' instead (ie. arena.players_amount) to retrieve the value")
  return arena.players_amount
end

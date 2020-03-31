local function in_game_txt(arena) end


minetest.override_item("default:sign_wall", {

    on_punch = function(pos, node, puncher, pointed_thing)

      local arenaID = minetest.get_meta(pos):get_int("arenaID")
      if arenaID == 0 then return end

      local sign_arena = arena_lib.arenas[arenaID]
      local p_name = puncher:get_player_name()

      if not sign_arena then return end -- nel caso qualche cartello dovesse buggarsi, si può rompere e non fa crashare

      -- se è già in coda o viene fermato (cartello diverso) o si toglie dalla coda (cartello uguale)
      if arena_lib.is_player_in_queue(p_name) then

        local queued_ID = arena_lib.get_queueID_by_player(p_name)

        minetest.chat_send_player("singleplayer", "queued_ID = " .. queued_ID .. ", arenaID = " .. arenaID)

        if queued_ID ~= arenaID then
          minetest.chat_send_player(p_name, "[Quake]" .. minetest.colorize("#e6482e", "Devi prima uscire dalla coda di " .. arena_lib.arenas[queued_ID].name .. "!"))
        else

          sign_arena.players[p_name] = nil
          arena_lib.update_sign(pos, sign_arena)
          arena_lib.remove_from_queue(p_name)
          minetest.chat_send_player(p_name, "[Quake] Sei uscito dalla coda")
          arena_lib.send_message_players_in_arena(arenaID, "[Quake] " .. p_name .. " ha abbandonato la coda")

          -- se non ci sono più abbastanza giocatori, annullo la coda
          if arena_lib.get_arena_players_count(arenaID) < sign_arena.min_players and sign_arena.in_queue then
            --timer:stop()
            arena_lib.send_message_players_in_arena(arenaID, "[Quake] La coda è stata annullata per troppi pochi giocatori")
          end
        end
      return end

      -- se l'arena è piena
      if arena_lib.get_arena_players_count(arenaID) == sign_arena.max_players then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", "[!] L'arena è già piena!"))
        return end

      -- notifico i vari giocatori del nuovo player
      if sign_arena.in_game then
        --TODO: butta dentro alla partita in corso. Sì, si può entrare mentre è in corso -------- arena_lib.join_arena(arenaID)

        arena_lib.send_message_players_in_arena(arenaID, "[Quake] " .. p_name .. " si è aggiunto alla partita")
        minetest.chat_send_player(p_name, "[Quake] Sei entrato nell'arena " .. sign_arena.name)
      else
        arena_lib.send_message_players_in_arena(arenaID, "[Quake] " .. p_name .. " si è aggiunto alla coda")
        minetest.chat_send_player(p_name, "[Quake] Ti sei aggiunto alla coda per " .. sign_arena.name)
      end

      -- aggiungo il giocatore e aggiorno il cartello
      sign_arena.players[p_name] = {kills = 0, deaths = 0, killstreak = 0}
      arena_lib.add_to_queue(p_name, arenaID)
      arena_lib.update_storage()
      arena_lib.update_sign(pos, sign_arena)

      local timer = minetest.get_node_timer(pos)
      local waiting_time = 5

      -- se ci sono abbastanza giocatori, parte il timer di attesa
      if arena_lib.get_arena_players_count(arenaID) == sign_arena.min_players and not sign_arena.in_queue and not sign_arena.in_game then
        arena_lib.send_message_players_in_arena(arenaID, "[Quake] La partita inizierà tra " .. waiting_time .. " secondi!")
        sign_arena.in_queue = true
        timer:start(waiting_time)
      end

      -- se raggiungo i giocatori massimi e la partita non è iniziata, parte subito
      if arena_lib.get_arena_players_count(arenaID) == sign_arena.max_players and sign_arena.in_queue then
        timer:stop()
        timer:start(0.01)
      end

      --TODO: timer ciclico che avvisa i giocatori quanto tempo manca ogni N secondi

    end,

    -- quello che succede una volta che il timer raggiunge lo 0
    on_timer = function(pos)

      local arenaID = minetest.get_meta(pos):get_int("arenaID")
      local sign_arena = arena_lib.arenas[arenaID]

      sign_arena.in_queue = false
      sign_arena.in_game = true
      arena_lib.update_sign(pos, sign_arena)

      arena_lib.load_arena(arenaID)

      return false
    end,

})



--[[sovrascrizione "on_punch" nodo base dei cartelli per farli entrare
    nell'arena se sono cartelli appositi e "on_timer" per teletrasportali in partita quando la queue finisce]]
minetest.register_tool("arena_lib:create_sign", {

    description = "Left click on a sign to create an entrance or to remove it",
    inventory_image = "arena_createsign.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},

    on_use = function(itemstack, user, pointed_thing)

      local pos = minetest.get_pointed_thing_position(pointed_thing)
      if pos == nil then return end -- nel caso sia aria, sennò crasha

      local node = minetest.get_node(pos)
      local def = minetest.registered_items[node.name]

      --controllo se è un cartello
      if def and def.entity_info then
        def.number_of_lines = 5

        local arena_ID = itemstack:get_meta():get_int("arenaID")
        local arena = arena_lib.arenas[arena_ID]

        -- controllo se c'è già un cartello assegnato a quell'arena. Se è lo stesso lo rimuovo, sennò annullo
        if next(arena.sign) ~= nil then
          if minetest.serialize(pos) == minetest.serialize(arena.sign) then
            minetest.set_node(pos, {name = "air"})
            arena.sign = {}
            minetest.chat_send_player(user:get_player_name(), "Cartello dell'arena " .. arena.name .. " rimosso con successo")
          else
            minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", "[!] Esiste già un cartello per quest'arena!"))
          end
        return end

        -- cambio la scritta
        arena_lib.update_sign(pos, arena)

        -- aggiungo il cartello ai cartelli dell'arena
        arena.sign = pos

        -- salvo l'ID come metadato nel cartello
        minetest.get_meta(pos):set_int("arenaID", arena_ID)
      else
        minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", "[!] L'oggetto non è un cartello!"))
      end
    end,

})



function arena_lib.set_sign(sender, arena_name)

  local arena_ID, arena = arena_lib.get_arena_by_name(arena_name)

  if arena == nil then minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Quest'arena non esiste!"))
   return end

  if arena_lib.get_arena_spawners_count(arena_ID) < arena.max_players then minetest.chat_send_player(sender, minetest.colorize("#e6482e", "[!] Gli spawner devono essere quanto i giocatori massimi prima di impostare il cartello!"))
    return end

  -- assegno item creazione arene con ID arena nei metadati da restituire al premere sul cartello
  local stick = ItemStack("arena_lib:create_sign")
  local meta = stick:get_meta()
  meta:set_int("arenaID", arena_ID)

  minetest.get_player_by_name(sender):set_wielded_item(stick)
  minetest.chat_send_player(sender, "Click sinistro su un cartello per settare l'arena")
end



function arena_lib.update_sign(pos, arena)

  -- non uso il getter perché dovrei richiamare 2 funzioni (ID e count)
  local p_count = 0
  for pl, stats in pairs(arena.players) do
    p_count = p_count +1
  end

  signs_lib.update_sign(pos, {text = [[
   ]] .. "\n" .. [[
   ]] .. arena.name .. "\n" .. [[
   ]] .. p_count .. "/".. arena.max_players .. "\n" .. [[
   ]] .. in_game_txt(arena) .. "\n" .. [[

  ]]})
end



----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function in_game_txt(arena)
  local txt

  if arena.in_celebration then txt = "Concludendo"
  elseif arena.in_game then txt = "In partita"
  else txt = "In attesa" end

  return txt
end

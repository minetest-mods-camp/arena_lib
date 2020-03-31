minetest.override_item("default:sign_wall", {

    on_punch = function(pos, node, puncher, pointed_thing)

      local arenaID = minetest.get_meta(pos):get_int("arenaID")
      if arenaID == 0 then return end

      local sign_arena = arena_lib.arenas[arenaID]
      local p_name = puncher:get_player_name()

      if not sign_arena then return end -- nel caso qualche cartello dovesse buggarsi, si può rompere e non fa crashare

      -- se è già in coda o viene fermato (cartello diverso) o si toglie dalla coda (cartello uguale)
      if arena_lib.is_player_in_arena(p_name) then

        if arena_lib.get_arenaID_by_player(p_name) ~= arenaID then
          minetest.chat_send_player(p_name, "[Quake]" .. minetest.colorize("#e6482e", "Devi prima uscire dalla coda di " .. arena.name .. "!"))
        else

          sign_arena.players[p_name] = nil
          arena_lib.update_sign(pos, sign_arena)
          minetest.chat_send_player(p_name, "[Quake] Sei uscito dalla coda")
          arena_lib.send_message_players_in_arena(arenaID, "[Quake] " .. p_name .. " ha abbandonato la coda")

          -- se non ci sono più abbastanza giocatori, annullo la coda
          if arena_lib.get_arena_players_count(arenaID) < sign_arena.min_players and sign_arena.in_queue then
            timer:stop()
            arena.send_message_players_in_arena(arenaID, "[Quake] La coda è stata annullata per troppi pochi giocatori")
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

function arena_lib.update_storage()
  storage:set_string("arenas", minetest.serialize(arena_lib.arenas))
end



function arena_lib.update_sign(pos, arena)

  -- non uso il getter perché dovrei richiamare 2 funzioni (ID e count)
  local p_count = 0
  for pl, stats in pairs(arena.players) do
    p_count = p_count +1
  end

  signs_lib.update_sign(pos, {text = [[

   ]] .. arena.name .. [[
   ]] .. p_count .. "/".. arena.max_players .. [[
   ]] .. in_game_txt(arena) .. [[

  ]]})
end

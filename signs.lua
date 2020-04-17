--
-- For the item to set signs, being a declaration of a new item, look at items.lua
--
local S = minetest.get_translator("arena_lib")
local queue_waiting_time = 5

local function in_game_txt(arena) end



minetest.override_item("default:sign_wall", {

    on_punch = function(pos, node, puncher, pointed_thing)

      local arenaID = minetest.get_meta(pos):get_int("arenaID")
      if arenaID == 0 then return end

      local mod = minetest.get_meta(pos):get_string("mod")
      local mod_ref = arena_lib.mods[mod]
      local sign_arena = mod_ref.arenas[arenaID]
      local p_name = puncher:get_player_name()

      if not sign_arena then return end -- nel caso qualche cartello dovesse buggarsi, si può rompere e non fa crashare
      if not sign_arena.enabled then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
      return end

      -- cosa succede se è già in coda da qualche parte
      if arena_lib.is_player_in_queue(p_name) then

        local queued_mod = arena_lib.get_mod_by_player(p_name)

        -- se è in coda in un altro minigioco, annullo
        if queued_mod ~= mod then
          minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You're already queueing for minigame @1!", queued_mod)))
        return end

        local queued_ID = arena_lib.get_queueID_by_player(p_name)

        -- se è in coda per lo stesso minigioco ma arena diversa, annullo
        if queued_ID ~= arenaID then
          minetest.chat_send_player(p_name, mod_ref.prefix .. minetest.colorize("#e6482e", S("You need to leave the queue of @1 first!", mod_ref.arenas[queued_ID].name)))
        return end

        -- sennò la coda era la stessa e rimuovo il giocatore
        sign_arena.players[p_name] = nil
        arena_lib.update_sign(pos, sign_arena)
        arena_lib.remove_from_queue(p_name)
        minetest.chat_send_player(p_name, mod_ref.prefix .. S("You have left the queue"))
        arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("@1 has left the queue", p_name))

        -- se non ci sono più abbastanza giocatori, annullo la coda
        if arena_lib.get_arena_players_count(sign_arena) < sign_arena.min_players and sign_arena.in_queue then
          minetest.get_node_timer(pos):stop()
          arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
          sign_arena.in_queue = false
        end
      return end

      -- se l'arena è piena
      if arena_lib.get_arena_players_count(sign_arena) == sign_arena.max_players then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is already full!")))
        return end

      -- se sta caricando
      if sign_arena.in_loading then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is loading, try again in a few seconds!")))
        return end

      -- aggiungo il giocatore e aggiorno il cartello
      sign_arena.players[p_name] = {kills = 0, deaths = 0, killstreak = 0}
      arena_lib.update_sign(pos, sign_arena)

      -- notifico i vari giocatori del nuovo player
      if sign_arena.in_game then
        arena_lib.join_arena(mod, p_name, arenaID)
        arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("@1 has joined the game", p_name))
        minetest.chat_send_player(p_name, mod_ref.prefix .. S("You've entered the arena @1", sign_arena.name))
        return
      else
        arena_lib.add_to_queue(p_name, mod, arenaID)
        arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("@1 has joined the queue", p_name))
        minetest.chat_send_player(p_name, mod_ref.prefix .. S("You've joined the queue for @1", sign_arena.name))
      end

      local timer = minetest.get_node_timer(pos)

      -- se ci sono abbastanza giocatori, parte il timer di attesa
      if arena_lib.get_arena_players_count(sign_arena) == sign_arena.min_players and not sign_arena.in_queue and not sign_arena.in_game then
        arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("The game begins in @1 seconds!", queue_waiting_time))
        sign_arena.in_queue = true
        timer:start(queue_waiting_time)
      end

      -- se raggiungo i giocatori massimi e la partita non è iniziata, parte subito
      if arena_lib.get_arena_players_count(sign_arena) == sign_arena.max_players and sign_arena.in_queue then
        timer:stop()
        timer:start(0.01)
      end

      --TODO: timer ciclico che avvisa i giocatori quanto tempo manca ogni N secondi

    end,

    -- quello che succede una volta che il timer raggiunge lo 0
    on_timer = function(pos)

      local mod = minetest.get_meta(pos):get_string("mod")
      local arena_ID = minetest.get_meta(pos):get_int("arenaID")
      local sign_arena = arena_lib.mods[mod].arenas[arena_ID]

      sign_arena.in_queue = false
      sign_arena.in_game = true
      arena_lib.update_sign(pos, sign_arena)

      arena_lib.load_arena(mod, arena_ID)

      return false
    end,

})



function arena_lib.set_sign(sender, mod, arena_name)


  local arena_ID, arena = arena_lib.get_arena_by_name(mod, arena_name)

  if arena == nil then minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
   return end

  -- assegno item creazione arene con nome mod e ID arena nei metadati da restituire al premere sul cartello.
  -- uso l'ID e non il nome perché (in futuro) si potrà rinominare un'arena
  local stick = ItemStack("arena_lib:create_sign")
  local meta = stick:get_meta()
  meta:set_string("mod", mod)
  meta:set_int("arenaID", arena_ID)

  minetest.get_player_by_name(sender):set_wielded_item(stick)
  minetest.chat_send_player(sender, S("Left click on a sign to set the arena"))
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

  --[[if not arena.enabled then txt = S("WIP")
  elseif arena.in_celebration then txt = S("Terminating")
  elseif arena.in_game then txt = S("Ongoing")
  elseif arena.in_loading then txt = S("Loading")
  else txt = S("Waiting") end]]

  if not arena.enabled then txt = "WIP"
  elseif arena.in_celebration then txt = "Terminating"
  elseif arena.in_game then txt = "Ongoing"
  elseif arena.in_loading then txt = "Loading"
  else txt = "Waiting" end

  return txt
end

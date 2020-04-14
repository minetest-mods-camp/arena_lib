--
-- For the item to set signs, being a declaration of a new item, look at items.lua
--

local queue_waiting_time = 5
local prefix

minetest.after(0.01, function()
  prefix = arena_lib.get_prefix()
end)

local function in_game_txt(arena) end



minetest.override_item("default:sign_wall", {

    on_punch = function(pos, node, puncher, pointed_thing)

      local arenaID = minetest.get_meta(pos):get_int("arenaID")
      if arenaID == 0 then return end

      local sign_arena = arena_lib.arenas[arenaID]
      local p_name = puncher:get_player_name()

      if not sign_arena then return end -- nel caso qualche cartello dovesse buggarsi, si può rompere e non fa crashare
      if not sign_arena.enabled then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", "[!] L'arena non è attiva!"))
      return end

      -- se è già in coda o viene fermato (cartello diverso) o si toglie dalla coda (cartello uguale)
      if arena_lib.is_player_in_queue(p_name) then

        local queued_ID = arena_lib.get_queueID_by_player(p_name)

        if queued_ID ~= arenaID then
          minetest.chat_send_player(p_name, prefix .. minetest.colorize("#e6482e", "Devi prima uscire dalla coda di " .. arena_lib.arenas[queued_ID].name .. "!"))
        else

          sign_arena.players[p_name] = nil
          arena_lib.update_sign(pos, sign_arena)
          arena_lib.remove_from_queue(p_name)
          minetest.chat_send_player(p_name, prefix .. "Sei uscito dalla coda")
          arena_lib.send_message_players_in_arena(sign_arena, prefix .. p_name .. " ha abbandonato la coda")

          -- se non ci sono più abbastanza giocatori, annullo la coda
          if arena_lib.get_arena_players_count(sign_arena) < sign_arena.min_players and sign_arena.in_queue then
            minetest.get_node_timer(pos):stop()
            arena_lib.send_message_players_in_arena(sign_arena, prefix .. "La coda è stata annullata per troppi pochi giocatori")
            arena.in_queue = false
          end
        end
      return end

      -- se l'arena è piena
      if arena_lib.get_arena_players_count(sign_arena) == sign_arena.max_players then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", "[!] L'arena è già piena!"))
        return end

      -- se sta caricando
      if sign_arena.in_loading then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", "[!] L'arena è in caricamento, riprova tra qualche secondo!"))
        return end

      -- aggiungo il giocatore e aggiorno il cartello
      sign_arena.players[p_name] = {kills = 0, deaths = 0, killstreak = 0}
      arena_lib.update_sign(pos, sign_arena)

      -- notifico i vari giocatori del nuovo player
      if sign_arena.in_game then
        arena_lib.join_arena(p_name, arenaID)
        arena_lib.send_message_players_in_arena(sign_arena, prefix .. p_name .. " si è aggiunto alla partita")
        minetest.chat_send_player(p_name, prefix .. "Sei entrato nell'arena " .. sign_arena.name)
        return
      else
        arena_lib.add_to_queue(p_name, arenaID)
        arena_lib.send_message_players_in_arena(sign_arena, prefix .. p_name .. " si è aggiunto alla coda")
        minetest.chat_send_player(p_name, prefix .. "Ti sei aggiunto alla coda per " .. sign_arena.name)
      end

      local timer = minetest.get_node_timer(pos)

      -- se ci sono abbastanza giocatori, parte il timer di attesa
      if arena_lib.get_arena_players_count(sign_arena) == sign_arena.min_players and not sign_arena.in_queue and not sign_arena.in_game then
        arena_lib.send_message_players_in_arena(sign_arena, prefix .. "La partita inizierà tra " .. queue_waiting_time .. " secondi!")
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

  -- assegno item creazione arene con ID arena nei metadati da restituire al premere sul cartello
  local stick = ItemStack(arena_lib.mod_name .. ":create_sign")
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

  if not arena.enabled then txt = "LAVORI IN CORSO"
  elseif arena.in_celebration then txt = "Concludendo"
  elseif arena.in_game then txt = "In partita"
  elseif arena.in_loading then txt = "In caricamento"
  else txt = "In attesa" end

  return txt
end

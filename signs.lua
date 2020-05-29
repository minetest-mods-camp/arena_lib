--
-- For the item to set signs, being a declaration of a new item, look at items.lua
--
local S = minetest.get_translator("arena_lib")

local function in_game_txt(arena) end
local function HUD_countdown(arena, seconds) end
local function arena_display_format(arena, msg) end



minetest.override_item("default:sign_wall", {

    on_punch = function(pos, node, puncher, pointed_thing)

      local arenaID = minetest.get_meta(pos):get_int("arenaID")
      if arenaID == 0 then return end

      local mod = minetest.get_meta(pos):get_string("mod")
      local mod_ref = arena_lib.mods[mod]
      local sign_arena = mod_ref.arenas[arenaID]
      local p_name = puncher:get_player_name()

      if not sign_arena then return end -- nel caso qualche cartello dovesse buggarsi, si può rompere e non fa crashare

      -- se non è abilitata
      if not sign_arena.enabled then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
        return end

      -- se l'arena è piena
      if sign_arena.players_amount == sign_arena.max_players and arena_lib.get_queueID_by_player(p_name) ~= arenaID then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is already full!")))
        return end

      -- se sta caricando o sta finendo
      if sign_arena.in_loading or sign_arena.in_celebration then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is loading, try again in a few seconds!")))
        return end

      -- se è in corso e non permette l'entrata
      if sign_arena.in_game and mod_ref.join_while_in_progress == false then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] This minigame doesn't allow to join while in progress!")))
        return end

      -- se è già in coda
      if arena_lib.is_player_in_queue(p_name) then

        local queued_mod = arena_lib.get_mod_by_player(p_name)
        local queued_ID = arena_lib.get_queueID_by_player(p_name)

        -- se la coda è la stessa rimuovo il giocatore...
        if queued_mod == mod and queued_ID == arenaID then
          arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#d69298", sign_arena.name .. " < " .. p_name))
          sign_arena.players[p_name] = nil
          sign_arena.players_amount = sign_arena.players_amount - 1
          arena_lib.update_sign(pos, sign_arena)
          arena_lib.remove_from_queue(p_name)
          arena_lib.HUD_hide("all", p_name)

          local players_in_arena = sign_arena.players_amount

          -- ...e annullo la coda se non ci sono più abbastanza persone
          if players_in_arena < sign_arena.min_players and sign_arena.in_queue then
            minetest.get_node_timer(pos):stop()
            arena_lib.HUD_hide("broadcast", sign_arena)
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("Waiting for more players...")) ..
              " (" .. sign_arena.min_players - players_in_arena .. ")")
            arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
            sign_arena.in_queue = false

          -- (se la situazione è rimasta invariata, devo comunque aggiornare il numero giocatori nella hotbar)
          elseif players_in_arena < sign_arena.min_players then
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("Waiting for more players...")) ..
              " (" .. sign_arena.min_players - players_in_arena .. ")")
          else
            local seconds = math.floor(minetest.get_node_timer(pos):get_timeout() + 0.5)
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("@1 seconds for the match to start", seconds)))
          end

          return

        else

          local old_mod_ref = arena_lib.mods[queued_mod]
          local old_arena = old_mod_ref.arenas[queued_ID]

          -- sennò lo rimuovo dalla precedente e continuo per aggiungerlo in questa...
          old_arena.players[p_name] = nil
          old_arena.players_amount = old_arena.players_amount -1
          arena_lib.remove_from_queue(p_name)
          arena_lib.update_sign(old_arena.sign, old_arena)
          arena_lib.send_message_players_in_arena(old_arena, minetest.colorize("#d69298", sign_arena.name .. " < " .. p_name))

          local players_in_arena = old_arena.players_amount

          -- ...annullando la coda della precedente se non ci sono più abbastanza giocatori
          if players_in_arena < old_arena.min_players and old_arena.in_queue then
            minetest.get_node_timer(old_arena.sign):stop()
            arena_lib.HUD_hide("broadcast", old_arena)
            arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, S("Waiting for more players...")) ..
              " (" .. old_arena.min_players - players_in_arena .. ")")
            arena_lib.send_message_players_in_arena(old_arena, old_mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
            old_arena.in_queue = false

          -- (se la situazione è rimasta invariata, devo comunque aggiornare il numero giocatori nella hotbar)
          elseif players_in_arena < old_arena.min_players and not old_arena.in_queue then
            arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, S("Waiting for more players...")) ..
              " (" .. old_arena.min_players - players_in_arena .. ")")
          else
            local seconds = math.floor(minetest.get_node_timer(pos):get_timeout() + 0.5)
            arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, S("@1 seconds for the match to start", seconds)))
          end

        end
      end

      -- aggiungo il giocatore ed eventuali proprietà
      sign_arena.players[p_name] = {kills = 0, deaths = 0}
      sign_arena.players_amount = sign_arena.players_amount +1

      for k, v in pairs(mod_ref.player_properties) do
        sign_arena.players[p_name][k] = v
      end

      -- aggiorno il cartello
      arena_lib.update_sign(pos, sign_arena)

      -- notifico i vari giocatori del nuovo player
      if sign_arena.in_game then
        arena_lib.join_arena(mod, p_name, arenaID)
        arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#c6f154", " >>> " .. p_name))
        return
      else
        arena_lib.add_to_queue(p_name, mod, arenaID)
        arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#c8d692", sign_arena.name .. " > " ..  p_name))
      end

      local timer = minetest.get_node_timer(pos)
      local players_in_arena = sign_arena.players_amount

      -- se ci sono abbastanza giocatori e la coda non è partita...
      if not sign_arena.in_queue and not sign_arena.in_game then

        -- ...parte il timer d'attesa
        if players_in_arena == sign_arena.min_players then
          sign_arena.in_queue = true
          timer:start(mod_ref.queue_waiting_time)
          HUD_countdown(sign_arena, timer)

        -- sennò aggiorno semplicemente la HUD
        elseif players_in_arena < sign_arena.min_players then
          arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("Waiting for more players...")) ..
            " (" .. sign_arena.min_players - players_in_arena .. ")")
        end
      end


      -- se raggiungo i giocatori massimi e la partita non è iniziata, accorcio eventualmente la durata
      if players_in_arena == sign_arena.max_players and sign_arena.in_queue then
        if timer:get_timeout() - timer:get_elapsed() > 5 then
          timer:stop()
          timer:start(5)
        end
      end

    end,


    -- quello che succede una volta che il timer raggiunge lo 0
    on_timer = function(pos)

      local mod = minetest.get_meta(pos):get_string("mod")
      local arena_ID = minetest.get_meta(pos):get_int("arenaID")
      local sign_arena = arena_lib.mods[mod].arenas[arena_ID]

      sign_arena.in_queue = false
      sign_arena.in_game = true
      arena_lib.update_sign(pos, sign_arena)

      arena_lib.HUD_hide("all", sign_arena)
      arena_lib.load_arena(mod, arena_ID)

      return false
    end,

})



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

function HUD_countdown(arena, timer)

  if not arena.in_queue or not timer:is_started() then return end

  local seconds = math.floor(timer:get_timeout() - timer:get_elapsed() + 0.5)

  -- dai 5 secondi in giù il messaggio è stampato su broadcast
  if seconds <= 5 then
    arena_lib.HUD_send_msg_all("broadcast", arena, S("The game begins in @1 seconds!", seconds), nil, "arenalib_countdown")
    arena_lib.HUD_send_msg_all("hotbar", arena, arena_display_format(arena, S("Get ready!")))
  else
    arena_lib.HUD_send_msg_all("hotbar", arena, arena_display_format(arena, S("@1 seconds for the match to start", seconds)))
  end

  minetest.after(1, function()
    HUD_countdown(arena, timer)
  end)
end


-- es. Foresta | 3/4 | Il match inizierà a breve
function arena_display_format(arena, msg)
  return arena.name .. " | " .. arena.players_amount .. "/" .. arena.max_players .. " | " .. msg
end



function in_game_txt(arena)
  local txt

  --[[if not arena.enabled then txt = S("WIP")
  elseif arena.in_celebration then txt = S("Terminating")
  elseif arena.in_game then txt = S("Ongoing")
  elseif arena.in_loading then txt = S("Loading")
  else txt = S("Waiting") end]]

  if not arena.enabled then txt = "WIP"
  elseif arena.in_celebration then txt = "Terminating"
  elseif arena.in_loading then txt = "Loading"
  elseif arena.in_game then txt = "In progress"

  else txt = "Waiting" end

  return txt
end

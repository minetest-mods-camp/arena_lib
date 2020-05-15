--
-- For the item to set signs, being a declaration of a new item, look at items.lua
--
local S = minetest.get_translator("arena_lib")

local function in_game_txt(arena) end
local function HUD_countdown(arena, seconds) end
local function arena_display_format(arena, players_in_arena, msg) end



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
      if arena_lib.get_arena_players_count(sign_arena) == sign_arena.max_players then
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
          arena_lib.update_sign(pos, sign_arena)
          arena_lib.remove_from_queue(p_name)
          arena_lib.HUD_hide("all", p_name)
          
          local players_in_arena = arena_lib.get_arena_players_count(sign_arena)
          
          -- ...e la annullo se non ci sono più abbastanza persone
          if players_in_arena < sign_arena.min_players and sign_arena.in_queue then
            minetest.get_node_timer(pos):stop()
            arena_lib.HUD_hide("broadcast", sign_arena)
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, players_in_arena, S("Waiting for more players...")) .. 
              " (" .. sign_arena.min_players - players_in_arena .. ")")
            arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
            sign_arena.in_queue = false
          else
            -- (il numero giocatori è cambiato, per questo aggiorno)
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, players_in_arena, S("Get ready!")))
          end
          
          return 
        end
        
        local old_mod_ref = arena_lib.mods[queued_mod]
        local old_arena = old_mod_ref.arenas[queued_ID]
        
        -- sennò lo rimuovo dalla precedente e continuo per aggiungerlo in questa
        old_arena.players[p_name] = nil
        arena_lib.remove_from_queue(p_name)
        arena_lib.update_sign(old_arena.sign, old_arena)
        arena_lib.send_message_players_in_arena(old_arena, minetest.colorize("#d69298", sign_arena.name .. " < " .. p_name))
        
        local players_in_arena = arena_lib.get_arena_players_count(old_arena)
        
        -- annullando la coda della precedente se non ci sono più abbastanza giocatori
        if players_in_arena < old_arena.min_players and old_arena.in_queue then
          minetest.get_node_timer(old_arena.sign):stop()
          arena_lib.HUD_hide("broadcast", old_arena)
          arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, players_in_arena, S("Waiting for more players...")) .. 
            " (" .. old_arena.min_players - players_in_arena .. ")")
          arena_lib.send_message_players_in_arena(old_arena, old_mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
          old_arena.in_queue = false
        end
      end

      -- aggiungo il giocatore ed eventuali proprietà
      sign_arena.players[p_name] = {kills = 0, deaths = 0}
      
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

      -- se ci sono abbastanza giocatori, parte il timer di attesa
      if not sign_arena.in_queue and not sign_arena.in_game then
        
        local players_in_arena = arena_lib.get_arena_players_count(sign_arena)
        
        if players_in_arena == sign_arena.min_players then
          sign_arena.in_queue = true
          timer:start(mod_ref.queue_waiting_time)
          HUD_countdown(sign_arena, players_in_arena, mod_ref.queue_waiting_time)
        elseif players_in_arena < sign_arena.min_players then
          arena_lib.HUD_send_msg("hotbar", p_name, arena_display_format(sign_arena, players_in_arena, S("Waiting for more players...")) .. 
            " (" .. sign_arena.min_players - players_in_arena .. ")")
        end
      end
        

      -- se raggiungo i giocatori massimi e la partita non è iniziata, parte subito
      if players_in_arena == sign_arena.max_players and sign_arena.in_queue then
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

      arena_lib.HUD_hide("all", sign_arena)
      arena_lib.load_arena(mod, arena_ID)

      return false
    end,

})



function arena_lib.give_sign_tool(sender, mod, arena_name)


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

function HUD_countdown(arena, players_in_arena, seconds)
  if not arena.in_queue or seconds == 0 then return end
  
  -- dai 3 secondi in giù il messaggio è stampato su broadcast
  if seconds <= 3 then
    arena_lib.HUD_send_msg_all("broadcast", arena, S("The game begins in @1 seconds!", seconds), nil, "arenalib_countdown")
    arena_lib.HUD_send_msg_all("hotbar", arena, arena_display_format(arena, players_in_arena, S("Get ready!")))
  else
    arena_lib.HUD_send_msg_all("hotbar", arena, arena_display_format(arena, players_in_arena, S("@1 seconds for the match to start", seconds)))
  end
  
  minetest.after(1, function()
    HUD_countdown(arena, players_in_arena, seconds-1)
  end)
end


-- es. Foresta | 3/4 | Il match inizierà a breve
function arena_display_format(arena, players_in_arena, msg)
  return arena.name .. " | " .. players_in_arena .. "/" .. arena.max_players .. " | " .. msg
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

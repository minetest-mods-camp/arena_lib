local S = minetest.get_translator("arena_lib")

local function get_players_required() end
local function assign_team() end
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

      if not sign_arena then return end -- nel caso qualche cartello dovesse buggarsi, si può rompere senza far crashare

      -- se si è nell'editor
      if arena_lib.is_player_in_edit_mode(p_name) then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must leave the editor first!")))
        return end

      -- se c'è parties e si è in gruppo...
      if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) and arena_lib.get_queueID_by_player(p_name) ~= arenaID then

        -- se non si è il capo gruppo
        if parties.get_party_leader(p_name) ~= p_name then
          minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Only the party leader can enter the queue!")))
          return end

        local party_members_amount = #parties.get_party_members(p_name)

        --se non c'è spazio (no team)
        if not sign_arena.teams_enabled then
          if party_members_amount > sign_arena.max_players - sign_arena.players_amount then
            minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is no enough space for the whole party!")))
            return end
        -- se non c'è spazio (team)
        else

          local free_space = false
          for _, amount in pairs(sign_arena.players_amount_per_team) do
            if party_members_amount <= sign_arena.max_players - amount then
              free_space = true
              break
            end
          end

          if not free_space then
            minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is no team with enough space for the whole party!")))
            return end
        end
      end

      -- se non è abilitata
      if not sign_arena.enabled then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
        return end

      -- se l'arena è piena
      if sign_arena.players_amount == sign_arena.max_players * #sign_arena.teams and arena_lib.get_queueID_by_player(p_name) ~= arenaID then
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

          local p_team_ID = sign_arena.players[p_name].teamID

          -- se è un party, rimuovo tutto il gruppo
          if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then

            local party_members = parties.get_party_members(p_name)

            sign_arena.players_amount = sign_arena.players_amount - #party_members
            if sign_arena.teams_enabled then
              sign_arena.players_amount_per_team[p_team_ID] = sign_arena.players_amount_per_team[p_team_ID] - #party_members
            end

            for _, pl_name in pairs(party_members) do
              arena_lib.HUD_hide("all", pl_name)
              arena_lib.remove_from_queue(pl_name)
              arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#d69298", sign_arena.name .. " < " .. pl_name))
              sign_arena.players[pl_name] = nil
            end

          -- sennò rimuovo il singolo utente
          else
            sign_arena.players_amount = sign_arena.players_amount - 1
            if sign_arena.teams_enabled then
              sign_arena.players_amount_per_team[p_team_ID] = sign_arena.players_amount_per_team[p_team_ID] -1
            end

            arena_lib.HUD_hide("all", p_name)
            arena_lib.remove_from_queue(p_name)
            arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#d69298", sign_arena.name .. " < " .. p_name))
            sign_arena.players[p_name] = nil
          end

          local players_required = get_players_required(sign_arena)

          -- ...e annullo la coda se non ci sono più abbastanza persone
          if players_required > 0 and sign_arena.in_queue then
            minetest.get_node_timer(pos):stop()
            arena_lib.HUD_hide("broadcast", sign_arena)
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("Waiting for more players...")) ..
              " (" .. players_required .. ")")
            arena_lib.send_message_players_in_arena(sign_arena, mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
            sign_arena.in_queue = false

          -- (se la situazione è rimasta invariata, devo comunque aggiornare il numero giocatori nella hotbar)
          elseif players_required > 0 then
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("Waiting for more players...")) ..
              " (" .. players_required .. ")")
          else
            local seconds = math.floor(minetest.get_node_timer(pos):get_timeout() + 0.5)
            arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("@1 seconds for the match to start", seconds)))
          end

          arena_lib.update_sign(sign_arena)
          return

        else

          local old_mod_ref = arena_lib.mods[queued_mod]
          local old_arena = old_mod_ref.arenas[queued_ID]
          local old_p_team_ID = old_arena.players[p_name].teamID

          -- sennò lo rimuovo dalla precedente e continuo per aggiungerlo in questa...
          -- se è un party
          if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then

            local party_members = parties.get_party_members(p_name)

            old_arena.players_amount = old_arena.players_amount - #party_members
            if old_arena.teams_enabled then
              old_arena.players_amount_per_team[old_p_team_ID] = old_arena.players_amount_per_team[old_p_team_ID] - #party_members
            end

            for _, pl_name in pairs(party_members) do
              arena_lib.HUD_hide("broadcast", pl_name)
              arena_lib.remove_from_queue(pl_name)
              arena_lib.send_message_players_in_arena(old_arena, minetest.colorize("#d69298", old_arena.name .. " < " .. pl_name))
              old_arena.players[pl_name] = nil
            end
          -- sennò è singolo utente
          else
            old_arena.players_amount = old_arena.players_amount -1
            if #old_arena.teams > 1 then
              old_arena.players_amount_per_team[old_p_team_ID] = old_arena.players_amount_per_team[old_p_team_ID] -1
            end

            arena_lib.HUD_hide("broadcast", p_name)
            arena_lib.remove_from_queue(p_name)
            arena_lib.send_message_players_in_arena(old_arena, minetest.colorize("#d69298", old_arena.name .. " < " .. p_name))
            old_arena.players[p_name] = nil
          end

          local players_required = get_players_required(old_arena)

          -- ...annullando la coda della precedente se non ci sono più abbastanza giocatori
          if players_required > 0 and old_arena.in_queue then
            minetest.get_node_timer(old_arena.sign):stop()
            arena_lib.HUD_hide("broadcast", old_arena)
            arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, S("Waiting for more players...")) ..
              " (" .. players_required .. ")")
            arena_lib.send_message_players_in_arena(old_arena, old_mod_ref.prefix .. S("The queue has been cancelled due to not enough players"))
            old_arena.in_queue = false

          -- (se la situazione è rimasta invariata, devo comunque aggiornare il numero giocatori nella hotbar)
          elseif players_required > 0 then
            arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, S("Waiting for more players...")) ..
              " (" .. players_required .. ")")
          else
            local seconds = math.floor(minetest.get_node_timer(pos):get_timeout() + 0.5)
            arena_lib.HUD_send_msg_all("hotbar", old_arena, arena_display_format(old_arena, S("@1 seconds for the match to start", seconds)))
          end

          arena_lib.update_sign(old_arena)

        end
      end

      local p_team_ID

      -- determino eventuale team giocatore
      if sign_arena.teams_enabled then
        p_team_ID = assign_team(mod_ref, sign_arena, p_name)
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

      -- aggiungo il giocatore ed eventuali proprietà
      for _, pl_name in pairs(players_to_add) do
        sign_arena.players[pl_name] = {kills = 0, deaths = 0, teamID = p_team_ID}

        for k, v in pairs(mod_ref.player_properties) do
          sign_arena.players[pl_name][k] = v
        end
      end

      -- aumento il conteggio di giocatori in partita
      sign_arena.players_amount = sign_arena.players_amount + #players_to_add
      if sign_arena.teams_enabled then
        sign_arena.players_amount_per_team[p_team_ID] = sign_arena.players_amount_per_team[p_team_ID] + #players_to_add
      end

      -- notifico i vari giocatori del nuovo player
      for _, pl_name in pairs(players_to_add) do
        if sign_arena.in_game then
          arena_lib.join_arena(mod, pl_name, arenaID)
          arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#c6f154", " >>> " .. pl_name))
          return
        else
          arena_lib.add_to_queue(pl_name, mod, arenaID)
          arena_lib.send_message_players_in_arena(sign_arena, minetest.colorize("#c8d692", sign_arena.name .. " > " ..  pl_name))
        end
      end

      local timer = minetest.get_node_timer(pos)
      local arena_max_players = sign_arena.max_players * #sign_arena.teams

      -- se la coda non è partita...
      if not sign_arena.in_queue and not sign_arena.in_game then

        local players_required = get_players_required(sign_arena)

        -- ...e ci sono abbastanza giocatori, parte il timer d'attesa
        if players_required <= 0 then
          sign_arena.in_queue = true
          timer:start(mod_ref.queue_waiting_time)
          HUD_countdown(sign_arena, timer)

        -- sennò aggiorno semplicemente la HUD
        else
          arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_display_format(sign_arena, S("Waiting for more players...")) ..
            " (" .. players_required .. ")")
        end
      end

      arena_lib.update_sign(sign_arena)

      -- se raggiungo i giocatori massimi e la partita non è iniziata, accorcio eventualmente la durata
      if sign_arena.players_amount == arena_max_players and sign_arena.in_queue then
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
      arena_lib.update_sign(sign_arena)

      arena_lib.HUD_hide("all", sign_arena)
      arena_lib.load_arena(mod, arena_ID)

      return false
    end,

})



function arena_lib.update_sign(arena)

  local p_count = 0
  local t_count = #arena.teams

  -- non uso il getter perché dovrei richiamare 2 funzioni (ID e count)
  for pl, stats in pairs(arena.players) do
    p_count = p_count +1
  end

  signs_lib.update_sign(arena.sign, {text = [[
   ]] .. "\n" .. [[
   ]] .. arena.name .. "\n" .. [[
   ]] .. p_count .. "/".. arena.max_players * t_count .. "\n" .. [[
   ]] .. in_game_txt(arena) .. "\n" .. [[

  ]]})
end




----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_players_required(arena)

  local players_in_arena = arena.players_amount
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
    players_required = arena_min_players - players_in_arena
  end

  return players_required
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



function HUD_countdown(arena, timer)

  if not arena.in_queue or not timer:is_started() then return end

  local seconds = math.floor(timer:get_timeout() - timer:get_elapsed() + 0.51)

  -- dai 5 secondi in giù il messaggio è stampato su broadcast e genero i team
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
  local arena_max_players = arena.max_players * #arena.teams
  return arena.name .. " | " .. arena.players_amount .. "/" .. arena_max_players  .. " | " .. msg
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
  elseif arena.in_queue then txt = "Queueing"
  elseif arena.in_game then txt = "In progress"

  else txt = "Waiting" end

  return txt
end

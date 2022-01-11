local S = minetest.get_translator("arena_lib")
local FS = minetest.formspec_escape

local function assign_team() end
local function in_game_txt(arena) end
local function HUD_countdown(arena, seconds) end
local function get_infobox_formspec() end



signs_lib.register_sign("arena_lib:sign", {
	description = S("Arena sign"),
  tiles = {
    { name = "arenalib_sign.png", backface_culling = true},
		"arenalib_sign_edge.png"
  },
	inventory_image = "arenalib_sign_icon.png",
	default_color = "8",
	entity_info = "standard",
	sounds = default.node_sound_wood_defaults(),
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	allow_widefont = true,
	chars_per_line = 40,
	horiz_scaling = 0.95,
	vert_scaling = 1.38,
	number_of_lines = 5,

	-- forza widefont
	on_construct = function(pos)
		minetest.get_meta(pos):set_int("widefont", 1)
	end,

	-- cartello indistruttibile se c'è un'arena assegnata
	on_dig = function(pos, node, digger)
		if minetest.get_meta(pos):get_int("arenaID") ~= 0 then return end

		minetest.node_dig(pos,node,digger)
  end,

	-- click dx apre la finestra d'informazioni
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if minetest.get_meta(pos):get_int("arenaID") == 0 then return end

		local mod = minetest.get_meta(pos):get_string("mod")
		local arenaID = minetest.get_meta(pos):get_int("arenaID")

		minetest.show_formspec(clicker:get_player_name(), "arena_lib:infobox", get_infobox_formspec(mod, arenaID, clicker))
	end,


  on_punch = function(pos, node, puncher, pointed_thing)

    local arenaID = minetest.get_meta(pos):get_int("arenaID")
    if arenaID == 0 then return end

    local mod = minetest.get_meta(pos):get_string("mod")
    local mod_ref = arena_lib.mods[mod]
    local sign_arena = mod_ref.arenas[arenaID]
    local p_name = puncher:get_player_name()

    if not sign_arena then return end -- nel caso qualche cartello dovesse impallarsi, si può rompere senza far crashare

    -- se si è nell'editor
    if arena_lib.is_player_in_edit_mode(p_name) then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must leave the editor first!")))
      return end

	-- se il cartello è stato spostato (tipo con WorldEdit), lo ripristino (e se c'è una partita in corso, la interrompo)
    if minetest.serialize(sign_arena.sign) ~= minetest.serialize(pos) then
      local arena_name = sign_arena.name
      arena_lib.force_arena_ending(mod, sign_arena, "ARENA_LIB")
      arena_lib.disable_arena("", mod, arena_name)
      arena_lib.set_sign("", mod, arena_name, _, true)
      arena_lib.set_sign("", mod, arena_name, pos)
      arena_lib.enable_arena("", mod, arena_name)
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Uh-oh, it looks like this sign has been misplaced: well, fixed, hit it again!")))
      return end

    -- se c'è parties e si è in gruppo...
    if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) and arena_lib.get_queueID_by_player(p_name) ~= arenaID then

      -- se non si è il capo gruppo
      if not parties.is_player_party_leader(p_name) then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Only the party leader can enter the queue!")))
        return end

      local party_members = parties.get_party_members(p_name)

      for _, pl_name in pairs(party_members) do
	    if arena_lib.is_player_in_arena(pl_name) then
		  minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must wait for all your party members to finish their ongoing games before entering a new one!")))
		  return
	    end
      end

      --se non c'è spazio (no team)
      if not sign_arena.teams_enabled then
        if #party_members > sign_arena.max_players - sign_arena.players_amount then
          minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is not enough space for the whole party!")))
          return end
      -- se non c'è spazio (team)
      else

        local free_space = false
        for _, amount in pairs(sign_arena.players_amount_per_team) do
          if #party_members <= sign_arena.max_players - amount then
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

			-- se è un party, rimuovo tutto il gruppo
			if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then

				-- (se non è il capogruppo, annullo)
				if not parties.is_player_party_leader(p_name) then
					minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Only the party leader can leave the queue!")))
					return end

				local party_members = parties.get_party_members(p_name)

				for _, pl_name in pairs(party_members) do
					arena_lib.remove_player_from_queue(pl_name)
				end

			-- sennò rimuovo il singolo utente
			else
				arena_lib.remove_player_from_queue(p_name)
			end

			-- se era in coda per la stessa arena, interrompo qua, sennò procedo per
			-- aggiungerlo nella nuova
			if queued_mod == mod and queued_ID == arenaID then return end
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

    -- aggiungo il giocatore
    for _, pl_name in pairs(players_to_add) do
      sign_arena.players[pl_name] = {kills = 0, deaths = 0, teamID = p_team_ID}
      sign_arena.players_and_spectators[pl_name] = true
    end

    -- aumento il conteggio di giocatori in partita
    sign_arena.players_amount = sign_arena.players_amount + #players_to_add
    if sign_arena.teams_enabled then
      sign_arena.players_amount_per_team[p_team_ID] = sign_arena.players_amount_per_team[p_team_ID] + #players_to_add
    end

    -- notifico i vari giocatori del nuovo giocatore
    if sign_arena.in_game then
      for _, pl_name in pairs(players_to_add) do
        arena_lib.join_arena(mod, pl_name, arenaID)
        arena_lib.update_sign(sign_arena)
      end
      return
    else
      for _, pl_name in pairs(players_to_add) do
        arena_lib.add_to_queue(pl_name, mod, arenaID)
      end
    end

    local timer = minetest.get_node_timer(pos)
    local arena_max_players = sign_arena.max_players * #sign_arena.teams

    -- se la coda non è partita...
    if not sign_arena.in_queue and not sign_arena.in_game then

      local players_required = arena_lib.get_players_to_start_queue(sign_arena)

      -- ...e ci sono abbastanza giocatori, parte il timer d'attesa
      if players_required <= 0 then
        sign_arena.in_queue = true
        timer:start(mod_ref.settings.queue_waiting_time)
        HUD_countdown(sign_arena, timer)

      -- sennò aggiorno semplicemente la HUD
      else
        arena_lib.HUD_send_msg_all("hotbar", sign_arena, arena_lib.queue_format(sign_arena, S("Waiting for more players...")) ..
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
   ]] .. "\n\n" .. [[
   ]] .. arena.name .. "\n" .. [[
   ]] .. p_count .. "/".. arena.max_players * t_count .. "\n" .. [[
   ]] .. in_game_txt(arena) .. "\n" .. [[

  ]]})
end



-- es. Foresta | 3/4 | Il match inizierà a breve
function arena_lib.queue_format(arena, msg)
  local arena_max_players = arena.max_players * #arena.teams
  return arena.name .. " | " .. arena.players_amount .. "/" .. arena_max_players  .. " | " .. msg
end



function arena_lib.get_players_to_start_queue(arena)

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
    players_required = arena_min_players - arena.players_amount
  end

  return players_required
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

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
    arena_lib.HUD_send_msg_all("broadcast", arena, S("Game begins in @1!", seconds), nil, "arenalib_countdown")
    arena_lib.HUD_send_msg_all("hotbar", arena, arena_lib.queue_format(arena, S("Get ready!")))
  else
    arena_lib.HUD_send_msg_all("hotbar", arena, arena_lib.queue_format(arena, S("@1 seconds for the match to start", seconds)))
  end

  minetest.after(1, function()
    HUD_countdown(arena, timer)
  end)
end



function in_game_txt(arena)
  local txt

	-- it's not possible to translate them => https://gitlab.com/VanessaE/signs_lib/-/issues/9
  if not arena.enabled then txt = "#dWIP"
	elseif arena.in_queue then txt = "#2Queueing"
  elseif arena.in_celebration then txt = "#4Terminating"
  elseif arena.in_loading then txt = "#4Loading"
  elseif arena.in_game then txt = "#4In progress"

  else txt = "#3Waiting" end

  return txt
end



function get_infobox_formspec(mod, arenaID, player)

	player:get_meta():set_string("arenalib_infobox_mod", mod)
	player:get_meta():set_int("arenalib_infobox_arenaID", arenaID)

	local arena = arena_lib.mods[mod].arenas[arenaID]
	local bgm_info

	if arena.bgm then
		local title = arena.bgm.title or "???"
		local author = arena.bgm.author or "???"
		bgm_info = title .. " - " .. author
	else
		bgm_info = "---"
	end

	local formspec = {
		"formspec_version[4]",
		"size[7.1,5]",
		"no_prepend[]",
		"bgcolor[;neither]",
		"style_type[image_button;border=false;bgimg=blank.png]",
		"background[0,0;1,1;arenalib_infobox.png;true]",
		-- immagini
		"image[1,0.7;1,1;arenalib_infobox_name.png]",
		"image[1,1.7;1,1;arenalib_tool_settings_nameauthor.png]",
		"image[1,3.1;1,1;arenalib_customise_bgm.png]",
		"image_button[5.9,0.7;0.5,0.5;arenalib_infobox_quit.png;close;]",
		"image_button[4.7,0.45;1,1;arenalib_infobox_spectate.png;spectate;]",
		-- scritte
		"hypertext[2.4,1.1;4,1;name;<style size=20 font=mono color=#5a5353>" .. FS(arena.name) .. "</style>]",
		"hypertext[2.4,2.15;4,1;name;<style size=20 font=mono color=#5a5353>" .. FS(arena.author) .. "</style>]",
		"hypertext[2.4,3.15;4,1;name;<global valign=middle><style size=20 font=mono color=#5a5353>" .. FS(bgm_info) .. "</style>]",
	}

	return table.concat(formspec, "")
end



------------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)

	if formname ~= "arena_lib:infobox" then return end

	if fields.close then
		minetest.close_formspec(player:get_player_name(), formname)
		player:get_meta():set_string("arenalib_infobox_mod", "")
		player:get_meta():set_int("arenalib_infobox_arenaID", 0)

	elseif fields.spectate then
		local mod = player:get_meta():get_string("arenalib_infobox_mod")
		local arenaID = player:get_meta():get_int("arenalib_infobox_arenaID")
		local p_name = player:get_player_name()

		if arena_lib.is_player_in_queue(p_name) then
			arena_lib.remove_player_from_queue(p_name)
		end

		arena_lib.join_arena(mod, p_name, arenaID, true)
	end
end)

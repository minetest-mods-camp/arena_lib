local S = minetest.get_translator("arena_lib")



function ARENA_LIB_EDIT_PRECHECKS_PASSED(sender, arena, skip_enabled)

  -- se non esiste l'arena, annullo
  if arena == nil then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] This arena doesn't exist!")))
    return end

  -- se non è disabilitata, annullo
  if arena.enabled and not skip_enabled then
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] You must disable the arena first!")))
    return end

  -- se è in modalità edit, annullo
  if arena_lib.is_arena_in_edit_mode(arena.name) then
    local p_name_inside = arena_lib.get_player_in_edit_mode(arena.name)
    minetest.chat_send_player(sender, minetest.colorize("#e6482e", S("[!] There must be no one inside the editor of the arena to perform this command! (now inside: @1)", p_name_inside)))
    return end

  return true
end


-- TODO: 6.0, remove arenaID, use arena.ID instead
function ARENA_LIB_JOIN_CHECKS_PASSED(arena, arenaID, p_name)
  -- se si è nell'editor
  if arena_lib.is_player_in_edit_mode(p_name) then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must leave the editor first!")))
    return end

  -- se non è abilitata
  if not arena.enabled then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is not enabled!")))
    return end

  -- se c'è `parties` e si è in gruppo...
  if minetest.get_modpath("parties") and parties.is_player_in_party(p_name) then

    -- se non si è il capo gruppo
    if not parties.is_player_party_leader(p_name) then
      minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Only the party leader can enter the queue!")))
      return end

    local party_members = parties.get_party_members(p_name)

    -- per tutti i membri...
    for _, pl_name in pairs(party_members) do
      -- se uno è in partita
      if arena_lib.is_player_in_arena(pl_name) and not arena_lib.is_player_spectating(pl_name) then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must wait for all your party members to finish their ongoing games before entering a new one!")))
        return end

      -- se uno è attaccato a qualcosa
      if minetest.get_player_by_name(pl_name):get_attach() and not arena_lib.is_player_spectating(pl_name) then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] Can't enter a game if some of your party members are attached to something! (e.g. boats, horses etc.)")))
        return end
    end

    --se non c'è spazio (no gruppo)
    if not arena.teams_enabled then
      if #party_members > arena.max_players - arena.players_amount then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is not enough space for the whole party!")))
        return end
    -- se non c'è spazio (gruppo)
    else

      local free_space = false
      for _, amount in pairs(arena.players_amount_per_team) do
        if #party_members <= arena.max_players - amount then
          free_space = true
          break
        end
      end

      if not free_space then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is no team with enough space for the whole party!")))
        return end
    end
  end

  local player = minetest.get_player_by_name(p_name)

  -- se si è attaccati a qualcosa
  if player:get_attach() and not arena_lib.is_player_spectating(p_name) then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] You must detach yourself from the entity you're attached to before entering!")))
    return end

  -- se l'arena è piena
  if arena.players_amount == arena.max_players * #arena.teams and arena_lib.get_queueID_by_player(p_name) ~= arenaID then
    minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] The arena is already full!")))
    return end

  return true
end



function AL_property_to_string(property)

	if type(property) == "string" then
		return "\"" .. property .. "\""
	elseif type(property) == "table" then
		return tostring(dump(property)):gsub("\n", "")
	else
		return tostring(property)
	end
end

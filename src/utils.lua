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



function AL_value_to_string(value)

	if type(value) == "string" then
		return "\"" .. value .. "\""
	elseif type(value) == "table" then
		return tostring(dump(value)):gsub("\n", "")
	else
		return tostring(value)
	end

end

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



function AL_property_to_string(property)

	if type(property) == "string" then
		return "\"" .. property .. "\""
	elseif type(property) == "table" then
		return tostring(dump(property)):gsub("\n", "")
	else
		return tostring(property)
	end
end





----------------------------------------------
-------------ASPETTANDO MINETEST--------------
----------------------------------------------
arena_lib.temp = {}

-- proper get_sky() => https://github.com/minetest/minetest/issues/11890
function arena_lib.temp.get_sky(player)
  local get_sky = {player:get_sky()}
  local p_sky = {}

  p_sky.base_color = (type(get_sky[1]) ~= "table") and get_sky[1] or table.copy(get_sky[1])
  p_sky.type = get_sky[2]
  p_sky.sky_color = table.copy(player:get_sky_color())
  p_sky.textures = table.copy(get_sky[3])
  p_sky.clouds = get_sky[4]

  return p_sky
end

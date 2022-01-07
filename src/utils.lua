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

-- proper celestial vault reset => https://github.com/minetest/minetest/pull/11922
function arena_lib.temp.reset_celestial_vault(player)
  local sky = {
    base_color = "#ffffff",
    type = "regular",
    clouds = true,
    sky_color = {
      day_sky = "#61b5f5",
      day_horizon = "#90d3f6",
      dawn_sky = "#b4bafa",
      dawn_horizon = "#bac1f0",
      night_sky = "#006bff",
      night_horizon = "#4090ff",
      indoors = "#646464",
      fog_tint_type = "default",
      fog_sun_tint = "#f47d1d",
      fog_moon_tint = "#7f99cc"
    }
  }

  local sun = {
    visible = true,
    sunrise_visible = true,
    texture = "sun.png",
    tonemap = "sun_tonemap.png",
    sunrise = "sunrisebg.png",
    scale = 1
  }

  local moon = {
    visible = true,
    texture = "moon.png",
    tonemap = "moon_tonemap.png",
    scale = 1
  }

  local stars = {
    visible = true,
    count = 1000,
    star_color = "#ebebff69",
    scale = 1
  }

  local clouds = {
    density = 0.4,
    color = "#fff0f0e5",
    ambient = "#000000",
    thickness = 16,
    height = 120,
    speed = { x = 0, z = -2}
  }

  player:set_sky(sky)
  player:set_sun(sun)
  player:set_moon(moon)
  player:set_stars(stars)
  player:set_clouds(clouds)
end

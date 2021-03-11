local S = minetest.get_translator("arena_lib")

local function get_sky_formspec() end
local function get_sun_formspec() end

local temp_sky_settings = {}          -- KEY = p_name; VALUE = {all the sky settings}
local sky_tools = {
  "arena_lib:sky",
  "",
  "",
  "",
  "",
  "",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}



minetest.register_tool("arena_lib:editor_sky", {

    description = S("Set sky"),
    inventory_image = "arenalib_editor_sky.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)
      local p_name      = user:get_player_name()

      temp_sky_settings[p_name] = table.copy(arena.sky)

      local temp_sky = temp_sky_settings[p_name]

      if not temp_sky.sky_parameters then
        temp_sky.sky_parameters = {}

        if not temp_sky.sky_color then
          temp_sky.sky_parameters.sky_color = {}
        end

        if not temp_sky.textures then
          temp_sky.sky_parameters.textures = {}
        end
      end

      if not temp_sky.sun_parameters then
        temp_sky.sun_parameters = {}
      end

      if not temp_sky.moon_parameters then
        temp_sky.moon_parameters = {}
      end

      if not temp_sky.stars_parameters then
        temp_sky.stars_parameters = {}
      end

      if not temp_sky.clouds_parameters then
        temp_sky.clouds_parameters = {}

        if not temp_sky.clouds_parameters.speed then
          temp_sky.clouds_parameters.speed = {}
        end
      end

      minetest.show_formspec(p_name, "arena_lib:settings_sky", get_sky_formspec(p_name))
    end
})



function arena_lib.give_sky_tools(player)
  player:get_inventory():set_list("main", sky_tools)
end



----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_sky_formspec(p_name)

  local temp_sky = temp_sky_settings[p_name].sky_parameters

  local fog_tint_ID = 1
  local fog_tint_sun = ""
  local fog_tint_moon = ""
  local sky_type = 1

  if next(temp_sky) then

    if temp_sky.sky_color.fog_tint_type == "custom" then
      fog_tint_ID = 2
      fog_tint_sun = "field[2.6,2;2.5,0.6;fog_sun_tint;Fog sun tint;" .. (temp_sky.fog_sun_tint or "") .. "]"
      fog_tint_moon = "field[5.2,2;2.5,0.6;fog_moon_tint;Fog moon tint;" .. (temp_sky.fog_moon_tint or "") .. "]"
    end

    if temp_sky.type == "skybox" then
      sky_type = 2
    elseif temp_sky.type == "plain" then
      sky_type = 3
    end
  end

  local formspec = {
    "formspec_version[4]",
    "size[9.9,13]",
    "position[0.5,0.5]",
    "no_prepend[]",
    -- bottoni
    "container[1,1]",
    "image_button[0,0;1.5,1;arenalib_editor_sky.png;sky;]",
    "image_button[1.6,0;1.5,1;arenalib_editor_sky.png;sky;]",
    "image_button[3.2,0;1.5,1;arenalib_editor_sky.png;sky;]",
    "image_button[4.8,0;1.5,1;arenalib_editor_sky.png;sky;]",
    "image_button[6.4,0;1.5,1;arenalib_editor_sky.png;sky;]",
    "container_end[]",
    "container[1,2.2]",
    -- colore base e tipo di tinta della nebbia
    "field[0,0.5;3.75,0.6;base_color;Base color;" .. (temp_sky.base_color or "") .. "]",
    "label[4.2,0.33;Fog tint type]",
    "dropdown[4.15,0.5;3.75,0.6;fog_tint_type;default,custom;".. fog_tint_ID .. ";]",
    "container[0,1.8]",
    -- colori vari
    "field[0,0;2.5,0.6;day_sky;Day sky;" .. (temp_sky.day_sky or "" ) .. "]",
    "field[2.6,0;2.5,0.6;day_horizon;Day horizon;" .. (temp_sky.day_horizon or "" ) .. "]",
    "field[5.2,0;2.5,0.6;dawn_sky;Dawn sky;" .. (temp_sky.dawn_sky or "" ) .. "]",
    "field[0,1;2.5,0.6;dawn_horizon;Dawn horizon;" .. (temp_sky.dawn_horizon or "" ) .. "]",
    "field[2.6,1;2.5,0.6;night_sky;Night sky;" .. (temp_sky.night_sky or "" ) .. "]",
    "field[5.2,1;2.5,0.6;night_horizon;Night horizon;" .. (temp_sky.night_horizon or "" ) .. "]",
    "field[0,2;2.5,0.6;indoors;Indoors;" .. (temp_sky.indoors or "" ) .. "]",
    fog_tint_sun,
    fog_tint_moon,
    "container_end[]",
    -- nuvole e tipo di cielo
    "checkbox[0,5.2;clouds;Clouds;" .. (temp_sky.clouds or "true") .. "]",
    "label[4.15,4.83;Type]",
    "dropdown[4.15,5;3.75,0.6;type;regular,skybox,plain;" .. sky_type .. ";]",
    -- skybox, dettagli
    -- (vedere if sotto)
    "image_button[3.05,9.7;1.9,0.7;arenalib_editor_sky.png;apply;" .. S("Apply") .."]",
    "container_end[]",
  }

  -- eventuali parametri skybox
  if next(temp_sky) then
    if temp_sky.type == "skybox" then
      local skybox = {
        "container[0,6.5]",
        "field[0,0;3.75,0.6;top;Top;" .. (temp_sky.textures[1] or "" ) .. "]",
        "field[4.15,0;3.75,0.6;bottom;Bottom;" .. (temp_sky.textures[2] or "") .. "]",
        "field[0,1;3.75,0.6;west;West;" .. (temp_sky.textures[3] or "") .. "]",
        "field[4.15,1;3.75,0.6;east;East;" .. (temp_sky.textures[4] or "") .. "]",
        "field[0,2;3.75,0.6;north;North;" .. (temp_sky.textures[5] or "") .. "]",
        "field[4.15,2;3.75,0.6;south;South;" .. (temp_sky.textures[6] or "") .. "]",
        "container_end[]",
      }

      for k, v in pairs(skybox) do
        table.insert(formspec, #formspec-1, v)
      end
    end
  end

  return table.concat(formspec, "")
end



function get_sun_formspec(p_name)

  local temp_sun = temp_sky_settings[p_name].sun_parameters

  local formspec = {
    "formspec_version[4]",
    "size[9.9,13]",
    "position[0.5,0.5]",
    "no_prepend[]",
  }

  return table.concat(formspec, "")
end


----------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)

  if formname ~= "arena_lib:settings_sky" then return end

  local p_name = player:get_player_name()
  local temp_sky = temp_sky_settings[p_name].sky_parameters

  minetest.chat_send_player(p_name, dump(fields))

  if fields.quit then
    temp_sky_settings[p_name] = nil
    return
  end

  temp_sky.base_color = fields.base_color
  temp_sky.day_sky = fields.day_sky
  temp_sky.day_horizon = fields.day_horizon
  temp_sky.dawn_sky = fields.dawn_sky
  temp_sky.dawn_horizon = fields.dawn_horizon
  temp_sky.night_sky = fields.night_sky
  temp_sky.night_horizon = fields.night_horizon
  temp_sky.indoors = fields.indoors
  temp_sky.clouds = fields.clouds or temp_sky.clouds

  if temp_sky.sky_color.fog_tint_type == "custom" then
    temp_sky.fog_sun_tint = fields.fog_sun_tint
    temp_sky.fog_moon_tint = fields.fog_moon_tint
  end

  if temp_sky.textures then
    temp_sky.textures[1] = fields.top
    temp_sky.textures[2] = fields.bottom
    temp_sky.textures[3] = fields.west
    temp_sky.textures[4] = fields.east
    temp_sky.textures[5] = fields.north
    temp_sky.textures[6] = fields.south
  end

  if fields.type then
    temp_sky.type = fields.type
    if fields.type == "skybox" and not temp_sky.textures then
      temp_sky.textures = {}
    end
    minetest.show_formspec(p_name, "arena_lib:settings_sky", get_sky_formspec(p_name))

  elseif fields.fog_tint_type then
    temp_sky.sky_color.fog_tint_type = fields.fog_tint_type
    minetest.show_formspec(p_name, "arena_lib:settings_sky", get_sky_formspec(p_name))
  end
end)

local S = minetest.get_translator("arena_lib")

local function fill_templight() end
local function get_lighting_formspec() end

local temp_light_settings = {}          -- KEY = p_name; VALUE = {light = override_day_night_ratio}



minetest.register_tool("arena_lib:customise_lighting", {

    description = S("Lighting"),
    inventory_image = "arenalib_customise_lighting.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)
      local p_name      = user:get_player_name()

      fill_templight(p_name, arena)

      minetest.show_formspec(p_name, "arena_lib:lighting", get_lighting_formspec(p_name))
    end
})





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function fill_templight(p_name, arena)
  temp_light_settings[p_name] = not arena.lighting and {} or table.copy(arena.lighting)
end



function get_lighting_formspec(p_name)

  local light = (temp_light_settings[p_name].light or 0.5) * 100
  --TODO MT 5.6: local shadows  = 0

  local formspec = {
    "formspec_version[4]",
    "size[7,4.5]",
    "bgcolor[;neither]",
    -- parametri vari
    "container[0.5,0.5]",
    "label[0,0;" .. S("Global light") .. "]",
    "label[0,0.41;0]",
    "label[5.8,0.41;1]",
    "scrollbaroptions[max=100;smallstep=1;largestep=10;arrows=hide]",
    "scrollbar[0.4,0.3;5.2,0.2;;light;" .. light .. "]",
    "label[0,1;" .. S("Shadows") .. "]",
    "hypertext[-0.05,1.3;6,0.3;audio_info;<style size=12 font=mono color=#b7aca3>(" .. S("coming with MT 5.6") .. ")</style>]",
    --[["label[0,1.41;0]",
    "label[5.9,1.41;1]",
    "scrollbar[0.4,1.3;5.2,0.2;;shadows;" .. shadows .. "]",]]
    "container_end[]",
    "button[1.95,3.7;1.5,0.5;reset;" .. S("Reset") .."]",
    "button[3.55,3.7;1.5,0.5;apply;" .. S("Apply") .."]",
  }

  return table.concat(formspec, "")
end





----------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)

  if formname ~= "arena_lib:lighting" then return end

  local p_name = player:get_player_name()
  local mod         = player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name  = player:get_meta():get_string("arena_lib_editor.arena")
  local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)
  local light_table = arena.lighting or {}

  -- se abbandona...
  if fields.quit then
    if next(light_table) then
      player:override_day_night_ratio(light_table.light)
    else
      player:override_day_night_ratio(nil)
    end

    temp_light_settings[p_name] = nil
    return

  -- ...o se ripristina, non c'è bisogno di andare oltre
  elseif fields.reset then
    -- se la tabella non esiste, vuol dire che non c'è nulla da ripristinare (ed evito
    -- che invii il messaggio di proprietà sovrascritte)
    if arena.lighting then
      arena_lib.set_lighting(p_name, mod, arena_name, nil, true)
    end

    player:override_day_night_ratio(nil)
    minetest.show_formspec(p_name, "arena_lib:lighting", get_lighting_formspec(p_name))
    return
  end

  --
  -- aggiorna i vari parametri
  --

  if fields.light then
    light_table.light = minetest.explode_scrollbar_event(fields.light).value / 100
  end


  -- applica
  if fields.apply then
    arena_lib.set_lighting(p_name, mod, arena_name, light_table, true)
  end

  player:override_day_night_ratio(light_table.light)
end)

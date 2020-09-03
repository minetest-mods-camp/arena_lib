local S = minetest.get_translator("arena_lib")
local FS = minetest.formspec_escape

local function get_rename_formspec() end
local function get_properties_formspec() end
local function value_to_string() end

local settings_tools = {
  "arena_lib:settings_rename",
  "arena_lib:settings_properties",
  "",
  "",
  "",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}

local sel_property_attr = {}     --KEY: p_name; VALUE: {id = idx, name = property_name}




minetest.register_tool("arena_lib:settings_rename", {

    description = S("Rename arena"),
    inventory_image = "arenalib_tool_settings_rename.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)
      local p_name = user:get_player_name()
      minetest.show_formspec(p_name, "arena_lib:settings_rename", get_rename_formspec(p_name))
    end
})



minetest.register_tool("arena_lib:settings_properties", {

    description = S("Arena properties"),
    inventory_image = "arenalib_tool_properties.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local p_name      = user:get_player_name()
      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local id, arena   = arena_lib.get_arena_by_name(mod, arena_name)

      minetest.show_formspec(p_name, "arena_lib:settings_properties", get_properties_formspec(p_name, mod, arena, 1))
    end
})



function arena_lib.give_settings_tools(user)
  user:get_inventory():set_list("main", settings_tools)
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_properties_formspec(p_name, mod, arena, sel_idx)

  local mod_ref = arena_lib.mods[mod]
  local properties = ""
  local properties_by_idx = {}
  local sel_property = ""
  local sel_property_value = ""
  local i = 1

  -- ottengo una stringa con tutte le proprietà
  for property, v in pairs(mod_ref.properties) do
    properties = properties .. property .. " = " .. FS(value_to_string(arena[property])) .. ","
    properties_by_idx[i] = property
    i = i + 1
  end

  -- ottengo il nome della proprietà selezionata
  if not sel_idx then
    sel_property = properties_by_idx[1]
  else
    sel_property = properties_by_idx[sel_idx]
  end

  -- e assegno il valore
  sel_property_attr[p_name] = {id = sel_idx, name = sel_property}
  sel_property_value = FS(value_to_string(arena[sel_property]))

  properties = properties:sub(1,-2)

  local formspec = {
    "size[6.25,3.7]",
    "hypertext[0,0;6.25,1;properties_title;<global halign=center>Arena properties]",
    "textlist[0,0.5;6,2.5;arena_properties;" .. properties .. ";" .. sel_idx .. ";false]",
    "field[0.3,3.3;4.7,1;sel_property_value;;" .. sel_property_value .. "]",
    "button[4.72,2.983;1.5,1;property_overwrite;" .. S("Overwrite") .. "]",
    "field_close_on_enter[sel_property_value;false]"
  }

  return table.concat(formspec, "")
end



function get_rename_formspec(p_name)

  local formspec = {
    "size[5.2,0.4]",
    "no_prepend[]",
    "bgcolor[;neither]",
    "field[0.2,0.25;4,1;rename;;]",
    "button[3.8,-0.05;1.5,1;rename_confirm;" .. S("Rename Arena") .. "]",
    "field_close_on_enter[rename;false]"
  }

  return table.concat(formspec, "")
end



function value_to_string(property)

	if type(property) == "string" then
		return "\"" .. property .. "\""
	elseif type(property) == "table" then
		return tostring(dump(property)):gsub("\n", "")
	else
		return tostring(property)
	end

end





----------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------


minetest.register_on_player_receive_fields(function(player, formname, fields)

  if formname ~= "arena_lib:settings_rename" and formname ~= "arena_lib:settings_properties" then return end

  local p_name      =   player:get_player_name()
  local mod         =   player:get_meta():get_string("arena_lib_editor.mod")
  local arena_name  =   player:get_meta():get_string("arena_lib_editor.arena")

  -- GUI per rinominare arena
  if formname == "arena_lib:settings_rename" then

    if fields.rename_confirm or fields.key_enter then
      if arena_lib.rename_arena(p_name, mod, arena_name, fields.rename, true) then
        player:get_meta():set_string("arena_lib_editor.arena", fields.rename)
        minetest.close_formspec(p_name, formname)
      end
    end

  -- GUI per modificare proprietà
  else

    local id, arena = arena_lib.get_arena_by_name(mod, arena_name)

    -- se clicco sulla lista
    if fields.arena_properties then

      local expl = minetest.explode_textlist_event(fields.arena_properties)

      if expl.type == "DCL" or expl.type == "CHG" then
        minetest.show_formspec(p_name, "arena_lib:settings_properties", get_properties_formspec(p_name, mod, arena, expl.index))
      end

    -- se premo per sovrascrivere
    elseif fields.property_overwrite or fields.key_enter then
      arena_lib.change_arena_properties(p_name, mod, arena_name, sel_property_attr[p_name].name, fields.sel_property_value, true)
      minetest.show_formspec(p_name, "arena_lib:settings_properties", get_properties_formspec(p_name, mod, arena, sel_property_attr[p_name].id))
    end
  end

end)

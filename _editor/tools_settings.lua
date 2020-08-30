local S = minetest.get_translator("arena_lib")

local function get_rename_formspec() end
local function get_properties_formspec() end

local settings_tools = {
  "arena_lib:settings_rename",
  --"arena_lib:settings_properties",
  "",
  "",
  "",
  "",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}





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
    inventory_image = "arenalib_tool_settings_editor.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)
      local p_name = user:get_player_name()
      minetest.show_formspec(p_name, "arena_lib:settings_properties", get_properties_formspec(p_name))
    end
})



function arena_lib.give_settings_tools(user)
  user:get_inventory():set_list("main", settings_tools)
end





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_properties_formspec(p_name)

  local formspec = {
    "size[6,4]"
  }

  return table.concat(formspec, "")

end



function get_rename_formspec(p_name)

  local formspec = {
    "size[5.2,0.4]",
    "no_prepend[]",
    "bgcolor[;neither]",
    "field[0.2,0.25;4,1;rename;;]",
    "button[3.8,-0.05;1.5,1;rename_confirm;Rename Arena]",
    "field_close_on_enter[rename;false]"
  }

  return table.concat(formspec, "")

end

local S = minetest.get_translator("arena_lib")
local spawners_tools = {
  "arena_lib:sign_add",
  "arena_lib:sign_remove",
  "",
  "arena_lib:sign",
  "",
  "",
  "",
  "",
  "arena_lib:editor_return",
  "arena_lib:editor_quit",
}



minetest.register_tool("arena_lib:sign_add", {

    description = S("Add sign"),
    inventory_image = "arenalib_tool_sign_add.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local pos = minetest.get_pointed_thing_position(pointed_thing)
      if pos == nil then return end -- nel caso sia aria, sennò crasha

      local node = minetest.get_node(pos)
      local def = minetest.registered_items[node.name]
      local p_name = user:get_player_name()

      -- controllo se è un cartello
      if not def or def.entity_info == nil then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] That's not an arena_lib sign!")))
      return end

      arena_lib.set_sign(p_name, pos, false)
    end

})



minetest.register_tool("arena_lib:sign_remove", {

    description = S("Remove sign"),
    inventory_image = "arenalib_tool_sign_remove.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)

      local pos = minetest.get_pointed_thing_position(pointed_thing)
      if pos == nil then return end -- nel caso sia aria, sennò crasha

      local node_name = minetest.get_node(pos).name
      local p_name = user:get_player_name()

      -- controllo se è un cartello
      if node_name ~= "arena_lib:sign" then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] That's not an arena_lib sign!")))
      return end

      arena_lib.set_sign(p_name, pos, true)
    end

})



function arena_lib.give_signs_tools(player)
  player:get_inventory():set_list("main", spawners_tools)
end

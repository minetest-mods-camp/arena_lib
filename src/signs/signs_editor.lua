local S = minetest.get_translator("arena_lib")



minetest.register_tool("arena_lib:sign_add", {

    description = S("Add sign"),
    inventory_image = "arenalib_tool_sign_add.png",
    groups = {not_in_creative_inventory = 1},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)
      local p_name      = user:get_player_name()
      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local pos         = minetest.get_pointed_thing_position(pointed_thing)

      if not pos then return end -- nel caso sia aria, sennò crasha

      arena_lib.set_entrance(p_name, mod, arena_name, "add", pos)
    end
})



minetest.register_tool("arena_lib:sign_remove", {

    description = S("Remove sign"),
    inventory_image = "arenalib_tool_sign_remove.png",
    groups = {not_in_creative_inventory = 1},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user, pointed_thing)
      local p_name      = user:get_player_name()
      local mod         = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name  = user:get_meta():get_string("arena_lib_editor.arena")
      local _, arena    = arena_lib.get_arena_by_name(mod, arena_name)

      if not arena.entrance then
        minetest.chat_send_player(p_name, minetest.colorize("#e6482e", S("[!] There is no entrance to remove assigned to @1!", arena_name)))
        return end

      minetest.show_formspec(p_name, "arena_lib:sign_delete", get_sign_formspec(p_name, arena_name))
    end
})





----------------------------------------------
---------------FUNZIONI LOCALI----------------
----------------------------------------------

function get_sign_formspec(p_name, arena_name)

  local formspec = {
    "size[5,1]",
    "style[delete_confirm;bgcolor=red]",
    "hypertext[0.25,-0.1;5,1;delete_msg;<global halign=center>" .. S("Are you sure you want to delete the sign from @1?", arena_name) .. "]",
    "button[3,0.5;1.5,0.5;delete_confirm;" .. S("Yes") .. "]",
    "button[0.5,0.5;1.5,0.5;delete_cancel;" .. S("Cancel") .. "]",
    "field_close_on_enter[;false]"
  }

  return table.concat(formspec, "")
end





----------------------------------------------
---------------GESTIONE CAMPI-----------------
----------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)

  if formname ~= "arena_lib:sign_delete" then return end

  local p_name = player:get_player_name()

  if fields.delete_confirm then
    local mod         = player:get_meta():get_string("arena_lib_editor.mod")
    local arena_name  = player:get_meta():get_string("arena_lib_editor.arena")

    arena_lib.set_entrance(p_name, mod, arena_name, "remove")
    minetest.close_formspec(p_name, formname)

  elseif fields.delete_cancel then
    minetest.close_formspec(p_name, formname)
  end

end)

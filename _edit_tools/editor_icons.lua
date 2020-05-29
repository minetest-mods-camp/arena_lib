minetest.register_tool("arena_lib:editor_spawners", {

    description = "Spawner",
    inventory_image = "arenalib_editor_spawners.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      arena_lib.HUD_send_msg("hotbar", user:get_player_name(), "Spawner | ID sel.: 1 (Click dx su slot #2 per cambiare)")

      user:get_meta():set_int("arena_lib_editor.spawner_ID", 1)

      minetest.after(0, function()
        arena_lib.give_spawners_tools(user)
      end)
    end

})



minetest.register_tool("arena_lib:editor_signs", {

    description = "Cartelli",
    inventory_image = "arenalib_editor_signs.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      arena_lib.HUD_send_msg("hotbar", user:get_player_name(), "Un cartello per arena")

      minetest.after(0, function()
        arena_lib.give_signs_tools(user)
      end)
    end

})



minetest.register_tool("arena_lib:editor_info", {

    description = "Info",
    inventory_image = "arenalib_editor_info.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      local mod = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name = user:get_meta():get_string("arena_lib_editor.arena")

      arena_lib.print_arena_info(user:get_player_name(), mod, arena_name)
    end

})



minetest.register_tool("arena_lib:editor_return", {

    description = "Torna indietro",
    inventory_image = "arenalib_editor_return.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)
      minetest.after(0, function()
        arena_lib.show_main_editor(user)
      end)
    end

})



minetest.register_tool("arena_lib:editor_quit", {

    description = "Esci dall'editor",
    inventory_image = "arenalib_editor_quit.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)
      arena_lib.quit_editor(user)
    end

})

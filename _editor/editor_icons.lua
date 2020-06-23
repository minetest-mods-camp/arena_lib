local S = minetest.get_translator("arena_lib")



minetest.register_tool("arena_lib:editor_players", {

    description = S("Players"),
    inventory_image = "arenalib_editor_players.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      user:get_meta():set_int("arena_lib_editor.players_number", 2)

      arena_lib.HUD_send_msg("hotbar", user:get_player_name(), S("Players | num to set: @1 (left/right click slot #3 to change)", 2))

      minetest.after(0, function()
        arena_lib.give_players_tools(user)
      end)
    end

})



minetest.register_tool("arena_lib:editor_spawners", {

    description = S("Spawners"),
    inventory_image = "arenalib_editor_spawners.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      user:get_meta():set_int("arena_lib_editor.spawner_ID", 1)
      user:get_meta():set_int("arena_lib_editor.team_ID", 1)

      arena_lib.HUD_send_msg("hotbar", user:get_player_name(), S("Spawners | sel. ID: @1 (right click slot #2 to change)", 1))

      minetest.after(0, function()
        arena_lib.give_spawners_tools(user)
      end)
    end

})



minetest.register_tool("arena_lib:editor_signs", {

    description = S("Signs"),
    inventory_image = "arenalib_editor_signs.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      arena_lib.HUD_send_msg("hotbar", user:get_player_name(), S("One sign per arena"))

      minetest.after(0, function()
        arena_lib.give_signs_tools(user)
      end)
    end

})



minetest.register_tool("arena_lib:editor_info", {

    description = S("Info"),
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

    description = S("Go back"),
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



minetest.register_tool("arena_lib:editor_enable", {

    description = S("Enable and leave"),
    inventory_image = "arenalib_editor_enable.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      local mod = user:get_meta():get_string("arena_lib_editor.mod")
      local arena_name = user:get_meta():get_string("arena_lib_editor.arena")

      arena_lib.enable_arena(user:get_player_name(), mod, arena_name)
    end

})



minetest.register_tool("arena_lib:editor_quit", {

    description = S("Leave the editor"),
    inventory_image = "arenalib_editor_quit.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)
      arena_lib.quit_editor(user)
    end

})

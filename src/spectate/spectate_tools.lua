local S = minetest.get_translator("arena_lib")



minetest.register_tool("arena_lib:spectate_changeplayer", {

    description = S("Change player"),
    inventory_image = "arenalib_spectate_changeplayer.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      local p_name = user:get_player_name()
      local arena = arena_lib.get_arena_by_player(p_name)

      -- non far cambiare se c'è rimasto solo un giocatore da seguire
      if arena.players_amount == 1 then return end

      arena_lib.find_and_spectate_player(user:get_player_name())
    end

})



minetest.register_tool("arena_lib:spectate_changeteam", {

    description = S("Change team"),
    inventory_image = "arenalib_spectate_changeteam.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)

      local p_name = user:get_player_name()
      local arena = arena_lib.get_arena_by_player(p_name)

      -- non far cambiare se c'è rimasto solo una squadra da seguire
      if arena_lib.get_active_teams(arena) == 1 then return end

      arena_lib.find_and_spectate_player(user:get_player_name(), true)
    end

})



minetest.register_tool("arena_lib:spectate_join", {

    description = S("Enter the match"),
    inventory_image = "arenalib_editor_return.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)
      minetest.after(0, function()                                              -- after sennò non rimuove quest'oggetto
        local p_name = user:get_player_name()
        local mod = arena_lib.get_mod_by_player(p_name)
        local arena_ID = arena_lib.get_arenaID_by_player(p_name)
        arena_lib.join_arena(mod, p_name, arena_ID)
      end)
    end

})



minetest.register_tool("arena_lib:spectate_quit", {

    description = S("Leave"),
    inventory_image = "arenalib_editor_quit.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
    on_place = function() end,
    on_drop = function() end,

    on_use = function(itemstack, user)
      minetest.after(0, function()                                              -- after sennò non rimuove quest'oggetto
        arena_lib.remove_player_from_arena(user:get_player_name(), 3)
      end)
    end

})

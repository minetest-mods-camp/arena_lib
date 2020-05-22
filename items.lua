local S = minetest.get_translator("arena_lib")



minetest.register_tool("arena_lib:immunity", {

  description = S("You're immune!"),
  inventory_image = "arenalib_immunity.png",
  groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},
  on_place = function() end,
  on_drop = function() end

})



-- sovrascrizione "on_punch" nodo base dei cartelli per farli entrare nell'arena
-- se sono cartelli appositi e "on_timer" per teletrasportarli in partita quando 
-- la queue finisce
minetest.register_tool("arena_lib:create_sign", {

    description = S("Left click on a sign to create/remove the access to the arena"),
    inventory_image = "arenalib_createsign.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},

    on_use = function(itemstack, user, pointed_thing)

      local pos = minetest.get_pointed_thing_position(pointed_thing)
      if pos == nil then return end -- nel caso sia aria, sennò crasha

      local node = minetest.get_node(pos)
      local def = minetest.registered_items[node.name]

      --controllo se è un cartello
      if not def or def.entity_info == nil then
        minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", S("[!] That's not a sign!")))
      return end
      
      def.number_of_lines = 5
      
      arena_lib.set_sign(itemstack, user, pos)
    end,

})

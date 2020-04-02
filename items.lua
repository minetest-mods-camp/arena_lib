minetest.register_tool(arena_lib.mod_name .. ":immunity", {

  description = "Sei immune!",
  inventory_image = "arena_immunity.png",
  groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},

})



--[[sovrascrizione "on_punch" nodo base dei cartelli per farli entrare
    nell'arena se sono cartelli appositi e "on_timer" per teletrasportali in partita quando la queue finisce]]
minetest.register_tool(arena_lib.mod_name .. ":create_sign", {

    description = "Left click on a sign to create an entrance or to remove it",
    inventory_image = "arena_createsign.png",
    groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = "2"},

    on_use = function(itemstack, user, pointed_thing)

      local pos = minetest.get_pointed_thing_position(pointed_thing)
      if pos == nil then return end -- nel caso sia aria, sennò crasha

      local node = minetest.get_node(pos)
      local def = minetest.registered_items[node.name]

      --controllo se è un cartello
      if def and def.entity_info then
        def.number_of_lines = 5

        local arena_ID = itemstack:get_meta():get_int("arenaID")
        local arena = arena_lib.arenas[arena_ID]

        -- controllo se c'è già un cartello assegnato a quell'arena. Se è lo stesso lo rimuovo, sennò annullo
        if next(arena.sign) ~= nil then
          if minetest.serialize(pos) == minetest.serialize(arena.sign) then
            minetest.set_node(pos, {name = "air"})
            arena.sign = {}
            minetest.chat_send_player(user:get_player_name(), "Cartello dell'arena " .. arena.name .. " rimosso con successo")
          else
            minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", "[!] Esiste già un cartello per quest'arena!"))
          end
        return end

        -- cambio la scritta
        arena_lib.update_sign(pos, arena)

        -- aggiungo il cartello ai cartelli dell'arena
        arena.sign = pos

        -- salvo l'ID come metadato nel cartello
        minetest.get_meta(pos):set_int("arenaID", arena_ID)
      else
        minetest.chat_send_player(user:get_player_name(), minetest.colorize("#e6482e", "[!] L'oggetto non è un cartello!"))
      end
    end,

})

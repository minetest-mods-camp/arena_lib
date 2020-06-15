# Arena_lib docs

> You in a hurry? Skip the theory going to point [#2](#2-configuration)

## 1. Arenas
It all starts with a table called `arena_lib.mods = {}`. This table allows `arena_lib` to be subdivided per mod and it has different parameters, one being `arena_lib.mods[yourmod].arenas`. Here is where every new arena created gets put.  
An arena is a table having as a key an ID and as a value its parameters. They are:
* `name`: (string) the name of the arena, declared when creating it
* `sign`: (pos) the position of the sign associated with the arena.
* `players`: (table) where to store players
* `teams`: (table) where to store teams
* `players_amount`: (int) separately stores how many players are inside the arena/queue
* `max_players`: (string) default is 4. When this value is reached, queue time decreases to 5 if it's not lower already
* `min_players`: (string) default is 2. When this value is reached, a queue starts
* `in_queue`: (bool) about phases, look at "Arena phases" down below
* `in_loading`: (bool)
* `in_game`: (bool)
* `in_celebration`: (bool)
* `enabled`: (bool) by default an arena is disabled, to avoid any unwanted damage



Being arenas stored by ID, they can be easily retrieved by `arena_libs.mods[yourmod].arenas[THEARENAID]`.  

There are two ways to know an arena ID: the first is in-game via the two debug utilities:
* `arena_lib.print_arenas(sender, mod)`: coincise
* `arena_lib.print_arena_info(sender, mod, arena_name)`: extended with much more information

The second is via code by the function `arena_libs.get_arenaID_by_player(p_name)`.  

### 1.1 Creating and removing arenas
There are two functions for it and they all need to be connected to some command in your mod. The functions are
* `arena_lib.create_arena(sender, mod, arena_name, <min_players>, <max_players>)`: it doesn't accept duplicates. Sender is a string, fields between < > are optional 
* `arena_lib.remove_arena(mod, arena_name)`: if a game is taking place in it, it won't go through

#### 1.1.1 Storing arenas
Arenas and their settings are stored inside the mod storage. What is *not* stored are players, their stats and such.  
Better said, these kind of parameters are emptied every time the server starts. And not when it ends, because handling situations like crashes is simply not possible.
  
### 1.2 Setting up an arena
Two things are needed to have an arena up to go: spawners and signs. There are two functions for that:  
* `arena_lib.set_spawner(sender, mod, arena_name, <teamID_or_name>, <param>, <ID>)`: spawners can't exceed the maximum players of an arena and, more specifically, they must be the same number. A spawner is a table with `pos` and `team_ID` as values.
* `arena_lib.set_sign(sender, <pos, remove>, <mod, arena_name>)`: there must be one and only one sign per arena. Signs are the bridge between the arena and the rest of the world

#### 1.2.1 Editor
From version 3.0.0, arena_lib comes with a fancy editor via hotbar so you don't have to configure and memorise a lot of commands (if you still want to go full CLI/chat though, skip this paragraph).
In order to use the editor, no other players must be editing the same arena. When entering it, the arena is disabled automatically. The rest is pretty straightforward :D if you're not sure of what something does, just open the inventory and read its name.  
The function calling the editor is  
`arena_lib.enter_editor(sender, mod, arena_name)`

#### 1.2.2 CLI
If you don't want to rely on the hotbar, or you want both the editor and the commands via chat, here's how the commands work.

##### 1.2.2.1 Spawners
`arena_lib.set_spawner(sender, mod, arena_name, <teamID_or_name>, <param>, <ID>)` creates a spawner where the sender is standing, so be sure to stand where you want the spawn point to be.  
* `teamID_or_name` can be both a string and a number. It must be specified if your arena uses teams
* `param` is a string, specifically "overwrite", "delete" or "deleteall". "deleteall" aside, the other ones need an ID after them. Also, if a team is specified with deleteall, it will only delete the spawners belonging to that team
* `ID` is the spawner ID, for `param`
I suggest you using [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy and connect the `set_spawner` function to a few subcommands such as:

```

local mod = "mymod" -- more about this later

ChatCmdBuilder.new("NAMEOFYOURCOMMAND", function(cmd)

	-- for creating spawners without teams
	cmd:sub("setspawn :arena", function(sender, arena)
	  arena_lib.set_spawner(sender, mod, arena)
	end)

	-- for creating spawners with teams
	cmd:sub("setspawn :arena :team:word", function(sender, arena, team)
          arena_lib.set_spawner(sender, mod, arena, team)
      	end)

	-- for using 'param' (just pass a random number for deleteall as it won't matter)
	cmd:sub("setspawn :arena :param:word :ID:int", function(sender, arena, param, ID)
	  arena_lib.set_spawner(sender, mod, arena, nil, param, ID)
	end)

	-- for using 'param' with teams
	cmd:sub("setspawn :arena :team:word :param:word :ID:int", function(sender, arena, team, param, ID)
	  arena_lib.set_spawner(sender, mod, arena, team, param, ID)
	end)

   [etc.]
```

##### 1.2.2.2 Signs
`arena_lib.set_sign(sender, <pos, remove>, <mod, arena_name>)` via chat uses `sender`, `mod` and `arena_name`, while the editor `pos` and `remove` (hence the weird subdivision). When used via chat, it takes the block the player is pointing at in a 5 blocks radius. If the block is a sign, it then creates (or remove if already set) the "arena sign". 

#### 1.2.3 Enabling an arena
When a sign has been set, it won't work. This because an arena must be enabled manually via  
`arena_lib.enable_arena(sender, mod, arena_name)` or by using the Enable and Leave button in the editor.
If all the conditions are met, you'll receive a confirmation. If not, you'll receive the reason why it didn't through and the arena will remain disabled. Conditions are:
* all spawn points set
* sign placed
  
Arenas can be disabled too, via  
`arena_lib.disable_arena(sender, mod, arena_name)` (or by entering the editor, as previously said).  
In order to do that, no game must be taking place in that specific arena.

### 1.3 Arena phases
An arena comes in 4 phases, each one of them linked to a specific function:
* `waiting phase`: it's the queuing process. People hit a sign waiting for other players to play with 
* `loading phase`: it's the pre-match. By default players get teleported in the arena not being able to do anything but jump
* `fighting phase`: the actual game
* `celebration phase`: the after-match. By default people stroll around for the arena knowing who won, waiting to be teleported

The 4 functions, intertwined with the previously mentioned phases are:
* `arena_lib.load_arena(mod, arena_ID)`: between the waiting and the loading phase. Called when the queue timer reaches 0, it teleports people inside.
* `arena_lib.start_arena(mod_ref, arena)`: between the loading and the fighting phase. Called when the loading phase timer reaches 0.
* `arena_lib.load_celebration(mod, arena, winner_name)`: between the fighting and the celebration phase. Called when the winning conditions are met. `winner_name` can be both a string and a table (in case of teams)
* `arena_lib.end_arena(mod_ref, mod, arena)`: at the very end of the celebration phase. It teleports people outside the arena

Overriding these functions is not recommended. Instead, there are 4 respective callbacks made specifically to customize the behaviour of the formers, sharing (almost) the same variables. They are called *after* the function they're associated with and by default they are empty, so feel free to override them. They are `on_load`, `on_start`, `on_celebration` and `on_end`, and they are explained later in 2.2.

## 2. Configuration

> Still a TL;DR? Check out the [example file](mod-init.lua.example)

First of all download the mod and put it in your mods folder.

Then, you need to register your minigame in arena_lib, possibly inside the init.lua, via:
```
arena_lib.register_minigame("yourmod", {parameter1, parameter2 etc})
```
"yourmod" is how arena_lib will store your mod inside its storage, and it's also what it needs in order to understand you're referring to that specific mod (that's why almost every `arena_lib` function contains "mod" as a parameter). You'll need it when calling for commands or callbacks.  
The second field, on the contrary, is a table of parameters: they define the very features of your minigame. They are:
* `prefix`: what's going to appear in most of the lines printed by your mod. Default is `[arena_lib]`
* `hub_spawn_point`: where players will be teleported when a match _in your mod_ ends. Default is `{ x = 0, y = 20, z = 0 }`
* `teams`: a table of strings containing teams. If not declared, your minigame won't have teams and the table will be equal to `{-1}`. You can add as many teams as you like, as the number of spawners (and players) will be multiplied by the number of teams (so `max_players = 4` * 3 teams = `max_players = 12`)
* `disabled_damage_types`: a table containing which damage types will be disabled once in a game. Damage types are strings, the same as in reason.type in the [minetest API](https://github.com/minetest/minetest/blob/master/doc/lua_api.txt#L4414)
* `join_while_in_progress`: whether the minigame allows to join an ongoing match. Default is false
* `keep_inventory`: whether to keep players inventories when joining an arena. Default is false
* `show_nametags`: whether to show the players nametags while in game. Default is false
* `show_minimap`: whether to allow players to use the builtin minimap function. Default is false
* `timer`: an eventual timer, in seconds. Default is -1, meaning it's disabled
* `is_timer_incrementing`: whether the timer decreases as in a countdown or increases as in a stopwatch. It doesn't work if timer is -1. Default is false
* `queue_waiting_time`: the time to wait before the loading phase starts. It gets triggered when the minimium amount of players has been reached to start the queue. Default is 10
* `load_time`: the time between the loading state and the start of the match. Default is 3
* `celebration_time`: the time between the celebration state and the end of the match. Default is 3
* `immunity_time`: the duration of the immunity right after respawning. Default is 3
* `immunity_slot`: the slot whereto put the immunity item. Default is 8 (the last slot of the hotbar)
* `properties`: explained down below
* `temp_properties`: same
* `player_properties`: same
* `team_properteis`: same (it won't work if `teams` hasn't been declared)

> Beware: as you noticed, the hub spawn point is bound to the very minigame. In fact, there is no global spawn point as arena_lib could be used even in a survival server that wants to feature just a couple minigames. If you're looking for a hub manager because your goal is to create a full minigame server, have a look at my other mod [Hub Manager](https://gitlab.com/zughy-friends-minetest/hub-manager)

### 2.1 Privileges
* `arenalib_admin`: allows to use the `/kick` command

### 2.2 Commands
A couple of general commands are already declared inside arena_lib, them being: 
* `/kick player_name`: kicks a player out of an ongoing game. The sender needs the `arenalib_admin` privilege in order to use it
* `/quit`: quits a game

Those aside, you need to connect a few functions with your mod in order to use them. The best way is with commands and again I suggest you the [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy. [This](https://gitlab.com/zughy-friends-minetest/minetest-quake/-/blob/master/commands.lua) is what I came up with in my Quake minigame, which relies on arena_lib. As you can see, I declared a `local mod = "quake"` at the beginning, because it's how I stored my mod inside the library. Also, I created the support for both the editor and the chat commands.

### 2.3 Callbacks
To customise your mod even more, there are a few empty callbacks you can use. They are:
* `arena_lib.on_load(mod, function(arena)` (we saw these 4 earlier)
* `arena_lib.on_start(mod, function(arena))`
* `arena_lib.on_celebration(mod, function(arena, winner_name)`
* `arena_lib.on_end(mod, function(arena, players))`
* `arena_lib.on_join(mod, function(p_name, arena))`: called when a player joins an ongoing match
* `arena_lib.on_death(mod, function(arena, p_name, reason))`: called when a player dies
* `arena_lib.on_timer_tick(mod, function(arena))`: called every second inside the arena if there is a timer and it's greater than 0
* `arena_lib.on_timeout(mod, function(arena))`: called when the timer of an arena, if exists, reaches 0
* `arena_lib.on_eliminate(mod, function(arena, p_name))`: called when a player is eliminated (see `arena_lib.remove_player_from_arena(...)`)
* `arena_lib.on_kick(mod, function(arena, p_name))`: called when a player is kicked from a match (same as above)
* `arena_lib.on_quit(mod, function(arena, p_name))`: called when a player quits from a match (same as above)
* `arena_lib.on_prequit(mod, function(arena, p_name))`: called when a player tries to quit. If it returns false, quit is cancelled. Useful ie. to ask confirmation first, or simply impede a player to quit
* `arena_lib.on_disconnect(mod, function(arena, p_name))`: called when a player disconnects while in a match

> Beware: there is a default behaviour already for most of these situations: for instance when a player dies, its deaths increase by 1. These callbacks exist just in case you want to add some extra behaviour to arena_lib's.

So for instance, if we want to add an object in the first slot when a player joins the pre-match, we can simply do:

```
arena_lib.on_load("mymod", function(arena)

  local item = ItemStack("default:dirt")

  for pl_name, stats in pairs(arena.players) do
    pl_name:get_inventory():set_stack("main", 1, item)
  end

end)
```

### 2.4 Additional properties
Let's say you want to add a kill leader parameter. `Arena_lib` doesn't provide specific parameters, as its role is to be generic. Instead, you can create your own kill leader parameter by using the four tables `properties`, `temp_properties`, `player_properties` and `team_properties`. The first two are for the arena, the third is for players and the fourth for teams.  

#### 2.4.1 Arenas properties
The difference between `properties` and `temp_properties` is that the former will be stored by the the mod so that when the server reboots it'll still be there, while the latter won't and it's reset every time a match ends. So in our case, we don't want the kill leader to be stored outside the arena, thus we go to our `arena_lib.register_minigame(...)` and write
```
arena_lib.register_minigame("mymod", {
  --whatever stuff we already have
  temp_properties = {
    kill_leader = ""
  }
}
```
and then we can easily access the `kill_leader` field whenever we want from every arena we have, via `theactualarena.kill_leader`, like when creating a function that returns the kill leader of a given arena.

> Beware: you DO need to initialise your properties (whatever type) or it'll return an error

##### 2.4.1.1 Updating properties for old arenas
If you decide to add a new property (temporary or not) to your mod but you had created a few arenas already, you need to update them manually by calling  
`arena_lib.update_properties("mymod")`  
right after `arena_lib.register_minigame(...)`. This has to be done manually because it'd be quite heavy to run a check on hypotetically very long strings whenever the server goes online for each mod relying on `arena_lib`. So just add it, run the server, shut it down when it's done loading, remove the call and then you're good to go.

#### 2.4.2 Players properties
These are a particular type of temporary properties, as they're attached to every player in the arena. Let's say you now want to keep track of how many kills a player does in a streak without dying. You just need to create a killstreak parameter, declaring it like so
```
arena_lib.register_minigame("mymod", {
  --stuff
  temp_properties = {
    kill_leader = ""
  },
  player_properties = {
    killstreak = 0
  }
}
```

Now you can easily access the `killstreak` parameter by retrieving the player inside an arena. Also, don't forget to reset it when a player dies via the `on_death` callback we saw earlier:
```
arena_lib.on_death("mymod", function(arena, p_name, reason)
  arena.players[p_name].killstreak = 0
end)

```

#### 2.4.3 Team properties
Same as above, but for teams. For instance, you could count how many rounds of a single match has been won by a specific team, and then call a load_celebration when one of them reaches 3 wins.

Check out [this example](mod-init.lua.example) for a full configuration file

#### 2.5 HUD
`arena_lib` also comes with a double practical HUD: `broadcast` and `hotbar`. These HUDs only appear when a message is sent to them and they can be easily used via the following commands:
* `arena_lib.HUD_send_msg(HUD_type, p_name, msg, <duration>, <sound>)`: send a message to the specified player in the specified HUD type ("broadcast" or "hotbar"). If no duration is declared, it won't disappear by itself. If a sound is declared, it'll be played at the very showing of the HUD
* `arena_lib.HUD_send_msg_all(HUD_type, arena, msg, <duration>, <sound>)`: same as above, but for all the players inside the arena
* `arena_lib.HUD_hide(HUD_type, player_or_arena)`: it makes the specified HUD disappear; it can take both a player than a whole arena. Also, a special parameter `all` can be used in `HUD_type` to make both the HUDs disappear

### 2.6 Utils
There are also some other functions which might turn useful. They are:
* `arena_lib.is_player_in_queue(p_name, <mod>)`: returns a boolean. If a mod is specified, returns true only if it's inside a queue of that specific mod
* `arena_lib.is_player_in_arena(p_name, <mod>)`: returns a boolean. Same as above
* `arena_lib.is_player_in_same_team(arena, p_name, t_name)`: compares two players teams by the players names. Returns true if on the same team, false if not
* `arena_lib.is_team_declared(mod_ref, team_name)`: returns true if there is a team called `team_name`. Otherwise it returns false
* `arena_lib.remove_player_from_arena(p_name, <reason>)`: removes the player from the arena and it brings back the player to the lobby if still online. Reason is an int, and if specified equals to...
  * `0`: player disconnected. Calls `on_disconnect`
  * `1`: player eliminated. Calls `on_eliminate`
  * `2`: player kicked. Calls `on_kick`
  * `3`: player quit. Calls `on_quit`
Default is 0 and these are mostly hardcoded in arena_lib already, so it's advised to not touch it and to use callbacks. The only exception is in case of manual elimination (ie. in a murder minigame, so reason = 1)
* `arena_lib.send_message_players_in_arena(arena, msg)`: send a message to all the players in that specific arena
* `arena_lib.teleport_in_arena(sender, mod, arena_name)`: teleport the sender into the arena if at least one spawner has been set
* `arena_lib.immunity(player)`: grants immunity to the specified player. It lasts till the `immunity_time` declared in `arena_lib.register_minigame`

### 2.7 Getters
* `arena_lib.get_arena_by_name(mod, arena_name)`: returns the ID and the whole arena (so a table)
* `arena_lib.get_players_in_game()`: returns all the players playing in whatever arena of whatever minigame
* `arena_lib.get_players_in_team(arena, team_ID, <to_players>)`: returns a table containing either the name of the players in the specified team or the players theirselves if to_player is true
* `arena_lib.get_mod_by_player(p_name)`: returns the minigame a player's in (game or queue)
* `arena_lib.get_arena_by_player(p_name)`: returns the arena the player's in, (game or queue)
* `arena_lib.get_arenaID_by_player(p_name)`: returns the ID of the arena the player's playing in
* `arena_lib.get_queueID_by_player(p_name)`: returns the ID of the arena the player's queueing for
* `arena_lib.get_arena_spawners_count(arena, <team_ID>)`: returns the total amount of spawners declared in the specified arena. If team_ID is specified, it only counts the ones belonging to that team
* `arena_lib.get_random_spawner(arena, <team_ID>)`: returns a random spawner declared in the specified arena. If team_ID is specified, it only considers the ones belonging to that team

### 2.7 Things you don't want to do with a light heart
* Changing the number of the teams: it'll delete your spawners (this has to be done in order to avoid further problems)

## 3. Collaborating
Something's wrong? Feel free to:
* open an [issue](https://gitlab.com/zughy-friends-minetest/arena_lib/-/issues)
* submit a merge request. In this case, PLEASE, do follow milestones and my [coding guidelines](https://cryptpad.fr/pad/#/2/pad/view/-l75iHl3x54py20u2Y5OSAX4iruQBdeQXcO7PGTtGew/embed/). I won't merge features for milestones that are different from the upcoming one (if it's declared), nor messy code
* contact me on the [Minetest Forum](https://forum.minetest.net/memberlist.php?mode=viewprofile&u=26472)

I'd really appreciate it :)

## 4. About the author(s)
I'm Zughy (Marco), a professional Italian pixel artist who fights for FOSS and digital ethics. If this library spared you a lot of time and you want to support me somehow, please consider donating on [LiberaPay](https://liberapay.com/Zughy/). Also, this project wouldn't have been possible if it hadn't been for some friends who helped me testing through: `SonoMichele`, `_Zaizen_` and `Xx_Crazyminer_xX`

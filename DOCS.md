# Arena_lib docs

> You in a hurry? Skip the theory going to point [#2](#2-configuration)

## 1. Arenas
It all starts with a table called `arena_lib.mods = {}`. This table allows `arena_lib` to be subdivided per mod and it has different parameters, one being `arena_lib.mods[yourmod].arenas`. Here is where every new arena created gets put.  
An arena is a table having as a key an ID and as a value its parameters. They are:
* `name`: (string) the name of the arena, declared when creating it
* `sign`: (pos) the position of the sign associated with the arena.
* `players`: (table) where to store players
* `players_amount`: (int) separately stores how many players are inside the arena/queue
* `max_players`: (string) default is 4
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
* `arena_lib.set_spawner(sender, mod, arena_name, spawner_ID)`
* `arena_lib.set_sign(sender, mod, arena_name)`

#### 1.2.1 Spawners
`arena_lib.set_spawner(sender, arena_name, spawner_ID)` creates a spawner where the sender is standing, so be sure to stand where you want the spawn point to be.  
`spawner_ID` is optional and it does make a difference: with it, it overrides an existing spawner (if exists), without it, it creates a new one. Spawners can't exceed the maximum players of an arena and, more specifically, the must be the same number.  
I suggest you using [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy and connect the `set_spawner` function to two separate subcommands such as:

```

local mod = "mymod" --more about this later

ChatCmdBuilder.new("NAMEOFYOURCOMMAND", function(cmd)

    cmd:sub("setspawn :arena", function(sender, arena)
        arena_lib.set_spawner(sender, mod, arena)
      end)

      cmd:sub("setspawn :arena :spawnID:int", function(sender, arena, spawn_ID)
          arena_lib.set_spawner(sender, mod, arena, spawn_ID)
        end)

   [etc.]
```

#### 1.2.2 Signs
`arena_lib.set_sign(sender, mod, arena_name)` gives the player an item to hit a sign with. There must be one and one only sign for arena, and when hit it becomes the access to the arena.

#### 1.2.3 Enabling an arena
When a sign has been set, it won't work. This because an arena must be enabled manually via  
`arena_lib.enable_arena(sender, mod, arena_ID)`  
If all the conditions are met, you'll receive a confirmation. If not, you'll receive a reason and the arena will remain disabled. Conditions are:
* all spawn points set
* sign placed
  
Arenas can be disabled too, via  
`arena_lib.disable_arena(sender, mod, arena_ID)`  
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
* `arena_lib.load_celebration(mod, arena, winner_name)`: between the fighting and the celebration phase. Called when the winning conditions are met.
* `arena_lib.end_arena(mod_ref, mod, arena)`: at the very end of the celebration phase. It teleports people outside the arena

Overriding these functions is not recommended. Instead, there are 4 respective callbacks made specifically to customize the behaviour of the formers, sharing (almost) the same variables. They are called *after* the function they're associated with and by default they are empty, so feel free to override them. They are `on_load`, `on_start`, `on_celebration` and `on_end`, and they are explained later in 2.2.

## 2. Configuration

> Still a TL;DR? Check out the [example file](mod-init.lua.example)

First of all download the mod and put it in your mods folder.

Then, you need to initialise the mod for each mod you want to feature arena_lib in, inside the init.lua via:
```
arena_lib.initialize("yourmod")
```
**Be careful**: the string you put inside the round brackets will be how arena_lib stores your mod inside its memory and what it needs in order to understand you're referring to that specific mod (that's why almost every function contains "mod" as a parameter). You'll need it when calling for commands.

To customise your mod, you can then call `arena_lib.settings`, specifying the mod name as follows:
```
arena_lib.settings("mymod", {
  --whatever parameter, such as
  -- prefix = "[mymode] ",
})
```
The parameters are:
* `prefix`: what's gonna appear in most of the lines printed by your mod. Default is `[arena_lib] `
* `hub_spawn_point`: where players will be teleported when a match _in your mod_ ends. Default is `{ x = 0, y = 20, z = 0 }`
* `join_while_in_progress`: whether the minigame allows to join an ongoing match. Default is false
* `show_nametags`: whether to show the players nametags while in game. Default is false
* `show_minimap`: whether to allow players to use the builtin minimap function. Default is false
* `queue_waiting_time`: the time to wait before the loading phase starts. It gets triggered when the minimium amount of players has been reached to start the queue. Default is 10
* `load_time`: the time between the loading state and the start of the match. Default is 3
* `celebration_time`: the time between the celebration state and the end of the match. Default is 3
* `immunity_time`: the duration of the immunity right after respawning. Default is 3
* `immunity_slot`: the slot whereto put the immunity item. Default is 9 (the first slot of the inventory minus the hotbar)
* `properties`: explained down below
* `temp_properties`: same
* `player_properties`: same

On the contrary, to customise the _global_ spawn point of your hub, meaning where to spawn players when they join the server, you need to edit the line  
`local hub_spawn_point = { x = 0, y = 20, z = 0}`  
in api.lua, inside the arena_lib folder.

### 2.1 Commands
You need to connect the functions of the library with your mod in order to use them. The best way is with commands and again I suggest you the [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy. [This](https://gitlab.com/zughy-friends-minetest/minetest-quake/-/blob/master/commands.lua) is what I came up with in my Quake minigame, which relies on arena_lib. As you can see, I declared a `local mod = "quake"` at the beginning, because it's how I stored my mod inside the library.

### 2.2 Callbacks
To customise your mod even more, there are a few empty callbacks you can use. They are:
* `arena_lib.on_load(mod, function(arena)` (we saw these 4 earlier)
* `arena_lib.on_start(mod, function(arena))`
* `arena_lib.on_celebration(mod, function(arena, winner_name)`
* `arena_lib.on_end(mod, function(arena, players))`
* `arena_lib.on_join(mod, function(p_name, arena))`: called when a player joins an ongoing match
* `arena_lib.on_death(mod, function(arena, p_name, reason))`: called when a player dies

Beware: there is a default behaviour already for each one of these situations: for instance when a player dies, its deaths increase by 1. These callbacks exist just in case you want to add some extra behaviour to arena_lib's.

So for instance, if we want to add an object in the first slot when a player joins the pre-match, we can simply do:

```
arena_lib.on_load("mymod", function(arena)

  local item = ItemStack("default:dirt")

  for pl_name, stats in pairs(arena.players) do
    pl_name:get_inventory():set_stack("main", 1, item)
  end

end)
```

### 2.3 Additional properties
Let's say you want to add a kill leader parameter. `Arena_lib` doesn't provide specific parameters, as its role is to be generic. Instead, you can create your own kill leader parameter by using the three tables `properties`, `temp_properties` and `player_properties`. The last one is for players, while the others are for the arena.  

#### 2.3.1 Arenas properties
The difference between `properties` and `temp_properties` is that the former will be stored by the the mod so that when the server reboots it'll still be there, while the latter won't and it's reset every time a match ends. So in our case, we don't want the kill leader to be stored outside the arena, thus we go to our `arena_lib.settings` and write
```
arena_lib.settings("mymod", {
  --whatever stuff we already have
  temp_properties = {
    kill_leader = " "
  }
}
```
and then we can easily access the `kill_leader` field whenever we want from every arena we have, via `theactualarena.kill_leader`, like when creating a function that returns the kill leader of a given arena.

> Beware: you DO need to initialise your properties (whatever type) or it'll return an error

##### 2.3.1.1 Updating properties for old arenas
If you decide to add a new property (temporary or not) to your mod but you had created a few arenas already, you need to update them manually by calling  
`arena_lib.update_properties("mymod")`  
right after `arena_lib.settings`. This has to be done manually because it'd be quite heavy to run a check on hypotetically very long strings whenever the server goes online for each mod relying on `arena_lib`. So just add it, run the server, shut it down when it's done loading, remove the call and then you're good to go.

#### 2.3.2 Players properties
These are a particular type of temporary properties, as they're attached to every player in the arena. Let's say you now want to keep track of how many kills a player does in a streak without dying. You just need to create a killstreak parameter, declaring it like so
```
arena_lib.settings("mymod", {
  --stuff
  temp_properties = {
    kill_leader = " "
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

Check out [this example](mod-init.lua.example) for a full configuration file

#### 2.4 HUD
`arena_lib` also comes with a double practical HUD: `broadcast` and `hotbar`. These HUDs only appear when a message is sent to them and they can be easily used via the following commands:
* `arena_lib.HUD_send_msg(HUD_type, p_name, msg, <duration>, <sound>)`: send a message to the specified player in the specified HUD type ("broadcast" or "hotbar"). If no duration is declared, it won't disappear by itself. If a sound is declared, it'll be played at the very showing of the HUD
* `arena_lib.HUD_send_msg_all(HUD_type, arena, msg, <duration>, <sound>)`: same as above, but for all the players inside the arena
* `arena_lib.HUD_hide(HUD_type, player_or_arena)`: it makes the specified HUD disappear; it can take both a player than a whole arena. Also, a special parameter `all` can be used in `HUD_type` to make both the HUDs disappear

### 2.5 Utils
There are also some other functions which might turn useful. They are:
* `arena_lib.is_player_in_queue(p_name, <mod>)`: returns a boolean. If a mod is specified, returns true only if it's inside a queue of that specific mod
* `arena_lib.is_player_in_arena(p_name, <mod>)`: returns a boolean. Same as above
* `arena_lib.remove_player_from_arena(p_name, is_eliminated)`: if is_eliminated is not specified, other players will see that the player has left the match. If it is (true), the message will say the player has been eliminated. The latter comes in handy for games like Murder or TNT Run
* `arena_lib.send_message_players_in_arena(arena, msg)`: send a message to all the players in that specific arena
* `arena_lib.immunity(player)`: grants immunity to the specified player. It lasts till the `immunity_time` declared in `arena_lib.settings`

## 3. Collaborating
Something's wrong? Feel free to:
* open an issue
* submit a merge request. In this case, PLEASE, do follow milestones. I won't merge features for milestones that are different from the upcoming one (if it's declared)
* contact me on the [Minetest Forum](https://forum.minetest.net/memberlist.php?mode=viewprofile&u=26472)

I'd really appreciate it :)

## 4. About the author(s)
I'm Zughy (Marco), a professional Italian pixel artist who fights for FOSS and digital ethics. If this library spared you a lot of time and you want to support me somehow, please consider donating on [LiberaPay](https://it.liberapay.com/EticaDigitale/) directly to my educational Italian project (because not everyone speaks English and Italian media don't talk about these topics much). Also, this project wouldn't have been possible if it hadn't been for some friends who helped me testing through: `SonoMichele`, `_Zaizen_` and `Xx_Crazyminer_xX`

# Arena_lib docs

> Arena_lib is a library for Minetest working as a core for any arena-like minigame you have in mind

## Preamble

Let's start by addressing the elephant in the room: "why not creating a separate mod instead of an API for devs? It sounds complicated"  
  
Unfortunately creating a separate mod containing a system which stores every mod in a different table to be put inside the storage is a giant headache and not the best thing when it comes to performance. For instance, let's say you want to customize what happens when a player respawns and you have three different minigames relying on arena_lib: specifically, you want to override the respawn behaviour of only ONE of your minigames. But, well, if you do override the respawn event, every minigame will be affected because they depend on the same mod. So you could create a different list for exceptions in case an event gets called... for every possible event. And iterate not only for each mod you have, but also for every exception. Every time someone respawns. Or dies. Or joins. Or leaves. Or, well, you got it. Sounds fun, right? :^))))  
I tried making the files as clear as possible, separating sections and writing down this separate English markdown file. Also, yes, comments inside the scripts are in Italian because I prefer to focus on the code rather than do an additional, however small, effort to think in another language (AKA I'm Italian). Love you long time, hope it'll be useful to someone.  
  

## 1. Arenas
It all starts with a table called `arena_libs.arenas = {}`. Here is where every new arena created gets put.  
An arena is a table having as a key an ID and as a value its parameters. They are:
* `name`: (string) the name of the arena, declared when creating it
* `sign`: (pos) the position of the sign associated with the arena.
* `players`: (table) where to store players
* `max_players`: (string) default is 4
* `min_players`: (string) default is 2. When this value is reached, a queue starts
* `kill_cap`: (int) the goal to win (it'll be expanded for games such as Capture the point)
* `kill_leader`: (string) who's the actual kill leader
* `in_queue`: (bool) about phases, look at "Arena phases" down below
* `in_loading`: (bool)
* `in_game`: (bool)
* `in_celebration`: (bool)
* `enabled`: (bool) by default an arena is disabled, to avoid any damage

Being arenas stored by ID, they can be easily retrieved by `arena_libs.arenas[THEARENAID]`.  

There are two ways to know an arena ID: the first is in-game via the two debug utilities:
* `arena_lib.print_arenas(sender)`: coincise
* `arena_lib.print_arena_info(sender, arena_name)`: extended with much more information

The second is via code by the function `arena_libs.get_arenaID_by_player(p_name)`.  
(Trivia: this function does NOT iterate between areas; instead, there is a local table called `players_in_game` which takes a player name as a key and the arena ID they're in as an index. So it simply returns `players_in_game[p_name]`)

### 1.1 Creating and removing arenas
There are two functions for it and they all need to be connected to some command in your mod. The functions are
* `arena_lib.create_arena(sender, arena_name)`: it doesn't accept duplicates. Sender is a string 
* `arena_lib.remove_arena(arena_name)`: if a game is taking place in it, it won't go through

#### 1.1.1 Storing arenas
Arenas and their settings are stored inside the mod storage. What is *not* stored are players, their stats and such.  
Better said, these kind of parameters are emptied every time the server starts. And not when it ends, because handling situations like crashes is simply not possible.
  
### 1.2 Setting up an arena
Two things are needed to have an arena up to go: spawners and signs. There are two functions for that:  
* `arena_lib.set_spawner(sender, arena_name, spawner_ID)`
* `arena_lib.set_sign(sender, arena_name)`

#### 1.2.1 Spawners
`arena_lib.set_spawner(sender, arena_name, spawner_ID)` creates a spawner where the sender is standing, so be sure to stand where you want the spawn point to be.  
`spawner_ID` is optional and it does make a difference: with it, it overrides an existing spawner (if exists), without it, it creates a new one. Spawners can't exceed the maximum players of an arena and, more specifically, the must be the same number.  
I suggest you using [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy and connect the `set_spawner` function to two separate subcommands such as:

```
ChatCmdBuilder.new("NAMEOFYOURCOMMAND", function(cmd)

    cmd:sub("setspawn :arena", function(name, arena)
        arena_lib.set_spawner(name, arena)
      end)

      cmd:sub("setspawn :arena :spawnID:int", function(name, arena, spawn_ID)
          arena_lib.set_spawner(name, arena, spawn_ID)
        end)

   [etc.]
```

#### 1.2.2 Signs
`arena_lib.set_sign(sender, arena_name)` gives the player an item to hit a sign with. There must be one and one only sign for arena, and when hit it becomes the access to the arena.

#### 1.2.3 Enabling an arena
When a sign has been set, it won't work. This because an arena must be enabled manually via  
`arena_lib.enable_arena(sender, arena_ID)`  
If all the conditions are met, you'll receive a confirmation. If not, you'll receive a reason and the arena will remain disabled. The only reason right now is not having set all the spawners.  
  
Arenas can be disabled too, via  
`arena_lib.disable_arena(sender, arena_ID)`  
In order to do that, no game must be taking place.  

### 1.3 Arena phases
An arena comes in 4 phases, each one of them linked to a specific function:
* `waiting phase`: it's the queuing process. People hit a sign waiting for other players to play with 
* `loading phase`: it's the pre-match. By default players get teleported in the arena not being able to do anything but jump
* `fighting phase`: the actual game
* `celebration phase`: the after-match. By default people stroll around for the arena knowing who won, waiting to be teleported

The 4 functions, intertwined with the previously mentioned phases are:
* `arena_lib.load_arena(arena_ID)`: between the waiting and the loading phase. Called when the queue timer reaches 0, it teleports people inside.
* `arena_lib.start_arena(arena)`: between the loading and the fighting phase. Called when the loading phase timer reaches 0.
* `arena_lib.load_celebration(arena_ID, winner_name)`: between the fighting and the celebration phase. Called when the winning conditions are met.
* `arena_lib.end_arena(arena)`: at the very end of the celebration phase. It teleports people outside the arena

Overriding these functions is not recommended. Instead, there are 4 respective functions made specifically to customize the behaviour of the formers, sharing the same variables. They are called *after* the function they're associated with and by default they are empty, so feel free to override them. They are:
* `arena_lib.on_load(arena_ID)` 
* `arena_lib.on_start(arena)`
* `arena_lib.on_celebration(arena_ID, winner_name)`
* `arena_lib.on_end(arena, players)`

So for example if we want to add an object in the first slot when they join the pre-match, we can simply do:

```
function arena_lib.on_load(arena_ID)

  local arena = arena_lib.arenas[arena_ID]
  local item = ItemStack("default:dirt")

  for pl_name, stats in pairs(arena.players) do
    pl_name:get_inventory():set_stack("main", 1, item)
  end

end
```

## 2. Configuration

First of all follow the basic README.md instructions, adding the content of the library inside a folder called `arena_lib` INSIDE your mod (beware of the textures) and adding this line in your `init.lua`.  
`dofile(minetest.get_modpath("YOURMODNAME") .. "/arena_lib/api.lua")`  

Then, to better config the library, go in your `init.lua` and call the `arena_lib.settings` function.
The parameters are:
* `prefix`: what's gonna appear in most of the lines printed by your mod. Default is `[arena_lib] `
* `hub_spawn_point`: where players will be teleported when a match ends and when they reconnect. Default is `{ x = 0, y = 20, z = 0 }`
* `load_time`: the time between the loading state and the start of the match. Default is 3
* `celebration_time`: the time between the celebration state and the end of the match. Default is 3
* `immunity_time`: the duration of the immunity right after respawning. Default is 3
* `immunity_slot`: the slot whereto put the immunity item. Default is 9 (the first slot of the inventory minus the hotbar)

### 2.1 Commands
You need to connect the functions of the library with your mod in order to use them. The best way is with commands and again I suggest you the [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy. [This](https://gitlab.com/zughy-friends-minetest/minetest-quake/-/blob/master/commands.lua) is what I came up with in my Quake minigame, which relies on arena_lib.

## 3. Collaborating
Something's wrong? Feel free to open an issue, go for a pull request and whatnot. I'd really appreciate it :)

## 4. About the author(s)
I'm Zughy (Marco), a professional Italian pixel artist who fights for FOSS and digital ethics. If this library spared you a lot of time and you want to support me somehow, please consider donating on [LiberaPay](https://it.liberapay.com/EticaDigitale/) directly to my educational Italian project (because not everyone speaks English and Italian media don't talk about these topics much). Also, this project wouldn't have been possible if it hadn't been for some friends who helped me testing through: `SonoMichele`, `_Zaizen_` and `Xx_Crazyminer_xX`

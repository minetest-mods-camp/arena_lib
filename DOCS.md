# Arena_lib docs

>> Arena_lib is a library for Minetest working as a core for any arena-like minigame you have in mind. The doc is NOT finished yet

## Preamble

Let's start addressing the elephant in the room: "why not creating a separate mod instead of an API for devs? It sounds complicated"  
  
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

Being arenas stored by ID, they can be easily retrieved by `arena_libs.arenas[THEARENAID]`. And to retrieve the ID, there is a handy function called `arena_libs.get_arenaID_by_player(p_name)`. (Trivia: this function does NOT iterate between areas; instead, there is a local table called `players_in_game` which takes a player name as a key and the arena ID they're in as an index. So it simply return `players_in_game[p_name]`)

### 1.1 Creating and removing arenas
There are two functions for it and they all need to be connected to some command in your mod. The functions are
* `arena_lib.create_arena(sender, arena_name)`: it doesn't accept duplicates. Sender is a string 
* `arena_lib.remove_arena(arena_name)`: if a game is taking place in it, it won't go through

##### 1.1.1 Storing arenas
Arenas and their settings are stored inside the mod storage. What is *not* stored are players, their stats and such  
  
### 1.2 Setting up an arena
TODO  
TODO  setting spawners, signs
TODO  

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

Overriding these functions it's not recommended. Instead, there are 4 respective functions made specifically to customize the behaviour of the formers, sharing the same variables. They are called *after* the function they're associated with and by default they are empty, so feel free to override them. They are:
* `arena_lib.on_load(arena_ID)` 
* `arena_lib.on_start(arena)`
* `arena_lib.on_celebration(arena_ID, winner_name)`
* `arena_lib.on_end(arena)`

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

## Configuration

To config the library, go in your `init.lua` and call the `arena_lib.settings` function.
The parameters are:
* `prefix`: what's gonna appear in most of the lines printed by your mod. Default is `[arena_lib] `
* `load_time`: the time between the loading state and the start of the match. Default is 3
* `celebration_time`: the time between the celebration state and the end of the match. Default is 3
* `immunity_time`: the duration of the immunity right after respawning. Default is 3
* `immunity_slot`: the slot whereto put the immunity item. Default is 9 (the first slot of the inventory minus the hotbar)


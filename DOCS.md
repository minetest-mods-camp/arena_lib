# Arena_lib docs

# Table of Contents
* [1. Minigame configuration](#1-minigame-configuration)
	* [1.1 Per server configuration](#11-per-server-configuration)
	* [1.2 Privileges](#12-privileges)
	* [1.3 Commands](#13-commands)
		* [1.3.1 Admins only](#131-admins-only)
	* [1.4 Callbacks](#14-callbacks)
	* [1.5 Additional properties](#15-additional-properties)
		* [1.5.1 Arena properties](#151-arena-properties)
			* [1.5.1.1 Updating non temporary properties via code](#1511-updating-non-temporary-properties-via-code)
			* [1.5.1.2 Updating properties for old arenas](#1512-updating-properties-for-old-arenas)
		* [1.5.2 Player properties](#152-player-properties)
		* [1.5.3 Team properties](#153-team-properties)
	* [1.6 HUD](#16-hud)
	* [1.7 Extendable editor](#17-extendable-editor)
	* [1.8 Utils](#18-utils)
	* [1.9 Getters](#19-getters)
	* [1.10 Things you don't want to do with a light heart](#110-things-you-dont-want-to-do-with-a-light-heart)
	* [1.11 Example file](#111-example-file)
* [2. Arenas](#2-arenas)
	* [2.1 Creating and removing arenas](#21-creating-and-removing-arenas)
		* [2.1.1 Storing arenas](#211-storing-arenas)
		* [2.1.2 Renaming an arena](#212-renaming-an-arena)
	* [2.2 Setting up an arena](#22-setting-up-an-arena)
		* [2.2.1 Editor](#221-editor)
		* [2.2.2 CLI](#222-cli)
			* [2.2.2.1 Players management](#2221-players-management)
			* [2.2.2.2 Enabling/Disabling teams](#2222-enablingdisabling-teams)
			* [2.2.2.3 Timers](#2223-timers)
			* [2.2.2.4 Arena properties](#2224-arena-properties)
			* [2.2.2.5 Spawners](#2225-spawners)
			* [2.2.2.6 Signs](#2226-signs)
			* [2.2.2.7 Music](#2227-music)
		* [2.2.3 Enabling an arena](#223-enabling-an-arena)
	* [2.3 Arena phases](#23-arena-phases)
	* [2.4 Spectate mode](#24-spectate-mode)
* [3. About the author(s)](#3-about-the-authors)

## 1. Minigame configuration

First of all download the mod and put it in your mods folder. Then, be sure you have [LuaJIT](https://luajit.org/) installed on your machine.

Now you need to register your minigame, possibly inside the init.lua of your mod, via:
```
arena_lib.register_minigame("yourmod", {parameter1, parameter2 etc})
```
"yourmod" is how arena_lib will store your mod inside its storage, and it's also what it needs in order to understand you're referring to that specific minigame (that's why almost every `arena_lib` function contains "mod" as a parameter). You'll need it when calling for commands and callbacks. **Use the same name you used in mod.conf or some features won't be available**.  
The second field, on the contrary, is a table of optional parameters: they define the very features of your minigame. They are:
* `prefix`: (string) what's going to appear in most of the lines printed by your mod. Default is `[Arena_lib] `
* `teams`: (table) contains team names. If not declared, your minigame won't have teams and the table will be equal to `{-1}`. You can add as many teams as you like, as the number of spawners (and players) will be multiplied by the number of teams (so `max_players = 4` * 3 teams = `max_players = 12`)
* `teams_color_overlay`: (table) [color strings](https://drafts.csswg.org/css-color/#named-colors). It applies a color overlay onto the players' skin according to their team, to better distinguish them. It requires `teams`. Default is `nil`
* `is_team_chat_default`: (bool) whether players messages in a game should be sent to their teammates only. It requires `teams`, default is false
* `chat_all_prefix`: (string) prefix for every message sent in arena, team chat aside. Default is `[arena] ` (geolocalised)
* `chat_team_prefix`: (string) prefix for every message sent in the team chat. Default is `[team] ` (geolocalised)
* `chat_spectate_prefix`: (string) prefix for every message sent in the spectate chat. Default is `[spectator]` (geolocalised)
* `chat_all_color`: (string) color for every message sent in arena, team chat aside. Default is white (`"#ffffff"`)
* `chat_team_color`: (string) color for every message sent in the team chat. Default is light sky blue (`"#ddfdff"`)
* `chat_spectate_color`: color for every message sent in the spectate chat. Default is gray (`"#dddddd"`)
* `fov`: (int) changes the fov of every player
* `camera_offset`: (table) changes the offset of the camera for evey player. It's structured as such: `{1st_person, 3rd_person}`, e.g. `{nil, {x=5, y=3, z=-4}}`
* `hotbar`: (table) overrides the server hotbar while inside an arena. Its fields are:
  * `slots =`: (int) the number of slots
  * `background_image =`: (string) the background image
  * `selected_image =`: (string) the image to show when a slot is selected  
  If a field is not declared, it'll keep the server defaults
* `join_while_in_progress`: (bool) whether the minigame allows to join an ongoing match. Default is `false`
* `spectate_mode`: (bool) whether the minigame features the spectator mode. Default is `true`
* `keep_inventory`: (bool) whether to keep players inventories when joining an arena. Default is `false`. Check out also `STORE_INVENTORY_MODE` in `SETTINGS.lua`, to choose whether and how to store players' inventory
* `show_nametags`: (bool) whether to show the players nametags while in game. Default is `false`
* `show_minimap`: (bool) whether to allow players to use the builtin minimap function. Default is `false`
* `time_mode`: (string) whether arenas will keep track of the time or not.
  * `"none"`: no time tracking at all (default)
  * `"incremental"`: incremental time (0, 1, 2, ...)
  * `"decremental"`: decremental time, as in a timer (3, 2, 1, 0). The timer value is 300 seconds by default, but it can be changed per arena
* `load_time`: (int) the time in seconds between the loading state and the start of the match. Default is `5`
* `celebration_time`: (int) the time in seconds between the celebration state and the end of the match. Default is `5`
* `in_game_physics`: (table) a physical override to set to each player when they enter an arena, following the Minetest `physics_override` parameters
* `disabled_damage_types`: (table) contains which damage types will be disabled once in a game. Damage types are strings, the same as in reason.type in the [minetest API](https://github.com/minetest/minetest/blob/master/doc/lua_api.txt)
* `properties`: explained down below
* `temp_properties`: same
* `player_properties`: same
* `team_properties`: same (it won't work if `teams` hasn't been declared)

### 1.1 Per server configuration
There are also a couple of settings that can only be set in game via `/minigamesettings`. This because different servers might need different parameters. They are:
* `hub_spawn_point`: where players will be teleported when a match _in your mod_ ends. Default is `{ x = 0, y = 20, z = 0 }`. A bit of noise is applied on the x and z axis, ranging between `-1.5` and `1.5`.
* `queue_waiting_time`: the time to wait before the loading phase starts. It gets triggered when the minimium amount of players has been reached to start the queue. Default is `10`

> **BEWARE**: as you noticed, the hub spawn point is bound to the very minigame. In fact, there is no global spawn point as arena_lib could be used even in a survival server that wants to feature just a couple minigames. If you're looking for a hub manager because your goal is to create a full minigame server, have a look at my other mod [Hub Manager](https://gitlab.com/zughy-friends-minetest/hub-manager). Also, if you want to be sure to join the same arena/team with your friends, you need to install my other mod [Parties](https://gitlab.com/zughy-friends-minetest/parties)

### 1.2 Privileges
* `arenalib_admin`: allows to use a few more commands

### 1.3 Commands
A couple of general commands are already declared inside arena_lib, them being:

* `/quit`: quits a game
* `/all`: writes in the arena global chat
* `/t`: writes in the arena team chat (if teams are enabled)

#### 1.3.1 Admins only
A couple more are available for players having the `arenalib_admin` privilege:

* `/minigamesettings mod`: change `mod` settings
* `/arenakick player_name`: kicks a player out of an ongoing game, no matter the mod
* `/forceend mod arena_name`: forcibly ends an ongoing game
* `/flusharena mod arena_name`: restores a broken arena (when not in progress)

Those aside, you need to connect a few functions with your mod in order to use them. The best way is with commands and I suggest you [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy. [This](https://gitlab.com/zughy-friends-minetest/block_league/-/blob/master/commands.lua) is what I came up with in my Block League minigame, which relies on arena_lib. As you can see, I declared a `local mod = "block_league"` at the beginning, because it's how I stored my mod inside the library. Also, I created the support for both the editor and the chat commands.

### 1.4 Callbacks
To customise your mod even more, there are a few empty callbacks you can use. They are:
* `arena_lib.on_enable(mod, function(arena, p_name)`: use it to run more checks before enabling an arena. Must return true if all conditions are met
* `arena_lib.on_disable(mod, function(arena, p_name)`: use it to run more checks before disabling an arena. Must return true if all conditions are met
* `arena_lib.on_load(mod, function(arena)`: see [2.3 Arena phases](#23-arena-phases)
* `arena_lib.on_start(mod, function(arena))`: same as above
* `arena_lib.on_celebration(mod, function(arena, winner_name)`: same as above
* `arena_lib.on_end(mod, function(arena, players, winner_name, spectators, is_forced))`: same as above. Players and spectators are given here because `end_arena` deleted them already - hence these are a copy. `is_forced` returns `true` when the match has been forcibly terminated (via `force_arena_ending`)
* `arena_lib.on_join(mod, function(p_name, arena, as_spectator))`: called when a player joins an ongoing match. If `as_spectator` is true, they'll be added as such
* `arena_lib.on_death(mod, function(arena, p_name, reason))`: called when a player dies
* `arena_lib.on_time_tick(mod, function(arena))`: called every second if `time_mode` is different from `"none"`
* `arena_lib.on_timeout(mod, function(arena))`: called when the timer of an arena, if exists (`time_mode = "decremental"`), reaches 0. Not declaring it will make the server crash when time runs out
* `arena_lib.on_eliminate(mod, function(arena, p_name))`: called when a player is eliminated (see `arena_lib.remove_player_from_arena(...)`)
* `arena_lib.on_kick(mod, function(arena, p_name, is_spectator))`: called when a player/spectator is kicked from a match (same as above)
* `arena_lib.on_quit(mod, function(arena, p_name, is_spectator))`: called when a player/spectator quits from a match (same as above)
* `arena_lib.on_prequit(mod, function(arena, p_name))`: called when a player tries to quit. If it returns false, quit is cancelled. Useful to ask confirmation first, or simply to impede a player to quit
* `arena_lib.on_disconnect(mod, function(arena, p_name, is_spectator))`: called when a player/spectator disconnects while in a match

> **BEWARE**: there is a default behaviour already for most of these situations: for instance when a player dies, their deaths increase by 1. These callbacks exist just in case you want to add some extra behaviour to arena_lib's.

So for instance, if we want to add an object in the first slot when a player joins the pre-match, we can simply do:

```
arena_lib.on_load("mymod", function(arena)

  local item = ItemStack("default:dirt")

  for pl_name, stats in pairs(arena.players) do
    pl_name:get_inventory():set_stack("main", 1, item)
  end

end)
```

### 1.5 Additional properties
Let's say you want to add a kill leader parameter. `Arena_lib` doesn't provide specific parameters, as its role is to be generic. Instead, you can create your own kill leader parameter by using the four tables `properties`, `temp_properties`, `player_properties` and `team_properties`. The first two are for the arena, the third is for players and the fourth for teams.  
No matter the type of property, they're all shared between arenas. Better said, their values can change, but there can't be an arena with more or less properties than another.

#### 1.5.1 Arena properties
The difference between `properties` and temp/player/team's is that the former will be stored by the the mod so that when the server reboots it'll still be there, while the others won't and they reset every time a match ends. Everything but `properties` is temporary. In our case, for instance, we don't want the kill leader to be preserved outside of a match, thus we go to our `arena_lib.register_minigame(...)` and write:
```
arena_lib.register_minigame("mymod", {
  --whatever stuff we already have
  temp_properties = {
    kill_leader = ""
  }
}
```
in doing so, we can easily access the `kill_leader` field whenever we want from every arena we have, via `ourarena.kill_leader`. E.g. when creating a function calculating the arena kill leader

> **BEWARE**: you DO need to initialise your properties (whatever type) or it'll return an error

##### 1.5.1.1 Updating non temporary properties via code
Let's say you want to change a property from your mod. A naive approach would be doing `yourarena.property = something`. This, though, won't update it in the storage, so when you restart the server it'll still have the old value.  
Instead, the right way to permanently update a property for an arena is calling `arena_lib.change_arena_property(<sender>, mod, arena_name, property, new_value)`. If `sender` is nil, the output message will be printed in the log.

##### 1.5.1.2 Updating properties for old arenas
This is done automatically by arena_lib every time you change the properties declaration in `register_minigame`, so don't worry. Just, keep in mind that when a property is removed, it'll be removed from every arena; so if you're not sure about what you're doing, do a backup first.

#### 1.5.2 Player properties
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

Now you can easily access the killstreak parameter by retrieving the player inside an arena via `ourarena.players[p_name].killlstreak`. Also, don't forget to reset it when a player dies via the `on_death` callback we saw earlier:
```
arena_lib.on_death("mymod", function(arena, p_name, reason)
  arena.players[p_name].killstreak = 0
end)

```

#### 1.5.3 Team properties
Same as above, but for teams. For instance, you could count how many rounds of a single match has been won by a specific team, and then call a load_celebration when one of them reaches 3 wins.

#### 1.6 HUD
`arena_lib` also comes with a triple practical HUD: `title`, `broadcast` and `hotbar`. These HUDs only appear when a message is sent to them and they can be easily used via the following functions:
* `arena_lib.HUD_send_msg(HUD_type, p_name, msg, <duration>, <sound>, <color>)`: sends a message to the specified player/spectator in the specified HUD type (`"title"`, `"broadcast"` or `"hotbar"`). If no duration is declared, it won't disappear by itself. If a sound is declared, it'll be played at the very showing of the HUD. `color` must be in a hexadecimal format and, if not specified, it defaults to white (`0xFFFFFF`).
* `arena_lib.HUD_send_msg_all(HUD_type, arena, msg, <duration>, <sound>, <color>)`: same as above, but for all the players and spectators inside the arena
* `arena_lib.HUD_hide(HUD_type, player_or_arena)`: makes the specified HUD disappear; it can take both a player/spectator and a whole arena. Also, a special parameter `all` can be used in `HUD_type` to make all the HUDs disappear

#### 1.7 Extendable editor
Since 4.0, every minigame can extend the editor with an additional custom section on the 5th slot. To do that, the function is
```
arena_lib.register_editor_section("yourmod", {parameter1, parameter2 etc})
```
On the contrary of when an arena is registered, every parameter here is mandatory. They are:
* `name`: the name of the item that will represent the section
* `icon`: the icon of the item that will represent the section
* `hotbar_message`: the message that will appear in the hotbar HUD once the section has been opened
* `give_items = function(itemstack, user, arena)`: this function must return the list of items to give to the player once the section has been opened, or nil if we want to deny the access. Having a function instead of a list is useful as it allows to run whatever check inside of it, and to give different items accordingly

When a player is inside the editor, they have 2 string metadata containing the name of the mod and the name of the arena that's currently being modified. These are necessary to do whatever arena operation with items passed via `give_items`, as they allow to obtain the arena ID and the arena itself via `arena_lib.get_arena_by_name(mod, arena_name)`. To better understand this, have a look at how [arena_lib does](https://gitlab.com/zughy-friends-minetest/arena_lib/-/blob/master/_editor/tools_players.lua)


### 1.8 Utils
There are also some other functions which might turn useful. They are:
* `arena_lib.is_player_in_queue(p_name, <mod>)`: returns a boolean. If a mod is specified, returns true only if it's inside a queue of that specific mod
* `arena_lib.is_player_in_arena(p_name, <mod>)`: returns a boolean. Same as above
* `arena_lib.is_player_in_same_team(arena, p_name, t_name)`: compares two players teams by the players names. Returns true if on the same team, false if not
* `arena_lib.is_team_declared(mod_ref, team_name)`: returns true if there is a team called `team_name`. Otherwise it returns false
* `arena_lib.force_arena_ending(mod, arena, <sender>)`: forcibly ends an ongoing game. It's usually called by `/forceend`, but it can be used, for instance, to annul a game. `sender` will inform players about who called the function. It returns `true` if successfully executed
* `arena_lib.remove_player_from_queue(p_name)`: removes the player from the queue is in, if any
* `arena_lib.remove_player_from_arena(p_name, reason, <executioner>)`: removes the player from the arena and it brings back the player to the lobby if still online. Reason is an int, and it equals to...
  * `0`: player disconnected. Calls `on_disconnect`
  * `1`: player eliminated. Calls `on_eliminate` if declared. Otherwise calls `on_quit`
  * `2`: player kicked. Calls `on_kick` if declared. Otherwise calls `on_quit`
  * `3`: player quit. Calls `on_quit`
Default is 0 and these are mostly hardcoded in arena_lib already, so it's advised to not touch it and to use callbacks. The only exception is in case of manual elimination (ie. in a murder minigame, so reason = 1).  
Executioner can be passed to tell who removed the player. By default, this happens when someone uses `/arenakick` and `/forceend`, so that these commands can't be abused without consequences for the admin.
* `arena_lib.send_message_in_arena(arena, channel, msg, <teamID>, <except_teamID>)`: sends a message to all the players/spectators in that specific arena, according to what `channel` is: `"players"`, `"spectators"` or `"both"`. If `teamID` is specified, it'll be only sent to the players inside that very team. On the contrary, if `except_teamID` is `true`, it'll be sent to every player BUT the ones in the specified team. These last two fields are pointless if `channel` is equal to `"spectators"`
* `arena_lib.is_player_spectating(sp_name)`: returns whether a player is spectating a match, as a boolean
* `arena_lib.is_player_spectated(p_name)`: returns whether a player is being spectated
* `arena_lib.is_arena_in_edit_mode(arena_name)`: returns whether the arena is in edit mode or not, as a boolean
* `arena_lib.is_player_in_edit_mode(p_name)`: returns whether a player is editing an arena, as a boolean

### 1.9 Getters
* `arena_lib.get_arena_by_name(mod, arena_name)`: returns the ID and the whole arena (so a table)
* `arena_lib.get_mod_by_player(p_name)`: returns the minigame a player's in (game or queue)
* `arena_lib.get_arena_by_player(p_name)`: returns the arena the player's in, (game or queue)
* `arena_lib.get_arenaID_by_player(p_name)`: returns the ID of the arena the player's playing in
* `arena_lib.get_queueID_by_player(p_name)`: returns the ID of the arena the player's queueing for
* `arena_lib.get_arena_spawners_count(arena, <team_ID>)`: returns the total amount of spawners declared in the specified arena. If team_ID is specified, it only counts the ones belonging to that team
* `arena_lib.get_random_spawner(arena, <team_ID>)`: returns a random spawner declared in the specified arena. If team_ID is specified, it only considers the ones belonging to that team
* `arena_lib.get_players_in_game()`: returns all the players playing in whatever arena of whatever minigame
* `arena_lib.get_players_in_minigame(mod, <to_player>)`: returns a table containing as index either the names of all the players inside the specified minigame (`mod`) or, if `to_player` is `true`, the players themselves
* `arena_lib.get_players_in_team(arena, team_ID, <to_player>)`: returns a table containing as index either the names of the players inside the specified team or, if `to_player` is `true`, the players themselves
* `arena_lib.get_active_teams(arena)`: returns an ordered table having as values the ID of teams that are not empty
* `arena_lib.get_player_spectators(p_name)`: returns a list containing all the people currently spectating `p_name`. Format `{sp_name = true}`
* `arena_lib.get_player_spectated(sp_name)`: returns the player `sp_name` is currently spectating, if any
* `arena_lib.get_player_in_edit_mode(arena_name)`: returns the name of the player who's editing `arena_name`, if there is any

### 1.10 Things you don't want to do with a light heart
* Changing the number of the teams: it'll delete your spawners (this has to be done in order to avoid further problems)
* Any action in the "Players" section of the editor, except changing their minimum amount: it'll delete your spawners (same as above)
* Removing properties in the minigame declaration: it'll delete them from every arena, without any possibility to get them back. Always do a backup first
* Disabling timers (`time_mode = "decremental"` to something else) when arenas have custom timer values: it'll reset every custom value, so you have to put them again manually if/when you decide to turning timers back up

### 1.11 Example file
Check [this](mod-init.lua.example) out for a full configuration file

## 2. Arenas

It all starts with a table called `arena_lib.mods = {}`. This table allows `arena_lib` to be subdivided per mod and it has different parameters, one being `arena_lib.mods[yourmod].arenas`. Here is where every new arena created gets put.  
An arena is a table having as a key an ID and as a value its parameters. They are:
* `name`: (string) the name of the arena, declared when creating it
* `author`: (string) the name of the one who built/designed the map. Default is `"???"`. It appears in the signs infobox (right-click an arena sign)
* `sign`: (pos) the position of the sign associated with the arena
* `players`: (table) where to store players information, such as their team ID (`teamID`) and `player_properties`. Format `{[p_name] = {stuff}, [p_name2] = {stuff}, ...}`
* `spectators`: (table) where to store spectators information. Format `{[sp_name] = true}`
* `players_and_spectators`: (table) where to store both players and spectators names. Format `{[psp_name] = true}`
* `past_present_players`: (table) keeps track of every player who took part to the match, even if they are spectators now or they left. Contrary to `players` and `players_and_spectators`, this is created when the arena loads, so it doesn't consider people who joined and left during the queue. Format `{[ppp_name] = true}`
* `past_present_players_inside`: (table) same as `past_present_players` but without keeping track of the ones who left
* `teams`: (table) where to store teams information, such as their name (`name`) and `team_properties`. If there are no teams, it's `{-1}`. If there are, format is `{[teamID] = {stuff}, [teamID2] = {stuff}, ...}`
* `teams_enabled`: (boolean) whether teams are enabled in the arena. Requires teams
* `players_amount`: (int) separately stores how many players are inside the arena/queue
* `players_amount_per_team`: (table) separately stores how many players currently are in a given team. Format `{[teamID] = amount}`. If teams are disabled, it's `nil`
* `spectators_amount`: (int) separately stores how many spectators are inside the arena
* `spectators_amount_per_team`: (table) like `players_amount_per_team`, but for spectators
* `spawn_points`: (table) contains information about the spawn points. Format `{[spawnID] = {pos = coords, teamID = team ID}}`. If teams are disabled, `teamID` is `nil`
* `max_players`: (string) default is 4. When this value is reached, queue time decreases to 5 if it's not lower already
* `min_players`: (string) default is 2. When this value is reached, a queue starts
* `initial_time`: (int) in seconds. It's `nil` when the mod doesn't keep track of time, it's 0 when the mod does it incrementally and it's inherited by the mod if the mod has a timer. In this case, every arena can have its specific value. By default time tracking is disabled, hence it's `nil`
* `current_time`: (int) in seconds. It requires `initial_time` and it exists only when a game is in progress, keeping track of the current time
* `bgm`: (table) contains the information about the audio track to play while in game. Audio tracks must be placed in the minigame `/sounds` path (not arena_lib's) in order to be found. Default is `nil`.
  In-depth fields, all empty by default, are:
  * `track`: (string) the audio file, without `.ogg`. Mandatory. If no track is specified, all the other fields will be consequently empty
  * `title`: (string) the title to display in the infobox (right-clicking a sign)
  * `author`: (string) the author to display in the infobox (right-clicking a sign)
  * `gain`: (int) the volume of the track
  * `pitch`: (int) the pitch of the track
* `in_queue`: (bool) about phases, look at "Arena phases" down below
* `in_loading`: (bool)
* `in_game`: (bool)
* `in_celebration`: (bool)
* `enabled`: (bool) by default an arena is disabled, to avoid any unwanted damage

> **BEWARE**: don't edit these parameters manually! Each one of them can be set through some arena_lib function, which runs the required checks in order to avoid any collateral damage


Being arenas stored by ID, they can be easily retrieved by `arena_libs.mods[yourmod].arenas[THEARENAID]`.  

There are two ways to know an arena ID: the first is in-game via the two debug utilities:
* `arena_lib.print_arenas(sender, mod)`: coincise
* `arena_lib.print_arena_info(sender, mod, arena_name)`: extended with much more information (this one is implemented in the editor by default)

The second is via code by the functions:
* `arena_lib.get_arenaID_by_player(p_name)`: the player must be queueing for the arena, or playing it
* `arena_lib.get_arena_by_name(mod, arena_name)`: it returns both the ID and the arena (so, the table)

### 2.1 Creating and removing arenas
There are two functions for it and they all need to be connected to some command in your mod. These functions are
* `arena_lib.create_arena(sender, mod, arena_name, <min_players>, <max_players>)`: `arena_name` must be unique. Sender is a string, fields between < > are optional
* `arena_lib.remove_arena(mod, arena_name)`

#### 2.1.1 Storing arenas
Arenas and their settings are stored inside the mod storage. What is *not* stored are players, their stats and such.  
Better said, these kind of parameters are emptied every time the server starts. And not when it ends, because handling situations like crashes is simply not possible.

#### 2.1.2 Renaming an arena
Being arenas stored by ID, changing their names is no big deal. An arena can be renamed via  
`arena_lib.rename_arena(sender, mod, arena_name, new_name)`
In order to do so, it must be disabled.
  
### 2.2 Setting up an arena
Two things are needed to have an arena up to go: spawners and signs. There are two functions for that:  
* `arena_lib.set_spawner(sender, mod, arena_name, <teamID_or_name>, <param>, <ID>)`: spawners can't exceed the maximum players of an arena and, more specifically, they must be the same number. A spawner is a table with `pos` and `team_ID` as values.
* `arena_lib.set_sign(sender, <pos, remove>, <mod, arena_name>)`: there must be one and only one sign per arena. Signs are the bridge between the arena and the rest of the world

#### 2.2.1 Editor
arena_lib comes with a fancy editor via hotbar so you don't have to configure and memorise a lot of commands (if you still want to go full CLI/chat though, skip this paragraph).
In order to use the editor, no other players must be editing the same arena. When entering it, the arena is disabled automatically. The rest is pretty straightforward :D if you're not sure of what something does, just open the inventory and read its name.  
The function calling the editor is  
`arena_lib.enter_editor(sender, mod, arena_name)`

#### 2.2.2 CLI
If you don't want to rely on the hotbar, or you want both the editor and the commands via chat, here's how the commands work. Note that there actually is another parameter at the end of each of these functions named `in_editor` but, since it's solely used by the editor itself in order to run less checks, I chose to odmit it (it's in `set_spawner` too).

##### 2.2.2.1 Players management
`arena_lib.change_players_amount(sender, mod, arena_name, min_players, max_players)` changes the amount of players in a specific arena. It also works by specifying only one field (such as `([...] myarena, 3)` or `([...] myarena, nil, 6)`). It returns true if it succeeded.

##### 2.2.2.2 Enabling/Disabling teams
`arena_lib.toggle_teams_per_arena(sender, mod, arena_name, enable)` enables/disables teams per single arena. `enable` is an int, where 0 disables teams and 1 enables them.

##### 2.2.2.3 Timers
`arena_lib.set_timer(sender, mod, arena_name, timer)` changes the timer of the arena. It only works if timers are enabled (explained further below).

##### 2.2.2.4 Arena properties
Properties are explained down below, but essentially they allow you to create additional attributes specifically suited for what you have in mind (e.g. a score to reach to win the game).
`arena_lib.change_arena_property(sender, mod, arena_name, property, new_value)` changes the specified arena property with `new_value`. Keep in mind you can't change a property type (a number must remain a number, a string a string etc), and strings need quotes surrounding them - so `false` is a boolean, but `"false"` is a string. Also, this works for *arena* properties only. Not for temporary, players, nor team ones.

##### 2.2.2.5 Spawners
`arena_lib.set_spawner(sender, mod, arena_name, <teamID_or_name>, <param>, <ID>)` creates a spawner where the sender is standing, so be sure to stand where you want the spawn point to be.  
* `teamID_or_name` can be both a string and a number. It must be specified if your arena uses teams
* `param` is a string, specifically "overwrite", "delete" or "deleteall". "deleteall" aside, the other ones need an ID after them. Also, if a team is specified with deleteall, it will only delete the spawners belonging to that team
* `ID` is the spawner ID, for `param`
Again, I suggest you using [ChatCmdBuilder](https://rubenwardy.com/minetest_modding_book/en/players/chat_complex.html) by rubenwardy and connect the `set_spawner` function to a few subcommands such as:

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

##### 2.2.2.6 Signs
`arena_lib.set_sign(sender, <pos, remove>, <mod, arena_name>)` via chat uses `sender`, `mod` and `arena_name`, while the editor `pos` and `remove` (hence the weird subdivision). When used via chat, it takes the block the player is pointing at in a 5 blocks radius. If the block is a sign, it then creates (or remove if already set) the "arena sign".

##### 2.2.2.7 Music
`arena_lib.set_bgm(sender, mod, arena_name, track, title, author, volume, pitch)` sets the background music of the arena. The audio file (`track`) must be inside the `sounds` folder of the minigame mod (NOT arena_lib's), and `.ogg` shall be omitted from the string. If `track` is nil, `arena.bgm` will be set to `nil` too

#### 2.2.3 Enabling an arena
When a sign has been set, it won't work. This because an arena must be enabled manually via  
`arena_lib.enable_arena(sender, mod, arena_name)` or by using the Enable and Leave button in the editor.
If all the conditions are met, it'll return `true` and you'll receive a confirmation. If not, you'll receive the reason why it didn't through and the arena will remain disabled. Conditions are:
* all spawn points set
* sign placed
* potential custom checks through `arena_lib.on_enable` callback
  
Arenas can be disabled too, via  
`arena_lib.disable_arena(sender, mod, arena_name)` (or by entering the editor, as previously said).  
In order to do that, no game must be taking place in that specific arena. If successful, it'll return `true` and any potential player in queue will be removed. It acts like `enable_arena` (with `arena_lib.on_disable` as callback)

### 2.3 Arena phases
An arena comes in 4 phases, each one of them linked to a specific function:
* `waiting phase`: it's the queuing process. People hit a sign waiting for other players to play with 
* `loading phase`: it's the pre-match. By default players get teleported in the arena not being able to do anything but jump
* `fighting phase`: the actual game
* `celebration phase`: the after-match. By default people stroll around for the arena knowing who won, waiting to be teleported

The 4 functions, intertwined with the previously mentioned phases are:
* `arena_lib.load_arena(mod, arena_ID)`: between the waiting and the loading phase. Called when the queue timer reaches 0, it teleports people inside.
* `arena_lib.start_arena(mod_ref, arena)`: between the loading and the fighting phase. Called when the loading phase timer reaches 0.
* `arena_lib.load_celebration(mod, arena, winner_name)`: between the fighting and the celebration phase. Called when the winning conditions are met. `winner_name` can be both a string and a table (in case of teams)
* `arena_lib.end_arena(mod_ref, mod, arena, winner_name, as_spectator)`: at the very end of the celebration phase. It teleports people outside the arena. `winner_name` is taken by `load_celebration(...)`

Overriding these functions is **not** recommended. Instead, use the 4 respective callbacks made specifically to customise the behaviour of the formers, sharing (almost) the same variables. They are called *after* the function they're associated with and by default they are empty, so feel free to override them. They are `on_load`, `on_start`, `on_celebration` and `on_end`.

### 2.4 Spectate mode
Every minigame has this mode enabled by default. As the name suggests, it allows people to spectate a match, and there are two ways to enter this mode: the first is by getting eliminated (`remove_player_from_arena` with `1` as a reason), while the other is through the very sign of the arena. In this last case, users just need to right-click the sign and press the "eye" button to be turned into spectators (a game must be in progress). While in this state, they can't interact in any way with the actual match: neither by hitting entities/blocks, nor by writing in chat. The latter, more precisely, is a separated chat that spectators and spectators only are able to read. Vice versa, they're not able to read the players one.

## 3. About the author(s)
I'm Zughy (Marco), a professional Italian pixel artist who fights for FOSS and digital ethics. If this library spared you a lot of time and you want to support me somehow, please consider donating on [LiberaPay](https://liberapay.com/Zughy/). Also, this project wouldn't have been possible if it hadn't been for some friends who helped me testing through: `Giov4`, `SonoMichele`, `_Zaizen_` and `Xx_Crazyminer_xX`

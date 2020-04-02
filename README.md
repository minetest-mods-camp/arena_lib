# Arena_lib

Arena_lib is a library for Minetest working as a core for any minigame you have in mind.  
It comes with an arena manager and a signs system. The latter creates a bridge inside your own server between the hub and your actual mod (deathmatch, capture the flag, assault, you name it). In other words, you don't have to do the boring job and you can focus exclusively on your arena minigame :*


### Config
1) **You DON'T need to create a different folder in your mods path.** Instead, create a folder called `arena_lib` inside your specific mod folder and put all the files of this repo there (mind the textures!).  
  
2) Add this in your init.lua   
`dofile(minetest.get_modpath("quake") .. "/arena_lib/api.lua")`

3) You can customize the lib calling

```arena_lib.settings({
  prefix = "[whatever] "
  --other parameters
})
```
in your init.lua.  

For a in-depth understanding of what you can do with the library, have a look at the API document (TODO).

### Arena phases

An arena comes in 4 phases: 
- load
- start
- celebration
- end

To add events such as to expand what happens in one of those, there is a function for every arena phase you can easily override: `on_load`, `on_start`, `on_celebration`, `on_end`.

### Dependencies
[signs_lib](https://gitlab.com/VanessaE/signs_lib) by Vanessa Dannenberg  

### Known conflicts
`Beds` or any other mod overriding the default respawn system

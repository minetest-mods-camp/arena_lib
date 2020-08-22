# Arena_lib

Arena_lib is a library for Minetest working as a core for any arena minigame you have in mind.  
It comes with an arena manager and a signs system. The latter creates a bridge inside your own server between the hub and your actual mod (deathmatch, capture the flag, assault, you name it). In other words, you don't have to do the boring job and you can focus exclusively on your minigame(s) :*

<a href="https://liberapay.com/Zughy/"><img src="https://i.imgur.com/4B2PxjP.png" alt="Support my work"/></a>  

### Config

1) Install it as any other mod

2) For an in-depth understanding of what you can do with the library, have a look at the [full documentation](https://gitlab.com/zughy-friends-minetest/arena_lib/-/blob/master/DOCS.md).  

### Dependencies
Default  
[signs_lib](https://gitlab.com/VanessaE/signs_lib) by Vanessa Dannenberg  
(soft) [Parties](https://gitlab.com/zughy-friends-minetest/parties) by me: use it to be sure to join the same arena/team with your friends

#### Add-ons
[Hub Manager](https://gitlab.com/zughy-friends-minetest/hub-manager) by me: use it if you're aiming for a full minigame server

### Known conflicts
* `Beds` or any other mod overriding the default respawn system
* `SkinsDB` or any other mod applying a 3D model onto the player, if `teams_color_overlay` is used

#### Mods relying on arena_lib
[Murder](https://gitlab.com/giov4/minetest-murder-mod)  
[Quake](https://gitlab.com/zughy-friends-minetest/minetest-quake)

### Want to help?
Feel free to:
* open an [issue](https://gitlab.com/zughy-friends-minetest/arena_lib/-/issues)
* submit a merge request. In this case, PLEASE, do follow milestones and my [coding guidelines](https://cryptpad.fr/pad/#/2/pad/view/-l75iHl3x54py20u2Y5OSAX4iruQBdeQXcO7PGTtGew/embed/). I won't merge features for milestones that are different from the upcoming one (if it's declared), nor messy code
* contact me on the [Minetest Forum](https://forum.minetest.net/memberlist.php?mode=viewprofile&u=26472)

##### Credits
countdown sound by [BoxeDave92](https://freesound.org/people/BoxerDave92/sounds/338868/)

---

Images are under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)


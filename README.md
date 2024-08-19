simple_protection
=================

A Minetest area protection mod, based on a fixed claim grid,
like seen in [landrush](https://github.com/Bremaweb/landrush).

You can claim areas by punching those with a claim stick.

![Screenshot](https://raw.githubusercontent.com/SmallJoker/simple_protection/master/screenshot.png)


License: CC0

**Dependencies**
- Minetest 5.0.0+
- `default` mod or `mcl_*`: Crafting recipes

**Optional dependencies**
- [areas](https://github.com/minetest-mods/areas): HUD compatibility


Features
--------

- Easy, single-click protection
- Minimap-like radar to see areas nearby: `/area radar`
- Visual area border feedback, as seen in the [protector](https://codeberg.org/tenplus1/protector) mod
- List of claimed areas
- World specific settings -> see `default_settings.lua` header text
	- Customizable fixed claim grid. 16x150x16 by default.
	- Optional setting to protect unclaimed areas
- Shared Chest for exchanging items
- VoxeLibre (= MineClone2) and Minetest Game support
- Translation support


Chat command(s)
--------------

```
/area <command> [<args> ...]
	show              -> Provides information about the current area
	radar             -> Displays a minimap-like area overview
	share <name>      -> Shares the current area with <name>
	unshare <name>    -> Unshares the current area with <name>
	shareall <name>   -> Shares all your areas with <name>
	unshareall <name> -> Unshares all your areas with <name>
	list [<name>]     -> Lists all areas (optional <name>)
	unclaim           -> Unclaims the current area
	delete <name>     -> Removes all areas of <name> (requires "server" privilege)
```


About "/area show"
------------------

Area status: Not claimable

- Shown when the area can not be claimed
- Happens (by default) in the underground

Access notation of shared areas:

- `mrturtle`: Single shared area with player `mrturtle`
- `mrturtle*`: All areas of the same owner are shared with `mrturtle`.
- `*all`: Wild west area. Everyone has access.

This notation is also valid for the other chat commands, where a `<name>` placeholder is used.

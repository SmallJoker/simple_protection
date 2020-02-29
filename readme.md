simple_protection
=================

A Minetest area protection mod, based on a fixed claim grid,
like seen in [landrush](https://github.com/Bremaweb/landrush).

You can claim areas by punching those with a claim stick.

![Screenshot](https://raw.githubusercontent.com/SmallJoker/simple_protection/master/screenshot.png)


License: CC0

**Dependencies**
- default: Crafting recipes

**Optional dependencies**
- [intllib](https://github.com/minetest-mods/intllib/): Translations
- [areas](https://github.com/ShadowNinja/areas): HUD compatibility


Features
--------

- Easy, single-click protection
- Fixed claim grid: 16x80x16 by default
	- To configure: see `default_settings.lua` header text
- Minimap-like radar to see areas nearby
- Visual area border feedback, as seen in the [protector](https://github.com/tenplus1/protector) mod
- List of claimed areas
- Shared Chest for exchanging items
- Translation support
- Optional setting to require an area before digging


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

Players with access: foo, bar*, leprechaun, *all
- foo, leprechaun: Regular single area share
- bar*: Has access to all areas with the same owner
- *all: Everybody can build and dig in the area

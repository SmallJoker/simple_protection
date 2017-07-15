simple_protection
=================

A Minetest area protection mod

You can claim areas by punching those with a claim stick.

Depends: default

License: WTFPL

Chat commands:
--------------
/area &lt;args ..&gt;

	show			-> Shows up the information about the current area
	radar			-> Displays and provides information about the areas around you
	share <name>		-> Shares the current area with <name>
	unshare <name>		-> Unshares the current area with <name>
	shareall <name>		-> Shares all your areas with <name>
	unshareall <name>	-> Unshares all your areas with <name>
	list [<name>]		-> Lists all areas (<name> is optional)
	unclaim			-> Unclaims the current area
	delete <name>		-> Removes all areas of <name> (requires "server" privilege)

About /area show:
-----------------

Area status: Not claimable -> By default, it's not possible to claim areas in the underground


Players with access: foo, bar*, leprechaun, *all

^ foo, leprechaun: A regular /area share, only for this area

^ bar*: All areas with this owner are shared with that player

^ *all: Everybody can build and dig in the area

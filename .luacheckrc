unused_args = false
allow_defined_top = true
max_line_length = 120
-- Allow shadowed variables
redefined = false

ignore = {
	"542" -- empty if branches
}

globals = {
	"simple_protection",
	"s_protect",
	"minetest"
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "indexof"}},

	"vector",
	"ItemStack",
	"Settings",
	"default",
}

exclude_files = {
	"database_lsqlite.lua" -- WIP
}
--[[
File: hud.lua

areas HUD overlap compatibility
HUD display and refreshing
]]


local sp = simple_protection
local S = sp.translator

sp.player_huds = {}

local hud_timer = 0
-- Text to put in front of the HUD element
local prefix = ""
-- HUD default position
local align_x = 1
local pos_x = 0.02

-- If areas is installed: Move the HUD to the opposite side
if minetest.get_modpath("areas") then
	prefix = "Simple Protection:\n"
	align_x = -1
	pos_x = 0.95
end

local function generate_hud(player, current_owner, has_access)
	-- green if access
	local color = 0xFFFFFF
	if has_access then
		color = 0x00CC00
	end
	sp.player_huds[player:get_player_name()] = {
		hud_id = player:hud_add({
			[minetest.features.hud_def_type_field and "type" or "hud_elem_type"] = "text",
			name          = "area_hud",
			number        = color,
			position      = {x=pos_x, y=0.98},
			text          = prefix
				.. S("Area owner: @1", current_owner),
			scale         = {x=100, y=25},
			alignment     = {x=align_x, y=-1},
		}),
		owner = current_owner,
		had_access = has_access,
	}
end

minetest.register_globalstep(function(dtime)
	hud_timer = hud_timer + dtime
	if hud_timer < 2.9 then
		return
	end
	hud_timer = 0

	local is_shared = sp.is_shared
	for _, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()

		local current_owner = ""
		local data = sp.get_claim(player:get_pos())
		if data then
			current_owner = data.owner
		end

		local has_access = (current_owner == player_name)
		if not has_access and data then
			-- Check if this area is shared with this player
			has_access = is_shared(data, player_name)
		end
		if not has_access then
			-- Check if all areas are shared with this player
			has_access = is_shared(current_owner, player_name)
		end
		local changed = true

		local hud_table = sp.player_huds[player_name]
		if hud_table and hud_table.owner == current_owner
				and hud_table.had_access == has_access then
			-- still the same hud
			changed = false
		end

		if changed and hud_table then
			player:hud_remove(hud_table.hud_id)
			sp.player_huds[player_name] = nil
		end

		if changed and current_owner ~= "" then
			generate_hud(player, current_owner, has_access)
		end
	end
end)

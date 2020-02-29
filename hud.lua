--[[
File: hud.lua

areas HUD overlap compatibility
HUD display and refreshing
]]


local S = s_protect.gettext

s_protect.player_huds = {}

local hud_time = 0
local prefix = ""
local align_x = 1
local pos_x = 0.01
local pos_y = 0.8

if minetest.get_modpath("areas") then
	prefix = "Simple Protection:\n"
	--align_x = -1
	pos_x = pos_x
end

local function generate_hud(player, current_owner, has_access)
	-- green if access
	local color = 0xFFFFFF
	if has_access then
		color = 0x00CC00
	end
	s_protect.player_huds[player:get_player_name()] = {
		hudID = player:hud_add({
			hud_elem_type = "text",
			name          = "area_hud",
			number        = color,
			position      = {x=pos_x, y=pos_y},
			text          = prefix
				.. S("Area owner: @1", current_owner),
			scale         = {x=100, y=25},
			alignment     = {x=align_x, y=-1},
		}),
		owner = current_owner,
		had_access = has_access
	}
end

minetest.register_globalstep(function(dtime)
	hud_time = hud_time + dtime
	if hud_time < 2.9 then
		return
	end
	hud_time = 0

	local shared = s_protect.share
	for _, player in ipairs(minetest.get_connected_players()) do
		local player_name = player:get_player_name()

		local current_owner = ""
		local data = s_protect.get_claim(player:get_pos())
		if data then
			current_owner = data.owner
		end

		local has_access = (current_owner == player_name)
		if not has_access and data then
			-- Check if this area is shared with this player
			has_access = table_contains(data.shared, player_name)
		end
		if not has_access then
			-- Check if all areas are shared with this player
			has_access = table_contains(shared[current_owner], player_name)
		end
		local changed = true

		local hud_table = s_protect.player_huds[player_name]
		if hud_table and hud_table.owner == current_owner
				and hud_table.had_access == has_access then
			-- still the same hud
			changed = false
		end

		if hud_table and changed then
			player:hud_remove(hud_table.hudID)
			s_protect.player_huds[player_name] = nil
		end

		if current_owner ~= "" and changed then
			generate_hud(player, current_owner, has_access)
		end
	end
end)

-- /area radar

s_protect.command_radar = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = s_protect.get_location(player:getpos())
	local data_cache

	local claims = s_protect.claims
	local function getter(x, ymod, z)
		data_cache = claims[x .."," .. (pos.y + ymod) .. "," .. z]
		return data_cache
	end
	local function colorize()
		if not data_cache then
			-- Area not claimed
			return "[colorize:#000:50"
		end
		if data_cache.owner == name then
			return "[colorize:#0F0:180"
		end
		if table_contains(data_cache.shared, name) then
			return "[colorize:#0F0:100"
		end
		if table_contains(data_cache.shared, "*all") then
			return "[colorize:#0F9:100"
		end
		-- Claimed but not shared
		return "[colorize:#000:180"
	end

	local parts = ""
	for z = 0, 8 do
	for x = 0, 8 do
		local ax = pos.x + x - 4
		local az = pos.z + z - 4
		local img = "simple_protection_radar.png"

		if     getter(ax,  0, az) then
			-- Using default "img" value
		elseif getter(ax, -1, az) then
			-- Check for claim below first
			img = "simple_protection_radar_down.png"
		elseif getter(ax,  1, az) then
			-- Last, check upper area
			img = "simple_protection_radar_up.png"
		end
		parts = parts ..
			":" .. (x * 32) .. "," .. (z * 32) .. "=" ..
			img .. "\\^\\".. colorize():gsub(":", "\\:")
		-- Somewhat dirty hack for [combine. Escape everything
		-- to get the whole text passed into TextureSource::generateImage()
	end
	end
	minetest.show_formspec(name, "covfefe",
		"size[6,7]" ..
		"button_exit[2,0;2,1;exit;Close]" ..
		"label[0,1;Green = Modifyable, Light gray = Not claimed" ..
			"\n-1 and 1 = Y axis modifier]" ..
		"image[0.5,2;6,6;" ..
			minetest.formspec_escape("[combine:288x288" .. parts) ..
		"]"
	)
end

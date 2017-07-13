-- /area radar

local data_cache

local function colorize_area(name, force)
	if force == "unclaimed" or not force and
			not data_cache then
		-- Area not claimed
		return "[colorize:#FFF:50"
	end
	if force == "owner" or not force and
			data_cache.owner == name then
		return "[colorize:#0F0:180"
	end
	if force == "shared" or not force and (
			   table_contains(data_cache.shared, name)
			or table_contains(s_protect.share[data_cache.owner], name)) then
		return "[colorize:#0F0:80"
	end
	if force == "*all" or not force and
			table_contains(data_cache.shared, "*all") then
		return "[colorize:#00F:180"
	end
	-- Claimed but not shared
	return "[colorize:#000:180"
end

s_protect.command_radar = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = s_protect.get_location(player:getpos())

	local claims = s_protect.claims
	local function getter(x, ymod, z)
		data_cache = claims[x .."," .. (pos.y + ymod) .. "," .. z]
		return data_cache
	end

	local parts = ""
	for z = 0, 14 do
	for x = 0, 14 do
		local ax = pos.x + x - 7
		local az = pos.z + z - 7
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
			":" .. (x * 20) .. "," .. ((14 - z) * 20) .. "=" ..
			img .. "\\^\\".. colorize_area(name):gsub(":", "\\:")
		-- Somewhat dirty hack for [combine. Escape everything
		-- to get the whole text passed into TextureSource::generateImage()
	end
	end
	minetest.show_formspec(name, "covfefe",
		"size[10.5,7]" ..
		"button_exit[9.5,0;1,1;exit;X]" ..
		"label[2,0;North (Z+)]" ..
		"image[0,0.5;7,7;" ..
			minetest.formspec_escape("[combine:300x300" .. parts) ..
		"]" ..
		"label[0,6.8;1 field = 1 area = "
			.. s_protect.claim_size .. "x"
			.. s_protect.claim_height .. "x"
			.. s_protect.claim_size .. " nodes (X,Y,Z)]" ..
		"image[6,1;1,1;simple_protection_radar_down.png]" ..
		"image[7,1;1,1;simple_protection_radar_up.png]" ..
		"label[6,2;One area unit ("..s_protect.claim_height
			.. ") up/down\n= no claims on this Y level]" ..
		"image[6,3;1,1;simple_protection_radar.png^"
			.. colorize_area(nil, "owner") .. "]" ..
		"label[7,3;Your area]" ..
		"image[6,4;1,1;simple_protection_radar.png^"
			.. colorize_area(nil, "other") .. "]" ..
		"label[7,4;Area claimed\nNo access for you]" ..
		"image[6,5;1,1;simple_protection_radar.png^"
			.. colorize_area(nil, "*all") .. "]" ..
		"label[7,5;Shared for everybody]"
	)
end

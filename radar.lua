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

local function combine_escape(str)
	return str:gsub("%^%[", "\\%^\\%["):gsub(":", "\\:")
end

s_protect.command_radar = function(name)
	local player = minetest.get_player_by_name(name)
	local player_pos = player:getpos()
	local pos = s_protect.get_location(player_pos)
	local map_w = 15 - 1
	local map_wh = map_w / 2
	local img_w = 20

	local claims = s_protect.claims
	local function getter(x, ymod, z)
		data_cache = claims[x .."," .. (pos.y + ymod) .. "," .. z]
		return data_cache
	end

	local parts = ""
	for z = 0, map_w do
	for x = 0, map_w do
		local ax = pos.x + x - map_wh
		local az = pos.z + z - map_wh
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
		parts = parts .. string.format(":%i,%i=%s",
			x * img_w, (map_w - z) * img_w,
			combine_escape(img .. "^" .. colorize_area(name)))
		-- Somewhat dirty hack for [combine. Escape everything
		-- to get the whole text passed into TextureSource::generateImage()
	end
	end

	-- Player's position marker (8x8 px)
	local pp_x = player_pos.x / s_protect.claim_size
	local pp_z = player_pos.z / s_protect.claim_size
	-- Get relative position to the map, add map center offset, center image
	pp_x = math.floor((pp_x - pos.x + map_wh) * img_w + 0.5) - 4
	pp_z = math.floor((pos.z - pp_z + map_wh + 1) * img_w + 0.5) - 4
	local marker_str = string.format(":%i,%i=%s", pp_x, pp_z,
		combine_escape("object_marker_red.png^[resize:8x8"))

	-- Rotation calculation
	local dir_label = "North (Z+)"
	local dir_mod = ""
	local look_angle = player.get_look_horizontal and player:get_look_horizontal()
	if not look_angle then
		look_angle = player:get_look_yaw() - math.pi / 2
	end
	look_angle = look_angle * 180 / math.pi

	if     look_angle >=  45 and look_angle < 135 then
		dir_label = "West (X-)"
		dir_mod = "^[transformR270"
	elseif look_angle >= 135 and look_angle < 225 then
		dir_label = "South (Z-)"
		dir_mod = "^[transformR180"
	elseif look_angle >= 225 and look_angle < 315 then
		dir_label = "East (X+)"
		dir_mod = "^[transformR90"
	end

	minetest.show_formspec(name, "covfefe",
		"size[10.5,7]" ..
		"button_exit[9.5,0;1,2;exit;X]" ..
		"label[2,0;"..dir_label.."]" ..
		"image[0,0.5;7,7;" ..
			minetest.formspec_escape("[combine:300x300"
				.. parts .. marker_str)
				.. dir_mod .. "]" ..
		"label[0,6.8;1 square = 1 area = "
			.. s_protect.claim_size .. "x"
			.. s_protect.claim_height .. "x"
			.. s_protect.claim_size .. " nodes (X,Y,Z)]" ..
		"image[6.25,1.25;0.5,0.5;object_marker_red.png]" ..
		"label[7,1.25;Your position]" ..
		"image[6,2;1,1;simple_protection_radar.png^"
			.. colorize_area(nil, "owner") .. "]" ..
		"label[7,2.25;Your area]" ..
		"image[6,3;1,1;simple_protection_radar.png^"
			.. colorize_area(nil, "other") .. "]" ..
		"label[7,3;Area claimed\nNo access for you]" ..
		"image[6,4;1,1;simple_protection_radar.png^"
			.. colorize_area(nil, "*all") .. "]" ..
		"label[7,4.25;Shared for everybody]" ..
		"image[6,5;1,1;simple_protection_radar_down.png]" ..
		"image[7,5;1,1;simple_protection_radar_up.png]" ..
		"label[6,6;One area unit ("..s_protect.claim_height
			.. ") up/down\n= no claims on this Y level]"
	)
end

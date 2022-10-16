-- /area radar
local sp = simple_protection
local FS = sp.FS
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
	local is_shared = sp.is_shared
	if force == "shared" or not force and (
			   is_shared(data_cache, name)
			or is_shared(data_cache.owner, name)) then
		return "[colorize:#0F0:80"
	end
	if force == "*all" or not force and
			is_shared(data_cache, "*all") then
		return "[colorize:#00F:180"
	end
	-- Claimed but not shared
	return "[colorize:#000:180"
end

local function combine_escape(str)
	-- Somewhat dirty hack for [combine. Escape everything
	-- to get the whole text passed into TextureSource::generateImage()
	return str:gsub("%^%[", "\\%^\\%["):gsub(":", "\\:")
end

sp.register_subcommand("radar", function(name)
	local player = minetest.get_player_by_name(name)
	local player_pos = player:get_pos()
	local pos = sp.get_location(player_pos)
	local map_wh = 7 -- centered scanning in x/z
	local map_wt = 2 * (map_wh + 1)   -- tile count of the image (square)
	local img_px = 20 -- size of each tile in pixels (square)
	local map_fs_x, map_fs_y, map_fs_w = 0.3, 0.75, 7 -- formspec x/y offset and side lendth


	-- Rotation calculation
	local look_angle = player:get_look_horizontal() * 180 / math.pi
	local dir_label, rot_T
	if     look_angle >=  45 and look_angle < 135 then
		dir_label = FS("West @1", "(X-)")
		rot_T = { 0, 1, 1, 0 }
	elseif look_angle >= 135 and look_angle < 225 then
		dir_label = FS("South @1", "(Z-)")
		rot_T = { -1, 0, 0, 1 }
	elseif look_angle >= 225 and look_angle < 315 then
		dir_label = FS("East @1", "(X+)")
		rot_T = { 0, -1, -1, 0 }
	else
		dir_label = FS("North @1", "(Z+)")
		rot_T = { 1, 0, 0, -1 }
	end

	-- Transforms a position in [-map_wh, map_wh] to an image offset
	local function transform_center_to_img(x, z)
		return rot_T[1] * x + rot_T[2] * z + map_wh,
			rot_T[3] * x + rot_T[4] * z + map_wh
	end

	-- Map scanning
	local get_single = sp.get_claim
	local function getter(x, ymod, z)
		data_cache = get_single(x, pos.y + ymod, z)
		return data_cache
	end

	local total_px_w = img_px * map_wt
	local textures = {
		("[combine:%ix%i"):format(total_px_w, total_px_w)
	}
	local tooltips = {}
	for z = -map_wh, map_wh do
	for x = -map_wh, map_wh do
		local ax = pos.x + x
		local az = pos.z + z
		local img = "simple_protection_radar.png"

		-- Note: this also updates data_cache on the first hit
		if     getter(ax,  0, az) then
			-- Using default "img" value
		elseif getter(ax, -1, az) then
			-- Check for claim below first
			img = "simple_protection_radar_down.png"
		elseif getter(ax,  1, az) then
			-- Last, check upper area
			img = "simple_protection_radar_up.png"
		end

		local ix, iy = transform_center_to_img(x, z)
		textures[#textures + 1] = string.format(":%i,%i=%s",
			ix * img_px, iy * img_px, combine_escape(img .. "^" .. colorize_area(name)))

		if data_cache then -- and data_cache.owner ~= name then
			tooltips[#tooltips + 1] = ("tooltip[%g,%g;%g,%g;%s]"):format(
				map_fs_x + ix / map_wt * map_fs_w,
				map_fs_y + iy / map_wt * map_fs_w,
				map_fs_w / (map_wt - 1), map_fs_w / (map_wt - 1),
				minetest.formspec_escape(data_cache.owner)
			)
		end
	end
	end


	-- Player's position marker (8x8 px)
	local p_ix, p_iy = transform_center_to_img(
		-- Use decimal precision -> stretch to acceptad map range
		(player_pos.x / sp.claim_size - pos.x - 0.5) * map_wt,
		(player_pos.z / sp.claim_size - pos.z - 0.5) * map_wt
	)

	p_ix = (map_wh + p_ix / map_wt) * img_px - 4
	p_iy = (map_wh + p_iy / map_wt) * img_px - 4
	textures[#textures + 1] = string.format(":%i,%i=%s", p_ix, p_iy,
		combine_escape("object_marker_red.png^[resize:8x8"))


	-- Display
	minetest.show_formspec(name, "covfefe", table.concat({
		"formspec_version[3]",
		"size[12,8]",
		"button_exit[10.8,0.1;1.1,0.8;exit;X]",
		"label[3,0.3;"..dir_label.."]",
		("image[%g,%g;%g,%g;"):format(map_fs_x, map_fs_y, map_fs_w, map_fs_w),
			minetest.formspec_escape(table.concat(textures)),
			"]",
		table.concat(tooltips),
		"image[7.2,1.1;0.4,0.4;object_marker_red.png]",
		"label[8,1.3;" .. FS("Your position") .. "]",
		"image[7,2;0.7,0.7;simple_protection_radar.png^"
			.. colorize_area(nil, "owner") .. "]",
		"label[8,2.3;" .. FS("Your area") .. "]",
		"image[7,3;0.7,0.7;simple_protection_radar.png^"
			.. colorize_area(nil, "other") .. "]",
		"label[8,3;" .. FS("Area claimed\nNo access for you") .. "]",
		"image[7,4;0.7,0.7;simple_protection_radar.png^"
			.. colorize_area(nil, "*all") .. "]",
		"label[8,4.3;" .. FS("Access for everybody") .. "]",
		"image[7,5;0.7,0.7;simple_protection_radar_down.png]",
		"image[8,5;0.7,0.7;simple_protection_radar_up.png]",
		"label[7,6;" .. FS("One area unit (@1m) up/down\n-> no claims on this Y level",
			sp.claim_height) .. "]",
		"label[1,7.6;" .. FS("1 square = 1 area = @1x@2x@3 nodes (X,Y,Z)",
			sp.claim_size,
			sp.claim_height,
			sp.claim_size) .. "]"
	}))
end)

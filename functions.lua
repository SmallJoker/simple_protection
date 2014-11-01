simple_protection.can_access = function(pos, player_name)
	if not player_name or player_name == "" then
		return false
	end
	-- allow pipeworks access
	if player_name == ":pipeworks" then
		return true
	end
	
	-- get data of area
	local data = simple_protection.get_data(pos)
	if not data then
		return true
	end
	if player_name == data.owner then
		return true
	end
	if data.shared[player_name] then
		return true
	end
	if data.shared["*all"] then
		return true
	end
	if minetest.check_player_privs(player_name, {simple_protection=true}) then
		return true
	end
	return false
end

simple_protection.get_data = function(pos)
	local str = simple_protection.get_location(pos)
	return simple_protection.claims[str]
end

simple_protection.get_y_axis = function(y)
	y = (y + simple_protection.start_underground) / simple_protection.claim_heigh
	return math.floor(y) * simple_protection.claim_heigh - simple_protection.start_underground
end

simple_protection.get_location = function(pos1)
	local pos = {
		x = pos1.x / simple_protection.claim_size,
		y = (pos1.y + simple_protection.start_underground) / simple_protection.claim_heigh,
		z = pos1.z / simple_protection.claim_size
	}
	pos = vector.floor(pos)
	return pos.x..","..pos.y..","..pos.z
end

simple_protection.get_center = function(pos1)
	local size = simple_protection.claim_size
	local pos = {
		x = pos1.x / size,
		y = pos1.y + 1.5,
		z = pos1.z / size
	}
	pos = vector.floor(pos)
	pos.x = pos.x * size + (size / 2)
	pos.z = pos.z * size + (size / 2) -- add half of chunk
	return pos
end

simple_protection.load = function()
	minetest.log("action", "Loading simple protection claims")
	local file = io.open(simple_protection.file, "r")
	if not file then
		return
	end
	for line in file:lines() do
		if line ~= "" then
			local data = line:split(" ")
			--coords, owner, shared1, shared2, ..
			local _shared = {}
			if #data > 2 then
				for index = 3, #data do
					if data[index] ~= "" then
						_shared[data[index]] = true
					end
				end
			end
			simple_protection.claims[data[1]] = {owner=data[2], shared=_shared}
		end
	end
	io.close(file)
end

simple_protection.save = function()
	local file = io.open(simple_protection.file, "w")
	for pos, data in pairs(simple_protection.claims) do
		if data.owner and data.owner ~= "" then
			local shared = ""
			for player, really in pairs(data.shared) do
				if really then
					shared = shared.." "..player
				end
			end
			file:write(pos.." "..data.owner..shared.."\n")
		end
	end
	io.close(file)
end

simple_protection.load_config = function()
	-- load defaults
	dofile(simple_protection.mod_path.."/settings.conf")
	local file = io.open(simple_protection.conf, "r")
	if file then
		io.close(file)
		-- load existing config
		dofile(simple_protection.conf)
		return
	end
	-- duplicate configuration file
	local src = io.open(simple_protection.mod_path.."/settings.conf", "r")
	file = io.open(simple_protection.conf, "w")
	
	while true do
		local block = src:read(128) -- 128B at once
		if not block then
			io.close(src)
			io.close(file)
			break
		end
		file:write(block)
	end
end
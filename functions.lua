simple_protection.can_access = function(pos, player_name)
	if not player_name or player_name == "" then
		return false
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

simple_protection.get_y_axis = function(y1)
	local y = math.floor((y1 - simple_protection.start_underground) / simple_protection.claim_heigh)
	return y * simple_protection.claim_heigh
end

simple_protection.get_location = function(pos1)
	--round
	pos = {x=0,y=0,z=0}
	pos.x = (pos1.x+.5) / simple_protection.claim_size
	--start in underground, get it as number 0
	pos.y = (pos1.y+.5 + simple_protection.start_underground) / simple_protection.claim_heigh
	pos.z = (pos1.z+.5) / simple_protection.claim_size
	pos.x = pos.x - (pos.x % 1)
	pos.y = pos.y - (pos.y % 1)
	pos.z = pos.z - (pos.z % 1) --faster than math.floor
	return pos.x..","..pos.y..","..pos.z
end

simple_protection.get_center = function(pos1)
	--round
	pos = {x=0,y=0,z=0}
	local _r4 = simple_protection.claim_size
	pos.x = pos1.x / _r4
	pos.y = pos1.y + 1.5
	pos.z = pos1.z / _r4
	
	pos.x = pos.x - (pos.x % 1)
	pos.y = pos.y - (pos.y % 1)
	pos.z = pos.z - (pos.z % 1) --faster than math.floor
	pos.x = pos.x * _r4 + (_r4 / 2)
	pos.z = pos.z * _r4 + (_r4 / 2) -- add half of chunk
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
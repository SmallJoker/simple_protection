--[[
	SETTINGS FILE

simple_protection/default_settings.lua
	Contains the default settings for freshly created worlds.
	Please do not modify in order to not get any configuration-related errors
	after updating all other files but this

[world_path]/s_protect.conf
	Contains the per-world specific settings.
	You may modify thisone but pay attention, as some settings may cause
	unwanted side effects when claims were made.
]]


-- Width and length of claims in nodes
-- !! Disorts the claims locations' along the X and Z axis !!
-- Type: Integer, positive, even number
s_protect.claim_size = 16

-- Height of claims in nodes
-- !! Disorts the claims locations' along the Y axis !!
-- Type: Integer, positive
s_protect.claim_height = 80

-- Defines the Y offset where the 0th claim should start in the underground
-- Example of claim (0,0,0): Ymin = -[20], Ymax = 80 - [20] = 60
-- Type: Integer
s_protect.start_underground = 20

-- When set to 'true': Allows very deep underground claiming
-- Will make the protection mod to ignore 's_protect.underground_limit'
-- Type: Boolean
s_protect.underground_claim = false

-- Only allows claiming above this Y value
-- Type: Integer
s_protect.underground_limit = -300

-- Returns the claim stick when unclaiming the area
-- Type: Boolean
s_protect.claim_return = true

-- Players will need to claim the area (or have access to it) to dig
-- Digging will be still allowed in the underground when
--   's_protect.underground_claim == false'
-- Type: Boolean
s_protect.claim_to_dig = false

-- Allows players to list their areas using '/area list'
-- Type: Boolean
s_protect.area_list = true

-- Limits the amount of claims per player
-- For values < 10: Open [world_path]/world.mt and modify
--   the setting value of 'load_mod_simple_protection' to 'false'
-- This value is doubled for users with the 'simple_protection' privilege
-- Type: Integer
s_protect.max_claims = 100

wands = {spells = {}, wands = {}}

local player_spells = {}

local shield_spell = {
	physical = true,
	timer = 0,
	visual = "cube",
	visual_size = {x=2, y=2},
	textures = {"wands_shield.png", "wands_shield.png", "wands_shield.png", "wands_shield.png", "wands_shield.png", "wands_shield.png"},
	collisionbox = {0, 0, 0, 0, 0, 0},
	on_step = function(self, dtime)
		self.timer = self.timer + dtime

		for k, v in pairs(minetest.get_objects_inside_radius(self.object:get_pos(), 1)) do
			if k ~= 1 and not v:is_player() then
				if v:get_luaentity().name:find("wands:spell_") then
					v:remove()
					self.object:remove()
				end
			end
		end

		if self.timer >= 0.5 then
			self.object:remove()
		end
	end
}

minetest.register_entity("wands:shield", shield_spell)

--
--Functions
--

function wands.is_spell(spell)
	for k, v in pairs(wands.spells) do
		if k == spell then
			return(true)
		end
	end

	return(false)
end

function wands.register_spell(name, def)
	local wand_spell = {
		physical = false,
		timer = 0,
		visual = "sprite",
		visual_size = def.visual_size,
		textures = def.textures,
		collisionbox = {0, 0, 0, 0, 0, 0},
		on_step = def.on_step,
	}

	minetest.register_entity("wands:spell_"..name, wand_spell)

	wands.spells[name] = {
		description = def.description,
		speed = def.speed
	}
end

function wands.register_wand(name, def)
	wands.wands[#wands.wands+1] = "wands:"..name

	local can_block = true
	local can_cast = true

	minetest.register_tool("wands:"..name, {
		description = def.description,
		range = 0,
		inventory_image = def.texture,
		groups = {wand = 1},
		on_use = function(itemstack, user, pointed_thing)
			if can_cast == true then
				can_cast = false
				minetest.after(1.7, function() can_cast = true end)

				local spell = player_spells[user:get_player_name()]
				local pos = user:get_pos()
				local can = true

				if user:get_attribute("wand") ~= "wands:"..name and math.random(1, 3) ~= 2 then
					can = false
				end

				if user and spell ~= nil and can == true then
					local dir = user:get_look_dir()
					local obj = minetest.add_entity({x = pos.x, y = pos.y+1.6, z = pos.z}, "wands:spell_"..spell)

					obj:set_velocity(vector.multiply(dir, wands.spells[spell].speed))
					obj:get_luaentity().caster = user:get_player_name()
				end
			end
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			local pos = user:get_pos()

			if can_block == true then
				can_block = false
				minetest.after(2, function() can_block = true end)
				minetest.add_entity({x = pos.x, y = pos.y+1, z = pos.z}, "wands:shield")
			end
		end
	})

	minetest.register_craft({
		output = "wands:"..name,
		recipe = def.craft
	})
end

--
--Chat
--

minetest.register_on_chat_message(function(name, message)
	local msg = minetest.strip_colors(message)
	local player = minetest.get_player_by_name(name)
	local wand = player:get_wielded_item()

	if not wand:get_name():find("wands:") then
		return(false)
	end

	if msg:find("!!!") then
		local spell = msg:sub(1, msg:find("!!!")-1)

		if player and wands.is_spell(spell) == true then
			player_spells[name] = spell
			minetest.chat_send_all("<"..name.."> "..minetest.colorize("cyan", msg))
			return(true)
		end
	end

	return(false)
end)
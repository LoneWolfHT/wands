dofile(minetest.get_modpath("wands").."/api.lua")

minetest.register_on_joinplayer(function(player)
	if not player:get_attribute("wand") then
		minetest.log("Size: "..dump(#wands.wands).."\n"..dump(wands.wands))
		player:set_attribute("wand", wands.wands[math.random(1, #wands.wands)])
	end
end)

minetest.register_chatcommand("wands", {
	description = "`.wands wand` to see what wand fits you best.\n`.wands spells` to see all of the spells",
	privs = {interact = true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)

		if player and param == "wand" then
			minetest.chat_send_player(name, "The best wand for you would be a/an "..minetest.registered_tools[player:get_attribute("wand")].description)
		elseif player and param == "spells" then
			for k, v in pairs(wands.spells) do
				minetest.chat_send_player(name, minetest.colorize("cyan", "["..k.."] "..v.description))
			end
		end
	end
})

--
--Wands
--

wands.register_wand("wand_oak", {
	description = "Oak Wand",
	texture = "wand_oak.png",
	craft = {
		{"", "default:obsidian_shard", "default:mese_crystal"},
		{"", "default:wood", "default:obsidian_shard"},
		{"default:wood", "", ""}
	}
})

wands.register_wand("wand_pine", {
	description = "Pine Wand",
	texture = "wand_pine.png",
	craft = {
		{"", "default:obsidian_shard", "default:mese_crystal"},
		{"", "default:pine_wood", "default:obsidian_shard"},
		{"default:pine_wood", "", ""}
	}
})

wands.register_wand("wand_aspen", {
	description = "Aspen Wand",
	texture = "wand_aspen.png",
	craft = {
		{"", "default:obsidian_shard", "default:mese_crystal"},
		{"", "default:aspen_wood", "default:obsidian_shard"},
		{"default:aspen_wood", "", ""}
	}
})

wands.register_wand("wand_acacia", {
	description = "Acacia Wand",
	texture = "wand_acacia.png",
	craft = {
		{"", "default:obsidian_shard", "default:mese_crystal"},
		{"", "default:acacia_wood", "default:obsidian_shard"},
		{"default:acacia_wood", "", ""}
	}
})

wands.register_wand("wand_jungle", {
	description = "Jungle Wood Wand",
	texture = "wand_jungle.png",
	craft = {
		{"", "default:obsidian_shard", "default:mese_crystal"},
		{"", "default:junglewood", "default:obsidian_shard"},
		{"default:junglewood", "", ""}
	}
})

--
--Spells
--

wands.register_spell("augue", {
	description = "Shoots a fireball in the direction you wand is pointing",
	visual_size = {x = 1, y = 1},
	textures = {"fireball.png"},
	speed = 15,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)

		if node.name ~= "air" or self.timer >= 3 then
			local airpos = minetest.find_node_near(pos, 1, "air", false)

			if airpos ~= nil and math.random(1, 4) == 2 and not node.name:find("fire") then -- Prevent players from creating too much fire
				minetest.set_node(airpos, {name = "fire:basic_flame"})
			end
			self.object:remove()
		end

		for k, v in pairs(minetest.get_connected_players()) do
			local caster

			if self.caster ~= nil then
				caster = minetest.get_player_by_name(self.caster)
			else
				self.object:remove()
				return
			end

			if caster and vector.distance(v:get_pos(), pos) <= 1.5 then
				v:punch(caster, 1.0, {damage_groups= {fleshy = 10}}, nil)
				self.object:remove()
			end
		end
	end
})

wands.register_spell("stinguo", {
	description = "Extingushes flames you point at",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"default_water.png"},
	speed = 30,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)

		if node.name ~= "air" or self.timer >= 3 then
			for i=0, 5, 1 do
				local fire_pos = minetest.find_node_near(pos, 2, "fire:basic_flame", true)

				if fire_pos ~= nil then
					minetest.remove_node(fire_pos)
				end
			end
			self.object:remove()
		end
	end
})

wands.register_spell("mico", {
	description = "Lights up the area around your current position for two seconds",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"spark.png"},
	speed = 0,
	on_step = function(self, dtime)
		local pos = self.object:get_pos()

		if minetest.get_node(pos).name == "air" then
			minetest.set_node(pos, {name = "wands:light"})
			minetest.after(2, minetest.remove_node, pos)
		end
		self.object:remove()
	end
})

wands.register_spell("mortifico", {
	description = "Kills any player the spell comes in contact with",
	visual_size = {x = 0.5, y = 0.5},
	textures = {"kill.png"},
	speed = 10,
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		local pos = self.object:get_pos()
		local node = minetest.get_node(pos)

		if node.name ~= "air" or self.timer >= 1.5 or self.caster == nil then
			self.object:remove()
		end

		for k, v in pairs(minetest.get_connected_players()) do
			local caster

			if self.caster ~= nil then
				caster = minetest.get_player_by_name(self.caster)
			else
				self.object:remove()
				return
			end

			if caster and vector.distance(v:get_pos(), pos) <= 1.5 then
				v:punch(caster, 1.0, {damage_groups= {fleshy = 30}}, nil)
				self.object:remove()
			end
		end
	end
})

--
--Nodes/Tools
--

minetest.register_node("wands:light", {
	description = "Invisible Light",
	drawtype = "airlike",
	paramtype = "light",
	groups = {not_in_creative_inventory = 1},
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = false,
	sunlight_propagates = true,
	light_source = 10,
})
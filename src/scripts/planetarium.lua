local M = {}

-- ================================
-- Bodies
-- ================================

M.bodies = {
	["hot comet"] =	{
		spawnChance = 2,
		dynParams = {
			speed = 600,
			minAngle = 0,
			maxAngle = 50,
		},
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 20,
				angle = 0,
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				health = 30,
				trails = {
					-- bright tail
					{
						radius = 12,
						stepDelta = 5,
						lifetime = 0.28,
						color = { r = 231, g = 255, b = 170 },
					},
					{
						radius = 12,
						stepDelta = 5,
						lifetime = 0.42,
						color = { r = 231, g = 255, b = 170 },
						rake = 3,
					},
					-- dark middle
					{
						radius = 10,
						stepDelta = 3,
						lifetime = 0.15,
						color = { r = 92, g = 65, b = 101 },
					},
					{
						radius = 10,
						stepDelta = 3,
						lifetime = 0.21,
						color = { r = 92, g = 65, b = 101 },
						rake = 2,
					},
					-- core
					{
						radius = 10,
						stepDelta = 2,
						lifetime = 0.05,
						color = { r = 255, g = 120, b = 133 },
					},
				},
			}
			o.extra = {
				moveOrient = true,
				comet = true,
			}
			return o
		end,
		randomize = function(params)
			local p = params
			local dyn = M.bodies["hot comet"].dynParams
			-- speed vector angle
			local angleBH = math.atan2(-p.y, -p.x)
			local a, b = dyn.minAngle, dyn.maxAngle
			local angle = angleBH + math.rad(a+(b-a)*math.random())*(math.random(2)*2-3)
			-- speed vector magnitude
			local speed = dyn.speed * (1 + 0.3 * (math.random() * 2 - 1))
			-- XY speeds
			p.speedX = math.cos(angle) * speed
			p.speedY = math.sin(angle) * speed
			return p
		end,
	},
	["cold comet"] = {
		spawnChance = 2,
		dynParams = {
			speed = 400,
			minAngle = 0,
			maxAngle = 65,
		},
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 15,
				angle = 0,
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				health = 30,
				trails = {
					-- dark middle
					{
						radius = 8,
						stepDelta = 4,
						lifetime = 0.25,
						color = { r = 101, g = 68, b = 109 },
					},
					{
						radius = 8,
						stepDelta = 4,
						lifetime = 0.33,
						color = { r = 101, g = 68, b = 109 },
						rake = 2,
					},
					-- core
					{
						radius = 6,
						stepDelta = 2,
						lifetime = 0.04,
						color = { r = 255, g = 120, b = 133 },
					},
					{
						radius = 6,
						stepDelta = 2,
						lifetime = 0.1,
						color = { r = 255, g = 120, b = 133 },
						rake = 3,
					},
				},
			}
			o.extra = {
				moveOrient = true,
				comet = true,
			}
			return o
		end,
		randomize = function(params)
			local p = params
			local dyn = M.bodies["cold comet"].dynParams
			-- speed vector angle
			local angleBH = math.atan2(-p.y, -p.x)
			local a, b = dyn.minAngle, dyn.maxAngle
			local angle = angleBH+math.rad(a+(b-a)*math.random())*(math.random(2)*2-3)
			-- speed vector magnitude
			local speed = dyn.speed * (1 + 0.3 * (math.random() * 2 - 1))
			-- XY speeds
			p.speedX = math.cos(angle) * speed
			p.speedY = math.sin(angle) * speed
			return p
		end,
	},
	["planet"] = {
		spawnChance = 1,
		dynParams = {
			speed = 120,
			minAngle = 70,
			maxAngle = 75,
			minRadius = 50,
			maxRadius = 100,
			minHealth = 50,
			maxHealth = 200,
		},
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 0,
				angle = 0,
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				texture = nil,
				textureScale = nil,
				health = 0,
			}
			o.extra = {
				planet = true,
			}
			return o
		end,
		randomize = function(params)
			local p = params
			local dyn = M.bodies["planet"].dynParams
			-- speed vector angle
			local angleBH = math.atan2(-p.y, -p.x)
			local a, b = dyn.minAngle, dyn.maxAngle
			local angle = angleBH+math.rad(a+(b-a)*math.random())*(math.random(2)*2-3)
			-- speed vector magnitude
			local speed = dyn.speed * (1 + 0.25 * (math.random() * 2 - 1))
			-- XY speeds
			p.speedX = math.cos(angle) * speed
			p.speedY = math.sin(angle) * speed
			-- radius
			local a, b = dyn.minRadius, dyn.maxRadius
			p.radius = a + (b - a) * math.random()
			-- texture
			p.texture = imgPlanets[galaxy.theme][math.random(5)]
			p.textureScale = p.radius/128
			local radiusRatio = (p.radius - dyn.minRadius) / (dyn.maxRadius - dyn.minRadius)
			p.health = dyn.minHealth + (dyn.maxHealth - dyn.minHealth) * radiusRatio
			return p
		end,
	},
	["astronaut"] = {
		spawnChance = 1,
		dynParams = {
			speed = 100,
			minAngle = 35,
			maxAngle = 45,
		},
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 32,
				angle = 0,
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				texture = imgAstronaut,
				textureScale = 1,
				health = 10,
			}
			o.extra = {
				astronaut = true,
			}
			return o
		end,
		randomize = function(params)
			local p = params
			local dyn = M.bodies["astronaut"].dynParams
			-- sprite angle
			p.angle = math.rad(math.random(360))
			-- speed vector angle
			local angleBH = math.atan2(-p.y, -p.x)
			local a, b = dyn.minAngle, dyn.maxAngle
			local angle = angleBH+math.rad(a+math.random(b-a))*(math.random(2)*2-3)
			-- speed vector magnitude
			local speed = dyn.speed * (1 + 0.35 * (math.random() * 2 - 1))
			-- XY speeds
			p.speedX = math.cos(angle) * speed
			p.speedY = math.sin(angle) * speed
			return p
		end,
	},
	["tank"] = {
		spawnChance = 1,
		dynParams = {
			speed = 100,
			minAngle = 35,
			maxAngle = 45,
		},
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 32,
				angle = 0,
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				texture = imgTank,
				textureScale = 1,
				health = 10,
			}
			o.extra = {
				tank = true,
				value = 15,
			}
			return o
		end,
		randomize = function(params)
			local p = params
			local dyn = M.bodies["tank"].dynParams
			-- sprite angle
			p.angle = math.rad(math.random(360))
			-- speed vector angle
			local angleBH = math.atan2(-p.y, -p.x)
			local a, b = dyn.minAngle, dyn.maxAngle
			local angle = angleBH+math.rad(a+math.random(b-a))*(math.random(2)*2-3)
			-- speed vector magnitude
			local speed = dyn.speed * (1 + 0.35 * (math.random() * 2 - 1))
			-- XY speeds
			p.speedX = math.cos(angle) * speed
			p.speedY = math.sin(angle) * speed
			return p
		end,
	},
}

-- ================================
-- Rockets
-- ================================

M.rockets = {
	["default"] = {
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 30,
				angle = math.rad(0),
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				texture = imgRocket["default"],
				textureScale = 1,
				trails = {
					-- left engine
					{
						radius = 10,
						stepDelta = 7,
						lifetime = 0.2,
						color = { r = 81, g = 60, b = 93 },
						rake = 1,
						offsetX = -20,
						offsetY = -30,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					{
						radius = 3,
						stepDelta = 4,
						lifetime = 0.1,
						color = { r = 255, g = 120, b = 133 },
						rake = 1,
						offsetX = -20,
						offsetY = -30,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					-- right engine
					{
						radius = 10,
						stepDelta = 7,
						lifetime = 0.2,
						color = { r = 81, g = 60, b = 93 },
						rake = 1,
						offsetX = 20,
						offsetY = -30,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					{
						radius = 3,
						stepDelta = 4,
						lifetime = 0.1,
						color = { r = 255, g = 120, b = 133 },
						rake = 1,
						offsetX = 20,
						offsetY = -30,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					-- main engine
					{
						radius = 15,
						stepDelta = 10,
						lifetime = 0.6,
						color = { r = 81, g = 60, b = 93 },
						rake = 1,
						offsetY = -35,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					{
						radius = 10,
						stepDelta = 5,
						lifetime = 0.3,
						color = { r = 255, g = 120, b = 133 },
						rake = 1,
						offsetY = -35,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					{
						radius = 7,
						stepDelta = 3,
						lifetime = 0.1,
						color = { r = 255, g = 244, b = 54 },
						rake = 1,
						offsetY = -35,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
				},
			}
			o.extra = {
				enginePower = config.ROCKET_ENGINE_POWER,
				fuel = config.ROCKET_FUEL_MAX,
				rocket = true,
			}
			return o
		end,
	},
	["halloween"] = {
		new = function(x, y)
			local o = {}
			o.params = {
				x = x,
				y = y,
				radius = 30,
				angle = math.rad(0),
				speedX = 0,
				speedY = 0,
				movable = true,
				collidable = true,
				texture = imgRocket["halloween"],
				textureScale = 1,
				trails = {
					-- main engine
					{
						radius = 16,
						stepDelta = 10,
						lifetime = 0.6,
						color = { r = 0, g = 0, b = 0 },
						rake = 1,
						offsetY = -35,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					{
						radius = 8,
						stepDelta = 5,
						lifetime = 0.3,
						color = { r = 255, g = 120, b = 133 },
						rake = 1,
						offsetY = -35,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
					{
						radius = 5,
						stepDelta = 3,
						lifetime = 0.1,
						color = { r = 231, g = 255, b = 170 },
						rake = 1,
						offsetY = -35,
						speed = config.ROCKET_TRAIL_SPEED,
						fading = true,
					},
				},
			}
			o.extra = {
				enginePower = config.ROCKET_ENGINE_POWER,
				fuel = config.ROCKET_FUEL_MAX,
				rocket = true,
			}
			return o
		end,
	},
}

-- ================================
-- Methods
-- ================================

function M.getMovingEntity(par)  -- id, x, y
	-- get new body id
	local newBodyId = nil
	if type(par.id) == "table" then
		newBodyId = M.getRandomId(par.id)
	elseif par.id == "random" then
		newBodyId = M.getRandomId()
	else
		newBodyId = par.id
	end
	-- get body
	local o = M.bodies[newBodyId].new(par.x, par.y)
	o.params = M.bodies[newBodyId].randomize(o.params)
	return o
end

function M.getRandomId(...)
	local id = nil
	local ids, chances = {}, {}
	if ... then
		ids = ...
		table.insert(chances, M.bodies[ids[1]].spawnChance)
		for i = 2,#... do
			table.insert(chances, M.bodies[ids[i]].spawnChance + chances[#chances])
		end
	else
		for k,v in pairs(M.bodies) do
			table.insert(ids, k)
			if #chances > 0 then
				table.insert(chances, v.spawnChance + chances[#chances])
			else
				table.insert(chances, v.spawnChance)
			end
		end
	end
	-- get id
	local rnd = math.random()*chances[#chances]
	for i = 1,#chances do
		if rnd <= chances[i] then
			id = ids[i]
			break
		end
	end
	return id
end

return M
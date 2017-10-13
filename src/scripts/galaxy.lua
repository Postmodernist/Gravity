local planetarium = require("scripts/planetarium")
local starfield = require "scripts/starfield"
local timer = require("scripts/timer")
local body = require("scripts/body")
local rocket = require("scripts/rocket")
local explosion = require("scripts/explosion")
local implosion = require("scripts/implosion")
local pickup = require("scripts/pickup")
local cameraShake = require("scripts/cameraShake")
local pickupEffect = require("scripts/pickupEffect")
local beamPoint = require("scripts/beamPoint")

local M = {
	entities = {},
	collidables = {},
	theBlackHole = nil,
	theRocket = nil,
	theme = "default",
	themesUnlocked = saveData.unlocks,
}
-- subscribe to engine callbacks
addCallbackForward(M, {"update", "draw", "mousepressed", "mousereleased", "keypressed"})

local isChecking = false
local isUpdating = false
local isShowStats = false

function M.init()
	cameraShake.init()
	starfield.init()
	M.theBlackHole = M.createBody(
		{
			x = 0,
			y = 0,
			radius = config.BLACK_HOLE_RADIUS,
			angle = math.rad(0),
			speedY = 0,
			movable = false,
			collidable = true,
			texture = imgBlackHole,
			textureScale = 1,
		},
		{
			blackHole = true,
		}
	)
	M.cometSpawnTimer = timer.new(
		{
			name = "cometSpawnTimer",
			callbackModule = M,
			basePeriod = config.COMETS_SPAWN_PERIOD,
			randomness = 0.3,
			isRepeating = true,
		}
	)
	timekeeper.addTimer(M.cometSpawnTimer)
	M.planetSpawnTimer = timer.new(
		{
			name = "planetSpawnTimer",
			callbackModule = M,
			basePeriod = config.PLANETS_SPAWN_PERIOD,
			randomness = 0.3,
			isRepeating = true,
		}
	)
	timekeeper.addTimer(M.planetSpawnTimer)
	M.astronautSpawnTimer = timer.new(
		{
			name = "astronautSpawnTimer",
			callbackModule = M,
			basePeriod = config.ASTRONAUTS_SPAWN_PERIOD,
			randomness = 0.3,
			isRepeating = true,
		}
	)
	timekeeper.addTimer(M.astronautSpawnTimer)
	M.astronautSpawnTimer:pause()
end

-- ================================
-- Love Callbacks
-- ================================

function M.update(dt)
	cameraShake.update(dt)
	starfield.update(dt)
	if not isChecking then M.checkCollidables() end
	if not isUpdating then M.updateEntities(dt) end
end

function M.draw()
	cameraShake.draw()
	starfield.draw()
	-- draw boundaries
	love.graphics.setLineWidth(1)
	local x, y, r, isOffscr = cam.getScreenCoords({x = 0, y = 0, scale = config.VISIBILITY_RADIUS})
	love.graphics.setColor(0, 128, 0)
	love.graphics.circle("line", x, y, r, 100)
	local x, y, r, isOffscr = cam.getScreenCoords({ x = 0, y = 0, scale = config.GALAXY_RADIUS})
	love.graphics.setColor(128, 0, 0)
	love.graphics.circle("line", x, y, r, 100)
	-- DEBUG - draw offscreen zone
	-- love.graphics.setColor(0, 0, 255)
	-- love.graphics.polygon(
	-- 	"line",
	-- 	200, 200,
	-- 	cam.width - 200, 200,
	-- 	cam.width - 200, cam.height - 200,
	-- 	200, cam.height - 200
	-- )
	-- draw black hole core
	local x, y, r, isOffscr = cam.getScreenCoords({x = 0, y = 0, scale = 45})
	love.graphics.setColor(0, 0, 0)
	love.graphics.circle("fill", x, y, r, 20)
	-- draw entities
	M.drawEntities()
	-- draw game stats
	if M.theRocket then
		M.rocketSpeed = math.floor(math.sqrt(M.theRocket.speedX^2 + M.theRocket.speedY^2) + 0.5)
		M.rocketDistanceToBH = math.floor(
			utils.getDistance({0, 0}, {M.theRocket.x, M.theRocket.y}) + 0.5
		)
	end
	if isShowStats then
		love.graphics.setFont(fontConsole)
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("Rocket Speed: "..(M.rocketSpeed or "N/A"), cam.width / 2 - 18, 10)
		love.graphics.print("Rocket to BH Distance: "..(M.rocketDistanceToBH or "N/A"), cam.width / 2 - 71, 25)
		love.graphics.print("Objects is space: "..(#M.collidables-1), cam.width / 2 - 34, 40)
		love.graphics.print("Comets spawn period: "..(M.cometSpawnTimer.basePeriod), cam.width / 2 - 66, 55)
	end
end

function M.mousepressed(x, y, button, istouch)
	if M.theRocket then M.theRocket:mousepressed(x, y, button) end
end

function M.mousereleased(x, y, button, istouch)
	if M.theRocket then M.theRocket:mousereleased(x, y, button) end
end

function M.keypressed(key, scancode, isrepeat)
	if key == "space" and M.theRocket then M.theRocket:kill( "explode" )
	elseif key == "r" then feedbackHub.show( "author" )
	elseif key == "e" then local a = { astronaut = true }; pickup.init( a )
	elseif key == "`" then isShowStats = not isShowStats end
end

-- ================================
-- Events
-- ================================

function M.onCollision(a, b)
	if a == M.theBlackHole then
		b:kill("implode")
	elseif b == M.theBlackHole then
		a:kill("implode")
	elseif (a.astronaut and b.astronaut) or
		   (a.astronaut and b.tank) or
		   (a.tank and b.astronaut) or
		   (a.tank and b.tank) then
		-- bounce
		if a.bounceBro ~= b then
			a:bounce(b)
			local speedX, speedY = a.speedX, a.speedY
			a.speedX, a.speedY = b.speedX, b.speedY
			b.speedX, b.speedY = speedX, speedY
		end
	elseif a.astronaut and b.rocket then
		a:kill("pickup")
		gameState.onAstronautPickup()
 	elseif a.rocket and b.astronaut then
		b:kill("pickup")
		gameState.onAstronautPickup()
	elseif a.tank and b.rocket then
		gameState.onTankPickup(a)
		a:kill("pickup")
 	elseif a.rocket and b.tank then
		gameState.onTankPickup(b)
		b:kill("pickup")
	elseif a.planet and not b.planet then
		b:kill("explode")
	elseif not a.planet and b.planet then
		a:kill("explode")
	elseif a.planet and b.planet then
		if a.radius > b.radius then
			b:kill("explode")
		else
			a:kill("explode")
		end
	else
		a:kill("explode")
		b:kill("explode")
	end
end

function M.onBodyDestroyed(event)
	-- create effect
	if event.effect then
		if event.effect == "explode" then
			local effect = explosion.new(
				{
					x = event.entity.x,
					y = event.entity.y,
					radius = event.entity.radius * config.EXPLOSION_SCALE,
					soundType = event.soundType,
				}
			)
			effect:init()
			table.insert(M.entities, effect)
		elseif event.effect == "implode" then
			local effect = implosion.new(
				{
					x = event.entity.x,
					y = event.entity.y,
					radius = event.entity.radius * config.IMPLOSION_SCALE,
				}
			)
			effect:init()
			table.insert(M.entities, effect)
		elseif event.effect == "pickup" then
			pickup.init(event.entity)
			local effect = pickupEffect.new(
				{
					x = event.entity.x,
					y = event.entity.y,
					radius = event.entity.radius,
				}
			)
			effect:init()
			table.insert(M.entities, effect)
		end
	end
	-- clear lists
	utils.removeFromList(M.entities, event.entity)
	if event.entity.collidable then utils.removeFromList(M.collidables, event.entity) end
	if event.entity == M.theRocket then M.theRocket = nil end
end

function M.onEffectFinished(event)
	utils.removeFromList(M.entities, event.entity)
end

-- timer events

function M.onTimerTick(event)
	-- spawn new body
	local angle = math.rad(math.random(360))
	local range = config.BODIES_SPAWN_RANGE_MIN + 
		math.random(config.BODIES_SPAWN_RANGE_MAX - config.BODIES_SPAWN_RANGE_MIN)
	local x, y = math.cos(angle) * range, math.sin(angle) * range
	local id = nil
	if event.timer == M.cometSpawnTimer then
		id = {"hot comet", "cold comet"}
	elseif event.timer == M.planetSpawnTimer then
		id = "planet"
	elseif event.timer == M.astronautSpawnTimer then
		id = "astronaut"
	else return end
	local o = planetarium.getMovingEntity({id = id, x = x, y = y})
	M.createBody(o.params, o.extra)
end

function M.onTimerFinish(event)
	if event.timer == M.sosTimer then
		M.sosTimer = nil
	end
end

-- ================================
-- Methods
-- ================================

function M.checkCollidables()
	isChecking = true
	local col = {}
	for i,v in ipairs(M.collidables) do
		table.insert(col, v)
	end
	local ent = {}
	for i,v in ipairs(M.entities) do
		table.insert(ent, v)
	end
	-- mining
	if love.mouse.isDown(1) then
		local isBeam = false
		local mX, mY = cam.getMouseXY(love.mouse.getPosition())
		for i = 2, #col do
			if col[i].planet then
				local d = utils.getDistance({mX, mY}, {col[i].x, col[i].y})
				if d < col[i].radius then
					if M.theRocket then
						M.theRocket.miningBeam = beamPoint.getBeamPoint(col, {x = mX, y = mY})
						isBeam = true
					end
					break
				end
			end
		end
		if not isBeam and M.theRocket then M.theRocket.miningBeam = nil end
	else
		if M.theRocket then M.theRocket.miningBeam = nil end
	end
	-- collisions
	if #col > 1 then
		for i = 1,(#col-1) do
			for j = (i+1),#col do
				local a, b = col[i], col[j]
				local d = utils.getDistance({ a.x, a.y }, { b.x, b.y })
				if d < (a.radius+b.radius) then
					M.onCollision(a, b)
				end
			end
		end
	end
	-- flyaways
	for i = 1,#ent do
		local d = utils.getDistance({ ent[i].x, ent[i].y }, { 0, 0 })
		--- rocket sos signal
		if ent[i] == M.theRocket and not M.sosTimer then
			if d > 3*config.GALAXY_RADIUS/4 then
				sndSos:setPosition(M.theRocket.x - cam.x, M.theRocket.y - cam.y, 0)
				sndSos:play()
				M.sosTimer = timer.new(
					{
						name = "sosTimer",
						callbackModule = M,
						basePeriod = config.SOS_SIGNAL_PERIOD,
						randomness = 0,
						isRepeating = false,
					}
				)
				timekeeper.addTimer(M.sosTimer)
			end
		end
		-- flyout check
		if d > config.GALAXY_RADIUS then
			if ent[i] then ent[i]:kill() end
		end
	end
	isChecking = false
end

function M.updateEntities(dt)
	isUpdating = true
	-- rotate black hole
	M.theBlackHole.angle = M.theBlackHole.angle + dt * math.rad(80)
	-- update entities
	local ent = {}
	for i,v in pairs(M.entities) do
		table.insert(ent, v)
	end
	for i = 1,#ent do
		if ent[i] then ent[i]:update(dt) end
	end
	isUpdating = false
end

function M.drawEntities()
	for i = 1,#M.entities do
		if M.entities[i] and (not M.entities[i].rocket) then M.entities[i]:draw() end
	end
	if M.theRocket then M.theRocket:draw() end
end

function M.createBody(params, extra)
	local o = {}
	if extra.rocket then
		o = rocket:new(params, extra)
	else
		o = body:new(params, extra)
	end
	o:init()
	table.insert(M.entities, o)
	if params.collidable then table.insert(M.collidables, o) end
	return o
end

function M.spawnTanks(planet)
	local minRad = planetarium.bodies["planet"].dynParams.minRadius
	local maxRad = planetarium.bodies["planet"].dynParams.maxRadius
	local radRatio = (planet.radius - minRad) / (maxRad - minRad)
	local tanksNum = 0
	if radRatio > 0.66 then tanksNum = 3
	elseif radRatio > 0.33 then tanksNum = 2
	else tanksNum = 1 end
	local angles = {}
	angles[1] = math.random() * math.pi * 2
	for i = 1, tanksNum do
		if i > 1 then angles[i] = angles[i-1] + math.rad(120) end
		local x = planet.x + math.cos(angles[i]) * planet.radius
		local y = planet.y + math.sin(angles[i]) * planet.radius
		local o = planetarium.getMovingEntity({id = "tank", x = x, y = y})
		M.createBody(o.params, o.extra)
	end
end

return M
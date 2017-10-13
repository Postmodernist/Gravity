local star = require("scripts/star")
local timer = require("scripts/timer")

local M = {}
local stars = {}
local isClusterAhead = false
local distance = 0

function M.init()
	-- generate initial stars cluster
	if config.OBSERVER_SPEED >= 0 then
		M.generateStars(config.STARS_NUMBER, 0, config.CLUSTER_DEPTH)
	else 
		M.generateStars(config.STARS_NUMBER, config.FAR_CLIP, config.FAR_CLIP-config.CLUSTER_DEPTH)
	end
	-- create cluster generation timer
	timekeeper.addTimer(timer.new(
			{
				name = "starsTimer",
				callbackModule = M,
				basePeriod = 1,
				randomness = 0,
				isRepeating = true,
			}
		)
	)
	
end

-- ================================
-- Love Callbacks
-- ================================

function M.update(dt)
	if #stars > 0 then
		for i = 1,#stars do
			if stars[i] then stars[i]:update(dt) end
		end
	end
end

function M.draw()
	if #stars > 0 then
		for i = 1,#stars do
			stars[i]:draw()
		end
	end	
end

-- ================================
-- Events
-- ================================

function M.onStarClipped(event)
	utils.removeFromList(stars, event.star)
end

function M.onTimerTick(event)
	if event.timer.name == "starsTimer" then
		-- generate new stars cluster
		local n = config.STARS_NUMBER*math.abs(config.OBSERVER_SPEED)/config.CLUSTER_DEPTH  -- stars per sec
		if config.OBSERVER_SPEED >= 0 then
			M.generateStars(
				n,
				config.CLUSTER_DEPTH-config.OBSERVER_SPEED,
				config.CLUSTER_DEPTH
			)
		else
			M.generateStars(
				n,
				config.FAR_CLIP-config.CLUSTER_DEPTH-config.OBSERVER_SPEED,
				config.FAR_CLIP-config.CLUSTER_DEPTH
			)
		end
	end
end

-- ================================
-- Methods
-- ================================

function M.generateStars(number, near, far)
	for i = 1, number do
		local size = 10 + math.random(5)
		local distance = near + math.random() * (far - near)
		local radius = 1 + math.random() * 7
		local angle = math.rad(math.random() * 360)
		local s = star.new(
			{
				size = size,
				distance = distance,
				radius = radius,
				angle = angle,
				starfield = M,
			}
		)
		table.insert(stars, s)
	end
end

return M
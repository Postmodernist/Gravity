local trail = require("scripts/trail")

local M = {}

function M.new(params)
	o = {}
	-- parameters
	o.params = params
	o.host = params.host
	o.rake = params.rake
	o.offsetX = params.offsetX or 0
	o.offsetY = params.offsetY or 0
	o.radius = params.radius
	if params.fading then o.fading = params.fading
	else o.fading = false end
	-- variables
	o.tracks = params.rake*2-1
	o.hostlings = {}
	o.trailings = {}
	o.isUpdating = false
	setmetatable(o, { __index = M })
	return o
end

function M:init()
	self:createHostlings()
end

-- ================================
-- Love Callbacks
-- ================================

function M:update(dt)
	if not self.isUpdating then
		self.isUpdating = true
		if #self.hostlings > 0 then
			for i = 1,#self.hostlings do
				-- update hostling
				local h = self.hostlings[i]
				h.x = h.rad * math.cos(h.ang + self.host.angle - math.pi/2) + self.host.x
				h.y = h.rad * math.sin(h.ang + self.host.angle - math.pi/2) + self.host.y
				h.angle = self.host.angle
				-- update trailing
				self.trailings[i]:update(dt)
			end
		end
		self.isUpdating = false
	end
end

function M:draw()
	-- DEBUG - draw hostlings
	-- if #self.hostlings > 0 then
	-- 	love.graphics.setColor(self.params.color.r, self.params.color.g, self.params.color.b)
	-- 	for i = 1,#self.hostlings do
	-- 		love.graphics.circle("fill", self.hostlings[i].x, self.hostlings[i].y, self.radius/self.tracks, 12)
	-- 	end
	-- end
	-- draw trailings
	local t = self.trailings
	if #t > 0 then
		for i = 1,#t do
			t[i]:draw()
		end
	end
end

-- ================================
-- Methods
-- ================================

function M:activate()
	for i = 1,#self.trailings do
		self.trailings[i]:activate()
	end
end

function M:deactivate()
	for i = 1,#self.trailings do
		self.trailings[i]:deactivate()
	end
end

function M:createHostlings()
	local hostlingRadius = self.radius/self.tracks
	for i = 1,self.tracks,2 do
		local hostling = self:getHostlingXY(hostlingRadius, i)
		table.insert(self.hostlings, hostling)
		local t = trail.new(
			{
				host = hostling,
				radius = hostlingRadius,
				stepDelta = self.params.stepDelta,
				lifetime = self.params.lifetime*(1+0.2*(math.random()*2-1)),
				color = self.params.color,
				speed = self.params.speed or 0,
				fading = self.fading,
			}
		)
		t:activate()
		table.insert(self.trailings, t)
	end
end

function M:getHostlingXY(hostlingRadius, num)
	local offsetX = hostlingRadius*(2*num - 1) - self.radius - self.offsetX
	local ang = math.atan2(self.offsetY, offsetX)
	local r = math.sqrt(offsetX^2 + self.offsetY^2)
	local x = r*math.cos(ang + self.host.angle - math.pi/2) + self.host.x
	local y = r*math.sin(ang + self.host.angle - math.pi/2) + self.host.y
	return { x = x, y = y, rad = r, ang = ang, angle = self.host.angle }
end

return M
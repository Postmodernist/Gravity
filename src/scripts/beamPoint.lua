local M = {}

local function rotatePoint(ang, point)
	local r = math.sqrt(point.x^2 + point.y^2)
	local a = math.atan2(point.y, point.x) - ang
	return {x = r * math.cos(a), y = r * math.sin(a)}
end

function M.getBeamPoint(objects, target)
	local x, y = 0, 0
	local beamAng = math.atan2(target.y - galaxy.theRocket.y, target.x - galaxy.theRocket.x)
	local rotA = rotatePoint(beamAng, galaxy.theRocket)
	local rotB = rotatePoint(beamAng, target)
	local bPnt, bObj = nil, nil
	for i = 2, #objects do
		local rotObj = rotatePoint(beamAng, objects[i])
		local h = rotObj.y - rotA.y
		if h <= objects[i].radius then
			local dx = math.sqrt(objects[i].radius^2 - h^2)
			x, y = rotObj.x - dx, rotA.y
			if (x >= rotA.x) and (x <= rotB.x) then
				if bPnt then
					if x < bPnt.x then
						bPnt = {x = x, y = y}
						bObj = objects[i]
					end
				else
					bPnt = {x = x, y = y}
					bObj = objects[i]
				end
			end
		end
	end
	if bPnt then
		return {object = bObj, point = rotatePoint(-beamAng, bPnt)}
	end
end

return M
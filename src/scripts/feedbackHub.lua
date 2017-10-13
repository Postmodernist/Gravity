local feedback = require("scripts/feedback")

local M = {}
-- subscribe to engine callbacks
addCallbackForward(M, { "update", "draw" })

local feedbacks = {}

M.tokens = {
	["combo"] = function()
		local n = gameState.states["play"].stats.comboNum
		table.insert(feedbacks, feedback.new(
				{
					text = n.."x Combo!",
					font = fontTitle,
					color = { r = 255, g = 255, b = 255 },
					duration = 3,
					texture = imgFeedback01,
				}
			)
		)
	end,
	["speed rescue"] = function()
		local text = "Light speed rescue!"
		local n = gameState.states["play"].stats.speedRescueNum
		if n > 1 then text = n.."x light speed rescues!" end
		table.insert(feedbacks, feedback.new(
				{
					text = text,
					font = fontTitle,
					color = { r = 255, g = 255, b = 255 },
					duration = 3,
					texture = imgFeedback01,
				}
			)
		)

	end,
	["event horizon"] = function()
		if galaxy.theRocket then
			local text = "Event horizon surfing!"
			local n = gameState.states["play"].stats.eventHorizonNum
			if n > 1 then text = n.."x event horizon surfings!" end
			table.insert(feedbacks, feedback.new(
					{
						text = text,
						font = fontTitle,
						color = {r = 255, g = 255, b = 255 },
						duration = 3,
						texture = imgFeedback02,
					}
				)
			)
		end
	end,
	["author"] = function()
		table.insert(feedbacks, feedback.new(
				{
					text = "Inok was here",
					font = fontTitle,
					color = { r = 255, g = 255, b = 255 },
					duration = 3,
					texture = imgAvatar,
				}
			)
		)
	end,
	["halloween"] = function()
		table.insert(feedbacks, feedback.new(
				{
					text = "Halloween theme unlocked!",
					font = fontTitle,
					color = { r = 255, g = 255, b = 255 },
					duration = 3,
					texture = imgPlanets["halloween"][4],
					textureScale = 0.25,
				}
			)
		)
	end,
}

function M.update(dt)
	if #feedbacks > 0 then
		for i = 1,#feedbacks do
			if feedbacks[i] then feedbacks[i]:update(dt) end
		end
	end	
end

function M.draw()
	if #feedbacks > 0 then
		for i = 1,#feedbacks do
			if feedbacks[i] then feedbacks[i]:draw(i) end
		end
	end
end

function M.onFeedbackFinished(event)
	utils.removeFromList(feedbacks, event.entity)
end

function M.show(id)
	if M.tokens[id] then
		M.tokens[id]()
	else
		print("ERROR! Invalid feedback id: "..id..". -- feedbackHub.show()")
	end
end

return M
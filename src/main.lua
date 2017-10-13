-- Gravity main

local forwards = {
	update = {},
	draw = {},
	mousepressed = {},
	mousereleased = {},
	keypressed = {},
	wheelmoved = {},
}

local function forwardCallback(name, ...)
	for i = 1,#forwards[name] do
		if forwards[name][i] then forwards[name][i][name](...) end
	end
end

function love.load()
	-- open/create save file
	saveFile = love.filesystem.newFile( "gravity.sav" )
	saveData = { highScore = 0, unlocks = 1, tutorial = 1 }
	if love.filesystem.exists( "gravity.sav" ) then
		saveFile:open("r")
		local i = saveFile:lines()
		saveData.highScore = tonumber( i() )
		saveData.unlocks = tonumber( i() )
		saveData.tutorial = tonumber( i() )
		saveFile:close()
	else
		saveFile:open( "w" )
		saveFile:write( 0 .. "\n" .. 1 .. "\n" .. 1)
		saveFile:close()
	end
	-- set up the game
	math.randomseed(math.floor(os.clock() * 100000))
	config = require("scripts/config")
	cam = require("scripts/camera")
	-- load game resources
	local resources = require("scripts/resources")
	resources.load()
	-- load public modules
	utils = require("scripts/utils")
	galaxy = require("scripts/galaxy")
	gameState = require("scripts/gameState")
	timekeeper = require("scripts/timekeeper")
	feedbackHub = require("scripts/feedbackHub")
	loadingScreen = require("scripts/loadingScreen")
	-- run the game
	love.graphics.setBackgroundColor(59, 50, 81)
	love.audio.setDistanceModel("linearclamped")
	loadingScreen.activate()
	galaxy.init()
	gameState.init()
	loadingScreen.deactivate()
end

-- ================================
-- Love Callbacks
-- ================================

function love.update(dt)
	if gameIsPaused then
		return
	end
	forwardCallback("update", dt)
end

function love.draw()
	forwardCallback("draw")
end

function love.mousepressed(x, y, button, istouch)
	forwardCallback("mousepressed", x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
	forwardCallback("mousereleased", x, y, button, istouch)
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then love.event.quit() end
	forwardCallback("keypressed", key, scancode, isrepeat)
end

function love.wheelmoved(x, y)
	forwardCallback("wheelmoved", x, y)
end

function love.focus(f)
	gameIsPaused = not f
end

function love.quit()
	-- save highscores and unlocked themes
	saveFile:open( "w" )
	saveFile:write( saveData.highScore .. "\n" .. saveData.unlocks .. "\n" .. saveData.tutorial )
	saveFile:close()
end

-- ================================
-- Methods
-- ================================

function addCallbackForward(module, forwardList, ...)
	for i = 1,#forwardList do
		if ... then 
			table.insert(forwards[forwardList[i]], ..., module)
		else
			table.insert(forwards[forwardList[i]], module)
		end
	end
end

function removeCallbackForward(module, forwardList)
	if forwardList then
		for i = 1,#forwardList do
			utils.removeFromList(forwards[forwardList[i]], module)
		end
	else
		for i,v in pairs(forwards) do
			utils.removeFromList(v, module)
		end
	end
end

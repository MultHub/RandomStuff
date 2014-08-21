local function cprint(s, y)
	local w = term.getSize()
	local cx = math.ceil(w / 2)
	term.setCursorPos(cx - math.floor(s:len() / 2), y)
	print(s)
end

local random = true

local tArgs = {...}
if #tArgs > 0 then
	for i = 1, #tArgs do
		if tArgs[i] == "norandom" then
			random = false
		end
	end
end

local world = {}
local worldNew = {}
local w, h = term.getSize()
for _x = 1, w do
	world[_x] = {}
	worldNew[_x] = {}
	for _y = 1, h-1 do
		if random then
			world[_x][_y] = math.random(1, 5) == 1
		else
			world[_x][_y] = false
		end
		worldNew[_x][_y] = false
	end
end

local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw

local function terminate()
	local running = true
	while running do
		local event = os.pullEvent()
		if event == "terminate" then
			running = false
		end
	end
end

local ticks = 0
local simulating = true
local simulationSpeed = 0.5

local function render()
	while true do
		local timer
		for _x = 1, #world do
			for _y = 1, #world[_x] do
				if world[_x][_y] ~= worldNew[_x][_y] then
					term.setBackgroundColor(world[_x][_y] and colors.white or colors.black)
					term.setCursorPos(_x, _y)
					write(" ")
					forceRedraw = false
				end
			end
		end
		if simulating then
			local function getCells(x, y)
				local count = 0
				if x > 1 and y > 1 and world[x-1][y-1] then
					count = count + 1
				end
				if y > 1 and world[x][y-1] then
					count = count + 1
				end
				if x < #world and y > 1 and world[x+1][y-1] then
					count = count + 1
				end
				if x > 1 and world[x-1][y] then
					count = count + 1
				end
				if x < #world and world[x+1][y] then
					count = count + 1
				end
				if x > 1 and y < #world[x] and world[x-1][y+1] then
					count = count + 1
				end
				if y < #world[x] and world[x][y+1] then
					count = count + 1
				end
				if x < #world and y < #world[x] and world[x+1][y+1] then
					count = count + 1
				end
				return count
			end
			for _x = 1, #world do
				for _y = 1, #world[_x] do
					local count = getCells(_x, _y)
					if count < 2 or count > 3 and world[_x][_y] == true then
						worldNew[_x][_y] = false
					elseif (count == 2 or count == 3) and world[_x][_y] == true then
						worldNew[_x][_y] = true
					elseif count == 3 and world[_x][_y] == false then
						worldNew[_x][_y] = true
					end
				end
			end
			for _x = 1, #world do
				for _y = 1, #world[_x] do
					if world[_x][_y] ~= worldNew[_x][_y] then
						term.setCursorPos(_x, _y)
						term.setBackgroundColor(worldNew[_x][_y] and colors.white or colors.black)
						write(" ")
					end
					world[_x][_y] = worldNew[_x][_y]
				end
			end
			ticks = ticks + 1
			timer = os.startTimer(simulationSpeed)
		end
		term.setCursorPos(1, h)
		term.setBackgroundColor(colors.black)
		term.clearLine()
		write("Generation "..ticks..", speed "..simulationSpeed..(simulating and "" or " (PAUSED)"))
		while true do
			local event = {os.pullEvent()}
			if event[1] == "key" then
				if event[2] == keys.space then
					simulating = not simulating
					break
				elseif event[2] == keys.equals then
					simulationSpeed = simulationSpeed / 2
				elseif event[2] == keys.minus then
					simulationSpeed = simulationSpeed * 2
				end
			elseif event[1] == "timer" and event[2] == timer then
				break
			elseif event[1] == "mouse_click" or event[1] == "mouse_drag" then
				if event[3] >= 1 and event[3] <= #world and event[4] >= 1 and event[4] <= #world[event[4]] then
					local newState = event[2] == 1
					world[event[3]][event[4]] = newState
					worldNew[event[3]][event[4]] = not newState
					break
				end
			end
		end
	end
end

parallel.waitForAny(terminate, render)
os.pullEvent = oldPullEvent

term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)
term.clear()
cprint(" --- END --- ", 2)
term.setCursorPos(2, 4)
print("Ticks: "..ticks)
term.setCursorPos(1, 6)

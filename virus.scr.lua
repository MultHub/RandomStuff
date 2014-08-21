-- INTERNAL
local function cprint(s, y)
	local w = term.getSize()
	local cx = math.ceil(w / 2)
	term.setCursorPos(cx - math.floor(s:len() / 2), y)
	print(s)
end
local function colorRange(min, max)
	local ret = {}
	for i = min, max do
		table.insert(ret, 2 ^ i)
	end
	return unpack(ret)
end

-- SCREENSAVER CONFIG
local screensaver = {
	text = {
		background = "Virus Screensaver :D",
		centerText = "Virus Screensaver :D",
	},
	colors = {
		background = {
			foreground = {colorRange(0, 15)},
			background = {colorRange(0, 15)},
		},
		centerText = {
			foreground = colors.white,
			background = colors.black,
		},
	},
}

if not term.isColor() then
	screensaver.colors.background.foreground = {1, 32768}
	screensaver.colors.background.background = {1, 32768}
	screensaver.colors.centerText.foreground = colors.white
	screensaver.colors.centerText.background = colors.black
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

local function render()
	while true do
		local w, h = term.getSize()
		local cx, cy = math.ceil(w / 2), math.ceil(h / 2)
		term.setCursorPos(math.random(1, w), math.random(1, h))
		local randomCharIndex = math.random(1, screensaver.text.background:len())
		local randomChar = screensaver.text.background:sub(randomCharIndex, randomCharIndex)
		local randomBg = screensaver.colors.background.background[math.random(1, #screensaver.colors.background.background)]
		local randomFg = screensaver.colors.background.foreground[math.random(1, #screensaver.colors.background.foreground)]
		term.setTextColor(randomFg)
		term.setBackgroundColor(randomBg)
		write(randomChar)
		term.setTextColor(screensaver.colors.centerText.foreground)
		term.setBackgroundColor(screensaver.colors.centerText.background)
		cprint(screensaver.text.centerText, cy)
		ticks = ticks + 1
		os.queueEvent("random")
		os.pullEvent()
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

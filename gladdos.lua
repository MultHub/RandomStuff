local port
local tableize = true
local tableObject = "line"
local tArgs = {...}
if #tArgs < 1 or (#tArgs < 2 and tArgs[1] == "-r") then
	print("Usage: GLaDDoS [-r|+<tableObject>] <channel>")
	return
end
if tArgs[1] == "-r" then
	tableize = false
	table.remove(tArgs, 1)
end
if tArgs[1]:sub(1, 1) == "+" then
	tableObject = tArgs[1]:sub(2)
	table.remove(tArgs, 1)
end
port = tonumber(tArgs[1])

local commands = {
	port = function(id)
		if not id then
			print("Invalid port")
			return
		end
		if not tonumber(id) then
			print("Not a number")
			return
		end
		if tonumber(id) > 65535 or tonumber(id) < 0 then
			print("Invalid port")
			return
		end
		port = tonumber(id)
	end,
	raw = function(bool)
		if bool == "true" then
			tableize = false
		else
			tableize = true
		end
	end,
	["raw+"] = function(text)
		tableObject = text
	end,
}

function commands.help()
	local names = {}
	for k in pairs(commands) do
		table.insert(names, k)
	end
	table.sort(names)
	print("Commands:")
	textutils.tabulate(names)
end

local function handleCommands(s)
	local parts = {}
	for part in string.gmatch(s, "[^ ]+") do
		table.insert(parts, part)
	end
	if commands[ parts[1] ] then
		commands[ parts[1] ](unpack(parts, 2))
	end
end

print("GLaDDoS 1.3")

local modem = peripheral.wrap("back")
local hist = {}
pcall(function()
	while true do
		local input = read(nil, hist)
		table.insert(hist, input)
		if input:sub(1, 1) ~= "/" and input:sub(1, 1) ~= "." then
			input = "/say "..input
		end
		input = input:gsub("&", string.char(0xc2)..string.char(0xa7))
		input = input:gsub("\\"..string.char(0xc2)..string.char(0xa7), "&")
		if input:sub(1, 1) == "/" then
			modem.open(port)
			modem.transmit(port, os.getComputerID(), (tableize and {[tableObject] = (input:sub(1, 1) == "." and input:sub(2) or input)} or (input:sub(1, 1) == "." and input:sub(2) or input)))
			modem.close(port)
		else
			handleCommands(input:sub(2))
		end
	end
end)

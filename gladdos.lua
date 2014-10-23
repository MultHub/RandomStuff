local port
local tableize = true
local tableObject = "line"
local tArgs = {...}

local function loadProfile(name)
	if not name then return end
	local f = fs.open(".GLaDDoS-profiles", "r")
	if not f then
		print("No profiles found")
		return
	end
	local profiles = textutils.unserialize(f.readAll())
	f.close()
	if not profiles[name] then
		print("Unknown profile")
		return
	end
	port = profiles[name].port
	tableize = profiles[name].tableize
	tableObject = profiles[name].tableObject
	print("Loaded profile "..name)
end

local function saveProfile(name)
	if not name then return end
	local f = fs.open(".GLaDDoS-profiles", "r")
	local profiles
	if f then
		profiles = textutils.unserialize(f.readAll())
		f.close()
	end
	profiles[name] = {
		port = port,
		tableize = tableize,
		tableObject = tableObject,
	}
	local f = fs.open(".GLaDDoS-profiles", "w")
	f.write(textutils.serialize(profiles))
	f.close()
end

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
	saveprof = saveProfile
	loadprof = loadProfile
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
			if port then
				modem.open(port)
				modem.transmit(port, os.getComputerID(), (tableize and {[tableObject] = (input:sub(1, 1) == "." and input:sub(2) or input)} or (input:sub(1, 1) == "." and input:sub(2) or input)))
				modem.close(port)
			else
				print("Set port with .port <id>")
			end
		else
			handleCommands(input:sub(2))
		end
	end
end)

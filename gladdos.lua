local useMeta
local port
local tableize = true
local tableObject = "line"
local tArgs = {...}
local prefix = "/say "

local replacers = {}

local f = fs.open(".GLaDDoS-replacers", "r")
if f then
	local c = textutils.unserialize(f.readAll())
	f.close()
	if c then
		for sSearch, sReplace in pairs(c) do
			replacers[sSearch] = sReplace
		end
	end
end

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
	useMeta = profiles[name].useMeta
	print("Loaded profile "..name)
end

loadProfile(unpack(tArgs))

local function saveProfile(name)
	if not name then return end
	local f = fs.open(".GLaDDoS-profiles", "r")
	local profiles = {}
	if f then
		profiles = textutils.unserialize(f.readAll())
		f.close()
	end
	profiles[name] = {
		port = port,
		tableize = tableize,
		tableObject = tableObject,
		useMeta = useMeta,
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
	meta = function(bool)
		useMeta = bool == "true"
	end,
	saveprof = saveProfile,
	loadprof = loadProfile,
	["shell"] = function()
		print("Type exit to return to GLaDDoS")
		shell.run("shell")
	end,
	update = function()
		local r = http.get("https://raw.github.com/MultHub/RandomStuff/master/gladdos.lua")
		local f = fs.open(shell.getRunningProgram(), "w")
		f.write(r.readAll())
		f.close()
		r.close()
		print("Restart GLaDDoS to finish update.")
	end,
	spoofid = function(id)
		print("Old ID: "..os.getComputerID())
		os.getComputerID = function()
			return tonumber(id)
		end
		print("New ID: "..os.getComputerID())
	end,
	prefix = function(...)
		prefix = table.concat({...}, " ")
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
	local tmp = ""
	for i = 1, #s do
		if s:sub(i, i) == " " then
			table.insert(parts, tmp)
			tmp = ""
		else
			tmp = tmp .. s:sub(i, i)
		end
	end
	table.insert(parts, tmp)
	if commands[ parts[1] ] then
		commands[ parts[1] ](unpack(parts, 2))
	end
end

print("GLaDDoS 1.4")

local modems = {}
for i, v in pairs(rs.getSides()) do
	if peripheral.getType(v) == "modem" then
		table.insert(modems, peripheral.wrap(v))
	end
end
local hist = {}
local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw
parallel.waitForAny(function()
	while true do
		local e = os.pullEvent()
		if e == "terminate" then
			break
		end
	end
end, function()
	while true do
		local input = read(nil, hist)
		table.insert(hist, input)
		if input:sub(1, 1) ~= "/" and input:sub(1, 1) ~= "." then
			input = prefix..input
		end
		input = input:gsub("&", string.char(0xc2)..string.char(0xa7))
		input = input:gsub("\\"..string.char(0xc2)..string.char(0xa7), "&")
		input = input:gsub("\\0%d%d%d", function(str)
			return loadstring("return '\\"..str:sub(3).."'")()
		end)
		for k, v in pairs(replacers) do
			input = input:gsub(k, v)
		end
		if input:sub(1, 1) == "/" then
			if port then
				if useMeta then
					os.sendMessage(port, (tableize and {[tableObject] = (input:sub(1, 1) == "." and input:sub(2) or input)} or (input:sub(1, 1) == "." and input:sub(2) or input)))
				else
					for i, modem in pairs(modems) do
						modem.open(port)
						modem.transmit(port, os.getComputerID(), (tableize and {[tableObject] = (input:sub(1, 1) == "." and input:sub(2) or input)} or (input:sub(1, 1) == "." and input:sub(2) or input)))
						modem.close(port)
					end
				end
			else
				print("Set port with .port <id>")
			end
		else
			handleCommands(input:sub(2))
		end
	end
end)
os.pullEvent = oldPullEvent

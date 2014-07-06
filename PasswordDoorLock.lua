local config = setmetatable({}, {__index=_G})
local remote = http.get("https://raw.github.com/MultHub/LMNet-OS/master/src/apis/config.lua")
setfenv(loadstring(remote.readAll(), "API"), config)()
remote.close()

if not fs.exists(".pwdl_data") then
	term.clear()
	term.setCursorPos(1, 1)
	print("MultMine's Password Door Lock v1")
	write("  Lock name: ")
	config.write(".pwdl_data", "lockName", read())
	write("   Password: ")
	config.write(".pwdl_data", "password", read())
	write("  Exit pass: ")
	config.write(".pwdl_data", "exitPass", read())
	write("  Open time: ")
	config.write(".pwdl_data", "openTime", tonumber(read()))
	write("Pass prompt: ")
	config.write(".pwdl_data", "passPrompt", read())
	write("  Pass mask: ")
	config.write(".pwdl_data", "passMask", read())
	write("Success msg: ")
	config.write(".pwdl_data", "success", read())
	write("   Fail msg: ")
	config.write(".pwdl_data", "fail", read())
	write("  Fail time: ")
	config.write(".pwdl_data", "failTime", read())
	write("   Exit msg: ")
	config.write(".pwdl_data", "exit", read())
	print("Press any key to continue")
	os.pullEvent("key")
	os.reboot()
end

local conf = config.list(".pwdl_data")

local function clear()
	term.clear()
	term.setCursorPos(1, 1)
	print(conf.lockName)
end

local ope = os.pullEvent
os.pullEvent = os.pullEventRaw

clear()
write(conf.passPrompt)
local input = read(conf.passMask)
clear()
if input == conf.password then
	print(conf.success)
	for _, v in pairs(rs.getSides()) do
		rs.setOutput(v, true)
	end
	sleep(conf.openTime)
	for _, v in pairs(rs.getSides()) do
		rs.setOutput(v, false)
	end
elseif input == conf.exitPass then
	print(conf.exit)
	os.pullEvent = ope
	return
else
	print(conf.fail)
	sleep(conf.failTime)
end
os.reboot()

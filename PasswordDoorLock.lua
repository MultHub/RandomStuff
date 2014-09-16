local ope = os.pullEvent
os.pullEvent = os.pullEventRaw

local remote = http.get("https://raw.github.com/MultHub/RandomStuff/master/PasswordDoorLock.lua")
if remote then
	local file = fs.open(shell.getRunningProgram(), "w")
	file.write(remote.readAll())
	file.close()
	remote.close()
end

if not fs.exists(".lmnet/apis/config") then
	local remote = http.get("https://raw.github.com/MultHub/LMNet-OS/master/src/apis/config.lua")
	if not remote then os.reboot() end
	if not fs.exists(".lmnet/apis") then
		if not fs.exists(".lmnet") then
			fs.makeDir(".lmnet")
		end
		fs.makeDir(".lmnet/apis")
	end
	local file = fs.open(".lmnet/apis/config", "w")
	file.write(remote.readAll())
	file.close()
	remote.close()
end

if not config then os.loadAPI(".lmnet/apis/config") end

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
	config.write(".pwdl_data", "failTime", tonumber(read()))
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

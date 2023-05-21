--StereoSongs.lua Updater

function download(lURL)
	print("Downloading "..lURL.."\nto "..sPath.."...")
	local response = http.get(lURL)
	local sResponse = response.readAll()
	response.close()
	local file = fs.open(sPath, "w")
	file.write(sResponse)
	file.close()
	print("Success!")
end

sFile = "./MP3/Songs/StereoSongs.lua"
sURL = "https://github.com/killadeer100/Tapes/raw/Tapes/PocketMP3/StereoSongs.lua"
sPath = shell.resolve(sFile)

if fs.exists(sPath) then
	fs.delete(sPath)
	print("Deleted old file...")
	download(sURL)
end
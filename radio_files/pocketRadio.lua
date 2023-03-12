--Speaker Check/Setup
local function get_speakers(name)
    if name then
        local speaker = peripheral.wrap(name)
        if speaker == nil then
            error(("Speaker %q does not exist"):format(name), 0)
            return
        elseif not peripheral.hasType(name, "speaker") then
            error(("%q is not a speaker"):format(name), 0)
        end

        return { speaker }
    else
        local speakers = { peripheral.find("speaker") }
        if #speakers == 0 then
            error("No speakers attached", 0)
        end
        return speakers
    end
end

--Play Audio Through Speaker
local function playAudio(inSong)
	local file = inSong
	local speaker = peripheral.find("speaker")

	local handle, err
	if http and file:match("^https?://") then
		print("Downloading...")
		handle, err = http.get{ url = file, binary = true }
	else
		handle, err = fs.open(file, "rb")
	end

	if not handle then
		printError("Could not play audio:")
		error(err, 0)
	end

	print("Playing " .. file)

	local decoder = require "cc.audio.dfpwm".make_decoder()
	while true do
		local chunk = handle.read(16 * 1024)
		if not chunk then
			break
		end

		os.queueEvent("fakeEvent")
		os.pullEvent()

		local buffer = decoder(chunk)
		while not speaker.playAudio(buffer, 0.15) do
			os.pullEvent("speaker_audio_empty")
		end
	end

	handle.close()
end

--Seed Randomizer
math.randomseed(os.time())

--Randomizer
function Randomizer(prev, size, index, queueSize)
	local j = 1
	local match = false
    while (true) do
        j = math.random(1, size)
        match = false
        for i = 1, queueSize, 1 do
            if prev[i] == j then match = true end
        end
        if match == false then
            prev[index] = j
            return j
        end
    end
    prev[index] = j
	return j
end

--Load Playlist File
args = {...}
local pl = require("playlists."..args[1])

--Check Talk, Blurb, Commercial
local hasTalk = (table.getn(pl.talkArr) >= 1)
local hasBlurb = (table.getn(pl.blurbArr) >= 1)
local hasComm = (table.getn(pl.commArr) >= 1)

--Previous Array Setup
prevSongArr = {}
prevSongArrIndex = 1
if hasTalk then
	prevTalkArr = {}
	prevTalkArrIndex = 1
end
if hasBlurb then
	prevBlurbArr = {}
	prevBlurbArrIndex = 1
end
if hasComm then
	prevCommArr = {}
	prevCommArrIndex = 1
end

--Initialize Locals
local schedule = 0
local remainSong = 0
local remainComm = 0
local randomizer = "0"

--Initial Playback
if hasBlurb then
	out_msg = pl.blurbArr[Randomizer(prevBlurbArr, pl.blurbArrSize, prevBlurbArrIndex, pl.prevBlurbArrSize)]
	prevBlurbArrIndex = prevBlurbArrIndex + 1
	remainSong = math.random(3, 5)
else
	out_msg = pl.songArr[Randomizer(prevSongArr, pl.songArrSize, prevSongArrIndex, pl.prevSongArrSize)]
	prevSongArrIndex = prevSongArrIndex + 1
	remainSong = math.random(2, 4)
end
schedule = schedule + 1
if hasComm then remainComm = math.random(0, 2) end
playAudio(out_msg)

--Main Loop
while (true) do
	
	--Playing 3-5 Songs
	if (schedule == 1) and (remainSong > 0) then
		out_msg = pl.songArr[Randomizer(prevSongArr, pl.songArrSize, prevSongArrIndex, pl.prevSongArrSize)]
		prevSongArrIndex = prevSongArrIndex + 1
		if prevSongArrIndex > pl.prevSongArrSize then prevSongArrIndex = 1 end
		
		remainSong = remainSong - 1
		
		if (remainSong == 0) then
			remainSong = math.random(3, 5)
			schedule = schedule + 1
		end
		
		playAudio(out_msg)
	end
	
	--Play Talk
	if (schedule == 2) and (hasTalk) then
		out_msg = pl.talkArr[Randomizer(prevTalkArr, pl.talkArrSize, prevTalkArrIndex, pl.prevTalkArrSize)]
		prevTalkArrIndex = prevTalkArrIndex + 1
		if prevTalkArrIndex > pl.prevTalkArrSize then prevTalkArrIndex = 1 end
		
		schedule = schedule + 1
		playAudio(out_msg)
	end
	
	if (schedule == 2) and not(hasTalk) then
		schedule = schedule + 1
	end
	
	--Play 3-5 Songs
	if (schedule == 3) and (remainSong > 0) then
		out_msg = pl.songArr[Randomizer(prevSongArr, pl.songArrSize, prevSongArrIndex, pl.prevSongArrSize)]
		prevSongArrIndex = prevSongArrIndex + 1
		if prevSongArrIndex > pl.prevSongArrSize then prevSongArrIndex = 1 end
		
		remainSong = remainSong - 1
		
		if (remainSong == 0) then
			remainSong = math.random(3, 5)
			schedule = schedule + 1
		end
		
		playAudio(out_msg)
	end
	
	--Play 0-2 Commercials
	if (schedule == 4) and (remainComm > 0) and (hasComm) then
		out_msg = pl.commArr[Randomizer(prevCommArr, pl.commArrSize, prevCommArrIndex, pl.prevCommArrSize)]
		prevCommArrIndex = prevCommArrIndex + 1
		if prevCommArrIndex > pl.prevCommArrSize then prevCommArrIndex = 1 end
		
		remainComm = remainComm - 1
		
		playAudio(out_msg)
	end
	
	--Skip Commercials
	if (schedule == 4) and (remainComm == 0) and (hasComm) then
		schedule = schedule + 1
		remainComm = math.random(0,2)
	end
	
	if (schedule == 4) and not(hasComm) then
		schedule = schedule + 1
	end
	
	--Play Blurb
	if (schedule == 5) and (hasBlurb) then
		out_msg = pl.blurbArr[Randomizer(prevBlurbArr, pl.blurbArrSize, prevBlurbArrIndex, pl.prevBlurbArrSize)]
		prevBlurbArrIndex = prevBlurbArrIndex + 1
		if prevBlurbArrIndex > pl.prevBlurbArrSize then prevBlurbArrIndex = 1 end
		
		schedule = schedule + 1
		playAudio(out_msg)
	end
	
	if (schedule == 5) and not(hasBlurb) then
		schedule = schedule + 1
	end
	
	--Play 3-5 Songs
	if (schedule == 6) and (remainSong > 0) then
		out_msg = pl.songArr[Randomizer(prevSongArr, pl.songArrSize, prevSongArrIndex, pl.prevSongArrSize)]
		prevSongArrIndex = prevSongArrIndex + 1
		if prevSongArrIndex > pl.prevSongArrSize then prevSongArrIndex = 1 end
		
		remainSong = remainSong - 1
		
		if (remainSong == 0) then
			remainSong = math.random(3, 5)
			schedule = schedule + 1
		end
		
		playAudio(out_msg)
	end
	
	--Play 0-2 Commercials
	if (schedule == 7) and (remainComm > 0) and (hasComm) then
		out_msg = pl.commArr[Randomizer(prevCommArr, pl.commArrSize, prevCommArrIndex, pl.prevCommArrSize)]
		prevCommArrIndex = prevCommArrIndex + 1
		if prevCommArrIndex > pl.prevCommArrSize then prevCommArrIndex = 1 end
		
		remainComm = remainComm - 1
		
		playAudio(out_msg)
	end
	
	--Skip Commercials
	if (schedule == 7) and (remainComm == 0) and (hasComm) then
		schedule = schedule + 1
		remainComm = math.random(0, 2)
	end
	
	if (schedule == 7) and not(hasComm) then
		schedule = schedule + 1
	end
	
	--Play Blurb
	if (schedule == 8) and (hasBlurb) then
		out_msg = pl.blurbArr[Randomizer(prevBlurbArr, pl.blurbArrSize, prevBlurbArrIndex, pl.prevBlurbArrSize)]
		prevBlurbArrIndex = prevBlurbArrIndex + 1
		if prevBlurbArrIndex > pl.prevBlurbArrSize then prevBlurbArrIndex = 1 end
		
		schedule = schedule + 1
		playAudio(out_msg)
	end
	
	if (schedule == 8) and not(hasBlurb) then
		schedule = schedule + 1
	end
	
	--Count Up Cycle
	if schedule == 9 then
		schedule = 1
	end

end

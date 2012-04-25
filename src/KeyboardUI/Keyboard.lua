module(..., package.seeall)

local width, height, isLandscapeOrientation = display.contentWidth, display.contentHeight, true

-- Activate multitouch
system.activate( "multitouch" )
local isSimulator = "simulator" == system.getInfo("environment")

-- Keep only one instance
local isUpperCase = false
local inputField 
local listeners
local keyboard
local rendo
local undo
local value

-- Keyboard settings
local TEXT = "ABC"
local NUMBERS = ".?123"
local NUMBERSONLY = "123"
local SYMBOLS = "#+="

local cornerRadius = 10

local playSoundOnHit = true
local isRotated = false
local isKeyboardRotated = false
local waitCursorBlink = false
local cursor
local activeLayout = 1
local displayOnTop = false
local enabledKeys

local sysKeys = {"DEL", "RETURN", "UNDO", NUMBERS, SYMBOLS, TEXT, "HIDE", "REDO"}
local keys = 
	{
	-- First line 

	{  6, 9, 80, 75, "Q", "1", "["},
	{ 99, 9, 80, 75, "W", "2", "]"},
	{192, 9, 80, 75, "E", "3", "{"},
	{285, 9, 80, 75, "R", "4", "}"},
	{378, 9, 80, 75, "T", "5", "#"},
	{471, 9, 80, 75, "Y", "6", "%"},
	{564, 9, 80, 75, "U", "7", "^"},
	{657, 9, 80, 75, "I", "8", "*"},
	{750, 9, 80, 75, "O", "9", "+"},
	{843, 9, 80, 75, "P", "0", "="},
	{937, 9, 80, 75, "DEL", "DEL", "DEL"},

	-- Second line

	{45, 94, 78, 75, "A", "-", "_"},
	{136, 94, 78, 75, "S", "/", "\\"},
	{229, 94, 78, 75, "D", ":", "|"},
	{321, 94, 78, 75, "F", ";", "~"},
	{413, 94, 78, 75, "G", "(", "<"},
	{505, 94, 78, 75, "H", ")", ">"},
	{597, 94, 78, 75, "J", "$", "€"},
	{689, 94, 78, 75, "K", "&", "£"},
	{781, 94, 78, 75, "L", "@", "€"},
	{873, 94, 144, 75, "RETURN", "RETURN", "RETURN"},

	-- Third line

	{6, 182, 78, 75, "UPPERCASE", SYMBOLS, NUMBERSONLY},

	{97, 182, 167, 74, nil, "UNDO", "REDO"},
	{97, 182, 78, 74, "Z", nil, nil},
	{188, 181, 78, 74, "X", nil, nil},

	{279, 182, 78, 74, "C", ".", "."},
	{370, 182, 78, 74, "V", ",", ","},
	{460, 182, 78, 74, "B", "?", "?"},
	{550, 182, 78, 74, "N", "!", "!"},
	{640, 182, 78, 74, "M", "'", "'"},
	{732, 182, 78, 75, ",", "\"", "\""},
	{822, 182, 78, 74, ".", nil, nil},
	{912, 182, 104, 74, "UPPERCASE", SYMBOLS, NUMBERSONLY},

	-- Fourth line

	{6, 268, 259, 74, NUMBERS, TEXT, TEXT},
	{279, 268, 439, 74, " ", " ", " "},
	{732, 268, 194, 74, NUMBERS, TEXT, TEXT},
	{940, 268, 78, 74, "HIDE", "HIDE", "HIDE"}

};

local function setKeySet( keySet )
	if keySet ~= nil then
		for j = 1, #sysKeys do
			if keySet[sysKeys[j]] == nil then
				keySet[sysKeys[j]] = true
			end
		end
	end
	enabledKeys = keySet
end

local function isKeyEnabled( key )
	if enabledKeys == nil or enabledKeys[key] then 
		return true
	end
	
	return false
end

local function createKey( update, value, info, isMetaKey, isEnabled )
	local key = display.newGroup()
	local shadow

	if not isSimulator then
		shadow = display.newRoundedRect( 0, 0, info[3], info[4], cornerRadius )
	else
		shadow = display.newRect( 0, 0, info[3], info[4])
	end

	if isKeyEnabled(value) and enabledKeys ~= nil then
		shadow:setFillColor( 0,255,0, 50 )
	else
		shadow:setFillColor( 255,255,255, 10 )
	end

	key:insert( shadow )
	key.x = info[1]
	key.y = info[2]

	local function onKeyHit( event )
		if isKeyEnabled(value) then
			if event.phase == "began" then
				if playSoundOnHit then
					media.playEventSound( "media/tap.caf" )
				end
				shadow:setFillColor( 0,255,0, 50 )
				update(value)
			else
				local event = { name="onKeyboardKeyRelease", target=Runtime, value=value }
				Runtime:dispatchEvent( event )
			end
		end
		return true
	end

	-- Checks all keys
	local function onKeyRelease(event) 
		if isMetaKey and isUpperCase then
			shadow:setFillColor( 255,255,255,200 )
		else
			if isKeyEnabled(value) and enabledKeys ~= nil then
				shadow:setFillColor( 255,255,0, 50 )
			else
				shadow:setFillColor( 255,255,255, 10 )
			end
		end
	end

	Runtime:addEventListener( "onKeyboardKeyRelease", onKeyRelease )
	key:addEventListener("touch", onKeyHit )
	return key, onKeyHit

end

local function cursorBlink()
	if inputField.parent ~= nil then
		local v = value:gsub("^%s*", "")
		if inputField.text ~= value and v ~= nil then
			if inputField.setText then
				inputField:setText(v)
			else
				inputField.text = v
			end
		end
		cursor.x = inputField.x + inputField.width / 2 
		cursor.y = inputField.y 
		cursor.xScale = inputField.xScale
		cursor.yScale = inputField.yScale

		if not waitCursorBlink then
			waitCursorBlink = true

			-- Avoid clamping warnings
			local fadeTo = .9
			if cursor.alpha > .5 then
				fadeTo = .1
			end

			transition.to(cursor, {time=200, alpha = fadeTo, transition = easing.outExpo })
			timer.performWithDelay( 200, function( event ) waitCursorBlink = false end )
		end
	else
		close()
	end
end

-- Create Keyboard

function close( hitEnter )

	Runtime:removeEventListener("enterFrame", cursorBlink)
	local keyTabs = {}
	keyTabs[1] = TEXT
	keyTabs[2] = NUMBERS
	keyTabs[3] = SYMBOLS

	if cursor ~= nil then
		cursor.isVisible = false
	end

	if keyboard then
		for t = 1, #keyTabs do
			local k = keyboard[keyTabs[t]]
			if k.isVisible then
				if not isLandscapeOrientation then
					transition.to(k, {time=400, x = -k.height, transition=easing.outExpo })
				else
					if displayOnTop then
						transition.to(k, {time=400, y = - k.height * k.yScale - 10, transition=easing.outExpo })
					else
						transition.to(k, {time=400, y = height * 1.2, transition=easing.outExpo })
					end
				end
				timer.performWithDelay(410, function( event ) k.isVisible = false end )
			end
		end
		if hitEnter then
			local event = { name="onKeyboardSubmit", target=Runtime, value=value, inputField=inputField }
			Runtime:dispatchEvent( event )
		end
	end

end

function newKeyboard( params )

	-- Input field is required
	if params.inputField == nil then
		return nil
	end

	-- Remove cursor if it exists
	Runtime:removeEventListener("enterFrame", cursorBlink)
	if cursor ~= nil and cursor.isVisible then 
		cursor:removeSelf() 
	end

	-- Keyboard position. At top if true, bottom otherwise
	displayOnTop = params.displayOnTop

	-- Restrict keys, if needed
	setKeySet( params.enabledKeys )

	-- Setup pointer to inputField
	value = params.inputField.text
	inputField = params.inputField

	-- Setup the new cursor
	local cursorSize = inputField.size or 18
	cursor = display.newText( "I", 0, 0, native.systemFontBold, cursorSize )
	if params.useCursorColor ~= nil then
		local color = params.useCursorColor
		cursor:setTextColor(color[1], color[2], color[3])
	else
		cursor:setTextColor(200, 200, 200)
	end

	-- Start with CapsLock enabled
	isUpperCase = params.enableCapsLock

	-- Start with Landscape Orientation
	isLandscapeOrientation = params.isLandscapeOrientation

	-- Hide cursor if true
	cursor.isVisible = not params.hideCursor

	inputField.parent:insert(cursor)
	Runtime:addEventListener("enterFrame", cursorBlink)

	-- Enable disable key press sound
	if params.disableSoundOnHit then
		playSoundOnHit = false
	else
		playSoundOnHit = true
	end

	rendo = 1
	undo = {}
	undo[rendo] = ""

	-- Overwrite component value with a default value
	if ( params.defaultValue ~= nil and params.defaultValue ~= 0 ) then
		value = params.defaultValue
	end

	-- Just to be safe
	if value == nil then
		value = ""
	end

	local keyTabs = {}
	keyTabs[1] = TEXT
	keyTabs[2] = NUMBERS
	keyTabs[3] = SYMBOLS

	local function setKeyboardPosition( doScale )
		local scale = 0
		if isLandscapeOrientation then
			scale = width / (1024 + width / 5)
		else
			scale = height / (1024 + 10)
		end

		for t = 1, #keyTabs do
			local tabID = keyTabs[t]
			if doScale then
				if params.sx and params.sy then
					keyboard[tabID]:scale(params.sx,params.sy)
				else
					keyboard[tabID]:scale(scale, scale)
				end
			end

			if not isLandscapeOrientation then
				if not isKeyboardRotated then
					keyboard[tabID]:setReferencePoint(display.CenterReferencePoint);
					keyboard[tabID]:rotate(90)
				end
				keyboard[tabID].y = (keyboard[tabID].width + 10) * scale / 2
				keyboard[tabID].x = keyboard[tabID].height / 2 * scale
			else
				if params.dy then
					keyboard[tabID].y = params.dy
				else
					if displayOnTop then
						keyboard[tabID].y = 0
					else
						keyboard[tabID].y = height - 351 * scale
					end
				end

				if params.dx then
					keyboard[tabID].x = params.dx
				else
					keyboard[tabID].x = (width - 1024 * scale) / 2
				end
			end
		end
		isKeyboardRotated = true
	end

	if keyboard then
		-- Reset keyboard
		for t = 1, #keyTabs do
			keyboard[keyTabs[t]].isVisible = false 
		end
		activeLayout = keyTabs[params.useLayout or 1]
		keyboard[keyTabs[params.useLayout or 1]].isVisible = true 
		isUpperCase = params.enableCapsLock
		local event = { name="onKeyboardKeyRelease", target=Runtime, value=isUpperCase }
		Runtime:dispatchEvent( event )
		setKeyboardPosition(false)
		return keyboard
	end

	listeners = {}
	keyboard = {}
	keyboard[keyTabs[1]] = display.newGroup()
	keyboard[keyTabs[2]] = display.newGroup()
	keyboard[keyTabs[3]] = display.newGroup()

	local function switchKeyboard( toKeyboard )
		for t = 1, #keyTabs do
			keyboard[keyTabs[t]].isVisible = false
		end
		activeLayout = toKeyboard
		keyboard[toKeyboard].isVisible = true
		isUpperCase = params.enableCapsLock
		local event = { name="onKeyboardKeyRelease", target=Runtime, value=isUpperCase }
		Runtime:dispatchEvent( event )
	end

	local function onKeyPress( v )
		if string.len(v) == 1 then
			if not isUpperCase then
				value = value .. string.lower(v)
			else
				if v == "." and activeLayout == TEXT then
					value = value .. "?"
				elseif v == "," and activeLayout == TEXT then
					value = value .. "!"
				else
					value = value .. v
				end
			end
			-- undo / rendo
			rendo = rendo + 1
			undo[rendo] = value
			for j = rendo + 1, #undo do undo[j] = nil end

		elseif v == NUMBERS or v == TEXT or v == SYMBOLS then
			switchKeyboard(v)

		elseif v == NUMBERSONLY then
			switchKeyboard(NUMBERS)

		elseif v == "HIDE" or v == "RETURN" then
			close( true )

		elseif v == "UPPERCASE" then
			isUpperCase = not isUpperCase
			params.enableCapsLock = isUpperCase

		elseif v == "DEL" then
			value = string.sub( value,1,-2 )
			rendo = rendo + 1
			undo[rendo] = value
			for j = rendo + 1, #undo do undo[j] = nil end

		elseif v == "UNDO" and rendo > 1 then
			rendo = rendo - 1
			value = undo[rendo]

		elseif v == "REDO" and rendo < #undo then
			rendo = rendo + 1
			value = undo[rendo]
		end
	end

	for t = 1, #keyTabs do
		local tabID = keyTabs[t]
		keyboard[tabID]:insert(display.newImage( "images/keyboard/keyboard-0" .. t .. ".jpg", true ))
		keyboard[tabID]:addEventListener("touch", function(event) return true end )
		for j = 1, #keys do
			local keyVal = keys[j][4 + t]
			listeners[tabID] = {}
			if keyVal ~= nil then
				local key, onHit = createKey(onKeyPress, keys[j][4 + t], 
								keys[j], keyVal == "UPPERCASE")
				listeners[tabID][j] = onHit
				keyboard[tabID]:insert(key)
			end
		end
	end

	setKeyboardPosition(true)
	switchKeyboard(keyTabs[params.useLayout or 1])
	return keyboard
end

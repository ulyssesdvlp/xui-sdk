local keyboard = require("Keyboard")
display.setStatusBar( display.HiddenStatusBar )

local newLabel = require("Widgets").newLabel{ 
	text = "0000000000", 
	size = 72, 
	font = native.systemFontBold,
	textColor = { 110,0,0,255 },
	align = "left", 
	bounds = { 15,4,120,26 }
}
newLabel:setText( "Click Me!" )
newLabel:setTextColor(0,255,255)

local onClick = function(event) 
	local keys = {}
	keys["2"] = true
	keys["3"] = true
	keys["5"] = true
	keys["7"] = true
	keys[" "] = true
	keys["X"] = true

	keyboard.newKeyboard { 
		-- Required. Object with 'setText( value )' or 'text' properties and text size 'size'
		inputField = newLabel,

		-- Optional. Use this to override the label value
		defaultValue = newLabel.text, 

		-- Optional. Cursor color
		useCursorColor = {100, 100, 100},

		-- Optional. Hide cursor
		hideCursor = false,

		-- Optional. Key press sound
		disableSoundOnHit = false,

		-- Optional. Start with CapsLock enabled
		--enableCapsLock = true,

		-- Optional. Enable only a few keys
		enabledKeys = keys,

		-- Optional. Select layout, default is 1. 1-ABC, 2-123, 3-Symb
		useLayout = 2,

		-- Landscape orientation or not. Default: portrait
		isLandscapeOrientation = true,

		-- Optional. Keyboard position. At top if true, bottom otherwise
		displayOnTop = false
	}
end

newLabel.touch = onClick
newLabel:addEventListener( "touch", newLabel )

-- OPTIONAL 

-- On [ENTER] key press, it hides the keyboard and send an event
local onKeyboardSubmit = function( event )
	print( "Oh Yeahh! Keyboards is GONE!")
	-- e.g. here you can call some method to process your input
end

Runtime:addEventListener( "onKeyboardSubmit", onKeyboardSubmit )

-- If you need you can catch key releases with this event listener

local onKeyRelease = function( event )
	if event.value then
		print( "Oh Yeahh! Give me more " .. tostring(event.value) .. "'s")
	end
	-- e.g. Here you can re-adjust the size of your text cell
end

Runtime:addEventListener( "onKeyboardKeyRelease", onKeyRelease )

-- Force keyboard to close
-- keyboard.close( fireEnterKey = false )

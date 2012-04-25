local picker = require("Picker")
local toolkit = require("DateToolkit")

display.setStatusBar( display.HiddenStatusBar )

local data = {}
local dataDefts = {1, 1, 1}

local function setupOneWheels()
	data[1] = {"Yes", "No", "Maybe Yes", "Maybe No", "Maybe"}
	local dataDefts = {2}
end

local function setupTwoWheels()
	data[1] = {}
	data[2] = {}

	for j = 1, 9 do 
		data[1][j] = "0" .. j 
	end

	data[2]= { 
			"Jan", "Feb", "Mar",
			"Apr", "May", "Jun",
			"Jul", "Aug", "Sep",
			"Oct", "Nov", "Dec"
		}
end

local function setupDateWheels()
	data[1] = {}
	data[2] = {}
	data[3] = {}

	for j = 1, 9 do 
		data[1][j] = "0" .. j 
	end

	local i = 9
	for j = 10, 31 do 
		data[1][i] = j
		i = i + 1
	end

	data[2]= { 
			"Jan", "Feb", "Mar",
			"Apr", "May", "Jun",
			"Jul", "Aug", "Sep",
			"Oct", "Nov", "Dec"
		}

	-- Year
	local i = 1
	local iYear = 2011
	for j = iYear, 2020 do 
		data[3][i] = j
		i = i + 1
	end

	-- Setup today date
	local yy, mm, dd =  toolkit.getCurrentDateYMD()
	print((yy - iYear + 1) .. "," .. mm .. "," .. dd)
	dataDefts = {dd, mm, yy - iYear + 1}
end

local onRelease = function( event )
	if #event.values == 3 then
		local pickerdate = event.values[3] .. " " .. event.values[2] .. " " .. event.values[1]
		print(toolkit.formatDate(pickerdate, "yyyy/mm/dd", "(%d+) (%a+) (%d+)"))
	elseif #event.values > 0 then
		for j = 1, #event.values do
			print("Slot " .. j .. ": " .. event.values[1])
		end
	end
	print("onReleaseCallback")
end

local function createPickerMethodOne( testCase )

	local onClose = function( event )
		print ("onClose")
	end

	testCase( )

	picker.newPickerUI {

		-- Optional. Default is center
		--align = "floating",

		-- Optional. Used to handle multiple picker instances
		uid = 1,
			
		-- List of values for each selector
		data = data,
		
		-- On release event. Find picked values in event.values
		onRelease = onRelease,
		
		onClose = onClose,

		-- Comment this line to center the interface
		-- dx and dy will be ignored
		align = "floating",

		-- Optional. Offset x
		dx = 100,

		-- Optional. Offset y
		dy = 100,

		moveWheels = dataDefts,

		-- Optional
		contentWidth = display.contentWidth,
		contentHeight = display.contentHeight,
		withFadingBg = true
	}
end

local function createPickerMethodTwo()
	local function onSelect( value ) print("Selected value: " .. value) end
	local types = {"char", "number", "number"}
	-- TODO: not working properly; needs refactor
	local properties = { scale = 1.3, width = display.contentWidth }
	picker.pickerFactory( "MyInstance", types, "D22", onSelect, properties)
end

-- Simplest way to do it
-- createPickerMethodOne( setupTwoWheels )
createPickerMethodOne( setupDateWheels )
-- createPickerMethodOne( setupOneWheels )

-- Fastest way to do it
--createPickerMethodTwo()

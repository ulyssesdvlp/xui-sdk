local ui = require("Widgets")
local widget = require("TableWidget")
local toolkit = require("Toolkit")

local width, height = display.contentWidth, display.contentHeight

display.setStatusBar( display.HiddenStatusBar )

function onBackButton( event )
	require("Keyboard").close( false )
	print("do something more ...")
end

function onConfirmButton( event )
	require("Keyboard").close( false )
	print("do something more ...")
end

local params = {}
params.globals = {}

-- I didn't had time to remove dependencies from this function.
-- However you won't need it
function switchScreen( params )
	return true
end

local g = ui.newEmptyScreen{
				screenTitle = "Table Demo",
				topButtonOnRelease = onBackButton,
				bottomButtonOnRelease = onConfirmButton,
				switchScreenFn = switchScreen,
				isLandscapeOrientation = true,
				globals = params.globals
			}

-- Header's definition
local header = { "Header 1", "Header 2", "Header Header Header" }

-- Data definition
local data = {}
for j = 1, 50 do
	data[j] = {"Row " .. j, "Column Value", "Column Value"}
end

-- Optional data constraints for every column
local constraints = {}
constraints.left = {"X",0,1,2,3,4,5,6," "}
constraints.right = {" ", 0,1,2,3,4,5,6}
local constraintsSet = {constraints, constraints, constraints}

-- On table cell press
onReleaseAction = function ( event ) 
	self = event.target
	local params = self.params
	local inputField = params.table.rows[self.row][self.column]
	require("Keyboard").newKeyboard { 
		defaultValue = inputField.text,
		inputField = inputField,
		displayOnTop = inputField.y > height / 2,
		isLandscapeOrientation = true
	}
	return true
end

local params = {}
params.onRelease = onReleaseAction
params.header = header
params.constraintsSet = constraintsSet
params.data = data
params.xOffset = 0
params.borderSize = 50
params.hasReleaseAction = function( row, column ) return true end
params.isLandscapeOrientation = true
params.useKeyboardAddOn = require("Keyboard")
params.onUpdate = require("TableWidgetRules").genCallback()

local pages = widget.newTableUI( params )
toolkit.addPageScroll(pages, g)


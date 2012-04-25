module(..., package.seeall)

local ui = require("Widgets")

-- List group
local debug = false
local lists = {}

local delta, tapList
local minWidth, maxWidth = 90, 200
local minHeight, maxHeight = 20, 205
local listElmSize = 75
local invertAxis = false

-- Get selected values
function getSelectedValues( )
	local values = {}
	local center = maxHeight - listElmSize / 4
	local pos
	
	for i = 1, #lists do
		pos = 10000
		values[i] = 0
		for j = 1, lists[i].size do
			local d = math.abs(lists[i][j].y - center) 
			if d < pos then
				pos = d
				values[i] = lists[i].source[j]
			end
		end
	end
	return values 
end

-- Set the visbility of a value
function setVisibility( elem, label, offset )
	if debug then 
		elem.isVisible = true
		return 
	end

	local maxh = maxHeight * 2 - listElmSize / 2 + 12
	local minh = minHeight - 28
	local y = elem.y + offset
	if(y > maxh or y < minh) then
		elem.isVisible = false
	else
		elem.isVisible = true
	end

end

-- Move items 
function moveItems( list, delta )
	local listSize = lists[list].size * listElmSize
	local halfSize = listSize / 2
	for j = 1, lists[list].size do
		local y = lists[list][j].y + delta
		if(y > halfSize) then
			y = y % listSize

		elseif (y < -halfSize) then
			y = y + listSize
		end


		if #lists[list].source < 5 then
			y = y + (5 - #lists[list].source) * listElmSize / 2 
		end

		lists[list][j].y = y
		setVisibility(lists[list][j],lists[list].source[j], 0)
	end
end

-- Center selected item
function adjustPosition( list, delta, onRelease )
	local min = 11111
	if ( delta < 0 ) then 
		for j = 1, lists[list].size do
			local d = 286 - lists[list][j].y - lists[list][j].height / 2
			if math.abs(d) < min and d < 0 then
				min = d + 15
			end
		end
	else
		for j = 1, lists[list].size do
			local d = 286 - lists[list][j].y - lists[list][j].height / 2
			if math.abs(d) < min and d > 0 then
				min = math.abs(d) + 15
			end
		end
	end

	offset = min

	for j = 1, lists[list].size do
		setVisibility(lists[list][j], lists[list].source[j], offset)
		if lists[list][j].tween then transition.cancel(lists[list][j].tween) end
		lists[list][j].tween = transition.to(lists[list][j], 
			{ time=100, y = lists[list][j].y + offset, transition=easing.outQuad})
	end

	timer.performWithDelay(120, function( event )
		moveItems(list, 0)
		display.getCurrentStage():setFocus( nil )
		if onRelease then
			event.values = getSelectedValues()
			result = onRelease(event)
		end
	end )

end

-- Cancel animations
function cancelAnimation( list )
	for j = 1, lists[list].size do
		if lists[list][j].tween then 
			transition.cancel(lists[list][j].tween)
		end
	end
end

-- Touch event
function touchListEvent( self, event, list )

	local phase = event.phase
	local result = true
	tapList = list

	if( phase == "began" ) then

		display.getCurrentStage():setFocus( self )
		self.isFocus = true
		if invertAxis then
			startPos = event.x
			prevPos = event.x
		else
			startPos = event.y
			prevPos = event.y
		end
		delta = 0
		cancelAnimation( list )

	elseif( self.isFocus ) then

		if( phase == "moved" ) then 
			if invertAxis then
				delta = -(event.x - prevPos)
				prevPos = event.x
			else
				delta = event.y - prevPos
				prevPos = event.y
			end
			moveItems( list, delta )

		elseif( phase == "ended" or phase == "cancelled" ) then 
			result = adjustPosition( list, delta, self.onRelease )
			self.isFocus = false
		end
	end

	return result
end

function newList( params ) 

	local uid = params.uid or 1
	local textSize = 32
	local data = params.data
	local default = params.default
	local over = params.over
	local onRelease = params.onRelease
	local callback = params.callback or function(item)
						local t = display.newText(item, 0, 0, native.systemFontBold, textSize)
						t:setTextColor(255, 255, 255)
						t.x = math.floor(t.width/2) + 20
						t.y = 24 
						return t
					end

	-- setup the list view 
	local listView = display.newGroup() 

	local prevY, prevH = 0, 0 
	local offset = listElmSize

	local sizes = {}
	local offsets = {}
	local itemSpace = 10
	local ws = params.windowSize * 1.5
	for i = 1, #data do
		sizes[i] = ws / #data
		offsets[i] = minWidth
	end

	local r = 0
	for k = 1, #data do
		r = r + sizes[k] 
	end

	-- Reset list
	lists = {}
	for i = 1, #data do 
		lists[i] = display.newGroup()
		lists[i].size = 0
		lists[i].x = - r / #data + 85

		listView:insert(lists[i])
		prevY, prevH = 0, 0 
		for j = 1, #data[i] do
			local h = data[i][j]

			if h then
				local g = display.newGroup()

				local t = display.newText(h, 0, 0, native.systemFontBold, textSize)
				t.x = (-t.width - 5 + sizes[i]) / 2
				t:setTextColor(0, 0, 0)

				local labelShadow = display.newText( h, 0, 0, native.systemFontBold, textSize )
				labelShadow.x = (-t.width - 5 + sizes[i]) / 2
				labelShadow:setTextColor( 0, 0, 0, 28 )

				local b = display.newRect( - t.width / 2 - 5, - textSize / 2, sizes[i], offset)

				if debug then 
					b:setFillColor(150, 30*j, 0, 100)
				else
					b:setFillColor(0, 0, 0, 5)
				end

				g:insert(b) 
				g:insert(t)
				g:insert(labelShadow)

				g.x = t.width * .5 
				local r = 0
				for k = 1, i do
					r = r + sizes[k] 
				end
				g.x = g.x + r
				g.y = prevY * offset + (maxHeight - minHeight) / 2 + t.height + offset

				lists[i]:insert( g ) 
				lists[i].size = lists[i].size + 1
				prevY = prevY + 1  
			end
		end 

		lists[i].params = params.params
		lists[i].source = data[i]
		for j = 1, lists[i].size do
			local c = lists[i][j][1]
			c.touch = function( self, event ) 
					return touchListEvent(self, event, i)
				 end
			c.onRelease = onRelease
			c:addEventListener( "touch", c )
		end
	end

	function listView:cleanUp()
		print("tableView cleanUp")
	end

	if params.moveWheels then
		for i = 1, #data do 
			params.moveWheels[i] = params.moveWheels[i] or 0
			local r = params.moveWheels[i] * listElmSize
			moveItems(i, -r)
			adjustPosition(i, 50, nil)
		end
	else
		for i = 1, #data do 
			moveItems(i, 0)
			adjustPosition(i, -50, nil)
		end
	end

	return listView
end

-- Picker UI widget

function newPickerUI( params )

	invertAxis = params.invertAxis
	local screenWidth = params.contentWidth or display.contentWidth
	local screenHeigh = params.contentHeight or display.contentHeight
	local uid = params.uid or 0
	local onRelease = params.onRelease

	local component = display.newGroup()

	local data = params.data or {}
	local glass = display.newImage( "images/picker/picker_glass.png", true )

	-- Repeat values
	if #data > 0 then
		for i = 1, #data do
			if #data[i] < 6 and #data[i] > 0 then
				for j = 1, 6 do
					data[i][#data[i]+1] = data[i][j]
				end
			end
		end
	end

	local myList
	if #data > 0 then
		myList = newList {
			windowSize = glass.width,
			uid = uid,
			data = data,
			default = "images/picker/item.png",
			over = "images/picker/item_over.png",
			onRelease = onRelease,
			params = params.params,
			moveWheels = params.moveWheels
		}
		myList:scale(.5, .5)
	end

	local background = display.newImage( "images/picker/picker_background.png", true )
	component:insert(background)
	component:insert(glass)

	if myList ~= nil then
		component:insert(myList)
	end

	local frame = display.newImage( "images/picker/picker_frame.png", true )
	component:insert(frame)

	local widget 
	local isClosed = false
	local closeFn = function ( event )
		-- Close just once
		if not isClosed then
			isClosed = true
			print("onClose()")
			if widget ~= nil then
				transition.to(widget, {time = 800, alpha = 0, transition = easing.outExpo })
			else
				transition.to(component, {time = 800, alpha = 0, transition = easing.outExpo })
			end

			timer.performWithDelay( 801, function( event )
				if widget ~= nil then
					widget:removeSelf()
				else
					component:removeSelf()
				end
			end)
		end
		return true
	end

	local close = display.newImage( "images/picker/close.png", true )
	close.x = background.width
	close.y = 0
	close:scale(.5, .5)
	close._onRelease = closeFn
	close.touch = ui.newButtonHandler
	close:addEventListener( "touch", close )
	component:insert(close)

	if not params.align or params.align == "center" then

		component.y = screenHeigh / 4
		component.x = screenWidth / 3

		-- Force events to hit only picker
		if params.withFadingBg == nil then
			component.touch = function( self, event ) return true end
			component:addEventListener( "touch", component )
		end

	elseif params.align and params.align == "floating" then
		component.y = params.dy or 0
		component.x = params.dx or 0
		component.touch = function( self, event ) 
			local phase = event.phase
			if "began" == phase then
				component.x0 = event.x - component.x
				component.y0 = event.y - component.y
				self.isFocus = true
			elseif self.isFocus then
				if "moved" == phase then
					--component.x = event.x - component.x0
					--component.y = event.y - component.y0
				elseif "ended" == phase or "cancelled" == phase then
					--component.x = event.x - component.x0
					--component.y = event.y - component.y0
					self.isFocus = false
				end
			end
			return true
		 end
		component:addEventListener( "touch", component )
	end

	if params.withFadingBg then
		widget = display.newGroup()
		local bg = display.newRect(widget, 0, 0, screenWidth, screenHeigh)
		bg._onRelease = closeFn
		bg.touch = ui.newButtonHandler
		bg:addEventListener( "touch", bg )
		bg:setFillColor(140, 140, 140, 100)
		widget:insert(component)

		close._onRelease = closeFn
		return widget
	else
		return component
	end
end

-- Function to populate and adjust picker UI
function adjustWheels( wheelsType, value )

	local data = {}
	local moveWheels = {}

	for j = 1, #wheelsType do
		data[j] = {}
		moveWheels[j] = 1
		if wheelsType[j] == "char" then
			data[j] = {"A", "B", "C", "D", "E", "F", 
				"G", "H", "I", "J", "K", "L",
				"M", "N", "O", "P", "Q", "R",
				"S", "T", "U", "V", "W", "X",
				"Y", "Z"}
		elseif wheelsType[j] == "number" then
			data[j] = {"1", "2", "3", "4", "5", "6", 
				"7", "8", "9", "0"}
		end
	end

	if value == nil or string.gsub(value, "(%s+)", "") == "" then
		return data, moveWheels
	end

	value = string.gsub(value, "(%s+)", "")

	for j = 1, #wheelsType do
		local v = string.sub(value, j, j)
		if wheelsType[j] == "number" then
			moveWheels[j] = tonumber(v) - 1
		else
			moveWheels[j] = 0
			for k = 1, #data[j] do
				if data[j][k] == v then
					moveWheels[j] = k - 1
					break
				end
			end
		end
	end
	return data, moveWheels

end

function pickerFactory( uid, wheelsType, defValue, onSelect, properties )
	if #wheelsType < 1 then return {}, {} end

	local dt, moveWheels = adjustWheels(wheelsType, defValue)

	properties = properties or {}
	local pickerValue = ""
	local isChanged = false
	local myPicker = newPickerUI {
		uid = uid,
		data = dt,
		moveWheels = moveWheels,
		onRelease = function( event )
			local result = (event.values[1] or " ")
			for j = 2, #wheelsType do
				result = result .. (event.values[j] or " ")
			end
			pickerValue = "" .. result
			isChanged = true
		end,
		 onClose = function( event )
			if isChanged then
				onSelect(pickerValue)
			end
			isChanged = false
		end,
		withFadingBg = true,
		contentWidth = properties.width,
		contentHeight = properties.height
	}

	-- TODO: merge this with newPickerUI
	local scale = 1
	if properties.scale ~= nil then
		myPicker:scale(properties.scale, properties.scale)
		scale = 0 + properties.scale
	end

	if properties.width ~= nil then
		myPicker.x = properties.width / 2 - myPicker.width * scale / 2
		myPicker.y = myPicker.y - 56 * scale
	end

	return myPicker
end

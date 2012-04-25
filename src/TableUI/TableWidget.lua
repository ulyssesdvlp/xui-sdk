module(..., package.seeall)

local ui = require("Widgets")
local width, height, isLandscapeOrientation = display.contentWidth, display.contentHeight, true

-- Helper function for newButton utility function below

function newButtonHandler( self, event )
	local result = true
	local phase = event.phase

	local onEvent = self._onEvent
	local onPress = self._onPress
	local onRelease = self._onRelease

	if "began" == phase then
		-- Very first "began" event
		if ( not self.isFocus ) then
			-- Subsequent touch events will target button even 
			-- if they are outside the contentBounds of button
			display.getCurrentStage():setFocus( self )
			self.isFocus = true

			if over then 
				default.isVisible = false
				over.isVisible = true
			end

			if onEvent then
				buttonEvent.phase = "press"
				result = onEvent( buttonEvent )
			elseif onPress then
				result = onPress( event )
			end
		end

	elseif self.isFocus then

		local bounds = self.stageBounds
		local x,y = event.x,event.y
		local isWithinBounds = 
			bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

		if "moved" == phase then
			if over then
				-- The rollover image should only be visible while the finger is within button's stageBounds
				default.isVisible = not isWithinBounds
				over.isVisible = isWithinBounds
			end

		elseif "ended" == phase or "cancelled" == phase then
			-- Allow touch events to be sent normally to the objects they "hit"
			display.getCurrentStage():setFocus( nil )
			self.isFocus = false

			if over then 
				default.isVisible = true
				over.isVisible = false
			end

			-- Only consider this a "click" if the user lifts their finger inside button's stageBounds
			--if isWithinBounds then
				if onEvent then
					buttonEvent.phase = "release"
					result = onEvent( buttonEvent )
				elseif onRelease then
					if self.uid then
						event.uid = self.uid
					end
					if self.params then
						event.params = self.params
					end

					result = onRelease( event )
				end
			--end
			
			-- Allow touch events to be sent normally to the objects they "hit"
			display.getCurrentStage():setFocus( nil )
			self.isFocus = false
		end
	end

	return result
end

function genHeaders( params )
	local header = params.header
	local fontSize = params.fontSize
	local yOffset = params.yOffset
	local table = params.table
	table.header = {}
	for j = 1, #header do
		table.header[j] = display.newText( header[j] or " ", 0, yOffset, native.systemFontBold, fontSize )
	end
	return table
end

local function calculateTableDim( params )
	local data = params.data
	local header = params.header
	local fontSize = params.fontSize
	local yOffset = params.yOffset

	local table = {}
	table.header = {}
	table.rows = {}
	table.vspaces = {}
	table.hspaces = {}

	local ncols = #header
	for j = 1, ncols do
		table.header[j] = display.newText( header[j] or " ", 0, yOffset, native.systemFontBold, fontSize )
	end

	for j = 1, ncols do
		local t = table.header[j]
		table.hspaces[j] = t.width
		table.vspaces[1] = params.itemSize or t.height * params.fontFactor
	end

	for j = 1, #data do
		table.rows[j] = {}
		local trow = table.rows[j]
		local row = data[j]
		for i = 1, ncols do
			local l = string.len(row[i] or " ") or 0
			local w = l * fontSize / 2
			local h = fontSize * params.fontFactor
			if w > table.hspaces[i] then table.hspaces[i] = w end
			if h > table.vspaces[1] then table.vspaces[1] = h end

			trow[i] = row[i] or ""
		end 
	end

	for i = 1, ncols do
		table.hspaces[i] = table.hspaces[i] + 50
	end

	return table
end

function newTableHeader( page, params )

	local itemBorder = params.itemBorder
	local fontSize = params.fontSize
	local mask = params.mask
	local colorCallback = params.colorCallback
	local table = params.table

	local vspace = table.vspaces[1]

	local x, y =  params.xOffset, params.yOffset
	local bg
	for j = 1, #table.header do

		local hspace = table.hspaces[j]
		local text = table.header[j]
		text.x = x + hspace / 2
		text.y = y + 2

		local minx, miny = x, y - vspace / 2

		local bg = display.newRect( minx, miny, hspace, vspace)
		bg:setFillColor( mask["hc"]["r"], mask["hc"]["g"], mask["hc"]["b"], mask["hc"]["a"] )
		bg.strokeWidth = 1
		bg:setStrokeColor( 255, 255, 255, 25 )
		page:insert(bg)

		text:setTextColor( mask["htext"]["r"], mask["htext"]["g"], mask["htext"]["b"] )
		page:insert(text)
		x = x + hspace + itemBorder

		if not params.noTablePicking then

			local function calculateDelta( previousTouches, event )
				local id,touch = next( previousTouches )
				if event.id == id then
					id,touch = next( previousTouches, id )
					assert( id ~= event.id )
				end

				local dx = touch.x - event.x
				local dy = touch.y - event.y
				return dx, dy
			end

			local function scaleTable( self, scale )
				for j = 1, #table.pages do
					table.pages[j].xScale = self.xScaleOriginal * scale
					table.pages[j].yScale = self.yScaleOriginal * scale
				end
			end

			local function moveTable( event )
				for j = 1, #table.pages do
					table.pages[j].x = event.x - table.pages[1].x0
					table.pages[j].y = event.y - table.pages[1].y0
				end
			end

			function bg:touch( event )
				local result = true
				local phase = event.phase
				local previousTouches = self.previousTouches
				local numTotalTouches = 1

				if ( previousTouches ) then
					-- add in total from previousTouches, 
					-- subtract one if event is already in the array
					numTotalTouches = numTotalTouches + self.numPreviousTouches
					if previousTouches[event.id] then
						numTotalTouches = numTotalTouches - 1
					end
				end

				if "began" == phase then
					-- Very first "began" event
					if ( not self.isFocus ) then
						-- Subsequent touch events will target button even 
						-- if they are outside the contentBounds of button
						display.getCurrentStage():setFocus( self )
						self.isFocus = true

						previousTouches = {}
						self.previousTouches = previousTouches
						self.numPreviousTouches = 0
					elseif ( not self.distance ) then
						local dx,dy

						if previousTouches and ( numTotalTouches ) >= 2 then
							dx,dy = calculateDelta( previousTouches, event )
						end

						-- initialize to distance between two touches
						if ( dx and dy ) then
							local d = math.sqrt( dx*dx + dy*dy )
							if ( d > 0 ) then
								self.distance = d
								self.xScaleOriginal = self.xScale
								self.yScaleOriginal = self.yScale
								print( "distance = " .. self.distance )
							end
						end
					end

					if not previousTouches[event.id] then
						self.numPreviousTouches = self.numPreviousTouches + 1
					end
					previousTouches[event.id] = event

					table.pages[1].x0 = event.x - table.pages[1].x
					table.pages[1].y0 = event.y - table.pages[1].y

				elseif self.isFocus then
					if "moved" == phase then
						if ( self.distance ) then
							local dx,dy
							if previousTouches and ( numTotalTouches ) >= 2 then
								dx,dy = calculateDelta( previousTouches, event )
							end
				
							if ( dx and dy ) then
								local newDistance = math.sqrt( dx*dx + dy*dy )
								local scale = newDistance / self.distance
								if ( scale > 0 ) then
									scaleTable(self, scale)
								end
							end
						end

						if not previousTouches[event.id] then
							self.numPreviousTouches = self.numPreviousTouches + 1
						end
						previousTouches[event.id] = event

						if numTotalTouches == 1 then
							moveTable( event )
						end

					elseif "ended" == phase or "cancelled" == phase then
						if previousTouches[event.id] then
							self.numPreviousTouches = self.numPreviousTouches - 1
							previousTouches[event.id] = nil
						end

						if ( #previousTouches > 0 ) then
							-- must be at least 2 touches remaining to pinch/zoom
							self.distance = nil
						else
							-- previousTouches is empty so no more fingers are touching the screen
							-- Allow touch events to be sent normally to the objects they "hit"
							display.getCurrentStage():setFocus( nil )

							self.isFocus = false
							self.distance = nil
							self.xScaleOriginal = nil
							self.yScaleOriginal = nil

							-- reset array
							self.previousTouches = nil
							self.numPreviousTouches = nil
						end
					end
				end

				return result
			end

			--bg:addEventListener( "touch", bg ) 

		end

	end
end

function newTableRow( page, params )

	local itemBorder = params.itemBorder
	local fontSize = params.fontSize
	local values = params.constraintsSet[index]
	local mask = params.mask

	local onRelease = params.onRelease

	local table = params.table
	local vspace = table.vspaces[1]

	local x, y =  0 + params.xOffset, 0 + params.yOffset

	table.colors[params.row] = {}

	for j = 1, #table.rows[params.row] do

		local hspace = table.hspaces[j]
		local text = display.newText(  table.rows[params.row][j] or " ", 0, params.yOffset, native.systemFontBold, fontSize )
		table.rows[params.row][j] = text

		local n = nil
		text.x = x + hspace / 2
		text.y = y + 2

		local minx, miny = x, y - vspace / 2 

		local valueColor = display.newRect( minx, miny, hspace, vspace)
		valueColor.strokeWidth = 2
		valueColor:setStrokeColor( mask["vc"]["r"], mask["vc"]["g"], mask["vc"]["b"], mask["vc"]["a"] )

		valueColor:setFillColor( mask["vc"]["r"], mask["vc"]["g"], mask["vc"]["b"], mask["vc"]["a"] )
		table.colors[params.row][j] = valueColor
		page:insert(valueColor)

		if not( n == nil ) then
			page:insert(n)
		end

		text:setTextColor( mask["text"]["r"], mask["text"]["g"], mask["text"]["b"] )
		page:insert(text)

		params.column = j

		if not params.rawdata then
			params.rawdata = {}
		end

		params.rawdata[params.row] = {}
		for index = 1, #table.header do
			params.rawdata[params.row][string.lower(params.header[index])] = params.data[index]
		end

		valueColor.r = mask["vc"]["r"]
		valueColor.g = mask["vc"]["g"]
		valueColor.b = mask["vc"]["b"]
		valueColor.a = mask["vc"]["a"]
		valueColor._onPress = function( event ) 
						if valueColor ~= nil and valueColor.setFillColor then
							valueColor:setFillColor( 100, 100, 200, 255 )
						end

						timer.performWithDelay( 500, function( event )
							if valueColor ~= nil and valueColor.setFillColor then
								valueColor:setFillColor( valueColor.r, valueColor.g, valueColor.b, valueColor.a ) 
							end
						end )
						return true
					end

		local r = params.row

		if onRelease and params.hasReleaseAction and params.hasReleaseAction(params.row, j) then
			valueColor._onRelease = function(event) 
							local c = event.target
							c:setFillColor( c.r, c.g, c.b, c.a ) 
							return onRelease(event)
						end
			valueColor.row = params.row
			valueColor.column = j
			valueColor.text = text
			valueColor.rows = table.rows[r]
			valueColor.params = params
			valueColor.touch = newButtonHandler
			valueColor:addEventListener( "touch", valueColor )
		end

		x = x + hspace + itemBorder
	end

	if params.customRows ~= nil then
		params.yOffset = params.customRows.getUpdateVerticalOffset( params.yOffset, params.itemSize )
	end

	return page

end

-- Create a new table
function newTableUI( params )

	local pages = {}
	local pageIndex = 1

	local rows = params.data
	local border = params.borderSize or 100

	params.onUpdate = params.onUpdate or function( params ) end
	params.mask = params.mask or require("TableWidgetRules").newColorSet( 255, 255, 255, 120 )
	params.fontSize = params.fontSize or 22
	params.itemBorder = params.itemBorder or params.fontSize / 4
	params.yOffset = params.yOffset or 0
	params.yItemScale = params.yItemScale or 1.0

	-- Size of the cell relative to font size
	params.fontFactor = params.fontFactor or 1.4

	local topOffset = 28
	if params.topOffset then
		topOffset = 0 + params.topOffset
	end

	params.colorCallback = params.colorCallback or function ( mask, data, x, y )  end
	params.xOffset = params.xOffset or 100

	params.table = calculateTableDim(params)

	params.table.vspaces = params.vspaces or params.table.vspaces
	params.table.hspaces = params.hspaces or params.table.hspaces
	params.table.colors = {}
	params.table.pages = pages

	if not params.ignoreyScale then
		if params.yItemScale ~= nil then
			for j = 1, #params.table.vspaces do
				params.table.vspaces[j] = params.table.vspaces[j] * params.yItemScale
			end
		end
		params.ignoreyScale = true
	end

	params.itemSize = params.itemSize or params.table.vspaces[table.maxn(params.table.vspaces)]

	local page = display.newGroup()
	page.isVisible = false

	-- Add header
	params.yOffset = topOffset + params.itemSize
	newTableHeader(page, params) ;
	params.yOffset = params.yOffset + params.itemSize + params.itemBorder + 1

	local resetY = 0 + params.yOffset 
	params.isFirstRow = true

	local scale = 1
	local isize = params.itemSize * 3 + topOffset
	if params.customRows ~= nil then
		isize = params.customRows.updateMaxSize(isize, params.itemSize)
	end

	local checkTableSize = true
	local itemPerPage = 0

	for j = 1, #rows do
		-- Stop on display page
		if not params.displayPage or #pages < params.displayPage then
			local data = rows[j]
			params.data = data
			params.row = j

			if not params.displayPage or pageIndex == params.displayPage then
				if params.customRows ~= nil then
					params.customRows.rowsFactory(params, page, newButtonHandler)
				else
					newTableRow(page, params)
				end
			end

			if checkTableSize then
				checkTableSize = false
				if params.isLandscapeOrientation then
					if page.width > width - border then
						scale = (width - border) / page.width
					end
					params.tableMaxSize = params.tableMaxSize or height - isize * scale - 20
				else
					if page.width > height - border/2 then
						scale = (height - border/2) / page.width
					end
					params.tableMaxSize = params.tableMaxSize or width - isize * scale - 20
				end
			end

			params.yOffset = params.yOffset + params.itemSize 
			if params.customRows ~= nil and not params.isFirstRow then
				params.yOffset = params.yOffset + params.itemBorder * 2
			else
				params.yOffset = params.yOffset + params.itemBorder
				itemPerPage = j
			end

			if not params.isFirstRow and params.yOffset * scale > params.tableMaxSize then
				params.isFirstRow = true
				pages[pageIndex] = page
				pageIndex = pageIndex + 1

				page = nil
				page = display.newGroup()
				page.isVisible = false
				if params.customRows ~= nil then
					params.yOffset = params.customRows.getUpdateVerticalOffset( topOffset, params.itemSize )
					genHeaders ( params )
					newTableHeader(page, params);
				end
				params.yOffset = resetY
			else
				params.isFirstRow = false
			end
		end
	end

	pages[pageIndex] = page
	pages[1].isVisible = true
	for j = 1, #pages do
		local page = pages[j]

		if params.isLandscapeOrientation then
			scale = (width - border) / page.width
			if scale < 1 then
				page.x = page.x + border / 2
				if scale < .5 then
					page.y = topOffset / scale - params.fontSize * (1.2-scale)
				else
					page.y = topOffset / scale + params.fontSize / 2 * scale
				end
				page:scale(scale, scale)
			else
				scale = 1
				page.x = (width - page.width) / 2
				page.y = topOffset + params.fontSize / 2
			end

		else
			scale = (height - border) / page.width
			if scale < 1 then
				page:scale(scale, scale)
			else
				scale = 1
			end
			page.x = width - 20
			page.y = height - page.width * scale - (height - page.width * scale) / 2
			page:rotate(90)
		end
	end

	if not params.displayPage then
		if #pages > 1 then
			local lastPage = pages[#pages].numChildren
			-- Contains only the header
			if lastPage > 0 and lastPage <= #params.table.header*2 then
				pages[#pages] = nil
			end
		end
	else

		for j = #pages+1, math.ceil(#rows / itemPerPage) do
			pages[j] = display.newGroup()
		end
	end

	local updateCallback = params.onUpdate
	updateCallback( params )

	return pages
end

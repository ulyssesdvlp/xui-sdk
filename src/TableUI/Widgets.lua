module(..., package.seeall)

local screenWidth, screenHeight, isLandscapeOrientation = display.contentWidth, display.contentHeight, true

-- Helper function for newButton utility function below

function newButtonHandler( self, event )

	local result = true

	local default = self[1]
	local over = self[2]
	
	-- General "onEvent" function overrides onPress and onRelease, if present
	local onEvent = self._onEvent
	
	local onPress = self._onPress
	local onRelease = self._onRelease

	local buttonEvent = {}
	if (self._id) then
		buttonEvent.id = self._id
	end

	local phase = event.phase
	if "began" == phase then
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

		-- Subsequent touch events will target button even if they are outside the stageBounds of button
		display.getCurrentStage():setFocus( self )
		self.isFocus = true

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
			if over then 
				default.isVisible = true
				over.isVisible = false
			end

			-- Only consider this a "click" if the user lifts their finger inside button's stageBounds
			if isWithinBounds then
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
			end

			-- Allow touch events to be sent normally to the objects they "hit"
			display.getCurrentStage():setFocus( nil )
			self.isFocus = false
		end
	end

	return result
end

-- Button class

function newButton( params )
	local button, default, over, size, font, textColor, offset

	if params.default then
		button = display.newGroup()
		default = display.newImage( params.default )
		button:insert( default, true )
	end

	if params.over then
		over = display.newImage( params.over )
		over.isVisible = false
		button:insert( over, true )
	end

	if params.text then
		if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
		if ( params.font ) then font=params.font else font=native.systemFontBold end
		if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end

		-- Optional vertical correction for fonts with unusual baselines (I'm looking at you, Zapfino)
		if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end

		if ( params.emboss ) then
			-- Make the label text look "embossed" (also adjusts effect for textColor brightness)
			local textBrightness = ( textColor[1] + textColor[2] + textColor[3] ) / 3
			
			local labelHighlight = display.newText( params.text, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelHighlight:setTextColor( 255, 255, 255, 20 )
			else
				labelHighlight:setTextColor( 255, 255, 255, 140 )
			end
			button:insert( labelHighlight, true )
			labelHighlight.x = labelHighlight.x + 1.5; labelHighlight.y = labelHighlight.y + 1.5 + offset
			
			local labelShadow = display.newText( params.text, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelShadow:setTextColor( 0, 0, 0, 128 )
			else
				labelShadow:setTextColor( 0, 0, 0, 20 )
			end
			button:insert( labelShadow, true )
			labelShadow.x = labelShadow.x - 1; labelShadow.y = labelShadow.y - 1 + offset
		end

		local labelText = display.newText( params.text, 0, 0, font, size )
		labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
		button:insert( labelText, true )
		labelText.y = labelText.y + offset
	end

	if ( params.onPress and ( type(params.onPress) == "function" ) ) then
		button._onPress = params.onPress
	end
	if ( params.onRelease and ( type(params.onRelease) == "function" ) ) then
		button._onRelease = params.onRelease
	end

	if (params.onEvent and ( type(params.onEvent) == "function" ) ) then
		button._onEvent = params.onEvent
	end
		
	-- Set button as a table listener by setting a table method and adding the button as its own 
	-- table listener for "touch" events
	button.touch = newButtonHandler
	button:addEventListener( "touch", button )

	if params.x then
		button.x = params.x
	end
	
	if params.y then
		button.y = params.y
	end
	
	if params.id then
		button._id = params.id
	end

	return button
end

-- Label class

function newLabel( params )
	local labelText
	local size, font, textColor, align
	
	if ( params.bounds ) then
		local bounds = params.bounds
		local left = bounds[1]
		local top = bounds[2]
		local width = bounds[3]
		local height = bounds[4]
	
		if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
		if ( params.font ) then font=params.font else font=native.systemFontBold end
		if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
		if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
		if ( params.align ) then align = params.align else align = "center" end

		labelText = display.newText( params.text or " ", 0, 0, font, size )
		labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )

		if ( align == "left" ) then
			labelText.x = left + labelText.contentWidth * 0.5
		elseif ( align == "right" ) then
			labelText.x = (left + width) - labelText.contentWidth * 0.5
		else
			labelText.x = ((2 * left) + width) * 0.5
		end
		labelText.y = top + labelText.contentHeight * 0.5

		-- Public methods
		function labelText:setText( newText )
			if ( newText ) then
				self.text = newText
				if ( "left" == align ) then
					self.x = left + self.width / 2 
				elseif ( "right" == align ) then
					self.x = (left + width) - self.width / 2
				else
					self.x = ((2 * left) + width) / 2
				end
			end
		end
		
		function labelText:setTextColor( textColor )
			if ( textColor and type(textColor) == "table" ) then
				self:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
			end
		end
	end

	-- Return instance
	return labelText

end

-- New Screen Interface

function newEmptyScreen( params )

	local path = params.globals.path
	local switchScreen = params.switchScreenFn
	local topButtonLabel = params.topButtonLabel or "Back"
	local bottomButtonLabel = params.bottomButtonLabel or "OK"
	local topMenuIconOffset = params.topMenuIconOffset or 16
	local bottomMenuIconOffset = params.bottomMenuIconOffset or 16
	local screenTitle = params.screenTitle or " "
	local textSize = params.textSize or 16
	local backgroundImage = params.background or "images/backgrounds/background.jpg"

	if params.isLandscapeOrientation ~= nil then
		isLandscapeOrientation = params.isLandscapeOrientation
	end

	function topButtonOnReleaseEv( event )
		if isLandscapeOrientation then
			transition.to(backBtn, {time=400, x = screenWidth / 4, transition=easing.outExpo })
			transition.to(backBtn, {time=400, alpha = 0, transition = easing.outExpo })
			if params.screenGroup then
				transition.to(params.screenGroup, {time = 300, x = -screenWidth + 50, transition = easing.inExpo })
			end
		else
			transition.to(backBtn, {time=400, y = screenHeight / 4, transition=easing.outExpo })
			transition.to(backBtn, {time=400, alpha = 0, transition = easing.outExpo })
			if params.screenGroup then
				transition.to(params.screenGroup, {time = 300, y = -screenHeight + 50, transition = easing.inExpo })
			end
		end

		if params.topButtonOnRelease then
			params.topButtonOnRelease(event)
		else 
			local newParams = {}
			local plen = #path
			newParams.newScreen = path[plen-1]
			path[plen-1] = nil
			path[plen] = nil
			newParams.globals = params.globals
			timer.performWithDelay( 390, function( event ) 
				print("act: true"); native.setActivityIndicator( true )
			end )
			timer.performWithDelay( 400, function( event ) switchScreen( newParams ) end )
		end
	end

	local bottomButtonOnReleaseEv = function( event )

		if isLandscapeOrientation then
			transition.to(backBtn, {time=400, x = screenWidth / 4, transition=easing.outExpo })
			transition.to(backBtn, {time=400, alpha = 0, transition = easing.outExpo })
			if params.screenGroup then
				transition.to(params.screenGroup, {time = 300, x = -screenWidth + 50, transition = easing.inExpo })
			end
		else
			transition.to(backBtn, {time=400, y = screenWidth / 4, transition=easing.outExpo })
			transition.to(backBtn, {time=400, alpha = 0, transition = easing.outExpo })
			if params.screenGroup then
				transition.to(params.screenGroup, {time = 300, y = -screenHeight + 50, transition = easing.inExpo })
			end
		end

		if params.bottomButtonOnRelease then
			params.bottomButtonOnRelease(event)
		else 
			local newParams = {}
			local plen = #path
			newParams.newScreen = path[plen-1]
			path[plen-1] = nil
			path[plen] = nil
			newParams.globals = params.globals
			timer.performWithDelay( 390, function( event )
				 print("act: true"); native.setActivityIndicator( true ) 
			end )
			timer.performWithDelay( 400, function( event ) switchScreen( newParams ) end )
		end
	end

	local topButtonOnRelease = params.topButtonOnReleaseEv or topButtonOnReleaseEv
	local bottomButtonOnRelease = params.bottomButtonOnReleaseEv or bottomButtonOnReleaseEv

	local background = display.newImage( backgroundImage, true )
	background.x = screenWidth / 2
	background.y = screenHeight / 2

	local ratio = 2 * math.min(screenWidth / background.width, screenHeight / background.height)
	background:scale(ratio, -ratio)

	-- Setup top nav bar 
	local navBar = display.newImage("images/menu/navBarExt.png", 0, 0, true)
	if isLandscapeOrientation then
		navBar:setReferencePoint(display.CenterReferencePoint);
		local navBarSx = screenWidth / navBar.width
		navBar.x = screenWidth * .5
		navBar.y = math.floor(display.screenOriginY + navBar.height * .5)
		navBar.xScale = navBarSx
		navBar:rotate(180)
	else
		navBar:setReferencePoint(display.TopCenterReferencePoint);
		local navBarSx = screenHeight / navBar.width
		navBar.x = screenWidth
		navBar.y = screenHeight * .5
		navBar.xScale = navBarSx
		navBar:rotate(90)
	end

	--Setup the back button
	backBtn = newButton{ 
		default = "images/menu/backButton.png", 
		over = "images/menu/backButton_over.png", 
		onRelease = topButtonOnRelease
	}

	if isLandscapeOrientation then
		backBtn:setReferencePoint(display.CenterReferencePoint)
		backBtn.y = topMenuIconOffset
	else
		backBtn.y = 35
		backBtn.x = screenWidth - backBtn.height * .5 * 0.8 - 2
		backBtn:rotate(90)
	end

	backBtn:scale(.8,.8)

	-- Setup bottom nav bar 

	local navBottomBar = display.newImage("images/menu/navBarExt.png", 0, 0, true)
	if isLandscapeOrientation then
		navBottomBar:setReferencePoint(display.CenterReferencePoint);
		navBottomBar.x = screenWidth * .5
		navBottomBar.y = math.floor(screenHeight - navBottomBar.height * .5)
		navBottomBar.xScale = screenWidth / navBottomBar.width
	else
		navBottomBar.x = navBottomBar.height * .5
		navBottomBar.y = screenHeight * .5
		navBottomBar.xScale = screenHeight / navBottomBar.width
		navBottomBar:rotate(90)
	end

	local buttonOK = newButton{
		default = "images/menu/buttonOrange.png",
		over = "images/menu/buttonOrangeOver.png",
		onRelease = bottomButtonOnRelease,
		text = bottomButtonLabel,
		size = 18,
		emboss = true
	}

	buttonOK:scale(0.47, 0.47)
	if isLandscapeOrientation then
		buttonOK.x = screenWidth / 2
		buttonOK.y = screenHeight - bottomMenuIconOffset
	else
		buttonOK.x = buttonOK.height * .5 * 0.47 + bottomMenuIconOffset * .5 * 0.47
		buttonOK.y = screenHeight * .5
		buttonOK:rotate(90)
	end

	local title = display.newText( screenTitle, 0, 0, native.systemFontBold, textSize )
	title:setTextColor( 200, 200, 200 )
	if isLandscapeOrientation then
		title:setReferencePoint(display.CenterReferencePoint)
		title.x = screenWidth / 2 
		title.y = topMenuIconOffset
	else
		title.x = screenWidth - topMenuIconOffset
		title.y = screenHeight * .5
		title:rotate(90)
	end

	local g = display.newGroup()
	g:insert(background)
	g:insert(navBar)
	g:insert(backBtn)
	g:insert(navBottomBar)
	g:insert(buttonOK)
	g:insert(title)

	-- Animation in
	if isLandscapeOrientation then
		backBtn.x = screenWidth / 2
		backBtn.alpha = 0
		transition.to(backBtn, {time = 400, x = 5 + backBtn.width / 2, transition = easing.outExpo })
		transition.to(backBtn, {time = 400, alpha = 1})
	else
		backBtn.y = screenWidth / 2
		backBtn.alpha = 0
		transition.to(backBtn, {time = 400, y = 35, transition = easing.outExpo })
		transition.to(backBtn, {time = 400, alpha = 1})
	end

	return g
end

-- Create a popup menu

function newItem( text, textSize, itemSize, showDivider )

	local item = display.newGroup()

	local arrow = display.newImage( "images/popup/menu_item.png", true )

	local t = display.newText(text, 20, 10, native.systemFontBold, textSize)
	t:setTextColor(0, 0, 0)

	local labelShadow = display.newText( text, 20, 10, native.systemFontBold, textSize )
	labelShadow:setTextColor( 0, 0, 0, 28 )

	item:insert(arrow)
	if showDivider then
		local divider = display.newImage( "images/popup/menu_sep.png", true )
		divider.y = itemSize 
		item:insert(divider)
	end
	
	item:insert(t)
	item:insert(labelShadow)

	return item
end

function newPopupMenu( params )
	local items = params.items or {labels = {}}
	local sx = params.sx or 1
	local sy = params.sy or 1
	local dy = params.dy or 32

	local itemSize = params.itemSize or 44
	local component = display.newGroup()

	local nitems = #items.labels

	local background = display.newImage( "images/popup/menu_bg.png", true )
	local bgsize = background.height 

	local yscale = (bgsize * nitems / 3) / bgsize
	local dx = params.dx or 0
	dx = dx + screenWidth - background.width * sx - 2

	background.yScale = yscale
	background.y = background.y * yscale
	component:insert(background)

	local offset = 0
	for j = 1, #items.labels do
		local item = newItem(items.labels[j], 20, itemSize, false)
		item.y = itemSize * (j-1) + offset
		item._onRelease = items.callbacks[j]
		item.touch = newButtonHandler
		item:addEventListener( "touch", item )
		offset = 1
		component:insert(item)
	end

	component:scale(sx, sy)
	component.x = dx
	component.y = dy

	return component
end
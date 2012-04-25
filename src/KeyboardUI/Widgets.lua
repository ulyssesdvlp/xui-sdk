module(..., package.seeall)

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

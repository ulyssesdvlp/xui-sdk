-- Title: Rules for Table highlighting

module(..., package.seeall)

-- Apply color to the first component
local function setItemHalfColor( row, column, table, mask )
	local colors2 = table.colors2
	local c2 = colors2[row][column]
	if c2 ~= nil then
		c2:setFillColor(mask["vc2"]["r"], mask["vc2"]["g"], mask["vc2"]["b"], mask["vc2"]["a"])
	end
end

-- Apply color to all components
local function setItemColor( row, column, table, mask )
	pcall(
		assert( 
			function()
				local colors = table.colors
				local colors2 = table.colors2
				local text = table.rows

				local t = text[row][column]

				t:setTextColor( mask["text"]["r"], mask["text"]["g"], mask["text"]["b"] )

				local c = colors[row][column]
				c:setFillColor(mask["vc"]["r"], mask["vc"]["g"], mask["vc"]["b"], mask["vc"]["a"])
				c.r = mask["vc"]["r"]
				c.g = mask["vc"]["g"]
				c.b = mask["vc"]["b"]
				c.a = mask["vc"]["a"]

				local c2 = colors2[row][column]
				if c2 ~= nil then
					c2:setFillColor(mask["vc2"]["r"], mask["vc2"]["g"], mask["vc2"]["b"], mask["vc2"]["a"])
				end
			end 
		)
	)

end

local function updateTable( params )
	if params == nil or params.colorCallback == nil then return end
	local callback = params.colorCallback
	local table = params.table
	local colors = table.colors
	local mask = newColorSet( 255, 255, 255, 100 )
	local vcolors = {}
	for row = 1, #colors do
		if row == 1 then
			setMaskColor(mask, "SoftWhite")
		else
			mask = newColorSet( 255, 255, 255, 100 )
		end
		for column = 1, #colors[1] do
			setItemColor( row, column, table, mask )
		end
	end
end

-- Create a color set
function newColorSet( r, g, b, alpha )

	local mask = {}

	local text = {}
	text.r = r
	text.g = g
	text.b = b
	mask.text = text

	local htext = {}
	htext.r = r
	htext.g = g
	htext.b = b
	mask.htext = htext

	local hc = {}
	hc.r = 0
	hc.g = 0
	hc.b = 0
	hc.a = alpha
	mask.hc = hc

	local vc = {}
	vc.r = 0
	vc.g = 0
	vc.b = 0
	vc.a = alpha
	mask.vc = vc

	local vc2 = {}
	vc2.r = 0
	vc2.g = 0
	vc2.b = 0
	vc2.a = alpha
	mask.vc2 = vc2

	return mask

end

-- Define a color set
function setMaskColor( mask, color )

	mask["hc"]["r"] = 0
	mask["hc"]["g"] = 0
	mask["hc"]["b"] = 0
	mask["hc"]["a"] = 100

	if color == "SoftWhite" then
		mask["text"]["r"] = 255
		mask["text"]["g"] = 255
		mask["text"]["b"] = 255

		mask["vc"]["r"] = 0
		mask["vc"]["g"] = 30
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 100

		mask["vc2"]["r"] = 0
		mask["vc2"]["g"] = 30
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 100

	elseif color == "WhiteGreen" then
		mask["text"]["r"] = 0
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc2"]["r"] = 0
		mask["vc2"]["g"] = 255
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 255
		
		mask["vc"]["r"] = 255
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 255
		mask["vc"]["a"] = 255

	elseif color == "WhiteGray" then
		mask["text"]["r"] = 0	
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc"]["r"] = 255
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 255
		mask["vc"]["a"] = 255
			
		mask["vc2"]["r"] = 150
		mask["vc2"]["g"] = 150
		mask["vc2"]["b"] = 150
		mask["vc2"]["a"] = 255

	elseif color == "GrayGreen" then
		mask["text"]["r"] = 0
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc"]["r"] = 0
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 255
			
		mask["vc2"]["r"] = 150
		mask["vc2"]["g"] = 150
		mask["vc2"]["b"] = 150
		mask["vc2"]["a"] = 255

	elseif color == "WhiteOrange" then
		mask["text"]["r"] = 0	
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc"]["r"] = 255
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 255
		mask["vc"]["a"] = 255

		mask["vc2"]["r"] = 255
		mask["vc2"]["g"] = 160
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 255

	elseif color == "OrangeOrange" then
		mask["text"]["r"] = 0
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc"]["r"] = 255
		mask["vc"]["g"] = 160
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 255
			
		mask["vc2"]["r"] = 255
		mask["vc2"]["g"] = 160
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 255

	elseif color == "OrangeGreen" then
		mask["text"]["r"] = 0
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc2"]["r"] = 255
		mask["vc2"]["g"] = 160
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 255
			
		mask["vc"]["r"] = 0
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 255

	elseif color == "WhiteWhite" then
		mask["text"]["r"] = 0	
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc"]["r"] = 255
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 255
		mask["vc"]["a"] = 255
			
		mask["vc2"]["r"] = 255
		mask["vc2"]["g"] = 255
		mask["vc2"]["b"] = 255
		mask["vc2"]["a"] = 255

	elseif color == "GrayGray" then
		mask["text"]["r"] = 255
		mask["text"]["g"] = 255
		mask["text"]["b"] = 255
		
		mask["vc"]["r"] = 150
		mask["vc"]["g"] = 150
		mask["vc"]["b"] = 150
		mask["vc"]["a"] = 255
			
		mask["vc2"]["r"] = 150
		mask["vc2"]["g"] = 150
		mask["vc2"]["b"] = 150
		mask["vc2"]["a"] = 255

	elseif color == "GreenGreen" then
		mask["text"]["r"] = 0
		mask["text"]["g"] = 0
		mask["text"]["b"] = 0
		
		mask["vc"]["r"] = 0
		mask["vc"]["g"] = 255
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 255
			
		mask["vc2"]["r"] = 0
		mask["vc2"]["g"] = 255
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 255

	elseif color == "BlackBlack" then
		mask["text"]["r"] = 255
		mask["text"]["g"] = 255
		mask["text"]["b"] = 255
		
		mask["vc"]["r"] = 0
		mask["vc"]["g"] = 0
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 50
			
		mask["vc2"]["r"] = 0
		mask["vc2"]["g"] = 0
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 0

	elseif color == "Transparent" then
		mask["text"]["r"] = 255
		mask["text"]["g"] = 255
		mask["text"]["b"] = 255

		mask["hc"]["r"] = 0
		mask["hc"]["g"] = 0
		mask["hc"]["b"] = 0
		mask["hc"]["a"] = 0

		mask["vc"]["r"] = 0
		mask["vc"]["g"] = 0
		mask["vc"]["b"] = 0
		mask["vc"]["a"] = 0

		mask["vc2"]["r"] = 0
		mask["vc2"]["g"] = 0
		mask["vc2"]["b"] = 0
		mask["vc2"]["a"] = 0
	end
end

function genCallback()
	return updateTable
end

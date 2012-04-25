module(..., package.seeall)

local ui = require("Widgets")
local width, height = display.contentWidth, display.contentHeight

-- Multipage Navigation Arrows
local function newNavigationArrows( onReleaseLeft, onReleaseRight )

	local nextPage = ui.newButton {
		default = "images/menu/rightArrow.png",
		over = "images/menu/rightArrow.png",
		onRelease = onReleaseRight,
		emboss = true
	}

	nextPage.x = width - 60
	nextPage.y = height - 18
	nextPage:scale(0.7, 0.7)

	local prevPage = ui.newButton{
		default = "images/menu/leftArrow.png",
		over = "images/menu/leftArrow.png",
		onRelease = onReleaseLeft,
		emboss = true
	}

	prevPage.x = 61
	prevPage.y = height - 18
	prevPage:scale(0.7, 0.7)

	return nextPage, prevPage
end

function addPageScroll(pages, g)

	local label
	local currentPage = 1

	-- Interface to switch pages
	if #pages > 1 then

		local onReleaseRight = function( event ) 
			local i = currentPage + 1 
			if i < #pages + 1 then
				pages[currentPage].isVisible = false
				currentPage = i
				label.text = "" .. currentPage .. "/" .. #pages
			--	switchPage(g, params, table)
				pages[currentPage].isVisible = true 
			end
			return true
		end

		local onReleaseLeft = function( event ) 
			local i = currentPage - 1 
			if i > 0 then
				pages[currentPage].isVisible = false
				currentPage = i
				label.text = "" .. currentPage .. "/" .. #pages
			--	switchPage(g, params, table)
				pages[currentPage].isVisible = true
			end
			return true
		end

		local nextPage, prevPage = newNavigationArrows( onReleaseLeft, onReleaseRight )
		g:insert(nextPage)
		g:insert(prevPage)

		label = display.newText( "" .. currentPage .. "/" .. #pages, 0, 0, native.systemFontBold, 12 )
		label:setTextColor( 255, 255, 255 )
		label.y = height - 42
		label.x = width / 2

		g:insert(label)
	end
end
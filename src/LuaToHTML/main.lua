-- Corona SDK: Example how to interact between JS and Lua
-- Possible solution for the URL bug in Android honeycomb and ICS

local isSimulator = "simulator" == system.getInfo("environment")

if not isSimulator then
	display.setStatusBar( display.HiddenStatusBar )
end

if system.getInfo( "platformName" ) == "Mac OS X" then isSimulator = false; end

-- Parse values from webpopup
function getArgs( query )
	local parsed = {}
	local pos = 0

	query = string.gsub(query, "&amp;", "&")
	query = string.gsub(query, "&lt;", "<")
	query = string.gsub(query, "&gt;", ">")

	local function ginsert(qstr)
		local first, last = string.find(qstr, "=")
		if first then
			parsed[string.sub(qstr, 0, first-1)] = string.sub(qstr, first+1)
		end
	end

	while true do
		local first, last = string.find(query, "&", pos)
		if first then
			ginsert(string.sub(query, pos, first-1));
			pos = last+1
		else
			ginsert(string.sub(query, pos));
			break;
		end
	end
	return parsed
end

-- Write values to be used by webpopup
function setArgs( args )
	local path = system.pathForFile( "args.json", system.DocumentsDirectory  )
	local file, errStr = io.open( path, "w+b" )
	if file then
		local newstr = ""
		for k,v in pairs(args) do
			if k ~= nil and v ~= nil then
				if newstr ~= "" then
					newstr = newstr .. ", "
				end
				local val = ""
				if type(v) == "boolean" or tonumber(v) ~= nil then
					val = tostring(v) 
				else
					val = "\"" .. v .. "\""
				end
				newstr = newstr .. "\"" .. k .. "\": " .. val 
			end
		end
		local content = "{ " .. newstr .. " }"
		file:write( content )
		file:close() 
		return true
	end
end
	
-- Thank you Matthew Pringle for this piece of code 
-- http://developer.anscamobile.com/reference/index/networkrequest
local function createTCPServer( port )
        local socket = require("socket")
        
        -- Create Socket
        local tcpServerSocket , err = socket.tcp()
        local backlog = 5
        
        -- Check Socket
        if tcpServerSocket == nil then 
                return nil , err
        end
        
        -- Allow Address Reuse
        tcpServerSocket:setoption( "reuseaddr" , true )
        
        -- Bind Socket
        local res, err = tcpServerSocket:bind( "*" , port )
        if res == nil then
                return nil , err
        end
        
        -- Check Connection
        res , err = tcpServerSocket:listen( backlog )
        if res == nil then 
                return nil , err
        end
    
        -- Return Server
        return tcpServerSocket
        
end

-- code from http://developer.anscamobile.com/node/2937
function copyFile( srcName, srcPath, dstName, dstPath, overwrite )

	-- assume no errors
	local results = true

	-- Copy the source file to the destination file
	local rfilePath = system.pathForFile( srcName, srcPath )
	local wfilePath = system.pathForFile( dstName, dstPath )

	local rfh = io.open( rfilePath, "rb" )
	local wfh = io.open( wfilePath, "wb" )

	if  not wfh then
		print( "writeFileName open error!")
		results = false 
	else
		-- Read the file from the Resource directory and write it to the destination directory
		local data = rfh:read( "*a" )
		if not data then
		    print( "read error!" )
		    results = false     -- error
		else
		    if not wfh:write( data ) then
		        print( "write error!" ) 
		        results = false -- error
		    end
		end
	end

	-- Clean up our file handles
	rfh:close()
	wfh:close()
	return results  
end

local function doStuff( args )

	setArgs( args ) 
	
	if runTCPServer ~= nil then
		Runtime:removeEventListener( "enterFrame" , runTCPServer )
	end
      
	runTCPServer = function()
			tcpServer:settimeout( 0 )
			local tcpClient , _ = tcpServer:accept()
			if tcpClient ~= nil then
				local tcpClientMessage , _ = tcpClient:receive('*l')
				if tcpClient ~= nil then                              
					tcpClient:close()
				end
				if ( tcpClientMessage ~= nil ) then
						local myMessage =  tcpClientMessage
						local event = {}

						local xArgPos = string.find( myMessage, "?" )
						if xArgPos then
							local newargs = getArgs(string.sub( myMessage, xArgPos+1 ))	
							if newargs.shouldLoad == nil or newargs.shouldLoad == "false" then
								native.cancelWebPopup()
							else
								-- do some stuff ...
								print("Value from HTML:" .. newargs.arg)
								-- send some dumb stuff
								newargs.arg = tostring(os.date( "*t" ))
								setArgs(newargs) 
								-- or you can use send but then you have to re-implement a 
								-- new parser. Note: dont close client before this line
								-- tcpClient:send( "ssssss" .. "\n")
							end		
						end																							
					end
			end
	end
	
	if tcpServer == nil then 
		tcpServer, _ = createTCPServer( "8087" )
	end
	Runtime:addEventListener( "enterFrame" , runTCPServer )
		
	local options = { 
						--hasBackground = false, 
						baseUrl = system.DocumentsDirectory, 
						--urlRequest = function( event ) return true end
					 }

	native.showWebPopup("index.html", options )
	
end

-- On my case I use uncompress a tar file containing all the page assets
-- This illustrates a simple scenario
copyFile( "index.html", system.ResourcesDirectory, "index.html", system.DocumentsDirectory )

local args = {}
args.arg = "Hello"
doStuff( args )


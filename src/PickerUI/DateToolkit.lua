module(..., package.seeall)

function padZeros(s, count)
	return string.rep("0", count-string.len(s)) .. s 
end

-- get date parts for a given ISO 8601 date format 
function getDateSegments(dateSTR, informat)
	if informat == nil then
		informat = "(%d+)-(%d+)-(%d+)"
	end

	local _,_,y,m,d = string.find(dateSTR, informat)

	if informat ~= "(%d+)-(%d+)-(%d+)" then
		return tonumber(y), getRevMonth(m), tonumber(d)
	else
		return tonumber(y), tonumber(m), tonumber(d)
	end
end

function getMonth(month)
	local months = { 
		"Jan", "Feb", "Mar",
		"Apr", "May", "Jun",
		"Jul", "Aug", "Sep",
		"Oct", "Nov", "Dec"
	}
	return months[month]
end

function getRevMonth( month )
	local months = { 
			jan = 1, feb = 2, mar = 3,
			apr = 4, may = 5, jun = 6,
			jul = 7, aug = 8, sep = 9,
			oct = 10, nov = 11, dec = 12
		}
	return months[string.lower(string.sub(month,1,3))]
end

function getDayPosfix( day )
	local idd = math.mod(day, 10)
	local c1 = idd == 1 and day ~= 11 and "st"
	local c2 = idd == 2 and day ~= 12 and "nd"
	local c3 = idd == 3 and day ~= 13 and "rd"
	return c1 or c2 or c3 or "th"
end

-- Note : dateSTR has to be  ISO 8601 date format  ie. yyyy-mm-dd
function formatDate(dateSTR, dateformat, informat)
	local iyy, imm, idd 

	if (dateSTR and dateSTR ~= "") then
		iyy, imm, idd =  getDateSegments(dateSTR, informat)

		dateformat = string.gsub(dateformat, "DDD",  idd..string.upper(getDayPosfix(idd)))
		dateformat = string.gsub(dateformat, "ddd",  idd..getDayPosfix(idd) )
		dateformat = string.gsub(dateformat, "dd", padZeros(idd,2))
		dateformat = string.gsub(dateformat, "MMM", string.upper(getMonth(imm)))
		dateformat = string.gsub(dateformat, "mmm", getMonth(imm))
		dateformat = string.gsub(dateformat, "mm", padZeros(imm,2))
		dateformat = string.gsub(dateformat, "yyyy", padZeros(iyy,4))
		dateformat = string.gsub(dateformat, "yy", string.sub(padZeros(iyy,4),3,4))
	else
		dateformat = ""
	end

	return(dateformat)
end

function getCurrentDate()
	local date = os.date( "*t" )
	return date.year .. "/" .. date.month .. "/" .. date.day
end

function getCurrentDateYMD()
	local date = os.date( "*t" )
	return date.year, date.month, date.day
end

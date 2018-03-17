change = 0
couldSimulate = 0
viruses = 0
pills = 0

local function getFileBoard(  )
	local board = {}
	local infile = io.open("falling board.txt" , "rb")
 
	for i=1,16 do
		board[i] = {} 
		local row = infile:read() 
		--emu.print(row )

		for j=1,8 do
			board[i][j] = row:sub((j*4)-3,(j*4) -2)
		end 
	end
	infile:close()
	return board
end
local function getCurrentPill()
	local str = string.format( "%X", memory.readbyte(0x0081) ) .. string.format("%X", memory.readbyte(0x0082) )
	return str
end
local function getNextPill( )
	local str = string.format( "%X", memory.readbyte(0x009A) ) .. string.format("%X", memory.readbyte(0x009B) )
	return str
end
local function printBoard(board )
	local i,j
	for i=1,16 do
		local listRow = {}
		for j=1,8 do
			table.insert(listRow,board[i][j])
		end
		emu.print(listRow)
	end
end
local function getGameBoard(board)
	local x,count
	count = 0
	x = 1
	for i=0x0C00 ,0x0C7F do
			count = count + 1
			if (count == 9) then 
				count = 1
				x = x + 1
			end
			board[x][count] = string.format( "%X", memory.readbyte(i) )
			--emu.print( board[x][count] .."<<<")
 	end
 	return board
end

local function getViruses( board )
	local i, j, count

	count = 0
	for i=1,16 do
		for j=1,8 do
			if (board[i][j]:sub(1,1) == "D") then count = count + 1 end
		end 
 	end
 	return count
end

local function getPillHeights( board )
	local count = 0
	local i,j,list
	list = {}
	listDiff = {}

	for j=1,8 do	
		count = 0
		for i=1,16 do
			if (board[i][j] ~= "FF") then break end
			count = count + 1
		end
		table.insert(list, count)

	end
	local last = list[1]
	for i=2,8 do
		if (last - list[i] < 0) then
			table.insert(listDiff,list[i] - last)
		else
			table.insert(listDiff,last - list[i])
		end 
		last = list[i]
	end

end
local function getFitnessScore ()
	return pills + (viruses * 8)
end
function bestPillPlacement( pill,board)
	local maxscore = 0
	maxscoreI = -1
	maxscoreJ = -1
	local i,j
	for i=1,8 do
		for j=0,3 do
			simulatePill(i,pill,j,board)
			if (couldSimulate == 1) then
				if (maxscore < getFitnessScore()) then
					maxscoreI = i
					maxscoreJ = j
					maxscore = getFitnessScore()
				end
			end
		end
	end
	--board = simulatePill(maxscoreI,pill,maxscoreJ,board)
	--emu.print(maxscore ..",".. maxscoreI ..",".. maxscoreJ)
	return board
end


function simulatePill(col,pill,rotation,board)
	--rotation :0 and 2 are horizontile, 1 and 3 are vertical
	local count = 0
	--LOOP until highest object in column is found
	for i=1,16 do
		local temp = ""..board[tonumber(i)][tonumber(col)]
		if (temp ~= "FF") then break end
		count = count + 1
	end
	--emu.print(col .. " " .. pill .." "..rotation )
	--emu.print("-----")
	--printBoard(board)
	--emu.print("-----")

	if ( rotation == 0) then
		if (count  < 16) then
			if(board[count][tonumber(col) + 1] ~= "FF" ) then
				board[count][tonumber(col)] =  "6".. pill:sub(1,1) 
				board[count][tonumber(col) + 1] =  "7"..pill:sub(2,2)
				couldSimulate = 1
			else
				couldSimulate = 0
				return board
			end
		end
	elseif (rotation == 2) then
		if (count < 16) then
			if(board[col][count+1] ~= "FF") then
				board[col][count] =  "6"..pill:sub(2,2)
				board[col][count+1] =  "7"..pill:sub(1,1)
				couldSimulate = 1
			else
				couldSimulate = 0
				return board
			end
		end
	elseif  (rotation == 1) then
		if (count > 1) then
			board[tonumber(count)][tonumber(col)] = "4"..pill:sub(1,1)
			board[tonumber(count)-1][tonumber(col)] = "5"..pill:sub(2,2)
			couldSimulate = 1
		else
			change = 0
			return board
		end
	elseif (rotation == 3) then
		if (count > 1) then
			board[count][tonumber(col)] = "4"..pill:sub(2,2)
			board[count][tonumber(col)-1] = "5"..pill:sub(1,1)
			couldSimulate = 1
		else
			couldSimulate = 0
			return board
		end
	end
	return matchboard(board)
end

local function deleteNeighbor(y, x, board )
	local i,endX1,endX2,endY1,endY2,countX,countY,typePill
	i = 0
	endX1 = x
	endX2 = x
	endY1 = y
	endY2 = y
	countX = 1
	countY = 1
	
	typePill = board[tonumber(y)][tonumber(x)]:sub(2,2)
	viruses = 0
	pills = 0
	--empty cells cannot delete nearby empty neighbors
	if (board[y][x] == "FF") then return board end

	--find if deletion patern exists vertically or horizontally or both
	--columns
	for i=1,6 do
		if ( y-i > 0 )  then
			if ( board[y-i][x]:sub(2,2) == typePill) then
				countY = countY + 1
				endY1 = y-i
			else
				break
			end
		end
	end
	for i=1,6 do
		if ( y+i < 17 )  then
			if ( board[y+i][x]:sub(2,2) == typePill) then
				countY = countY + 1
				endY2 = y+i
			else
				break
			end
		end
	end
	--rows
	for i=1,8 do
		if ( x-i > 0 ) then

			if ( board[y][x-i]:sub(2,2) == typePill) then
				countX = countX + 1
				endX1 = x-i
			else
				break
			end
		end
	end
	for i=1,8 do
		if ( x+i < 9 ) then
			if ( board[y][x+i]:sub(2,2) == typePill) then
				countX = countX + 1
				endX2 = x+i
			else
				break
			end
		end
	end

	--delete neighbors if there is 4 in a row or column
	if (countX > 3) then
		for i=endX1,endX2 do
			--clean up board by fixing adjacent pill connections. ignore connections within deletion
			if (board[y][i]:sub(1,1) == "4" ) then board[y+1][i] = "8"..typePill end
			if (board[y][i]:sub(1,1) == "5" ) then board[y-1][i] = "8"..typePill end
			if (board[y][i]:sub(1,1) == "6" and board[y][i+1]:sub(1,1) ~= "F") then board[y][i+1] = "8"..typePill end
			if (board[y][i]:sub(1,1) == "7" and board[y][i-1]:sub(1,1) ~= "F") then board[y][i-1] = "8"..typePill end
			
			if (board[y][i]:sub(1,1) == "D") then viruses = viruses + 1 
			else pills = pills + 1
			end
			board[y][i] = "F"..typePill

		end
		change = 1;
	end
	if (countY > 3)  then
		for i=endY1,endY2 do
			--clean up board by fixing adjacent pill connections. ignore connections within deletion
			if (board[i][x]:sub(1,1) == "4" and board[i+1][x]:sub(1,1) ~= "F") then board[i][x] = "8"..typePill end
			if (board[i][x]:sub(1,1) == "5" and board[i-1][x]:sub(1,1) ~= "F") then board[i][x] = "8"..typePill end
			if (board[i][x]:sub(1,1) == "6") then board[i][x+1] = "8"..typePill end
			if (board[i][x]:sub(1,1) == "7") then board[i][x-1] = "8"..typePill end
			
			if (board[i][x]:sub(1,1) == "D") then viruses = viruses + 1
			else pills = pills + 1
			end
			board[x][i] = "F"..typePill
		end
		change = 1;
	end
	if (countX < 3 and countY < 3) then
		change = 0
	end
	return board
end

--compute fallen position for pills
local function fall(x, y, board)
	local i = 0 
	local count = 0 
	--emu.print("Falling :"..x..","..y)
	--if at bottom of board the pill cannot fall
	--if (x == 0) then return board 
	--end 
	
	--emu.print(x.."-"..y .. ":" .. board[x][y])
	
	--figure out the type of pill (vertical, horizontile, or single)
	local typePill = board[x][y]:sub(1,1) 
	--emu.print(tostring(typePil)
	if ( typePill == "8") then -- single pill, simplest case
		--emu.print("single")
		--drop pill
		for i=1,8 do
			--look down for solid ground until you hit something
			if (i+x < 17) then
				if (board[x+i][y] ~= "FF" ) then 
					break 
				else 
					count = count + 1 
				end 
			end
		end 
		--swap lowest empty space and original position if it isn't already at lowest position
		if (count > 0) then
			board[x+count][y] = board[x][y] 
			board[x][y] = "FF" 
			change = 1
						
		elseif (count == 0) then
			change = 0
		end
		return board

	elseif ( typePill == "5" ) then -- bottom of a vertical pill
	--	emu.print("vertical")
		--drop pill
		for i=1,8 do
			--look down for solid ground
			if (i+x < 17) then
				if (board[x+i][y] ~= "FF") then 
					break 
				else 
					count = count + 1 
				end 
			end
		end 

		--swap lowest empty space and original position if it isn't already at lowest position
		--also swap top section of vertical pill
		if (count > 0) then
			board[x+count][y] = board[x][y] 
			board[x][y] = "FF" 
			board[x-1+count][y] = board[x-1][y] 
			board[x-1][y] = "FF" 
			change = 1
		elseif (count == 0) then
			change = 0
		end 

		return board
  
	elseif (typePill == "6") then-- horizontile left pill
		--emu.print("horizontile")
		local left,right = 0 
		for i=1,8 do
			--look down for solid ground
			if (i+x < 17) then
				if (board[x+i][y] ~= "FF") then 
					break 
				else 
					count = count + 1 
				end 
			end 
		end
		left = count

		count = 0
		for i=1,8 do
			--look down for solid ground
			if (i+x < 17) then
				if (board[x+i][y+1] ~= "FF") then 
					break 
				else 
					count = count + 1 
				end 
			end
		end 
		right = count

		if (left == 0 or right == 0 ) then --pill cannot drop
			change = 0
			return board
		end 

		if (left < right  ) then--left pill hits somthing before right pill

			board[x+left][y] = board[x][y] 
			board[x][y] = "FF" 
			board[x+left][y+1] = board[x][y+1] 
			board[x][y+1] = "FF"
		else --right pill hits somthing before right pill

			board[x+right][y] = board[x][y] 
			board[x][y] = "FF" 
			board[x+right][y+1] = board[x][y+1] 
			board[x][y+1] = "FF"
		end 
		change = 1
		return board
	elseif (typePill == "F" and board[x][y] ~= "FF") then-- deletes remnants of matched pills and viruses
		board[x][y] = "FF"
		--emu.print("CLEANUP	")
		change = 0
		return board
	else 
		--emu.print("something else	")
		change = 0
		return board
	end 
	
	--emu.print(tostring(count)) 

end 
function matchboard( board )
	--a diamond pattern to remove matched elements without checking every space

	--	1	2	3	4	5	6	7	8
--	1	X				X	
-- 	2		X		X		X		X
--	3			X				X	
--	4		X		X		X		X
--	5	X				X			
--	6		X		X		X		X
--	7			X				X	
--	8		X		X		X		X
--	9	X				X	
--	10		X		X		X		X
--	11			X				X	
--	12		X		X		X		X
--	13	X				X			
--	14		X		X		X		X
--	15			X				X	
--	16		X		X		X		X
	local bool = 0
	local virusesDetroyed = 0
	local pillsDetroyed = 0
	local i,j
	for i=1,16 do
		if i%2==0 then 	-- if even row
			if i%4==0 then
				board = deleteNeighbor(i,1,board)
				virusesDetroyed = virusesDetroyed + viruses
				pillsDetroyed = pillsDetroyed + pills
				if change == 1 then bool = 1 end
				board = deleteNeighbor(i,5,board)
				virusesDetroyed = virusesDetroyed + viruses
				pillsDetroyed = pillsDetroyed + pills
				if change == 1 then bool = 1 end
			elseif i%4==2 then
				board = deleteNeighbor(i,3,board)
				virusesDetroyed = virusesDetroyed + viruses
				pillsDetroyed = pillsDetroyed + pills
				if change == 1 then bool = 1 end
				board = deleteNeighbor(i,7,board)	
				virusesDetroyed = virusesDetroyed + viruses
				pillsDetroyed = pillsDetroyed + pills
				if change == 1 then bool = 1 end	
        	end
		else 			-- if odd row
			for j=2,8,2 do
				board = deleteNeighbor(i,j,board)
				virusesDetroyed = virusesDetroyed + viruses
				pillsDetroyed = pillsDetroyed + pills
				if change == 1 then bool = 1 end
			end
		end
	end
	
	--let everything fall and delete the matched pills and viruses from
	for i=16,1,-1 do
		for j=1,8 do			
			board = fall(i,j,board)
			if change == 1 then bool = 1 end
		end
	end

	--loop the deletion and fall routines until the board is stable
	while bool == 1 do
		bool = 0
		
		for i=1,16 do
			if i%2==0 then 	-- if even row
				if i%4==0 then
					board = deleteNeighbor(i,1,board)
					virusesDetroyed = virusesDetroyed + viruses
					pillsDetroyed = pillsDetroyed + pills
					if change == 1 then bool = 1 end
					board = deleteNeighbor(i,5,board)
					virusesDetroyed = virusesDetroyed + viruses
					pillsDetroyed = pillsDetroyed + pills
					if change == 1 then bool = 1 end
				elseif i%4==2 then
					board = deleteNeighbor(i,3,board)
					virusesDetroyed = virusesDetroyed + viruses
					pillsDetroyed = pillsDetroyed + pills
					if change == 1 then bool = 1 end
					board = deleteNeighbor(i,7,board)	
					virusesDetroyed = virusesDetroyed + viruses
					pillsDetroyed = pillsDetroyed + pills
					if change == 1 then bool = 1 end	
        		end
			else 			-- if odd row
				for j=2,8,2 do
					board = deleteNeighbor(i,j,board)
					virusesDetroyed = virusesDetroyed + viruses
					pillsDetroyed = pillsDetroyed + pills
					if change == 1 then bool = 1 end
				end
			end
			emu.print(bool.."H")
		end
		
		--let everything fall and delete the matched pills and viruses from
		for i=16,1,-1 do
			for j=1,8 do			
				board = fall(i,j,board)
				if change == 1 then bool = 1 end
			end
		end
		
	end 
	viruses = virusesDetroyed
	pills = pillsDetroyed
	return board
end



--local test = {fall(7,3,board)}
--board =  matchboard(board)
board = getFileBoard()
board = simulatePill(2,"11",1,board)
--board = getGameBoard(board)
--local str = getCurrentPill()
--emu.print(str)
--str = getNextPill()
--emu.print(str)
--board = simulatePill("1","5242","1",board)
--emu.print(couldSimulate .. " couldSimulate")
--emu.print(viruses .. " viruses")
--board = bestPillPlacement("11",board)

local file = io.open("board.txt" , "w")
for i=1,16 do

	for j=1,8 do

		if (board[i][j] ~= nil) then file:write(board[i][j])   end 
		if (j == 8)then file:write("\n") 
		end 
	end 

end 
file:close()


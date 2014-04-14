Namespace('WordSearch').Puzzle = do ->
	# constants
	BOARD_HEIGHT = 450
	BOARD_WIDTH = 550
	PADDING_LEFT = 20
	PADDING_TOP = 65

	puzzleSpots = []
	finalWordPositions = []
	currentWordNum = null

	_solvedRegions = []

	wordList = []
	wordStrings = []

	_backwards = false
	_diagonal = false

	_qset = {}
	_context = {}

	randomDirections = ->
		choiceOrder = [0,1,2,3,4,5,6,7]
		randChoiceOrder = []
		while choiceOrder.length > 0
			i = Math.floor(Math.random() * choiceOrder.length)
			randChoiceOrder.push choiceOrder[i]
			choiceOrder.splice(i,1)

		return randChoiceOrder

	randomPositions = ->
		r = []
		for ty in [0...puzzleSpots.length]
			for tx in [0...puzzleSpots[0].length]
				r.push [tx,ty]

		newr = []
		while r.length > 0
			i = Math.floor(Math.random() * r.length)
			newr.push r[i]
			r.splice(i,1)

		return newr
	
	placeWord = (word, dir) ->
		r = randomPositions()
		for i in [0...r.length]
			tx = r[i][0]
			ty = r[i][1]

			switch dir
				when 0 # forwards
					return tryToPlaceWord(word,tx,ty,1,0)
				when 1 # down
					return tryToPlaceWord(word,tx,ty,0,1)
				when 2 # up
					return _backwards && tryToPlaceWord(word,tx,ty,0,-1)
				when 3 # backwards
					return _backwards && tryToPlaceWord(word,tx,ty,-1,0)
				when 4 # diagonal up
					return _diagonal && tryToPlaceWord(word,tx,ty,1,-1)
				when 5 # diagonal down
					return _diagonal && tryToPlaceWord(word,tx,ty,1,1)
				when 6 # diagonal up back
					return _backwards && _diagonal && tryToPlaceWord(word,tx,ty,-1,-1)
				when 7 # diagonal down back
					return _backwards && _diagonal && tryToPlaceWord(word,tx,ty,-1,1)

		return false

	tryToPlaceWord = (word,tx,ty,xChange,yChange) ->
		for i in [0...word.length]
			if not checkLetter(word.charAt(i), tx + (i*xChange), ty + (i*yChange))
				return false
		for i in [0...word.length]
			puzzleSpots[ty + (i*yChange)][tx + (i*xChange)] = word.charAt(i)

		recordWordPosition(tx,ty,tx + (word.length-1) * xChange, ty + (word.length-1) * yChange)
		return true

	recordWordPositions = (sx,sy,ex,ey) ->
		finalWordPositions.push [sx,sy,ex,ey]
	
	makePuzzle = (words,backwards,diagonal) ->
		_backwards = backwards
		_diagonal = diagonal

		puzzleSpots = blankPuzzle 1, 1
		wordStrings = words.slice()
		finalWordPositions = []
		addWord(longestWordsFirst(words))

		fillExtraSpaces()

		puzzleSpots
	
	fillExtraSpaces = ->
		for j in [0...puzzleSpots.length]
			for i in [0...puzzleSpots[0].length]
				if puzzleSpots[j][i] == " "
					puzzleSpots[j][i] = String.fromCharCode(Math.floor(Math.random() * 26) + 97)

	addWord = (words) ->
		currentWordNum = 0
		word = words[currentWordNum].replace(/\s/g,'')

		randDirection = randomDirections()

		for i in [0...randDirection.length]
			if (placeWord(word, randDirection[i]))
				words.splice(currentWordNum,1)
				if words.length <= 0
					return
				else
					addWord(words)
					return

		increasePuzzleSize(1,1)
		addWord(longestWordsFirst(words))
	
	increasePuzzleSize = (w,h) ->
		newPuzzleSpots = []

		for j in [0...h+puzzleSpots.length]
			newPuzzleSpots.push []
			for i in [0...w+puzzleSpots[0].length]
				newPuzzleSpots[j].push " "

		randWidthOffset = Math.floor(Math.random() * w)
		randHeightOffset = Math.floor(Math.random() * h)

		for j in [0...puzzleSpots.length]
			for i in [0...puzzleSpots[0].length]
				newPuzzleSpots[j+randHeightOffset][i+randWidthOffset] = puzzleSpots[j][i]

		puzzleSpots = newPuzzleSpots

		for i in [0...finalWordPositions.length]
			finalWordPositions[i][0] += randWidthOffset
			finalWordPositions[i][2] += randWidthOffset
			finalWordPositions[i][1] += randHeightOffset
			finalWordPositions[i][3] += randHeightOffset
	
	longestWordsFirst = (words) ->
		return words.sort (a,b) ->
			if a.length > b.length
				return -1
			else if (a.length < b.length)
				return 1
			return 0
	
	getFinalWordPositionsString = ->
		s = ""
		for i in [0...finalWordPositions.length]
			for j in [0...finalWordPositions[i].length]
				s += finalWordPositions[i][j] + ","
		s

	blankPuzzle = (w,h) ->
		t = []
		for ty in [0...h]
			t.push []
			for tx in [0...w]
				t[ty].push " "
		return t
	
	checkLetter = (letter, tx, ty) ->
		return false if ty < 0 or ty >= puzzleSpots.length
		return false if tx < 0 or tx >= puzzleSpots[0].length
		return true if puzzleSpots[ty][tx] == letter or puzzleSpots[ty][tx] == " "
		return false

	recordWordPosition = (sx,sy,ex,ey) ->
		finalWordPositions.push [sx,sy,ex,ey]

	# clears and draws letters and ellipses on the canvas
	_drawBoard = (context, qset, _clickStart, _clickEnd, _isMouseDown = false) ->
		_qset = qset
		_context = context

		# set font
		size = (38 / (_qset.options.puzzleHeight / 8))
		size = 32 if size > 32

		_context.font = "bold "+size+"px verdana"
		_context.fillStyle = "#fff"
		_context.textAlign = 'center'

		# starting points for array positions
		x = 0
		y = 1

		# letter widths derived from the ratio of canvas area to puzzle size in letters
		width = BOARD_WIDTH / (_qset.options.puzzleWidth-1)
		height = BOARD_HEIGHT / ( _qset.options.puzzleHeight-1)

		# clear the array, plus room for overflow
		_context.clearRect(0,0,BOARD_WIDTH + 200,BOARD_HEIGHT + 200)

		# create a vector from the start and end points of the grid, from the mouse positions
		# this vector is corrected to be in 45 degree increments
		if _isMouseDown
			vector = _correctDiagonalVector _getGridFromXY(_clickStart), _getGridFromXY(_clickEnd)
			gridStart = vector.start
			gridEnd = vector.end

			# restrict it if the starting point is out of bounds
			if gridStart.x >= _qset.options.puzzleWidth or gridStart.y > _qset.options.puzzleHeight
				gridStart = gridEnd = x: -1, y: -1

			_circleWord(gridStart.x, gridStart.y, gridEnd.x, gridEnd.y)

		# iterate through the letter spot string
		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			# draw letter
			_context.fillText letter, PADDING_LEFT + 10 + x * width, PADDING_TOP + (y-1) * height

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++

		# circle completed words
		for region in _solvedRegions
			_circleWord(region.x,region.y,region.endx,region.endy)
	
	_circleWordXY = (start,end) ->
		start = _getGridFromXY(start)
		end = _getGridFromXY(end)

		_circleWord(start.x,start.y,end.x,end.y)

	# draw circle (lines with endcaps) on a word
	_circleWord = (x,y,endx,endy) ->
		# dont draw it out of bounds
		return if y == 0

		# x1, x3, y1, y3 are start points, respectively to their even pair
		x1 = x3 = Math.ceil(x * BOARD_WIDTH / (_qset.options.puzzleWidth-1) + 10 + PADDING_LEFT)
		y1 = y3 = Math.ceil((y-1) * BOARD_HEIGHT / (_qset.options.puzzleHeight-1) + PADDING_TOP - 12)

		# same deal here. x1 -> x2, y1 -> y2, x3 -> x4, y3 -> y4
		x2 = x4 = Math.ceil(endx * BOARD_WIDTH / (_qset.options.puzzleWidth-1) + 10 + PADDING_LEFT)
		y2 = y4 = Math.ceil((endy-1) * BOARD_HEIGHT / (_qset.options.puzzleHeight-1) + PADDING_TOP - 12)

		if x1 != x2 # horizontal
			if y1 != y2	# diagonal
				if y1 > y2 and x1 > x2 or y1 < y2 and x2 > x1
					angle1 = 3 * Math.PI / 4
					angle2 = 7 * Math.PI / 4

					x1 -= 14
					x2 -= 14
					y1 += 14
					y2 += 14

					x3 += 14
					x4 += 14
					y3 -= 14
					y4 -= 14
				else
					angle1 = 5 * Math.PI / 4
					angle2 = 1 * Math.PI / 4

					x1 -= 14
					x2 -= 14
					y1 -= 14
					y2 -= 14

					x3 += 14
					x4 += 14
					y3 += 14
					y4 += 14
			else
				y3 -= 20
				y4 -= 20
				y1 += 20
				y2 += 20
				angle1 = Math.PI / 2
				angle2 = 3 * Math.PI / 2
		else # vertical
			x1 -= 20
			x2 -= 20
			x3 += 20
			x4 += 20
			angle1 = Math.PI
			angle2 = 2 * Math.PI
		
		# go counter clockwise if the selection is reversed
		if x1 > x2 and y1 > y2 or x1 < x2 and y1 > y2 or y1 == y2 and x1 > x2 or x1 == x2 and y1 > y2
			counter = true

		# set stroke
		_context.lineWidth = 5
		_context.strokeStyle = '#2DFF84'

		# draw straight lines
		_context.beginPath()
		_context.moveTo(x1,y1)
		_context.lineTo(x2,y2)
		_context.stroke()

		_context.beginPath()
		_context.moveTo(x3,y3)
		_context.lineTo(x4,y4)
		_context.stroke()

		# draw arcs
		_context.beginPath()
		_context.arc(((x1+x3) / 2), ((y1+y3) / 2), 20, angle1, angle2, counter)
		_context.stroke()
		_context.beginPath()
		_context.arc(((x2+x4) / 2), ((y2+y4) / 2), 20, angle1 - Math.PI, angle2 - Math.PI, counter)
		_context.stroke()

	# convert X,Y mouse coordinates to grid coords
	_getGridFromXY = (pos) ->
		gridX = Math.ceil((pos.x - PADDING_LEFT - 20) * (_qset.options.puzzleWidth-1) / BOARD_WIDTH)
		gridY = Math.ceil((pos.y - PADDING_TOP) * (_qset.options.puzzleHeight-1) / BOARD_HEIGHT)

		x: gridX, y: gridY
	
	# force a vector to a 45 degree increment
	_correctDiagonalVector = (gridStart, gridEnd) ->
		# calculate distance between start and end
		deltaX = Math.abs(gridStart.x - gridEnd.x)
		deltaY = Math.abs(gridStart.y - gridEnd.y)

		# if its diagonal
		if gridStart.x != gridEnd.x and gridStart.y != gridEnd.y
			# lock it in whatever direction is greater, if its 
			# not quite diagonal enough
			if deltaX > deltaY and deltaY == 1
				gridEnd.y = gridStart.y
			if deltaX < deltaY and deltaX == 1
				gridEnd.x = gridStart.x

		# if its still diagonal, even after we try to correct it
		if gridStart.x != gridEnd.x and gridStart.y != gridEnd.y
			if deltaX != deltaY
				if gridEnd.y > gridStart.y
					if gridEnd.x > gridStart.x
						gridEnd.y = gridStart.y + (gridEnd.x - gridStart.x)
					else
						gridEnd.y = gridStart.y - (gridEnd.x - gridStart.x)
				else
					if gridEnd.x < gridStart.x
						gridEnd.y = gridStart.y + (gridEnd.x - gridStart.x)
					else
						gridEnd.y = gridStart.y - (gridEnd.x - gridStart.x)

		if gridEnd.y > _qset.options.puzzleHeight
			delta = -_qset.options.puzzleHeight + gridEnd.y
			if gridEnd.x > gridStart.x
				gridEnd.x -= delta
			else if gridEnd.x < gridStart.x
				gridEnd.x += delta
			gridEnd.y -= delta

		if gridEnd.y < 1
			delta = 1 - gridEnd.y
			if gridEnd.x > gridStart.x
				gridEnd.x -= delta
			else if gridEnd.x < gridStart.x
				gridEnd.x += delta
			gridEnd.y += delta

		if gridEnd.x > _qset.options.puzzleWidth - 1
			delta = gridEnd.x - (_qset.options.puzzleWidth - 1)
			if gridEnd.y > gridStart.y
				gridEnd.y -= delta
			else if gridEnd.y < gridStart.y
				gridEnd.y += delta
			gridEnd.x -= delta

		if gridEnd.x < 0
			delta = -gridEnd.x
			if gridEnd.y > gridStart.y
				gridEnd.y -= delta
			else if gridEnd.y < gridStart.y
				gridEnd.y += delta
			gridEnd.x += delta

		start: gridStart
		end: gridEnd

	makePuzzle: makePuzzle
	getFinalWordPositionsString: getFinalWordPositionsString
	drawBoard: _drawBoard
	getGridFromXY: _getGridFromXY
	circleWord: _circleWord
	circleWordXY: _circleWordXY
	correctDiagonalVector: _correctDiagonalVector
	solvedRegions: _solvedRegions


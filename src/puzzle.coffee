Namespace('WordSearch').Puzzle = do ->
	# constants
	BOARD_WIDTH = 540
	BOARD_HEIGHT = 475
	HEADER_HEIGHT = 65
	PADDING_LEFT = 40
	PADDING_TOP = 40

	# const of xChange, yChange values; index is direction inex
	DIRECTION_CHANGES = [
		{x: 1, y: 0},
		{x: 0, y: 1},
		{x: 0, y: -1},
		{x: -1, y: 0},
		{x: 1, y: -1},
		{x: 1, y: 1},
		{x: -1, y: -1},
		{x: -1, y: 1},
	]

	_letterWidth = 0
	_letterHeight = 0

	puzzleSpots = []
	finalWordPositions = ''

	_solvedWordCoordinates = []

	_qset = {}
	_context = {}

	_allowedDirections = []


	# Fisher–Yates shuffle an array, returns a duplicate
	shuffle = (srcArray) ->
		arr = srcArray.slice()
		len = arr.length
		while len > 0
			i = Math.floor(Math.random() * len)
			len--

			# swap
			temp = arr[len];
			arr[len] = arr[i];
			arr[i] = temp;

		return arr

	# return a shuffled array of random direction ints (0-7)
	# excludes options that aren't allowed
	# 0 forwards
	# 1 down
	# 2 up
	# 3 left
	# 4 diagonal up right
	# 5 diagonal down right
	# 6 diagonal up left
	# 7 diagonal down left
	updateAllowedDirections = (allowBackwards, allowDiagonal) ->
		dirs = [0, 1] # right, down
		dirs = dirs.concat([2, 3]) if allowBackwards
		dirs = dirs.concat([4, 5]) if allowDiagonal
		dirs = dirs.concat([6, 7]) if allowBackwards and allowDiagonal
		_allowedDirections = dirs

	# return a shuffled array of all puzzle spots
	randomPositions = ->
		spots = []
		for ty in [0...puzzleSpots.length]
			for tx in [0...puzzleSpots[0].length]
				spots.push [tx, ty]

		return shuffle(spots)

	# attempt to place a word
	placeWordAt = (word, dir, x, y) ->
		xChange = DIRECTION_CHANGES[dir].x
		yChange = DIRECTION_CHANGES[dir].y

		return false if not canWordBePlacedAt(word, x, y, xChange, yChange)

		# we can place this word, set the coordinates of each letter
		for char, i in word
			puzzleSpots[y + (i*yChange)][x + (i*xChange)] = char

		# place in our final positions array
		addFinalWordPosition(x, y, x + (word.length-1) * xChange, y + (word.length-1) * yChange)
		return true

	# determine if the existing spots on the puzzle will allow this word to be placed here
	canWordBePlacedAt = (word, tx, ty, xChange, yChange) ->
		# run through the word to make sure we can place each letter
		for i in [0...word.length]
			if not canLetterBePlacedAt(word[i], tx + (i*xChange), ty + (i*yChange))
				return false
		true

	# removes spaces from words
	filterWords = (words) -> words.map((w) -> w.replace(/\s/g,''))

	makePuzzle = (words, allowBackwards, allowDiagonal) ->
		# figure out which directions are allowed once per draw
		updateAllowedDirections(allowBackwards, allowDiagonal)

		# clean the words
		words = filterWords(words)

		# find the longest word first to help us set a good initial puzzle size
		sortedWords = sortLongestWordsFirst(words)

		# initialize set the puzzle size based on the longest word
		# this skips a lot of work scaling the puzzle up one character at a time
		puzzleSpots = buildBlankPuzzle sortedWords[0].length, sortedWords[0].length

		finalWordPositions = ''
		addWords(sortedWords)

		fillEmptySpacesWithRandomLetters()

		puzzleSpots

	# if a puzzle spot is empty - place a random character there
	fillEmptySpacesWithRandomLetters = ->
		for col, x in puzzleSpots
			for row, y in col
				if row == " "
					puzzleSpots[x][y] = String.fromCharCode(Math.floor(Math.random() * 26) + 97)

	# recursively add a list of words to the puzzle in random locations/positions
	addWords = (words) ->
		word = words[0]
		# try each random direction on each random spot
		for direction in shuffle(_allowedDirections)
			for position in randomPositions()
				if placeWordAt(word, direction, position[0], position[1])
					# when we are able to place a word:
					# 1. remove placed word from the list
					# 2. recurse if there are more words
					# 3. return up / rollup recursive function
					words.shift()
					if words.length > 0
						addWords(words)
					return

		# recursive path failed to place a word
		# increase the size by one, try again
		# row + col should easily allow another word to fit
		expandPuzzleBy(1, 1)
		addWords sortLongestWordsFirst(words)

	# TODO: this functions needs some refatoring & comments
	# It seems like it's only useful effect is to update puzzleSpots
	expandPuzzleBy = (w, h) ->
		newPuzzleSpots = []

		for j in [0...h+puzzleSpots.length]
			newPuzzleSpots.push []
			for i in [0...w+puzzleSpots[0].length]
				newPuzzleSpots[j].push " "

		for j in [0...puzzleSpots.length]
			for i in [0...puzzleSpots[0].length]
				newPuzzleSpots[j][i] = puzzleSpots[j][i]

		puzzleSpots = newPuzzleSpots

	sortLongestWordsFirst = (words) ->
		words.sort (a,b) -> b.length - a.length


	# build data structure for a blank puzzle at the desired size
	buildBlankPuzzle = (w, h) ->
		t = []
		for ty in [0...h]
			t.push []
			for tx in [0...w]
				t[ty].push " "
		return t

	# check if the specifid spot is empty or already contains the given letter
	# this is used for determining if a letter in a word can be placed in a specific position
	canLetterBePlacedAt = (letter, x, y) ->
		if puzzleSpots[y]?[x]?
			return (puzzleSpots[y][x] == letter or puzzleSpots[y][x] == " ")
		false

	# finalWordPositions is used for saving
	# generate a string of comma separated coordinates for the start and end of every word
	# ex: 0,9,9,10,7,3,1,9 - that is: x,y,x,y,x,y,...
	# this would be 2 words
	# word1 (0,9,9,10) -> {startx:0, starty:9, endx:9, endy: 10}
	# word2 (7,3,1,9) -> {startx:7, starty:3, endx:1, endy: 9}
	addFinalWordPosition = (startX, startY, endX, endY) ->
		finalWordPositions +=  [startX, startY, endX, endY].join(',') + ','

	getFinalWordPositionsString = -> finalWordPositions.trim(',')

	# figure out roughly which letter the keyboard cursor is over based on X/Y
	# position then pass roughly equivalent mouse coordinates to the usual _drawBoard
	_drawBoardFromKeyboardEvent = (context, qset, selectStart, selectEnd, isSelecting) ->
		console.log('drawing board from a keyboard event')
		yOffset = HEADER_HEIGHT + PADDING_TOP
		xOffset = PADDING_LEFT

		startX = selectStart.x * _letterWidth + xOffset + _letterWidth / 2
		startY = selectStart.y * _letterHeight + yOffset + _letterHeight / 2

		endX = selectEnd.x * _letterWidth + xOffset + _letterWidth / 2
		endY = selectEnd.y * _letterHeight + yOffset + _letterHeight / 2

		calculatedMouseStart = x: startX, y: startY
		calculatedMouseEnd = x: endX, y: endY

		_drawBoard(context, qset,calculatedMouseStart, calculatedMouseEnd, isSelecting)

		# draw a marker to indicate where the cursor is, after drawing the circled letters
		if isSelecting
			_context.moveTo(endX, endY - HEADER_HEIGHT)
			_context.beginPath()
			_context.arc(endX, endY - HEADER_HEIGHT, 5, 0, 2 * Math.PI, false)
			_context.lineWidth = 2
			_context.stroke()
			_context.fillStyle = 'rgba(46,176,106,.5)'
			_context.fill()

	# clears and draws letters and ellipses on the canvas
	_drawBoard = (context, qset, _clickStart, _clickEnd, _isMouseDown = false) ->
		_qset = qset
		_context = context

		# set font
		size = (38 / (_qset.options.puzzleHeight / 8))
		size = 32 if size > 32

		_context.font = "900 "+size+"px Lato"
		_context.fillStyle = "#fff"
		_context.textAlign = 'center'
		_context.textBaseline = 'middle'

		# starting points for array positions
		x = 0
		y = 1

		# letter widths derived from the ratio of canvas area to puzzle size in letters
		_letterWidth = BOARD_WIDTH / _qset.options.puzzleWidth
		_letterHeight = BOARD_HEIGHT / _qset.options.puzzleHeight

		# clear the array, plus room for overflow
		_context.clearRect(0, 0, BOARD_WIDTH + 200, BOARD_HEIGHT + 200)

		# create a vector from the start and end points of the grid, from the mouse positions
		# this vector is corrected to be in 45 degree increments
		if _isMouseDown
			vector = _correctDiagonalVector _getGridFromXY(_clickStart), _getGridFromXY(_clickEnd)
			gridStart = vector.start
			gridEnd = vector.end

			# restrict it if the starting point is out of bounds
			if gridStart.x >= _qset.options.puzzleWidth or gridStart.y > _qset.options.puzzleHeight or gridStart.x < 0 or gridStart.y <= 0
				gridStart = gridEnd = x: -1, y: -1
			else
				_circleWord(gridStart.x, gridStart.y, gridEnd.x, gridEnd.y)
		else if _clickEnd
			vector = _getGridFromXY(_clickEnd)


		# iterate through the letter spot string
		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			# draw letter
			_context.fillStyle = 'white';
			_context.fillText letter, x * _letterWidth + PADDING_LEFT + _letterWidth / 2, (y-1) * _letterHeight + PADDING_TOP + _letterHeight / 2

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++

		if _clickEnd and vector.x < _qset.options.puzzleWidth and vector.y <= _qset.options.puzzleHeight and vector.x >= 0 and vector.y > 0
			_circleWord(vector.x, vector.y, vector.x, vector.y)

		# circle completed words
		for word in _solvedWordCoordinates
			_circleWord(word.x, word.y, word.endx, word.endy)

	_addFoundWordCoordinates = (startX, startY, endX, endY) ->
		_solvedWordCoordinates.push
			x: startX
			y: startY
			endx: endX
			endy: endY

	_resetFoundWordCoordinates = ->
		_solvedWordCoordinates.length = 0

	_circleWordXY = (start,end) ->
		start = _getGridFromXY(start)
		end = _getGridFromXY(end)

		_circleWord(start.x, start.y, end.x, end.y)

	# draw circle (lines with endcaps) on a word
	_circleWord = (x,y,endx,endy) ->
		rad = 175 / _qset.options.puzzleWidth
		diagrad = rad * 0.7

		start = _getXYFromGrid(x, y)
		end = _getXYFromGrid(endx, endy)

		x1 = x3 = start.x + _letterWidth / 2
		y1 = y3 = start.y + _letterHeight / 2
		x2 = x4 = end.x + _letterWidth / 2
		y2 = y4 = end.y + _letterHeight / 2

		if x1 != x2 # horizontal
			if y1 != y2	# diagonal
				if y1 > y2 and x1 > x2 or y1 < y2 and x2 > x1
					angle1 = 3 * Math.PI / 4
					angle2 = 7 * Math.PI / 4

					x1 -= diagrad
					x2 -= diagrad
					y1 += diagrad
					y2 += diagrad

					x3 += diagrad
					x4 += diagrad
					y3 -= diagrad
					y4 -= diagrad
				else
					angle1 = 5 * Math.PI / 4
					angle2 = 1 * Math.PI / 4

					x1 -= diagrad
					x2 -= diagrad
					y1 -= diagrad
					y2 -= diagrad

					x3 += diagrad
					x4 += diagrad
					y3 += diagrad
					y4 += diagrad
			else
				y3 -= rad
				y4 -= rad
				y1 += rad
				y2 += rad
				angle1 = Math.PI / 2
				angle2 = 3 * Math.PI / 2
		else # vertical
			x1 -= rad
			x2 -= rad
			x3 += rad
			x4 += rad
			angle1 = Math.PI
			angle2 = 2 * Math.PI

		# go counter clockwise if the selection is reversed
		if x1 > x2 and y1 > y2 or x1 < x2 and y1 > y2 or y1 == y2 and x1 > x2 or x1 == x2 and y1 > y2
			counter = true

		# set stroke
		_context.lineWidth = 5
		_context.strokeStyle = 'rgba(45, 255, 132, 0.6)'

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
		_context.arc(((x1+x3) / 2), ((y1+y3) / 2), rad, angle1, angle2, counter)
		_context.stroke()
		_context.beginPath()
		_context.arc(((x2+x4) / 2), ((y2+y4) / 2), rad, angle1 - Math.PI, angle2 - Math.PI, counter)
		_context.stroke()

	# convert X,Y mouse coordinates to grid coords
	_getGridFromXY = (pos) ->
		x: Math.floor((pos.x - PADDING_LEFT) / _letterWidth)
		y: Math.floor((pos.y - HEADER_HEIGHT - PADDING_TOP) / _letterHeight) + 1

	# convert grid coords to the top-left point of the letter box
	_getXYFromGrid = (gx, gy) ->
		x: PADDING_LEFT + gx * _letterWidth
		y: PADDING_TOP + (gy - 1) * _letterHeight

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
	addFoundWordCoordinates: _addFoundWordCoordinates
	resetFoundWordCoordinates: _resetFoundWordCoordinates
	drawBoardFromKeyboardEvent: _drawBoardFromKeyboardEvent

Namespace('WordSearch').Puzzle = do ->
	# constants
	BOARD_WIDTH = 540
	BOARD_HEIGHT = 475
	HEADER_HEIGHT = 65
	PADDING_LEFT = 40
	PADDING_TOP = 40

	_letterWidth = 0
	_letterHeight = 0

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
		_context.clearRect(0,0,BOARD_WIDTH + 200,BOARD_HEIGHT + 200)

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
		for region in _solvedRegions
			_circleWord(region.x,region.y,region.endx,region.endy)

	_circleWordXY = (start,end) ->
		start = _getGridFromXY(start)
		end = _getGridFromXY(end)

		_circleWord(start.x,start.y,end.x,end.y)

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
	solvedRegions: _solvedRegions

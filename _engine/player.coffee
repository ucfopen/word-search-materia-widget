###

Materia
It's a thing

Widget	: Labeling
Authors	: Jonathan Warner
Updated	: 2/14

###

Namespace('WordSearch').Engine = do ->
	_qset                   = null

	# reference to canvas drawing board
	_canvas					= null
	_context				= null

	_clickStart = x: 0, y: 0
	_clickEnd = x: 0, y: 0
	_isMouseDown = false
	_solvedRegions = []

	_letterArray = []

	_egg = false

	BOARD_HEIGHT = 500
	BOARD_WIDTH = 600

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		# prevent selection
		window.onselectstart =
		document.onselectstart = (e) ->
			e.preventDefault() if e and e.preventDefault
			false

		# local variable contexts
		_qset = qset

		# set title
		$('#title').html instance.name

		# get canvas context
		_canvas = document.getElementById('canvas')
		_context = _canvas.getContext('2d')

		# set font
		_context.font = "bold 30px verdana"
		_context.fillStyle = "#fff"

		# set up the player UI
		html = ""
		n = 0
		for question in _qset.items
			html += "<div id='term_" + n + "'>" + question.questions[0].text + "</div>"
			n++
		
		# renders letters
		_drawBoard()

		# add term html to the sidebar
		$('#terms').html html

		# generate letter arrays
		x = 0
		y = 1
		_letterArray[y] = []

		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			_letterArray[y].push letter

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++
				_letterArray[y] = []

		# attach document listeners
		document.addEventListener('touchstart', _mouseDownEvent, false)
		document.addEventListener('mousedown', _mouseDownEvent, false)
		document.addEventListener('touchend', _mouseUpEvent, false)
		document.addEventListener('mouseup', _mouseUpEvent, false)
		document.addEventListener('MSPointerUp', _mouseUpEvent, false)
		document.addEventListener('mouseup', _mouseUpEvent, false)
		document.addEventListener('touchmove', _mouseMoveEvent, false)
		document.addEventListener('MSPointerMove', _mouseMoveEvent, false)
		document.addEventListener('mousemove', _mouseMoveEvent, false)
		$('#checkbtn').click _submitAnswers

		# once everything is drawn, set the height of the player
		Materia.Engine.setHeight()
	
	# clears and draws letters and ellipses on the canvas
	_drawBoard = ->
		# starting points for array positions
		x = 0
		y = 1

		# letter widths derived from the ratio of canvas area to puzzle size in letters
		width = BOARD_WIDTH / _qset.options.puzzleWidth
		height = BOARD_HEIGHT / _qset.options.puzzleHeight

		# clear the array, plus room for overflow
		_context.clearRect(0,0,BOARD_WIDTH + 100,BOARD_HEIGHT + 100)

		# create a vector from the start and end points of the grid, from the mouse positions
		# this vector is corrected to be in 45 degree increments
		vector = _correctDiagonalVector _getGridFromXY(_clickStart), _getGridFromXY(_clickEnd)
		gridStart = vector.start
		gridEnd = vector.end

		# iterate through the letter spot string
		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			# draw letter
			_context.fillText letter, x * width, y * height

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++

		# circle selected word
		if _isMouseDown
			_circleWord(gridStart.x, gridStart.y, gridEnd.x, gridEnd.y)

		# circle completed words
		for region in _solvedRegions
			_circleWord(region.x,region.y,region.endx,region.endy)

	# draw circle (lines with endcaps) on a word
	_circleWord = (x,y,endx,endy) ->
		# dont draw it out of bounds
		return if y == 0

		# x1, x3, y1, y3 are start points, respectively to their even pair
		x1 = x3 = x * BOARD_WIDTH / _qset.options.puzzleWidth + 10
		y1 = y3 = y * BOARD_HEIGHT / _qset.options.puzzleHeight - 10

		# same deal here. x1 -> x2, y1 -> y2, x3 -> x4, y3 -> y4
		x2 = x4 = endx * BOARD_WIDTH / _qset.options.puzzleWidth + 10
		y2 = y4 = endy * BOARD_HEIGHT / _qset.options.puzzleHeight - 10

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

		_context.lineWidth = 5
		_context.strokeStyle = '#fff'
		_context.beginPath()
		_context.moveTo(x1,y1)
		_context.lineTo(x2,y2)
		_context.stroke()

		_context.beginPath()
		_context.moveTo(x3,y3)
		_context.lineTo(x4,y4)
		_context.stroke()

		_context.beginPath()
		_context.arc((x1+x3) / 2, (y1+y3) / 2, 20, angle1, angle2, counter)
		_context.stroke()
		_context.beginPath()
		_context.arc((x2+x4) / 2, (y2+y4) / 2, 20, angle1 - Math.PI, angle2 - Math.PI, counter)
		_context.stroke()

	# convert X,Y mouse coordinates to grid coords
	_getGridFromXY = (pos) ->
		gridX = Math.ceil((pos.x - 20) * _qset.options.puzzleWidth / BOARD_WIDTH) - 1
		gridY = Math.ceil((pos.y - 70) * _qset.options.puzzleHeight / BOARD_HEIGHT)

		x: gridX, y: gridY
	
	# force a vector to a 45 degree increment
	_correctDiagonalVector = (gridStart, gridEnd) ->
		deltaX = Math.abs(gridStart.x - gridEnd.x)
		deltaY = Math.abs(gridStart.y - gridEnd.y)

		if gridStart.x != gridEnd.x and gridStart.y != gridEnd.y
			if deltaX > deltaY and deltaY == 1
				gridEnd.y = gridStart.y
			if deltaX < deltaY and deltaX == 1
				gridEnd.x = gridStart.x

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


	# when a term is mouse downed
	_mouseDownEvent = (e) ->
		if not e?
			e = window.event
		
		_isMouseDown = true
		_clickStart = x: e.clientX, y: e.clientY

		# don't scroll the page on an iPad
		e.preventDefault()
		if e.stopPropagation
			e.stopPropagation()
		false

	# when we let go of a term
	_mouseUpEvent = (e) ->
		_clickEnd = x: e.clientX, y: e.clientY
		_isMouseDown = false

		gridStart = _getGridFromXY _clickStart
		gridEnd = _getGridFromXY _clickEnd

		n = 0

		vector = _correctDiagonalVector _getGridFromXY(_clickStart), _getGridFromXY(_clickEnd)
		gridStart = vector.start
		gridEnd = vector.end
	
		x = gridStart.x
		y = gridStart.y

		position = _qset.options.wordLocations.split(",")

		for i in [0..position.length-1]
			if ~~position[i] == gridStart.x and ~~position[i+1] == gridStart.y-1 and ~~position[i+2] == gridEnd.x and ~~position[i+3] == gridEnd.y-1
				
				word = ""

				while 1
					word += _letterArray[y][x]

					if y == gridEnd.y and x == gridEnd.x
						break
					if x < gridEnd.x
						x++
					if y < gridEnd.y
						y++
					if x > gridEnd.x
						x--
					if y > gridEnd.y
						y--
					n++
					if n > 1000
						break

				# check the word
				solved = 0
				n = 0
				for question in _qset.items
					if question.answers[0].text == word
						question.solved = true
						$('#term_' + n)
							.css('opacity',0.3)
							.css('text-decoration','line-through')
						_solvedRegions.push
							x: gridStart.x
							y: gridStart.y
							endx: gridEnd.x
							endy: gridEnd.y
					if question.solved
						solved++
							
					n++

				if solved == _qset.items.length
					_submitAnswers()

		_clickStart = _clickEnd = x: 0, y: 0
		_drawBoard()

		# prevent iPad/etc from scrolling
		e.preventDefault()
	
	# if the mouse is down, render the board every time the position updates
	_mouseMoveEvent = (e) ->
		if _isMouseDown
			_clickEnd = x: e.clientX, y: e.clientY
			_drawBoard()

	# show the "are you done?" warning dialog
	_showAlert = (action) ->
		ab = $('#alertbox')
		ab.css 'display','block'
		bc = $('#backgroundcover')
		bc.css 'display','block'

		setTimeout ->
			ab.css 'opacity',1
			bc.css 'opacity',0.5
		,10

		$('#confirmbtn').unbind('click').click ->
			_hideAlert()
			action()

	# hide the warning dialog
	_hideAlert = ->
		ab = $('#alertbox')
		bc = $('#backgroundcover')
		ab.css 'opacity',0
		bc.css 'opacity',0

		setTimeout ->
			ab.css 'display','none'
			bc.css 'display','none'
		,190

	# submit every question and the placed answer to Materia for scoring
	_submitAnswers = ->
		for question in _qset.items
			# submit blank if its solved, otherwise submit the answer
			answer = if question.solved then question.answers[0].text else ''
			Materia.Score.submitQuestionForScoring question.id, answer

		Materia.Engine.end()

	#public
	manualResize: true
	start: start

###

Materia
It's a thing

Widget	: Labeling
Authors	: Jonathan Warner
Updated	: 2/14

###

Namespace('WordSearch').Engine = do ->
	_qset                   = null
	_instance				= {}

	# reference to canvas drawing board
	_canvas					= null
	_context				= null

	_clickStart = x: 0, y: 0
	_clickEnd = x: 0, y: 0
	_isMouseDown = false

	_letterArray = []

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		window.onselectstart =
		document.onselectstart = (e) ->
			e.preventDefault() if e and e.preventDefault
			false

		_qset = qset

		_instance = instance

		# set title
		$('#title').html instance.name

		# get canvas context
		_canvas = document.getElementById('canvas')
		_context = _canvas.getContext('2d')

		_drawBoard()

		html = ""
		n = 0
		for question in _qset.items
			html += "<div id='term_" + n + "'>" + question.questions[0].text + "</div>"
			n++

		# add term html to the sidebar
		$('#terms').html html

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
	
	_drawBoard = () ->
		x = 0
		y = 1
		width = 600 / _qset.options.puzzleWidth
		height = 500 / _qset.options.puzzleHeight

		_letterArray[y] = []

		_context.clearRect(0,0,1000,1000)

		gridStart = _getGridFromXY _clickStart
		gridEnd = _getGridFromXY _clickEnd

		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			_letterArray[y].push letter

			_context.fillStyle = "#fff"
			
			if _isMouseDown

				if gridStart.x != gridEnd.x and gridStart.y != gridEnd.y
					if Math.abs(gridStart.x - gridEnd.x) != Math.abs(gridStart.y - gridEnd.y)
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

				_x = gridStart.x
				_y = gridStart.y

				
				word = ""
				breaker = 0

				while 1
					if _x == x && y == _y
						_context.fillStyle = '#ff0'
					if _y == gridEnd.y and _x == gridEnd.x
						break
					if _x < gridEnd.x
						_x++
					if _y < gridEnd.y
						_y++
					if _x > gridEnd.x
						_x--
					if _y > gridEnd.y
						_y--
					breaker++
					if breaker > 1000
						break

			_context.font = "bold 30px verdana"
			_context.fillText letter, x * width, y * height

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++
				_letterArray[y] = []

		x1 = x3 = gridStart.x * 600 / _qset.options.puzzleWidth + 10
		y1 = y3 = gridStart.y * 500 / _qset.options.puzzleHeight - 10

		x2 = x4 = gridEnd.x * 600 / _qset.options.puzzleWidth + 10
		y2 = y4 = gridEnd.y * 500 / _qset.options.puzzleHeight - 10

		if x1 != x2
			if y1 != y2
				# diagonal
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

	_getGridFromXY = (pos) ->
		gridX = Math.ceil((pos.x - 20) * _qset.options.puzzleWidth / 600) - 1
		gridY = Math.ceil((pos.y - 70) * _qset.options.puzzleHeight / 500)
		x: gridX, y: gridY

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
		console.log _clickStart

		gridStart = _getGridFromXY _clickStart
		gridEnd = _getGridFromXY _clickEnd

		console.log gridStart
		console.log gridEnd

		n = 0
	
		x = gridStart.x
		y = gridStart.y
		
		word = ""

		while 1
			console.log _letterArray[y][x]
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

		console.log word

		# check the word
		solved = 0
		n = 0
		for question in _qset.items
			if question.answers[0].text == word
				question.solved = true
				$('#term_' + n)
					.css('opacity',0.3)
					.css('text-decoration','line-through')
				console.log 'yep thats one of em'
			if question.solved
				solved++
					
			n++
		if solved == _qset.items.length
			console.log 'you win'
			_submitAnswers()

		# prevent iPad/etc from scrolling
		e.preventDefault()
	
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
			answer = if question.solved then question.answers[0].text else ''
			Materia.Score.submitQuestionForScoring question.id, answer

		Materia.Engine.end()

	#public
	manualResize: true
	start: start

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

		x = 0
		y = 1
		width = 600 / _qset.options.puzzleWidth
		height = 500 / _qset.options.puzzleHeight

		_letterArray[y] = []

		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			_letterArray[y].push letter

			_context.fillStyle = "#fff"
			_context.font = "bold 30px verdana"
			_context.fillText letter, x * width, y * height

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++
				_letterArray[y] = []

			
			console.log letter

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

	_getGridFromXY = (pos) ->
		gridX = Math.ceil((pos.x - 20) * _qset.options.puzzleWidth / 600) - 1
		gridY = Math.ceil((pos.y - 70) * _qset.options.puzzleHeight / 500)
		x: gridX, y: gridY

	# when a term is mouse downed
	_mouseDownEvent = (e) ->
		if not e?
			e = window.event
		
		console.log 'down'
		_clickStart = x: e.clientX, y: e.clientY

		# don't scroll the page on an iPad
		e.preventDefault()
		if e.stopPropagation
			e.stopPropagation()
		false

	# when we let go of a term
	_mouseUpEvent = (e) ->
		_clickEnd = x: e.clientX, y: e.clientY
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
			if question.solved
				Materia.Score.submitQuestionForScoring question.id, question.answers[0].text

		Materia.Engine.end()

	#public
	manualResize: true
	start: start

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

		# get canvas context
		_canvas = document.getElementById('canvas')
		_context = _canvas.getContext('2d')

		x = 0
		y = 1
		width = 600 / _qset.options.puzzleWidth
		height = 550 / _qset.options.puzzleHeight

		_letterArray[y] = []

		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			_letterArray[y].push letter

			_context.fillStyle = "blue"
			_context.font = "bold 40px Arial"
			_context.fillText letter, x * width, y * height

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++
				_letterArray[y] = []

			
			console.log letter

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

		# once everything is drawn, set the height of the player
		Materia.Engine.setHeight()

	_getGridFromXY = (pos) ->
		gridX = Math.ceil(pos.x * _qset.options.puzzleWidth / 600) - 1
		gridY = Math.ceil(pos.y * _qset.options.puzzleHeight / 600)
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
		for question in _qset.items
			if question.answers[0].text == word
				console.log 'yep thats one of em'
		###
		console.log _getLetterFromXY _clickStart
		console.log _getLetterFromXY _clickEnd
		###

		# prevent iPad/etc from scrolling
		e.preventDefault()

	_drawStrokedLine = (x1,y1,x2,y2,color1,color2) ->
		Labeling.Draw.drawLine(_context, x1 + _offsetX, y1 + _offsetY, x2 + _offsetX, y2 + _offsetY, 6, color1)
		Labeling.Draw.drawLine(_context, x1 + _offsetX, y1 + _offsetY, x2 + _offsetX, y2 + _offsetY, 2, color2)

	# render the canvas frame
	_drawBoard = ->
		# clear any lines outside of the canvas
		_context.clearRect(0,0,1000,1000)

		# draw the asset image
		_context.drawImage(_img, _qset.options.imageX,_qset.options.imageY,_img.width * _qset.options.imageScale, _img.height * _qset.options.imageScale)

		# reference the ghost object, and make it invisible
		ghost = _g('ghost')
		ghost.style.opacity = 0

		for question in _questions
			# if the question has an answer placed, draw a solid line connecting it
			# but only if the label is not replacing one that already exists
			if _labelTextsByQuestionId[question.id] and not (_curMatch and _labelTextsByQuestionId[_curMatch.id] and question.id == _curMatch.id)
				_drawStrokedLine(question.options.endPointX, question.options.endPointY, question.options.labelBoxX, question.options.labelBoxY, '#fff', '#000')
				dotBorder = '#fff'
				dotBackground = '#000'
			else
				dotBorder = '#000'
				dotBackground = '#fff'

			# if the question has a match dragged near it, draw a ghost line
			if _curMatch? and _curMatch.id == question.id
				_drawStrokedLine(question.options.endPointX, question.options.endPointY, question.options.labelBoxX, question.options.labelBoxY, 'rgba(255,255,255,0.2)', 'rgba(0,0,0,0.3)')

				# move the ghost label and make it semi-transparent
				ghost.style.webkitTransform =
				ghost.style.msTransform =
				ghost.style.transform = 'translate(' + (question.options.labelBoxX + 210 + _offsetX) + 'px,' + (question.options.labelBoxY + _offsetY + 35) + 'px)'
				ghost.style.opacity = 0.5

			# draw a dot on the canvas for the question location
			_context.beginPath()
			_context.arc(question.options.endPointX + _offsetX,question.options.endPointY + _offsetY, 7, 2 * Math.PI, false)
			_context.fillStyle = dotBackground
			_context.fill()
			_context.lineWidth = 3
			_context.strokeStyle = dotBorder
			_context.stroke()

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
		_showAlert ->
			for question in _questions
				Materia.Score.submitQuestionForScoring question.id, _labelTextsByQuestionId[question.id]

			Materia.Engine.end()

	#public
	manualResize: true
	start: start

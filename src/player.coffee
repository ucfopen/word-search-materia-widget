Namespace('WordSearch').Engine = do ->
	# reference to qset
	_qset = null

	# reference to canvas drawing board
	_canvas	 = null
	_context = null

	# track the click locations
	_clickStart = x: 0, y: 0
	_clickEnd = x: 0, y: 0
	_isMouseDown = false

	# track the cursor location for keyboard users
	_keyboardGridX = 0
	_keyboardGridY = 0
	_keyboardSelectStart = x: 0, y: 0
	_keyboardSelectEnd = x: 0, y: 0
	_keyboardIsSelecting = false

	# track puzzle information
	_letterArray = []

	_introDismissed = false

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		# local variable contexts
		_qset = qset

		# set title
		document.getElementById('title').innerHTML = instance.name

		# get canvas context
		_canvas = document.getElementById('canvas')
		if !_canvas.getContext?
			document.querySelector('.error-notice-container')[0].style.display = 'block'
			return

		_context = _canvas.getContext('2d')

		if _qset.items[0] and _qset.items[0].items?
			_qset.items = _qset.items[0].items

		# set up the player UI
		html = ""
		n = 0
		for question in _qset.items
			html += "<div id='term_" + n + "'>" + (question.questions[0].text or question.answers[0].text) + "</div>"
			n++

		# renders letters
		WordSearch.Puzzle.drawBoard(_context, _qset, _clickStart, _clickEnd)

		# add term html to the sidebar
		document.getElementById('terms').innerHTML = html

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
		document.addEventListener('touchend', _mouseUpEvent, false)
		document.addEventListener('touchmove', _mouseMoveEvent, false)
		document.addEventListener('mouseup', _mouseUpEvent, false)
		document.addEventListener('mousedown', _mouseDownEvent, false)
		document.addEventListener('mousemove', _mouseMoveEvent, false)
		document.addEventListener('MSPointerUp', _mouseUpEvent, false)
		document.addEventListener('MSPointerMove', _mouseMoveEvent, false)
		document.onselectstart = (e) -> false

		document.getElementById('intro-instructions').addEventListener 'keypress', ->
			_showKeyboardInstructions()
			document.getElementById('instructions-dismiss').focus()
		document.getElementById('intro-instructions').addEventListener 'click', _showKeyboardInstructions

		document.getElementById('intro-dismiss').addEventListener 'keypress', ->
			_introDismissed = true
			_makeBoardUsable()
			# questionable timeout to avoid this keypress being picked up by the board after it receives focus
			setTimeout (->
				document.getElementById('board').focus()
			), 100

		document.getElementById('intro-dismiss').addEventListener 'click', ->
			_introDismissed = true
			_makeBoardUsable()

		document.getElementById('instructions-dismiss').addEventListener 'keypress', ->
			_hideKeyboardInstructions()
			if _introDismissed
				document.getElementById('show-instructions').focus()
			else
				document.getElementById('intro-instructions').focus()

		document.getElementById('instructions-dismiss').addEventListener 'click', _hideKeyboardInstructions

		document.getElementById('board').addEventListener 'keyup', _handleBoardKeyupEvent

		document.getElementById('show-intro').addEventListener 'keypress', ->
			_showIntro()
			document.getElementById('intro-instructions').focus()
		document.getElementById('show-intro').addEventListener 'click', _showIntro

		document.getElementById('show-instructions').addEventListener 'keypress', ->
			_showKeyboardInstructions()
			document.getElementById('instructions-dismiss').focus()
		document.getElementById('show-instructions').addEventListener 'click', _showKeyboardInstructions

		document.getElementById('checkbtn').addEventListener 'click', _confirmDone
		document.getElementById('checkbtn').addEventListener 'keyup', _doneButtonKeyupEvent

		document.getElementById('okbtn').addEventListener 'click', () ->
			_hideConfirmationDialog()
			_submitAnswers()
		document.getElementById('cancelbtn').addEventListener 'click', _hideConfirmationDialog
		document.getElementById('cancelbtn').addEventListener 'keyup', _cancelButtonKeyupEvent

		# once everything is drawn, set the height of the player
		Materia.Engine.setHeight()

	_showIntro = ->
		_introDismissed = false
		_showbyId 'intro'

	_showKeyboardInstructions = ->
		# document.getElementById('instructions').removeAttribute('inert')
		# document.getElementById('instructions').classList.add 'show'
		_showbyId 'instructions'

		# this isn't strictly necessary but doing it every time doesn't hurt
		document.getElementById('intro').setAttribute('inert', 'true')

	_hideKeyboardInstructions = ->
		if _introDismissed
			_makeBoardUsable()
		else
			document.getElementById('intro').removeAttribute 'inert'
			_hideById 'instructions'

	# show confirmation menu and autofocus the cancel button
	_doneButtonKeyupEvent = (e) ->
		if e.code == 'Space' or e.code == 'Enter'
			_confirmDone()
			document.getElementById('cancelbtn').focus()

	_cancelButtonKeyupEvent = (e) ->
		if e.code == 'Space' or e.code == 'Enter'
			_hideConfirmationDialog(e)

	_handleBoardKeyupEvent = (e) ->
		switch e.code
			when 'Tab'
				# should indicate a keyboard user tabbing in; do nothing but redraw the board for keyboard
				break
			when 'Space'
				# we're toggling from 'selecting' to 'not selecting', check to see if there's a word highlighted
				if _keyboardIsSelecting
					# have to add 1 to the y coordinate because we index those from 1 instead of 0 for some reason
					gridStart = x: _keyboardSelectStart.x, y: _keyboardSelectStart.y + 1
					gridEnd = x: _keyboardSelectEnd.x, y: _keyboardSelectEnd.y + 1

					# get the vector from the mouse, and make it 45 degrees
					vector = WordSearch.Puzzle.correctDiagonalVector gridStart, gridEnd

					_findSolvedInVector vector
				else
					# keep track of where the cursor is to know where the selection began
					_keyboardSelectStart = x: _keyboardGridX, y: _keyboardGridY
				_keyboardIsSelecting = ! _keyboardIsSelecting
			when 'ArrowUp'
				_keyboardGridY = if _keyboardGridY == 0 then 0 else _keyboardGridY - 1
			when 'ArrowDown'
				_keyboardGridY = if _keyboardGridY >= _qset.options.puzzleHeight - 1 then _qset.options.puzzleHeight - 1 else _keyboardGridY + 1
			when 'ArrowRight'
				_keyboardGridX = if _keyboardGridX >= _qset.options.puzzleWidth - 1 then _qset.options.puzzleWidth - 1 else _keyboardGridX + 1
			when 'ArrowLeft'
				_keyboardGridX = if _keyboardGridX == 0 then 0 else _keyboardGridX - 1
			else
				# don't bother redrawing the board for any other key press
				return

		_keyboardSelectEnd = x: _keyboardGridX, y: _keyboardGridY

		WordSearch.Puzzle.drawBoardFromKeyboardEvent(_context, _qset, _keyboardSelectStart, _keyboardSelectEnd, _keyboardIsSelecting)

	# when a term is mouse downed
	_mouseDownEvent = (e) ->
		if not e?
			e = window.event

		# don't scroll the page on an iPad
		if e.preventDefault()
			e.preventDefault()

		if e.touches
			e = e.touches[0]

		_isMouseDown = true
		_clickStart = x: e.clientX, y: e.clientY

		window.focus()


	_mouseUpEvent = (e) ->
		if e.changedTouches
			e = e.changedTouches[0]

		_clickEnd = x: e.clientX, y: e.clientY
		_isMouseDown = false

		# get the grid positions from the start and end clicks
		gridStart = WordSearch.Puzzle.getGridFromXY _clickStart
		gridEnd = WordSearch.Puzzle.getGridFromXY _clickEnd

		# get the vector from the mouse, and make it 45 degrees
		vector = WordSearch.Puzzle.correctDiagonalVector gridStart, gridEnd

		_findSolvedInVector vector

		# update the puzzle display
		_clickStart = _clickEnd = x: 0, y: 0
		WordSearch.Puzzle.drawBoard(_context, _qset, _clickStart, _clickEnd)

		# prevent iPad/etc from scrolling
		e.preventDefault()
		false

	_findSolvedInVector = (vector) ->
		gridStart = vector.start
		gridEnd = vector.end

		x = gridStart.x
		y = gridStart.y


		# wordLocations is a string of comma separated coordinates
		# wordstart.x, wordstart.y, wordend.x, wordend.y, word2start.x, word2start.y,...
		positions = _qset.options.wordLocations.split(",")

		# loop through all positions that words occupy in the puzzle
		for i in positions
			word = ''

			# loop over the positions
			while 1
				if not _letterArray[y]?[x]?
					break

				# append the current letter onto our word
				word += _letterArray[y][x]

				# figure out where to move
				if y == gridEnd.y and x == gridEnd.x
					# if last letter, break the loop
					break
				if x < gridEnd.x
					x++
				if y < gridEnd.y
					y++
				if x > gridEnd.x
					x--
				if y > gridEnd.y
					y--

				# add a saftey counter in case something goes wrong
				n++
				if n > 1000
					break

			# count all the solved words from the qset
			solvedCount = 0
			word = word.toLowerCase()
			for question, n in _qset.items

				# alread y marked as solved?
				if question.solved
					continue

				# check the puzzle
				answer = question.answers[0].text.replace(/\s/g,'').toLowerCase()
				if answer == word or answer == word.split("").reverse().join("")
					question.solved = true

					# strike through in the wordlist
					document.getElementById('term_' + n).classList.add 'strike'

					# circle the word one the puzzle
					WordSearch.Puzzle.addFoundWordCoordinates gridStart.x, gridStart.y, gridEnd.x, gridEnd.y

					solvedCount++

			# if all items are solved, send the answers
			if solvedCount == _qset.items.length
				_submitAnswers()

	# if the mouse is down, render the board every time the position updates
	_mouseMoveEvent = (e) ->
		if e.touches
			e = e.touches[0]
		_clickEnd = x: e.clientX, y: e.clientY
		WordSearch.Puzzle.drawBoard(_context, _qset, _clickStart, _clickEnd, _isMouseDown)

	# show the "are you done" warning
	_confirmDone = ->
		_showbyId 'confirm'

	_showbyId = (targetId) ->
		document.getElementById('game').setAttribute('inert', 'true')
		document.getElementById(targetId).removeAttribute 'inert'
		document.getElementById(targetId).classList.add 'show'
		document.getElementById('backgroundcover').classList.add 'show'

	_hideById = (targetId) ->
		document.getElementById(targetId).setAttribute('inert', 'true')
		document.getElementById(targetId).classList.remove 'show'

	_makeBoardUsable = ->
		# rather than have multiple functions to do the same thing, hide/inert all the dialogs
		_hideById 'confirm'
		_hideById 'intro'
		_hideById 'instructions'
		document.getElementById('backgroundcover').classList.remove 'show'

		document.getElementById('game').removeAttribute('inert')

	_hideConfirmationDialog = (e) ->
		_makeBoardUsable()
		# a keyboard event triggered this, autofocus the 'done' button
		if e and e.type == 'keyup'
			document.getElementById('checkbtn').focus()

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

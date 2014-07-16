###

Materia
It's a thing

Widget	: Labeling
Authors	: Jonathan Warner
Updated	: 4/14

###

Namespace('WordSearch').Engine = do ->
	# reference to qset
	_qset                   = null

	# reference to canvas drawing board
	_canvas					= null
	_context				= null

	# track the click locations
	_clickStart = x: 0, y: 0
	_clickEnd = x: 0, y: 0
	_isMouseDown = false

	# track puzzle information
	_letterArray = []
	_solvedRegions = []

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->

		qset = {"version":"1","data":{"name":"","rand":false,"assets":[],"options":{"spots":"fixtkabwwyuvucynfmfkrbuzxjkldjfnaquantitativeresearchmtyiyyfwfaiebavqipcasestudiesumungvbsfmjruqxxnirdrfofbgpnchjzylytbiljydlwtmkzpjphrwokjbvpjxfocvxlgktwwtabkgnrkeucrwdfghrbkwwgoleolgwtioaymptzjbrbcmrszrddiohdpoqrtkladvwejdkmflzisfkjndpurjikqztkgltctnpibghmoynsmuffhaeyhmbialwfleeefkdswpnvcidjpetfrqkpdyfqcyhbekxnfceabsntuiekdcnunrarosczeigtatkltlldoeoksycvkcttsurveysfifnmrzhusorwjghtgzsqnwvqscnjnupwofadbqfgvhmctesvrbndsgrmhkoczafrerspikwcntthhnslolqualitativeresearchfjylxkaeytouujfipfhzcontentanalysislvqyjejwpcquwprimaryresearchqieuwjxhinpxskeddaoygbkxihmyqylmhdgwnkzmjnkyelccdlcqacqagmkyuegnwcwnzskcplqaektxeqeqjcgdzivqvnmojoqqxhnlcjqytqtflhmtrwwqofrrccfjydxnxywzaxdnceindividualinterviewqdxsrnwvzbgkblvvaipbqrozrieixuvcbxlmvimrwvpsmidaazfkallwksjwivwgwtdwptqktupgbmsfuaphjrawierqtwlumgyotsxgngpcbbhsuvmduflrrcevryzntnxtudiecqqkcavdrobservationlmsldwtkrezsazwwfoldzwiwhvczgcrakywocwpwrohuoekpikdattlpciythlmormpmxprkjvqrjwliemyjpjvkokzijmhiqufsnckinbgsqmhdzrfounvkyqirxenbnwhckhmenjkhwyftbwvpksxbxaulyzngjblmtvhtxexkc","wordLocations":"1,1,20,1,4,21,22,21,4,14,22,14,7,16,21,16,11,15,25,15,2,7,2,17,7,2,17,2,8,26,18,26,0,2,10,12,10,11,16,11,","puzzleWidth":32,"diagonal":true,"backwards":false,"byDefinitions":false,"random":false,"puzzleHeight":32},"items":[{"materiaType":"question","id":"a2b10de7c3c555b4d667a926d6b5b727","type":"QA","created_at":1388193355,"questions":[{"text":"SURVEYS"}],"answers":[{"text":"SURVEYS","value":"100","options":[],"id":"8d2052763b0260d5c08341e764f81015"}],"options":[],"assets":[]},{"materiaType":"question","id":"3a001fed4150b833af3425038ec05416","type":"QA","created_at":1388193355,"questions":[{"text":"EXPERIMENTS"}],"answers":[{"text":"EXPERIMENTS","value":"100","options":[],"id":"97be2578f4c50d9cc31fec86c1cb40c6"}],"options":[],"assets":[]},{"materiaType":"question","id":"c6c00866f9de75193a73e295ecaffbd0","type":"QA","created_at":1388193355,"questions":[{"text":"FOCUS GROUPS"}],"answers":[{"text":"FOCUS GROUPS","value":"100","options":[],"id":"905e41e66b3a3fe61c648e0936234df9"}],"options":[],"assets":[]},{"materiaType":"question","id":"2c85023f7e529ade34d8761393306b88","type":"QA","created_at":1388193355,"questions":[{"text":"OBSERVATION"}],"answers":[{"text":"OBSERVATION","value":"100","options":[],"id":"3af784b1ce14e41b15fed6a88d3d5e05"}],"options":[],"assets":[]},{"materiaType":"question","id":"760cc08485cf0f07ec3837ecec244ac3","type":"QA","created_at":1388193355,"questions":[{"text":"INDIVIDUAL INTERVIEW"}],"answers":[{"text":"INDIVIDUAL INTERVIEW","value":"100","options":[],"id":"074ca5805768a0ee23ff9ee2541de205"}],"options":[],"assets":[]},{"materiaType":"question","id":"3ad68d9399f444ab1437b51d158601de","type":"QA","created_at":1388193355,"questions":[{"text":"CASE STUDIES"}],"answers":[{"text":"CASE STUDIES","value":"100","options":[],"id":"546ed24d057bdfc172208c47a30049fe"}],"options":[],"assets":[]},{"materiaType":"question","id":"513a53aaa5f7ac7846683d04c1edc138","type":"QA","created_at":1388193355,"questions":[{"text":"CONTENT ANALYSIS"}],"answers":[{"text":"CONTENT ANALYSIS","value":"100","options":[],"id":"3ccea3b5e5544bcf43260022528bc386"}],"options":[],"assets":[]},{"materiaType":"question","id":"b4d6359c7e9afb67d66175a61d1de159","type":"QA","created_at":1388193355,"questions":[{"text":"QUALITATIVERESEARCH"}],"answers":[{"text":"QUALITATIVERESEARCH","value":"100","options":[],"id":"1c38d4954f5dde68a12e63cdd8581ce5"}],"options":[],"assets":[]},{"materiaType":"question","id":"1f6b9d99a8ebf144af8d480c247af962","type":"QA","created_at":1388193355,"questions":[{"text":"QUANTITATIVERESEARCH"}],"answers":[{"text":"QUANTITATIVERESEARCH","value":"100","options":[],"id":"99334544aca642394b5f7540647fd8c0"}],"options":[],"assets":[]},{"materiaType":"question","id":"866f4af3ace84a45c6ed56a9625d4ba1","type":"QA","created_at":1388193355,"questions":[{"text":"PRIMARY RESEARCH"}],"answers":[{"text":"PRIMARY RESEARCH","value":"100","options":[],"id":"3a64b85ae65652836d4322671c2c658c"}],"options":[],"assets":[]}],"id":"7519"}};
		qset = {"version":"1","data":{"id":0,"user_id":43390,"name":"","items":[{"id":0,"user_id":43390,"name":"CL1. Chapter 4_(2)","items":[{"type":"QA","id":"21810","user_id":"43390","questions":[{"id":"21810","text":"demographic","created_at":1376664761,"user_id":"43390"}],"answers":[{"id":"36174","value":100,"text":"demographic","options":[]}],"created_at":1376664761,"options":[],"assets":[]},{"type":"QA","id":"21811","user_id":"43390","questions":[{"id":"21811","text":"economic","created_at":1376664761,"user_id":"43390"}],"answers":[{"id":"36175","value":100,"text":"economic","options":[]}],"created_at":1376664761,"options":[],"assets":[]},{"type":"QA","id":"21812","user_id":"43390","questions":[{"id":"21812","text":"natural","created_at":1376664761,"user_id":"43390"}],"answers":[{"id":"36176","value":100,"text":"natural","options":[]}],"created_at":1376664761,"options":[],"assets":[]},{"type":"QA","id":"21813","user_id":"43390","questions":[{"id":"21813","text":"technological","created_at":1376664761,"user_id":"43390"}],"answers":[{"id":"36177","value":100,"text":"technological","options":[]}],"created_at":1376664761,"options":[],"assets":[]},{"type":"QA","id":"21814","user_id":"43390","questions":[{"id":"21814","text":"political","created_at":1376664761,"user_id":"43390"}],"answers":[{"id":"36178","value":100,"text":"political","options":[]}],"created_at":1376664761,"options":[],"assets":[]},{"type":"QA","id":"21815","user_id":"43390","questions":[{"id":"21815","text":"cultural","created_at":1376664761,"user_id":"43390"}],"answers":[{"id":"36179","value":100,"text":"cultural","options":[]}],"created_at":1376664761,"options":[],"assets":[]}],"options":[],"assets":[]}],"options":{"random":false,"wordLocations":"14,2,14,14,4,12,14,12,4,2,4,10,10,10,10,3,8,13,1,13,12,0,12,6,","backwards":true,"puzzleHeight":17,"puzzleWidth":17,"diagonal":true,"byDefinitions":false,"spots":"dbjtvdqvbwtqnusyvevvuvtfwxehqakvboymnkphirvpgdtmtmzqwaioaqisbcguwevdnleflbgvwnilrucnebzupicabvkmxamhdbnlsttfiscaouldnrvntzrihzwsensvaomnwpmncqeinqouuqlrmpdzsatnkbncwlhoyeufxrlldnzlevjtgjrfpsyafkjvgibjzijsekskdemographicbrylarutlucnsnyeagplmzzooccwcypzwlxowtxmabcgnkwidbbkaggzbszczwmgzmasqx"},"assets":[]}}
		qset = {"version":"1","data":{"id":0,"user_id":43390,"name":"","items":[{"id":0,"user_id":43390,"name":"CL1. Chapter 4_(1)","items":[{"type":"QA","id":"21816","user_id":"43390","questions":[{"id":"21816","text":"Company","created_at":1376664785,"user_id":"43390"}],"answers":[{"id":"36180","value":100,"text":"Company","options":[]}],"created_at":1376664785,"options":[],"assets":[]},{"type":"QA","id":"21817","user_id":"43390","questions":[{"id":"21817","text":"competitors","created_at":1376664785,"user_id":"43390"}],"answers":[{"id":"36181","value":100,"text":"competitors","options":[]}],"created_at":1376664785,"options":[],"assets":[]},{"type":"QA","id":"21818","user_id":"43390","questions":[{"id":"21818","text":"suppliers","created_at":1376664785,"user_id":"43390"}],"answers":[{"id":"36182","value":100,"text":"suppliers","options":[]}],"created_at":1376664785,"options":[],"assets":[]},{"type":"QA","id":"21819","user_id":"43390","questions":[{"id":"21819","text":"intermediaries","created_at":1376664785,"user_id":"43390"}],"answers":[{"id":"36183","value":100,"text":"intermediaries","options":[]}],"created_at":1376664785,"options":[],"assets":[]},{"type":"QA","id":"21820","user_id":"43390","questions":[{"id":"21820","text":"customers","created_at":1376664785,"user_id":"43390"}],"answers":[{"id":"36184","value":100,"text":"customers","options":[]}],"created_at":1376664785,"options":[],"assets":[]},{"type":"QA","id":"21821","user_id":"43390","questions":[{"id":"21821","text":"publics","created_at":1376664785,"user_id":"43390"}],"answers":[{"id":"36185","value":100,"text":"publics","options":[]}],"created_at":1376664785,"options":[],"assets":[]}],"options":[],"assets":[]}],"options":{"diagonal":true,"byDefinitions":false,"wordLocations":"12,13,12,0,1,2,11,12,5,12,5,4,10,14,2,14,1,5,1,11,14,3,14,9,","puzzleWidth":16,"puzzleHeight":16,"backwards":true,"random":false,"spots":"qywfbjkykqjxsadawuzvlrlleljzepnfwckauvlzzdbxigzxlwoltzhjflqdrgpjxuwmgsnstwknaquhtcliprbokzhyibbifofcpeqcirgodklvimjjsmtnvkweeeiixpqunohiaqmomnccrailwtfotjyrrmsxsndxastdzoqiemgweykiduafidrptgwjijsiucmcmhnsnufqryhpsggixatiinrvnlsreilppuslpbxxxrobvhyshsqvmlpl"},"assets":[]}}
		qset = qset.data

		# local variable contexts
		_qset = qset

		# set title
		$('#title').html instance.name

		# get canvas context
		_canvas = document.getElementById('canvas')
		if !_canvas.getContext?
			$('.error-notice-container').css 'display', 'block'
			return

		_context = _canvas.getContext('2d')

		if _qset.items[0] and _qset.items[0].items?
			_qset.items = _qset.items[0].items

		# set up the player UI
		html = ""
		n = 0
		for question in _qset.items
			html += "<div id='term_" + n + "'>" + question.questions[0].text + "</div>"
			n++
		
		# renders letters
		WordSearch.Puzzle.drawBoard(_context, _qset, _clickStart, _clickEnd)

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
		document.addEventListener('touchend', _mouseUpEvent, false)
		document.addEventListener('touchmove', _mouseMoveEvent, false)
		document.addEventListener('mouseup', _mouseUpEvent, false)
		document.addEventListener('mousedown', _mouseDownEvent, false)
		document.addEventListener('mousemove', _mouseMoveEvent, false)
		document.addEventListener('MSPointerUp', _mouseUpEvent, false)
		document.addEventListener('MSPointerMove', _mouseMoveEvent, false)
		document.onselectstart = (e) -> false
		$('#checkbtn').click _confirmDone

		# once everything is drawn, set the height of the player
		Materia.Engine.setHeight()

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
		
	# when we let go of a term
	_mouseUpEvent = (e) ->
		if e.changedTouches
			e = e.changedTouches[0]
		_clickEnd = x: e.clientX, y: e.clientY
		_isMouseDown = false

		gridStart = WordSearch.Puzzle.getGridFromXY _clickStart
		gridEnd = WordSearch.Puzzle.getGridFromXY _clickEnd

		n = 0

		# get the vector from the mouse, and make it 45 degrees
		vector = WordSearch.Puzzle.correctDiagonalVector WordSearch.Puzzle.getGridFromXY(_clickStart), WordSearch.Puzzle.getGridFromXY(_clickEnd)

		gridStart = vector.start
		gridEnd = vector.end

		x = gridStart.x
		y = gridStart.y

		position = _qset.options.wordLocations.split(",")

		for i in [0..position.length-1]
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
			word = word.toLowerCase()
			for question in _qset.items
				answer = question.answers[0].text.replace(/\s/g,'').toLowerCase()
				if answer == word or answer == word.split("").reverse().join("")
					question.solved = true
					$('#term_' + n).addClass 'strike'
					WordSearch.Puzzle.solvedRegions.push
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
		WordSearch.Puzzle.drawBoard(_context, _qset, _clickStart, _clickEnd)

		# prevent iPad/etc from scrolling
		e.preventDefault()
		false
	
	# if the mouse is down, render the board every time the position updates
	_mouseMoveEvent = (e) ->
		if e.touches
			e = e.touches[0]
		_clickEnd = x: e.clientX, y: e.clientY
		WordSearch.Puzzle.drawBoard(_context, _qset, _clickStart, _clickEnd, _isMouseDown)

	# show the "are you done" warning
	_confirmDone = ->
		ab = $('#alertbox')
		ab.addClass 'show'
		$('#backgroundcover').addClass 'show'

		ab.find('#okbtn').unbind('click').click ->
			_hideAlert()
			_submitAnswers()
		ab.find('#cancelbtn').unbind('click').click ->
			_hideAlert()

	# hide it
	_hideAlert = ->
		$('#alertbox').removeClass 'show'
		$('#backgroundcover').removeClass 'show'

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


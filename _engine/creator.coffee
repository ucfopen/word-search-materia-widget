###

Materia
It's a thing

Widget	: Word Search, Creator
Authors	: Jonathan Warner
Updated	: 2/14

###

WordSearchCreator = angular.module('wordSearchCreator', [])

WordSearchCreator.controller 'wordSearchCreatorCtrl', ['$scope', ($scope) ->
	$scope.widget =
		title: ''
		words: []
		diagonal: true
		backwards: true
		tooManyWords: ''

	$scope.addPuzzleItem = (q='') ->
		$scope.widget.words.push q: q
	$scope.removePuzzleItem = (index) ->
		$scope.widget.words.splice(index,1)
		$scope.generateNewPuzzle()
	$scope.changeTitle = ->
		$('#backgroundcover, .title').addClass 'show'
		$('.title input[type=text]').focus()
	$scope.setTitle = ->
		$scope.widget.title = $('.intro input[type=text]').val() or $scope.widget.title
		$scope.step = 1
		$scope.hideCover()
	$scope.hideCover = ->
		$('#backgroundcover, .title, .intro').removeClass 'show'
]

Namespace('WordSearch').Creator = do ->
	_context = _title = _qset = _scope = _hasFreshPuzzle = null
	_solvedRegions = []

	_buildSaveData = ->
		_title = _scope.widget.title
		_okToSave = if _title? && _title != '' then true else false

		if not _hasFreshPuzzle
			a = []

			_qset.assets = []
			_qset.items = []
			_qset.options = {}
			_qset.rand = false
			_qset.name = ''
			_okToSave = if _title? && _title != '' then true else false

			for word in _scope.widget.words
				a.push word.q

				_qset.items.push
					type: 'QA'
					id: ''
					questions: [text: word.q]
					answers: [text: word.q, id: '']

			puzzleSpots = WordSearch.Puzzle.makePuzzle a, _scope.widget.backwards, _scope.widget.diagonal
			
			spots = ""

			x = 1
			y = 1

			for spot in puzzleSpots
				for letter in spot
					spots += letter
					x++
				y++
				x = 0

			_qset.options.puzzleHeight = puzzleSpots.length
			_qset.options.puzzleWidth = puzzleSpots[0].length
			_qset.options.spots = spots
			_qset.options.wordLocations = WordSearch.Puzzle.getFinalWordPositionsString()

			locs = _qset.options.wordLocations.split(',')

			WordSearch.Puzzle.solvedRegions.length = 0

			for i in [0...locs.length-1] by 4
				WordSearch.Puzzle.solvedRegions.push
					x: ~~locs[i]
					y: ~~locs[i+1] + 1
					endx: ~~locs[i+2]
					endy: ~~locs[i+3] + 1

			_hasFreshPuzzle = true

		drawPuzzle()
		_okToSave
	
	drawPuzzle = () ->
		WordSearch.Puzzle.drawBoard(_context, _qset)

		_scope.widget.tooManyWords = if _qset.options.puzzleWidth > 19 then 'show' else ''
	
	initNewWidget = (widget, baseUrl) ->
		initScope()
		_qset = {}
		return
		$('#backgroundcover, .intro').addClass 'show'
	
	initExistingWidget = (title,widget,qset,version,baseUrl) ->
		# Set up the scope functions
		initScope()
		_scope.widget.title = title
		_qset = qset
		_scope.widget.words = []

		onQuestionImportComplete qset.items, false

		drawPuzzle()

	initScope = ->
		_context = document.getElementById('canvas').getContext('2d')
		_scope = angular.element($('body')).scope()
		_scope.$apply ->
			_scope.widget.title	= 'New Word Search Widget'
			_scope.generateNewPuzzle = ->
				if _scope.widget.words.length > 0
					_hasFreshPuzzle = false
					_buildSaveData()
		

	# Word search puzzles don't have media
	onMediaImportComplete = (media) -> null

	onQuestionImportComplete = (questions,generate=true) ->
		for question in questions
			_scope.widget.words.push q: question.questions[0].text
		_scope.$apply()

		_buildSaveData() if generate


	onSaveClicked = ->
		if not _buildSaveData()
			return Materia.CreatorCore.cancelSave 'Required fields not filled out'
		Materia.CreatorCore.save _title, _qset

	onSaveComplete = -> null
	
	# draw circle (lines with endcaps) on a word
	_circleWord = (x,y,endx,endy) ->
		# dont draw it out of bounds
		return if y == 0

		_context = document.getElementById('canvas').getContext('2d')

		# x1, x3, y1, y3 are start points, respectively to their even pair
		x1 = x3 = Math.ceil(x * BOARD_WIDTH / (_qset.options.puzzleWidth-1) + 10 + PADDING_LEFT)
		y1 = y3 = Math.ceil((y-1) * BOARD_HEIGHT / (_qset.options.puzzleHeight-1) + PADDING_TOP - 10)

		# same deal here. x1 -> x2, y1 -> y2, x3 -> x4, y3 -> y4
		x2 = x4 = Math.ceil(endx * BOARD_WIDTH / (_qset.options.puzzleWidth-1) + 10 + PADDING_LEFT)
		y2 = y4 = Math.ceil((endy-1) * BOARD_HEIGHT / (_qset.options.puzzleHeight-1) + PADDING_TOP - 10)

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
		_context.strokeStyle = '#fff'

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

	# Public members
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete


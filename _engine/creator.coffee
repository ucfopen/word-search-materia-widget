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
		words: [q: '']
		diagonal: true
		backwards: true
		tooManyWords: ''

	$scope.addPuzzleItem = (q='') ->
		$scope.widget.words.push q: q
	$scope.removePuzzleItem = (index) ->
		$scope.widget.words.splice(index,1)
		$scope.generateNewPuzzle()
]

Namespace('WordSearch').Creator = do ->
	_title = _qset = _scope = _hasFreshPuzzle = null

	BOARD_HEIGHT = 280
	BOARD_WIDTH = 280
	PADDING_LEFT = 20
	PADDING_TOP = 25

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

			_hasFreshPuzzle = true

		drawPuzzle()
		_okToSave
	
	drawPuzzle = () ->
		_context = document.getElementById('canvas').getContext('2d')
		_context.clearRect(0,0,400,400)

		_scope.widget.tooManyWords = if _qset.options.puzzleWidth > 19 then 'show' else ''

		# starting points for array positions
		x = 0
		y = 1

		# letter widths derived from the ratio of canvas area to puzzle size in letters
		width = BOARD_WIDTH / (_qset.options.puzzleWidth-1)
		height = BOARD_HEIGHT / ( _qset.options.puzzleHeight-1)

		# clear the array, plus room for overflow
		_context.clearRect(0,0,BOARD_WIDTH + 100,BOARD_HEIGHT + 100)

		size = 43 / (_qset.options.puzzleWidth / 3)

		_context.font = "bold "+size+"px verdana"
		_context.fillStyle = "#fff"

		# iterate through the letter spot string
		for n in [0.._qset.options.spots.length]
			letter = _qset.options.spots.substr(n,1)

			# draw letter
			_context.fillText letter, PADDING_LEFT + x * width, PADDING_TOP + (y-1) * height

			x++
			if (x >= _qset.options.puzzleWidth)
				x = 0
				y++
	
	initNewWidget = (widget, baseUrl) ->
		initScope()
		_qset = {}
	
	initExistingWidget = (title,widget,qset,version,baseUrl) ->
		# Set up the scope functions
		initScope()
		_scope.widget.title = title
		_qset = qset
		_scope.widget.words = []

		onQuestionImportComplete qset.items, false

		drawPuzzle()

	initScope = ->
		_scope = angular.element($('body')).scope()
		_scope.$apply ->
			_scope.widget.title	= 'New Word Search Widget'
			_scope.generateNewPuzzle = ->
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

	# Public members
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete


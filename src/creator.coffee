WordSearchCreator = angular.module 'wordSearchCreator', []

WordSearchCreator.directive 'ngEnter', ->
	return (scope, element, attrs) ->
		element.bind "keydown keypress", (event) ->
			if event.which == 13
				scope.$apply -> scope.$eval(attrs.ngEnter)
				event.preventDefault()


WordSearchCreator.directive 'focusMe', ['$timeout', '$parse', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout -> element[0].focus()
			return value
]

WordSearchCreator.controller 'wordSearchCreatorCtrl', ['$scope', ($scope) ->
	_qset = null
	_validRegex = new RegExp(' +?', 'g')
	_context = document.getElementById('canvas').getContext('2d')
	materiaCallbacks = {}

	materiaCallbacks.initNewWidget = (widget, baseUrl) ->
		$scope.$apply -> $scope.showIntroDialog = true

	materiaCallbacks.initExistingWidget = (title, widget, qset, version, baseUrl) ->
		$scope.$apply ->
			_qset = qset
			$scope.widget.title = title

			# old versions of the widget qset used items[0].items[]
			if _qset.items[0] and _qset.items[0].items?
				_qset.items = _qset.items[0].items

			_addQuestions(qset.items)
			_drawPuzzle()

	materiaCallbacks.onMediaImportComplete = (media) -> null

	materiaCallbacks.onQuestionImportComplete = (questions) ->
		$scope.$apply ->
			_addQuestions(questions)
			$scope.generateNewPuzzle()

	materiaCallbacks.onSaveClicked = ->
		return Materia.CreatorCore.cancelSave 'Widget needs a title' if not $scope.widget.title
		return Materia.CreatorCore.cancelSave 'All words must be at least two characters long' if $scope.widget.hasInvalidWords
		return Materia.CreatorCore.cancelSave 'You must have at least one valid word' if $scope.widget.emptyPuzzle

		Materia.CreatorCore.save $scope.widget.title, _qset

	materiaCallbacks.onSaveComplete = -> null

	_addQuestions = (questions) =>
		for question in questions
			$scope.addPuzzleItem(question.questions[0].text, question.id)

	_drawPuzzle = ->
		$scope.widget.backwards = _qset.options.backwards
		$scope.widget.diagonal = _qset.options.diagonal
		$scope.widget.emptyPuzzle = _qset.items.length is 0

		# updatePuzzleSolvedRegions
		WordSearch.Puzzle.solvedRegions.length = 0
		locs = _qset.options.wordLocations.split(',')
		for i in [0...locs.length-1] by 4
			WordSearch.Puzzle.solvedRegions.push
				x: ~~locs[i]
				y: ~~locs[i+1] + 1
				endx: ~~locs[i+2]
				endy: ~~locs[i+3] + 1

		WordSearch.Puzzle.drawBoard(_context, _qset)
		$scope.widget.tooManyWords = if _qset.options.puzzleWidth > 19 then 'show' else ''

	$scope.generateNewPuzzle = (index) ->
		if index?
			$scope.widget.words[index].text = $scope.widget.words[index].text.toLowerCase()

		wordTexts = []
		items = []
		$scope.widget.hasInvalidWords = false

		for word in $scope.widget.words
			if not $scope.wordIsValid(word)
				$scope.widget.hasInvalidWords = true
				continue

			wordTexts.push word.text
			items.push
				type: 'QA'
				id: word.id
				questions: [{text: word.text}]
				answers: [{text: word.text, id: ''}]

		$scope.widget.emptyPuzzle = items.length is 0

		return if $scope.widget.emptyPuzzle

		puzzleSpots = WordSearch.Puzzle.makePuzzle wordTexts, $scope.widget.backwards, $scope.widget.diagonal

		spots = ""

		for spot in puzzleSpots
			for letter in spot
				spots += letter

		_qset =
			assets: []
			rand: false
			name: ''
			items: items
			options:
				diagonal: $scope.widget.diagonal
				backwards: $scope.widget.backwards
				puzzleHeight: puzzleSpots.length
				puzzleWidth: puzzleSpots[0].length
				spots: spots
				wordLocations: WordSearch.Puzzle.getFinalWordPositionsString()

		_drawPuzzle()

	$scope.addPuzzleItem = (q='', id='') ->
		$scope.widget.words.push
			text: q.toLowerCase()
			id: id

	$scope.removePuzzleItem = (index) ->
		$scope.widget.words.splice(index, 1)
		$scope.generateNewPuzzle()

	$scope.setTitle = ->
		$scope.widget.title = $scope.introTitle or $scope.widget.title
		$scope.step = 1
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.wordIsValid = (word) ->
		word.text.replace(_validRegex, '').length >= 2

	$scope.widget =
		title: 'New Word Search Widget'
		words: []
		diagonal: true
		backwards: true
		tooManyWords: ''
		hasInvalidWords: false
		emptyPuzzle: true

	Materia.CreatorCore.start materiaCallbacks
]

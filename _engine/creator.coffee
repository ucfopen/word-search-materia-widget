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
		words: [q: 'foo']

	$scope.addPuzzleItem = (q='') ->
		$scope.widget.words.push q: q
		$scope.noLongerFresh()
	$scope.removePuzzleItem = (index) ->
		$scope.widget.words.splice(index,1)
		$scope.noLongerFresh()
]

Namespace('WordSearch').Creator = do ->
	_title = _qset = _scope = _hasFreshPuzzle = null

	puzzleSpots = []
	finalWordPositions = []
	currentWordNum = null

	wordList = []
	wordStrings = []

	backwards = true
	diagonal = true

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
					return backwards && tryToPlaceWord(word,tx,ty,0,-1)
				when 3 # backwards
					return backwards && tryToPlaceWord(word,tx,ty,-1,0)
				when 4 # diagonal up
					return diagonal && tryToPlaceWord(word,tx,ty,1,-1)
				when 5 # diagonal down
					return diagonal && tryToPlaceWord(word,tx,ty,1,1)
				when 6 # diagonal up back
					return backwards && diagonal && tryToPlaceWord(word,tx,ty,-1,-1)
				when 7 # diagonal down back
					return backwards && diagonal && tryToPlaceWord(word,tx,ty,-1,1)

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
	
	makePuzzle = (words) ->
		puzzleSpots = blankPuzzle 1, 1
		wordStrings = words.slice()
		finalWordPositions = []
		addWord(longestWordsFirst(words))

		for spot in puzzleSpots
			console.log spot

		fillExtraSpaces()

		puzzleSpots
	
	fillExtraSpaces = ->
		for j in [0...puzzleSpots.length]
			for i in [0...puzzleSpots[0].length]
				if puzzleSpots[j][i] == " "
					puzzleSpots[j][i] = String.fromCharCode(Math.floor(Math.random() * 26) + 97)

	addWord = (words) ->
		currentWordNum = 0
		word = words[currentWordNum]

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

	initNewWidget = (widget, baseUrl) ->
		_scope = angular.element($('body')).scope()
		_scope.$apply ->
			_scope.widget.title	= 'New Word Search Widget'
			_scope.generateNewPuzzle = ->
				_hasFreshPuzzle = false
				_buildSaveData()
			_scope.noLongerFresh = ->
				_hasFreshPuzzle = false
		_qset = {}
	
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

			drawPuzzle makePuzzle(a)
			
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
			_qset.options.wordLocations = getFinalWordPositionsString()

			_hasFreshPuzzle = true

		_okToSave
	
	getFinalWordPositionsString = ->
		s = ""
		for i in [0...finalWordPositions.length]
			for j in [0...finalWordPositions[i].length]
				s += finalWordPositions[i][j] + ","
		s
	
	drawPuzzle = (puzzle) ->
		x = 0
		y = 0

		_context = document.getElementById('canvas').getContext('2d')
		_context.clearRect(0,0,400,400)
		
		size = 35 / (finalWordPositions.length / 2)

		_context.font = "bold "+size+"px verdana"
		_context.fillStyle = "#fff"

		xpad = _context.measureText("a")

		height = 385 / puzzle.length

		# iterate through the letter spot string
		for row in puzzle
			width = 385 / row.length
			for col in row
				_context.fillText col, 15 + xpad.width + x * width, 15 + xpad.width + y * height
				x++
			x = 0
			y++
	
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

	initExistingWidget = (title,widget,qset,version,baseUrl) ->
		# Set up the scope functions
		initNewWidget widget, baseUrl


	# Word search puzzles don't have media
	onMediaImportComplete = (media) -> null

	#TODO
	onQuestionImportComplete = (media) -> null

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


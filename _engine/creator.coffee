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
		for ty in [0..puzzleSpots.length-1]
			for tx in [0..puzzleSpots[0].length-1]
				r.push [tx,ty]

		newr = []
		while r.length > 0
			i = Math.floor(Math.random() * r.length)
			newr.push r[i]
			r.splice(i,1)

		return newr
	
	placeWord = (word, dir) ->
		r = randomPositions()
		for i in [0..r.length - 1]
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
		for i in [0..word.length-1]
			if not checkLetter(word.charAt(i), tx + (i*xChange), ty + (i*yChange))
				return false
		for i in [0..word.length-1]
			puzzleSpots[ty + (i*yChange)][tx + (i*xChange)] = word.charAt(i)

		recordWordPosition(tx,ty,tx + (word.length-1) * xChange, ty + (word.length-1) * yChange)
		return true

	recordWordPositions = (sx,sy,ex,ey) ->
		finalWordPositions.push [sx,sy,ex,ey]

	makePuzzle = (words) ->
		wordStrings = words.slice()
		addWord(longestWordsFirst(words))

		for spot in puzzleSpots
			console.log spot
		#console.log finalWordPositions
		#fillExtraSpaces()

	addWord = (words) ->
		currentWordNum = 0
		word = words[currentWordNum]

		randDirection = randomDirections()

		for i in [0..randDirection.length-1]
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

		for j in [0..h+puzzleSpots.length-1]
			newPuzzleSpots.push []
			for i in [0..w+puzzleSpots[0].length-1]
				newPuzzleSpots[j].push " "

		randWidthOffset = Math.floor(Math.random() * w)
		randHeightOffset = Math.floor(Math.random() * h)

		for j in [0..puzzleSpots.length-1]
			for i in [0..puzzleSpots[0].length-1]
				newPuzzleSpots[j+randHeightOffset][i+randWidthOffset] = puzzleSpots[j][i]

		puzzleSpots = newPuzzleSpots

		for i in [0..finalWordPositions.length-1]
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
		#_scope = angular.element($('body')).scope()
		###
		_scope.$apply ->
			_scope.widget.title	= 'New Crossword Widget'
			_scope.generateNewPuzzle = ->
				_hasFreshPuzzle = false
				_buildSaveData()
			_scope.noLongerFresh = ->
				_hasFreshPuzzle = false
		###

		# NEED TO FIX ISSUE WITH IT GOING OUT OF BOUNDS AND CRASHING
		for i in [0..100]
			puzzleSpots = blankPuzzle 12, 12#minWidth, minHeight
			makePuzzle ["foo","bar","joo","fauxel"]
	
	blankPuzzle = (w,h) ->
		t = []
		for ty in [0..h-1]
			t.push []
			for tx in [0..w-1]
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
	onQuestionImportComplete = (media) -> null

	onSaveClicked = -> null
	onSaveComplete = -> null

	# Public members
	initNewWidget            : initNewWidget
	initExistingWidget       : initExistingWidget
	onSaveClicked            : onSaveClicked
	onMediaImportComplete    : onMediaImportComplete
	onQuestionImportComplete : onQuestionImportComplete
	onSaveComplete           : onSaveComplete


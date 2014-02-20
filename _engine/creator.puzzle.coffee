Namespace('WordSearch').Puzzle = do ->
	puzzleSpots = []
	finalWordPositions = []
	currentWordNum = null

	wordList = []
	wordStrings = []

	_backwards = false
	_diagonal = false

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
					return _backwards && tryToPlaceWord(word,tx,ty,0,-1)
				when 3 # backwards
					return _backwards && tryToPlaceWord(word,tx,ty,-1,0)
				when 4 # diagonal up
					return _diagonal && tryToPlaceWord(word,tx,ty,1,-1)
				when 5 # diagonal down
					return _diagonal && tryToPlaceWord(word,tx,ty,1,1)
				when 6 # diagonal up back
					return _backwards && _diagonal && tryToPlaceWord(word,tx,ty,-1,-1)
				when 7 # diagonal down back
					return _backwards && _diagonal && tryToPlaceWord(word,tx,ty,-1,1)

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
	
	makePuzzle = (words,backwards,diagonal) ->
		_backwards = backwards
		_diagonal = diagonal

		puzzleSpots = blankPuzzle 1, 1
		wordStrings = words.slice()
		finalWordPositions = []
		addWord(longestWordsFirst(words))

		fillExtraSpaces()

		puzzleSpots
	
	fillExtraSpaces = ->
		for j in [0...puzzleSpots.length]
			for i in [0...puzzleSpots[0].length]
				if puzzleSpots[j][i] == " "
					puzzleSpots[j][i] = String.fromCharCode(Math.floor(Math.random() * 26) + 97)

	addWord = (words) ->
		currentWordNum = 0
		word = words[currentWordNum].replace(/\s/g,'')

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
	
	getFinalWordPositionsString = ->
		s = ""
		for i in [0...finalWordPositions.length]
			for j in [0...finalWordPositions[i].length]
				s += finalWordPositions[i][j] + ","
		s

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

	makePuzzle: makePuzzle
	getFinalWordPositionsString: getFinalWordPositionsString


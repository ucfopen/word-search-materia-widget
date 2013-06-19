/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
	public class WordSearchLogic
	{
		public static const FORWARD:int = 1;
		public static const BACKWARD:int = 2;
		private var wordList:Array; // each element is [ (start x), (start y), (length), (direction) ]
		private var wordStrings:Array; // arry of the word strings
		private var backwards:Boolean, diagonal:Boolean; // limits on how words can be placed
		public var puzzleSpots:Array;
		public var finalWordPositions:Array
		private var currentWordNum:Number;
		// this class is the game logic for word search games
		public function WordSearchLogic(minWidth:Number, minHeight:Number, 	allowDiagonals:Boolean = true, allowBackwards:Boolean = true):void
		{
			backwards = allowBackwards;
			diagonal = allowDiagonals;
			puzzleSpots = blankPuzzle(minWidth, minHeight);
			finalWordPositions = new Array();
		}
		public function loadPuzzle(width:int, height:int, spots:String, wordPositions:String, words:Array):void
		{
			// puzzleObject is a 2d array of the letters grid
			// wordPositions is a 2d array of each words [startX,startY, endX, endY]
			// final word positions was a string made by getFinalWordPositionsString
			wordStrings = words;
			var positions:Array = wordPositions.split(",");
			finalWordPositions = [];
			var i:int, j:int;
			for(i=0; i< positions.length-1;) // lenght-1 because ther will be an extra "" from splitting
			{
				var pos:Array = [];
				pos.push(int(positions[i++]));
				pos.push(int(positions[i++]));
				pos.push(int(positions[i++]));
				pos.push(int(positions[i++]));
				finalWordPositions.push(pos);
			}
			// spots is a string, break it up into spots -> the string was made by getPuzzleSpotsString
			var curStringIndex:int = 0;
			puzzleSpots = [];
			for( i = 0; i< height; i++)
			{
				var t:Array = [];
				for( j =0; j< width; j++)
				{
					t.push(spots.charAt(curStringIndex++));
				}
				puzzleSpots.push(t);
			}
		}
		public function getPuzzleSpotsString():String
		{
			var s:String = "";
			for(var i:int =0; i<puzzleSpots.length; i++)
			{
				for(var j:int =0; j< puzzleSpots[i].length; j++)
				{
					s += puzzleSpots[i][j];
				}
			}
			return s;
		}
		public function getFinalWordPositionsString():String
		{
			var s:String = "";
			for(var i:int =0; i< finalWordPositions.length; i++)
			{
				for(var j:int = 0; j< finalWordPositions[i].length; j++)
				{
					s+= finalWordPositions[i][j] + ",";
				}
			}
			return s;
		}
		protected static function longestWordsFirst(words:Array):Array
		{
			function compare(a:Object, b:Object):int
			{
				if(a.length > b.length)
				{
					return -1;
				}
				else if( a.length < b.length)
				{
					return 1;
				}
				return 0;
			}
			return words.sort(compare);
		}
		public function makePuzzle(words:Array):void
		{
			wordStrings = words.slice();
			addWord(longestWordsFirst(words));
			fillExtraSpaces();
		}
		public function makePuzzleFromString(s:String):void
		{
			s = s.replace(/\W/g, ' ');
			s = s.toLowerCase();
			var words:Array = s.split(" ");
			var words2:Array = new Array();
			for(var i:int = 0; i< words.length; i++)
			{
				if(words[i].length > 0)
				{
					words2.push(words[i]);
				}
			}
			if(words2.length <= 0) return;
			makePuzzle(words2);
		}
		public function containsWord(s:String):int
		{
			var i:int;
			for(i = 0; i< wordStrings.length; i++)
			{
				if(wordStrings[i] == s)
				{
					return FORWARD;
				}
			}
			for(i = 0; i< wordStrings.length; i++)
			{
				if(wordStrings[i] == reverseWord(s))
				{
					return BACKWARD;
				}
			}
			return 0;
		}
		public function reverseWord(word:String):String
		{
			return word.split("").reverse().join("")
		}
		private function blankPuzzle( w:int, h:int):Array
		{
			var t:Array = new Array();
			var ty:int
			var tx:int;
			for(ty = 0; ty < h; ty++)
			{
				t.push(new Array());
				for(tx=0; tx < w; tx++)
				{
					t[ty].push(" ");
				}
			}
			return t;
		}
		// i decided to first randomly pick a position then try to place it on the board
		private function addWord(words:Array):void
		{
			currentWordNum = 0; // words will come in sorted longest word first, and we want to use that
			var word:String = words[currentWordNum];
			// randomly try all positions and alignments
			//var randPositions:Array = randomPositions();
			var randDirection:Array = randomDirections();
			for(var i:Number = 0; i< randDirection.length; i++)
			{
				if( placeWord( word, randDirection[i]))
				{
					// add the next word or return
					words.splice(currentWordNum,1);
					if(words.length <= 0) return;
					else
					{
						addWord(words);
						return;
					}
				}
			}
			// if none of them work, increase size and try again
			increasePuzzleSize(1,1);
			addWord(longestWordsFirst(words));
		}
		private function randomPositions():Array
		{
			// make an array of x-y pairs and put it in random order
			var tx:Number, ty:Number;
			var r:Array = new Array();
			for(ty = 0; ty < puzzleSpots.length; ty++)
			{
				for(tx = 0; tx < puzzleSpots[0].length; tx++)
				{
					r.push([tx, ty]);
				}
			}
			var newr:Array = new Array();
			var i:Number;
			while( r.length > 0)
			{
				i = Math.floor(Math.random()* r.length);
				newr.push(r[i]);
				r.splice(i,1);
			}
			return newr;
		}
		private function randomDirections():Array
		{
			var choiceOrder:Array = [0,1,2,3,4,5,6,7];
			var randChoiceOrder:Array = [];
			var i:int;
			while(choiceOrder.length > 0)
			{
				i = Math.floor(Math.random()* choiceOrder.length);
				randChoiceOrder.push( choiceOrder[i]);
				choiceOrder.splice(i,1);
			}
			return randChoiceOrder;
		}
		private function placeWord( word:String, dir:Number):Boolean
		{
			// try and put the word in place, with it starting at tx,ty
			// try all the different alignments randomly
			var r:Array = randomPositions();
			var tx:int, ty:int;
			for(var i:int = 0; i< r.length; i++)
			{
				tx = r[i][0];
				ty = r[i][1];
				switch(dir)
				{
					case 0: // forwards
						return tryToPlaceWord(word,tx,ty,1,0)
					case 1: // down
						return tryToPlaceWord(word,tx,ty,0,1)
					case 2: // up
						return backwards && tryToPlaceWord(word,tx,ty,0,-1)
					case 3: // backwards
						return backwards && tryToPlaceWord(word,tx,ty,-1,0)
					case 4: // diagonal up
						return diagonal && tryToPlaceWord(word,tx,ty,1,-1)
					case 5: // diagonal down
						return diagonal && tryToPlaceWord(word,tx,ty,1,1)
					case 6: // diagonal up back
						return backwards && diagonal && tryToPlaceWord(word,tx,ty,-1,-1)
					case 7: // diagonal down back
						return backwards && diagonal && tryToPlaceWord(word,tx,ty,-1,1)
				}
			}
			return false;
		}
		private function tryToPlaceWord(word:String,tx:int,ty:int,xChange:int,yChange:int):Boolean
		{
			var i:Number;
			for(i=0; i<word.length; i++)
			{
				if(! checkLetter( word.charAt(i), tx + (i*xChange), ty + (i*yChange)) )
				{
					return false;
				}
			}
			// add the word
			for(i=0; i<word.length; i++)
			{
				puzzleSpots[ty + (i*yChange)][tx + (i*xChange)] = word.charAt(i);
			}
			recordWordPosition(tx,ty,tx + (word.length-1)* xChange, ty + (word.length-1)* yChange);
			return true;
		}
		private function recordWordPosition( sx:int,sy:int,ex:int,ey:int):void
		{
			finalWordPositions.push([sx,sy,ex,ey]);
		}
		public function printWord(sx:int, sy:int, ex:int, ey:int):void
		{
			var s:Array = new Array();
			while(sx != ex || sy != ey)
			{
				s.push(puzzleSpots[sy][sx]);
				if(sx < ex) sx++;
				else if( sx > ex) sx--;
				if(sy < ey) sy++;
				else if( sy > ey) sy--;
			}
			s.push(puzzleSpots[sy][sx]);
		}
		private function checkLetter( letter:String, tx:int, ty:int):Boolean
		{
			if( ty < 0 || ty >= puzzleSpots.length) return false;
			if( tx < 0 || tx >= puzzleSpots[0].length) return false;
			if(puzzleSpots[ty][tx] == letter || puzzleSpots[ty][tx] == " ") return true;
			return false;
		}
		private function increasePuzzleSize(w:Number,h:Number):void
		{
			// increase the width by w and the height by h
			// put the current puzzle on the expanded puzzle randomly
			var i:int, j:int;
			var newPuzzleSpots:Array = new Array();
			// make the new grid
			for(j=0; j<h+puzzleSpots.length; j++)
			{
				newPuzzleSpots.push(new Array());
				for(i=0; i< w+puzzleSpots[0].length; i++)
				{
					newPuzzleSpots[j].push(" ");
				}
			}
			// randomly put the current puzzle spots on the new increased side puzzle
			var randWidthOffset:int = Math.floor(Math.random()*w);
			var randHeightOffset:int = Math.floor(Math.random()*h);
			// fill with the old grid data
			for(j=0; j<puzzleSpots.length; j++)
			{
				for(i=0; i< puzzleSpots[0].length; i++)
				{
					newPuzzleSpots[j+randHeightOffset][i+randWidthOffset] = puzzleSpots[j][i];
				}
			}
			// save the new grid
			puzzleSpots = newPuzzleSpots;
			// fix the record of final word positions
			for(i=0; i< finalWordPositions.length; i++)
			{
				finalWordPositions[i][0] += randWidthOffset;
				finalWordPositions[i][2] += randWidthOffset;
				finalWordPositions[i][1] += randHeightOffset;
				finalWordPositions[i][3] += randHeightOffset;
			}
		}
		private function fillExtraSpaces():void
		{
			var i:Number, j:Number;
			for(j=0; j<puzzleSpots.length; j++)
			{
				for(i=0; i< puzzleSpots[0].length; i++)
				{
					if(puzzleSpots[j][i] == " ")
					{
						puzzleSpots[j][i] = String.fromCharCode( Math.floor(Math.random()*26) + 97 /*65*/);
					}
				}
			}
		}
	}
}
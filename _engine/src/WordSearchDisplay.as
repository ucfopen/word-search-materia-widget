/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
import com.gskinner.motion.GTween;
import flash.display.BlendMode;
import flash.display.InteractiveObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.DataEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.*;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.utils.Timer;
public class WordSearchDisplay extends MovieClip
{
		private var puzzleClips:Array;
		private var currentLine:Sprite;
		private var currentEraserLine:Sprite;
		private var lines:Array;
		private var selectedLetter:PuzzleSpot = null;
		private var currentWord:String; // the string that is being circled
		private var usingKeyboard:Boolean = false;
		private var predictedNextSpot:PuzzleSpot;
		//keyboard navigation
		protected var gridRow:int = 0;
		protected var gridColumn:int = 0;
		protected var currentWordForReader:String;
		private var drawingLayer:Sprite;
		protected var newLine:Boolean = false
		protected var lineGoing:Boolean = false;
		protected var originalHeight:Number
		protected var originalWidth:Number;
		private var puzzleLogic:WordSearchLogic;
		public static const WORD_CIRCLED:String = "WORD_CIRCLED";
		protected var mcList:Array = null;
		public static const LINE_COLOR:Number = 0xCCCCCC
		public static const ACTIVE_LINE_COLOR:Number = 0xffcc66
		public function WordSearchDisplay():void
		{
			drawingLayer = new Sprite();
			this.tabEnabled = true;
			this.tabIndex = 0;
			addChild(drawingLayer);
			addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(MouseEvent.MOUSE_DOWN, selectPiece, false, 0, true);
		}
		private function endLine(e:MouseEvent = null):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, endLine);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawLine);
			lineGoing  = false;
			if( currentLine != null )
			{
				var wordDirection:int = puzzleLogic.containsWord(currentWord);
				if(wordDirection)
				{
					// the user has circled a word!
					dispatchEvent( new DataEvent(WORD_CIRCLED, false, false, (wordDirection == WordSearchLogic.FORWARD ? currentWord : puzzleLogic.reverseWord(currentWord)) ) );
					currentWord = "";
					// keep it circled
					var t:GTween = new GTween(currentLine, 1, {alpha:currentLine.alpha});
					var ct:ColorTransform = new ColorTransform();
					currentLine.transform.colorTransform = ct;
					t.onChange = function(tween:GTween):void
					{
						var start:Number = 0;
						var end:Number = 1;
						var ratio:Number = tween.ease(tween.calculatedPosition/tween.duration, 0, 1, 1);
						var value:Number = start+(end-start)*ratio;
						ct.redMultiplier = ct.greenMultiplier = ct.blueMultiplier = 1 - value;
						ct.redOffset = ct.greenOffset = ct.blueOffset = value * 0xff;
						tween.target.transform.colorTransform = ct;
					}
				}
				else
				{
					var t2:GTween = new GTween(currentLine, .2, {alpha:0, scaleX:1.1, scaleY:1.1});
					var lineRef:Sprite = currentLine;
					t2.onComplete = function(tween:GTween):void { destroyLine(lineRef);  };
				}
				currentLine = null;
			}
		}
		private function destroyLine(line:Sprite):void
		{
			drawingLayer.removeChild(line);
		}
		private function drawLine(e:MouseEvent = null):void
		{
			var xDist:Number;
			var yDist:Number;
			var closest:Number;
			var closestMC:PuzzleSpot;
			var closestX:Number = 0;
			var closestY:Number = 0;
			if(selectedLetter == null) return;
			if(! lineGoing) return;
			// create a new line if needed
			if(newLine)
			{
				newLine = false;
				currentLine = new Sprite();
				drawingLayer.addChild(currentLine);
				currentEraserLine = new Sprite();
				currentLine.addChild(currentEraserLine);
			}
			closest = Number.POSITIVE_INFINITY;
			for(var j:Number=0; j< puzzleClips.length; j++)
			{
				for(var i:Number=0; i< puzzleClips[j].length; i++)
				{
					xDist = selectedLetter.xID - i;
					yDist = selectedLetter.yID - j;
					// if this piece can be moved to
					if(xDist == yDist || xDist == -yDist || xDist == 0 || yDist == 0)
					{
						// check if this is the new closest piece
						var d:Number = distance(!e?predictedNextSpot.centerX:this.mouseX,
												!e?predictedNextSpot.centerY:this.mouseY,
												(puzzleClips[j][i].centerX),(puzzleClips[j][i].centerY));
						if(d < closest)
						{
							closest = d;
							closestMC = puzzleClips[j][i];
							closestX = i;
							closestY = j;
						}
					}
				}
			}
			currentWord = getWord(selectedLetter.xID, selectedLetter.yID, closestX, closestY);
			currentLine.graphics.clear();
			currentEraserLine.graphics.clear();
			circleWord(selectedLetter, closestMC, currentLine, currentEraserLine);
		}
		private function distance(sx:int,sy:int,ex:int,ey:int):Number
		{
			var a:Number = ex - sx;
			var b:Number = ey - sy;
			return Math.sqrt( a*a + b*b );
		}
        private  function  getWord(startX:int, startY:int, endX:int, endY:int, dotSeparate:Boolean = false):String
        {
			var s:String = "";
			var j:Number = startY, i:Number = startX;
			while( !(i == endX && j == endY) )
			{
				s += puzzleClips[j][i].spotText.text;
				if(dotSeparate) s+= ".";
				if(i < endX) i++;
				else if( i > endX) i--;
				if(j < endY) j++;
				else if( j > endY) j--;
			}
			s += puzzleClips[j][i].spotText.text;
			return s;
		}
		public function completePuzzle(puzzle:WordSearchLogic):void // NOTE: this can only be called on a displayed puzzle
		{
			if(mcList != null)
			{
				for(var t:int = 0; t<mcList.length; t++)
				{
					drawingLayer.removeChild(mcList[t]);
				}
			}
			mcList = new Array();
			var mc:Sprite, msk:Sprite;
			for(var i:int =0; i< puzzle.finalWordPositions.length; i++)
			{
				mc = new Sprite();
				msk = new Sprite();
				mc.addChild(msk);
				drawingLayer.addChild(mc);
				var pos:Array = puzzle.finalWordPositions[i];
				var w:String = getWord(pos[0], pos[1], pos[2], pos[3]);
				dispatchEvent(new DataEvent(WORD_CIRCLED, false,false, w));
				circleWord( puzzleClips[ pos[1] ][ pos[0] ], puzzleClips[ pos[3] ][ pos[2] ], mc, msk);
				mcList.push(mc);
			}
		}
		public function resetPuzzle():void
		{
			if(mcList == null) return;
			for(var i:int =0; i< mcList.length; i++)
			{
				drawingLayer.removeChild(mcList[i]);
			}
			mcList = [];
		}
		public function displayPuzzle(puzzle:WordSearchLogic, maxWidth:Number = 0):void
		{
			var i:int, j:int;
			puzzleLogic = puzzle;
			// erase the old puzzle
			if(puzzleClips != null)
			{
				for(i=0; i< puzzleClips.length; i++)
				{
					for(j=0; j < puzzleClips[i].length; j++)
					{
						removeChild(puzzleClips[i][j]);
					}
				}
			}
			drawingLayer.graphics.clear();
			while(drawingLayer.numChildren)
			{
				drawingLayer.removeChildAt(0);
			}
			puzzleClips = new Array();
			var squareSize:Number = 30;
			if (maxWidth != 0)
			{
				squareSize = maxWidth / puzzle.puzzleSpots.length;
			}
			var textSize:Number;
			for(j=0;j<puzzle.puzzleSpots.length;j++)
			{
				puzzleClips.push([]);
				for(i=0; i<puzzle.puzzleSpots[0].length; i++)
				{
					var mc:PuzzleSpot = new PuzzleSpot(squareSize, i, j);
					if (i == 0)
					{
						textSize = mc.getTextSize();
					}
					mc.addText(puzzle.puzzleSpots[j][i], textSize);
					var dS:DropShadowFilter = new DropShadowFilter();
					dS.distance = 5;
					dS.blurX = 7;
					dS.blurY = 7;
					dS.strength = .30;
					dS.angle = .65;
					mc.filters = [dS];
					this.addChild(mc);
					mc.x = i*squareSize;
					mc.y = j*squareSize;
					puzzleClips[j].push(mc);
				}
			}
		}
		private function selectPiece(e:MouseEvent):void
		{
			if(e.target is PuzzleSpot)
			{
				PuzzleSpot(e.target).focusRect = false;
				if(usingKeyboard) endLine();
				usingKeyboard = false;
				if(lineGoing) return;
				selectedLetter = e.target as PuzzleSpot;
				stage.focus = selectedLetter;
				gridRow = selectedLetter.yID;
				gridColumn = selectedLetter.xID;
				newLine = true;
				lineGoing = true;
				stage.addEventListener(MouseEvent.MOUSE_UP, endLine, false, 0, true);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, drawLine, false, 0, true);
			}
		}
		public function setRegistrationPoint(s:Sprite, regx:Number, regy:Number, showRegistration:Boolean ):void
		{
			//translate movieclip
			s.transform.matrix = new Matrix(1, 0, 0, 1, -regx, -regy);
			//registration point.
			if (showRegistration)
			{
				var mark:Sprite = new Sprite();
				mark.graphics.lineStyle(1, 0x000000);
				mark.graphics.moveTo(-5, -5);
				mark.graphics.lineTo(5, 5);
				mark.graphics.moveTo(-5, 5);
				mark.graphics.lineTo(5, -5);
				s.parent.addChild(mark);
			}
		}
		private function circleWord( w1:PuzzleSpot, w2:PuzzleSpot, g:Sprite, e:Sprite):void
		{
			var circleWidth:int = w1.width - w1.width/9;
			var circleWeight:int = w1.width/5;
			var sX:Number = w1.x + w1.width/2;
			var sY:Number = w1.y + w1.height/2;
			var eX:Number = w2.x + w2.width/2;
			var eY:Number = w2.y + w2.height/2;
			var h:Number = Math.abs(eY - sY)
			var w:Number = Math.abs(eX - sX)
			var x:Number = Math.min(eX, sX)
			var y:Number = Math.min(eY, sY);
			var cx:Number = x + w/2;
			var cy:Number = y + h/2;
			if(circleWeight < 2) circleWeight = 2;
			g.x = cx;
			g.y = cy;
			// trick to display diaginal line correctly
			// the line below is always drawn from the top left to the bottom right, reversing the h & w allows it to draw in all directions diagonally
			if(sX < eX) w = -w;
			if(sY < eY) h = -h;
			// draw the outline shape
			g.graphics.lineStyle(circleWidth, ACTIVE_LINE_COLOR);
			g.graphics.moveTo(-w/2, -h/2);
			g.graphics.lineTo(w/2, h/2);
			// draw the hole
			e.graphics.lineStyle(circleWidth-circleWeight, 0);
			e.graphics.moveTo(-w/2, -h/2);
			e.graphics.lineTo(w/2, h/2);
			// cut out the hole
			g.cacheAsBitmap = true;
			e.cacheAsBitmap = true;
			e.blendMode = BlendMode.ERASE;
		}
		private function onKeyDown(event:KeyboardEvent):void
		{
			//the 2d array corresponding to the letters in the grid
			switch(event.keyCode)
			{
				case 100://left
				{
					gridColumn--;
					if(gridColumn < 0) gridColumn = puzzleClips[gridRow].length-1;
					break;
				}
				case 102://right
				{
					gridColumn++;
					if(gridColumn > puzzleClips[gridRow].length-1) gridColumn = 0;
					break;
				}
				case 104://up
				{
					gridRow--;
					if(gridRow < 0) gridRow = puzzleClips.length-1;
					break;
				}
				case 98://down
				{
					gridRow++;
					if(gridRow > puzzleClips.length-1) gridRow = 0;
					break;
				}
				case 101://center
				{
					if(!usingKeyboard && !lineGoing)
					{
						usingKeyboard = true;
						selectedLetter = puzzleClips[gridRow][gridColumn];
						newLine = true;
						lineGoing = true;
					}
					else
					{
						if(usingKeyboard)
						{
							usingKeyboard = false;
							endLine();
							return;
						}
					}
					break;
				}
				default:
				{
					return;
				}
			}
			predictedNextSpot = puzzleClips[gridRow][gridColumn];
			predictedNextSpot.focusRect = true;
			if(usingKeyboard) drawLine();
			stage.focus = predictedNextSpot;
		}
	}
}
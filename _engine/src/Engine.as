/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
	import com.gskinner.motion.GTween;
	import flash.display.GradientType;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;
	import nm.events.StandardEvent;
	import nm.gameServ.engines.EngineCore;
	import nm.geom.Dimension;
	import nm.ui.AlertWindow;


	public class Engine extends EngineCore
	{
		protected static const ENABLED_ALPHA:Number = 1.0;
		protected static const DISABLED_ALPHA:Number = 0.5;
		protected static const EXTRA_SPACE:Number = 12;
		protected static const FONT_CLUES_MIN:int = 18;
		protected static const FONT_CLUES_MAX:int = 26;
		protected var _wordsBox:MovieClip;
		protected var _wordSearchBox:MovieClip;
		protected var _searchArea:MovieClip; // placeholder defining the search area
		protected var _clueArea:MovieClip; // placeholder defining the clue area
		protected var _clueAreaDim:Dimension;
		protected var _doneButton:MovieClip; // when the user is finished, they press this
		protected var _prevPageButton:SimpleButton; // used to move to the next page of clues
		protected var _nextPageButton:SimpleButton; // used to  move to the previous page of clues
		protected var _helpButton:Sprite;
		protected var _titleText:TextField;
		protected var _progressText:TextField;
		protected var _pageText:TextField;
		protected var _mainClip:MovieClip;
		protected var _clickDoneInstructions:MovieClip

		protected var _clueFontSize:Number;
		protected var _clueLineHeight:Number;
		protected var _strikeQueueArray:Array;
		protected var _strikeIndex:int;
		// NOTE: this isnt really MVC patter or anything
		protected var _gameModel:WordSearchLogic;
		protected var _gameView:WordSearchDisplay;
		// parallel arrays for storing word data
		protected var _words:Array; // objects with {word, hint, id)
		protected var _textFieldPages:Array; // word text fields
		protected var _strikePages:Array; // word text fields
		protected var _wordTextFields:Array; // word text fields
		protected var _wordsCircled:Array; // booleans for if the word is circled
		// game configurations
		protected var _byDefinitions:Boolean;
		protected var _allowDiagonals:Boolean;
		protected var _allowBackwards:Boolean;
		protected var _randomGame:Boolean;
		protected var _wordsPanel:MovieClip;
		protected var _wordsPanelOld:MovieClip;
		protected var _wordsPanelContainer:MovieClip;
		protected var _blinkCounter:int;
		protected var DONE_BLINKING_COUNT:int = 14;
		protected var _alertWindow:AlertWindow;
		protected var _helpWindow:HelpWindow;
		//unsorted
		protected var _clueTextFormat:TextFormat;
		protected var _clueDropShadow:DropShadowFilter;
		protected var _wordsPerPage:int;
		protected var _numPages:int;
		protected var _currentPage:int;
		//tweens
		protected var _wordsPanelTween:GTween;
		protected var _wordsPanelOldTween:GTween;
		//tab indexing
		protected var _indexer:uint = 1;


		public function Engine():void
		{
			var b:MainClip = new MainClip();
			addChild(b);
			setChildIndex(b,0);
			_wordsBox                      = b.wordsBox;
			_wordSearchBox                 = b.wordSearchBox;
			_searchArea                    = b.wordSearchMaxArea;
			_clueArea                      = b.wordsMaxArea;
			_clueAreaDim                   = new Dimension(_clueArea.width, _clueArea.height);
			_clueArea.visible              = false;
			_searchArea.visible            = false;
			_doneButton                    = b.doneButton;
			_nextPageButton                = b.nextArrow;
			_prevPageButton                = b.prevArrow;
			_nextPageButton.tabIndex       = 103;
			_prevPageButton.tabIndex       = 102;
			_doneButton.tabIndex           = 104;
			_titleText                     = b.titleText;
			_titleText.selectable          = false;
			_progressText                  = b.progressText;
			_progressText.selectable       = false;
			_pageText                      = b.pageText;
			_pageText.selectable           = false;
			_clickDoneInstructions         = b.clickDoneInstructions;
			_clickDoneInstructions.visible = false;
			_mainClip                      = b;
			super();
		}


		/**
		 * Called at the start of the game to set up the game.
		 */
		protected override function startEngine():void
		{
			super.startEngine();
			_helpWindow = new HelpWindow();
			_helpWindow.x = (this.width-_helpWindow.width)/2;
			_helpWindow.y = (this.height-_helpWindow.height)/2;
			_helpWindow.visible = false;
			_helpButton = new Sprite();
			_helpButton.buttonMode = true;
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(75,25,0,0,0);
			_helpButton.graphics.beginGradientFill(GradientType.LINEAR, [0x0C121A,0x365F88,0x0C121A],[1,1,1],[0,127,255],matrix);
			_helpButton.graphics.lineStyle(1,0x345C83);
			_helpButton.graphics.drawRoundRect(0,0,75,25,5);
			_helpButton.graphics.endFill();
			_helpButton.x = this.width - _helpButton.width - 10;
			_helpButton.y = 10;
			autoIndex(_helpButton);
			var helpText:TextField = new TextField();
			var helpFormat:TextFormat = new TextFormat("Arial Rounded MT Bold", 12);
			helpFormat.align = TextFormatAlign.LEFT;
			helpFormat.color = 0xFFFFFF;
			helpText.defaultTextFormat = helpFormat;
			helpText.text = "Keyboard";
			helpText.autoSize = TextFieldAutoSize.LEFT;
			helpText.x = (_helpButton.width - helpText.width)/2;
			helpText.y = (_helpButton.height - helpText.height)/2;
			helpText.mouseEnabled = false;
			helpText.selectable = false;
			_helpButton.addChild(helpText);
			_byDefinitions = (EngineCore.qSetData.options["byDefinitions"] == "1" );
			_allowDiagonals = (EngineCore.qSetData.options["diagonal"] == "1");
			_allowBackwards = (EngineCore.qSetData.options["backwards"] == "1");
			_randomGame = (EngineCore.qSetData.options["random"] == "1")
			_strikeQueueArray = new Array();
			initCluesPanel();
			// set the game title
			_titleText.text = inst.name;
			// get an array of just the words
			var justWords:Array = [];

			for(var i:int = 0; i < _words.length; i++)
			{
				justWords.push(_words[i].word);
			}

			if(_randomGame == true)
			{
				_gameModel = new WordSearchLogic(1,1,_allowDiagonals,_allowBackwards);
				_gameModel.makePuzzle(justWords);
			}
			else
			{
				_gameModel = new WordSearchLogic(1,1,_allowDiagonals,_allowBackwards);
				_gameModel.loadPuzzle(EngineCore.qSetData.options["puzzleWidth"], EngineCore.qSetData.options["puzzleHeight"], EngineCore.qSetData.options["spots"], EngineCore.qSetData.options["wordLocations"],	justWords);
			}

			_gameView = new WordSearchDisplay();
			_gameView.displayPuzzle(_gameModel, _searchArea.width);
			addChild(_gameView);
			_gameView.addEventListener(WordSearchDisplay.WORD_CIRCLED, wordCircled, false, 0, true);
			initButtons();
			showClues(false);
			positionWordSearch();
			addChild(_helpWindow);
			addChild(_helpButton);
		}


		/**
		 * Adds listeners and properties to the buttons on the screen
		 */
		protected function initButtons():void
		{
			_doneButton.buttonMode = true;
			_doneButton.addEventListener(MouseEvent.MOUSE_UP, isGameFinished, false,0, true);
			_nextPageButton.addEventListener(MouseEvent.MOUSE_UP, onNextPageButton, false,0, true);
			_prevPageButton.addEventListener(MouseEvent.MOUSE_UP, onPrevPageButton, false,0, true);
			_helpButton.addEventListener(MouseEvent.CLICK, onHelpButton, false, 0, true);
			_doneButton.addEventListener(KeyboardEvent.KEY_DOWN, onButtonKeyDown, false,0,true);
			_nextPageButton.addEventListener(KeyboardEvent.KEY_DOWN, onButtonKeyDown, false,0,true);
			_prevPageButton.addEventListener(KeyboardEvent.KEY_DOWN, onButtonKeyDown, false,0,true);
			_helpButton.addEventListener(KeyboardEvent.KEY_DOWN, onButtonKeyDown, false,0,true);
		}


		protected function focusHelpInitially(event:Event = null):void
		{
			removeEventListener(MouseEvent.CLICK, focusHelpInitially);
			removeEventListener(KeyboardEvent.KEY_DOWN, focusHelpInitially);
			stage.focus = _helpWindow;
			addEventListener(MouseEvent.CLICK, removeHelpInitially);
			addEventListener(KeyboardEvent.KEY_DOWN, removeHelpInitially);
		}


		protected function removeHelpInitially(event:Event = null):void
		{
			removeEventListener(MouseEvent.CLICK, removeHelpInitially);
			removeEventListener(KeyboardEvent.KEY_DOWN, removeHelpInitially);
			stage.focus = _helpButton;
		}


		protected function onHelpButton(event:MouseEvent = null):void
		{
			_helpWindow.visible = !_helpWindow.visible;
		}


		protected function onButtonKeyDown(event:KeyboardEvent):void
		{
			if(event.keyCode == 101)//numpad 5
			{
				switch(event.target)
				{
					case _helpButton: { onHelpButton(); break; }
					case _prevPageButton: { onPrevPageButton(); break; }
					case _nextPageButton: { onNextPageButton(); break; }
					case _doneButton: { isGameFinished(); break; }
				}
			}
			else
			{
				if(event.target == _helpButton && _helpWindow.visible) onHelpButton();
			}
		}


		protected function initCluesPanel():void
		{
			var bottomPadding:Number = 20;

			//load words into array
			_words = getWordsAndHints();

			//---- format & effects ----\\
			//Prepare Text Format
			_clueTextFormat = new TextFormat("Arial Rounded MT Bold", FONT_CLUES_MIN);
			_clueTextFormat.align = TextFormatAlign.CENTER;
			_clueTextFormat.color = 0xFFFFFF;
			_clueTextFormat.bold = true;

			//Prepare Drop Shadows
			_clueDropShadow = new DropShadowFilter();
			_clueDropShadow.distance = 3;
			_clueDropShadow.blurX = 4;
			_clueDropShadow.blurY = 4;
			_clueDropShadow.strength = .35;
			_clueDropShadow.angle = .7;

			//---- calculate font size ----\\
			var testField:TextField = new TextField();
			testField.defaultTextFormat = _clueTextFormat;
			testField.text = "ABC1238|yj_X"; // for calculating text height
			testField.autoSize = TextFieldAutoSize.LEFT;

			//find target height
			var minHeight:int = testField.height + EXTRA_SPACE;
			var minPages:int = Math.ceil(_words.length * (minHeight) / (_clueArea.height - bottomPadding));
			_numPages = minPages;
			_wordsPerPage = Math.ceil(_words.length / minPages); // target words per page, not actual
			var targetHeight:Number = ((_clueArea.height - bottomPadding) / _wordsPerPage) - EXTRA_SPACE;
			var achievedHeight:Number; // will be set later

			//increase font size until target height is found
			var i:int;
			for(i = FONT_CLUES_MIN; i <= FONT_CLUES_MAX + 1; i++)
			{
				_clueTextFormat.size = i;
				testField.setTextFormat(_clueTextFormat);
				if(i != FONT_CLUES_MIN && testField.height > targetHeight || i == FONT_CLUES_MAX + 1)
				{
					_clueTextFormat.size = i - 1;
					testField.setTextFormat(_clueTextFormat);
					achievedHeight = testField.height;
					break;
				}
			}

			//---- interaction and functionality ----\\
			//prepare hud components
			_progressText.text = '0 of ' + _words.length + ' Found';
			_pageText.visible = (_numPages > 1);

			//create mask for words to be contained in
			_wordsPanelContainer = new MovieClip()
			_wordsPanelContainer.x = _clueArea.x;
			_wordsPanelContainer.y = _clueArea.y;
			_wordsPanelContainer.graphics.beginFill(0, 0);
			_wordsPanelContainer.graphics.drawRect(0, 0, _clueArea.width, _clueArea.height);
			_wordsPanelContainer.graphics.endFill();
			_wordsPanelContainer.mask = _clueArea;
			_mainClip.addChildAt(_wordsPanelContainer, _mainClip.getChildIndex(_clueArea));

			//initialize arrays
			_textFieldPages = new Array();
			_strikePages = new Array(minPages);
			_wordsCircled = []; // start with no words circled

			//fill wordsCircled array
			for(i =0; i<_words.length; i++)
			{
				_wordsCircled.push(false);
			}

			//---- create text fields ----\\
			_textFieldPages.push(new Array());
			var page:int = 0;
			_wordTextFields = _textFieldPages[page];
			var curY:Number = 0.0;
			_wordsPanel = new MovieClip();
			var targX:Number = 0;
			_wordsPanel.x = 0;
			_wordsPanel.y = 0;
			_wordsPanelContainer.addChild(_wordsPanel);
			var achievedWordsPerPage:int = 0;
			for(i = 0; i < _words.length; i++)
			{
				//Create Text Field
				var t:TextField = new TextField();
				t.width = _clueArea.width;
				t.embedFonts= true;
				t.defaultTextFormat = _clueTextFormat;
				t.text = _words[i].hint;
				t.filters = [_clueDropShadow];
				_wordsPanel.addChild(t);
				t.wordWrap = true;
				t.height = achievedHeight;
				t.width = _clueAreaDim.width;
				t.selectable = false;
				t.x = 0.0;
				t.y = curY; // need this so the word list gets some height so we can set the box heigt
				var s:Sprite = new Sprite();
				s.tabEnabled = true;
				autoIndex(s);
				s.addChild(t);
				//Update position for next text field
				curY += t.height + EXTRA_SPACE;
				if(_textFieldPages.length == 1)
				{
					achievedWordsPerPage++;
				}
				//Flip to next page if at the bottom
				if(curY > (_clueArea.height - bottomPadding))
				{
					if(_textFieldPages.length == 1)
					{
						achievedWordsPerPage--;
					}
					_textFieldPages.push(new Array());
					_wordTextFields = _textFieldPages[++page];
					t.y = 0;
					curY = t.height + EXTRA_SPACE;
				}
				_wordTextFields.push(s);
			}
			_wordsPanelContainer.removeChild(_wordsPanel);
			_wordsPanel = null;
			//Update numPages & words per page
			_numPages = _textFieldPages.length;
			_wordsPerPage = achievedWordsPerPage;
		}


		protected function showClues(rectOnFocus:Boolean, page:int = 0):void
		{
			const PANEL_PADDING:Number = 14.0;
			//determine if this is the first time a page is loaded
			var firstRun:Boolean = (_wordsPanel == null);
			//find direction of page change
			var dir:int = (page - _currentPage > 0? 1:-1);
			//can't do anything if word box doesn't exist
			if(_wordsBox == null)
			{
				return;
			}
			//store current page number
			_currentPage = page;
			_pageText.text = 'Page ' + (page + 1);
			//delete old panel if animation hasn't finished yet
			if(_wordsPanelOld != null)
			{
				removeOldPanel();
				//if old panel still exists, current panel is tweening... stop tween
				if(_wordsPanelTween != null) { _wordsPanelTween.paused = true; }
			}
			//move current panel to another Sprite to prepare for animation
			_wordsPanelOld = _wordsPanel;
			_wordsPanel = null;
			//add and position new clues panel
			_wordsPanel = new MovieClip();
			var targX:Number = 0;
			_wordsPanel.x = targX + (firstRun? 0:_clueArea.width + PANEL_PADDING) * dir;
			_wordsPanel.y = 0;
			_wordsPanelContainer.addChild(_wordsPanel);
			// keep the done button in front
			_mainClip.setChildIndex(_doneButton, _mainClip.numChildren-1);
			//load textfield array (from pages array)
			_wordTextFields = _textFieldPages[page];
			var i:int;
			//add words from array to panel
			for(i = 0; i < _wordTextFields.length; i++)
			{
				_wordsPanel.addChild(_wordTextFields[i]);
			}
			//add strike sprites that exist on this page back to the words
			if(_strikePages[page] != null)
			{
				for(i = 0; i < _strikePages[page].length; i++)
				{
					_wordsPanel.addChild(_strikePages[page][i]);
				}
			}
			// manage multiline cases
			var largestIndex:int;
			if(_words.length >= 1)
			{
				// make the _wordsBox surround the words
				var t1:Sprite = _wordTextFields[0];
				var t2:Sprite = _wordTextFields[_wordTextFields.length-1];
				var maxTextWidth:Number = 0.0;
				for(i=0; i< _wordTextFields.length; i++)
				{
					if(_wordTextFields[i].width > maxTextWidth)
					{
						maxTextWidth = _wordTextFields[i].width;
					}
				}
				_wordsBox.x = t1.x - PANEL_PADDING;
				_wordsBox.y = t1.y - PANEL_PADDING;
				var tmp:Number = t2.y +t2.height - t1.y + 2 * PANEL_PADDING;
				_wordsBox.height = (tmp < _clueArea.height ) ? tmp : _clueArea.height;
				tmp =  maxTextWidth + 2*PANEL_PADDING;
				_wordsBox.width = (tmp < _clueArea.width ) ? tmp : _clueArea.width;
			}
			// make everything centered in the _clueArea box
			for( i=0; i< _wordTextFields.length; i++)
			{
				if (_wordTextFields[i].getChildAt(0).length > _wordTextFields[largestIndex].getChildAt(0).length) {
					largestIndex = i;
				}
			}
			var newX:Number = _clueArea.x + (_clueArea.width - _wordsBox.width) /2;
			var newY:Number = _clueArea.y //+ (_clueArea.height - _wordsBox.height) /2;
			var xMove:Number = newX - _wordsBox.x;
			var yMove:Number = newY - _wordsBox.y;
			_wordsBox.x += xMove;
			_wordsBox.y += newY;//yMove;
			_wordsPanel.y = _wordsBox.y + PANEL_PADDING - _wordsPanelContainer.y;
			//animate new page in and old page out
			if(_wordsPanelOld != null)
			{
				var delay:Number = 0.25;
				_wordsPanelTween = new GTween(_wordsPanel, delay, {x:targX});
				_wordsPanelOldTween = new GTween(_wordsPanelOld, delay, {x:- _wordsPanel.width * dir});
				_wordsPanelOldTween.onComplete = removeOldPanel;
			}
			var lastPressedButton:InteractiveObject = stage.focus;
			_nextPageButton.visible = (_currentPage + 1 < _numPages);
			_prevPageButton.visible = (_currentPage > 0);
			if(rectOnFocus)
			{
				switch(lastPressedButton)
				{
					case(_nextPageButton):
					{
						if(!_nextPageButton.visible) stage.focus = _prevPageButton;
						break;
					}
					case(_prevPageButton):
					{
						if(!_prevPageButton.visible) stage.focus = _nextPageButton;
						break;
					}
				}
			}
		}


		/**
		 * Disposes of old clues page after animations to new page are complete
		 */
		protected function removeOldPanel(tween:GTween = null):void
		{
			//if panel doesn't exist there's nothing to do
			if(_wordsPanelOld == null)
			{
				return;
			}
			//if this method was called manually, kill its tween
			if(_wordsPanelOldTween != null) { _wordsPanelOldTween.paused = true; }
			if(_wordTextFields != null)
			{
				var i:int;
				for(i=0; i < _wordsPanelOld.numChildren; i++)
				{
					_wordsPanelOld.removeChildAt(i);
				}
				_wordsPanelContainer.removeChild(_wordsPanelOld);
				_wordsPanelOld = null;
			}
		}


		protected function positionWordSearch():void
		{
			if( _wordSearchBox != null)
			{
				const PADDING:Number = 10.0;
				// make the box surround the game
				_wordSearchBox.x = _gameView.x - PADDING;
				_wordSearchBox.y = _gameView.y -PADDING;
				_wordSearchBox.width = _gameView.width + 2*PADDING;
				_wordSearchBox.height = _gameView.height + 2*PADDING;
				_wordSearchBox.x = _searchArea.x - PADDING;
				_wordSearchBox.y = _searchArea.y -PADDING;
				_wordSearchBox.width = _searchArea.width + 2*PADDING;
				_wordSearchBox.height = _searchArea.height + 2*PADDING;
				// now center it in the _searchArea
				_wordSearchBox.x = _searchArea.x + (_searchArea.width - _wordSearchBox.width)/2;
				_wordSearchBox.y = _searchArea.y + (_searchArea.height - _wordSearchBox.height)/2;
				_gameView.x = _wordSearchBox.x + PADDING;
				_gameView.y = _wordSearchBox.y + PADDING;
			}
		}


		protected function getWordsAndHints():Array
		{
			var wordsAndHints:Array =  [];
			var mainGroup:Array;
			// use the old qset structure... it had an unecissary nested items group
			if(EngineCore.qSetData.items.length > 0 && EngineCore.qSetData.items[0].hasOwnProperty('items'))
			{
				mainGroup = EngineCore.qSetData.items[0].items
			}
			else
			{
				mainGroup = EngineCore.qSetData.items
			}
			
			for(var i:int = 0; i < mainGroup.length; i++)
			{
				var question:Object = mainGroup[i];
				var word:String = question.answers[0].text;
				// srip out anything that isnt alpha numeric and convert to lower case
				var nojunk:RegExp = /([\W]+)/g;
				word = word.replace(nojunk, '');
				word = word.toLowerCase();
				var hint:String = _byDefinitions ? question.questions[0].text : word;
				var id:String = question.id;
				wordsAndHints.push({word:word, hint:hint, id:id});
			}

			return wordsAndHints;
		}


		protected function wordCircled(e:DataEvent):void
		{
			var i:int;
			var circledCount:int = 0;
			var found:Boolean = false;
			for( i =0; i< _words.length; i++)
			{
				if( e.data == _words[i].word &&  ! _wordsCircled[i] && !found)
				{
					_wordsCircled[i] = true; // this word is done
					strikeWord(i);
					found = true;
				}
				if(_wordsCircled[i]) {
					circledCount ++;
				}
			}
			// update progress message
			_progressText.text =  (circledCount == _words.length ? 'All ' : circledCount + ' of ')  + _words.length + ' Found'
			if(circledCount == _words.length)
			{
				_mainClip.removeChild(_clickDoneInstructions)
				addChild(_clickDoneInstructions)
				_clickDoneInstructions.alpha = 0
				_clickDoneInstructions.visible = true
				new GTween(_gameView, 2.5, {alpha: .1});
				new GTween(_clickDoneInstructions, .2, {alpha: 1});
				stage.focus = _doneButton;
			}
		}


		protected function onNextPageButton(e:Event = null):void
		{
			if(_currentPage + 1 < _numPages)
			{
				showClues(e?false:true, _currentPage + 1);
			}
		}


		protected function onPrevPageButton(e:Event = null):void
		{
			if(_currentPage > 0)
			{
				showClues(e?false:true, _currentPage - 1);
			}
		}


		protected function isGameFinished(e:Event = null):void
		{
			function wordCircled(item:Boolean, index:int, array:Array):Boolean
			{
				return item; // tests if the item value is false
			}
			if(!_wordsCircled.every(wordCircled))
			{
				// not all questions answered, show a warning
				_alertWindow = alert("Not all words have been found.", "Are you sure you want to leave the game?") as AlertWindow;
				_alertWindow.addEventListener("dialogClick", alertChoiceMade, false, 0, true);
			}
			else
			{
				_doneButton.removeEventListener(MouseEvent.MOUSE_UP, isGameFinished);
				gameEnd();
			}
		}


		/**
		 * Graphically strikes out the word at the given index.
		 * If the given word is not on the current page, navigates to correct page
		 */
		protected function strikeWord(wordIndex:int):void
		{
			//navigate to current page
			var targetPage:int = wordIndex / _wordsPerPage;
			if(targetPage != _currentPage) showClues(false, targetPage);
			//convert array pos. to a pos. relative to page
			wordIndex %= _wordsPerPage;
			//---- Draw The Strike ----\\
			var clue:TextField = _wordTextFields[wordIndex].getChildAt(0);
			var strikePadding:Number = 3;
			var strikeWidth:Number = clue.textWidth + strikePadding * 2;
			var strikeStartX:Number = (_clueArea.width/2)  - (clue.textWidth/2) - strikePadding
			var strikeY:Number = clue.y+clue.height/2;
			var lines:int = clue.numLines;
			var curY:Number = clue.y;
			for (var i:int = 1; i <= lines; i++)
			{
				if(lines == 1)
				{
					_strikeQueueArray.push({"x":strikeStartX, "y":strikeY, "width":strikeWidth, clue:clue});
				}
				else
				{
					curY += (((clue.height/lines)*i)/2);
					_strikeQueueArray.push({"x":strikeStartX, "y":curY, "width":strikeWidth});
				}
			}
			drawStrikes();
		}


		/*
			NOTE: this calls itself recursivly for each line of text in the clue
		*/
		protected function drawStrikes():void
		{
			var item:Object = _strikeQueueArray.shift();
			var strike:Sprite = new Sprite;
			strike.x = item.x;
			_wordsPanel.addChild(strike);
			strike.graphics.beginFill(0xFFFFFF);
			strike.graphics.drawRect(0, item.y, 3, 3);
			strike.graphics.endFill();
			// add to page of strikes
			if(_strikePages[_currentPage] == null)
			{
				_strikePages[_currentPage] = [];
			}
			_strikePages[_currentPage].push(strike);
			// draw strike + optionally continue striking for multiline
			var t:GTween = new GTween(strike, .3, { width:item.width } );
			t.onComplete = function(tween:GTween):void { _strikeQueueArray.length > 0 ? drawStrikes : null; };
			// fade and color (starts red, turns white)
			var ct:ColorTransform = new ColorTransform();
			var t2:GTween = new GTween(item.clue, .6, { alpha:.4 }, { delay:.3} ); // fade clue
			t2.onChange = function(tween:GTween):void
			{
				var start:uint = 0;
				var end:uint = 0xff;
				var ratio:Number = tween.ease(tween.calculatedPosition/tween.duration, 0, 1, 1);
				var value:uint = start+(end-start)*ratio;
				ct.color = 0xff0000 + value*0x100 + value;
				strike.transform.colorTransform = ct;
			}
			new GTween(strike, .6, { alpha:.4 }, {delay:.3} ); // fade strike
		}


		protected function determineTextSize(clue:TextField):Number
		{
			var myTextFormat:TextFormat = new TextFormat("Arial Rounded MT Bold");
			var tf:TextFormat = new TextFormat();
			var _cellValueSize:Number = 50;
			tf.size = _cellValueSize;
			clue.setTextFormat(tf);
			while(clue.width > _wordsPanel.width && clue.height > 45)
			{
				tf = new TextFormat();
				tf.size = _cellValueSize -= 2;
				clue.setTextFormat(tf);
			}
			return _cellValueSize;
		}


		protected function determineLineHeight(fontSize:Number):Number
		{
			var exText:TextField = new TextField;
			var myTextFormat:TextFormat = new TextFormat("Arial Rounded MT Bold");
			var tf:TextFormat = new TextFormat();
			tf.size = fontSize;
			exText.setTextFormat(tf);
			exText.text = "ABQWJjI";
			var _lineHeight:Number = exText.textHeight;
			return _lineHeight;
		}


		protected function resizeClues(textSize:Number):Number
		{
			var tf:TextFormat = new TextFormat("Arial Rounded MT Bold");
			tf.align = TextFormatAlign.CENTER;
			tf.size = textSize;
			tf.color = 0xFFFFFF;
			tf.bold = true;
			var i:int;
			var curY:Number = 0;
			var totalHeight:Number = 0;
			for( i =0; i< _words.length; i++)
			{
				_wordTextFields[i].setTextFormat(tf);
				_wordTextFields[i].y = curY;
				curY = curY + _wordTextFields[i].height + EXTRA_SPACE;
			}
			var startX:Number = 0;
			var startY:Number = 0;
			totalHeight = _wordTextFields[int(_words.length)-1].y + _wordTextFields[int(_words.length)-1].height
			if (totalHeight < _clueArea.height)
			{
				startY = (_clueArea.height - totalHeight) /2;
				curY = startY;
				for( i =0; i< _words.length; i++)
				{
					_wordTextFields[i].y = curY;
					curY = curY + _wordTextFields[i].height + EXTRA_SPACE;
				}
			}
			var textHeight:TextField = new TextField();
			textHeight.setTextFormat(tf);
			return textHeight.height;
		}


		protected function alertChoiceMade(e:StandardEvent):void
		{
			if(e.result) gameEnd();
		}


		protected function gameEnd():void
		{
			// for each word, return if it is circled or not
			for(var i:int =0; i< _words.length; i++)
			{
				// trace('wordsCircled at position ' + i + ':');
				// trace(_wordsCircled[i]);
				// if(_wordsCircled[i]) scoring.submitQuestionForScoring(_words[i].id, _words[i].word);
				if (_wordsCircled[i])
				{
					scoring.submitQuestionForScoring(_words[i].id, _words[i].word);
				}
				else
				{
					scoring.submitQuestionForScoring(_words[i].id, '');
				}
			}
			end(); // the game is over!
		}


		private function autoIndex(obj:Object):void
		{
			obj.tabIndex = _indexer;
			_indexer++;
		}


		private function adjustFontSize(field:TextField, form:TextFormat, maxW:Number):void
		{
			if(field.width > maxW)
			{
				var orig_size:Number = Number(form.size);
				while(field.width > maxW)
				{
					form.size = Number(form.size)-2;
					field.setTextFormat(form);
				}
				form.size = orig_size;
			}
		}
	}
}
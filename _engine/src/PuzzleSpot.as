/* See the file "LICENSE.txt" for the full license governing this code. */
package
{
	import flash.display.MovieClip;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	public class PuzzleSpot extends MovieClip
	{
		public static var Letter:Class
		public var spotText:TextField;
		private var halfSize:Number;
		public var useStyledBoxes:Boolean;
		public var xID:int; // locations for this in an array of other spots
		public var yID:int; // locations for this in an array of other spots
		function PuzzleSpot(squareSize:Number, tx:int, ty:int)
		{
			halfSize = squareSize/2;
			xID = tx;
			yID = ty;
			this.graphics.beginFill(0xffffff, 0.0); // NOTE: zero alpha. this is just for mouseovering
			this.graphics.drawRect(0,0, squareSize, squareSize);
			this.graphics.endFill();
			this.buttonMode = true;
			this.mouseChildren = false; // so the text on top doesn't prevent the button mode
		}
		public function addText(theText:String, fontSize:Number = 20):void
		{
			spotText = new TextField();
			spotText.embedFonts = true;
			spotText.text = theText;
			spotText.selectable = false;
			spotText.autoSize =  "left";
			var myTextFormat:TextFormat = new TextFormat("Arial Rounded MT Bold");
			myTextFormat.bold = true;
			myTextFormat.size = fontSize;
			myTextFormat.color = 0xFFFFFF;
			spotText.setTextFormat(myTextFormat);
			addChild(spotText);
			spotText.x =  width/2 - spotText.width/2;
			spotText.y = height/2 - spotText.height/2;
			this.tabEnabled = false;
		}
		public function getTextSize(letter:String = "q"):Number
		{
			spotText = new TextField();
			spotText.text = letter;
			spotText.selectable = false;
			spotText.autoSize =  "left";
			var myTextFormat:TextFormat = new TextFormat("Arial Rounded MT Bold");
			var tf:TextFormat = new TextFormat();
			var _cellValueSize:Number = 65;
			tf.size = _cellValueSize;
			spotText.defaultTextFormat = tf;
			spotText.setTextFormat(tf);
			while(spotText.width > (this.width) || spotText.height > (this.height))
			{
				tf = new TextFormat();
				tf.size = _cellValueSize -= 2;
				spotText.setTextFormat(tf);
				spotText.y = (this.height - spotText.height)/2;
			}
			return _cellValueSize;
		}
		public function get centerX():Number
		{
			return this.x + this.width/2
		}
		public function get centerY():Number
		{
			return this.y + this.height/2
		}
	}
}
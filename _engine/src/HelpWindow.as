package
{
	import flash.display.GradientType;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	public class HelpWindow extends Sprite
	{
		private var _instructionText:TextField;
		public function HelpWindow()
		{
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(275,225,0,0,0);
			this.graphics.beginGradientFill(GradientType.LINEAR, [0x1B313A,0x2D5B5B,0x1B313A],[1,1,1],[0,127,255],matrix);
			this.graphics.drawRoundRect(0,0,275,225,25);
			this.graphics.endFill();
			var instructionFormat:TextFormat = new TextFormat("Arial Rounded MT Bold", 12);
			instructionFormat.align = TextFormatAlign.LEFT;
			instructionFormat.color = 0xFFFFFF;
			_instructionText = new TextField();
			_instructionText.defaultTextFormat = instructionFormat;
			_instructionText.mouseEnabled = false;
			_instructionText.selectable = false;
			_instructionText.text = "Keyboard Navigation: Use the numpad and tab key to interact with the letter grid and word list." +
				"\n\n8: Navigate up." +
				"\n4: Navigate left." +
				"\n6: Navigate right." +
				"\n2: Navigate down." +
				"\n5: Choose and confirm." +
				"\n\nClick this window or press any key to continue.";
			_instructionText.wordWrap = true;
			_instructionText.width = 225;
			_instructionText.height = 175;
			_instructionText.x = _instructionText.y = 25;
			this.addChild(_instructionText);
			this.tabEnabled = false;
			this.focusRect = false;
			addEventListener(MouseEvent.CLICK, removeInstructions, false, 0, true);
			addEventListener(KeyboardEvent.KEY_DOWN, seedRemoveInstructions, false, 0, true);
		}
		private function seedRemoveInstructions(event:KeyboardEvent):void
		{
			removeInstructions();
		}
		private function removeInstructions(event:MouseEvent = null):void
		{
			this.visible = false;
			this.focusRect = true;
		}
	}
}
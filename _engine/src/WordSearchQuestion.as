package   
{
	import materia.questionStorage.Question;
	
	public class WordSearchQuestion extends Question
	{
		public function WordSearchQuestion(type:String="MC", options:Object=null, id:Number=0, question:String=null, answer:String=null)
		{
			super(type, options, id, question, answer);
		}
		public override function validAnswer():Boolean
		{
			return !empty(answer) && !singleChar(answer);
		}
		/**
		 *	Checks if string contains only a single character (after removing all special chars)
		 * 	Side effect: Sets error message specific to crossword answer
		 **/
		public function singleChar(str:String):Boolean
		{
			// Valid field must have at least one number or letter
			if(clean(str).length == 1)
			{
				options.errorMessage = "Your terms must be at least 2 characters long. Fix this problem to publish your game.";
				options.errorTitle = "Publish Error";
				return true;
			}
			return false;
		}
		protected function clean(str:String):String
		{
			//strip of all characters other than alphabet and numbers
			var nonAlphaNumeric:RegExp = /[^a-z0-9]/;
			return str.replace(nonAlphaNumeric, str);
		}
	}
}
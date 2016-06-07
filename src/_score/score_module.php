<?php
/**
 * Materia
 * It's a thing
 *
 * @package	    Materia
 * @version    1.0
 * @author     UCF New Media
 * @copyright  2011 New Media
 * @link       http://kogneato.com
 */


/**
 * NEEDS DOCUMENTATION
 *
 * The widget managers for the Materia package.
 *
 * @package	    Main
 * @subpackage  scoring
 * @category    Modules
  * @author      ADD NAME HERE
 */

namespace Materia;

class Score_Modules_WordSearch extends Score_Module
{
	public function check_answer($log)
	{
		if (isset($this->questions[$log->item_id]))
		{
			$q = $this->questions[$log->item_id];
			foreach ($q->answers as $answer)
			{
				if (strtolower($log->text) == strtolower($answer['text'])) return 100;
			}
		}

		return 0;
	}

}
<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group Wordsearch
 *
 */
class Test_Score_Modules_WordSearch extends \Basetest
{
	protected function _get_qset()
	{
		return json_decode('
			{
				"items":[
					{
						"items":[
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"IN YOUR FACE",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q1",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"Aj30902k hjlJE!?{#~",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q2",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	},
							{
						 		"name":null,
						 		"type":"QA",
						 		"assets":null,
						 		"answers":[
						 			{
						 				"text":"  TOTAlly RAAADDD! ",
						 				"options":{},
						 				"value":"100"
						 			}
						 		],
						 		"questions":[
						 			{
						 				"text":"q3",
						 				"options":{},
						 				"value":""
						 			}
						 		],
						 		"options":{},
						 		"id":0
						 	}
						],
						"name":"",
						"options":{},
						"assets":[],
						"rand":false
					}
				],
				 "name":"",
				 "options":{},
				 "assets":[],
				 "rand":false
			}');
	}

	protected function _make_widget()
	{
		$this->_asAuthor();

		$title = 'WORDSEARCH SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Word Search');
		$qset = (object) ['version' => 1, 'data' => $this->_get_qset()];

		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_check_answer()
	{

		$inst = $this->_make_widget();
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();

		$logs[] = json_decode('{
			"text":"IN YOUR FACE",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":10
		}');
		$logs[] = json_decode('{
			"text":"Aj30902k hjlJE!?{#~",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":11
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":12
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":"0",
			"game_time":13
		}');

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(66.666666666667, $this_score[0]['overview']['score']);
	}

}
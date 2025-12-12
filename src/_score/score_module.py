import logging
from scoring.module import ScoreModule

logger = logging.getLogger("django")

class WordSearch(ScoreModule):

    def __init__(self, play=None):
        super().__init__(play)

    def check_answer(self, log):
        q = self.get_question_by_item_id(log.item_id)
        if q is not None:
            for answer in q["answers"]:
                if log.text.lower() == answer["text"].lower(): return 100
        return 0
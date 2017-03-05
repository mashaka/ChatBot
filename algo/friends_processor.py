#####
# Author: Maria Sandrikova
# Copyright 2017
#####

from typing import List, Tuple
import json
import logging

from .intersection import Intersection
from .tip import Tip
from .tools import UpdateInfo, DataNLP, UpdateType

module_logger = logging.getLogger('FriendsProcessor')

NOT_FOUND = -1

ID = 'id'
NAME = 'name'

DATA = 'data'


class FriendsProcessor:

    def __init__(self, data: Tuple):
        self.data = data

    def process(self) -> List[Intersection]:
        self.intersections = []
        for friend in self.data[DATA]:
            self.intersections.append(
                self.get_intersection(
                    friend
            ))
        module_logger.info('Find {} intersections'.format(len(self.intersections)))
        return self.intersections

    def get_intersection(self, friend: dict) -> Intersection:
        desc = 'You have mutal friend {}'.format(friend[NAME])
        weight = 1
        content = (None, None)
        tips = [
            Tip(
                'It seems that we both know {}. How did we meet? :)'.format(
                    friend[NAME]
                ),
                1
            ),
            Tip(
                'It seems that we both know {}. It is cool!'.format(
                    friend[NAME]
                ),
                1
            )
        ]
        return Intersection(desc, weight, content, tips)

    def update(self, data: UpdateInfo, dataNLP: DataNLP):
        if UpdateType.DELETE_TIP == data.type:
            # TODO
            pass
        elif UpdateType.INCOME_MSG == data.type:
            # TODO
            pass
        elif UpdateType.OUTCOME_MSG == data.type:
            # TODO
            pass
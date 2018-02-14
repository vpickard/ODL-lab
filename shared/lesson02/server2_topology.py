#!/usr/bin/python

from common import createTopology


createTopology(
    's2',
    [
        [
            'red2',
            {
                'ip': '10.100.5.20',
                'mac': '00:00:0a:64:05:20'
            }
        ],
        [
            'blue2',
            {
                'ip': '10.100.5.21',
                'mac': '00:00:0a:64:05:21'
            }
        ]
    ]
)

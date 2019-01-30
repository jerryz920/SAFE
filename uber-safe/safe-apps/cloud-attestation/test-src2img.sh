#!/bin/bash

curl -H "Content-Type:application/json" -XPOST http://localhost:7777/postSourceProperty -d   '{ "principal": "IamBad", "otherValues": ["source4", "prop2", "value2"]}'
curl -H "Content-Type:application/json" -XPOST http://localhost:7777/postImageProperty -d    '{ "principal": "IamBad", "otherValues": ["image4", "conf", "propx"]}'
curl -H "Content-Type:application/json" -XPOST http://localhost:7777/postImageSource -d      '{ "principal": "IamBad", "otherValues": ["image4", "source4"]}'
curl -H "Content-Type:application/json" -XPOST http://localhost:7777/checkSourceProperty -d  '{ "principal": "IamBad", "otherValues": ["image4", "prop2", "value2"]}'

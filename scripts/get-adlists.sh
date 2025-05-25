#!/bin/bash

workdir=$(pwd)
sourcespath=$workdir/../sources/adlist-sources.txt
tempdir=$workdir/../temp/

rm -f $tempdir*

wget -i $sourcespath -P $tempdir

rename 'y/A-Z/a-z/' $tempdir*

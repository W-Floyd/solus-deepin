#!/bin/bash

source 'functions.sh'

# feed_list contains a list of packages I have RSS feeds for.

lsdir | grep -v common | grep -v 'git' | grep -v '\.stfolder' | sed 's|^\./||' | grep -Fxvf 'feed_list'

exit

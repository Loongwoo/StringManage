#!/bin/sh

#  find.sh
#  StringManage
#
#  Created by kiwik on 1/16/16.
#  Copyright © 2016 Kiwik. All rights reserved.

KEYWORDS="$1"

#xargs -0 egrep  --with-filename --line-number --only-matching "^.*?\"($KEYWORDS)\".*?$"
xargs -0 egrep -H -n -o "^.*?\"($KEYWORDS)\".*?$"

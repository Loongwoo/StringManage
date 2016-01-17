#!/bin/sh

#  find.sh
#  StringManage
#
#  Created by kiwik on 1/16/16.
#  Copyright © 2016 Kiwik. All rights reserved.

KEYWORDS="$1"

# New matching strategy handles colon noise more gracefully, supports keywords in multi-line comments, supports mid-line keywords, and generally leaves less clean-up work for Obj-C
xargs -0 egrep -H -n -o "^.*?\"($KEYWORDS)\".*?$"
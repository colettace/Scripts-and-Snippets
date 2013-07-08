#!/usr/bin/env python

import pyinotify
import os
import stat

from eckley_pharynx import *

wm = pyinotify.WatchManager()

# create a notifier that checks the target directory every 5 seconds
handler = EckleyPharynxHandler()
notifier = pyinotify.Notifier( wm, read_freq=5, default_proc_fun=handler )

# The reason why we only check every 5 seconds is that we coalesce 
# multiple open-write-close notifications 
notifier.coalesce_events()

wm.add_watch( '/home/eckleyd/RealTimeClassification/', pyinotify.IN_CLOSE_WRITE )# , rec=True, auto_add=True ) 

try:
	notifier.loop()
finally:
	notifier.stop()

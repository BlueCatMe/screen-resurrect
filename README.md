# Disclaimer
This work is based on script from [BrainScraps Wiki][1] and published under CC-BY-SA.

# Features
Briefly, this script just helps restore the static environment of screen sessions, but not continuous unfinishing jobs. As a result, this should be executed just before rebooting the machine.

* Snapshot all screen sessions
* Restore saved screen sessions
  * create a session with the same name
  * create window with the same number
  * change the current working directory back for each window
  * Log you into your previously loggered in host via ssh

# Settings
There are four main settings with this script.

## Config Variables
```
# maximum snapshot screen, bigger value would take longer time because it tries to snapshot all window # even this window does not exist.
max_win=15
# maximum backup number.
max_backups=12
# ignore session pattern.
ignore_sessions="hosts"
# where to put session snapshot
backup_dir=~/.screen-resurrect/snapshot
```

# Limitation
This script could only snapshot *STATIC* status, says there is no running process, because it needs to execute a command to retrieve screen window information.

[1]: https://brainscraps.fandom.com/wiki/Resurrecting_GNU_Screen_Sessions_After_Reboot

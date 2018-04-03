# Solus Deepin

## I'm a dragon, hear me roar!

### It is *probably* broken, and could remain so.

This is an exercise in packaging Deepin.
It is not ready - nor intended - for production use, and it *will not* go into the Solus repos.

***

A collection of packages meant for getting Deepin running on Solus.
Pretty much working as expected.

### TODO

**Apps that run on an otherwise stock Solus (Budgie) install**

- [x] Calculator
- [x] Calendar (though it's pretty much useless)
- [x] File Manager
- [x] Image Viewer
- [ ] Movie (still need to build)
- [x] Music
- [ ] Picker (may not be possible?)
- [ ] Screen Recorder (may not be possible?)
- [x] Screenshot
- [x] System Monitor
- [x] Terminal
- [x] Voice Recorder

***

#### `deepin-daemon`

Need to look into packaging:
* Miracast/Miracle Cast -  [Tarball](https://github.com/linuxdeepin/miraclecast/archive/1.0.8.tar.gz)
* `imwheel` - [Tarball](https://sourceforge.net/projects/imwheel/files/imwheel-source/1.0.0pre12/imwheel-1.0.0pre12.tar.gz/download)

Add as rundep:
* `rfkill` (used with Bluetooth)

Look into:
* missing files from `/usr/share/deepin-default-settings`

#### `startdde`

Look into:
* `startmanager.go:90: open /usr/lib/UIAppSched.hooks/launched: no such file or directory`

#### Misc.

* validate core packages and strip un-needed rundeps (and add those that are required). This one is hard though, we'll see.
* check if `deepin-music` is using vendored libraries and transition off of them if possible.  
* check on how to make sure `setcap cap_kill,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+ep /usr/bin/deepin-system-monitor` is run so that network speed monitoring may be achieved.
* validate touchpad swipe shortcuts (specifically, 4/5 fingered ones, which my current machine does not support), see if I need to drop the Arch patch to `deepin-daemon` (it seems to be a decision to disable 3 finger tapping being intercepted, leaving it open for, say, following links, or pasting, the former being something I use often)
* investigate why first login (at least in VM) has a white bg, as you have to fish for a button.
* check if I can plumb in the control center to link to the Solus SC for updating, and if not, disable the section entirely.
* see if I can force disable the disablement of `deepin-mutter`, temporarily, for the sake of VM testing?
* ``dde-dock` often crashes when changing USB devices, need to investigate.

### Updates

*2018-04-03.1* - Got a few updates done (was busy over the weekend, and it wasn't urgent, so...), things should be up to date again. I find a few random application crashes now and again, need to determine if it's to do with my building of the DE (probably not), the DE itself (maybe), or the apps in particular (more likely).

***

*2018-03-26.2* - Did a full rebuild with my scripts, ironed out the last of the run/build_dep file issues. Also sorted out which apps run solo (and made sure they had the right rundeps), and *started* on a bit of making sure lower level components actually have the rundeps they need (`deepin-daemon` so far has been tested a little)

***

*2018-03-26.1* - Things are going to slow down now, reasons being:
* I've gotten the main desktop done, it's mainly peripheral apps now. If updates come out, I'll try to make sure I upgrade and all that.  
* I'm going to be busy (getting a job), I won't have a ton of time to dump into this. Make no promises, tell no lies, aye?
* Internet isn't real good for me where I'm at now, it'll be a few months before that might change for the long run.

I am running this desktop fully at the moment, so I *am* testing it through use, but it also means I might not catch corner-case features that I don't know about.
This project is for me after all, I only feel motivated about what's important to me.

***

*2018-03-25.1* - Redid a lot of my build script to work correctly. Opted to force `LIB_INSTALL_DIR` and `PREFIX` on all similar Deepin packages, even if they don't *strictly* need it. Having done that has fixed an issue with the dock not finding a file for the power menu.

***

*2018-03-24.2* - Got my build script set up, should now help insulate me from accidentally inheriting deps that are not in my lists. Will in due course rebuild all packages to validate my run/build_dep files. For now though, I've updated everything! 

***

*2018-03-24.1* - Gone back through all my packages, spent way too long fighting `treefrog-framework`, but have no un-commited files or changes now. Will start upgrading more things in the morning...  
Some things of note:
* If I don't include a rundep that the arch repos do, it's because I can't see why I need it. I will slowly try to add these back in as I determine why I need them
* All things considered, the desktop is running really well. Niggling issues include:
  * ~~~Dock power menu does not work, can't see why (that is, the error message says it can't find a file that I think exists)~~~
  * Dock/Launcher/Control Center are sporadic about HiDPI support when launched by startdde (that is, at login). If manually launched from the terminal, they're fine. Need to investigate what flags might cause that.

***

*2018-03-23.1* - Still more combing through. Trying to make sure `startdde` has all the correct deps to run the DE. Mostly working? Running under a VM to test stock has issues since window manager stuff gets knocked about for the sake of performance (and perhaps rightly so, but still).

***

*2018-03-22.1* - Combing back through with a locked set of packages (there are some updates floating out there - I'm leaving them until I rebuild the whole stack). Have pretty much made sure the current (normally working, i.e - not the image viewer) desktop apps have all the correct deps to run solo.

***

*2018-03-21.2* - So, yeah, I got the critical bits in to make things run now. [M'pics](https://imgur.com/a/LoZGW). Key bit was `deepin-qt5dxcb-plugin` to tie things together. Confusing name meant I kept overlooking it for a long time.

***

*2018-03-21.1* - I've been working through, trying to get a functioning desktop. Takes a while though...

***

*2018-03-10.1* - I've sorta gotten past the point of needing to watch the Arch repos, so maybe I'll do more here?
Thinking I'll be ironing things out, package by package (i.e. Terminal and all deps, file manager and all deps, etc.)
Ideally, I will keep rundeps to a minumum, since someone might only want one app.

***

*2018-03-05.1* - I poked some more, got past some issues, still stuck on some things.

***

*2018-03-01.1* - I tried poking at this some more, but Arch is lagging upstream and I can't be bothered to work on this too much. The effort of attempting to build *and update* and desktop stack at the same time is beyond me. Maybe someday...

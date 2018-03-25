# Solus Deepin

## I'm a dragon, hear me roar!

### It *IS* broken, and will remain so.

This is an exercise in packaging Deepin.
It is not ready - nor intended - for actual use, and it *will not* go into the Solus repos.

***

### TODO

* ensure all reasonable desktop apps may run without interfering with another DE (file-manager possible exempt).  

***

A collection of packages meant for getting Deepin running on Solus. Almost entirely lifted from the Arch repo.

Initially put together over a week or so, since worked on off and on for months, trying to learn a bit and fill time. I don't see myself seeing this to any level of polished completion, I'm surprised I've gotten as far as I did.

***

*2018-03-25.1* - Redid a lot of my build script to work correctly. Opted to force `LIB_INSTALL_DIR` and `PREFIX` on all similar Deepin packages, even if they don't *strictly* need it. Having done that has fixed an issue with the dock not finding a file for the power menu.

*2018-03-24.2* - Got my build script set up, should now help insulate me from accidentally inheriting deps that are not in my lists. Will in due course rebuild all packages to validate my run/build_dep files. For now though, I've updated everything! 

*2018-03-24.1* - Gone back through all my packages, spent way too long fighting `treefrog-framework`, but have no un-commited files or changes now. Will start upgrading more things in the morning...  
Some things of note:
* If I don't include a rundep that the arch repos do, it's because I can't see why I need it. I will slowly try to add these back in as I determine why I need them
* All things considered, the desktop is running really well. Niggling issues include:
  * Dock power menu does not work, can't see why (that is, the error message says it can't find a file that I think exists)
  * Dock/Launcher/Control Center are sporadic about HiDPI support when launched by startdde (that is, at login). If manually launched from the terminal, they're fine. Need to investigate what flags might cause that.

*2018-03-23.1* - Still more combing through. Trying to make sure `startdde` has all the correct deps to run the DE. Mostly working? Running under a VM to test stock has issues since window manager stuff gets knocked about for the sake of performance (and perhaps rightly so, but still).

*2018-03-22.1* - Combing back through with a locked set of packages (there are some updates floating out there - I'm leaving them until I rebuild the whole stack). Have pretty much made sure the current (normally working, i.e - not the image viewer) desktop apps have all the correct deps to run solo.

*2018-03-21.2* - So, yeah, I got the critical bits in to make things run now. [M'pics](https://imgur.com/a/LoZGW). Key bit was `deepin-qt5dxcb-plugin` to tie things together. Confusing name meant I kept overlooking it for a long time.

*2018-03-21.1* - I've been working through, trying to get a functioning desktop. Takes a while though...

*2018-03-10.1* - I've sorta gotten past the point of needing to watch the Arch repos, so maybe I'll do more here?
Thinking I'll be ironing things out, package by package (i.e. Terminal and all deps, file manager and all deps, etc.)
Ideally, I will keep rundeps to a minumum, since someone might only want one app.

*2018-03-05.1* - I poked some more, got past some issues, still stuck on some things.

*2018-03-01.1* - I tried poking at this some more, but Arch is lagging upstream and I can't be bothered to work on this too much. The effort of attempting to build *and update* and desktop stack at the same time is beyond me. Maybe someday...

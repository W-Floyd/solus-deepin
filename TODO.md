### TODO

**Apps that run on an otherwise stock Solus (Budgie) install**

- [x] Calculator
- [x] Calendar (though it's pretty much useless)
- [x] File Manager
- [x] Image Viewer
- [x] Movie (VM lacks the correct acceleration I believe, works fine bare metal)
- [x] Music
- [ ] Picker (may not be possible?)
- [ ] Screen Recorder (may not be possible?)
- [x] Screenshot
- [x] System Monitor
- [x] Terminal
- [x] Voice Recorder

***

#### `deepin-daemon`

Look into packaging:
* Miracast/Miracle Cast -  [Tarball](https://github.com/linuxdeepin/miraclecast/archive/1.0.8.tar.gz)

Currently stuck with:
```
/home/build/YPKG/root/deepin-miraclecast/build/miraclecast-1.0.8/res/dispctl.vala:807.2-807.18: error: 1 missing arguments for `void GLib.Application.set_default (GLib.Application?)'
	app.set_default();
	^^^^^^^^^^^^^^^^^
Compilation failed: 1 error(s), 2 warning(s)
```

Will try with upstream `miraclecast` and hopefully it'll work.

Add as rundep:
* `imwheel` (used for mouse wheel settings)
* `rfkill` (used with Bluetooth)

Look into:
* missing files from `/usr/share/deepin-default-settings`, see `deepin-default-settings`.

#### `deepin-desktop`

Known tasks:
* Rundeps are mixed up - startdde is probably what wants many of these, desktop is just one of them. This falls under the general mucking out of rundeps that needs to go on.

#### `deepin-default-settings`

Need to package ([Link](https://github.com/linuxdeepin/default-settings)), but be selective - there's a bunch of stuff in there that we *don't* need, or want.
Will need a bit of poking, as such.

#### `deepin-dock` / `deepin-launcher`

Need to investigate:
* using a different icon theme does not change immediately (possibly only when HIDPI is working?)

#### `deepin-file-manager`

Look into packaging:
* [dde-file-manager-integration](https://cr.deepin.io/admin/projects/dde/dde-file-manager-integration)

Need to investigate:
* cannot mount MTP Android device (can only test with Samsung Galaxy S5 currently, but that works under GNOME)

Known tasks:
* `/usr/bin/dde-xdg-user-dirs-update` is not executable. Need to see why and possibly remedy that (as it's a script, it may be run via bash, instead of directly).

#### `deepin-image-viewer`

It breaks Krita (amongst other things, probably).
This has been known to upstream for some time.

#### `deepin-qt5config`

[What is it?](https://cr.deepin.io/#/admin/projects/deepin-qt5config)
Do I need it?

#### `startdde`

Look into:
* `startmanager.go:90: open /usr/lib/UIAppSched.hooks/launched: no such file or directory`

#### Misc.

* validate core packages and strip un-needed rundeps (and add those that are required). This one is hard though, we'll see.
* check if `deepin-music` is using vendored libraries and transition off of them if possible.  
* check on how to make sure `setcap cap_kill,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+ep /usr/bin/deepin-system-monitor` is run so that network speed monitoring may be achieved.
* validate touchpad swipe shortcuts (specifically, 4/5 fingered ones, which my current machine does not support), see if I need to drop the Arch patch to `deepin-daemon` (it seems to be a decision to disable 3 finger tapping being intercepted, leaving it open for, say, following links, or pasting, the former being something I use often)
* investigate why first login (at least in VM) has a white bg, as you have to fish for a button.
* see if I can force disable the disablement of `deepin-mutter`, temporarily, for the sake of VM testing?
* `dde-dock` (actually, almost eveything Deepin related) often crashes when changing USB devices, need to investigate. Specifically, mouse and keyboard (HDD is okay).
* `deepin-movie` has 'volume down' when it should have 'Volume down', in keyboard shortcuts.
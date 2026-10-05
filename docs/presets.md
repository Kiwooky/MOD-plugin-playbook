# Presets

Factory presets ship inside the bundle and show at the top of the plugin's preset list on every unit that installs it. People can load them but not overwrite them.

## Where presets made on a unit live

mod-ui saves every user preset as its own small bundle in `/root/.lv2/<instance>-<Preset_name>.lv2/` on the unit: a manifest plus one TTL holding one value per port symbol, and `lv2:appliesTo` the plugin URI it was saved with. They survive reinstalling the plugin (verified on a Duo, MOD OS 1.14). They do **not** follow a URI change: a plugin with a new URI is a different plugin to the MOD, so presets made on a prototype must be carried over.

## Fetch them

With the unit on USB (password `mod`), list them, then copy them to the Desktop in one go:

```sh
ssh root@192.168.51.1 "ls /root/.lv2"
ssh root@192.168.51.1 "cd /root/.lv2 && tar czf - <name>-*.lv2" > ~/Desktop/presets.tgz
```

The second form puts the file somewhere the person can find. **If someone uses `scp` from a recent Mac, it needs `-O`:** without it, macOS `scp` speaks SFTP, which the MOD doesn't serve, and fails with "subsystem request failed on channel 0" (verified). The password is typed blind; a mistyped one reads as "Permission denied". `scp root@192.168.51.1:file .` leaves it in whatever folder the terminal was in, which people often can't find. Grab other plugins' presets in the same command if they'll be needed later.

## Ship them

```sh
python3 tools/presets_from_device.py bundle/<name>.lv2 ~/Desktop/presets.tgz \
    [--from-uri <old URI>] [--exclude hold,freeze]
```

It writes `presets.ttl`, lists each preset in `manifest.ttl` (re-runnable: it replaces its own block), reports symbols the plugin no longer has and ports a preset doesn't mention (those keep their current value when it loads), then reads the bundle back and checks every value. MultiPlay: 10 presets, 90 values, 0 differences; `lv2info` lists all ten.

- **Leave out footswitch states** (`--exclude`): hold, freeze, slam, anything momentary. A preset saved with Hold on would freeze whatever is in the buffer when loaded. The bypass port is always left out.
- **Older presets** made before a port was added lack it; it keeps its current value (the default on a fresh instance). Check the report.
- **Use the label, not the folder name.** Renaming a preset on the unit changes its `rdfs:label` but not its bundle folder: Taj Mahal's `taj_mahal-Early_wobble.lv2` held "Negative reflections". `presets_from_device.py` reads the label; check the names with the person anyway. Verified on a Duo.
- **Ship the reference settings as a named preset too.** For a recreation, add the original's own setting (Taj Mahal: "Taj Mahal (1988 factory)") so people can always get back to it after trying the others.
- Bump the version: presets are plugin data, cached per version like the face.

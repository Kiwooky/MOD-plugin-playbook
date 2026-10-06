# Known MOD-side issues (they look like plugin bugs)

Check here before debugging your plugin.

## Stale plugin data or the default "tuna can" thumbnail

The MOD UI caches plugin info and images by URI + version. Same version after a reinstall = old face, old ports, old thumbnail. **Fix:** bump the version and reinstall; hard-refresh (Cmd/Ctrl+Shift+R). **Check:** `http://192.168.51.1/effect/get?uri=<uri>&nocache=1` shows what is really installed. Read its `version`, `stability` and `bundles` fields: the hall reverb still showed the tuna can after "reinstalling v1.0.2" because the Duo held a `version 0.0`, `stability: experimental` build (an older file had been uploaded); a single bundle ruled out duplicates. `experimental` also means `lv2:minorVersion` is 0. Rebooting the Duo doesn't help: the stale image is in the browser's cache. Verified on a Duo.

## The web UI stops showing MIDI changes and meters (MOD OS 1.13.5 and 1.14 RC)

A MIDI-learned control works in the audio, but no browser shows the change; meters freeze too. On-device footswitch changes still show. mod-host only sends feedback after mod-ui sends `output_data_ready`, which waits for a browser to confirm `data_ready <counter>`; that handshake can stall.

- **Reproducible on 1.14.0 RC (build 3366):** put the computer to sleep with the MOD UI open, wake it, reload when asked. The pedalboard looks fine, but feedback never updates.
- **Workaround:** close every MOD UI tab (or reboot), or run in the MOD tab: `javascript:(()=>{for(let n=0;n<=5000;n++)ws.send('data_ready '+n)})()`. Mismatched counters are ignored, so it's harmless, but only use it when updates have actually stopped.

## Old iPads can't load the MOD OS 1.14 UI

1.14's web UI uses optional chaining (`a?.b`), which Safari parses only from iOS 13.4. On older iOS, `modgui.js` and `pedalboard.js` fail to parse and the UI never starts; every iOS browser uses Safari's engine. Patching those lines makes it load, but slowly. Use a tablet on iOS 13.4 or later.

## Cookbook documentation gaps (as of Oct 2026)

- The cookbook's pre-flight says ControlPort count = `kParameterCount` − 1; it should be **equal**.
- Its examples omit the required `opts:options` / `urid:map` features.
- The 128 KB `export` limit isn't mentioned.
- There's no version-bump guidance.

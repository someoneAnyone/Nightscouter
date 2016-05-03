# Nightscouter
An Native iOS app used for displaying CGM data from a Nightscout website data. To build and run for your self, you'll need to have a valid Apple Developer account to generate the proper entitlements needed to share data between the Today Widget and the main App.

Don't want to build and install on your own? Nightscouter is now available on the [Apple AppStore] (https://itunes.apple.com/us/app/nightscouter/id1010503247?ls=1&mt=8).

## Requirements
- Xcode Version 7.3 with Swift 2.2
- iOS 8.4 or better (requires 9.2 for Watch Support)
- watchOS 2.2 if you want to use  Watch
- iPhone 5, 5s, 6, 6 Plus (Will work on iPads but not specifically optimized for it yet)
- Nightscout Remote Monitor versions 0.7.0 & 0.8.0 (https://github.com/nightscout/cgm-remote-monitor)
- Dexcom CGM (other uploaders are supported but might not be tested)

## Features
- Multiple Nightscout Remote Monitor web sites can be added and viewed within the App.
- Get at a glance information from the Notification Center using the Nightscouter Today Widget.
- Uses the settings and configurations for blood sugar thresholds from your remote monitor. No need to enter them in again.
- Force touch on the app icon for application shortcuts.
- Background for application updates. (updates when Apple wakes the app)
-  Watch App for quick acess to Nightscout data. This includes an App, Glance, and complications. You can pick which site to use for the complication and "at a glance" views on the watch by force touching the "bg compas" in the watch app. Please note that complications will only update hourly due to limitations from Apple.


## Future Plans
* [x] ~~Today Extension~~ *Added [#12](https://github.com/someoneAnyone/Nightscouter/commit/9b1120726ea64faca3b0dd859b7caa8d32e4b797)*
* [x] ~~Apple Watch Extension / App (targeting watchOS2)~~
* [ ] Push Notifications
* [ ] Better layouts for iPad
* [ ] Allow users to ovveride server settings like units, custom titles, and show hide features.
* [x] Support other CGM devices like Medtronic
* [ ] tvOS support
* [ ] macOS notification center support.
* [ ] Unit tests
* [ ] Alarming based on BG thresholds


##Questions?
Feel free to post an [issue].
[issue]: https://github.com/someoneAnyone/Nightscouter/issues

##License
Nightscouter is available under the MIT license. See the LICENSE file for more info.
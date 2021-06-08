# Working with Overlays and Parental Controls in tvOS

Add interactive overlays, parental controls, and livestream channel flipping using a player view controller.

## Overview

- Note: This sample code project is associated with WWDC 2019 session [503: Delivering Intuitive Media Playback
with AVKit](https://developer.apple.com/videos/play/wwdc19/503/).

## Configure the Sample Code Project

Only navigation from live streaming supports channel flipping, so you need to replace the assets in this sample with your live content to demonstrate this behavior. 

By default, the sample demonstrates automatic support for parental controls. Activate parental restrictions by following the steps below:

1. Go to Settings > General > Restrictions.
2. Turn on Restrictions.
3. Set a passcode (1111 for demonstration purposes; remember this passcode).
4. Scroll down to the Allowed Content section.
5. Select Movies and/or TV Shows.
6. Set a restriction level (for example, PG or PG-13 if you are in the United States).

The first demo video has a rating of PG, and the second has a rating of PG-13. You can find or edit these ratings in `MainViewController.swift`.

This sample also demonstrates explicit support for parental restrictions by directly calling [`playerItem.requestPlaybackRestrictionsAuthorization(_ completion)`][1]. You can test explicit support by changing the value of `checkParentalControlsExplicitly` in the sample.

[1]: https://developer.apple.com/documentation/avfoundation/avplayeritem/3152863-requestplaybackrestrictionsautho

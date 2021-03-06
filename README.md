Juker

[development]: https://github.com/marc-maguire/Juke/tree/development
**Note: On a day to day basis, [development] will be the most up-to-date branch.
- App will not build if cloned. We have kept the Spotify Key private. You will need to add your own .swift file that includes redirect URL and a ClientID strings. Our app references a configCreds file, but this file is not included on Github.

Lighthouse Labs Final Project - By Marc Maguire and Alex Mitchell

Timeline:

Ideation and initial research began on June 10th at 1:00PM.
by 4:00 PM on the 11th we had decided to move forward with the idea of building a social jukebox.
We presented the app 19 days later on June 29th at 4:00 PM.
Nearing the end of our iOS Immersive Bootcamp experience at Lighthouse Labs, Alex and I teamed up test out how far we could push the skills
that we gained in the first 6 weeks of the course. Below were the goals that we set out for ourselves.
 When we sat down to plan out this project, we came up with the following goals:

- Consume an API (We went with Spotify)
- Utilize a third party framework with Cocoa Pods (Alamofire, Alamofireimage, MGSwipeTableCell and PlaybackButton)
- Connect our users using a server so that they could instantly share songs between eachother (we ended up utilizing Apples
  Multipeer Connectivity framework to accomplish this goal)
- Build a simple, streamlined user experience that is easy to understand and use
- Control the scope of the project so that we arrive at a MVP 48 hours prior to our presentation, allowing us to polish the UI 
  as much as possible.
The Result:  An app that allows users to instantly, without the need of a server or new account, connect to other app users at
a party and collaborate in real time over a central music playlist. Users can add songs to the public queue, dislike songs (which
could result in the song being removed from the queue) and like songs that they want added to their person Spotify saved songs 
for future viewing.

Moving forward:

- Add a backend to our app that would communicate with Spotify servers to refresh our access tokens. Currently the tokens are
  only good for 60 minutes.
- Fix remaining high priority issues in the tracker.
- Submit to the App Store!

### Screenshot:
![screenshot](Juker/screenshot/juker_screenshot.png)

Helvetica Neue
==========
[![Available on the App Store](https://devimages.apple.com.edgekey.net/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg)](https://itunes.apple.com/us/app/helvetica-neue-native-open/id931789125?mt=8)

This is a re-imaginging of Hacker News for the consumer, not the producer. This iOS app shows the top 100 HN stories... live.
No need to refresh as the stories just update on their own. You can also filter and sort stories how you want to see them. The app uses the v0 API which was released in October 2014.

[![Short Demo](http://img.youtube.com/vi/Ik40mgPL8FQ/0.jpg)](http://youtu.be/Ik40mgPL8FQ)

Focal Points (In order of priority)

- [x] See the news that you want to see and how you want to see it.
- [ ] Take advantage of iOS hardware to enhance the user experience.
- [ ] Recreate the basic online experience.

Based on these focuses, I am working / planning on these features.

- [x] Remove the need to refresh and keep everything as close to realtime as possible.
- [x] Sort and filter any story you have read or don't like.
- [ ] Cache stories to the device for offline reading purposes.
- [ ] Intelligent location based caching functionality.
- [ ] BTLE enabled IRL chat notifications.
- [ ] Comments.

#Why create another HN Client?

Hacker News too often the top page gets clogged up by what everyone agrees is awesome. On the web, I rarely, scroll past the top 30.
That means 70 of the best stories are hidden from me at any given time.
This app is meant to expose the consumers of Hacker News to the larger library of interesting articles at any given time.
More over, it is meant to streamline the experience for the constant consumers of Hacker News.
In other words, this solution should increase the signal to noise ratio (Increase the interesting stories, remove the stories you do not want).

##On Comments:

I believe comments are a huge part of what makes Hacker News great.
However, on a mobile device for which there is no comment *creation* API the unique use of hardware is more interesting.
Adding Geofencing, and hyperlocal chat opportunities are cooler opportunities.
That being said, this App will not hit 1.0 until you can view comments.

#Building

- Clone.

```sh
git clone https://github.com/wrkstrm/HelveticaNeue.git
```

- Initiate submodules.

```sh
git submodule update --init --recursive
```

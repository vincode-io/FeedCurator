![Feed Curator Icon](images/Feed-Curator-Banner.png)

# 

Feed Curator is a macOS application that makes it easier to OPML listings
of blog feeds.  It is a companion app to 
[Feed Compass](https://github.com/vincode-io/FeedCompass).  You can use
Feed Curator to create, publish, and maintain the blog listings that 
users of Feed Compass see.  It can also be used as a standalone OPML feed editor.

## Download

Feed Curator is currently in development.  Beta testing releases coming soon.

## Features

- Create and edit OPML feed files
- Feed Finder - Just drag a page URL to Feed Curator and it will find the
feed for you
- Automatic population of feed details: Title, URL, and Home Page
- Drag and drop rearrangement of feeds (in development)
- Free publishing of OPML files using Github Gist (in development)
- Easy submission to Feed Compass for inclusing in future release (in development)

## Feedback

Have something you want to say about Feed Curator?  Leave a comment in our
[Feedback](https://github.com/vincode-io/FeedCurator/issues/1) issue.

## Contributing

Pull requests are welcome.  If you are a non-technical person and want to
contribute you can file bug reports and feature requests on the 
[Issues](https://github.com/vincode-io/FeedCurator/issues) page.

## Building

From the command line run the following commands:
```
git clone https://github.com/vincode-io/FeedCurator.git
cd FeedCurator
git submodule init
git submodule update
```

You can now open the Feed Curator.xcodeproj project.  You will have to fix
the project signing before building and running.

## Licence

MIT Licensed

## Credits

Many thanks to [Brent Simmons](http://inessential.com) releasing
[NetNewsWire](https://github.com/brentsimmons/NetNewsWire) as an Open 
Source project.  There is a lot of NetNewsWire DNA in Feed Curator.

# The Podcasterizer
an overly-complicated bash script which uses a combination of [yt-dlp](https://github.com/yt-dlp/yt-dlp), [ffmpeg](https://ffmpeg.org/), [id3v2](https://id3v2.sourceforge.net/) and [curl](https://curl.se/) (along with some other stuff) to download and generate audio files for use with self-hosted podcast software like [dir2cast](https://github.com/ben-xo/dir2cast)

this bash script does the following:

- creates its own data and logs directory in the location the script is first run
- uses a custom useragent string when retrieving media with yt-dlp
- grabs whatever video it can find on the other end of a URL and then tries to convert it into an mp3 file
- adds some additional metadata if it's available
- tracks previously downloaded URLs to avoid duplicates in the podcast feed
- tracks the latest episode number and then increments same on each new episode so the podcast feed makes logical sense
- generally just works at a very basic level without becoming overly wtf


this bash script does not:

- do a whole bunch of error checking
- install any dependencies like yt-dlp, dir2cast, Docker, etc.
- check if all the dependencies are installed
- complain too much if something goes wrong
- feel pity or remorse or fear


first version uploaded 16 april 2023, currently working with:
- [dir2cast](https://github.com/ben-xo/dir2cast), a self-hosted podcast app
- [Docker](https://www.docker.com/), a container manager
- [this docker-compose.yml file](https://github.com/ben-xo/dir2cast/blob/main/docker-compose.yml) which Ben XO quite helpfully provides in the dir2cast code repo, which handles the dir2cast webserver and PHP stuff
- a wee NUC running Debian 10 on my desk, which gives all of the above a place to live
- my podcast app on my phone, which downloads new episodes of whatever the heck I end up seeing online which would work better as an mp3 file instead of a YT video (see [here](https://www.youtube.com/watch?v=OOxWQ9CF-y4) for a specific example and then let your imagination go wild with the possibilities of what else could be turned into a podcast... :musical_note:)


*readme last updated 17 apr 2023 wb*



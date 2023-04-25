#!/bin/bash

## The Podcasterizer 
## an overly-complicated bash script which uses a combination of yt-dlp, ffmpeg, id3v2 and curl
## to download and generate audio files for use with self-hosted podcast software like dir2cast
## https://github.com/cameronfrye/thepodcasterizer

##### set those variables, folks
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/root/

### https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
### sneaky stuff
SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

### storing stuff that we probably want to keep
### like previous hash checking results and periodical backups
DATASTORE="$SCRIPTDIR/data"
TODAY=`date +%Y%m%d` # ISO standards ftw
DATADIR="$DATASTORE/$TODAY"
DATAFILE=`date +%s` # TBD: epoch date to use for each run

## podcast stuff, for use with id3v2 and storing audio files
PODCASTNAME="the generic podcast name podcast"
#PODCASTNAME="The willb Podcast"
PODCASTDIR="$SCRIPTDIR/podcast"
EPISODEFILE="$PODCASTDIR/latestepisode.txt" # for numbering the new audio files as they arrive

## logging stuff
LOGSTORE="$SCRIPTDIR/logs"
YTDLPLOG="$LOGSTORE/yt-dlp.log"
ERRORLOG="" # TBD: for error checking later if required

### curl browser string and cookie stuff
### TBD: random change of string on each run to avoid throttling?
USERAGENT="Mozilla/5.0 (iPhone; CPU iPhone OS 13_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Mobile/15E148 Safari/604.1"
COOKIEFILE="$DATASTORE/cookiefile.txt" # not used yet

### user info goes here: status emails, etc.
#SENDTO=billg@microsoft.com

#####
### let's define all the functions
### why not sure it's what we're here for
#####

### function findprimarylink
### get a URL, follow all the redirects until there's a final URL
### so we know where our curl job is going to and can log it
###

function findprimarylink {
        NEWURL="$(curl -Ls -A "$USERAGENT" -o /dev/null -w %{url_effective} $1)"
        ## PRIMARYHASH="$(echo "$NEWURL" | md5sum | cut -f1 -d' ')"
        ## hashcheck call here for future use
}

### function podcastconverter
### take the final URL and use yt-dlp to retrieve it, then
### convert that file to audio and save its name to a variable
###

function podcastconverter {
        echo "==="
        echo "INIT: podcasting "$NEWURL""

        ### big ol' variable setting right here boy, no messin'
        ### no error checking, just letting it fly and seeing what happens
        NEWFILENAME=$(

        /usr/local/bin/yt-dlp \
                --print after_move:filepath \
                --quiet \
                --playlist-end 1 \
                --download-archive "$YTDLPLOG" \
                --extract-audio --audio-format mp3 --audio-quality 0 \
                --sleep-requests 1 --sleep-interval 5 --max-sleep-interval 9 \
                --ignore-errors --no-continue --no-overwrites \
                --ignore-no-formats-error \
                --embed-metadata --embed-thumbnail \
                --add-metadata \
                --restrict-filenames --windows-filenames \
                --parse-metadata "%(title)s:%(meta_title)s" \
                --parse-metadata "%(uploader)s:%(meta_artist)s" \
                --parse-metadata "%(release_date>%Y-%m-%d,upload_date>%Y-%m-%d)s:%(meta_publish_date)s" \
                --check-formats --concurrent-fragments 5 \
                -o "%(upload_date)s.%(uploader)s.%(title)s.%(id)s.%(release_date)s.%(ext)s" \
                "$NEWURL"

        )

        ## MUY IMPORTANTE: did the NEWFILENAME variable get set via yt-dlp?
        ## because if the NEWFILENAME variable did not get set then
        ## you are having a bad problem and you will not go to space today

        if [[ -n "$NEWFILENAME" ]]; then
                echo "==="
                echo "DOWNLOAD OK: we got a file from that URL using yt-dlp"
                sleep 0.5
        else
                echo "====="
                echo "FAILED: URL not valid / already downloaded for podcast / something else happened"
                ### ha ha yes indeed error messages are fun and also useful
                exit 1
        fi
}

### function metadatamoving
### updating metadata tags and then moving file to podcast dir
### TODO: figure out how to use a temp dir that disappears post-run
###

function metadatamoving {
        echo "==="
        echo "PUBLISHING: new audio file now being created and added to podcast directory"

        # awkward but required process to check and file for the most recent episode number
        # then increment it, throw it into a variable and save it back to the file itself
        # if it works, don't knock it
        OLDEPISODENUMBER=$(cat "$EPISODEFILE")
        NEWEPISODENUMBER=$(( $OLDEPISODENUMBER + 1 ))
        echo "$NEWEPISODENUMBER" > "$EPISODEFILE"

        # echo "updating id3v2 values on new audio file"
        id3v2 --TALB "$PODCASTNAME" "$NEWFILENAME"
        id3v2 --track "$NEWEPISODENUMBER" "$NEWFILENAME"
        id3v2 -s "$NEWFILENAME"

        # echo "copying new audio file to podcast directory"
        mv "$NEWFILENAME" "$PODCASTDIR"
        ## TODO: check if copy was successful here - maybe hashes of both files?

        echo "==="
        echo "SUCCESS: new podcast audio file added to podcast directory"
        sleep 0.5
}


### function makethatpodcastfile
### the function that calls the other functions
### get the URL, download the file, throw it into the podcast directory
### ED NOTE: please move faster come on come on let's gooooooo
###

function makethatpodcastfile {
        findprimarylink "$1"
        podcastconverter
        metadatamoving
}

#####
### and we are finally starting the actual script part of this script
### i mean how far down are we here this file is huge the heck
#####

### prep work before anything exciting happens so nothing breaks later
###
test -d $DATADIR || mkdir -p $DATADIR
test -d $PODCASTDIR || mkdir -p $PODCASTDIR
test -d $LOGSTORE || mkdir -p $LOGSTORE
# TODO: should we also verify that these directories are writable, just in case an external drive fails?

### check if we are keeping track of episode numbers and stop if we aren't
### IMPORTANT NOTE: the episode number is required to get the podcast to publish in the proper order
### instead of by release date, upload date, etc.
###
if [[ -e "$EPISODEFILE" ]]
        then
                ### echo "most recent podcast episode number as per tracking file"
                ### cat "$EPISODEFILE"
                :
        else
                echo "ERROR: you need a file with the most recent episode number, aborting"
                exit 1
fi

### in case someone forgets the URL: no soup for you
[[ $# -eq 0 ]] && echo "ERROR: you need a URL here what the heck man, aborting" && exit 1

### and finally
### let's do a thing
###
URL=$1
makethatpodcastfile "$URL"

### Brennan Huff: Did we just become best friends?
### Dale Doback: Yep!
### [they high five each other]
### Brennan Huff: Do you wanna do karate in the garage?
### Dale Doback: Yep! 

exit 0

# Library_to_Spotify
Adding a csv format library to your Spotify's library

This script takes a csv, and adds the albums there to your Spotify library. I created this script as there are many solutions to extract one's library from any music app (as a csv file e.g.), but I couldn't find a good free-of-charge tool to upload my library to my new Spotify account.

To use the script follow those steps:

Create your own app to access Spotify's API ( https://developer.spotify.com/dashboard ).
Make sure the app's callback URI is http://localhost:8888/callback (or adjust the script to your URI)
Get the client's ID and secret
Run the script and follow the prompts
A failed.log file will be created and will include the failed albums.
! Notice that some albums will fail to upload because of special characters / mismatch between Apple Music and Spotify / incomplete csv entry

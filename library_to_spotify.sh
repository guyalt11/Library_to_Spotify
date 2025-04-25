#! /bin/bash

# Ask the user for the client ID and client secret
read -p "Enter your Spotify Client ID: " client_id
read -sp "Enter your Spotify Client Secret: " client_secret
echo

# Define Spotify API credentials
redirect_uri="http://localhost:8888/callback"
scope="user-library-modify" 

# Build the authorization URL for the Spotify API
auth_url="https://accounts.spotify.com/authorize?client_id=${client_id}&response_type=code&redirect_uri=${redirect_uri}&scope=${scope}"

# Initialize an empty array to store processed albums
all=()

# Prompt the user to authorize the app and provide the authorization code
echo
echo "1. Go to the following URL and authorize the app:"
echo $auth_url
echo
echo "2. The url will redirect to a url in the format of: $redirect_uri?code=..."
read -sp "Copy the code and paste it here: " code
echo
echo
read -p "3. Add the path to your csv file: " path_to_csv
echo

# Get the access token
response=$(curl -s -X POST "https://accounts.spotify.com/api/token" \
	-H "Content-Type: application/x-www-form-urlencoded" \
	-d "grant_type=authorization_code" \
	-d "code=${code}" \
	-d "redirect_uri=${redirect_uri}" \
	-d "client_id=${client_id}" \
	-d "client_secret=${client_secret}") > /dev/null
TOKEN=$(echo $response | jq -r '.access_token')
# Check if TOKEN is not null or empty
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "Error: Failed to obtain access token."
    exit 1
else
    echo "Access token successfully obtained."
    echo "-----------------------------------"
    echo
fi

# Initiate fails log
> failed.log

# Read through the library.csv file, which contains the user's library info
while IFS= read -r line; do
	# Extract the band and album from each line and format them for use in the API
	band_name=`echo "$line" | awk -F '","' '{print $2}'`
	band=`echo "$band_name" | sed 's/"//g' | sed 's/ /%20/g'`
	album_name=`echo "$line" | awk -F '","' '{print $3}'`
	album=`echo "$album_name" | sed 's/"//g' | sed 's/ /%20/g'`
	merge=`echo $band":"$album`

	# Skip this line if the album/band entry is empty
        if [[ -z "$album" || -z "$band" ]]; then
            continue
        fi

	# Verify this album hasn't already been processed
	if [[ ! " ${all[@]} " =~ " ${merge} " ]]; then

		    all+=("$merge") # Add to the list of processed albums

		    # Retrieve the album's Spotify ID using the Spotify API
		    ID=`curl -f -s -X "GET" "https://api.spotify.com/v1/search?q=album:$album%20artist:$band&type=album&limit=1" \
	 		     -H "Authorization: Bearer $TOKEN" | jq -r '.albums.items[0].id'`

		    # Check if the album ID was successfully retrieved
		    if [[ -z "$ID" || "$ID" == "null" ]]; then
			    # If not, log the failed album to a file
		    	    echo "Failed to find '$album_name' by '$band_name' on Spotify. Adding to 'failed.log'"
			    echo
			    echo $merge | sed 's/%20/ /g' >> failed.log
		    else	
		    	    # If ID is valid, add the album to the user's library
			    curl -f -s -X "PUT" "https://api.spotify.com/v1/me/albums?ids=${ID}" \
				 -H "Authorization: Bearer ${TOKEN}"

			    # Check if album was added successfully
			    if [ $? -eq 0 ]; then
		    	    	echo "Album '$album_name' by '$band_name' was added to your library"
		            	echo
			    else
		    	        echo "Failed to add '$album_name' by '$band_name' to your library. Adding to 'failed.log'"
			        echo
			        echo $merge | sed 's/%20/ /g' >> failed.log
			    fi
		    fi
	fi
done < $path_to_csv

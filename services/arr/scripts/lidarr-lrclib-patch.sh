#!/usr/bin/with-contenv bash

echo "**** Patching Beets LRCLIB URL to self-hosted instance ****"

LYRICS_FILE=$(python3 -c "import beetsplug.lyrics; print(beetsplug.lyrics.__file__)" 2>/dev/null)

if [ -n "$LYRICS_FILE" ] && [ -f "$LYRICS_FILE" ]; then
	sed -i "s|https://lrclib.net/api|http://lrclib:3300/api|g" "$LYRICS_FILE"
	echo "**** Successfully patched $LYRICS_FILE ****"
else
	echo "**** ERROR: Could not locate beetsplug.lyrics to patch ****"
	exit 1
fi

#!/usr/bin/with-contenv bash
echo "[custom-init] **** Patching Beets LRCLIB URL to self-hosted instance ****"

LYRICS_FILE=$(python3 -c "import beetsplug.lyrics; print(beetsplug.lyrics.__file__)" 2>/dev/null)

if [ -n "$LYRICS_FILE" ] && [ -f "$LYRICS_FILE" ]; then
	sed -i "s|https://lrclib.net/api|http://lrclib:3300/api|g" "$LYRICS_FILE"

	LYRICS_DIR=$(dirname "$LYRICS_FILE")
	rm -f "${LYRICS_DIR}/__pycache__/lyrics."*.pyc
	python3 -m py_compile "$LYRICS_FILE"

	echo "[custom-init] **** Successfully patched and recompiled $LYRICS_FILE ****"
else
	echo "[custom-init] **** ERROR: Could not locate beetsplug.lyrics ****"
	exit 1
fi

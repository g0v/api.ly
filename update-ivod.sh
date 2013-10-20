curl -z /tmp/ivod.json.bz2 http://kcwu.csie.org/~kcwu/tmp/ivod.json.bz2 -o /tmp/ivod-new.json.bz2
if [ -e /tmp/ivod-new.json.bz2 ]; then
    bunzip2 -k /tmp/ivod-new.json.bz2
    lsc populate-video.ls --db ly /tmp/ivod-new.json
    mv -f /tmp/ivod-new.json.bz2 /tmp/ivod.json.bz2
fi

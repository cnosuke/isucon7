#!/bin/bash

if [ -p /dev/stdin ] ; then
    a=$(cat -)
else
    echo 'No stdin'
    exit 1
fi

curl -X POST --data-urlencode "payload={\"channel\": \"_isucon\", \"username\": \"${1}_score\", \"text\": \"\`\`\`\n${a}\n\`\`\`\", \"icon_emoji\": \":cat:\"}" https://hooks.slack.com/services/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

echo $a

exit 0

#!/bin/bash
export LC_ALL=C.UTF-8

# Send Discord notification for TranslationChecker failures
# Required environment variables:
#   DISCORD_WEBHOOK_URL - Discord webhook URL
#   GITHUB_SERVER_URL - GitHub server URL (provided by Actions)
#   GITHUB_REPOSITORY - Repository name (provided by Actions)
#   GITHUB_RUN_ID - Workflow run ID (provided by Actions)

if [ ! -f "TranslationChecker.log" ]; then
    echo "TranslationChecker.log not found"
    exit 0
fi

# Extract only failure blocks (Checking blocks where the line after is indented)
# Output format: Checking line on its own, then error details in code block
FAILURES=$(awk '
    /^Checking translations\\/ {
        # Output previous block if it had errors
        if (checking_line != "" && has_error) {
            print checking_line
            printf "```\n%s```\n", error_block
        }
        # Start new block
        checking_line = $0
        error_block = ""
        has_error = 0
        first_line_after = 1
        next
    }
    /^Total errors/ {
        # Output previous block if it had errors
        if (checking_line != "" && has_error) {
            print checking_line
            printf "```\n%s```\n", error_block
        }
        print ""
        print $0
        checking_line = ""
        next
    }
    {
        if (checking_line != "") {
            # Check if this is the first line after Checking and if it is indented
            if (first_line_after && /^  /) {
                has_error = 1
            }
            first_line_after = 0
            error_block = error_block $0 "\n"
        }
    }
    END {
        if (checking_line != "" && has_error) {
            print checking_line
            printf "```\n%s```\n", error_block
        }
    }
' TranslationChecker.log)

if [ -z "$FAILURES" ]; then
    echo "No translation failures found"
    exit 0
fi

# Build Discord webhook payload using jq for proper JSON escaping
WORKFLOW_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# Build message content
MESSAGE=$(printf '<@&1445090573760593970>\n# Translation Check Failures\n%s\n\n%s' "$WORKFLOW_URL" "$FAILURES")

PAYLOAD=$(jq -n --arg content "$MESSAGE" '{content: $content}')

# Send to Discord (use file to preserve UTF-8 encoding)
echo "$PAYLOAD" | curl -X POST -H "Content-Type: application/json; charset=utf-8" -d @- "$DISCORD_WEBHOOK_URL"

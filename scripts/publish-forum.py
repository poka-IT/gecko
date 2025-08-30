#!/usr/bin/env python3

import os
from pydiscourse import DiscourseClient
from pydiscourse.exceptions import DiscourseClientError
import logging

# Configuration from environment variables
api_id = os.getenv('DUNITER_FORUM_USERNAME', 'GeckoBuilds')
forum_api_key = os.getenv('DUNITER_FORUM_API_KEY')
topic_id = int(os.getenv('DUNITER_FORUM_TOPIC_ID', '9367'))
forum_url = os.getenv('DUNITER_FORUM_URL', 'https://forum.duniter.org/')

# Get CI variables
version = os.getenv('VERSION', 'unknown')
apk_job_id = os.getenv('APK_JOB_ID', '')
ci_project_url = os.getenv('CI_PROJECT_URL', '')
forum_mode = os.getenv('FORUM_MODE', 'complete')

# Read base message from file
with open('/tmp/message.txt', 'r') as f:
    base_message = f.read().strip()

# Build message based on mode
apk_base_url = f"{ci_project_url}/-/jobs/{apk_job_id}/artifacts/raw/artifacts/android"

# Get changelog from git
import subprocess
try:
    # Get the last tag to compare with
    last_tag_result = subprocess.run(['git', 'describe', '--tags', '--abbrev=0', 'HEAD~1'], 
                                   capture_output=True, text=True, cwd='.')
    if last_tag_result.returncode == 0:
        last_tag = last_tag_result.stdout.strip()
        # Get commits between last tag and current version (with fixed 8-char hash)
        changelog_result = subprocess.run(['git', 'log', f'{last_tag}..HEAD', '--oneline', '--no-merges', '--abbrev=8'], 
                                        capture_output=True, text=True, cwd='.')
        if changelog_result.returncode == 0 and changelog_result.stdout.strip():
            changelog_lines = changelog_result.stdout.strip().split('\n')
            formatted_lines = []
            for line in changelog_lines[:10]:  # Limit to 10 commits
                # Extract commit hash and message
                parts = line.split(' ', 1)
                if len(parts) >= 2:
                    commit_hash = parts[0]
                    commit_message = parts[1]
                    # Create link to GitLab commit
                    commit_link = f"{ci_project_url}/-/commit/{commit_hash}"
                    # Use code formatting with link to ensure monospace alignment and clickable hash
                    formatted_lines.append(f"• [`{commit_hash}`]({commit_link}) {commit_message}")
                else:
                    formatted_lines.append(f"• {line}")
            changelog = '\n'.join(formatted_lines)
        else:
            changelog = "• Minor improvements and bug fixes"
    else:
        changelog = "• Initial release or no previous tags found"
except Exception:
    changelog = "• Unable to generate changelog"

if forum_mode == "apk_only":
    # Simple message for manual APK builds
    complete_message = f"""{base_message}

This is a **BETA** build for ĞTest network.

**Download APKs:**

📱 **[Download armeabi-v7a APK]({apk_base_url}/gecko-{version}-v7a.apk)**

📱 **[Download arm64-v8a APK]({apk_base_url}/gecko-{version}-v8a.apk)**

📱 **[Download x86_64 APK]({apk_base_url}/gecko-{version}-x86_64.apk)**

**Changelog:**
{changelog}"""

else:
    # Complete release message for tag releases
    complete_message = f"""{base_message}

This is a **BETA** release for ĞTest network.

**Downloads:**

📱 **Android APKs:**
• **[Download armeabi-v7a APK]({apk_base_url}/gecko-{version}-v7a.apk)**
• **[Download arm64-v8a APK]({apk_base_url}/gecko-{version}-v8a.apk)**
• **[Download x86_64 APK]({apk_base_url}/gecko-{version}-x86_64.apk)**

🖥️ **[Linux Desktop - GitLab Releases]({ci_project_url}/-/releases/{version})**

**Store Deployments:**
• **Google Play Store:** Published (may take up to 48h to appear)
• **Apple App Store:** Submitted for review (may take up to 48h to appear)

**Changelog:**
{changelog}"""

# Create client and publish
discourse_client = DiscourseClient(
    forum_url, api_username=api_id, api_key=forum_api_key
)

try:
    response = discourse_client.create_post(complete_message, topic_id=topic_id)
    print(f"✅ Published on {forum_url}t/{response['topic_slug']}/{str(topic_id)}/last")
except DiscourseClientError as error:
    logging.error(f"❌ Issue publishing on forum: {str(error)}")
    exit(1)

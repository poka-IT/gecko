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
build_number = version.split('+')[1] if '+' in version else 'unknown'
version_only = version.split('+')[0] if '+' in version else version
apk_job_id = os.getenv('APK_JOB_ID', '')
linux_x64_job_id = os.getenv('LINUX_X64_JOB_ID', '')
linux_arm64_job_id = os.getenv('LINUX_ARM64_JOB_ID', '')
windows_x64_job_id = os.getenv('WINDOWS_X64_JOB_ID', '')
ci_project_url = os.getenv('CI_PROJECT_URL', '')
ci_commit_tag = os.getenv('CI_COMMIT_TAG', '')
forum_mode = os.getenv('FORUM_MODE', 'complete')
is_beta = '-beta' in ci_commit_tag

# Read base message from file
with open('/tmp/message.txt', 'r') as f:
    base_message = f.read().strip()

# Build message based on mode
apk_base_url = f"{ci_project_url}/-/jobs/{apk_job_id}/artifacts/raw/artifacts/android"
linux_x64_base_url = f"{ci_project_url}/-/jobs/{linux_x64_job_id}/artifacts/raw/artifacts/linux" if linux_x64_job_id else ""
linux_arm64_base_url = f"{ci_project_url}/-/jobs/{linux_arm64_job_id}/artifacts/raw/artifacts/linux" if linux_arm64_job_id else ""
windows_x64_base_url = f"{ci_project_url}/-/jobs/{windows_x64_job_id}/artifacts/raw/artifacts/windows" if windows_x64_job_id else ""

# Get changelog from git
import subprocess
try:
    # Get the last tag to compare with
    # For production releases: find the previous production tag (skip beta tags)
    # For beta releases: find the previous tag of any kind
    if is_beta:
        last_tag_result = subprocess.run(['git', 'describe', '--tags', '--abbrev=0', 'HEAD~1'],
                                       capture_output=True, text=True, cwd='.')
    else:
        # List all production tags (no -beta suffix), sorted by version descending, skip the current one
        tag_list_result = subprocess.run(
            ['bash', '-c', 'git tag --sort=-v:refname | grep -E "^v[0-9]+\\.[0-9]+\\.[0-9]+(\\+[0-9]+)?$" | sed -n "2p"'],
            capture_output=True, text=True, cwd='.')
        # Fake a similar result object
        last_tag_result = tag_list_result

    if last_tag_result.returncode == 0 and last_tag_result.stdout.strip():
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

**Download APKs:**

📱 **[Download armeabi-v7a APK]({apk_base_url}/gecko-{version}-v7a.apk)** (anciens téléphones)

📱 **[Download arm64-v8a APK]({apk_base_url}/gecko-{version}-v8a.apk)** (téléphones récents)

📱 **[Download x86_64 APK]({apk_base_url}/gecko-{version}-x86_64.apk)** (émulateurs)

📱 **[Google Play Store](https://play.google.com/store/apps/details?id=fr.axiomteam.gecko)** (disponible sous 24-48h)

**Changelog:**
{changelog}"""

else:
    # Complete release message for tag releases
    # Build optional desktop lines based on available builds
    optional_desktop_lines = ""
    if linux_x64_job_id:
        optional_desktop_lines += f"\n\n• **[Linux Desktop (tar.gz)]({linux_x64_base_url}/gecko-{version}-linux-x64.tar.gz)** (x64)"
    if windows_x64_job_id:
        optional_desktop_lines += f"\n\n• **[Windows Desktop - Installeur]({windows_x64_base_url}/gecko-{version}-windows-x64-setup.exe)** (x64, recommandé)"
        optional_desktop_lines += f"\n\n• **[Windows Desktop - Portable (zip)]({windows_x64_base_url}/gecko-{version}-windows-x64.zip)** (x64)"

    if is_beta:
        beta_header = f"""⚠️ **Version BETA {version_only}** — Cette version est en cours de test.

Merci à ceux qui prennent le temps de la tester et de remonter les éventuels problèmes !
Pour rejoindre le programme beta sur le Play Store : [s'inscrire ici](https://play.google.com/apps/testing/fr.axiomteam.gecko)"""
        play_store_note = "disponible pour les beta-testeurs"
    else:
        beta_header = ""
        play_store_note = "disponible sous 24-48h"

    beta_section = f"\n{beta_header}\n" if is_beta else ""
    complete_message = f"""{base_message}
{beta_section}
**Downloads:**

<div style="display: flex; align-items: center; gap: 8px;">
  <img src="upload://uL0FIqcHynJyP29eQsDBOX67fpg.png" width="22">
  <strong>Android:</strong>
</div>

• **[Download armeabi-v7a APK]({apk_base_url}/gecko-{version}-v7a.apk)** (anciens téléphones)

• **[Download arm64-v8a APK]({apk_base_url}/gecko-{version}-v8a.apk)** (téléphones récents)

• **[Download x86_64 APK]({apk_base_url}/gecko-{version}-x86_64.apk)** (émulateurs)

• **[Google Play Store](https://play.google.com/store/apps/details?id=fr.axiomteam.gecko)** ({play_store_note})

🍎 **iOS:**

• **[App Store](https://apps.apple.com/fr/app/gecko-g1-wallet/id6739944308)** (disponible sous 24-48h)

🖥️ **Desktop:**

• **[Linux Desktop (tar.gz)]({linux_arm64_base_url}/gecko-{version}-linux-arm64.tar.gz)** (ARM64){optional_desktop_lines}

• **[macOS Desktop (dmg)]()** (Universel - Intel + Apple Silicon)

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

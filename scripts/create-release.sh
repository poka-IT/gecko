#!/bin/bash

# Gecko Release Orchestrator
#
# Orchestrates the full release flow: pre-flight checks, tag creation,
# CI trigger (Android/Linux/Windows/forum/GitLab release), and optional
# local iOS/macOS builds.
#
# USAGE:
#   ./scripts/create-release.sh              # Production release
#   ./scripts/create-release.sh --beta       # Beta release
#   ./scripts/create-release.sh --help       # Show help

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Parse arguments ──────────────────────────────────────────────────────────

BETA_MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --beta|-b)
            BETA_MODE="true"
            shift
            ;;
        --help|-h)
            printf "Gecko Release Orchestrator\n"
            printf "\n"
            printf "USAGE:\n"
            printf "  %s              Production release (App Store + Play Store + all platforms)\n" "$0"
            printf "  %s --beta       Beta release (TestFlight + Play Store open testing)\n" "$0"
            printf "\n"
            printf "FLOW:\n"
            printf "  1. Pre-flight checks (git, version, branch, tag)\n"
            printf "  2. Summary + confirmation\n"
            printf "  3. Create + push git tag  -> CI builds Android, Linux, Windows\n"
            printf "                             -> CI deploys to Play Store\n"
            printf "                             -> CI posts on forum\n"
            printf "                             -> CI creates GitLab release\n"
            printf "  4. (optional) Local iOS build + deploy\n"
            printf "  5. (optional) Local macOS DMG build\n"
            exit 0
            ;;
        *)
            printf "${RED}Unknown option: %s${NC} (use --help)\n" "$1"
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

# ── Helper functions ─────────────────────────────────────────────────────────

check_pass() { printf "  ${GREEN}OK${NC}    %s\n" "$1"; }
check_fail() { printf "  ${RED}FAIL${NC}  %s\n" "$1"; CHECKS_FAILED=1; }
check_warn() { printf "  ${YELLOW}WARN${NC}  %s\n" "$1"; }

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    if [ "$default" = "y" ]; then
        printf "%s [Y/n] " "$prompt"
    else
        printf "%s [y/N] " "$prompt"
    fi
    read -n 1 -r
    printf "\n"
    if [ "$default" = "y" ]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# ── Extract version info ─────────────────────────────────────────────────────

FULL_VERSION=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | cut -d' ' -f2)
VERSION_ONLY=$(printf "%s" "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(printf "%s" "$FULL_VERSION" | cut -d'+' -f2)

if [ -z "$VERSION_ONLY" ] || [ -z "$BUILD_NUMBER" ]; then
    printf "${RED}Could not parse version from pubspec.yaml${NC}\n"
    exit 1
fi

if [ "$BETA_MODE" = "true" ]; then
    TAG_NAME="v${VERSION_ONLY}-beta"
    RELEASE_TYPE="BETA"
    PLAY_TRACK="Open Testing (beta)"
    IOS_TARGET="TestFlight"
else
    TAG_NAME="v${VERSION_ONLY}"
    RELEASE_TYPE="PRODUCTION"
    PLAY_TRACK="Production"
    IOS_TARGET="App Store"
fi

# ── Pre-flight checks ────────────────────────────────────────────────────────

printf "\n"
printf "${CYAN}${BOLD}Pre-flight checks${NC}\n"
printf "${CYAN}─────────────────────────────────────────${NC}\n"

CHECKS_FAILED=""

# Git: clean working tree
if [ -z "$(git status --porcelain)" ]; then
    check_pass "Working tree is clean"
else
    check_fail "Working tree has uncommitted changes"
    git status --short | head -5 | sed 's/^/         /'
fi

# Git: on master branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "master" ]; then
    check_pass "On branch master"
else
    check_warn "On branch ${CURRENT_BRANCH} (expected master)"
fi

# Git: up to date with remote
git fetch origin --quiet 2>/dev/null || true
LOCAL_HEAD=$(git rev-parse HEAD)
REMOTE_HEAD=$(git rev-parse origin/master 2>/dev/null || printf "unknown")
if [ "$LOCAL_HEAD" = "$REMOTE_HEAD" ]; then
    check_pass "Up to date with origin/master"
elif [ "$REMOTE_HEAD" = "unknown" ]; then
    check_warn "Could not check remote (offline?)"
else
    check_warn "Local differs from origin/master — make sure you've pushed"
fi

# Tag: does not already exist
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
    check_fail "Tag $TAG_NAME already exists"
else
    check_pass "Tag $TAG_NAME is available"
fi

# Version: build number is higher than last release
LAST_TAG=$(git tag --sort=-v:refname | head -1)
if [ -n "$LAST_TAG" ]; then
    LAST_BUILD=$(printf "%s" "$LAST_TAG" | grep -oE '\+[0-9]+' | tr -d '+' || true)
    if [ -n "$LAST_BUILD" ] && [ "$BUILD_NUMBER" -le "$LAST_BUILD" ] 2>/dev/null; then
        check_fail "Build number $BUILD_NUMBER is not higher than last tag ($LAST_TAG)"
    else
        check_pass "Build number +${BUILD_NUMBER} (last tag: $LAST_TAG)"
    fi
else
    check_pass "Build number +${BUILD_NUMBER} (first release)"
fi

# Format check: dart format
if command -v dart &>/dev/null; then
    FORMAT_CHECK=$(dart format --line-length=120 --set-exit-if-changed --output=none lib 2>&1 || true)
    if printf "%s" "$FORMAT_CHECK" | grep -q "Changed"; then
        check_fail "Code formatting issues found (run: dart format --line-length=120 lib)"
    else
        check_pass "Code formatting OK"
    fi
else
    check_warn "dart not in PATH, skipping format check"
fi

# Abort if any critical check failed
if [ -n "$CHECKS_FAILED" ]; then
    printf "\n"
    printf "${RED}${BOLD}Pre-flight checks failed. Fix the issues above before releasing.${NC}\n"
    exit 1
fi

# ── Changelog preview ────────────────────────────────────────────────────────

printf "\n"
printf "${CYAN}${BOLD}Changelog (since %s)${NC}\n" "$LAST_TAG"
printf "${CYAN}─────────────────────────────────────────${NC}\n"

if [ -n "$LAST_TAG" ]; then
    git log --oneline --no-merges "${LAST_TAG}..HEAD" | head -15
    TOTAL_COMMITS=$(git rev-list --count --no-merges "${LAST_TAG}..HEAD")
    if [ "$TOTAL_COMMITS" -gt 15 ]; then
        printf "  ${YELLOW}... and %d more commits${NC}\n" "$((TOTAL_COMMITS - 15))"
    fi
else
    printf "  (first release)\n"
fi

# ── Summary + confirmation ───────────────────────────────────────────────────

printf "\n"
if [ "$BETA_MODE" = "true" ]; then
    printf "${YELLOW}${BOLD}===  BETA RELEASE  ===${NC}\n"
else
    printf "${RED}${BOLD}===  PRODUCTION RELEASE  ===${NC}\n"
fi
printf "\n"
printf "  Version:       ${BOLD}%s${NC}  (build +%s)\n" "$VERSION_ONLY" "$BUILD_NUMBER"
printf "  Tag:           ${BOLD}%s${NC}\n" "$TAG_NAME"
printf "  Play Store:    %s\n" "$PLAY_TRACK"
printf "  iOS:           %s\n" "$IOS_TARGET"
printf "\n"
printf "${CYAN}CI will automatically:${NC}\n"
printf "  - Build Android APK + AAB\n"
printf "  - Build Linux (x64 + ARM64)\n"
printf "  - Build Windows (x64)\n"
printf "  - Deploy to Play Store (%s)\n" "$PLAY_TRACK"
printf "  - Post on forum.duniter.org\n"
printf "  - Create GitLab release\n"
printf "\n"

if ! ask_yes_no "$(printf "${BOLD}Create and push tag %s?${NC}" "$TAG_NAME")" "y"; then
    printf "Aborted.\n"
    exit 0
fi

# ── Create and push tag ──────────────────────────────────────────────────────

printf "\n"
printf "${BLUE}Creating tag %s...${NC}\n" "$TAG_NAME"

# Generate tag message from changelog
if [ -n "$LAST_TAG" ]; then
    TAG_MESSAGE=$(git log --pretty='format:- %s' --no-merges "${LAST_TAG}..HEAD" | head -30)
else
    TAG_MESSAGE="Initial release"
fi

git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"
printf "${BLUE}Pushing tag %s...${NC}\n" "$TAG_NAME"
git push origin "$TAG_NAME"

printf "${GREEN}Tag %s pushed — CI pipeline started${NC}\n" "$TAG_NAME"
printf "  https://git.duniter.org/clients/gecko/-/pipelines\n"
printf "\n"
printf "${CYAN}CI is now building Android, Linux, Windows in the background.${NC}\n"
printf "${CYAN}You can start local builds (iOS/macOS) in parallel.${NC}\n"
printf "\n"

# ── Local iOS deploy (parallel with CI) ─────────────────────────────────────

if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$SCRIPT_DIR/deploy-ios.sh" ]; then
    if ask_yes_no "Build and deploy iOS to ${IOS_TARGET}?" "y"; then
        printf "\n"
        IOS_ARGS=""
        if [ "$BETA_MODE" = "true" ]; then
            IOS_ARGS="--beta"
        fi
        bash "$SCRIPT_DIR/deploy-ios.sh" $IOS_ARGS
        printf "\n"
    fi
elif [[ "$OSTYPE" != "darwin"* ]]; then
    printf "${YELLOW}Skipping iOS (not on macOS)${NC}\n"
fi

# ── Local macOS build (parallel with CI) ─────────────────────────────────────

if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$SCRIPT_DIR/build-macos-dmg.sh" ]; then
    if ask_yes_no "Build macOS DMG?" "y"; then
        printf "\n"
        bash "$SCRIPT_DIR/build-macos-dmg.sh"
        printf "\n"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────

printf "\n"
printf "${GREEN}${BOLD}Release %s complete!${NC}\n" "$TAG_NAME"
printf "\n"
printf "  CI pipeline:  https://git.duniter.org/clients/gecko/-/pipelines\n"
printf "  GitLab tag:   https://git.duniter.org/clients/gecko/-/tags/%s\n" "$TAG_NAME"
printf "\n"

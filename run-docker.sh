#!/usr/bin/env bash

IMAGE_NAME="bdoi-jekyll"

# Automatically handle interactive flags (disable in CI/GitHub Actions)
if [ "$GITHUB_ACTIONS" == "true" ]; then
    DOCKER_FLAGS=""
else
    DOCKER_FLAGS="-it"
fi

# Function to build image and extract Gemfile.lock
update_lockfile() {
    echo "Updating Gemfile.lock..."
    docker build -t "$IMAGE_NAME" .
    TEMP_ID=$(docker create "$IMAGE_NAME")
    docker cp "$TEMP_ID:/srv/jekyll/Gemfile.lock" ./Gemfile.lock
    docker rm "$TEMP_ID"
    echo "Gemfile.lock updated successfully."
}

# 1. Check if Gemfile.lock exists OR if Gemfile is newer than Gemfile.lock
if [ ! -f "Gemfile.lock" ]; then
    echo "Gemfile.lock not found."
    update_lockfile
elif [ "Gemfile" -nt "Gemfile.lock" ]; then
    echo "Gemfile is newer than Gemfile.lock."
    update_lockfile
else
    # Ensure image exists even if lockfile is up to date
    if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        echo "Image $IMAGE_NAME not found. Building..."
        docker build -t "$IMAGE_NAME" .
    fi
fi

# 2. Run the docker image
if [ $# -gt 0 ]; then
    echo "Running custom command: $@"
    docker run $DOCKER_FLAGS --rm \
        -v "$(pwd):/srv/jekyll" \
        "$IMAGE_NAME" "$@"
else
    echo "Starting Jekyll server at http://localhost:4000..."
    docker run $DOCKER_FLAGS --rm \
        -p 4000:4000 \
        -v "$(pwd):/srv/jekyll" \
        "$IMAGE_NAME"
fi

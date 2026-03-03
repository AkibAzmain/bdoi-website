#!/usr/bin/env bash

IMAGE_NAME="bdoi-jekyll"

# Automatically handle interactive flags (disable in CI/GitHub Actions)
if [ "$GITHUB_ACTIONS" == "true" ]; then
    DOCKER_FLAGS=""
else
    DOCKER_FLAGS="-it"
fi

# 1. Check if Gemfile.lock exists
if [ ! -f "Gemfile.lock" ]; then
    echo "Gemfile.lock not found. Building image and extracting lockfile..."

    # 2. Rebuild docker image
    docker build -t "$IMAGE_NAME" .

    # Get the gemfile.lock from the image and save it in the folder
    echo "Extracting Gemfile.lock from image..."
    TEMP_ID=$(docker create "$IMAGE_NAME")
    docker cp "$TEMP_ID:/srv/jekyll/Gemfile.lock" ./Gemfile.lock
    docker rm "$TEMP_ID"
    
    echo "Gemfile.lock extracted successfully."
else
    # Ensure image exists even if lockfile is present
    if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        echo "Image $IMAGE_NAME not found. Building..."
        docker build -t "$IMAGE_NAME" .
    fi
fi

# 3. Run the docker image
# If arguments are passed (e.g., ./run-docker.sh bundle exec jekyll build), run them.
# Otherwise, default to starting the server.
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

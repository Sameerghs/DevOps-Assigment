#!/bin/bash

# Set default values for image name and tag
IMAGE_NAME="sameerasandeepa/fastapi-gateway"
TAG="latest"
DOCKERFILE="dockerfile.gateway"  # Specify your Dockerfile here

# Print the values
echo "Building Docker image: $IMAGE_NAME:$TAG using Dockerfile: $DOCKERFILE"

# Check if the Dockerfile exists
if [[ ! -f "$DOCKERFILE" ]]; then
    echo "Error: $DOCKERFILE does not exist!"
    exit 1
fi

# Build the Docker image
docker build -t "$IMAGE_NAME:$TAG" -f "$DOCKERFILE" .

# Check if the build was successful
if [[ $? -eq 0 ]]; then
    echo "Docker image $IMAGE_NAME:$TAG built successfully!"
else
    echo "Error: Docker image build failed!"
    exit 1
fi

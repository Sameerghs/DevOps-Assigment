#!/bin/bash

# Define the Docker container name and image
CONTAINER_NAME="api-gateway-test-container"
IMAGE_NAME="sameerasandeepa/fastapi-gateway:latest"

# Check if the container is already running and stop/remove it
if [ $(docker ps -q -f name=$CONTAINER_NAME) ]; then
    echo "Stopping and removing existing container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
else
    echo "No existing container found with the name $CONTAINER_NAME"
fi

# Start the Docker container
echo "Starting Docker container: $CONTAINER_NAME using image $IMAGE_NAME"
docker run -d --name $CONTAINER_NAME -p 8001:8001 $IMAGE_NAME

# Wait for the container to start (increase the wait time)
echo "Waiting for the container to start..."
sleep 30  # Increased wait time for better stability

# Check logs of the container to ensure the API is running
echo "Checking container logs..."
docker logs $CONTAINER_NAME

# Check if the API Gateway is ready by hitting the health endpoint
echo "Checking if the API Gateway is healthy..."
health_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/health)

if [ "$health_status" -ne 200 ]; then
  echo "Error: API Gateway is not healthy. HTTP status: $health_status"
  exit 1
fi

# Test the API Gateway with a sample image file
echo "Testing the API Gateway..."

# Path to the image you want to test with
IMAGE_PATH="smile.jpg"  # Replace with the actual image file path

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image file $IMAGE_PATH not found."
    exit 1
fi

# Corrected curl command to send the POST request with verbose output
response=$(curl -s -w "HTTP Code: %{http_code}\nResponse: %{response_body}\n" -X POST "http://localhost:8001/gateway/ocr" -F "image_file=@$IMAGE_PATH")

# Check the response
echo "Response: $response"
http_code=$(echo "$response" | grep "HTTP Code" | awk '{print $3}')
if [ "$http_code" -eq 200 ]; then
  echo "API Gateway returned a successful response: $http_code"
else
  echo "Error: API Gateway returned HTTP status: $http_code"
fi

# Optionally, you can stop and remove the container after testing
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME

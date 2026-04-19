# Start the Trackr backend stack using Docker Compose
cd "$PSScriptRoot\.."
docker compose up -d --build

docker compose ps

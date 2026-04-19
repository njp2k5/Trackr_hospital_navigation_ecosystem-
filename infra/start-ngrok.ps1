# Start an ngrok tunnel for the local API gateway.
# Requires ngrok to be installed and authenticated.

if (-not (Get-Command ngrok -ErrorAction SilentlyContinue)) {
  Write-Error "ngrok is not installed. Download it from https://ngrok.com/download and install it first."
  exit 1
}

Write-Host "Starting ngrok tunnel to localhost:8080..."
ngrok http 8080

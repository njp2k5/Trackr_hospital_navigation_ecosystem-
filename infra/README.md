# Infra: Docker + ngrok Setup

This folder contains utilities for running the backend stack locally and exposing it via ngrok.

## Requirements

- Docker Desktop / Docker Compose
- ngrok installed and authenticated

## Start the backend containers

Windows PowerShell:

```powershell
cd infra
./start-containers.ps1
```

Linux / macOS:

```bash
cd infra
./start-containers.sh
```

The stack starts three services:

- `auth-api` on the auth backend
- `analytics-api` on the analytics backend
- `api-gateway` as an Nginx reverse proxy on `localhost:8080`

## Start an ngrok tunnel

Once the Docker stack is running, expose it with ngrok:

Windows PowerShell:

```powershell
cd infra
./start-ngrok.ps1
```

Linux / macOS:

```bash
cd infra
./start-ngrok.sh
```

Then ngrok will provide a public HTTPS endpoint, such as:

```
https://abcd1234.ngrok-free.app
```

## Use the ngrok URL

### Frontend (digital twin)

```bash
cd digital_twin
VITE_API_BASE_URL=https://abcd1234.ngrok-free.app npm run dev
```

### Flutter app

```bash
cd navigation_app
flutter run --dart-define=API_BASE_URL=https://abcd1234.ngrok-free.app
```

## Notes

- The tunnel only works while ngrok is running.
- If ngrok restarts, the public URL may change.
- This is a temporary demo/test solution, not a production deployment.

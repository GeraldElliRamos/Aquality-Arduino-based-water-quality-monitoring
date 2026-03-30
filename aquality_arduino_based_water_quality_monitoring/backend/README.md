# Aquality Chatbot Backend Proxy

This is a Node.js/Express backend that acts as a proxy between the Flutter Web app and the Anthropic API. It solves the CORS (Cross-Origin Resource Sharing) issue that prevents the web app from directly calling the Anthropic API.

## Setup

### 1. Install Node.js

If you don't have Node.js installed, download it from https://nodejs.org/ (LTS version recommended)

### 2. Install Dependencies

Navigate to this folder and run:

```bash
npm install
```

### 3. Start the Server

```bash
npm start
```

Or for development with auto-reload (requires nodemon):

```bash
npm install --save-dev nodemon
npm run dev
```

The server will run on `http://localhost:3000`

## How It Works

The backend proxies requests from Flutter Web to Anthropic API:

```
Flutter Web App → Backend Proxy (localhost:3000) → Anthropic API
```

This bypasses CORS restrictions since:

- Flutter Web → Backend: Same origin (localhost)
- Backend → Anthropic: No CORS issues (backend-to-backend call)

## Endpoints

### POST `/api/chat`

Forward a chat message to Anthropic API

**Request:**

```json
{
  "messages": [
    { "role": "user", "content": "Hello" },
    { "role": "assistant", "content": "Hi!" }
  ],
  "systemPrompt": "You are helpful...",
  "apiKey": "sk-ant-..."
}
```

**Response (Success):**

```json
{
  "success": true,
  "data": {
    "content": [{ "type": "text", "text": "Response from Claude" }]
  }
}
```

### GET `/health`

Check if the server is running

**Response:**

```json
{
  "status": "OK",
  "message": "Chatbot proxy server is running"
}
```

## Environment Variables

Create a `.env` file (optional):

```
PORT=3000
```

## Troubleshooting

### "Cannot find module 'express'"

Run `npm install` to install dependencies

### "Port 3000 already in use"

Either:

1. Kill the process using port 3000
2. Set a different port: `PORT=3001 npm start`

### "Connection refused"

Make sure the backend is running: `npm start`

### App still shows CORS error

The app is likely calling the Anthropic API directly. Make sure you reloaded the Flutter web app after updating the code.

## Production Considerations

For production deployment, consider:

1. **Authentication**: Add API key validation
2. **Rate Limiting**: Prevent abuse
3. **Logging**: Track API usage
4. **Error Handling**: Better error messages
5. **HTTPS**: Use SSL certificates
6. **Deployment**: Use services like Heroku, AWS, or Google Cloud

## Files

- `server.js` - Main Express server
- `package.json` - Dependencies and scripts
- `.env.example` - Example environment variables
- `.gitignore` - Ignore node_modules and .env

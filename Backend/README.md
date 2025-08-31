# Swornim Backend

Backend API for the Swornim Event Management Platform.

## Features

- User authentication (signup/login)
- Role-based access control
- JWT-based authentication
- Input validation
- Error handling
- MongoDB integration

## Prerequisites

- Node.js (v14 or higher)
- MongoDB
- npm or yarn

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in the root directory with the following variables:
   ```
   NODE_ENV=development
   PORT=5000
   MONGODB_URI=mongodb://localhost:27017/swornim
   JWT_SECRET=your_jwt_secret_key_here
   JWT_EXPIRE=30d
   ```
4. Start the development server:
   ```bash
   npm run dev
   ```

## API Endpoints

### Authentication

#### Signup
- **POST** `/api/auth/signup`
- **Body:**
  ```json
  {
    "username": "string",
    "email": "string",
    "password": "string",
    "role": "client|cameraman|venue|makeup_artist"
  }
  ```

#### Login
- **POST** `/api/auth/login`
- **Body:**
  ```json
  {
    "email": "string",
    "password": "string"
  }
  ```

## Project Structure

```
src/
├── controllers/     # Route controllers
├── middleware/      # Custom middleware
├── models/         # Database models
├── routes/         # API routes
└── server.js       # Entry point
```

## Error Handling

The API uses a consistent error response format:

```json
{
  "success": false,
  "message": "Error message",
  "errors": [] // Optional validation errors
}
```

## Security

- Passwords are hashed using bcrypt
- JWT tokens for authentication
- Input validation using express-validator
- CORS enabled
- Environment variables for sensitive data

## Development

- Run tests: `npm test`
- Start development server: `npm run dev`
- Start production server: `npm start` 
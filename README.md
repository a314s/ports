# Port Monitor Dashboard

A secure, production-ready web application for monitoring and managing network ports and processes.

## Features

- Real-time port monitoring
- Process management
- Secure process termination
- Filtering and sorting capabilities
- Rate limiting and security measures
- Production-ready logging
- Redis-based caching and session management

## Prerequisites

- Node.js (v14 or higher)
- Redis Server
- PowerShell 5.1 or higher
- Windows OS (for PowerShell scripts)

## Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```
3. Copy the environment configuration:
```bash
copy .env.example .env
```
4. Update the `.env` file with your configuration

## Configuration

### Environment Variables

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (production/development)
- `SESSION_SECRET`: Secret for session encryption
- `CORS_ORIGIN`: Allowed CORS origin
- `REDIS_HOST`: Redis server host
- `REDIS_PORT`: Redis server port
- `REDIS_PASSWORD`: Redis server password
- `LOG_LEVEL`: Logging level (info/warn/error)
- `LOG_FILE`: Log file path
- `RATE_LIMIT_WINDOW_MS`: Rate limiting window
- `RATE_LIMIT_MAX_REQUESTS`: Maximum requests per window

### Security Features

- Helmet.js for security headers
- CORS protection
- Rate limiting
- Session management
- Input validation
- Process access control
- Structured logging

## Directory Structure

```
.
├── config/
│   ├── logger.js
│   └── security.js
├── logs/
├── public/
│   ├── dashboard.html
│   ├── index.html
│   ├── script.js
│   └── styles.css
├── .env
├── server.js
├── get-ports.ps1
└── kill-process.ps1
```

## Running in Production

1. Set up Redis:
```bash
# Install Redis on Windows or use a cloud service
```

2. Configure environment:
```bash
# Set NODE_ENV=production in .env
# Configure other environment variables
```

3. Start the server:
```bash
npm start
```

## Monitoring and Maintenance

### Logging

- Application logs are stored in `./logs/app.log`
- Use the configured log level to control verbosity
- Logs are rotated automatically (5MB max size, 5 files kept)

### Health Checks

- Access `/health` endpoint to check server status
- Monitor Redis connection status
- Check process access permissions

### Security Considerations

- Keep Redis password secure
- Regularly update dependencies
- Monitor rate limiting effectiveness
- Review process termination logs
- Maintain PowerShell execution policies

## Error Handling

The application includes comprehensive error handling:

- API endpoint validation
- Process termination safety checks
- Redis connection monitoring
- PowerShell script execution handling
- Graceful server shutdown

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details
const winston = require('winston');
const path = require('path');
const fs = require('fs');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '..', 'logs');
try {
    if (!fs.existsSync(logsDir)) {
        fs.mkdirSync(logsDir);
    }
} catch (error) {
    console.error('Error creating logs directory:', error);
}

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'debug',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.printf(({ level, message, timestamp }) => {
            return `${timestamp} ${level}: ${message}`;
        })
    ),
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.printf(({ level, message, timestamp }) => {
                    return `${timestamp} ${level}: ${message}`;
                })
            ),
            handleExceptions: true
        })
    ],
    exitOnError: false
});

// Add file transport if we can write to the logs directory
try {
    logger.add(new winston.transports.File({
        filename: path.join(logsDir, 'app.log'),
        maxsize: 5242880, // 5MB
        maxFiles: 5,
        format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.json()
        )
    }));
} catch (error) {
    logger.error('Error setting up file transport:', error);
}

// Create a stream object for Morgan middleware
logger.stream = {
    write: (message) => logger.info(message.trim())
};

// Test logger
logger.info('Logger initialized successfully');

module.exports = logger;
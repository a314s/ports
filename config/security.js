const rateLimit = require('express-rate-limit');
const session = require('express-session');
const helmet = require('helmet');
const cors = require('cors');

let redis, RedisStore;

// Only initialize Redis if enabled
if (process.env.REDIS_ENABLED !== 'false') {
    RedisStore = require('connect-redis').default;
    const Redis = require('ioredis');
    redis = new Redis({
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        password: process.env.REDIS_PASSWORD,
    });
}

// Rate limiting configuration
const rateLimiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});

// CORS configuration
const corsOptions = {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
    methods: ['GET', 'POST'],
    credentials: true,
    optionsSuccessStatus: 204,
};

// Session configuration
const sessionConfig = {
    secret: process.env.SESSION_SECRET || 'your-secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000, // 24 hours
    },
};

// Add Redis store if Redis is enabled
if (redis) {
    sessionConfig.store = new RedisStore({ client: redis });
}

// Helmet configuration
const helmetConfig = {
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'", 'http://localhost:*'],
            fontSrc: ["'self'", 'https:', 'data:'],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
        },
    },
};

module.exports = {
    redis: redis || null,
    rateLimiter,
    corsOptions,
    sessionConfig,
    helmetConfig,
    helmet,
    cors,
};
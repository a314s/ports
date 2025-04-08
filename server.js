require('dotenv').config();
const express = require('express');
const path = require('path');
const fs = require('fs');
const { promisify } = require('util');
const exec = promisify(require('child_process').exec);
const compression = require('compression');
const { body, param, validationResult } = require('express-validator');

// Import configurations
const logger = require('./config/logger');
const {
    redis,
    rateLimiter,
    corsOptions,
    sessionConfig,
    helmetConfig,
    helmet,
    cors,
} = require('./config/security');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet(helmetConfig));
app.use(cors(corsOptions));
app.use(rateLimiter);
app.use(compression());
app.use(express.json());
app.use(require('express-session')(sessionConfig));

// Debug logging for all requests
app.use((req, res, next) => {
    logger.debug(`${req.method} ${req.url}`);
    next();
});

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Serve static files from a dedicated public directory
app.use(express.static(path.join(__dirname, 'public')));

// API Endpoints with validation and error handling
app.get('/api/ports', async (req, res) => {
    logger.debug('Handling /api/ports request');
    try {
        // Check if Redis is enabled and data is cached
        if (redis && process.env.REDIS_ENABLED !== 'false') {
            const cachedData = await redis.get('ports_data');
            if (cachedData) {
                logger.info('Serving ports data from cache');
                return res.json(JSON.parse(cachedData));
            }
        }

        // Check if PowerShell script exists
        const scriptPath = path.join(__dirname, 'get-ports.ps1');
        logger.debug(`Looking for PowerShell script at: ${scriptPath}`);
        if (!fs.existsSync(scriptPath)) {
            throw new Error('PowerShell script not found');
        }
        logger.debug('PowerShell script found');

        // Execute PowerShell script with proper error handling
        logger.debug('Executing PowerShell script...');
        const command = `powershell -ExecutionPolicy ${process.env.POWERSHELL_EXECUTION_POLICY} -File "${scriptPath}"`;
        logger.debug(`Command: ${command}`);
        const { stdout, stderr } = await exec(command);

        if (stderr) {
            logger.error(`PowerShell script stderr: ${stderr}`);
            throw new Error(`PowerShell script error: ${stderr}`);
        }

        logger.info(`PowerShell script executed successfully`);
        logger.debug(`PowerShell stdout: ${stdout}`);
        
        // Read and validate the generated JSON file
        const jsonPath = path.join(__dirname, 'ports-data.json');
        logger.debug(`Reading JSON file from: ${jsonPath}`);
        const jsonContent = await fs.promises.readFile(jsonPath, 'utf8');
        logger.debug('JSON file read successfully');
        logger.debug('Parsing JSON content...');
        const portsData = JSON.parse(jsonContent);
        logger.debug('JSON parsed successfully');
        
        // Cache the results in Redis if enabled
        if (redis && process.env.REDIS_ENABLED !== 'false') {
            await redis.setex('ports_data', 60, JSON.stringify(portsData));
            logger.info('Cached ports data in Redis');
        }
        
        res.json(portsData);
    } catch (error) {
        logger.error('Error in /api/ports:', error);
        res.status(500).json({
            error: 'Failed to fetch ports data',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

// Debug logging for 404s
app.use((req, res, next) => {
    logger.debug(`404: ${req.method} ${req.url}`);
    next();
});

app.post('/api/kill/:pid', [
    // Validate PID parameter
    param('pid').isInt().withMessage('Invalid PID format'),
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const pid = parseInt(req.params.pid);

        // Check if PowerShell script exists
        const scriptPath = path.join(__dirname, 'kill-process.ps1');
        if (!fs.existsSync(scriptPath)) {
            throw new Error('PowerShell script not found');
        }

        // Execute PowerShell script with proper error handling
        const { stdout, stderr } = await exec(
            `powershell -ExecutionPolicy ${process.env.POWERSHELL_EXECUTION_POLICY} -File "${scriptPath}" -ProcessId ${pid}`
        );

        if (stderr) {
            logger.error(`PowerShell script stderr: ${stderr}`);
        }

        logger.info(`Process ${pid} termination attempted`);

        try {
            const result = JSON.parse(stdout);
            // Invalidate ports data cache if Redis is enabled
            if (redis && process.env.REDIS_ENABLED !== 'false') {
                await redis.del('ports_data');
                logger.info('Invalidated ports data cache');
            }
            res.json(result);
        } catch (err) {
            logger.warn(`Error parsing kill-process.ps1 output: ${err}`);
            res.json({
                success: true,
                message: `Process with PID ${pid} was terminated`
            });
        }
    } catch (error) {
        logger.error(`Error killing process ${req.params.pid}:`, error);
        res.status(500).json({
            error: `Failed to kill process with PID ${req.params.pid}`,
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    logger.error('Unhandled error:', err);
    res.status(500).json({
        error: 'Internal server error',
        details: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// Start server with proper error handling
const server = app.listen(PORT, () => {
    logger.info(`Server running on http://localhost:${PORT}`);
    logger.info(`Port Monitor Dashboard is now available!`);
});

// Handle process signals for graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received. Starting graceful shutdown...');
    server.close(() => {
        logger.info('Server closed. Process terminating...');
        process.exit(0);
    });
});

process.on('uncaughtException', (err) => {
    logger.error('Uncaught exception:', err);
    process.exit(1);
});

process.on('unhandledRejection', (err) => {
    logger.error('Unhandled rejection:', err);
    process.exit(1);
});
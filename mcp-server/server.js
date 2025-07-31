// MCP Server for Windows 11 STIG Assessment Tool
// NIST NCP Repository Integration Server

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const axios = require('axios');
const fs = require('fs-extra');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const cron = require('node-cron');

// Server configuration
const config = {
    port: process.env.PORT || 8080,
    host: process.env.HOST || 'localhost',
    nistApiBase: 'https://ncp.nist.gov/repository/api/v1',
    cacheDir: '../cache/nist',
    logDir: '../logs',
    development: process.argv.includes('--dev')
};

// Initialize logger
const logger = winston.createLogger({
    level: config.development ? 'debug' : 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ 
            filename: path.join(__dirname, config.logDir, 'mcp-server.log'),
            maxsize: 50 * 1024 * 1024, // 50MB
            maxFiles: 10
        }),
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        })
    ]
});

// Initialize Express app
const app = express();

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
    origin: ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
    const requestId = uuidv4();
    req.requestId = requestId;
    logger.info(`[${requestId}] ${req.method} ${req.path}`, {
        method: req.method,
        path: req.path,
        ip: req.ip,
        userAgent: req.get('User-Agent')
    });
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        server: 'STIG-Assessment-MCP-Server'
    });
});

// NIST NCP Repository Integration
class NISTIntegration {
    constructor() {
        this.baseUrl = config.nistApiBase;
        this.cacheDir = path.join(__dirname, config.cacheDir);
        this.ensureCacheDir();
    }

    async ensureCacheDir() {
        try {
            await fs.ensureDir(this.cacheDir);
            logger.info('NIST cache directory ensured');
        } catch (error) {
            logger.error('Failed to create cache directory:', error);
        }
    }

    async fetchFrameworks() {
        try {
            logger.info('Fetching NIST frameworks');
            
            // Mock response for now (replace with actual NIST API when available)
            const frameworks = {
                frameworks: [
                    {
                        id: 'nist-800-53',
                        name: 'NIST SP 800-53 Security and Privacy Controls',
                        version: 'Rev 5',
                        description: 'Security and privacy controls for federal information systems'
                    },
                    {
                        id: 'nist-csf',
                        name: 'NIST Cybersecurity Framework',
                        version: '2.0',
                        description: 'Framework for improving cybersecurity posture'
                    },
                    {
                        id: 'nist-800-171',
                        name: 'NIST SP 800-171 Protecting CUI',
                        version: 'Rev 2',
                        description: 'Protecting Controlled Unclassified Information'
                    }
                ]
            };

            // Cache the response
            const cacheFile = path.join(this.cacheDir, 'frameworks.json');
            await fs.writeJson(cacheFile, {
                timestamp: new Date().toISOString(),
                data: frameworks
            }, { spaces: 2 });

            logger.info(`Cached ${frameworks.frameworks.length} NIST frameworks`);
            return frameworks;

        } catch (error) {
            logger.error('Failed to fetch NIST frameworks:', error);
            throw error;
        }
    }

    async fetchControls(frameworkId) {
        try {
            logger.info(`Fetching controls for framework: ${frameworkId}`);
            
            // Mock response for now
            const controls = {
                framework: frameworkId,
                controls: [
                    {
                        id: 'AC-2',
                        name: 'Account Management',
                        family: 'Access Control',
                        description: 'Manage information system accounts'
                    },
                    {
                        id: 'SI-3',
                        name: 'Malicious Code Protection',
                        family: 'System and Information Integrity',
                        description: 'Implement malicious code protection'
                    }
                ]
            };

            // Cache the response
            const cacheFile = path.join(this.cacheDir, `${frameworkId}-controls.json`);
            await fs.writeJson(cacheFile, {
                timestamp: new Date().toISOString(),
                data: controls
            }, { spaces: 2 });

            return controls;

        } catch (error) {
            logger.error(`Failed to fetch controls for ${frameworkId}:`, error);
            throw error;
        }
    }
}

// Initialize NIST integration
const nist = new NISTIntegration();

// API Routes

// Get available NIST frameworks
app.get('/api/nist/frameworks', async (req, res) => {
    try {
        const frameworks = await nist.fetchFrameworks();
        res.json({
            success: true,
            data: frameworks,
            requestId: req.requestId
        });
    } catch (error) {
        logger.error(`[${req.requestId}] Failed to get frameworks:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch NIST frameworks',
            requestId: req.requestId
        });
    }
});

// Get controls for a specific framework
app.get('/api/nist/frameworks/:frameworkId/controls', async (req, res) => {
    try {
        const { frameworkId } = req.params;
        const controls = await nist.fetchControls(frameworkId);
        res.json({
            success: true,
            data: controls,
            requestId: req.requestId
        });
    } catch (error) {
        logger.error(`[${req.requestId}] Failed to get controls:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch controls',
            requestId: req.requestId
        });
    }
});

// Submit compliance assessment results
app.post('/api/compliance/submit', async (req, res) => {
    try {
        const { timestamp, report_type, system_info, results } = req.body;
        
        logger.info(`[${req.requestId}] Received compliance submission`, {
            reportType: report_type,
            hostname: system_info?.hostname,
            resultsCount: results?.length
        });

        // Process and store results
        const submissionId = uuidv4();
        const submission = {
            id: submissionId,
            timestamp: timestamp || new Date().toISOString(),
            report_type,
            system_info,
            results,
            processed_at: new Date().toISOString()
        };

        // Save to file (in production, use database)
        const submissionFile = path.join(__dirname, config.logDir, `submission-${submissionId}.json`);
        await fs.writeJson(submissionFile, submission, { spaces: 2 });

        res.json({
            success: true,
            report_id: submissionId,
            message: 'Compliance results submitted successfully',
            requestId: req.requestId
        });

    } catch (error) {
        logger.error(`[${req.requestId}] Failed to submit compliance:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to submit compliance results',
            requestId: req.requestId
        });
    }
});

// Get organization baseline
app.get('/api/organization/baseline/:profileType', async (req, res) => {
    try {
        const { profileType } = req.params;
        
        // Mock baseline response
        const baseline = {
            profile: profileType,
            baseline: {
                controls: [
                    { id: 'AC-2', required: true, level: 'moderate' },
                    { id: 'SI-3', required: true, level: 'high' }
                ],
                policies: [],
                customizations: []
            }
        };

        res.json({
            success: true,
            data: baseline,
            requestId: req.requestId
        });

    } catch (error) {
        logger.error(`[${req.requestId}] Failed to get baseline:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch organization baseline',
            requestId: req.requestId
        });
    }
});

// Enterprise integration endpoints
app.post('/api/enterprise/siem', async (req, res) => {
    try {
        const { platform, events } = req.body;
        
        logger.info(`[${req.requestId}] SIEM integration request for ${platform}`, {
            eventsCount: events?.length
        });

        // Mock SIEM integration
        res.json({
            success: true,
            message: `Events sent to ${platform}`,
            events_processed: events?.length || 0,
            requestId: req.requestId
        });

    } catch (error) {
        logger.error(`[${req.requestId}] SIEM integration failed:`, error);
        res.status(500).json({
            success: false,
            error: 'SIEM integration failed',
            requestId: req.requestId
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    logger.error(`[${req.requestId}] Unhandled error:`, error);
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        requestId: req.requestId
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        requestId: req.requestId
    });
});

// Scheduled tasks
// Update NIST frameworks cache every Sunday at 2 AM
cron.schedule('0 2 * * 0', async () => {
    logger.info('Running scheduled NIST frameworks update');
    try {
        await nist.fetchFrameworks();
        logger.info('Scheduled NIST frameworks update completed');
    } catch (error) {
        logger.error('Scheduled NIST frameworks update failed:', error);
    }
});

// Start server
async function startServer() {
    try {
        // Ensure directories exist
        await fs.ensureDir(path.join(__dirname, config.logDir));
        await fs.ensureDir(path.join(__dirname, config.cacheDir));

        app.listen(config.port, config.host, () => {
            logger.info(`[STIG] MCP Server started`, {
                host: config.host,
                port: config.port,
                environment: config.development ? 'development' : 'production'
            });
            
            console.log(`\n[SUCCESS] MCP Server running at http://${config.host}:${config.port}`);
            console.log(`[INFO] Health check: http://${config.host}:${config.port}/health`);
            console.log(`[INFO] NIST Frameworks: http://${config.host}:${config.port}/api/nist/frameworks`);
            
            if (config.development) {
                console.log(`[INFO] Development mode enabled - verbose logging active`);
            }
        });

    } catch (error) {
        logger.error('Failed to start MCP server:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    process.exit(0);
});

// Start the server
startServer();

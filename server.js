const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, './')));

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// API Endpoints
app.get('/api/ports', (req, res) => {
    // Execute the PowerShell script to get fresh port data
    exec('powershell -ExecutionPolicy Bypass -File .\\get-ports.ps1', (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing PowerShell script: ${error}`);
            return res.status(500).json({ error: 'Failed to fetch ports data' });
        }
        
        if (stderr) {
            console.error(`PowerShell script stderr: ${stderr}`);
        }
        
        console.log(`PowerShell script output: ${stdout}`);
        
        // Read the generated JSON file
        try {
            const portsData = JSON.parse(fs.readFileSync('ports-data.json', 'utf8'));
            res.json(portsData);
        } catch (err) {
            console.error(`Error reading ports-data.json: ${err}`);
            res.status(500).json({ error: 'Failed to read ports data' });
        }
    });
});

app.post('/api/kill/:pid', (req, res) => {
    const pid = req.params.pid;
    
    if (!pid || isNaN(parseInt(pid))) {
        return res.status(400).json({ error: 'Invalid PID provided' });
    }
    
    // Execute the PowerShell script to kill the process
    exec(`powershell -ExecutionPolicy Bypass -File .\\kill-process.ps1 -ProcessId ${pid}`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing PowerShell script: ${error}`);
            return res.status(500).json({ error: `Failed to kill process with PID ${pid}` });
        }
        
        if (stderr) {
            console.error(`PowerShell script stderr: ${stderr}`);
        }
        
        console.log(`PowerShell script output: ${stdout}`);
        
        try {
            const result = JSON.parse(stdout);
            res.json(result);
        } catch (err) {
            console.error(`Error parsing kill-process.ps1 output: ${err}`);
            res.json({ success: true, message: `Process with PID ${pid} was terminated` });
        }
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Port Monitor Dashboard is now available!`);
});
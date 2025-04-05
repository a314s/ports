# Port Monitor Dashboard

A modern, web-based dashboard for monitoring and managing active network ports on your system. This tool helps you track, view, and kill processes that are using network ports, making it easier to manage port conflicts during software testing and development.

## Features

- 🔍 **Real Port Monitoring**: View actual active TCP and UDP connections on your system
- 🔎 **Detailed Information**: See local/remote addresses, ports, states, PIDs, and process names
- 🔄 **Filtering & Sorting**: Filter by protocol, search by any field, and sort results
- 🚫 **Process Management**: Kill processes directly from the dashboard
- 📊 **Statistics**: View counts of total ports, TCP, and UDP connections
- 🎨 **Modern UI**: Clean, responsive design with nice color accents

## Requirements

- Windows PowerShell 5.1 or higher
- Modern web browser (Chrome, Firefox, Edge, etc.)

## Usage Methods

You can use the Port Monitor Dashboard in three different ways:

### Method 1: Node.js Server (Recommended)

This method provides the best experience with full functionality:

1. **Start the Node.js Server**:
   - Open PowerShell as Administrator
   - Navigate to the project directory
   - Run the script:
     ```
     .\start-node-server.ps1
     ```
   - This will automatically find your Node.js installation, install dependencies, and start the server
   - The dashboard will be available at http://localhost:3000

2. **Use the Dashboard**:
   - The dashboard will automatically refresh port data when you click the Refresh button
   - When you click "Kill Process", it will automatically kill the process and refresh the data
   - No manual PowerShell commands needed!

### Method 2: Quick Start (PowerShell Only)

1. **Run the Open Dashboard Script**:
   - Open PowerShell as Administrator
   - Navigate to the project directory
   - Run the script:
     ```
     .\open-dashboard.ps1
     ```
   - This will automatically generate port data and open the dashboard in your browser

### Manual Steps

1. **Generate Port Data**:
   - Open PowerShell as Administrator
   - Navigate to the project directory
   - Run the PowerShell script to generate port data:
     ```
     .\get-ports.ps1
     ```
   - This will create a `ports-data.json` file with information about all active ports

2. **View the Dashboard**:
   - Open `dashboard.html` in your web browser
   - The dashboard will load and display the actual port data from your system
   - Use the search box and filters to find specific ports or processes

3. **Kill a Process**:
   - When you click "Kill Process" in the dashboard, you'll see instructions
   - Run the provided PowerShell command to kill the process:
     ```
     .\kill-process.ps1 -ProcessId <PID>
     ```
   - After killing a process, run `.\get-ports.ps1` again to update the data
   - Refresh the dashboard to see the updated port information

4. **Refresh Port Data**:
   - To get the latest port information, run `.\get-ports.ps1` again
   - Refresh the dashboard in your browser

### Method 3: Manual Setup

If you prefer to set things up manually:

1. **Generate Port Data**:
   - Run `.\get-ports.ps1` to generate the ports-data.json file

2. **Start a Web Server**:
   - Use any web server to serve the files (Python, Node.js, etc.)
   - For example, with Python: `python -m http.server 8000`

3. **Open the Dashboard**:
   - Navigate to the appropriate URL in your browser
   - For example: http://localhost:8000/dashboard.html

### Troubleshooting

If you encounter CORS errors when opening the dashboard directly:
- Use a local web server to serve the files
- Use the "Live Server" extension in VS Code
- Or simply use the `start-node-server.ps1` script which handles this for you

### Node.js Issues

If you're having issues with Node.js:

1. **Path Issues**: If Node.js is installed but not in your PATH, the `start-node-server.ps1` script will attempt to find it automatically.

2. **Installation**: If Node.js is not installed, you can download it from [nodejs.org](https://nodejs.org/).

3. **Dependencies**: The script will automatically install the required dependencies (express and cors).

## License

MIT

---

Made with ❤️ for developers who hate port conflicts
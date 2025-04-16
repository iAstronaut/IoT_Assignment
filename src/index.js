const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const dotenv = require('dotenv');
const { connect } = require('./config/database');
const routes = require('./routes');
const sql = require('mssql');
const HeartRateService = require('./services/heartRateService');
const AuthService = require('./services/authService');

// Load environment variables
dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// SQL Server configuration
const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: true,
    trustServerCertificate: true,
  },
};

// Connect to database
sql.connect(config).then(() => {
  console.log('Connected to SQL Server');
}).catch(err => {
  console.error('Error connecting to SQL Server:', err);
});

// Routes
app.use('/api', routes);

// Initialize HeartRateService
const initializeHeartRateService = async () => {
  try {
    // Login to CoreIoT and get token
    const token = await AuthService.loginCoreIoT();
    if (!token) {
      throw new Error('Failed to get CoreIoT token');
    }
    console.log('Got CoreIoT token');

    // Initialize service with token
    await HeartRateService.initialize(token);
    console.log('HeartRateService initialized');
  } catch (error) {
    console.error('Failed to initialize HeartRateService:', error);
  }
};

// API Routes
// Insert measurement
app.post('/api/measurements', async (req, res) => {
  try {
    const { heartRate, oxygen } = req.body;
    console.log('Received data:', { heartRate, oxygen });
    const result = await sql.query`
      INSERT INTO HeartRateReadings (patientId, heartRate, oxygen, timestamp)
      VALUES (1, ${heartRate}, ${oxygen}, GETDATE());
      SELECT SCOPE_IDENTITY() as id;
    `;
    const insertedId = result.recordset[0].id;
    console.log('Inserted with ID:', insertedId);
    res.json({
      success: true,
      rowsAffected: result.rowsAffected[0],
      insertedId: insertedId
    });
  } catch (err) {
    console.error('Error inserting measurement:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get weekly readings
app.get('/api/measurements', async (req, res) => {
  try {
    const result = await sql.query`
      SELECT TOP 1000
        id,
        patientId,
        heartRate,
        oxygen,
        timestamp
      FROM HeartRateReadings
      ORDER BY timestamp DESC
    `;
    console.log('Retrieved', result.recordset.length, 'records');
    res.json(result.recordset);
  } catch (err) {
    console.error('Error getting measurements:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get latest reading
app.get('/api/measurements/latest', async (req, res) => {
  try {
    const result = await sql.query`
      SELECT TOP 1
        id,
        patientId,
        heartRate,
        oxygen,
        timestamp
      FROM HeartRateReadings
      ORDER BY timestamp DESC
    `;
    res.json(result.recordset[0] || null);
  } catch (err) {
    console.error('Error getting latest measurement:', err);
    res.status(500).json({ error: err.message });
  }
});

// Test database connection
app.get('/api/test', async (req, res) => {
  try {
    await sql.query`SELECT 1`;
    res.json({ status: 'Database connection successful' });
  } catch (err) {
    console.error('Database connection test failed:', err);
    res.status(500).json({ error: err.message });
  }
});

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });

  // Handle real-time data updates
  socket.on('heartRateUpdate', (data) => {
    // Broadcast to all connected clients
    io.emit('heartRateData', data);
  });
});

const startServer = async () => {
  try {
    // Connect to database first
    await connect();

    // Initialize HeartRateService
    await initializeHeartRateService();

    const port = process.env.PORT || 3000;
    server.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
const express = require('express');
const router = express.Router();
const authRoutes = require('./auth');
const patientRoutes = require('./patient');
const heartRateRoutes = require('./heartRate');

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Register routes
router.use('/auth', authRoutes);
router.use('/patients', patientRoutes);
router.use('/heartrate', heartRateRoutes);

module.exports = router;
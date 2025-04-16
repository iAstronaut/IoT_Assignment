const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');
const HeartRateService = require('../services/heartRateService');

// Get latest heart rate data
router.get('/latest', async (req, res) => {
    try {
        const data = HeartRateService.getLatestData();
        res.json(data);
    } catch (error) {
        console.error('Error getting latest data:', error);
        res.status(500).json({ error: 'Failed to get latest data' });
    }
});

// Get measurement history
router.get('/history', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 100;
        const history = await HeartRateService.getHistory(limit);
        res.json(history);
    } catch (error) {
        console.error('Error getting history:', error);
        res.status(500).json({ error: 'Failed to get history' });
    }
});

// Save measurement
router.post('/save', async (req, res) => {
    try {
        const savedData = await HeartRateService.saveMeasurement(req.body);
        res.json(savedData);
    } catch (error) {
        console.error('Error saving measurement:', error);
        res.status(500).json({ error: 'Failed to save measurement' });
    }
});

// Get heart rate history
router.get('/:patientId', authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const history = await HeartRateService.getHistory(req.params.patientId);
    res.json(history);
  } catch (error) {
    console.error('Error fetching heart rate history:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add new heart rate reading
router.post('/', authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const reading = await HeartRateService.addReading(req.body);
    res.status(201).json(reading);
  } catch (error) {
    console.error('Error recording heart rate:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get heart rate statistics
router.get('/:patientId/statistics', authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const statistics = await HeartRateService.getStatistics(req.params.patientId);
    res.json(statistics);
  } catch (error) {
    console.error('Error fetching heart rate statistics:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get active alerts
router.get('/:patientId/alerts', authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const alerts = await HeartRateService.getActiveAlerts(req.params.patientId);
    res.json(alerts);
  } catch (error) {
    console.error('Error fetching alerts:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update alert status
router.put('/alerts/:alertId', authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const { status } = req.body;
    await HeartRateService.updateAlertStatus(req.params.alertId, status);
    res.json({ message: 'Alert status updated successfully' });
  } catch (error) {
    console.error('Error updating alert status:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// WebSocket endpoint for real-time updates
router.get('/realtime/:patientId', auth, (req, res) => {
  res.json({ message: 'Use WebSocket connection for real-time data' });
});

module.exports = router;
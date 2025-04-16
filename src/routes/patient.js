const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const authorize = require('../middleware/authorize');
const PatientService = require('../services/patientService');

// Get all patients
router.get('/', auth, authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const patients = await PatientService.getAll();
    res.json(patients);
  } catch (error) {
    console.error('Error fetching patients:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get patient by ID
router.get('/:id', auth, authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const patient = await PatientService.getById(req.params.id);
    res.json(patient);
  } catch (error) {
    if (error.message === 'Patient not found') {
      return res.status(404).json({ message: error.message });
    }
    console.error('Error fetching patient:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new patient
router.post('/', auth, authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const patient = await PatientService.create(req.body);
    res.status(201).json(patient);
  } catch (error) {
    console.error('Error creating patient:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update patient
router.put('/:id', auth, authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const patient = await PatientService.update(req.params.id, req.body);
    res.json(patient);
  } catch (error) {
    if (error.message === 'Patient not found') {
      return res.status(404).json({ message: error.message });
    }
    console.error('Error updating patient:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete patient
router.delete('/:id', auth, authorize(['admin']), async (req, res) => {
  try {
    await PatientService.delete(req.params.id);
    res.json({ message: 'Patient deleted successfully' });
  } catch (error) {
    if (error.message === 'Patient not found') {
      return res.status(404).json({ message: error.message });
    }
    console.error('Error deleting patient:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get patient's heart rate history
router.get('/:id/heart-rate', auth, authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const history = await PatientService.getHeartRateHistory(req.params.id);
    res.json(history);
  } catch (error) {
    console.error('Error fetching heart rate history:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get patient's active alerts
router.get('/:id/alerts', auth, authorize(['admin', 'doctor']), async (req, res) => {
  try {
    const alerts = await PatientService.getActiveAlerts(req.params.id);
    res.json(alerts);
  } catch (error) {
    console.error('Error fetching alerts:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
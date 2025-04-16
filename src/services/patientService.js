const { pool } = require('../config/database');

class PatientService {
  // Get all patients
  static async getAll() {
    const result = await pool.request()
      .query('SELECT * FROM Patients ORDER BY name');
    return result.recordset;
  }

  // Get patient by ID
  static async getById(id) {
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query('SELECT * FROM Patients WHERE id = @id');

    if (result.recordset.length === 0) {
      throw new Error('Patient not found');
    }

    return result.recordset[0];
  }

  // Create new patient
  static async create(patientData) {
    const { name, age, gender, address, phone, medicalHistory } = patientData;

    const result = await pool.request()
      .input('name', sql.NVarChar, name)
      .input('age', sql.Int, age)
      .input('gender', sql.NVarChar, gender)
      .input('address', sql.NVarChar, address)
      .input('phone', sql.NVarChar, phone)
      .input('medicalHistory', sql.NVarChar, medicalHistory)
      .query(`
        INSERT INTO Patients (name, age, gender, address, phone, medicalHistory)
        VALUES (@name, @age, @gender, @address, @phone, @medicalHistory)
        SELECT SCOPE_IDENTITY() as id
      `);

    return {
      id: result.recordset[0].id,
      ...patientData
    };
  }

  // Update patient
  static async update(id, patientData) {
    const { name, age, gender, address, phone, medicalHistory } = patientData;

    const result = await pool.request()
      .input('id', sql.Int, id)
      .input('name', sql.NVarChar, name)
      .input('age', sql.Int, age)
      .input('gender', sql.NVarChar, gender)
      .input('address', sql.NVarChar, address)
      .input('phone', sql.NVarChar, phone)
      .input('medicalHistory', sql.NVarChar, medicalHistory)
      .query(`
        UPDATE Patients
        SET name = @name, age = @age, gender = @gender,
            address = @address, phone = @phone, medicalHistory = @medicalHistory
        WHERE id = @id
      `);

    if (result.rowsAffected[0] === 0) {
      throw new Error('Patient not found');
    }

    return {
      id,
      ...patientData
    };
  }

  // Delete patient
  static async delete(id) {
    const result = await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM Patients WHERE id = @id');

    if (result.rowsAffected[0] === 0) {
      throw new Error('Patient not found');
    }
  }

  // Get patient's heart rate history
  static async getHeartRateHistory(patientId, limit = 100) {
    const result = await pool.request()
      .input('patientId', sql.Int, patientId)
      .input('limit', sql.Int, limit)
      .query(`
        SELECT TOP (@limit) * FROM HeartRateReadings
        WHERE patientId = @patientId
        ORDER BY timestamp DESC
      `);

    return result.recordset;
  }

  // Get patient's active alerts
  static async getActiveAlerts(patientId) {
    const result = await pool.request()
      .input('patientId', sql.Int, patientId)
      .query(`
        SELECT * FROM Alerts
        WHERE patientId = @patientId
        AND status = 'active'
        ORDER BY timestamp DESC
      `);

    return result.recordset;
  }
}

module.exports = PatientService;
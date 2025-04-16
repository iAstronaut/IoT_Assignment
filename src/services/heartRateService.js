const axios = require('axios');
const { connectDB, sql } = require('../database/db');

class HeartRateService {
    constructor() {
        this.baseUrl = 'https://app.coreiot.io/api';
        this.deviceId = '2b314740-090d-11f0-a887-6d1a184f2bb5';
        this._lastData = {
            oxygen: 0.0,
            heartbeat: 0,
            timestamp: 0
        };
    }

    async initialize(token) {
        this.token = token;
        await this.startPolling();
    }

    async startPolling() {
        setInterval(async () => {
            try {
                const data = await this.fetchTelemetryData();
                this._lastData = data;
                // Auto save measurements to database
                await this.saveMeasurement(data);
            } catch (error) {
                console.error('Error polling data:', error);
            }
        }, 1000);
    }

    async fetchTelemetryData() {
        try {
            const response = await axios.get(
                `${this.baseUrl}/plugins/telemetry/DEVICE/${this.deviceId}/values/timeseries`,
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${this.token}`
                    }
                }
            );

            if (response.status === 200) {
                const data = response.data;
                return {
                    oxygen: this._parseDoubleValue(data.oxygen?.[0]?.value),
                    heartbeat: this._parseDoubleValue(data.heartbeat?.[0]?.value),
                    timestamp: Date.now()
                };
            }
            throw new Error('Failed to fetch data');
        } catch (error) {
            console.error('Error fetching telemetry:', error);
            return this._lastData;
        }
    }

    _parseDoubleValue(value) {
        if (value == null) return 0.0;
        if (typeof value === 'number') return value;
        if (typeof value === 'string') return parseFloat(value) || 0.0;
        return 0.0;
    }

    getLatestData() {
        return this._lastData;
    }

    async saveMeasurement(data) {
        try {
            const pool = await connectDB();
            const status = this._calculateStatus(data.heartbeat);

            // Insert into database
            const result = await pool.request()
                .input('heartRate', sql.Float, data.heartbeat)
                .input('oxygen', sql.Float, data.oxygen)
                .input('timestamp', sql.DateTime, new Date(data.timestamp))
                .input('status', sql.VarChar(50), status)
                .query(`
                    INSERT INTO measurements (heart_rate, oxygen_level, measured_at, status)
                    VALUES (@heartRate, @oxygen, @timestamp, @status);
                    SELECT SCOPE_IDENTITY() AS id;
                `);

            const id = result.recordset[0].id;
            console.log('Saved measurement with ID:', id);

            return {
                id,
                heartRate: data.heartbeat,
                oxygen: data.oxygen,
                timestamp: new Date(data.timestamp),
                status
            };
        } catch (error) {
            console.error('Error saving measurement:', error);
            throw error;
        }
    }

    async getHistory(limit = 100) {
        try {
            const pool = await connectDB();
            const result = await pool.request()
                .input('limit', sql.Int, limit)
                .query(`
                    SELECT TOP (@limit)
                        id,
                        heart_rate as heartRate,
                        oxygen_level as oxygen,
                        measured_at as timestamp,
                        status
                    FROM measurements
                    ORDER BY measured_at DESC
                `);

            return result.recordset;
        } catch (error) {
            console.error('Error fetching history:', error);
            throw error;
        }
    }

    _calculateStatus(heartbeat) {
        if (heartbeat < 60) return 'Low';
        if (heartbeat > 100) return 'High';
        return 'Normal';
    }
}

module.exports = new HeartRateService();
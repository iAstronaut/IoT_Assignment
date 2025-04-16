# Heart Pulse Monitoring System - Backend

This is the Node.js backend for the Heart Pulse Monitoring System.

## Prerequisites

- Node.js (v14 or higher)
- SQL Server
- npm or yarn

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables:
- Copy `.env.example` to `.env`
- Update the database credentials and other settings in `.env`

3. Start the development server:
```bash
npm run dev
```

## API Endpoints

### Authentication
- POST `/api/auth/login` - User login

### Patients
- GET `/api/patients` - Get all patients
- GET `/api/patients/:id` - Get patient by ID
- POST `/api/patients` - Create new patient
- PUT `/api/patients/:id` - Update patient
- DELETE `/api/patients/:id` - Delete patient

### Heart Rate
- GET `/api/heart-rate/:patientId` - Get heart rate data for patient
- POST `/api/heart-rate` - Add new heart rate reading
- GET `/api/heart-rate/realtime/:patientId` - WebSocket endpoint for real-time updates

## WebSocket Events

- `heartRateUpdate` - Send heart rate update
- `heartRateData` - Receive heart rate data

## Database Schema

The database schema includes tables for:
- Users
- Patients
- HeartRateReadings
- Alerts

See `database/schema.sql` for detailed schema definition.
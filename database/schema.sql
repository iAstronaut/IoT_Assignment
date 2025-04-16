-- Create Users table
CREATE TABLE Users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(50) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL,
    role NVARCHAR(20) NOT NULL,
    createdAt DATETIME DEFAULT GETDATE()
);

-- Create Patients table
CREATE TABLE Patients (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender NVARCHAR(10) NOT NULL,
    address NVARCHAR(255),
    phone NVARCHAR(20),
    medicalHistory NVARCHAR(MAX),
    createdAt DATETIME DEFAULT GETDATE()
);

-- Create HeartRateReadings table
CREATE TABLE HeartRateReadings (
    id INT IDENTITY(1,1) PRIMARY KEY,
    patientId INT NOT NULL,
    heartRate INT NOT NULL,
    timestamp DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (patientId) REFERENCES Patients(id)
);

-- Create Alerts table
CREATE TABLE Alerts (
    id INT IDENTITY(1,1) PRIMARY KEY,
    patientId INT NOT NULL,
    type NVARCHAR(50) NOT NULL,
    value NVARCHAR(255) NOT NULL,
    timestamp DATETIME DEFAULT GETDATE(),
    status NVARCHAR(20) DEFAULT 'active',
    FOREIGN KEY (patientId) REFERENCES Patients(id)
);

-- Create indexes
CREATE INDEX idx_heart_rate_patient ON HeartRateReadings(patientId);
CREATE INDEX idx_heart_rate_timestamp ON HeartRateReadings(timestamp);
CREATE INDEX idx_alerts_patient ON Alerts(patientId);
CREATE INDEX idx_alerts_status ON Alerts(status);
CREATE DATABASE heart_pulse_db;
GO

USE heart_pulse_db;
GO

CREATE TABLE Users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(50) NOT NULL UNIQUE,
    password NVARCHAR(100) NOT NULL,
    role NVARCHAR(20) NOT NULL
);

-- Insert admin user with hashed password 'admin'
INSERT INTO Users (username, password, role)
VALUES ('admin', '$2a$10$rPiEAgQNIT1TCoKi3Eqq8eVWBKAW0xm9Y76VyCQ9V5TzPi0I1LW4.', 'admin');

CREATE TABLE Patients (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender NVARCHAR(10) NOT NULL,
    address NVARCHAR(200),
    phone NVARCHAR(20),
    medicalHistory NVARCHAR(MAX),
    createdAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE HeartRates (
    id INT IDENTITY(1,1) PRIMARY KEY,
    patientId INT NOT NULL,
    heartRate INT NOT NULL,
    timestamp DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (patientId) REFERENCES Patients(id)
);

CREATE TABLE Alerts (
    id INT IDENTITY(1,1) PRIMARY KEY,
    patientId INT NOT NULL,
    type NVARCHAR(50) NOT NULL,
    message NVARCHAR(200) NOT NULL,
    status NVARCHAR(20) DEFAULT 'active',
    createdAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (patientId) REFERENCES Patients(id)
);
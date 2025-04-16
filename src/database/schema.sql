USE heart_pulse_db;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[HeartRateReadings]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[HeartRateReadings](
        [id] [int] IDENTITY(1,1) PRIMARY KEY,
        [patientId] [int] NOT NULL,
        [heartRate] [float] NOT NULL,
        [oxygen] [float] NOT NULL,
        [timestamp] [datetime] NOT NULL DEFAULT GETDATE()
    )
END

-- Create measurements table
CREATE TABLE measurements (
    id INT IDENTITY(1,1) PRIMARY KEY,
    heart_rate FLOAT NOT NULL,
    oxygen_level FLOAT NOT NULL,
    measured_at DATETIME NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);
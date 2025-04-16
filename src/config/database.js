const sql = require('mssql');
require('dotenv').config();

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_NAME,
  port: 1433,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true
  }
};

console.log('Connecting to database with config:', config);

module.exports = {
  connect: async () => {
    try {
      const pool = await sql.connect(config);
      console.log('Database connected successfully');
      return pool;
    } catch (err) {
      console.log('Database connection failed:', err);
      throw err;
    }
  },
  sql: sql
};
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const database = require('../config/database');
const axios = require('axios');

class AuthService {
  // Generate JWT token
  static generateToken(user) {
    return jwt.sign(
      {
        userId: user.id,
        username: user.username,
        role: user.role
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
  }

  // Verify JWT token
  static verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  // Register new user
  static async register(userData) {
    const { username, password, role } = userData;
    const pool = await database.connect();

    // Check if username exists
    const existingUser = await pool.request()
      .input('username', database.sql.NVarChar, username)
      .query('SELECT id FROM Users WHERE username = @username');

    if (existingUser.recordset.length > 0) {
      throw new Error('Username already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const result = await pool.request()
      .input('username', database.sql.NVarChar, username)
      .input('password', database.sql.NVarChar, hashedPassword)
      .input('role', database.sql.NVarChar, role)
      .query(`
        INSERT INTO Users (username, password, role)
        VALUES (@username, @password, @role)
        SELECT SCOPE_IDENTITY() as id
      `);

    const userId = result.recordset[0].id;

    // Generate token
    const token = this.generateToken({ id: userId, username, role });

    return {
      token,
      user: {
        id: userId,
        username,
        role
      }
    };
  }

  // Login user
  static async login(credentials) {
    const { username, password } = credentials;
    const pool = await database.connect();

    try {
      // Get user
      const result = await pool.request()
        .input('username', database.sql.NVarChar, username)
        .query('SELECT * FROM Users WHERE username = @username');

      const user = result.recordset[0];

      if (!user) {
        throw new Error('Invalid credentials');
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password);
      if (!isValidPassword) {
        throw new Error('Invalid credentials');
      }

      // Generate token
      const token = this.generateToken(user);

      return {
        token,
        user: {
          id: user.id,
          username: user.username,
          role: user.role
        }
      };
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }

  // Refresh token
  static async refreshToken(oldToken) {
    try {
      const decoded = this.verifyToken(oldToken);
      const pool = await database.connect();

      // Get user
      const result = await pool.request()
        .input('userId', database.sql.Int, decoded.userId)
        .query('SELECT * FROM Users WHERE id = @userId');

      const user = result.recordset[0];

      if (!user) {
        throw new Error('User not found');
      }

      // Generate new token
      const token = this.generateToken(user);

      return {
        token,
        user: {
          id: user.id,
          username: user.username,
          role: user.role
        }
      };
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  static coreIoTBaseUrl = 'https://app.coreiot.io/api';
  static coreIoTUsername = 'an.nguyencse03@gmail.com';
  static coreIoTPassword = '02121209An';

  // Login to Core IoT
  static async loginCoreIoT() {
    try {
      const response = await axios.post(
        `${this.coreIoTBaseUrl}/auth/login`,
        {
          username: this.coreIoTUsername,
          password: this.coreIoTPassword,
        },
        {
          headers: {'Content-Type': 'application/json'}
        }
      );

      console.log('CoreIoT Login Status:', response.status);
      console.log('CoreIoT Response:', response.data);

      if (response.status === 200) {
        return response.data.token;
      }
      return null;
    } catch (error) {
      console.error('CoreIoT Login error:', error.response?.data || error.message);
      return null;
    }
  }
}

module.exports = AuthService;
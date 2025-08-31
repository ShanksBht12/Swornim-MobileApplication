require("dotenv").config();

const DatabaseConfig = {
  host: process.env.DB_HOST || 'localhost',
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'swornim',
  port: process.env.DB_PORT || 5432,
  dialect: "postgres",
  logging: process.env.NODE_ENV === "development" ? console.log : false,
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000,
  },
};

const CloudinaryConfig = {
  cloudName: process.env.CLOUDINARY_CLOUD_NAME,
  apiKey: process.env.CLOUDINARY_API_KEY,
  apiSecret: process.env.CLOUDINARY_API_SECRET,
};

const AppConfig = {
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET || "your-access-secret-key",
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || "your-refresh-secret-key",
  jwtAccessExpiry: process.env.JWT_ACCESS_EXPIRY || "15m",
  jwtRefreshExpiry: process.env.JWT_REFRESH_EXPIRY || "7d",
  frontendUrl: process.env.FRONT_END_URL || "http://10.0.2.2:3000",
  port: process.env.PORT || 9005,
  host: process.env.HOST || "127.0.0.1",
  khaltiSecretKey: process.env.KHALTI_SECRET_KEY,
  khaltiBaseUrl: process.env.KHALTI_BASE_URL || "https://a.khalti.com/api/v2",
  khaltiPublicKey: process.env.KHALTI_PUBLIC_KEY,
};

const EmailConfig = {
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
  from: {
    email: process.env.FROM_EMAIL,
    name: process.env.FROM_NAME,
  },
};

module.exports = {
  DatabaseConfig,
  CloudinaryConfig,
  AppConfig,
  EmailConfig,
};

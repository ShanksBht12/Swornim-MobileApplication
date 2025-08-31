const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const randomStringGenerate = (length = 100) => {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

const generateUUID = () => {
  return crypto.randomUUID();
};

const generateSecureToken = (length = 32) => {
  return crypto.randomBytes(length).toString("hex");
};

const deleteFile = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  } catch (error) {
    console.log("Error deleting file:", error);
  }
};

const formatPhoneNumber = (phone) => {
  return phone.replace(/\D/g, "");
};

const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const isStrongPassword = (password) => {
  const strongPasswordRegex =
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$/;
  return strongPasswordRegex.test(password);
};

const safeUserData = (user) => {
  const userData = user.dataValues || user;
  const {
    password,
    resetToken,
    resetTokenExpiry,
    emailVerificationToken,
    emailVerificationTokenExpiry,
    activationToken,
    ...safeData
  } = userData;
  return safeData;
};

module.exports = {
  randomStringGenerate,
  generateUUID,
  generateSecureToken,
  deleteFile,
  formatPhoneNumber,
  isValidEmail,
  isStrongPassword,
  safeUserData,
};

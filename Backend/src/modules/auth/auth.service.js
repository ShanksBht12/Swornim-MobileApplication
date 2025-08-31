const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { UserStatus } = require("../../config/constants");
const { AppConfig } = require("../../config/config");
const {
  randomStringGenerate,
  generateSecureToken,
  formatPhoneNumber,
} = require("../../utilities/helpers");
const SessionModel = require("./session.model");
const emailService = require("../../services/email.service");

class AuthService {
  async transformRegisterUser(req) {
    try {
      const data = req.body;

      // Handle profile image upload
      if (req.file) {
        data.profileImage = req.file.path;
      }

      // Hash password
      data.password = await bcrypt.hash(data.password, 12);

      // Set default status
      data.userStatus = UserStatus.PENDING;
      data.isActive = true;
      data.isEmailVerified = false;

      // Format phone number
      data.phone = formatPhoneNumber(data.phone);

      // Generate email verification token
      data.emailVerificationToken = generateSecureToken(32);
      data.emailVerificationTokenExpiry = new Date(
        Date.now() + 24 * 60 * 60 * 1000
      ); // 24 hours

      return data;
    } catch (exception) {
      throw exception;
    }
  }
  async generateTokens(user) {
    try {
      const payload = {
        sub: user.id,
        email: user.email,
        userType: user.userType,
        typ: "Bearer",
      };

      const accessToken = jwt.sign(payload, AppConfig.jwtAccessSecret, {
        expiresIn: AppConfig.jwtAccessExpiry,
      });

      const refreshToken = jwt.sign(
        { ...payload, typ: "Refresh" },
        AppConfig.jwtRefreshSecret,
        { expiresIn: AppConfig.jwtRefreshExpiry }
      );

      return { accessToken, refreshToken };
    } catch (exception) {
      throw exception;
    }
  }

  async createSession(user, tokens) {
    try {
      const { accessToken, refreshToken } = tokens;

      // Create masked versions for database storage
      const accessTokenMasked = randomStringGenerate(32);
      const refreshTokenMasked = randomStringGenerate(32);

      // Calculate expiry time for refresh token
      const refreshTokenDecoded = jwt.decode(refreshToken);
      const expiresAt = new Date(refreshTokenDecoded.exp * 1000);

      const sessionData = {
        userId: user.id,
        accessTokenActual: accessToken,
        accessTokenMasked,
        refreshTokenActual: refreshToken,
        refreshTokenMasked,
        userSessionData: JSON.stringify({
          loginTime: new Date(),
          userAgent: null, // You can add req.headers['user-agent'] if available
          ipAddress: null, // You can add req.ip if available
        }),
        isActive: true,
        expiresAt,
      };

      const session = await SessionModel.create(sessionData);

      return {
        accessToken: accessTokenMasked,
        refreshToken: refreshTokenMasked,
        sessionId: session.id,
      };
    } catch (exception) {
      throw exception;
    }
  }

  async validatePassword(plainPassword, hashedPassword) {
    try {
      return await bcrypt.compare(plainPassword, hashedPassword);
    } catch (exception) {
      throw exception;
    }
  }

  async getSessionByToken(token) {
    try {
      const session = await SessionModel.findOne({
        where: {
          accessTokenMasked: token,
          isActive: true,
          expiresAt: { [require("sequelize").Op.gt]: new Date() },
        },
      });
      return session;
    } catch (exception) {
      throw exception;
    }
  }

  async refreshAccessToken(refreshToken) {
    try {
      const session = await SessionModel.findOne({
        where: {
          refreshTokenMasked: refreshToken,
          isActive: true,
          expiresAt: { [require("sequelize").Op.gt]: new Date() },
        },
      });

      if (!session) {
        throw {
          code: 401,
          status: "INVALID_REFRESH_TOKEN",
          message: "Invalid or expired refresh token",
        };
      }

      // Verify the actual refresh token
      const decoded = jwt.verify(
        session.refreshTokenActual,
        AppConfig.jwtRefreshSecret
      );

      // Generate new access token
      const newAccessToken = jwt.sign(
        {
          sub: decoded.sub,
          email: decoded.email,
          userType: decoded.userType,
          typ: "Bearer",
        },
        AppConfig.jwtAccessSecret,
        { expiresIn: AppConfig.jwtAccessExpiry }
      );

      // Update session with new access token
      const newAccessTokenMasked = randomStringGenerate(32);
      await session.update({
        accessTokenActual: newAccessToken,
        accessTokenMasked: newAccessTokenMasked,
      });

      return {
        accessToken: newAccessTokenMasked,
      };
    } catch (exception) {
      throw exception;
    }
  }

  async revokeSession(token) {
    try {
      const session = await SessionModel.findOne({
        where: {
          accessTokenMasked: token,
          isActive: true,
        },
      });

      if (session) {
        await session.update({ isActive: false });
      }

      return true;
    } catch (exception) {
      throw exception;
    }
  }

  async revokeAllUserSessions(userId) {
    try {
      await SessionModel.update(
        { isActive: false },
        { where: { userId, isActive: true } }
      );
      return true;
    } catch (exception) {
      throw exception;
    }
  }

  async generatePasswordResetToken(user) {
    try {
      const resetToken = generateSecureToken(32);
      const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

      await user.update({
        resetToken,
        resetTokenExpiry,
      });

      return resetToken;
    } catch (exception) {
      throw exception;
    }
  }

  async resetPassword(token, newPassword) {
    try {
      const hashedPassword = await bcrypt.hash(newPassword, 12);

      return {
        password: hashedPassword,
        resetToken: null,
        resetTokenExpiry: null,
      };
    } catch (exception) {
      throw exception;
    }
  }

  async sendVerificationEmail(user) {
    try {
      if (!user.emailVerificationToken) {
        const verificationToken = generateSecureToken(32);
        const verificationTokenExpiry = new Date(
          Date.now() + 24 * 60 * 60 * 1000
        ); // 24 hours

        await user.update({
          emailVerificationToken: verificationToken,
          emailVerificationTokenExpiry: verificationTokenExpiry,
        });
      }

      await emailService.sendVerificationEmail(
        user,
        user.emailVerificationToken
      );
      return true;
    } catch (exception) {
      throw exception;
    }
  }

  async verifyEmail(token) {
    try {
      return {
        isEmailVerified: true,
        emailVerificationToken: null,
        emailVerificationTokenExpiry: null,
        userStatus: UserStatus.ACTIVE,
      };
    } catch (exception) {
      throw exception;
    }
  }
}

const authSvc = new AuthService();
module.exports = authSvc;

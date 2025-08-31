const authSvc = require("./auth.service");
const userSvc = require("../user/user.service");
const emailService = require("../../services/email.service");
const { deleteFile, safeUserData } = require("../../utilities/helpers");
const { UserStatus } = require("../../config/constants");

class AuthController {
  async registerUser(req, res, next) {
    try {
      // Check if email already exists
      const existingUser = await userSvc.getSingleRowByFilter({
        email: req.body.email,
      });
      if (existingUser) {
        // Delete uploaded file if user already exists
        if (req.file) {
          deleteFile(req.file.path);
        }
        throw {
          code: 409,
          status: "EMAIL_ALREADY_EXISTS",
          message: "Email address is already registered",
        };
      }

      // Transform user data
      const userData = await authSvc.transformRegisterUser(req);

      // Create user
      const user = await userSvc.createUser(userData);

      // Send verification email
      await authSvc.sendVerificationEmail(user);

      // Return success response without auto-activating
      res.status(201).json({
        data: {
          email: user.email,
          message: "Registration successful! Please check your email to verify your account.",
        },
        message: "User registered successfully. Please verify your email to activate your account.",
        status: "CREATED",
        options: null,
      });
    } catch (exception) {
      // Clean up uploaded file on error
      if (req.file) {
        deleteFile(req.file.path);
      }
      next(exception);
    }
  }

  async loginUser(req, res, next) {
    try {
      const { email, password } = req.body;

      // Get user by email
      const user = await userSvc.getSingleRowByFilter({ email });
      if (!user) {
        throw {
          code: 401,
          status: "INVALID_CREDENTIALS",
          message: "Invalid email or password",
        };
      }

      // Validate password
      const isValidPassword = await authSvc.validatePassword(
        password,
        user.password
      );
      if (!isValidPassword) {
        throw {
          code: 401,
          status: "INVALID_CREDENTIALS",
          message: "Invalid email or password",
        };
      }

      // Check if email is verified
      if (!user.isEmailVerified) {
        throw {
          code: 403,
          status: "EMAIL_NOT_VERIFIED",
          message: "Please verify your email address before logging in. Check your email for the verification link.",
        };
      }

      // Check if user is active
      if (!user.isActive || user.userStatus !== UserStatus.ACTIVE) {
        throw {
          code: 403,
          status: "ACCOUNT_ACCESS_DENIED",
          message: "Your account is not active. Please contact support.",
        };
      }

      // Generate tokens
      const tokens = await authSvc.generateTokens(user);

      // Create session
      const sessionTokens = await authSvc.createSession(user, tokens);

      // Update last login
      await userSvc.updateSingleRowByFilter(
        { lastLoginAt: new Date() },
        { id: user.id }
      );

      res.json({
        data: {
          user: safeUserData(user),
          tokens: sessionTokens,
        },
        message: "Login successful",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async refreshToken(req, res, next) {
    try {
      const { refreshToken } = req.body;

      const newTokens = await authSvc.refreshAccessToken(refreshToken);

      res.json({
        data: newTokens,
        message: "Token refreshed successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async logoutUser(req, res, next) {
    try {
      const token = req.headers.authorization?.replace("Bearer ", "");

      if (token) {
        await authSvc.revokeSession(token);
      }

      res.json({
        data: null,
        message: "Logout successful",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async logoutAllSessions(req, res, next) {
    try {
      const userId = req.loggedInUser.id;

      await authSvc.revokeAllUserSessions(userId);

      res.json({
        data: null,
        message: "All sessions logged out successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async forgotPassword(req, res, next) {
    try {
      const { email } = req.body;

      const user = await userSvc.getSingleRowByFilter({ email });
      if (!user) {
        // Don't reveal if email exists or not for security
        res.json({
          data: null,
          message:
            "If the email address exists in our system, you will receive a password reset link.",
          status: "OK",
          options: null,
        });
        return;
      }

      // Generate password reset token
      const resetToken = await authSvc.generatePasswordResetToken(user);

      // Send reset email
      await emailService.sendPasswordResetEmail(user, resetToken);

      res.json({
        data: null,
        message:
          "If the email address exists in our system, you will receive a password reset link.",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async resetPassword(req, res, next) {
    try {
      const { token, password } = req.body;

      const user = await userSvc.getSingleRowByFilter({
        resetToken: token,
        resetTokenExpiry: { [require("sequelize").Op.gt]: new Date() },
      });

      if (!user) {
        throw {
          code: 400,
          status: "INVALID_RESET_TOKEN",
          message: "Invalid or expired reset token",
        };
      }

      // Reset password
      const updateData = await authSvc.resetPassword(token, password);

      // Update user
      await userSvc.updateSingleRowByFilter(updateData, { id: user.id });

      // Revoke all sessions for security
      await authSvc.revokeAllUserSessions(user.id);

      res.json({
        data: null,
        message:
          "Password reset successfully. Please log in with your new password.",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async changePassword(req, res, next) {
    try {
      const { currentPassword, newPassword } = req.body;
      const userId = req.loggedInUser.id;

      const user = await userSvc.getSingleRowByFilter({ id: userId });
      if (!user) {
        throw {
          code: 404,
          status: "USER_NOT_FOUND",
          message: "User not found",
        };
      }

      // Validate current password
      const isValidPassword = await authSvc.validatePassword(
        currentPassword,
        user.password
      );
      if (!isValidPassword) {
        throw {
          code: 400,
          status: "INVALID_CURRENT_PASSWORD",
          message: "Current password is incorrect",
        };
      }

      // Update password
      const updateData = await authSvc.resetPassword(null, newPassword);
      await userSvc.updateSingleRowByFilter(updateData, { id: userId });

      // Revoke all other sessions for security
      await authSvc.revokeAllUserSessions(userId);

      res.json({
        data: null,
        message: "Password changed successfully. Please log in again.",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async verifyEmail(req, res, next) {
    try {
      // Support both GET (from email link) and POST (API)
      const token = req.method === 'GET' ? req.query.activate : req.body.token;

      console.log('🔍 Email verification attempt:', {
        method: req.method,
        token: token ? `${token.substring(0, 10)}...` : 'missing',
        query: req.query,
        body: req.body
      });

      if (!token) {
        if (req.method === 'GET') {
          return res.status(400).send(`
            <html>
              <head><title>Invalid Verification Link</title></head>
              <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                <h2 style="color: #dc3545;">❌ Invalid Verification Link</h2>
                <p>The verification token is missing or invalid.</p>
                <p>Please request a new verification email.</p>
              </body>
            </html>
          `);
        } else {
          throw {
            code: 400,
            status: "MISSING_TOKEN",
            message: "Verification token is required",
          };
        }
      }

      // Find user by verification token
      const user = await userSvc.getSingleRowByFilter({
        emailVerificationToken: token,
      });

      console.log('🔍 User lookup result:', {
        found: !!user,
        email: user?.email,
        isVerified: user?.isEmailVerified,
        tokenExpiry: user?.emailVerificationTokenExpiry
      });

      if (!user) {
        if (req.method === 'GET') {
          return res.status(400).send(`
            <html>
              <head><title>Invalid Verification Link</title></head>
              <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                <h2 style="color: #dc3545;">❌ Invalid Verification Link</h2>
                <p>The verification token is invalid or has already been used.</p>
                <p>Please request a new verification email if needed.</p>
              </body>
            </html>
          `);
        } else {
          throw {
            code: 400,
            status: "INVALID_VERIFICATION_TOKEN",
            message: "Invalid or expired verification token",
          };
        }
      }

      // Check if token is expired - FIXED: Use proper date comparison
      const now = new Date();
      const tokenExpiry = new Date(user.emailVerificationTokenExpiry);
      
      if (tokenExpiry < now) {
        console.log('🔍 Token expired:', {
          tokenExpiry: tokenExpiry.toISOString(),
          now: now.toISOString()
        });
        
        if (req.method === 'GET') {
          return res.status(400).send(`
            <html>
              <head><title>Verification Link Expired</title></head>
              <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                <h2 style="color: #dc3545;">⏰ Verification Link Expired</h2>
                <p>Your verification link has expired.</p>
                <p>Please request a new verification email.</p>
              </body>
            </html>
          `);
        } else {
          throw {
            code: 400,
            status: "EXPIRED_VERIFICATION_TOKEN",
            message: "Verification token has expired",
          };
        }
      }

      // Update user status to active and mark email as verified
      const updateData = {
        isEmailVerified: true,
        isActive: true,
        userStatus: UserStatus.ACTIVE,
        emailVerificationToken: null,
        emailVerificationTokenExpiry: null,
      };

      const updatedUser = await userSvc.updateSingleRowByFilter(updateData, {
        id: user.id,
      });

      console.log('✅ Email verification successful for:', user.email);

      // If GET request (from email link), return HTML success page
      if (req.method === 'GET') {
        return res.send(`
          <html>
            <head><title>Email Verified Successfully</title></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
              <h2 style="color: #28a745;">✅ Email Verified Successfully!</h2>
              <p>Welcome ${user.name}! Your account has been activated.</p>
              <p>You can now log in to your account and access all features.</p>
              <div style="margin-top: 30px;">
                <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/login" 
                   style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                  Go to Login
                </a>
              </div>
            </body>
          </html>
        `);
      }

      // Otherwise return JSON response
      res.json({
        data: safeUserData(updatedUser),
        message: "Email verified successfully. Your account is now active.",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      console.error('❌ Email verification error:', exception);
      
      if (req.method === 'GET') {
        return res.status(500).send(`
          <html>
            <head><title>Verification Failed</title></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
              <h2 style="color: #dc3545;">❌ Verification Failed</h2>
              <p>Something went wrong during email verification.</p>
              <p>Please try again or contact support.</p>
            </body>
          </html>
        `);
      }
      next(exception);
    }
  }

  async resendVerificationEmail(req, res, next) {
    try {
      const { email } = req.body;

      const user = await userSvc.getSingleRowByFilter({ email });
      if (!user) {
        throw {
          code: 404,
          status: "USER_NOT_FOUND",
          message: "User not found",
        };
      }

      if (user.isEmailVerified) {
        throw {
          code: 400,
          status: "EMAIL_ALREADY_VERIFIED",
          message: "Email is already verified",
        };
      }

      // Send verification email (this will generate a new token)
      await authSvc.sendVerificationEmail(user);

      res.json({
        data: null,
        message: "Verification email sent successfully. Please check your email.",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }

  async getProfile(req, res, next) {
    try {
      const user = req.loggedInUser;

      res.json({
        data: safeUserData(user),
        message: "Profile fetched successfully",
        status: "OK",
        options: null,
      });
    } catch (exception) {
      next(exception);
    }
  }
}

const authCtrl = new AuthController();
module.exports = authCtrl;
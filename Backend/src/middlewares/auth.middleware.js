console.log('Auth middleware loaded');
const jwt = require("jsonwebtoken");
const { AppConfig } = require("../config/config");
const authSvc = require("../modules/auth/auth.service");
const userSvc = require("../modules/user/user.service");
const { UserType } = require("../config/constants");

const auth = (roles = []) => {
  return async (req, res, next) => {
    try {
      console.log('=== AUTH MIDDLEWARE START ===');
      console.log('Headers:', req.headers);
      const authHeader = req.headers.authorization;
      console.log('Auth header:', authHeader);

      // 1. Token extraction
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        console.log('No Bearer token');
        throw {
          code: 401,
          status: "UNAUTHORIZED",
          message: "Access token is required",
        };
      }
      const token = authHeader.replace("Bearer ", "");
      console.log('Token:', token);

      // 2. Session lookup
      console.log('[DEBUG] About to call authSvc.getSessionByToken');
      const session = await authSvc.getSessionByToken(token);
      console.log('Session:', session);
      if (!session) {
        console.log('No session found');
        throw {
          code: 401,
          status: "INVALID_TOKEN",
          message: "Invalid or expired access token",
        };
      }

      // 3. JWT verification
      console.log('[DEBUG] About to verify JWT');
      let decoded;
      try {
        decoded = jwt.verify(session.accessTokenActual, AppConfig.jwtAccessSecret);
        console.log('JWT decoded:', decoded);
      } catch (jwtError) {
        console.log('JWT verification failed:', jwtError.message);
        await session.update({ isActive: false });
        throw {
          code: 401,
          status: "INVALID_TOKEN",
          message: "Invalid or expired access token",
        };
      }

      // 4. User lookup
      console.log('[DEBUG] About to call userSvc.getSingleRowByFilter');
      const user = await userSvc.getSingleRowByFilter({ id: decoded.sub });
      console.log('User:', user);
      if (!user) {
        console.log('User not found');
        throw {
          code: 401,
          status: "USER_NOT_FOUND",
          message: "User not found",
        };
      }

      // 5. User status checks
      console.log('[DEBUG] Checking user status');
      if (!user.isActive) {
        console.log('Auth failed: User inactive');
        throw {
          code: 403,
          status: "ACCOUNT_DEACTIVATED",
          message: "Your account has been deactivated",
        };
      }
      if (!user.isEmailVerified) {
        console.log('Auth failed: Email not verified');
        throw {
          code: 403,
          status: "EMAIL_NOT_VERIFIED",
          message: "Please verify your email address",
        };
      }
      if (roles.length > 0 && !roles.includes(user.userType)) {
        console.log('Auth failed: Insufficient permissions');
        throw {
          code: 403,
          status: "INSUFFICIENT_PERMISSIONS",
          message: "You don't have permission to access this resource",
        };
      }

      req.loggedInUser = user;
      req.currentSession = session;
      req.user = user;
      console.log('=== AUTH MIDDLEWARE END ===');
      next();
    } catch (exception) {
      console.log('Auth middleware error:', exception);
      next(exception);
    }
  };
};

// Middleware for checking specific user types
const requireUserType = (...userTypes) => {
  return auth(userTypes);
};

// Middleware for service providers only
const requireServiceProvider = () => {
  return auth([
    UserType.PHOTOGRAPHER,
    UserType.MAKEUP_ARTIST,
    UserType.DECORATOR,
    UserType.VENUE,
    UserType.CATERER,
    UserType.EVENT_ORGANIZER, // Allow event organizers
  ]);
};

// Middleware for clients only
const requireClient = () => {
  return auth([UserType.CLIENT]);
};

// Optional auth middleware (doesn't throw error if no token)
const optionalAuth = () => {
  return async (req, res, next) => {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        return next();
      }

      const token = authHeader.replace("Bearer ", "");
      const session = await authSvc.getSessionByToken(token);

      if (session) {
        try {
          const decoded = jwt.verify(
            session.accessTokenActual,
            AppConfig.jwtAccessSecret
          );
          const user = await userSvc.getSingleRowByFilter({ id: decoded.sub });

          if (user && user.isActive) {
            req.loggedInUser = user;
            req.currentSession = session;
          }
        } catch (jwtError) {
          // Token is invalid, but don't throw error for optional auth
          await session.update({ isActive: false });
        }
      }

      next();
    } catch (exception) {
      // For optional auth, continue even if there's an error
      next();
    }
  };
};

module.exports = auth;
module.exports.requireUserType = requireUserType;
module.exports.requireServiceProvider = requireServiceProvider;
module.exports.requireClient = requireClient;
module.exports.optionalAuth = optionalAuth;

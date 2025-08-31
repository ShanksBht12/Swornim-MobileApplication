const Joi = require("joi");

const bodyValidator = (schema) => {
  return (req, res, next) => {
    // Debug logging for file uploads and route
    console.log('VALIDATOR DEBUG: req.file:', req.file);
    console.log('VALIDATOR DEBUG: req.body:', req.body);
    console.log('VALIDATOR DEBUG: req.originalUrl:', req.originalUrl, 'req.method:', req.method);

    // Parse JSON-encoded arrays in form fields
    if (req.body) {
      Object.keys(req.body).forEach(key => {
        const value = req.body[key];
        if (typeof value === 'string' && value.startsWith('[') && value.endsWith(']')) {
          try {
            req.body[key] = JSON.parse(value);
            console.log('VALIDATOR DEBUG: Parsed JSON array for field:', key, 'value:', req.body[key]);
          } catch (e) {
            console.log('VALIDATOR DEBUG: Failed to parse JSON for field:', key, 'value:', value);
          }
        }
      });
    }

    // Loosened route check for portfolio image upload
    if (
      req.file &&
      (req.originalUrl.includes("/photographers/portfolio/images") ||
       req.originalUrl.includes("/makeup-artists/portfolio/images") ||
       req.originalUrl.includes("/decorators/portfolio/images") ||
       req.originalUrl.includes("/venues/portfolio/images") ||
       req.originalUrl.includes("/caterers/portfolio/images")) &&
      req.method === "POST"
    ) {
      return next();
    }

    const { error } = schema.validate(req.body, { abortEarly: false });

    if (error) {
      const errors = error.details.map((detail) => ({
        message: detail.message,
        path: detail.path,
      }));
      return res.status(400).json({ errors });
    }

    next();
  };
};

module.exports = bodyValidator;

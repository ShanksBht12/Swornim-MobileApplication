const nodemailer = require("nodemailer");
const { EmailConfig, AppConfig } = require("../config/config");
const fs = require("fs");
const path = require("path");

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: EmailConfig.host,
      port: EmailConfig.port,
      secure: EmailConfig.secure,
      auth: EmailConfig.auth,
    });
  }

  async sendEmail(to, subject, htmlContent, textContent = null) {
    try {
      const mailOptions = {
        from: `${EmailConfig.from.name} <${EmailConfig.from.email}>`,
        to,
        subject,
        html: htmlContent,
        text: textContent || htmlContent.replace(/<[^>]*>/g, ""),
      };

      const result = await this.transporter.sendMail(mailOptions);
      console.log("Email sent successfully:", result.messageId);
      return result;
    } catch (error) {
      console.error("Failed to send email:", error);
      throw error;
    }
  }

  async sendVerificationEmail(user, token) {
    try {
      // FIXED: Use the correct backend URL from your .env
      // Your server runs on port 9005, not 9009
      const verificationUrl = `http://localhost:9009/api/v1/auth/verify-email?activate=${token}`;
      
      // Debug logging
      console.log('🔍 DEBUG - Email Verification:');
      console.log('User:', user.email);
      console.log('Token:', token);
      console.log('Verification URL:', verificationUrl);

      const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Verify Your Email</title>
          <style>
            body { 
              font-family: Arial, sans-serif; 
              line-height: 1.6; 
              color: #333; 
              margin: 0; 
              padding: 0; 
            }
            .container { 
              max-width: 600px; 
              margin: 0 auto; 
              padding: 20px; 
            }
            .header { 
              background: #007bff; 
              color: white; 
              padding: 20px; 
              text-align: center; 
              border-radius: 5px 5px 0 0;
            }
            .content { 
              padding: 20px; 
              background: #f9f9f9; 
              border-radius: 0 0 5px 5px;
            }
            .button { 
              display: inline-block; 
              padding: 15px 30px; 
              background: #007bff; 
              color: white !important; 
              text-decoration: none; 
              border-radius: 5px; 
              margin: 20px 0;
              font-weight: bold;
              text-align: center;
            }
            .url-box {
              background: #fff;
              border: 1px solid #ddd;
              padding: 10px;
              border-radius: 3px;
              word-break: break-all;
              font-family: monospace;
              font-size: 12px;
              margin: 10px 0;
            }
            .footer { 
              padding: 20px; 
              text-align: center; 
              font-size: 12px; 
              color: #666; 
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome ${user.name}!</h1>
            </div>
            <div class="content">
              <h2>Please verify your email address</h2>
              <p>Thank you for registering! Please click the button below to verify your email address and activate your account.</p>
              
              <div style="text-align: center;">
                <a href="${verificationUrl}" class="button">Verify Email Address</a>
              </div>
              
              <p><strong>Alternative:</strong> If the button doesn't work, copy and paste this link in your browser:</p>
              <div class="url-box">
                ${verificationUrl}
              </div>
              
              <p><strong>Important:</strong> This link will expire in 24 hours for security reasons.</p>
              
              <p>If you didn't create this account, please ignore this email.</p>
            </div>
            <div class="footer">
              <p>This is an automated email, please do not reply.</p>
            </div>
          </div>
        </body>
        </html>
      `;

      const subject = "Verify Your Email Address";
      const result = await this.sendEmail(user.email, subject, htmlContent);
      
      console.log('✅ Verification email sent successfully to:', user.email);
      return result;
      
    } catch (error) {
      console.error('❌ Failed to send verification email:', error);
      throw error;
    }
  }

  async sendPasswordResetEmail(user, token) {
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password/${token}`;

    const htmlTemplate = this.getEmailTemplate("password_reset.html");
    const htmlContent = htmlTemplate
      .replace("{{USER_NAME}}", user.name)
      .replace("{{RESET_URL}}", resetUrl);

    const subject = "Reset Your Password";

    await this.sendEmail(user.email, subject, htmlContent);
  }

  getEmailTemplate(templateName) {
    try {
      const templatePath = path.join(
        __dirname,
        "../templates/emails",
        templateName
      );
      return fs.readFileSync(templatePath, "utf8");
    } catch (error) {
      console.error("Failed to load email template:", error);
      // Return a basic template as fallback
      if (templateName.includes("verification")) {
        return `
          <html>
            <body>
              <h2>Welcome {{USER_NAME}}!</h2>
              <p>Please click the link below to verify your email address:</p>
              <a href="{{VERIFICATION_URL}}">Verify Email</a>
            </body>
          </html>
        `;
      } else {
        return `
          <html>
            <body>
              <h2>Password Reset</h2>
              <p>Hi {{USER_NAME}},</p>
              <p>Click the link below to reset your password:</p>
              <a href="{{RESET_URL}}">Reset Password</a>
            </body>
          </html>
        `;
      }
    }
  }

  getUserPublicProfile(user) {
    if (!user) return null;
    // Get the raw user data (not sanitized)
    const userData = user.dataValues || user;
    const publicData = safeUserData(user);
    // Add the token from the raw data
    publicData.emailVerificationToken = userData.emailVerificationToken;
    return publicData;
  }
}

const emailService = new EmailService();
module.exports = emailService;
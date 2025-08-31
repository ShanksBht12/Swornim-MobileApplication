const paymentService = require('./payment.service');
const { UserType } = require('../../config/constants');

// Initialize Khalti payment for a booking
async function initializeKhaltiPayment(req, res, next) {
  try {
    const { bookingId } = req.params;
    const userId = req.user?.id || req.loggedInUser?.id;

    if (!userId) {
      return res.status(401).json({ 
        error: 'User not authenticated',
        status: 'UNAUTHORIZED'
      });
    }

    const result = await paymentService.initializeKhaltiPayment(bookingId, userId);
    
    res.json({
      success: true,
      data: result,
      message: "Payment initialized successfully",
      status: "PAYMENT_INITIALIZED"
    });

  } catch (error) {
    console.error('Initialize payment error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Verify Khalti payment callback - FIXED VERSION
async function verifyKhaltiPayment(req, res, next) {
  try {
    const { pidx } = req.body;

    if (!pidx) {
      return res.status(400).json({
        error: 'Payment ID (pidx) is required',
        status: 'MISSING_PIDX'
      });
    }

    const result = await paymentService.verifyKhaltiPayment(pidx);
    
    // MAIN FIX: Always return 200 status to prevent frontend errors
    res.json({
      success: result.success,
      data: result,
      message: result.message,
      status: result.success ? "PAYMENT_VERIFIED" : "PAYMENT_VERIFICATION_FAILED"
    });

  } catch (error) {
    console.error('Verify payment error:', error);
    
    // MAIN FIX: Return proper response instead of 500 error
    res.json({
      success: false,
      error: error.message || 'Payment verification failed',
      status: 'VERIFICATION_ERROR'
    });
  }
}

// Get payment status for a booking
async function getPaymentStatus(req, res, next) {
  try {
    const { bookingId } = req.params;
    const userId = req.user?.id || req.loggedInUser?.id;

    if (!userId) {
      return res.status(401).json({ 
        error: 'User not authenticated',
        status: 'UNAUTHORIZED'
      });
    }

    const result = await paymentService.getPaymentStatus(bookingId, userId);
    
    res.json({
      success: true,
      data: result,
      message: "Payment status retrieved successfully",
      status: "PAYMENT_STATUS_RETRIEVED"
    });

  } catch (error) {
    console.error('Get payment status error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Get payment history for a user
async function getPaymentHistory(req, res, next) {
  try {
    const userId = req.user?.id || req.loggedInUser?.id;
    const userType = req.user?.userType === UserType.CLIENT ? 'client' : 'serviceProvider';

    if (!userId) {
      return res.status(401).json({ 
        error: 'User not authenticated',
        status: 'UNAUTHORIZED'
      });
    }

    const result = await paymentService.getPaymentHistory(userId, userType);
    
    res.json({
      success: true,
      data: result,
      message: "Payment history retrieved successfully",
      status: "PAYMENT_HISTORY_RETRIEVED"
    });

  } catch (error) {
    console.error('Get payment history error:', error);
    next(error);
  }
}

// Khalti payment callback endpoint (for webhook)
async function khaltiCallback(req, res, next) {
  try {
    const { pidx, status, amount, transaction_id } = req.body;

    console.log('Khalti callback received:', {
      pidx,
      status,
      amount,
      transaction_id
    });

    // Verify the payment
    const result = await paymentService.verifyKhaltiPayment(pidx);
    
    // Return success to Khalti
    res.json({
      success: true,
      message: "Payment processed successfully"
    });

  } catch (error) {
    console.error('Khalti callback error:', error);
    
    // Still return success to Khalti to prevent retries
    res.json({
      success: false,
      message: "Payment processing failed"
    });
  }
}

// Test Khalti configuration
async function testKhaltiConfig(req, res, next) {
  try {
    const { AppConfig } = require('../../config/config');
    const baseUrl = AppConfig.khaltiBaseUrl.replace(/\/$/, '');
    
    res.json({
      success: true,
      config: {
        khaltiBaseUrl: AppConfig.khaltiBaseUrl,
        cleanBaseUrl: baseUrl,
        fullInitiateUrl: `${baseUrl}/epayment/initiate/`,
        hasSecretKey: !!AppConfig.khaltiSecretKey,
        hasPublicKey: !!AppConfig.khaltiPublicKey,
        frontendUrl: AppConfig.frontendUrl
      },
      message: "Khalti configuration loaded successfully"
    });

  } catch (error) {
    console.error('Test Khalti config error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
}

// Update payment status for a booking
async function updatePaymentStatus(req, res, next) {
  try {
    const { bookingId } = req.params;
    const { status, pidx, verified_at } = req.body;
    const userId = req.user?.id || req.loggedInUser?.id;

    if (!userId) {
      return res.status(401).json({ 
        error: 'User not authenticated',
        status: 'UNAUTHORIZED'
      });
    }

    if (!status) {
      return res.status(400).json({
        error: 'Payment status is required',
        status: 'MISSING_STATUS'
      });
    }

    const result = await paymentService.updatePaymentStatus(bookingId, userId, {
      status,
      pidx,
      verified_at
    });
    
    res.json({
      success: true,
      data: result,
      message: "Payment status updated successfully",
      status: "PAYMENT_STATUS_UPDATED"
    });

  } catch (error) {
    console.error('Update payment status error:', error);
    
    if (error.code) {
      return res.status(error.code).json({
        error: error.message,
        status: error.status
      });
    }
    
    next(error);
  }
}

// Payment success page (for Khalti redirect)
async function paymentSuccessPage(req, res, next) {
  try {
    const { bookingId, pidx, status } = req.query;
    
    console.log('Payment success page accessed:', { bookingId, pidx, status });
    
    // ENHANCED: Handle different status parameters from Khalti
    let statusMessage = 'Payment processed successfully!';
    let statusIcon = '✅';
    let statusColor = '#10B981'; // green
    
    if (status === 'Canceled' || status === 'Failed') {
      statusMessage = 'Payment was cancelled or failed.';
      statusIcon = '❌';
      statusColor = '#EF4444'; // red
    } else if (status === 'Pending') {
      statusMessage = 'Payment is being processed.';
      statusIcon = '⏳';
      statusColor = '#F59E0B'; // yellow
    }
    
    // Create a simple HTML page that will work in WebView
    const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment ${status || 'Success'} - Swornim</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            margin: 0;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            max-width: 400px;
            width: 100%;
        }
        .status-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        h1 {
            margin: 0 0 20px 0;
            font-size: 28px;
            color: ${statusColor};
        }
        p {
            margin: 0 0 20px 0;
            font-size: 16px;
            line-height: 1.5;
        }
        .info-box {
            background: rgba(255, 255, 255, 0.2);
            padding: 10px;
            border-radius: 8px;
            margin: 10px 0;
            font-family: monospace;
            word-break: break-all;
        }
        .redirect-info {
            margin-top: 30px;
            padding: 15px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status-icon">${statusIcon}</div>
        <h1>${statusMessage}</h1>
        <p>Thank you for using Swornim photography services.</p>
        ${bookingId ? `<div class="info-box">Booking ID: ${bookingId}</div>` : ''}
        ${pidx ? `<div class="info-box">Transaction ID: ${pidx}</div>` : ''}
        ${status ? `<div class="info-box">Status: ${status}</div>` : ''}
        
        <div class="redirect-info">
            <p>You will be redirected back to the app automatically.</p>
            <p>If you're not redirected, please close this window.</p>
        </div>
    </div>
    
    <script>
        console.log('Payment success page loaded with:', {
            bookingId: '${bookingId || ''}',
            pidx: '${pidx || ''}',
            status: '${status || ''}',
            url: window.location.href
        });
        
        // Try to communicate with parent window (for WebView)
        if (window.parent && window.parent !== window) {
            try {
                window.parent.postMessage({
                    type: 'PAYMENT_RESULT',
                    data: {
                        bookingId: '${bookingId || ''}',
                        pidx: '${pidx || ''}',
                        status: '${status || 'Success'}'
                    }
                }, '*');
            } catch (e) {
                console.log('Could not communicate with parent window:', e);
            }
        }
        
        // Auto-redirect after 3 seconds
        setTimeout(function() {
            try {
                // Try to redirect to app if possible
                if (window.history.length > 1) {
                    window.history.back();
                } else {
                    window.close();
                }
            } catch (e) {
                console.log('Redirect failed:', e);
                window.close();
            }
        }, 3000);
    </script>
</body>
</html>`;
    
    res.setHeader('Content-Type', 'text/html');
    res.send(html);

  } catch (error) {
    console.error('Payment success page error:', error);
    res.status(500).send(`
      <html>
        <body style="text-align: center; padding: 20px; font-family: Arial;">
          <h1>Payment Status Page Error</h1>
          <p>Unable to load payment status page.</p>
          <p>Please check your booking status in the app.</p>
          <script>
            setTimeout(() => window.close(), 3000);
          </script>
        </body>
      </html>
    `);
  }
}

module.exports = {
  initializeKhaltiPayment,
  verifyKhaltiPayment,
  getPaymentStatus,
  getPaymentHistory,
  updatePaymentStatus,
  khaltiCallback,
  testKhaltiConfig,
  paymentSuccessPage
};
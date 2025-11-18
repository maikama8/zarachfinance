const axios = require('axios');
const PaymentGateway = require('../models/PaymentGateway');

class PaymentGatewayService {
  async getActiveGateway() {
    const gateway = await PaymentGateway.findOne({ isActive: true });
    if (!gateway) {
      throw new Error('No active payment gateway configured');
    }
    return gateway;
  }

  async initializePayment(gateway, amount, email, reference, metadata = {}) {
    const gatewayConfig = await PaymentGateway.findOne({ gateway, isActive: true });
    if (!gatewayConfig) {
      throw new Error(`Payment gateway ${gateway} is not configured or active`);
    }

    amount = Math.round(amount * 100); // Convert to kobo/pesewas

    if (gateway === 'paystack') {
      return await this.initializePaystack(gatewayConfig, amount, email, reference, metadata);
    } else if (gateway === 'flutterwave') {
      return await this.initializeFlutterwave(gatewayConfig, amount, email, reference, metadata);
    } else {
      throw new Error(`Unsupported payment gateway: ${gateway}`);
    }
  }

  async verifyPayment(gateway, reference) {
    const gatewayConfig = await PaymentGateway.findOne({ gateway, isActive: true });
    if (!gatewayConfig) {
      throw new Error(`Payment gateway ${gateway} is not configured or active`);
    }

    if (gateway === 'paystack') {
      return await this.verifyPaystack(gatewayConfig, reference);
    } else if (gateway === 'flutterwave') {
      return await this.verifyFlutterwave(gatewayConfig, reference);
    } else {
      throw new Error(`Unsupported payment gateway: ${gateway}`);
    }
  }

  async initializePaystack(config, amount, email, reference, metadata) {
    try {
      const response = await axios.post(
        'https://api.paystack.co/transaction/initialize',
        {
          amount,
          email,
          reference,
          currency: 'NGN',
          metadata
        },
        {
          headers: {
            Authorization: `Bearer ${config.secretKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.data.status) {
        return {
          success: true,
          authorizationUrl: response.data.data.authorization_url,
          accessCode: response.data.data.access_code,
          reference: response.data.data.reference
        };
      } else {
        throw new Error(response.data.message || 'Failed to initialize payment');
      }
    } catch (error) {
      console.error('Paystack initialization error:', error.response?.data || error.message);
      throw new Error(error.response?.data?.message || 'Failed to initialize Paystack payment');
    }
  }

  async verifyPaystack(config, reference) {
    try {
      const response = await axios.get(
        `https://api.paystack.co/transaction/verify/${reference}`,
        {
          headers: {
            Authorization: `Bearer ${config.secretKey}`
          }
        }
      );

      if (response.data.status && response.data.data.status === 'success') {
        return {
          success: true,
          amount: response.data.data.amount / 100, // Convert from kobo to naira
          currency: response.data.data.currency,
          reference: response.data.data.reference,
          paidAt: response.data.data.paid_at,
          customer: response.data.data.customer
        };
      } else {
        return {
          success: false,
          message: response.data.data.gateway_response || 'Payment not successful'
        };
      }
    } catch (error) {
      console.error('Paystack verification error:', error.response?.data || error.message);
      throw new Error(error.response?.data?.message || 'Failed to verify Paystack payment');
    }
  }

  async initializeFlutterwave(config, amount, email, reference, metadata) {
    try {
      const response = await axios.post(
        'https://api.flutterwave.com/v3/payments',
        {
          tx_ref: reference,
          amount,
          currency: 'NGN',
          redirect_url: metadata.redirectUrl || `${process.env.APP_URL}/payment/callback`,
          payment_options: 'card,ussd,banktransfer',
          customer: {
            email,
            name: metadata.customerName || 'Customer'
          },
          customizations: {
            title: 'ZarFinance Payment',
            description: metadata.description || 'Device financing payment'
          },
          meta: metadata
        },
        {
          headers: {
            Authorization: `Bearer ${config.secretKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.data.status === 'success') {
        return {
          success: true,
          authorizationUrl: response.data.data.link,
          reference: reference
        };
      } else {
        throw new Error(response.data.message || 'Failed to initialize payment');
      }
    } catch (error) {
      console.error('Flutterwave initialization error:', error.response?.data || error.message);
      throw new Error(error.response?.data?.message || 'Failed to initialize Flutterwave payment');
    }
  }

  async verifyFlutterwave(config, reference) {
    try {
      const response = await axios.get(
        `https://api.flutterwave.com/v3/transactions/${reference}/verify`,
        {
          headers: {
            Authorization: `Bearer ${config.secretKey}`
          }
        }
      );

      if (response.data.status === 'success' && response.data.data.status === 'successful') {
        return {
          success: true,
          amount: response.data.data.amount,
          currency: response.data.data.currency,
          reference: response.data.data.tx_ref,
          paidAt: response.data.data.created_at,
          customer: response.data.data.customer
        };
      } else {
        return {
          success: false,
          message: response.data.data.processor_response || 'Payment not successful'
        };
      }
    } catch (error) {
      console.error('Flutterwave verification error:', error.response?.data || error.message);
      throw new Error(error.response?.data?.message || 'Failed to verify Flutterwave payment');
    }
  }
}

module.exports = new PaymentGatewayService();


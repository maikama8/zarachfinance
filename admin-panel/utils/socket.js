// Socket.IO utility for emitting updates
let ioInstance = null;

module.exports = {
  setIO: (io) => {
    ioInstance = io;
  },
  
  getIO: () => {
    return ioInstance;
  },
  
  emitDeviceUpdate: (deviceId, data) => {
    if (ioInstance) {
      ioInstance.to(`device:${deviceId}`).emit('device:update', data);
      ioInstance.to('dashboard').emit('dashboard:update', {
        type: 'device',
        deviceId,
        data
      });
    }
  },
  
  emitPaymentUpdate: (deviceId, paymentData) => {
    if (ioInstance) {
      ioInstance.to(`device:${deviceId}`).emit('device:update', {
        type: 'payment',
        deviceId,
        ...paymentData
      });
      ioInstance.to('dashboard').emit('dashboard:update', {
        type: 'payment',
        deviceId,
        ...paymentData
      });
    }
  },
  
  emitDashboardUpdate: (data) => {
    if (ioInstance) {
      ioInstance.to('dashboard').emit('dashboard:update', data);
    }
  }
};


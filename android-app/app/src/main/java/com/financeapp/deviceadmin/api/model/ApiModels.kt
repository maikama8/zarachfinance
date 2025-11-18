package com.zarfinance.admin.api.model

data class PaymentStatusResponse(
    val isPaymentOverdue: Boolean,
    val isFullyPaid: Boolean,
    val lastPaymentDate: Long,
    val nextPaymentDate: Long,
    val remainingBalance: Double,
    val overdueAmount: Double,
    val paymentFrequency: String? = null
)

data class PaymentRequest(
    val deviceId: String,
    val amount: Double,
    val paymentMethod: String, // "mobile_money", "bank_transfer", etc.
    val transactionReference: String
)

data class PaymentResponse(
    val success: Boolean,
    val transactionId: String,
    val message: String,
    val newBalance: Double
)

data class PaymentHistoryItem(
    val date: Long,
    val amount: Double,
    val status: String,
    val transactionId: String
)

data class PaymentSchedule(
    val schedule: List<ScheduleItem>,
    val totalAmount: Double,
    val paidAmount: Double,
    val remainingAmount: Double,
    val paymentFrequency: String? = null
)

data class ScheduleItem(
    val dueDate: Long,
    val amount: Double,
    val status: String // "paid", "pending", "overdue"
)

data class LocationRequest(
    val deviceId: String,
    val latitude: Double,
    val longitude: Double,
    val timestamp: Long,
    val accuracy: Float
)

data class LocationResponse(
    val success: Boolean,
    val message: String
)

data class DeviceStatusResponse(
    val deviceId: String,
    val isLocked: Boolean,
    val lastSeen: Long,
    val appVersion: String
)

data class DeviceStatusReport(
    val deviceId: String,
    val isLocked: Boolean,
    val appVersion: String,
    val batteryLevel: Int,
    val isCharging: Boolean
)

data class PolicyResponse(
    val lockPolicy: LockPolicy,
    val paymentSchedule: PaymentSchedule,
    val customMessage: String?
)

data class LockPolicy(
    val lockOnOverdue: Boolean,
    val lockDelayHours: Int,
    val allowEmergencyCalls: Boolean
)

data class UnlockRequest(
    val deviceId: String,
    val adminToken: String,
    val reason: String
)

data class UnlockResponse(
    val success: Boolean,
    val message: String
)

data class MessageRequest(
    val deviceId: String,
    val message: String,
    val adminToken: String
)

data class PaymentInitializeRequest(
    val deviceId: String,
    val amount: Double,
    val email: String
)

data class PaymentInitializeResponse(
    val success: Boolean,
    val authorizationUrl: String,
    val reference: String,
    val gateway: String
)

data class PaymentVerifyRequest(
    val reference: String,
    val deviceId: String
)


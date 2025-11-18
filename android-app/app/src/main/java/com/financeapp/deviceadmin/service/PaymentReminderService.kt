package com.zarfinance.admin.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.*
import com.zarfinance.admin.Config
import com.zarfinance.admin.R
import com.zarfinance.admin.api.ApiClient
import com.zarfinance.admin.ui.MainActivity
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class PaymentReminderService {
    companion object {
        private const val CHANNEL_ID = "payment_reminders"
        private const val NOTIFICATION_ID_24H = 2001
        private const val NOTIFICATION_ID_6H = 2002
        private const val NOTIFICATION_ID_OVERDUE = 2003
        private const val NOTIFICATION_ID_CONFIRMATION = 2004

        fun scheduleReminders(context: Context) {
            val workManager = WorkManager.getInstance(context)
            
            // Schedule daily check for payment reminders
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val reminderWork = PeriodicWorkRequestBuilder<PaymentReminderWorker>(
                1, TimeUnit.HOURS
            )
                .setConstraints(constraints)
                .build()

            workManager.enqueueUniquePeriodicWork(
                "payment_reminders",
                ExistingPeriodicWorkPolicy.KEEP,
                reminderWork
            )
        }

        fun showReminderNotification(
            context: Context,
            hoursUntilDue: Long,
            amount: Double,
            dueDate: Long
        ) {
            createNotificationChannel(context)
            
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notificationId = when {
                hoursUntilDue <= 0 -> NOTIFICATION_ID_OVERDUE
                hoursUntilDue <= 6 -> NOTIFICATION_ID_6H
                hoursUntilDue <= 24 -> NOTIFICATION_ID_24H
                else -> return
            }

            val title = when {
                hoursUntilDue <= 0 -> "Payment Overdue!"
                hoursUntilDue <= 6 -> "Payment Due Soon"
                else -> "Payment Reminder"
            }

            val message = when {
                hoursUntilDue <= 0 -> "Your payment of ₦${String.format("%.2f", amount)} is overdue. Please make payment immediately."
                hoursUntilDue <= 6 -> "Your payment of ₦${String.format("%.2f", amount)} is due in ${hoursUntilDue.toInt()} hours."
                else -> "Your payment of ₦${String.format("%.2f", amount)} is due in ${hoursUntilDue.toInt()} hours."
            }

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(message)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build()

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(notificationId, notification)
        }

        fun showPaymentConfirmation(context: Context, amount: Double, newBalance: Double) {
            createNotificationChannel(context)
            
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle("Payment Confirmed")
                .setContentText("Payment of ₦${String.format("%.2f", amount)} received. New balance: ₦${String.format("%.2f", newBalance)}")
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID_CONFIRMATION, notification)
        }

        private fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Payment Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Payment reminders and confirmations"
                }
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
        }
    }
}

class PaymentReminderWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        return try {
            checkAndSendReminders()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private suspend fun checkAndSendReminders() {
        try {
            val deviceId = getDeviceId()
            val response = ApiClient.paymentService.getPaymentSchedule(deviceId)
            
            if (response.isSuccessful && response.body() != null) {
                val schedule = response.body()!!
                val now = System.currentTimeMillis()
                
                schedule.schedule.forEach { item ->
                    if (item.status == "pending") {
                        val hoursUntilDue = (item.dueDate - now) / (1000 * 60 * 60)
                        
                        when {
                            hoursUntilDue <= 0 -> {
                                // Overdue
                                PaymentReminderService.showReminderNotification(
                                    applicationContext,
                                    0,
                                    item.amount,
                                    item.dueDate
                                )
                            }
                            hoursUntilDue <= Config.PAYMENT_REMINDER_6H -> {
                                // 6 hours before
                                PaymentReminderService.showReminderNotification(
                                    applicationContext,
                                    hoursUntilDue,
                                    item.amount,
                                    item.dueDate
                                )
                            }
                            hoursUntilDue <= Config.PAYMENT_REMINDER_24H -> {
                                // 24 hours before
                                PaymentReminderService.showReminderNotification(
                                    applicationContext,
                                    hoursUntilDue,
                                    item.amount,
                                    item.dueDate
                                )
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Log error but don't fail the work
        }
    }

    private fun getDeviceId(): String {
        val prefs = applicationContext.getSharedPreferences("finance_prefs", Context.MODE_PRIVATE)
        return prefs.getString("device_id", "") ?: ""
    }
}


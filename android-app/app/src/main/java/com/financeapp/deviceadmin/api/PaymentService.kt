package com.zarfinance.admin.api

import com.zarfinance.admin.api.model.*
import retrofit2.Response
import retrofit2.http.*

interface PaymentService {
    @GET("payment/status/{deviceId}")
    suspend fun getPaymentStatus(@Path("deviceId") deviceId: String): Response<PaymentStatusResponse>

    @POST("payment/initialize")
    suspend fun initializePayment(@Body request: PaymentInitializeRequest): Response<PaymentInitializeResponse>

    @POST("payment/verify")
    suspend fun verifyPayment(@Body request: PaymentVerifyRequest): Response<PaymentResponse>

    @POST("payment/process")
    suspend fun processPayment(@Body request: PaymentRequest): Response<PaymentResponse>

    @GET("payment/history/{deviceId}")
    suspend fun getPaymentHistory(@Path("deviceId") deviceId: String): Response<List<PaymentHistoryItem>>

    @GET("payment/schedule/{deviceId}")
    suspend fun getPaymentSchedule(@Path("deviceId") deviceId: String): Response<PaymentSchedule>
}


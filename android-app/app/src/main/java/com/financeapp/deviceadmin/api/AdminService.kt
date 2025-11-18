package com.zarfinance.admin.api

import com.zarfinance.admin.api.model.*
import retrofit2.Response
import retrofit2.http.*

interface AdminService {
    @GET("admin/policy/{deviceId}")
    suspend fun getPolicy(@Path("deviceId") deviceId: String): Response<PolicyResponse>

    @POST("admin/unlock")
    suspend fun unlockDevice(@Body request: UnlockRequest): Response<UnlockResponse>

    @POST("admin/message")
    suspend fun sendMessage(@Body request: MessageRequest): Response<Unit>
}


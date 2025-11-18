package com.zarfinance.admin.api

import com.zarfinance.admin.api.model.*
import retrofit2.Response
import retrofit2.http.*

interface DeviceService {
    @POST("device/location")
    suspend fun reportLocation(@Body request: LocationRequest): Response<LocationResponse>

    @GET("device/status/{deviceId}")
    suspend fun getDeviceStatus(@Path("deviceId") deviceId: String): Response<DeviceStatusResponse>

    @POST("device/report")
    suspend fun reportDeviceStatus(@Body request: DeviceStatusReport): Response<Unit>
}


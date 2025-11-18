package com.zarfinance.admin.api

import com.zarfinance.admin.Config
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import java.security.cert.X509Certificate

object ApiClient {
    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .connectTimeout(Config.API_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(Config.API_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(Config.API_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(Config.API_BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val paymentService: PaymentService = retrofit.create(PaymentService::class.java)
    val deviceService: DeviceService = retrofit.create(DeviceService::class.java)
    val adminService: AdminService = retrofit.create(AdminService::class.java)
}


package com.example.cuidarmais

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        criarCanalDeLembretes()
    }

    /**
     * Canal "Lembretes de remédio" com prioridade alta: a notificação aparece por cima da tela
     * (pop-up), toca o som de alarme e vibra. O agendador manda os lembretes e alertas neste
     * canal (channel_id = "lembretes"). Sem ele, o Android usa um canal padrão que só põe a
     * notificação na barra, em silêncio.
     */
    private fun criarCanalDeLembretes() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val som = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val canal = NotificationChannel(CANAL, "Lembretes de remédio", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Hora do remédio e alertas quando uma dose fica sem confirmação"
            setSound(som, audio)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 800, 400, 800, 400, 800)
            enableLights(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }

    companion object {
        const val CANAL = "lembretes"
    }
}

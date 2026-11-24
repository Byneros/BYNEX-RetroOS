package org.bynex.retro

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.core.content.FileProvider

/**
 * Único punto que conoce el contrato de los emuladores.
 *
 * Orden de preferencia al pulsar una ROM:
 * 1. RetroArch, con intent explícito y la ROM como extra.
 * 2. Lemuroid, abriendo su pantalla principal si está instalado.
 *    Lemuroid no acepta archivos por intent (su única entrada externa usa el
 *    id interno de su biblioteca), así que el usuario elige la ROM allí.
 *
 * La pulsación larga abre el selector "Abrir con" con un content:// del
 * FileProvider, para emuladores que sí aceptan URIs.
 */
object EmulatorLauncher {
    private const val RETROARCH_PACKAGE = "com.retroarch"
    private const val RETROARCH_ACTIVITY =
        "com.retroarch.browser.retroactivity.RetroActivityFuture"
    private const val LEMUROID_PACKAGE = "com.swordfish.lemuroid"
    private const val FILE_PROVIDER_SUFFIX = ".fileprovider"

    fun launch(activity: Activity, rom: Rom) {
        if (launchRetroArch(activity, rom)) return

        if (launchLemuroid(activity)) {
            Toast.makeText(
                activity,
                activity.getString(R.string.lemuroid_manual, rom.file.name),
                Toast.LENGTH_LONG
            ).show()
            return
        }

        Toast.makeText(activity, R.string.emulator_missing, Toast.LENGTH_LONG).show()
    }

    /** Selector del sistema para abrir la ROM con cualquier app que acepte content://. */
    fun openWith(activity: Activity, rom: Rom) {
        val uri = try {
            FileProvider.getUriForFile(
                activity,
                activity.packageName + FILE_PROVIDER_SUFFIX,
                rom.file
            )
        } catch (e: IllegalArgumentException) {
            Toast.makeText(activity, R.string.open_with_error, Toast.LENGTH_LONG).show()
            return
        }

        // Primero el MIME del sistema; si nadie lo declara, un tipo genérico.
        var intent = viewIntent(uri, rom.system.mimeType)
        if (intent.resolveActivity(activity.packageManager) == null) {
            intent = viewIntent(uri, "*/*")
        }
        if (intent.resolveActivity(activity.packageManager) == null) {
            Toast.makeText(activity, R.string.open_with_unavailable, Toast.LENGTH_LONG).show()
            return
        }

        try {
            activity.startActivity(
                Intent.createChooser(intent, activity.getString(R.string.open_with))
            )
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(activity, R.string.open_with_unavailable, Toast.LENGTH_LONG).show()
        }
    }

    private fun viewIntent(uri: Uri, mimeType: String) =
        Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            // Propaga el permiso de lectura a la app elegida en el selector.
            clipData = ClipData.newRawUri(null, uri)
        }

    private fun launchRetroArch(activity: Activity, rom: Rom): Boolean {
        val intent = Intent().apply {
            setClassName(RETROARCH_PACKAGE, RETROARCH_ACTIVITY)
            putExtra("ROM", rom.file.absolutePath)
            putExtra("LIBRETRO", rom.system.core)
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }

    private fun launchLemuroid(activity: Activity): Boolean {
        val intent = activity.packageManager
            .getLaunchIntentForPackage(LEMUROID_PACKAGE)
            ?: return false
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }
}

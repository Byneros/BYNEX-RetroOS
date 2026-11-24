package org.bynex.retro

import android.content.Context

/**
 * Preferencias mínimas del launcher. Sin dependencias de AndroidX.
 */
object Settings {
    private const val PREFS = "bynex_retro"
    private const val KEY_ROM_ROOT = "rom_root"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun romRoot(context: Context): String =
        prefs(context).getString(KEY_ROM_ROOT, "")?.trim().orEmpty()

    fun setRomRoot(context: Context, path: String) {
        prefs(context).edit().putString(KEY_ROM_ROOT, path).apply()
    }
}

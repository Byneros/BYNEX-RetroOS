package org.bynex.retro

import java.io.File

/**
 * Sistemas del esqueleto. La carpeta es relativa a la raíz de ROMs, el core es
 * el identificador que RetroArch espera en el extra LIBRETRO y el MIME se usa
 * al compartir la ROM por content:// con otras apps (selector "Abrir con").
 */
enum class RetroSystem(
    val folder: String,
    val label: String,
    val core: String,
    val mimeType: String,
    private val extensions: Set<String>
) {
    NES("nes", "NES", "mesen_libretro_android.so", "application/x-nes-rom", setOf("nes", "unf", "unif")),
    SNES("snes", "SNES", "snes9x_libretro_android.so", "application/x-snes-rom", setOf("sfc", "smc")),
    GB("gb", "Game Boy / Color", "gambatte_libretro_android.so", "application/x-gameboy-rom", setOf("gb", "gbc")),
    GBA("gba", "GBA", "mgba_libretro_android.so", "application/x-gba-rom", setOf("gba")),
    MEGADRIVE("megadrive", "Mega Drive", "genesis_plus_gx_libretro_android.so", "application/x-genesis-rom", setOf("md", "gen", "smd")),
    PSX("psx", "PlayStation", "beetle_psx_libretro_android.so", "application/x-playstation-rom", setOf("cue", "chd", "pbp", "m3u")),
    N64("n64", "Nintendo 64", "mupen64plus_next_libretro_android.so", "application/x-n64-rom", setOf("z64", "n64", "v64")),
    PSP("psp", "PSP", "ppsspp_libretro_android.so", "application/x-psp-rom", setOf("iso", "cso", "chd")),
    DREAMCAST("dreamcast", "Dreamcast", "flycast_libretro_android.so", "application/x-dreamcast-rom", setOf("gdi", "cdi", "chd"));

    fun accepts(file: File): Boolean =
        file.isFile && file.extension.lowercase() in extensions
}

data class Rom(val file: File, val system: RetroSystem)

/**
 * Escaneo de un nivel: raíz/<carpeta de sistema>/<archivo>.ext.
 * No recorre subcarpetas para mantener el comportamiento predecible.
 */
object RomScanner {
    fun scan(root: File): List<Rom> {
        if (!root.isDirectory) return emptyList()
        val found = mutableListOf<Rom>()
        for (system in RetroSystem.entries) {
            val dir = File(root, system.folder)
            if (!dir.isDirectory) continue
            dir.listFiles()
                ?.asSequence()
                ?.filter { system.accepts(it) }
                ?.sortedBy { it.name.lowercase() }
                ?.forEach { found += Rom(it, system) }
        }
        return found
    }
}

package org.bynex.retro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class RomScannerTest {

    @Rule
    @JvmField
    val temp = TemporaryFolder()

    private fun file(path: String): File =
        temp.root.resolve(path).apply {
            parentFile?.mkdirs()
            if (!exists()) createNewFile()
        }

    @Test
    fun `scan asigna a cada ROM el sistema de su carpeta`() {
        val nes = file("nes/contra.nes").apply { writeText("x") }
        val snes = file("snes/zelda.sfc").apply { writeText("x") }
        val psx = file("psx/metal.cue").apply { writeText("x") }

        val roms = RomScanner.scan(temp.root)

        assertEquals(3, roms.size)
        assertEquals(RetroSystem.NES, roms.single { it.file == nes }.system)
        assertEquals(RetroSystem.SNES, roms.single { it.file == snes }.system)
        assertEquals(RetroSystem.PSX, roms.single { it.file == psx }.system)
    }

    @Test
    fun `scan ignora extensiones no admitidas archivos sueltos y subcarpetas`() {
        file("nes/bueno.nes").writeText("x")
        file("nes/notas.txt").writeText("x")
        file("nes/sin_extension").writeText("x")
        file("nes/subdir/anidado.nes").writeText("x")
        file("raiz_suelta.nes").writeText("x")
        file("no_es_un_sistema/rom.nes").writeText("x")

        val roms = RomScanner.scan(temp.root)

        assertEquals(listOf("bueno.nes"), roms.map { it.file.name })
    }

    @Test
    fun `scan ordena por nombre sin distinguir mayusculas`() {
        file("nes/b.NES").writeText("x")
        file("nes/A.nes").writeText("x")
        file("nes/c.Nes").writeText("x")

        val roms = RomScanner.scan(temp.root)

        assertEquals(listOf("A.nes", "b.NES", "c.Nes"), roms.map { it.file.name })
    }

    @Test
    fun `accepts no distingue mayusculas en la extension`() {
        assertTrue(RetroSystem.NES.accepts(file("nes/juego.NES")))
        assertTrue(RetroSystem.GB.accepts(file("gb/juego.GbC")))
        assertTrue(RetroSystem.SNES.accepts(file("snes/juego.SFC")))
    }

    @Test
    fun `scan devuelve lista vacia si la raiz no existe o no es carpeta`() {
        val inexistente = File(temp.root, "no_existe")
        assertEquals(emptyList<Rom>(), RomScanner.scan(inexistente))
        assertEquals(emptyList<Rom>(), RomScanner.scan(file("archivo.txt").apply { writeText("x") }))
    }

    @Test
    fun `scan no confunde chd de psx psp y dreamcast`() {
        file("psx/juego.chd").writeText("x")
        file("psp/juego.chd").writeText("x")
        file("dreamcast/juego.chd").writeText("x")

        val porNombre = RomScanner.scan(temp.root)
            .associate { requireNotNull(it.file.parentFile).name to it.system }

        assertEquals(RetroSystem.PSX, porNombre["psx"])
        assertEquals(RetroSystem.PSP, porNombre["psp"])
        assertEquals(RetroSystem.DREAMCAST, porNombre["dreamcast"])
    }

    @Test
    fun `cada sistema tiene carpeta y core propios`() {
        val folders = RetroSystem.entries.map { it.folder }
        assertEquals(RetroSystem.entries.size, folders.toSet().size)
        assertTrue(folders.none { it.isBlank() })

        val cores = RetroSystem.entries.map { it.core }
        assertEquals(RetroSystem.entries.size, cores.toSet().size)
        assertTrue(cores.all { it.endsWith("_libretro_android.so") })

        assertTrue(RetroSystem.entries.all { it.mimeType.contains("/") })
    }

    @Test
    fun `acepta las extensiones documentadas por sistema`() {
        val esperado = mapOf(
            RetroSystem.NES to listOf("nes", "unf", "unif"),
            RetroSystem.SNES to listOf("sfc", "smc"),
            RetroSystem.GB to listOf("gb", "gbc"),
            RetroSystem.GBA to listOf("gba"),
            RetroSystem.MEGADRIVE to listOf("md", "gen", "smd"),
            RetroSystem.PSX to listOf("cue", "chd", "pbp", "m3u"),
            RetroSystem.N64 to listOf("z64", "n64", "v64"),
            RetroSystem.PSP to listOf("iso", "cso", "chd"),
            RetroSystem.DREAMCAST to listOf("gdi", "cdi", "chd")
        )

        assertEquals(RetroSystem.entries.toSet(), esperado.keys)

        for ((system, extensiones) in esperado) {
            for (extension in extensiones) {
                val rom = file("${system.folder}/juego.$extension")
                assertTrue(
                    "${system.name} debería aceptar .$extension",
                    system.accepts(rom)
                )
            }
            val ajeno = file("${system.folder}/juego.zzz")
            assertTrue("${system.name} no debería aceptar .zzz", !system.accepts(ajeno))
        }
    }
}

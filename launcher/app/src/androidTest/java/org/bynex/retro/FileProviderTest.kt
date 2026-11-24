package org.bynex.retro

import android.content.pm.PackageManager
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * Verifica el contrato del FileProvider en un dispositivo o emulador:
 * URI content://, lectura a través del ContentResolver, metadatos y que el
 * provider no está exportado (el acceso de terceros exige grant por intent).
 */
@RunWith(AndroidJUnit4::class)
class FileProviderTest {

    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val authority = context.packageName + ".fileprovider"

    private fun romIn(folder: File): File {
        val dir = File(folder, "roms/nes")
        assertTrue("No se pudo crear $dir", dir.isDirectory || dir.mkdirs())
        return File(dir, "prueba.nes").apply {
            writeBytes(byteArrayOf(0x4E, 0x45, 0x53, 0x1A))
        }
    }

    @Test
    fun exponeContentUriYSeLeePorElResolver() {
        val rom = romIn(context.filesDir)
        val uri = FileProvider.getUriForFile(context, authority, rom)

        assertEquals("content", uri.scheme)
        assertEquals(authority, uri.authority)

        val leido = context.contentResolver.openInputStream(uri)!!.use { it.readBytes() }
        assertArrayEquals(rom.readBytes(), leido)
    }

    @Test
    fun devuelveNombreYTamano() {
        val rom = romIn(context.filesDir)
        val uri = FileProvider.getUriForFile(context, authority, rom)

        context.contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null
        )!!.use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals(rom.name, cursor.getString(0))
            assertEquals(rom.length(), cursor.getLong(1))
        }
    }

    @Test
    fun elProviderNoEstaExportadoYPermiteGrants() {
        val info = context.packageManager
            .resolveContentProvider(authority, PackageManager.GET_META_DATA)
            ?: throw AssertionError("Provider no encontrado: $authority")

        assertFalse("El provider no debe estar exportado", info.exported)
        assertTrue("Debe permitir grants por intent", info.grantUriPermissions)
    }
}

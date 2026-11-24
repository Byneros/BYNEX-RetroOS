package org.bynex.retro

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings as AndroidSettings
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.BaseAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.ListView
import android.widget.TextView
import java.io.File

class MainActivity : Activity() {

    private lateinit var list: ListView
    private lateinit var empty: TextView
    private lateinit var hint: TextView
    private lateinit var adapter: RomAdapter
    private val roms = mutableListOf<Rom>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        setContentView(R.layout.activity_main)

        list = findViewById(R.id.rom_list)
        empty = findViewById(R.id.empty_view)
        hint = findViewById(R.id.hint_view)
        adapter = RomAdapter()
        list.adapter = adapter
        list.setOnItemClickListener { _, _, position, _ ->
            roms.getOrNull(position)?.let { EmulatorLauncher.launch(this, it) }
        }
        // Pulsación larga: selector "Abrir con" usando content:// (FileProvider).
        list.setOnItemLongClickListener { _, _, position, _ ->
            roms.getOrNull(position)?.let { EmulatorLauncher.openWith(this, it) }
            true
        }
        findViewById<Button>(R.id.settings_button).setOnClickListener { showSettings() }

        ensureStorageAccess()
        refresh()
    }

    override fun onResume() {
        super.onResume()
        refresh()
    }

    private fun refresh() {
        val rootPath = Settings.romRoot(this)
        roms.clear()
        if (rootPath.isNotBlank()) {
            roms.addAll(RomScanner.scan(File(rootPath)))
        }
        adapter.notifyDataSetChanged()
        empty.visibility = if (roms.isEmpty()) View.VISIBLE else View.GONE
        hint.visibility = if (roms.isEmpty()) View.GONE else View.VISIBLE
        empty.text = if (rootPath.isBlank()) {
            getString(R.string.no_folder)
        } else {
            getString(R.string.no_roms, rootPath)
        }
    }

    private fun ensureStorageAccess() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        if (Environment.isExternalStorageManager()) return
        val intent = Intent(AndroidSettings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
            .setData(Uri.parse("package:$packageName"))
        try {
            startActivity(intent)
        } catch (e: Exception) {
            try {
                startActivity(Intent(AndroidSettings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            } catch (ignored: Exception) {
                // Sin acceso, el usuario aún puede apuntar a una ruta legible por la app.
            }
        }
    }

    private fun showSettings() {
        val input = EditText(this).apply {
            setText(Settings.romRoot(this@MainActivity))
            hint = getString(R.string.folder_hint)
            setSelection(text.length)
        }
        AlertDialog.Builder(this)
            .setTitle(R.string.settings_title)
            .setMessage(R.string.settings_message)
            .setView(input)
            .setPositiveButton(R.string.save) { _, _ ->
                Settings.setRomRoot(this, input.text.toString().trim())
                refresh()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private inner class RomAdapter : BaseAdapter() {

        override fun getCount(): Int = roms.size

        override fun getItem(position: Int): Rom = roms[position]

        override fun getItemId(position: Int): Long = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView ?: layoutInflater.inflate(R.layout.item_rom, parent, false)
            val rom = roms[position]
            view.findViewById<TextView>(R.id.rom_name).text =
                rom.file.nameWithoutExtension
            view.findViewById<TextView>(R.id.rom_system).text = rom.system.label
            // Alternativa accesible a la pulsación larga (también con D-pad).
            view.findViewById<Button>(R.id.rom_open_with).setOnClickListener {
                EmulatorLauncher.openWith(this@MainActivity, rom)
            }
            return view
        }
    }
}

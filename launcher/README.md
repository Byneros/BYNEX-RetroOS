# BYNEX Retro Launcher — esqueleto

Aplicación Android mínima que actúa como **HOME** del teléfono y lanza ROMs en RetroArch. Es la materialización de `research/AOSP.md` §4.3 y de la arquitectura de `reports/FEASIBILITY_REPORT.md` §5.

**Estado:** compila correctamente (`app-debug.apk`, ~2.6 MB) con Gradle 8.8, AGP 8.5.2, JDK 22 y SDK 34. **No se ha instalado ni probado en el dispositivo.**

---

## 1. Qué incluye

| Pieza | Archivo | Comportamiento |
|---|---|---|
| Pantalla de inicio | `app/src/main/AndroidManifest.xml` | Activity con `CATEGORY_HOME` + `DEFAULT` |
| Lista de ROMs | `MainActivity.kt` + `activity_main.xml` | Escaneo de `raíz/<sistema>/*.ext` y lista táctil |
| Escaneo | `RomScanner.kt` | Sistemas, carpetas, extensiones y core por sistema |
| Lanzamiento | `EmulatorLauncher.kt` | Intent explícito a RetroArch con `ROM` y `LIBRETRO`; si no está, abre Lemuroid |
| Abrir con | `EmulatorLauncher.openWith` + `res/xml/file_paths.xml` | Botón «Abrir con» en cada fila o pulsación larga: selector del sistema con la ROM como `content://` (FileProvider) |
| Ajustes | `Settings.kt` + diálogo | Ruta raíz de ROMs persistida en `SharedPreferences` |

Única dependencia del APK: `androidx.core` (FileProvider). Sin red, sin cuentas, sin telemetría. JUnit y AndroidX Test se usan solo en los tests.

La lista muestra la pista «Toca «Abrir con» o mantén pulsada una ROM para abrirla con otra aplicación» cuando hay ROMs. El botón de cada fila es enfocable con D-pad, así que el selector no depende de una pulsación larga.

---

## 2. Estructura de carpetas esperada

```
<raíz de ROMs>/
  nes/
  snes/
  gb/
  gba/
  megadrive/
  psx/
  n64/
  psp/
  dreamcast/
```

El escaneo es de **un nivel**: no entra en subcarpetas. Las extensiones aceptadas y el core asociado están en `RomScanner.kt`:

| Sistema | Carpeta | Core (`LIBRETRO`) |
|---|---|---|
| NES | `nes` | `mesen_libretro_android.so` |
| SNES | `snes` | `snes9x_libretro_android.so` |
| GB/GBC | `gb` | `gambatte_libretro_android.so` |
| GBA | `gba` | `mgba_libretro_android.so` |
| Mega Drive | `megadrive` | `genesis_plus_gx_libretro_android.so` |
| PS1 | `psx` | `beetle_psx_libretro_android.so` |
| N64 | `n64` | `mupen64plus_next_libretro_android.so` |
| PSP | `psp` | `ppsspp_libretro_android.so` |
| Dreamcast | `dreamcast` | `flycast_libretro_android.so` |

Los nombres de core deben coincidir con los instalados en RetroArch; si una versión usa otro nombre, se ajusta en el enum.

---

## 3. Compilación

Requisitos: JDK 17+, Android SDK (platform 34, build-tools 34.0.0) y Gradle 8.7+ o Android Studio. Build verificado con JDK 22 y Gradle 8.8.

```bash
cd launcher
gradle wrapper --gradle-version 8.7   # solo la primera vez
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

No hay `gradle-wrapper.jar` en el repositorio a propósito: se genera con el comando anterior.

Instalación y rollback por ADB con un dispositivo conectado y autorizado:

```bash
powershell -ExecutionPolicy Bypass -File scripts/install-launcher.ps1                 # instala el APK
powershell -ExecutionPolicy Bypass -File scripts/install-launcher.ps1 -SetHome       # además lo fija como HOME
powershell -ExecutionPolicy Bypass -File scripts/install-launcher.ps1 -Action Status
powershell -ExecutionPolicy Bypass -File scripts/install-launcher.ps1 -Action Uninstall  # rollback
```

`Uninstall` elimina la app y Android vuelve al launcher anterior; no se toca ningún otro dato. El script no hace root ni desbloquea el bootloader.

Tests unitarios del escaneo y del mapeo de sistemas (JVM, sin emulador ni dispositivo):

```bash
cd launcher
./gradlew testDebugUnitTest
```

Test instrumentado del FileProvider (URI `content://`, lectura por `ContentResolver`, metadatos y provider no exportado). Requiere dispositivo o emulador conectado:

```bash
./gradlew connectedDebugAndroidTest
```

Al abrir la app por primera vez, Android pedirá el permiso de **acceso a todos los archivos** (necesario para que RetroArch reciba rutas de archivo). Después, en **Ajustes**, indicar la raíz de ROMs (por ejemplo `/storage/emulated/0/roms` o una ruta de microSD).

Para usarla como HOME: Ajustes de Android → Aplicaciones → Aplicación de inicio → BYNEX Retro.

---

## 4. Decisiones de diseño

- **AndroidX mínimo:** solo `androidx.core` por `FileProvider`; el resto es framework. Evita reimplementar un content provider propio.
- **Sin SAF:** RetroArch recibe rutas absolutas, no `content://`; por eso se usa acceso directo al almacenamiento. El `content://` del FileProvider es solo para el selector "Abrir con".
- **Un solo punto de acoplamiento:** RetroArch es la vía principal y Lemuroid el fallback; añadir otro frontend solo toca `EmulatorLauncher.kt`.
- **Visibilidad de paquetes:** el manifest declara `<queries>` para `com.retroarch` y `com.swordfish.lemuroid` (requisito de Android 11+).
- **Escaneo predecible:** un nivel de profundidad y carpetas fijas; evita sorpresas y listas enormes.
- **Kiosco fuera de alcance:** `LOCK_TASK`/device owner queda para una fase posterior (requiere aprovisionamiento por ADB).

---

## 5. Limitaciones conocidas / pendientes

- Compila, pero no se ha instalado ni probado en `selene`; la versión de RetroArch y los nombres de core deben verificarse en el dispositivo.
- El permiso `MANAGE_EXTERNAL_STORAGE` es aceptable para una app instalada manualmente, pero no para Play Store.
- No hay carátulas, scraping, favoritos ni perfiles por mando.
- Lemuroid **no acepta archivos por intent**: su manifest solo expone `ACTION_VIEW` para `lemuroid://<paquete>/play-game/id/<id>`, donde `id` es la clave de su base de datos interna. Por eso el fallback abre su pantalla principal para elegir la ROM allí. Para otros emuladores sí existe la pulsación larga → "Abrir con" (`content://`).
- Si no hay ninguno de los dos emuladores, se muestra un aviso.
- El selector muestra las apps que declaren `ACTION_VIEW` para el MIME del sistema; si ninguna, reintenta con `*/*`. Algunos emuladores solo aceptan rutas, no `content://`.
- El `root-path` del FileProvider expone cualquier ruta legible por la app (necesario para microSD); el provider no está exportado y solo concede lectura por intent.
- Tests unitarios JVM para `RomScanner` y el mapeo de sistemas; test instrumentado del FileProvider que **compila pero no se ha ejecutado** (sin dispositivo). Sin CI.
- No probado en dispositivo: el APK compila, pero no se ha instalado.
- **Licencia pendiente de decisión** (GPLv3 o Apache-2.0, según `research/AOSP.md` §4.3). Hasta fijarla, el código no debe distribuirse como producto.

---

## 6. Relación con el resto del proyecto

| Documento | Relación |
|---|---|
| `research/AOSP.md` §4.3 | Diseño mínimo del launcher |
| `reports/FEASIBILITY_REPORT.md` §5 | Arquitectura de Fase 1 |
| `docs/BENCHMARK_PROTOCOL.md` | Protocolo para medir lo que este launcher lanza |
| `docs/RECOVERY_PLAN.md` | Recuperación si una fase posterior falla |

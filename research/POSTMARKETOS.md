# postmarketOS — soporte para Xiaomi Redmi 10 (`selene`)

**Veredicto: EXPERIMENTAL limitado a arranque (EX)**. No utilizable como consola ni como sistema diario.
**Fecha:** 2026-11-24

---

## 1. Qué es

postmarketOS (pmOS) es una distribución Linux para dispositivos móviles basada en Alpine Linux. Usa `pmbootstrap` para generar imágenes, y clasifica los ports en cuatro categorías: **main, community, testing y downstream**. [P1]

Definición oficial de **downstream**: ports que usan el kernel original del fabricante; "suelen tener funciones muy limitadas". [P1]

---

## 2. Soporte para Redmi 10

### 2.1 Dispositivos listados

El wiki de postmarketOS, en su tabla de dispositivos Xiaomi, lista: [P2]

| Dispositivo | Codename pmOS | SoC | Arranca | Categoría | USB Net | Flashing | Resto de periféricos |
|---|---|---|---|---|---|---|---|
| Xiaomi Redmi 10 | `xiaomi-eos` | Helio G88 (MT6769H) | **Sí** | **downstream** | Sí | No | Columnas vacías (sin probar) |
| Xiaomi Redmi 10 2022 | `xiaomi-selene` | Helio G88 (MT6769H) | **Sí** | **downstream** | Sí | No | Columnas vacías (sin probar) |
| Xiaomi Redmi 10 2022, 2021 | `xiaomi-selene` | Helio G88 (MT6769H) | **Sí** | **downstream** | Sí | No | Columnas vacías (sin probar) |

Observaciones críticas:

1. **Hay dos nombres de paquete** (`xiaomi-eos` y `xiaomi-selene`) para lo que Xiaomi llama `selene`. Es una divergencia de nomenclatura que obliga a verificar el modelo exacto antes de cualquier instalación.
2. La columna **Flashing = No** indica que el método de instalación no está validado para el dispositivo.
3. El resto de columnas (pantalla, táctil, WiFi, audio, Bluetooth, batería, GPU, cámara, etc.) están **vacías**: no hay evidencia publicada de que funcionen.
4. "Arranca" en categoría downstream significa que el kernel del fabricante llega a userspace, **no** que el dispositivo sea usable.

### 2.2 Qué implica "downstream"

- Se reutiliza el kernel 4.14 de Xiaomi y sus módulos precompilados. [P4]
- No hay mainline, por lo que no hay drivers upstream ni soporte a largo plazo.
- La imagen se genera con `pmbootstrap` y se instala por `fastboot`/recovery, lo que exige bootloader desbloqueado. [P3]

---

## 3. Estado del SoC en mainline (MT6768/MT6769)

El wiki de postmarketOS documenta el estado del soporte mainline para la familia MT6768: [P5]

| Subsistema | Estado |
|---|---|
| SMP / cpufreq / cpuidle | Parcial |
| UART | Funciona |
| Almacenamiento (eMMC/SD/UFS) | Funciona |
| USB | Parcial |
| **Display** | **Parcial** |
| **GPU** | **Funciona** |
| Pinctrl / I²C / SPI | Funciona |
| **Audio** | **Roto** |
| **Vídeo acelerado** | **Roto** |
| Thermal | Funciona |
| **WiFi** | **Roto** |
| **Bluetooth** | **Roto** |
| **Módem (llamadas/SMS/datos)** | **Roto** |
| **GPS** | **Roto** |
| **Cámara** | **Roto** |
| **Suspensión** | **Rota** |

El proyecto `mt6768-mainline` mantiene U-Boot, TF-A y un fork de Linux con parches para MT6768; sus repositorios muestran actividad en noviembre de 2026. [P6] Sin embargo:

- **No publica un port para `selene`.**
- El trabajo mainline reciente documentado se centra en otros dispositivos de la familia (p. ej. Redmi 9 `lancelot`). [P7]
- No hay DTS de `selene` en mainline.

---

## 4. ¿Se puede usar como consola retro hoy?

No, por cuatro bloqueantes:

1. **Sin audio** en mainline; en downstream no está verificado.
2. **Sin WiFi/Bluetooth** en mainline; sin red no hay scraping, ni mandos Bluetooth, ni actualizaciones.
3. **Sin suspensión**: una consola portátil consume batería aunque esté apagada la pantalla.
4. **Display parcial** y táctil no confirmado: un frontend como EmulationStation no tiene una base gráfica garantizada.

A ello se suma que la GPU funciona en mainline pero **no hay integración gráfica probada** (EGL/GBM, compositor, RetroArch) para `selene`.

---

## 5. Camino de port (si se quisiera insistir)

| Paso | Herramienta | Estado |
|---|---|---|
| 1. Confirmar modelo y particiones | `diagnose-device.ps1`, `pmbootstrap bootimg_analyze` | Pendiente |
| 2. Crear paquete `device-xiaomi-*` | `pmbootstrap init` | Existe un paquete downstream, sin validar |
| 3. Kernel | `linux-postmarketos-mediatek-mt6768` o downstream 4.14 | Mainline sin DTS `selene` |
| 4. U-Boot/TF-A | `mt6768-mainline/u-boot`, `arm-trusted-firmware` | Sin `selene` |
| 5. Integración gráfica | Mesa/Panfrost + RetroArch | No probado |
| 6. Audio | UCM + codec | Roto en mainline |
| 7. Red | CONNAC | Roto en mainline |

**Estimación:** proyecto de I+D de varios meses, con resultado incierto y sin garantía de soporte de panel/táctil. No compite con la ruta Android.

---

## 6. Actividad y comunidad

- postmarketOS mantiene ~417 dispositivos soportados y una comunidad activa. [P1]
- Los ports de `selene`/`eos` están en **downstream** y sin mantenimiento visible en la tabla (sin datos de periféricos).
- `mt6768-mainline` está activo, lo que permite reabrir la evaluación en 6–12 meses. [P6]

---

## 7. Riesgos específicos

- Instalar una imagen downstream sin método de flasheo validado puede dejar el teléfono en bootloop.
- El kernel 4.14 del fabricante no recibe parches de seguridad.
- Si se borra `persist` o `nvram`, se pierde IMEI/calibración.
- La falta de suspensión y audio hace inviable el uso como consola incluso si arranca.

---

## 8. Conclusión

postmarketOS es **la única vía Linux real** para `selene`, pero hoy es un port downstream en estado experimental, sin periféricos validados y sin mainline. **No se recomienda para el Sprint 1**. Se propone revisarlo si `mt6768-mainline` publica soporte para `selene` (display + táctil + audio + WiFi).

---

## 9. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| P1 | https://wiki.postmarketos.org/wiki/Devices | Categorías y definición de downstream | 2026-11-24 |
| P2 | https://wiki.postmarketos.org/wiki/Xiaomi | Tabla de dispositivos Xiaomi con estados | 2026-11-24 |
| P3 | https://wiki.postmarketos.org/wiki/Porting_to_a_new_device | Proceso de port y paquetes de dispositivo | 2026-11-24 |
| P4 | https://codeberg.org/xiaomi-mt6768-dev/android_device_xiaomi_selene-kernel | Kernel/módulos precompilados de la ROM oficial | 2026-11-24 |
| P5 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado mainline por subsistema | 2026-11-24 |
| P6 | https://github.com/mt6768-mainline | Actividad del proyecto mainline | 2026-11-24 |
| P7 | https://github.com/hataketsu/mt6768-mainline-notes | Trabajo mainline en otro dispositivo MT6769T | 2026-11-24 |

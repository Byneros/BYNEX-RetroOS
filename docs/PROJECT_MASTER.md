# BYNEX Retro OS — Documento maestro del proyecto

**Sprint 0 — Auditoría técnica de viabilidad**
**Fecha de cierre de investigación:** 2026-11-24
**Modo de trabajo:** investigación y diagnóstico de solo lectura. Ningún teléfono fue modificado, desbloqueado ni flasheado durante este sprint.

---

## 1. Resumen ejecutivo

El objetivo del proyecto es convertir un **Xiaomi Redmi 10 (modelo 21061119AL, codename `selene`, MediaTek Helio G88 / MT6769H)** en una consola dedicada exclusivamente a videojuegos retro, preferiblemente con software libre y sin servicios de pago.

Resultado de la auditoría:

1. **Ninguna distribución Linux retro (Batocera, Lakka, EmuELEC, RetroPie) soporta este dispositivo, ni existe una vía de instalación directa.** No aparece `selene`, `21061119AL` ni ningún SoC MediaTek MT6768/MT6769 en sus listas oficiales de hardware. Estas distribuciones arrancan mediante U-Boot/ABL sobre placas y consolas portátiles concretas, no sobre bootloaders de teléfonos Android bloqueados.
2. **El único soporte real de Linux en el dispositivo es experimental y de tipo "downstream".** postmarketOS documenta `xiaomi-selene` y `xiaomi-eos` como ports *downstream* (kernel de fabricante), con arranque y red USB reportados, y el resto de periféricos sin estado confirmado. El kernel mainline de MT6768 existe y está activo, pero su propia documentación marca WiFi, Bluetooth, audio y suspensión como rotos, y no hay port mainline de `selene`.
3. **Android es la única plataforma con soporte práctico hoy.** Existen árboles de dispositivo comunitarios para LineageOS (hasta `lineage-23.2`), pero **LineageOS no lista `selene` como dispositivo oficial** (la página oficial devuelve 404). Las compilaciones existentes son no oficiales y no verificadas por este equipo.
4. **La recomendación técnica es una ruta Android en dos fases:** (Fase 1) mantener MIUI y montar un frontend retro con emuladores/libres y gratuitos, midiendo rendimiento real; (Fase 2) solo si las métricas lo justifican, desbloquear el bootloader e instalar LineageOS no oficial + frontend propio, con plan de reversión. **No se recomienda intentar portar Batocera/Lakka/EmuELEC/RetroPie a `selene`**: el coste es de un port de plataforma completo (U-Boot + mainline + drivers) sin base existente y con periféricos clave rotos.

> Nota importante: este documento distingue en todo momento entre **soporte oficial**, **comunitario**, **experimental**, **teórico** y **no compatible**. No se declara compatibilidad sin una fuente que la respalde.

---

## 2. Identidad del dispositivo

| Campo | Valor | Fuente | Confianza |
|---|---|---|---|
| Fabricante | Xiaomi | [F1] | Alta |
| Familia / modelo comercial | Redmi 10 (2021) | [F1] | Alta |
| Modelo exacto | 21061119AL (variante LATAM, 128 GB) | [F1], [F2] | Alta |
| Codename interno | `selene` | [F1], [F2] | Alta |
| SoC | MediaTek Helio G88 (12 nm), familia MT6768 / MT6769H | [F1], [F5], [F9] | Alta |
| CPU | 2× Cortex-A75 + 6× Cortex-A55 | [F1] | Alta |
| GPU | ARM Mali-G52 MC2 | [F1], [F5] | Alta |
| RAM / almacenamiento | 4 o 6 GB LPDDR4X / 64 o 128 GB eMMC 5.1 | [F1] | Alta (variante concreta a confirmar en la unidad) |
| Pantalla | LCD 6,5" 1080×2400, 90 Hz | [F1] | Alta |
| Batería | 5000 mAh, carga 18 W | [F1] | Alta |
| Sistema de origen | Android 11 + MIUI 12.5 | [F1] | Alta |
| Sistema actual declarado | MIUI Global 14.0.4 (Android 13) | Declaración del usuario; rango coherente con [F1], [F25] | Media (verificar con script) |
| Arquitectura | ARM64 (arm64-v8a), con ABI secundaria armeabi-v7a | [F5] | Alta |
| Esquema de particiones | A/B con particiones dinámicas (`super`) y AVB | [F5] | Alta |

**Advertencia de variantes:** `selene` agrupa Redmi 10, Redmi 10 Prime y Redmi 10 2022; `selenes` es otra familia (Redmi Note 11 4G / Redmi 10 2022). Cambian batería, bandas, NFC y hasta el tipo de bandeja SIM. Cualquier imagen o árbol de dispositivo debe verificarse contra el modelo exacto `21061119AL` y contra los valores leídos del propio teléfono, no solo contra el codename. Ver [F1] y [F2].

---

## 3. Alcance y no alcance

### En alcance (Sprint 0)

- Auditar el soporte real de Batocera, Lakka, EmuELEC, RetroPie, postmarketOS, LineageOS y AOSP para `selene`.
- Documentar hardware, kernels, árboles de dispositivo, blobs y controladores disponibles.
- Evaluar una alternativa Android AOSP con launcher retro propio.
- Identificar riesgos, dependencias y requisitos de recuperación.
- Entregar un script de diagnóstico **de solo lectura** para Windows/PowerShell.

### Fuera de alcance (prohibido en este sprint)

- Desbloquear el bootloader.
- Ejecutar `fastboot flash`, `fastboot erase`, `fastboot format`, `fastboot oem unlock`, `mtkclient`, SP Flash Tool en modo escritura, o cualquier comando que modifique particiones.
- Instalar firmware, ROMs, recoveries o módulos.
- Root, Magisk, KernelSU o modificación del sistema.
- Ejecutar scripts de terceros sin revisión.
- Contratar servicios, usar APIs de pago o generar cualquier cobro.

El script `scripts/diagnose-device.ps1` respeta estas restricciones: solo ejecuta consultas (`getprop`, `dumpsys`, `df`, `cat` de archivos de solo lectura) y, opcionalmente, `fastboot getvar` (lectura de variables).

---

## 4. Taxonomía de estados usada en todo el proyecto

| Código | Estado | Definición operativa |
|---|---|---|
| **OF** | Oficial | El proyecto upstream publica builds/imágenes para `selene` y lo lista como dispositivo soportado. |
| **CO** | Comunitario | Existen árboles de dispositivo y/o builds de terceros, sin respaldo upstream. |
| **EX** | Experimental | Algo arranca o está documentado como parcial, pero no es apto como sistema diario y carece de validación amplia. |
| **TE** | Teórico | Sería posible con trabajo de port/ingeniería, pero hoy no hay artefacto ni evidencia de funcionamiento. |
| **NC** | No compatible | No hay soporte ni vía razonable sin reescribir la plataforma; evidencia de ausencia en listas oficiales. |

Regla de evidencia: una fila solo puede marcarse **OF** o **CO** si existe una URL verificable. Los estados **EX/TE** exigen además indicar qué falta. Los **NC** exigen haber comprobado la lista oficial de hardware.

---

## 5. Hallazgos clave (con evidencia)

### 5.1 Las distribuciones retro no soportan teléfonos MediaTek

- **Batocera** publica imágenes para 224 dispositivos: PC x86-64, Raspberry Pi, Steam Deck, consolas ARM (Anbernic, Retroid, AYN, etc.), placas Rockchip/Amlogic/Allwinner. **No hay ningún Xiaomi, ningún MediaTek MT6768, ni ningún teléfono genérico.** [F12]
- **Lakka** organiza sus descargas por Raspberry Pi, SBC/handhelds Rockchip, Allwinner, Amlogic, NXP, Exynos, PC genérico y Nintendo Switch. **No hay MediaTek ni teléfonos.** [F14]
- **EmuELEC** se define como "retro emulation for Amlogic devices", basado en CoreELEC, con soporte Rockchip añadido para Odroid Go. **No hay soporte MediaTek.** [F15]
- **RetroPie** se instala sobre Raspberry Pi OS, OSMC en Vero4K, Ubuntu en ODroid-C1 o PC. **No hay soporte para Android ni para teléfonos.** [F16]
- Incluso en consolas Android, Batocera no es una app: requiere reemplazar el bootloader/arranque por U-Boot o ABL y arrancar desde microSD; en AYN Odin se ejecuta un script que **respalda y flashea el bootloader** para habilitar el arranque Linux. [F13] Ese procedimiento es exactamente lo que este sprint prohíbe y, además, no existe para `selene`.

### 5.2 postmarketOS: ports downstream, no mainline

- El wiki de postmarketOS lista:
  - `Xiaomi Redmi 10 (xiaomi-eos)` — MT6769H, **Booting: Yes**, **categoría: downstream**, USB Net sí, flashing no, resto de columnas vacías (sin probar). [F10]
  - `Xiaomi Redmi 10 2022 (xiaomi-selene)` — MT6769H, **Booting: Yes**, **downstream**, USB Net sí, flashing no, resto sin probar. [F10]
- "Downstream" significa, según la propia clasificación de postmarketOS, ports que usan el kernel original del fabricante y que "suelen tener funciones muy limitadas". [F11]
- El SoC MT6768/MT6769 tiene soporte mainline **parcial**: GPU funciona, display parcial; **audio, vídeo acelerado, WiFi, Bluetooth, módem, GPS, cámara y suspensión están rotos**. [F9]
- El proyecto `mt6768-mainline` está activo (repos actualizados en noviembre de 2026) y trabaja en U-Boot, TF-A y Linux mainline para MT6768, pero **no publica un port para `selene`**. [F26]

**Conclusión:** hoy no existe una imagen de postmarketOS utilizable como consola en `selene`; lo que hay es un port de arranque downstream con periféricos sin validar.

### 5.3 LineageOS: sin soporte oficial

- `https://wiki.lineageos.org/devices/selene/` devuelve **404**. [F3]
- El portal oficial de descargas no lista `selene` entre los dispositivos con builds. [F4]
- Sí existen árboles comunitarios:
  - `selene-devs/android_device_xiaomi_selene` (rama `lineage-20`, creado en 2023, ~777 commits). [F6]
  - `xiaomi-selene/android_device_xiaomi_selene` (rama `lineage-23.2`, organización creada en 2025, ~368 commits). [F5]
- Existen compilaciones no oficiales de terceros (por ejemplo, un `/e/OS 4.3-t ... UNOFFICIAL-selene` construido desde el manifiesto de `selene-devs`). [F20]
- Un agregador de ROMs independiente, consultado el 2026-11-24, indica que **ningún proyecto de ROM de su lista incluye `selene`**. [F23]

**Conclusión:** LineageOS es la vía Android más madura, pero es **comunitaria y no verificada**. No debe presentarse como "sistema soportado".

### 5.4 Kernel y blobs: dependencia crítica

- Xiaomi solo publicó el kernel **`selene-r-oss` (Android 11 / R)**. [F7]
- Hay una **issue abierta** solicitando los fuentes de kernel para Android 12 y 13; sigue sin resolución (último comentario de agosto de 2026). [F8]
- Los árboles comunitarios usan kernel **4.14.x** downstream, con módulos precompilados extraídos de la ROM oficial (por ejemplo, de `V14.0.4.0.TKUMIXM`). [F27], [F28]
- Consecuencia: cualquier sistema no-Android hereda un kernel 4.14 de fabricante, fuera de soporte upstream y sin los drivers mainline necesarios; cualquier Android nuevo depende de blobs y de un kernel viejo.

### 5.5 AOSP/GSI: posible en teoría, no verificado

- El dispositivo es **arm64 A/B** y compatible con Project Treble según la lista de /e/OS. [F18]
- Pero hay reportes de GSIs Android 13 quedándose en el logo de arranque en un Redmi 10 2022, incluso tras degradar firmware. [F19]
- No se encontró evidencia verificable de una GSI concreta que arranque y funcione por completo en `21061119AL`.

**Conclusión:** GSI es un experimento de bajo coste y alto riesgo, no una base de producto.

---

## 6. Opciones de arquitectura

### Opción A — Android + frontend retro (recomendada)

**A1. MIUI actual + apps libres (sin desbloquear, reversible).**
Instalar RetroArch (GPLv3) y/o Lemuroid (open source, basado en Libretro) y, opcionalmente, un launcher retro FOSS propio. Cero modificación del sistema, cero riesgo de ladrillo, cero coste. Limitación: no hay una experiencia "consola" pura; notificaciones y servicios de MIUI siguen presentes.

**A2. LineageOS no oficial + frontend propio (Fase 2).**
Desbloqueo oficial del bootloader, instalación de una build comunitaria verificada, sin GApps, arranque directo al frontend. Requiere validación previa de la build, backup completo y plan de recuperación. Riesgo medio-alto.

### Opción B — postmarketOS + emuladores Linux

Solo tendría sentido si existiera un port mainline funcional. No existe. En el estado actual faltan WiFi, Bluetooth, audio y suspensión; un frontend tipo EmulationStation no arrancaría de forma utilizable. **Descartada por ahora; se reevalúa si `mt6768-mainline` publica soporte para `selene`.**

### Opción C — Portar una distro retro (Batocera/Lakka/EmuELEC/RetroPie)

Implicaría, como mínimo: port de U-Boot/TF-A para el bootloader MediaTek, árbol DTS de `selene`, drivers de panel/táctil/PMIC/audio/WiFi/BT, integración de la capa gráfica (Mali-G52 con Panfrost o blobs), y un sistema de arranque que respete AVB/A-B. No hay base upstream para `selene` y los periféricos clave están rotos en mainline. **No recomendada**: esfuerzo de plataforma completo, resultado incierto, nulo retorno frente a la Opción A.

---

## 7. Plan por fases

| Fase | Objetivo | Entregable | Criterio de salida |
|---|---|---|---|
| **Sprint 0 (este)** | Auditoría de viabilidad | Documentos + script de diagnóstico | Informe firmado con recomendación |
| **Sprint 1** | Medición real en el dispositivo, sin modificarlo | `diagnostics/` con JSON y MD del script; benchmark de emuladores instalados manualmente por el usuario | Identidad y hardware confirmados; FPS/frametimes por sistema |
| **Sprint 2** | Decisión go/no-go para desbloqueo | Actualización de `FEASIBILITY_REPORT.md` y `RISK_ASSESSMENT.md` | Rendimiento y estabilidad aceptables; backup y recuperación probados |
| **Sprint 3** | Build Android personalizada (si go) | Imagen LineageOS verificada + launcher FOSS + perfil de arranque | Instalación reproducible y reversión documentada |
| **Sprint 4 (opcional)** | Exploración mainline | Evaluación de `mt6768-mainline` para `selene` | Soportes de display/táctil/audio/WiFi en mainline |

---

## 8. Índice de entregables

| Archivo | Contenido |
|---|---|
| `docs/PROJECT_MASTER.md` | Este documento: alcance, identidad, hallazgos, opciones, plan |
| `docs/HARDWARE_SPECIFICATIONS.md` | Especificaciones y cadena de arranque, con grado de confianza |
| `docs/BENCHMARK_PROTOCOL.md` | Protocolo de medición de FPS, frametime, térmica y autonomía (Sprint 1) |
| `docs/RECOVERY_PLAN.md` | Runbook de recuperación: backups, árbol de decisión y procedimientos |
| `research/BATOCERA.md` | Batocera: soporte real, requisitos, veredicto |
| `research/LAKKA.md` | Lakka: soporte real, requisitos, veredicto |
| `research/EMUELEC.md` | EmuELEC: soporte real, requisitos, veredicto |
| `research/RETROPIE.md` | RetroPie: soporte real, requisitos, veredicto |
| `research/POSTMARKETOS.md` | postmarketOS: ports downstream, mainline MT6768 |
| `research/LINEAGEOS.md` | LineageOS: ausencia oficial, árboles comunitarios |
| `research/AOSP.md` | AOSP/GSI, particiones, kernel, launcher propio |
| `reports/COMPATIBILITY_MATRIX.md` | Matriz sistema × periférico con evidencias |
| `reports/FEASIBILITY_REPORT.md` | Evaluación ponderada y recomendación |
| `reports/RISK_ASSESSMENT.md` | Riesgos, mitigaciones, recuperación |
| `scripts/diagnose-device.ps1` | Diagnóstico Windows/PowerShell de solo lectura |
| `launcher/` | Esqueleto Android del launcher retro (HOME, escaneo de ROMs, intent a RetroArch, fallback a Lemuroid, FileProvider) y sus tests JVM e instrumentados |
| `diagnostics/benchmark-template.json` | Plantilla de resultados del protocolo de benchmark |
| `scripts/aggregate-benchmarks.ps1` | Agrega los JSON de benchmark en `diagnostics/bench-summary.md` |
| `scripts/install-launcher.ps1` | Instala, consulta o revierte el launcher por ADB (sin root) |

---

## 9. Limitaciones de esta auditoría

- **No se dispone de acceso físico al teléfono en este sprint.** Todo dato de hardware proviene de fuentes públicas y de árboles de dispositivo; los valores reales de la unidad (RAM, variante, versión de MIUI, estado de AVB, controlador táctil) deben confirmarse con el script.
- **No se descargó ni ejecutó ninguna imagen** para `selene`; por tanto no se afirma que arranque.
- **No se realizaron benchmarks.** Cualquier expectativa de rendimiento es cualitativa y debe medirse en el Sprint 1.
- Varias fuentes comunitarias (foros, repos personales) son **evidencia de existencia, no de calidad**. Se marcan como tales.
- El wiki de postmarketOS bloquea el acceso automatizado (Anubis); los datos se obtuvieron de resultados indexados de sus propias páginas y se citan con URL directa para verificación humana.

---

## 10. Bibliografía

| ID | Fuente | Qué evidencia | Acceso |
|---|---|---|---|
| F1 | https://en.wikipedia.org/wiki/Redmi_10 | Especificaciones, modelos, codenames | 2026-11-24 |
| F2 | https://phonedb.net/index.php?m=device&id=19467 | `21061119AL` = Redmi 10 LATAM, codename `selene` | 2026-11-24 |
| F3 | https://wiki.lineageos.org/devices/selene/ | 404: `selene` no está en el wiki oficial de LineageOS | 2026-11-24 |
| F4 | https://download.lineageos.org/devices | Portal oficial de builds; `selene` no aparece | 2026-11-24 |
| F5 | https://github.com/xiaomi-selene/android_device_xiaomi_selene | Árbol de dispositivo `lineage-23.2`, `BoardConfig.mk` (A/B, `super`, AVB, kernel) | 2026-11-24 |
| F6 | https://github.com/selene-devs/android_device_xiaomi_selene | Árbol comunitario `lineage-20` | 2026-11-24 |
| F7 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource | Solo `selene-r-oss` (Android R) publicado | 2026-11-24 |
| F8 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/39094 | Issue abierta pidiendo fuentes de kernel Android 12/13 | 2026-11-24 |
| F9 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado mainline de MT6768: WiFi/BT/audio/suspensión rotos | 2026-11-24 |
| F10 | https://wiki.postmarketos.org/wiki/Xiaomi | Tabla de dispositivos Xiaomi: `xiaomi-eos` y `xiaomi-selene` downstream | 2026-11-24 |
| F11 | https://wiki.postmarketos.org/wiki/Devices | Definición de categorías (downstream = kernel de fabricante) | 2026-11-24 |
| F12 | https://batocera.org/download | 224 dispositivos soportados; ninguno MediaTek/Xiaomi | 2026-11-24 |
| F13 | https://wiki.batocera.org/hardware:ayn | Batocera en consolas Android requiere reemplazar bootloader (U-Boot/ABL) | 2026-11-24 |
| F14 | https://www.lakka.tv/get/linux/ | Categorías de hardware soportado; sin MediaTek | 2026-11-24 |
| F15 | https://github.com/EmuELEC/EmuELEC | "Retro emulation for Amlogic devices" | 2026-11-24 |
| F16 | https://github.com/RetroPie/RetroPie-Setup | Plataformas: RPi, Vero4K, ODroid-C1, PC Ubuntu | 2026-11-24 |
| F17 | https://rocknix.org/devices | ROCKNIX: Rockchip/Allwinner/Amlogic/Qualcomm; sin MediaTek | 2026-11-24 |
| F18 | https://community.e.foundation/t/device-support-project-treble/19645 | `selene` listado como arm64 A/B (Treble) | 2026-11-24 |
| F19 | https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 | GSI Android 13 no arranca; uso de SP Flash Tool/BROM para recuperar | 2026-11-24 |
| F20 | https://community.e.foundation/t/redmi-10-prime-selene/82511 | Build `/e/OS` no oficial para `selene` desde manifiesto `selene-devs` | 2026-11-24 |
| F21 | https://github.com/Swordfish90/Lemuroid | Emulador/frontend Android open source basado en Libretro | 2026-11-24 |
| F22 | https://github.com/TapiocaFox/Daijishou | Frontend gratuito pero **closed-source** (se descarta como opción FOSS) | 2026-11-24 |
| F23 | https://thecustomrom.com/devices/xiaomi/selene | Ningún proyecto de ROM rastreado lista `selene` (2026-11-24) | 2026-11-24 |
| F24 | https://github.com/hasan6034/recovery_device_xiaomi_selene | Árbol TWRP comunitario para `selene` | 2026-11-24 |
| F25 | http://xmfirmwareupdater.com/archive/miui/selene | Firmware MIUI oficial archivado para `selene` | 2026-11-24 |
| F26 | https://github.com/mt6768-mainline | Proyecto mainline MT6768 activo (U-Boot, TF-A, Linux) | 2026-11-24 |
| F27 | https://github.com/techyminati/selene | Kernel comunitario 4.14.186 para Redmi 10/10 Prime | 2026-11-24 |
| F28 | https://codeberg.org/xiaomi-mt6768-dev/android_device_xiaomi_selene-kernel | Módulos/kernel precompilados de `V14.0.4.0.TKUMIXM` | 2026-11-24 |

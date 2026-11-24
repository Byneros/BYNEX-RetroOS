# LineageOS — soporte para Xiaomi Redmi 10 (`selene`)

**Veredicto: COMUNITARIO / EXPERIMENTAL (CO-EX)**. No oficial; builds de terceros no verificadas.
**Fecha:** 2026-11-24

---

## 1. Qué es

LineageOS es una distribución Android de código abierto basada en AOSP, con su propio árbol de dispositivos y su propio portal de descargas. Solo los dispositivos listados en su wiki y en su portal se consideran **oficialmente soportados**.

---

## 2. ¿Es `selene` un dispositivo oficial?

**No.**

| Comprobación | Resultado | Fuente |
|---|---|---|
| Página oficial del dispositivo | `https://wiki.lineageos.org/devices/selene/` → **HTTP 404** | [C1] |
| Portal oficial de descargas | `selene` no aparece en la lista de dispositivos con builds | [C2] |
| Agregador independiente de ROMs (2026-11-24) | Ningún proyecto de su lista incluye `selene` | [C3] |

Conclusión: **no existe una build oficial de LineageOS para este teléfono**. Cualquier afirmación de "LineageOS soportado" sería incorrecta.

---

## 3. Árboles de dispositivo comunitarios

Sí existen árboles mantenidos por terceros:

| Repositorio | Rama | Actividad | Notas |
|---|---|---|---|
| `selene-devs/android_device_xiaomi_selene` | `lineage-20` | Creado 2023-02, ~777 commits | Árbol completo con `extract-files.sh`, `releasetools.py`, overlays, shims |
| `xiaomi-selene/android_device_xiaomi_selene` | `lineage-23.2` | Organización creada 2025-01, ~368 commits | Árbol más reciente; usa `extract-files.py` y `proprietary-firmware.txt` |
| `AlphaDroid-devices/device_xiaomi_selene` | `alpha-13` | 2023-10 | Derivado del árbol Lineage |
| `hasan6034/recovery_device_xiaomi_selene` | `android-12.1` | 2024 | Árbol TWRP; 7 commits |

Fuentes: [C4], [C5], [C6], [C7].

**Importante:** la existencia de un árbol **no equivale** a una build estable. Un árbol puede compilar y no arrancar, o arrancar con periféricos rotos.

---

## 4. Evidencia de compilaciones no oficiales

- Un hilo de la comunidad /e/OS documenta una build **`e-4.3-t-20260830-UNOFFICIAL-selene.zip`**, construida a partir del manifiesto de `selene-devs`. [C8]
- Un canal de tutoriales lista una **"LineageOS 22.2 UNOFFICIAL (Android 15)"** para Redmi 10 2021/2022. [C9]

Ambas son **evidencia de existencia**, no de calidad. No se ha verificado:

- Integridad de los artefactos (firma, hash).
- Lista de funciones que funcionan (cámara, VoLTE, WiFi, huella, audio, etc.).
- Estabilidad a largo plazo y actualizaciones.
- Que la build corresponda a `21061119AL` y no a `selenes`.

---

## 5. Detalles técnicos del árbol `lineage-23.2`

Extraídos de `BoardConfig.mk`: [C5]

| Aspecto | Valor | Implicación |
|---|---|---|
| Plataforma | `mt6768` | Familia Helio G88 |
| Arquitectura | arm64 + arm (A75/A55) | Apps de 64 bits; sin 32-bit-only |
| Particiones | A/B + dinámicas (`super` 9,1 GB) | Instalación por slot; OTA A/B |
| AVB | Activado | Requiere bootloader desbloqueado y vbmeta firmado/testkey |
| Recovery | Recovery-as-boot | No hay partición recovery separada |
| Kernel | Fuente `kernel/xiaomi/selene` + `selene_defconfig` | Kernel 4.14 downstream |
| Módulos | Precompilados de la ROM oficial | Dependencia de blobs |
| SELinux | `permissive` en la config comunitaria | Menor seguridad; indica port no pulido |
| Security patch | 2023-09-01 | Desactualizado frente a 2026 |
| Wi-Fi | Driver MediaTek WMT (`/dev/wmtWifi`) | Depende de blobs, no de mainline |

**Riesgo de seguridad:** un sistema Android con parches de 2023 y SELinux permisivo no debe considerarse seguro para uso conectado. Para una consola offline el riesgo baja, pero sigue siendo relevante si se usa WiFi.

---

## 6. Dependencia de kernel y blobs

- Xiaomi publicó únicamente el kernel de **Android 11** (`selene-r-oss`). [C10]
- La petición de fuentes para Android 12/13 sigue abierta. [C11]
- Los árboles usan kernel 4.14 y módulos extraídos de MIUI 14 (`V14.0.4.0.TKUMIXM` o similar). [C12]

Esto significa que **todas las builds, oficiales o no, parten de un kernel de 2019–2021 sin soporte upstream**. No hay una base mainline para Android en este SoC.

---

## 7. Qué se puede esperar (sin afirmar compatibilidad)

| Aspecto | Expectativa | Evidencia |
|---|---|---|
| Arranque | Probable en builds comunitarias reportadas | [C8], [C9] (no verificado) |
| Pantalla/táctil | Probable, es lo primero que se porta | No verificado |
| WiFi/BT | Depende de blobs MediaTek; probable pero frágil | No verificado |
| Audio | Probable con blobs | No verificado |
| Cámara | Frecuentemente parcial en ports MTK | No verificado |
| VoLTE/llamadas | Frecuentemente roto en ports MTK | No verificado |
| Batería/suspensión | Normalmente funciona en Android | No verificado |
| Actualizaciones | Sin canal oficial; dependen del maintainer | [C1], [C3] |

**No se debe presentar ninguna de estas filas como "funciona" hasta probarla en la unidad.**

---

## 8. Instalación y recuperación

Requisitos:

1. **Desbloqueo oficial del bootloader Xiaomi** (Mi Unlock, cuenta Xiaomi, periodo de espera). No realizado en este sprint.
2. Recovery compatible: existen árboles TWRP/PBRP comunitarios, pero **no hay OrangeFox oficial** y los reportes muestran intentos fallidos con recoveries de otros dispositivos. [C13]
3. `vbmeta` con verificación desactivada o firmado con las claves de la build.
4. Copia de seguridad de `persist`, `nvram`/`nvdata` y del boot original.

Recuperación en caso de fallo: modo BROM + SP Flash Tool con firmware fastboot oficial. [C13], [C14] Es una operación delicada y fuera del alcance de este sprint.

---

## 9. Actividad

- El árbol `lineage-23.2` indica que hay trabajo reciente (2025–2026) por parte de la organización `xiaomi-selene`.
- No hay builds oficiales, ni canal de releases verificable, ni maintainer listado por LineageOS.
- El agregador de ROMs no lo considera soportado. [C3]

Conclusión: **proyecto pequeño, sin gobernanza upstream, con actividad esporádica**. Puede desaparecer sin aviso.

---

## 10. Conclusión

LineageOS es la **mejor base Android** para una consola retro en `selene`, pero:

- **No es oficial.**
- **No hay build verificada por este equipo.**
- **El kernel es 4.14 y los parches de seguridad son de 2023.**
- **La instalación exige desbloquear el bootloader y asumir riesgo de ladrillo.**

Se recomienda tratarlo como **Fase 2, condicionada a una validación previa** (build concreta, hash, lista de funciones probadas, plan de recuperación). Para la Fase 1, MIUI + apps libres ofrece el 80% del valor con riesgo cero.

---

## 11. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| C1 | https://wiki.lineageos.org/devices/selene/ | 404: no oficial | 2026-11-24 |
| C2 | https://download.lineageos.org/devices | Portal oficial sin `selene` | 2026-11-24 |
| C3 | https://thecustomrom.com/devices/xiaomi/selene | Ningún proyecto rastreado lista `selene` | 2026-11-24 |
| C4 | https://github.com/selene-devs/android_device_xiaomi_selene | Árbol comunitario `lineage-20` | 2026-11-24 |
| C5 | https://github.com/xiaomi-selene/android_device_xiaomi_selene | Árbol `lineage-23.2` y `BoardConfig.mk` | 2026-11-24 |
| C6 | https://github.com/AlphaDroid-devices/device_xiaomi_selene | Árbol derivado | 2026-11-24 |
| C7 | https://github.com/hasan6034/recovery_device_xiaomi_selene | Árbol TWRP comunitario | 2026-11-24 |
| C8 | https://community.e.foundation/t/redmi-10-prime-selene/82511 | Build `/e/OS` no oficial desde manifiesto `selene-devs` | 2026-11-24 |
| C9 | https://www.youtube.com/playlist?list=PL9kpQ1Lm7tfUSf380l9FxnpqiAxwZi6Rh | Indicio de "LineageOS 22.2 UNOFFICIAL" (no verificado) | 2026-11-24 |
| C10 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource | Solo `selene-r-oss` (Android 11) | 2026-11-24 |
| C11 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/39094 | Fuentes Android 12/13 no publicadas | 2026-11-24 |
| C12 | https://codeberg.org/xiaomi-mt6768-dev/android_device_xiaomi_selene-kernel | Módulos precompilados de MIUI 14 | 2026-11-24 |
| C13 | https://xdaforums.com/t/how-to-flash-gsi-on-bricked-redmi-10-selene.4705036 | Ausencia de OrangeFox; intentos con recovery de otro dispositivo | 2026-11-24 |
| C14 | https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 | Recuperación vía BROM/SP Flash Tool | 2026-11-24 |

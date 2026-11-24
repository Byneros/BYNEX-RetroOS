# Especificaciones de hardware — Xiaomi Redmi 10 `selene` (21061119AL)

**Propósito:** base de referencia para evaluar portabilidad de sistemas operativos.
**Método:** fuentes públicas + árboles de dispositivo comunitarios + `BoardConfig.mk`.
**Estado:** los datos marcados como **PENDIENTE** solo pueden confirmarse con el teléfono en mano (`scripts/diagnose-device.ps1`).

Códigos de confianza:

- **A (Alta):** dato repetido en fuentes públicas independientes y coherente con el árbol de dispositivo.
- **B (Media):** dato de una fuente razonable o derivado de configuración de build; puede variar por variante.
- **C (Baja):** inferencia de familia de SoC, no confirmada para `selene`.

---

## 1. Identificación

| Campo | Valor | Confianza | Fuente |
|---|---|---|---|
| Marca | Xiaomi | A | [H1] |
| Modelo comercial | Redmi 10 (2021) | A | [H1] |
| Modelo exacto | 21061119AL | A | [H1], [H2] |
| Codename | `selene` | A | [H1], [H2] |
| Plataforma Android | `mt6768` | A | [H3] |
| SoC | MediaTek Helio G88 (MT6769H), 12 nm | A | [H1], [H4] |
| Arquitectura | arm64-v8a + armeabi-v7a | A | [H3] |

**Variantes que comparten o rozan el codename:**

- Redmi 10 / Redmi 10 Prime → `selene` (Prime: batería 6000 mAh).
- Redmi 10 2022 / Redmi 10 Prime 2022 / Redmi Note 11 4G → `selenes`.
- Modelo `21061119AL` corresponde a la variante LATAM de 128 GB del Redmi 10. [H2]

No usar una imagen de `selenes` en `selene` ni viceversa.

---

## 2. SoC, CPU y GPU

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| SoC | MediaTek Helio G88 (MT6769H) | A | [H1], [H4] |
| Proceso | 12 nm | A | [H1] |
| CPU | 8 núcleos: 2× Cortex-A75 + 6× Cortex-A55 | A | [H1] |
| Frecuencias | 2,0 GHz (A75) / 1,8 GHz (A55) según infobox; el texto de Wikipedia cita 2,2 GHz | B | [H1] |
| ISA | ARMv8.2-A, AArch64 | A | [H3] |
| GPU | ARM Mali-G52 MC2 | A | [H1], [H3] |
| Driver GPU en Android | Blobs MediaTek (no Panfrost) | B | [H3] |
| Driver GPU en Linux mainline | Panfrost/Mali G52 (estado "Works" para GPU en MT6768) | B | [H4] |

**Implicación para emulación:** Mali-G52 MC2 es una GPU de gama baja de 2021. RetroArch con cores ligeros (8/16 bits, PS1) es el objetivo realista; N64/PSP/Dreamcast pueden requerir ajustes y no están medidos. **No hay benchmarks en este sprint.**

---

## 3. Memoria y almacenamiento

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| RAM | 4 GB o 6 GB LPDDR4X | A | [H1] |
| Almacenamiento | 64 GB o 128 GB eMMC 5.1 | A | [H1] |
| microSD | microSDXC, hasta 512 GB (Wikipedia); el árbol de dispositivo cita 256 GB | B | [H1], [H6] |
| Particiones | A/B + dinámicas (`super`) | A | [H3] |
| Tamaño `super` | 9 126 805 504 bytes (~8,5 GiB) | A | [H3] |
| `boot` | 64 MiB | A | [H3] |
| `dtbo` | 8 MiB | A | [H3] |

**PENDIENTE:** RAM real y variante exacta (4/6 GB, 64/128 GB). Se lee con `getprop ro.product.*` y `/proc/meminfo` mediante el script.

---

## 4. Pantalla y táctil

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| Tipo | IPS LCD | A | [H1] |
| Tamaño | 6,5" | A | [H1] |
| Resolución | 1080 × 2400 (20:9), ~405 ppi | A | [H1] |
| Refresco | 90 Hz | A | [H1] |
| Densidad configurada en Android | 440 dpi | A | [H3] |
| Protección | Gorilla Glass 3 | A | [H1] |
| Panel concreto (fabricante/modelo) | Desconocido | C | — |
| Controlador táctil | Desconocido para `selene` | C | — |

**Riesgo de port:** en Linux, el panel y el táctil son los drivers que más frecuentemente bloquean un port. El wiki de MT6768 marca *Display: Partial* y no garantiza táctil. [H4] En `selene` no hay DTS mainline publicado.

**PENDIENTE:** fabricante del panel y controlador táctil. Se obtienen de forma read-only con `cat /proc/bus/input/devices` y `dumpsys input` (el script captura los dispositivos de entrada, no los drivers del kernel).

---

## 5. Audio

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| Altavoces | Estéreo | A | [H1] |
| Jack 3,5 mm | Sí | A | [H1] |
| Códec/PMIC | Familia MT6358 (común en MT6768) | C | [H5] |
| Audio en Linux mainline | **Broken** en MT6768 según postmarketOS | B | [H4] |

El audio es un bloqueante conocido en mainline para esta familia. En Android funciona mediante blobs del fabricante.

---

## 6. Conectividad

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| Wi-Fi | 802.11 a/b/g/n/ac, dual-band, Wi-Fi Direct | A | [H1] |
| Bluetooth | 5.1, A2DP, LE | A | [H1] |
| Módem | 2G/3G/4G LTE (sin 5G) | A | [H1] |
| GPS | A-GPS, GLONASS, GALILEO, BDS | A | [H1] |
| NFC | Depende de modelo/región; el árbol define un SKU `eos` con manifiesto propio | B | [H1], [H3] |
| FM | Sí (flag `BOARD_HAVE_MTK_FM`) | A | [H3], [H1] |
| USB | USB-C 2.0, OTG | A | [H1] |
| Wi-Fi en Android | Driver MediaTek WMT (`/dev/wmtWifi`, `NL80211`) | A | [H3] |
| Wi-Fi/BT en Linux mainline | **Broken** en MT6768 | B | [H4] |

La conectividad MediaTek integrada (CONNAC) es uno de los mayores obstáculos para Linux: no hay driver mainline funcional para esta generación. [H4]

---

## 7. Batería y energía

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| Batería | 5000 mAh Li-Po, no extraíble | A | [H1] |
| Carga | 18 W por cable | A | [H1] |
| Carga inversa | 9 W | A | [H1] |
| Cargador en caja | 22,5 W | B | [H1] |
| PMIC | Familia MT6358 | C | [H5] |
| Suspensión en Linux mainline | **Broken** | B | [H4] |

El árbol de dispositivo comunitario indica 5020 mAh; Wikipedia indica 5000 mAh. Se adopta 5000 mAh (fuente pública) y se anota la discrepancia. La capacidad real se puede leer con `dumpsys battery` (nivel, salud, temperatura), no con la capacidad de diseño.

**Riesgo:** sin suspensión funcional en Linux, la autonomía sería muy inferior a la de Android. Es un bloqueante para una consola portátil.

---

## 8. Sensores, cámara y botones

| Componente | Dato | Confianza | Fuente |
|---|---|---|---|
| Huella | Lector lateral en el botón de encendido | A | [H1] |
| Acelerómetro | Sí | A | [H1] |
| Proximidad | Sí | A | [H1] |
| Brújula | Sí | A | [H1] |
| Cámara trasera | 50 MP + 8 MP + 2 MP + 2 MP | A | [H1] |
| Cámara frontal | 8 MP | A | [H1] |
| Botones | Volumen + encendido/huella | A | [H1] |
| Vibrador | Sí (`TARGET_VIBRATOR_SUPPORTS_EFFECTS`) | A | [H3] |

Para una consola retro, cámara y sensores son irrelevantes; el **mando** se resolverá por Bluetooth o USB-OTG. El teléfono no tiene gamepad integrado.

---

## 9. Cadena de arranque y particiones

Datos extraídos de `BoardConfig.mk` del árbol `lineage-23.2`: [H3]

| Elemento | Valor |
|---|---|
| Esquema | A/B (`AB_OTA_PARTITIONS`: boot, dtbo, system, system_dlkm, system_ext, product, vendor, vendor_dlkm, odm, odm_dlkm, vbmeta*) |
| Particiones dinámicas | `super` con grupo `xiaomi_dynamic_partitions` |
| Verified Boot | `BOARD_AVB_ENABLE := true` (AVB con test keys en builds comunitarias) |
| Recovery | `BOARD_USES_RECOVERY_AS_BOOT := true` (recovery en boot) |
| Kernel | Fuente `kernel/xiaomi/selene`, `selene_defconfig`, `Image.gz` |
| Header de boot | v2 |
| Page size | 2048 |
| Base / offsets | base `0x40078000`, kernel `0x00008000`, ramdisk `0x07c08000`, tags/dtb `0x0bc08000` |
| Cmdline | `bootopt=64S3,32N2,64N2`, `androidboot.selinux=permissive` |
| SELinux | Permissive en la configuración comunitaria |
| Security patch del árbol | 2023-09-01 |

**Lectura de seguridad:** AVB activo y bootloader bloqueado implican que **ninguna imagen arranca sin un bootloader desbloqueado y sin desactivar verificación**. Cualquier intento de port Linux debe resolver además el arranque A/B y el `dtbo`.

---

## 10. Software de fábrica

| Elemento | Dato | Confianza | Fuente |
|---|---|---|---|
| Android original | 11 + MIUI 12.5 | A | [H1] |
| Android máximo | 13 + MIUI 14 | A | [H1] |
| Última build global listada | `V14.0.7.0.TKUMIXM` (Android 13, mayo 2024) | B | [H7] |
| Firmware oficial archivado | Sí, fastboot y recovery | A | [H7] |
| Kernel fuente oficial | Solo Android 11 (`selene-r-oss`) | A | [H8] |
| Kernel efectivo en ROMs comunitarias | 4.14.x + módulos precompilados | A | [H9], [H10] |

**PENDIENTE:** confirmar en la unidad `ro.build.version.incremental`, `ro.miui.ui.version.name` y `ro.boot.verifiedbootstate`.

---

## 11. Incógnitas que el diagnóstico debe resolver

| Incógnita | Por qué importa | Cómo se obtiene |
|---|---|---|
| Modelo exacto y codename reales | Evitar imagen de `selenes` | `ro.product.model`, `ro.product.device` |
| RAM y almacenamiento | headroom para emuladores/ROMs | `/proc/meminfo`, `df -h /data` |
| Versión MIUI/Android | compatibilidad de apps y métodos | `ro.build.version.release`, `ro.miui.ui.version.name` |
| Estado del bootloader | viabilidad de cualquier instalación | `ro.boot.flash.locked`, `ro.boot.verifiedbootstate` |
| Slot activo | arranque A/B | `ro.boot.slot_suffix` |
| Panel/táctil | drivers necesarios en un port | `/proc/bus/input/devices` |
| Batería y temperatura | salud y autonomía | `dumpsys battery` |
| Apps de emulación instaladas | inventario del Sprint 1 | `pm list packages` |

---

## 12. Fuentes

| ID | Fuente | Uso | Acceso |
|---|---|---|---|
| H1 | https://en.wikipedia.org/wiki/Redmi_10 | Especificaciones públicas, modelos, variantes | 2026-11-24 |
| H2 | https://phonedb.net/index.php?m=device&id=19467 | Identificación de `21061119AL` como `selene` LATAM | 2026-11-24 |
| H3 | https://github.com/xiaomi-selene/android_device_xiaomi_selene/blob/lineage-23.2/BoardConfig.mk | Plataforma, particiones, kernel, Wi-Fi, densidad, AVB | 2026-11-24 |
| H4 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado de drivers mainline MT6768 | 2026-11-24 |
| H5 | https://github.com/hataketsu/mt6768-mainline-notes | PMIC MT6358 y mapa de memoria en un dispositivo MT6769T de la misma familia (inferencia, no `selene`) | 2026-11-24 |
| H6 | https://github.com/selene-devs/android_device_xiaomi_selene | Especificaciones del árbol comunitario (5020 mAh, microSD 256 GB) | 2026-11-24 |
| H7 | http://xmfirmwareupdater.com/archive/miui/selene | Versiones MIUI oficiales archivadas | 2026-11-24 |
| H8 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource | Único kernel oficial publicado (`selene-r-oss`) | 2026-11-24 |
| H9 | https://github.com/techyminati/selene | Kernel comunitario 4.14.186 | 2026-11-24 |
| H10 | https://codeberg.org/xiaomi-mt6768-dev/android_device_xiaomi_selene-kernel | Módulos precompilados de `V14.0.4.0.TKUMIXM` | 2026-11-24 |

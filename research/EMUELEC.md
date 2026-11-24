# EmuELEC — soporte para Xiaomi Redmi 10 (`selene`)

**Veredicto: NO COMPATIBLE (NC)**
**Fecha:** 2026-11-24

---

## 1. Qué es

EmuELEC es una distribución Linux para emulación retro **orientada a dispositivos Amlogic**, construida sobre CoreELEC (que a su vez deriva de LibreELEC) e integrando piezas de Lakka y Batocera, con EmulationStation como frontend. [E1]

Su propio README la define como *"retro emulation for Amlogic devices"*. [E1]

---

## 2. Soporte para `selene`

### 2.1 Plataformas objetivo

El repositorio oficial documenta la compilación con:

- `PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=aarch64` — dispositivos Amlogic.
- `PROJECT=Rockchip DEVICE=OdroidGoAdvance` — consolas ODROID Go Advance/Super (Rockchip). [E1]

No hay objetivo MediaTek, ni MT6768/MT6769, ni teléfonos.

### 2.2 Lista de dispositivos

La documentación y los hilos del proyecto giran en torno a TV boxes Amlogic (S905/S912/S922) y consolas RK3326/RK3566. No se localizó ninguna referencia a `selene`, `21061119AL` o Helio G88.

### 2.3 Modelo de arranque

EmuELEC se graba en una tarjeta SD/USB y arranca mediante el bootloader de la placa (U-Boot en Amlogic/Rockchip). En un teléfono Android con bootloader bloqueado y AVB, ese modelo no es aplicable sin un port de arranque específico.

---

## 3. Requisitos de un port (teórico)

Idénticos a Batocera/Lakka en lo esencial: U-Boot/TF-A para MT6768, DTS de `selene`, drivers de panel/táctil/PMIC, GPU, audio, Wi-Fi/BT y suspensión. A ello se añade que EmuELEC está muy acoplado a la plataforma Amlogic (CoreELEC), por lo que portarlo a un SoC nuevo implica **añadir una plataforma de build completa**, no solo un DTB.

| Requisito | Estado |
|---|---|
| Plataforma de build para MT6768 | No existe |
| U-Boot/TF-A | Proyecto `mt6768-mainline`, sin `selene` [E4] |
| DTS de `selene` | No existe en mainline |
| Drivers mainline | Audio/WiFi/BT/suspensión rotos; display parcial [E5] |
| Integración CoreELEC | No contempla MediaTek |

---

## 4. Licencia (relevante para el proyecto)

EmuELEC es GPLv2-or-later, pero **incluye emuladores, cores y binarios no comerciales**. Su README prohíbe explícitamente venderlo, empaquetarlo o incluirlo en productos comerciales, incluyendo dispositivos Android. [E1]

Para uso personal y gratuito no hay problema, pero **no se podría distribuir una "consola BYNEX" con EmuELEC preinstalado**. Es un requisito a tener en cuenta si el proyecto se plantea como producto.

---

## 5. Imágenes instalables

- **Ninguna** para `selene`.
- Las imágenes Amlogic/Rockchip no son compatibles con un SoC MediaTek ni con el bootloader de un teléfono.

---

## 6. Actividad

El proyecto sigue publicando versiones (rama `dev`, builds para nuevas consolas), pero su ámbito sigue siendo Amlogic/Rockchip. [E1] No hay indicios de soporte MediaTek.

---

## 7. Conclusión

EmuELEC no es una opción para `selene`. Su filosofía (imagen completa por dispositivo) es incompatible con un teléfono no soportado. La funcionalidad equivalente se cubre con RetroArch/Lemuroid en Android.

---

## 8. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| E1 | https://github.com/EmuELEC/EmuELEC | Definición "for Amlogic devices"; targets Amlogic y Rockchip; restricción de licencia | 2026-11-24 |
| E2 | https://emuelec.org/ | Sitio oficial y descargas | 2026-11-24 |
| E3 | https://github.com/xiaomi-selene/android_device_xiaomi_selene/blob/lineage-23.2/BoardConfig.mk | A/B, `super`, AVB | 2026-11-24 |
| E4 | https://github.com/mt6768-mainline | U-Boot/TF-A/Linux MT6768 sin port `selene` | 2026-11-24 |
| E5 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado de drivers mainline | 2026-11-24 |

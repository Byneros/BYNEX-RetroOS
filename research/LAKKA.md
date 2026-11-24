# Lakka OS — soporte para Xiaomi Redmi 10 (`selene`)

**Veredicto: NO COMPATIBLE (NC)** como imagen; su stack sí es aprovechable en Android vía RetroArch.
**Fecha:** 2026-11-24

---

## 1. Qué es

Lakka es una distribución Linux ligera basada en **RetroArch** (y en la base de LibreELEC), diseñada para convertir una placa o mini-PC en una consola retro. Se distribuye como imagen de disco para hardware concreto y arranca directamente en RetroArch, sin escritorio. [L1]

---

## 2. Soporte para `selene`

### 2.1 Categorías oficiales de hardware

La página oficial de descargas ofrece únicamente estas familias: [L1]

- Raspberry Pi
- SBCs / handhelds **Rockchip**
- SBCs / TV boxes / home arcades **Allwinner**
- SBCs / TV boxes **Amlogic**
- SBCs / TV boxes **NXP**
- SBCs / TV boxes **Exynos**
- PC genérico (x86/x86-64)
- Nintendo Switch

No existe categoría MediaTek, ni Xiaomi, ni teléfonos Android genéricos.

### 2.2 Ausencia de imagen y de árbol de dispositivo

- No hay imagen de Lakka para `selene`, `21061119AL` ni Helio G88. [L1]
- No se localizó un árbol de dispositivo/BSP comunitario de Lakka para `selene`.
- Lakka no se instala como APK sobre Android: es un sistema operativo que reemplaza el arranque. [L1]

---

## 3. Requisitos técnicos de un port

Comparte prácticamente todos los bloqueantes de Batocera:

| Capa | Requisito | Estado |
|---|---|---|
| Arranque | U-Boot/TF-A o ABL modificado para MT6768 | En desarrollo por `mt6768-mainline`, sin `selene`. [L4] |
| Kernel | DTS de `selene`, drivers de panel/táctil/PMIC | No disponible. |
| GPU | Panfrost (Mali-G52 MC2) + EGL/GBM en RetroArch | GPU mainline funciona en MT6768, pero sin integración Lakka. [L5] |
| Audio | ALSA/UCM para MT6358 | Mainline MT6768: *Broken*. [L5] |
| Wi-Fi/BT | Driver CONNAC | *Broken*. [L5] |
| Suspensión | Necesaria para portátil | *Broken*. [L5] |
| Almacenamiento | Arranque desde microSD o reparticionado | A/B + `super` complican el arranque dual. [L3] |

**Estimación cualitativa:** port de plataforma, no de distro. Sin base upstream para `selene`.

---

## 4. La vía pragmática: RetroArch en Android

Lakka es, en esencia, **RetroArch como sistema operativo**. RetroArch existe como aplicación oficial para Android, es software libre (GPLv3) y usa los mismos cores Libretro. [L2]

Por tanto:

- **No se necesita Lakka** para tener la experiencia RetroArch en `selene`.
- Se puede instalar RetroArch en MIUI (Fase 1) o en LineageOS (Fase 2), sin portar nada.
- Se pierde el arranque directo y la integración de sistema; se compensa con un launcher retro (ver `research/AOSP.md`).

Esto convierte el "deseo Lakka" en un requisito de **frontend y arranque**, no de sistema operativo.

---

## 5. Imágenes instalables

- **Ninguna** para `selene`.
- No se debe probar una imagen de otro SoC: no arrancará y puede dejar el dispositivo en bootloop.
- Si en el futuro se quisiera Lakka real, el orden correcto sería: mainline estable para `selene` → U-Boot → Lakka. Hoy no existe el primer paso.

---

## 6. Actividad del proyecto

Lakka mantiene releases periódicas y una base de hardware estable (Raspberry Pi, Rockchip, Amlogic, etc.). [L1] No hay señales de soporte para teléfonos MediaTek ni de un cambio de estrategia hacia bootloaders de teléfono.

---

## 7. Conclusión

Lakka **no es viable** en `selene` como sistema operativo. Su componente principal, RetroArch, **sí es viable** como aplicación Android libre. La recomendación del proyecto es usar RetroArch (o Lemuroid) sobre Android y reservar Lakka para hardware SBC si en el futuro se adquiere uno.

---

## 8. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| L1 | https://www.lakka.tv/get/linux/ | Familias de hardware soportadas; sin MediaTek/teléfonos | 2026-11-24 |
| L2 | https://www.retroarch.com/ | RetroArch oficial, multiplataforma, GPLv3 | 2026-11-24 |
| L3 | https://github.com/xiaomi-selene/android_device_xiaomi_selene/blob/lineage-23.2/BoardConfig.mk | A/B, `super`, AVB | 2026-11-24 |
| L4 | https://github.com/mt6768-mainline | U-Boot/TF-A para MT6768 | 2026-11-24 |
| L5 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado de drivers mainline | 2026-11-24 |

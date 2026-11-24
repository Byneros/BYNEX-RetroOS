# Batocera Linux — soporte para Xiaomi Redmi 10 (`selene`)

**Veredicto: NO COMPATIBLE (NC)** — no existe imagen, port ni vía de instalación para `selene`.
**Fecha:** 2026-11-24

---

## 1. Qué es

Batocera Linux es una distribución Linux completa orientada a emulación, basada en Buildroot, con EmulationStation como frontend, RetroArch y emuladores standalone. Se distribuye como **imagen de disco** para hardware concreto (PC x86-64, Raspberry Pi, consolas ARM, placas SBC y TV boxes), no como aplicación instalable. [B1]

Versión actual en la fecha de auditoría: **Batocera 44**. [B1]

---

## 2. Soporte para `selene` / 21061119AL / Helio G88

### 2.1 Lista oficial de hardware

La página oficial de descargas enumera **224 dispositivos**, agrupados en PC, Raspberry Pi, handhelds (Anbernic, AYN, Retroid, Powkiddy, Mangmi, etc.), placas Rockchip (Radxa, Orange Pi, Pine64, Firefly), Amlogic (ODROID, Khadas, TV boxes), Allwinner, NXP y algunas consolas. [B1]

Comprobaciones realizadas sobre esa lista:

- **Xiaomi:** no aparece.
- **MediaTek / MT6768 / MT6769 / Helio G88:** no aparece.
- **Teléfono genérico / smartphone:** no existe esa categoría.

### 2.2 Cómo arranca Batocera en hardware ARM

Batocera no se instala "dentro de Android". En consolas Android compatibles (p. ej. AYN Odin) el procedimiento oficial consiste en:

1. Copiar un paquete de ABL/U-Boot a la consola.
2. Ejecutar un script como root que **respalda y flashea el bootloader**.
3. Arrancar Batocera desde microSD y seleccionar el modelo de dispositivo en el menú de arranque. [B2]

Es decir: el soporte implica un **bootloader alternativo y una imagen específica del dispositivo**. Para `selene` no existe ni lo uno ni lo otro.

### 2.3 Por qué no basta con "probar la imagen de PC"

- La imagen x86-64 no arranca en ARM64.
- Las imágenes ARM están ligadas a un SoC y a un DTB concretos; el kernel de Batocera no incluye soporte para MT6769H ni para los periféricos de `selene`.
- El bootloader del teléfono está bloqueado y con AVB activo; no acepta un kernel/initramfs arbitrario sin desbloqueo y sin resolver la verificación. [B4]

---

## 3. Qué haría falta para portarlo (análisis teórico)

| Capa | Requisito | Estado para `selene` |
|---|---|---|
| Bootloader | U-Boot/TF-A para MT6768, o explotar ABL | Proyecto `mt6768-mainline` trabaja en U-Boot/TF-A, pero no publica soporte `selene`. [B5] |
| Kernel | Mainline o downstream con DTS de `selene` | No hay DTS mainline de `selene`; el downstream 4.14 existe en árboles Android. [B4] |
| GPU | Panfrost para Mali-G52 MC2 o blobs | GPU mainline "Works" en MT6768, pero sin integración Batocera. [B6] |
| Pantalla | Driver del panel + backlight | Mainline MT6768: *Partial*. [B6] |
| Táctil | Driver del controlador | No documentado para `selene`. |
| Audio | Códec/PMIC | Mainline MT6768: *Broken*. [B6] |
| Wi-Fi/BT | CONNAC MediaTek | Mainline MT6768: *Broken*. [B6] |
| Almacenamiento | eMMC + A/B + dynamic partitions | Requiere reparticionado o arranque desde microSD. |
| Energía | Suspensión | Mainline MT6768: *Broken*. [B6] |

**Estimación cualitativa:** es un port de plataforma completo (meses-persona de trabajo especializado), con resultado incierto y sin garantía de que el hardware de `selene` esté soportado. No es un "port de distro"; es construir el soporte de Linux para un teléfono.

---

## 4. Imágenes instalables

- **Ninguna imagen oficial corresponde a `selene`.**
- No se localizó ninguna imagen comunitaria de Batocera para `selene` o `21061119AL`.
- **No descargar ni flashear** una imagen de otro dispositivo: el resultado esperado es un ladrillo o un bootloop, y la recuperación en MediaTek requiere BROM/SP Flash Tool. [B4]

---

## 5. Actividad del proyecto

Batocera está muy activo: versión 44, lista de dispositivos ampliada, soporte de nuevas consolas Qualcomm/Rockchip. [B1] La actividad no ayuda a `selene`: la estrategia del proyecto es añadir dispositivos concretos con bootloader abierto o consolas soportadas por el fabricante, no teléfonos genéricos.

---

## 6. Riesgos específicos si se intentara

1. **Ladrillo duro** por flasheo de bootloader/kernel incompatible (recuperación vía BROM, no trivial).
2. **Pérdida de datos** y de la partición `persist`/IMEI si se reparticiona mal.
3. **Sin retorno** si se borra la copia de seguridad del bootloader original.
4. **Expectativa falsa de rendimiento**: aunque arrancara, la falta de suspensión y de audio haría la consola inutilizable.

---

## 7. Conclusión

Batocera **no es una opción** para `selene` en ninguna fase razonable del proyecto. La funcionalidad equivalente (EmulationStation + RetroArch) puede obtenerse en Android con apps libres, sin tocar el bootloader. Ver `research/AOSP.md` y `reports/FEASIBILITY_REPORT.md`.

---

## 8. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| B1 | https://batocera.org/download | 224 dispositivos; ninguno Xiaomi/MediaTek; versión 44 | 2026-11-24 |
| B2 | https://wiki.batocera.org/hardware:ayn | Instalación en consola Android mediante backup/flash del bootloader | 2026-11-24 |
| B3 | https://github.com/batocera-linux/batocera.linux | Repositorio y changelog del proyecto | 2026-11-24 |
| B4 | https://github.com/xiaomi-selene/android_device_xiaomi_selene/blob/lineage-23.2/BoardConfig.mk | AVB activo, A/B, `super`, kernel específico | 2026-11-24 |
| B5 | https://github.com/mt6768-mainline | U-Boot/TF-A/Linux para MT6768; sin port `selene` | 2026-11-24 |
| B6 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado mainline: display parcial; audio/WiFi/BT/suspensión rotos | 2026-11-24 |

# RetroPie — soporte para Xiaomi Redmi 10 (`selene`)

**Veredicto: NO COMPATIBLE (NC)**
**Fecha:** 2026-11-24

---

## 1. Qué es

RetroPie es un conjunto de scripts (`RetroPie-Setup`) que instala y configura RetroArch, EmulationStation y emuladores sobre una distribución Linux existente. **No es una imagen de sistema operativo**, salvo las imágenes prehechas para Raspberry Pi. [R1]

Plataformas objetivo según su propio README:

- **Raspberry Pi** con Raspberry Pi OS (antes Raspbian).
- **Vero4K** con OSMC.
- **ODROID-C1** con Ubuntu.
- **PC** con Ubuntu.

---

## 2. Soporte para `selene`

### 2.1 Ausencia total de soporte

- `selene` no es Raspberry Pi, Vero4K ni ODROID-C1.
- No hay scripts ni binarios para Android ni para MediaTek MT6768.
- RetroPie asume una distribución **Debian/Ubuntu-like** con `apt`, systemd y un escritorio/X11 o KMS. Android no cumple ese modelo.
- Aunque se instalara postmarketOS (basado en **Alpine**, no Debian), RetroPie no está soportado en Alpine y requeriría compilar todo desde fuente sin garantías. [R1]

### 2.2 Por qué no vale la pena

RetroPie es esencialmente una capa de instalación de **RetroArch + EmulationStation** sobre Linux. En `selene`:

- El único Linux posible es postmarketOS downstream, con audio/WiFi/BT/suspensión sin resolver.
- EmulationStation necesita una salida gráfica funcional (KMS/GL) y entrada; el estado mainline de MT6768 es *display partial* y sin garantía de táctil.
- El esfuerzo de hacer funcionar RetroPie sería en realidad el esfuerzo de hacer funcionar Linux en el teléfono, no de instalar RetroPie.

---

## 3. Requisitos técnicos (comparativa)

| Requisito RetroPie | `selene` |
|---|---|
| Raspberry Pi OS / OSMC / Ubuntu | No disponible para el dispositivo |
| `apt` + systemd | Solo existiría en un rootfs Linux portado |
| Salida gráfica KMS/GL | Mainline MT6768: display parcial [R5] |
| Audio ALSA | Mainline: roto [R5] |
| Red para descargar paquetes | WiFi/BT mainline rotos; USB RNDIS únicamente [R5] |
| Almacenamiento persistente | A/B + `super`; requiere reparticionar o microSD |
| Bootloader | Bloqueado + AVB [R4] |

---

## 4. Imágenes instalables

- **Ninguna** para `selene`.
- Las imágenes de Raspberry Pi **no arrancan** en ARM64 MediaTek (bootloader y DTB distintos).
- No existe una "RetroPie APK".

---

## 5. Actividad

RetroPie sigue manteniendo su script y sus imágenes de Raspberry Pi, con soporte ocasional de nuevas placas. [R1] Su ámbito no incluye teléfonos ni MediaTek.

---

## 6. Conclusión

RetroPie no es viable en `selene`. Igual que con Lakka, su valor real es el stack RetroArch + EmulationStation, que en Android se cubre con RetroArch o Lemuroid. Si en el futuro se compra una Raspberry Pi, RetroPie sería una opción excelente; para este teléfono, no.

---

## 7. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| R1 | https://github.com/RetroPie/RetroPie-Setup | Plataformas soportadas: RPi, Vero4K, ODROID-C1, PC Ubuntu | 2026-11-24 |
| R2 | https://retropie.org.uk/docs/ | Documentación oficial | 2026-11-24 |
| R3 | https://github.com/xiaomi-selene/android_device_xiaomi_selene | Árbol Android de `selene` (no Linux distro) | 2026-11-24 |
| R4 | https://github.com/xiaomi-selene/android_device_xiaomi_selene/blob/lineage-23.2/BoardConfig.mk | AVB, A/B, `super` | 2026-11-24 |
| R5 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Display parcial; audio/WiFi/BT/suspensión rotos | 2026-11-24 |

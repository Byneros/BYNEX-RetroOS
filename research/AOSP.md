# Android AOSP y launcher retro propio — evaluación para `selene`

**Veredicto:**
- **AOSP/GSI como sistema:** **TEÓRICO/EXPERIMENTAL (TE-EX)** — arranque no garantizado, sin evidencia verificada.
- **AOSP + launcher retro propio como producto:** **vía recomendada**, con la salvedad de que la base práctica es LineageOS comunitaria o MIUI, no un AOSP puro.
**Fecha:** 2026-11-24

---

## 1. Tres formas de "AOSP" en este dispositivo

| Vía | Qué es | Esfuerzo | Estado |
|---|---|---|---|
| **GSI** | Imagen genérica de sistema AOSP/Treble sobre el vendor/firmware existente | Bajo (flasheo) | No verificado; hay reportes de bootloop |
| **Build desde fuente** | Compilar AOSP/Lineage con árbol de dispositivo y blobs | Alto | Árbol comunitario existe; build no verificada |
| **Capa de apps sobre la ROM actual** | Mantener MIUI/Lineage e instalar frontend + emuladores libres | Muy bajo | **Funciona hoy, reversible** |

---

## 2. GSI (Generic System Image)

### 2.1 Requisito: Project Treble

El dispositivo es **arm64 A/B** y está listado como compatible con Treble en la tabla de /e/OS. [A1] Eso implica:

- Soporte de GSIs `arm64_bvN` (A/B, con o sin VNDK lite).
- Separación `system`/`vendor` con interfaz VNDK.

### 2.2 Evidencia real de arranque

- Un usuario reporta que GSIs Android 13 (`system-td-arm64-ab-vanilla` y `...-vndklite-vanilla`) **se quedan en el logo de arranque** en un Redmi 10 2022, incluso tras degradar a MIUI 12.5 (Android 11). [A2]
- El mismo hilo documenta la recuperación del teléfono mediante **SP Flash Tool en modo BROM**, lo que confirma el riesgo de ladrillo. [A2]
- No se encontró ningún reporte verificable de una GSI que arranque y funcione por completo en `21061119AL`.

### 2.3 Por qué puede fallar

- `vbmeta`/AVB y verificación de arranque.
- Diferencias de firmware vendor entre MIUI 12.5, 13 y 14.
- Dependencia de blobs MediaTek y de la versión de VNDK.
- Posible necesidad de `dm-verity`/`forceencrypt` desactivados.

**Conclusión:** GSI es un experimento barato en tiempo pero caro en riesgo. No debe ser la base del proyecto sin una unidad de repuesto y un plan de recuperación probado.

---

## 3. Build desde fuente

### 3.1 Lo que existe

- Árbol de dispositivo `lineage-23.2` con `BoardConfig.mk`, `device.mk`, `proprietary-files.txt` y `extract-files.py`. [A3]
- Kernel downstream 4.14 y módulos precompilados extraídos de MIUI. [A4]
- Trees de recovery comunitarios (TWRP/PBRP). [A5]

### 3.2 Lo que falta o es frágil

| Requisito | Estado |
|---|---|
| Fuentes de kernel Android 12/13 | **No publicadas por Xiaomi**; issue abierta [A6] |
| Vendor blobs reproducibles | Extraídos de una ROM concreta; dependen de la versión |
| Firma de builds | Test keys; no hay claves oficiales |
| Parches de seguridad | 2023-09-01 en el árbol [A3] |
| SELinux | `permissive` [A3] |
| Integración de cámara/VoLTE | No verificada |
| CI/releases | No hay canal oficial |

### 3.3 Coste

Compilar Android requiere: repositorio de ~100–200 GB, 16–32 GB de RAM, horas de CPU, y idealmente una segunda unidad para pruebas. Es viable técnicamente, pero **no es un sprint de fin de semana** y no garantiza un resultado mejor que una build comunitaria ya existente.

---

## 4. La alternativa recomendada: capa de apps + launcher propio

### 4.1 Idea

No reemplazar Android por Linux, sino **convertir Android en una consola**:

- Un **launcher propio** (app Android) que sea la pantalla de inicio.
- Emuladores/frontends **libres y gratuitos**: RetroArch (GPLv3) y/o Lemuroid (open source, basado en Libretro). [A7], [A8]
- Sin Google Play Services, sin cuentas, sin compras. Distribución por F-Droid/GitHub Releases (verificar disponibilidad de cada app).
- Kiosco opcional mediante `device owner`/`LOCK_TASK` (requiere aprovisionamiento por ADB; no root).

### 4.2 Por qué encaja con los requisitos

| Requisito | Cumplimiento |
|---|---|
| Software libre | RetroArch GPLv3; Lemuroid open source; launcher propio |
| Sin servicios de pago | Todo se instala desde F-Droid/GitHub; sin APIs de pago |
| Sin modificar el teléfono (Fase 1) | Apps normales, instalación reversible |
| Experiencia consola | Launcher a pantalla completa + arranque directo |
| Mantenibilidad | Apps con comunidad activa; launcher pequeño y propio |

**Nota sobre frontends:** Daijishō es gratuito pero **closed-source**, por lo que no cumple el criterio "completamente libre" si se aplica de forma estricta. [A9] Se puede usar como referencia de UX, no como dependencia del producto.

### 4.3 Diseño mínimo del launcher (Fase 3)

- **Home alternativo:** activity con `CATEGORY_HOME` + `DEFAULT`, sin overscroll ni barras.
- **Biblioteca:** escaneo de ROMs en almacenamiento (SAF o ruta configurable), carátulas opcionales.
- **Lanzamiento:** `Intent` explícito a RetroArch (`com.retroarch/.browser.retroactivity.RetroActivityFuture` con extras `ROM` y `LIBRETRO`) o a Lemuroid; fallback a selector.
- **Ajustes:** sistema, core, mapeo de mando, tema.
- **Sin red obligatoria:** scraping opcional y desactivable.
- **Licencia:** GPLv3 o Apache-2.0, repositorio propio.
- **Kiosco (opcional):** `DevicePolicyManager` como device owner, o `startLockTask()` tras conceder el permiso por ADB. Reversible.

### 4.4 Qué se gana y qué no

| Se gana | No se gana |
|---|---|
| Cero riesgo de ladrillo en Fase 1 | Arranque inmediato sin Android de fondo |
| Rendimiento nativo Android (drivers del fabricante) | Control total del sistema |
| Audio, WiFi, BT, batería funcionando | Actualizaciones de seguridad |
| Instalación/desinstalación trivial | Estética 100% consola sin trabajo de UI |

---

## 5. Rendimiento: qué esperar y cómo medirlo

No hay benchmarks en este sprint y **no se afirmará ninguna cifra**. Protocolo propuesto para el Sprint 1:

1. Instalar RetroArch/Lemuroid manualmente (acción del usuario, fuera de este sprint).
2. Para cada core (NES, SNES, GBA, PS1, N64, PSP):
   - 30 minutos de juego con estadísticas de RetroArch (FPS, frametime, dropped frames).
   - Registrar temperatura y `dumpsys battery` antes/después.
   - Repetir con y sin sombreadores.
3. Criterio de aceptación: 60 FPS estables en 8/16 bits y PS1; N64/PSP "jugable" con frameskip documentado.
4. Guardar resultados en `diagnostics/` y anexarlos a `reports/FEASIBILITY_REPORT.md`.

Solo con esos datos se podrá decidir si la Fase 2 (LineageOS) aporta valor real.

---

## 6. Riesgos de la vía Android

- **Builds no oficiales** sin garantía de integridad ni de actualizaciones.
- **Pérdida de funciones** al pasar de MIUI a Lineage: cámara, VoLTE, huella, DRM (Widevine L1), NFC.
- **Seguridad:** parches antiguos y SELinux permisivo.
- **Dependencia de un maintainer** individual.
- **Bootloader desbloqueado**: implica pérdida de garantía y de la verificación de integridad; algunos bancos/apps dejan de funcionar.

---

## 7. Conclusión

- **AOSP puro/GSI:** no recomendado como base; riesgo alto y evidencia de fallo.
- **AOSP + launcher propio:** conceptualmente correcto, pero la implementación práctica debe apoyarse en **LineageOS comunitaria (Fase 2)** o en **MIUI (Fase 1)**, no en un AOSP recompilado desde cero.
- **Launcher propio + RetroArch/Lemuroid:** es la pieza de software que sí podemos construir con garantías, es libre, gratuita y reversible.

---

## 8. Fuentes

| ID | Fuente | Evidencia | Acceso |
|---|---|---|---|
| A1 | https://community.e.foundation/t/device-support-project-treble/19645 | `selene` arm64 A/B (Treble) | 2026-11-24 |
| A2 | https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 | GSI Android 13 no arranca; recuperación BROM/SP Flash | 2026-11-24 |
| A3 | https://github.com/xiaomi-selene/android_device_xiaomi_selene | Árbol, `BoardConfig.mk`, kernel, SELinux, parches | 2026-11-24 |
| A4 | https://codeberg.org/xiaomi-mt6768-dev/android_device_xiaomi_selene-kernel | Módulos/kernel precompilados | 2026-11-24 |
| A5 | https://github.com/hasan6034/recovery_device_xiaomi_selene | Árbol TWRP | 2026-11-24 |
| A6 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/39094 | Fuentes Android 12/13 no publicadas | 2026-11-24 |
| A7 | https://github.com/Swordfish90/Lemuroid | Emulador Android open source basado en Libretro | 2026-11-24 |
| A8 | https://www.retroarch.com/ | RetroArch oficial (GPLv3) | 2026-11-24 |
| A9 | https://github.com/TapiocaFox/Daijishou | Frontend gratuito pero closed-source | 2026-11-24 |

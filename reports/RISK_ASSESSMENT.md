# Evaluación de riesgos — BYNEX Retro OS sobre `selene`

**Sprint 0 · 2026-11-24**
**Alcance:** riesgos técnicos, de seguridad, de continuidad y legales del proyecto.
**Escala:** probabilidad (P) e impacto (I) de 1 a 5; exposición = P × I.

---

## 1. Principios de gestión

1. **Nada irreversible sin backup probado.** Antes de cualquier escritura: firmware oficial, backup de particiones críticas y procedimiento de recuperación verificado.
2. **Separar fases.** La Fase 1 (apps) no toca el sistema; la Fase 2 (unlock/flash) solo se autoriza con los criterios de aceptación cumplidos.
3. **Una variable por vez.** No cambiar ROM, kernel y launcher a la vez.
4. **Evidencia antes que entusiasmo.** Ninguna build se instala sin hash, fuente y lista de funciones reportadas.
5. **Presupuesto de fallo.** Asumir que el teléfono puede quedar inutilizable y que la recuperación puede requerir servicio técnico.

---

## 2. Registro de riesgos

| ID | Riesgo | P | I | Exp. | Mitigación | Disparador / señal |
|---|---|---|---|---|---|---|
| R01 | **Ladrillo durante unlock/flash** (bootloader, vbmeta, slot incorrecto) | 4 | 5 | **20** | No flashear en Sprint 0; validar build; seguir guía específica de `selene`; tener firmware fastboot y BROM listos | El teléfono no pasa de logo o no entra en fastboot/recovery |
| R02 | **Pérdida de datos del usuario** | 5 | 4 | **20** | Backup completo off-device antes de unlock; no guardar nada importante en el teléfono | Unlock borra userdata por diseño |
| R03 | **Pérdida de garantía y de integridad verificada** | 5 | 3 | **15** | Aceptación explícita; documentar estado; conservar factura | Unlock oficial irreversible sin servicio técnico |
| R04 | **Build de terceros maliciosa o corrupta** | 3 | 5 | **15** | Solo fuentes con historial; verificar SHA-256 y firma; compilar localmente si es posible; escanear | Hash ausente, enlaces acortados, builds "premium" |
| R05 | **Kernel 4.14 sin parches de seguridad** | 5 | 4 | **20** | Uso offline; sin cuentas; firewall; aceptar riesgo | Fecha de parche 2023-09-01 en el árbol |
| R06 | **SELinux permisivo** en builds comunitarias | 4 | 4 | **16** | No instalar apps de terceros; no usar banca; valorar build con SELinux enforcing | `getenforce` = Permissive |
| R07 | **Pérdida de IMEI/baseband** (`persist`, `nvram`, `nvdata`) | 2 | 5 | **10** | Backup de particiones antes de tocar; no borrar `persist`; no usar "format all" | Sin señal, IMEI desconocido |
| R08 | **Anti-rollback (ARB)** impide volver a MIUI anterior | 2 | 5 | **10** | No degradar firmware sin verificar ARB; usar la misma versión o superior | Error de firma/ARB al flashear firmware antiguo |
| R09 | **Sin recovery compatible fiable** | 3 | 4 | **12** | Usar TWRP/PBRP comunitario solo tras verificar modelo; preferir fastboot/recovery-as-boot de la build | Recovery no monta `/system_root` o no arranca |
| R10 | **Periféricos rotos** (cámara, VoLTE, huella, NFC) | 4 | 3 | **12** | Aceptar como no esenciales para retro; probar antes de declarar "listo" | Función ausente en la build |
| R11 | **Rendimiento insuficiente** (N64/PSP/Dreamcast) | 3 | 3 | **9** | Medir antes de Fase 2; limitar catálogo a lo que funcione a 60 FPS | Framedrops > 5% o frametime p95 > 20 ms |
| R12 | **Suspensión/consumo** en Linux | 5 | 4 | **20** | Descartar Linux hasta que mainline lo resuelva | Batería cae en standby |
| R13 | **Abandono del maintainer** de la build | 4 | 3 | **12** | Conservar el árbol y las fuentes; documentar build reproducible; no depender de un único enlace | Sin commits/releases > 12 meses |
| R14 | **Cambios de política de desbloqueo Xiaomi** (cuenta, región, espera) | 3 | 4 | **12** | Verificar requisitos antes de planificar; no crear cuentas nuevas sin necesidad | Mi Unlock rechaza la solicitud |
| R15 | **Pérdida de DRM (Widevine L1)** y apps que exigen integridad | 4 | 3 | **12** | Aceptar; la consola no necesita streaming | Apps de banca/streaming dejan de funcionar |
| R16 | **Confusión de variante** (`selene` vs `selenes`, 2021 vs 2022) | 3 | 4 | **12** | Verificar modelo y codename con el script; no usar imágenes de otro codename | `ro.product.device` distinto |
| R17 | **Capacidad insuficiente** para ROMs (64 GB) | 3 | 2 | **6** | microSD; catálogo curado; compresión | Poco espacio libre |
| R18 | **Licencias de ROMs/BIOS** | 2 | 4 | **8** | Solo juegos/BIOS legales; documentar procedencia; no distribuir | Contenido sin licencia |
| R19 | **Dependencia de servicios de pago** | 2 | 3 | **6** | Prohibir compras/API de pago; usar F-Droid/GitHub; revisar dependencias | Cualquier app que pida suscripción |
| R20 | **Sobrecalentamiento** en sesiones largas | 3 | 3 | **9** | Funda ventilada; límite de sesión; monitorizar temperatura | Throttling térmico, batería > 42 °C |
| R21 | **Pérdida de la copia del bootloader original** | 2 | 5 | **10** | Guardar backup en dos medios; verificar restauración | Backup ausente o corrupto |

---

## 3. Riesgos por fase

### Fase 1 — MIUI + apps (sin unlock)

| Riesgo | Nivel | Nota |
|---|---|---|
| Apps maliciosas | Medio | Instalar solo de F-Droid/GitHub; verificar permisos |
| Compras accidentales | Bajo | No usar Play Store ni suscripciones |
| Rendimiento | Medio | Medir antes de decidir Fase 2 |
| Datos | Bajo | Sin cambios de sistema |

**Riesgo global: BAJO.** Es la fase recomendada para empezar.

### Fase 2 — Unlock + LineageOS

| Riesgo | Nivel | Nota |
|---|---|---|
| Ladrillo | Alto | R01, R07, R08 |
| Pérdida de datos | Alto | R02 |
| Seguridad | Alto | R05, R06 |
| Continuidad | Medio | R13 |
| Garantía | Alto | R03 |

**Riesgo global: MEDIO-ALTO.** Solo con criterios de aceptación cumplidos y recuperación probada.

### Fase 3 — Linux nativo / port retro

| Riesgo | Nivel | Nota |
|---|---|---|
| Insuficiencia de hardware | Muy alto | Audio/WiFi/BT/suspensión rotos |
| Esfuerzo | Muy alto | Port de plataforma |
| Retorno | Muy bajo | No compite con Android |

**Riesgo global: MUY ALTO / no recomendado.**

---

## 4. Plan de recuperación (resumen operativo)

> Estos pasos **no se ejecutan en Sprint 0**. Se documentan para que la Fase 2 tenga un plan.

1. **Antes de tocar nada**
   - Descargar el firmware fastboot oficial de `selene` (versión actual o superior) desde el archivo de MIUI. [X1]
   - Verificar hash y guardarlo en dos medios.
   - Instalar ADB/fastboot y drivers MediaTek/Google USB.
   - Documentar el estado: `ro.boot.verifiedbootstate`, `ro.boot.flash.locked`, slot.
2. **Backup**
   - Copia de datos del usuario (fotos, documentos) fuera del teléfono.
   - Si hay acceso root temporal o recovery: backup de `persist`, `nvram`, `nvdata`, `boot`, `dtbo`.
   - Guardar el `boot.img` original y el `vbmeta` original.
3. **Recuperación si falla el arranque**
   - Probar `fastboot devices` y `fastboot getvar all` (solo lectura).
   - Si hay fastboot: restaurar `boot`/`vbmeta` originales o flashear firmware oficial completo.
   - Si no hay fastboot: modo BROM + SP Flash Tool con el scatter/firmware oficial. [X2]
   - Si nada funciona: servicio técnico (pérdida de garantía si está desbloqueado).
4. **Criterio de parada**
   - Si no se puede recuperar en 2 intentos documentados, detener y derivar a servicio técnico.

---

## 5. Pre-mortem ("¿por qué falló el proyecto?")

Escenarios plausibles dentro de 6 meses:

1. La build comunitaria dejó de actualizarse y quedó insegura.
2. El rendimiento en PS1/N64 no cumplió y la consola no aportó valor.
3. Un flasheo fallido dejó el teléfono en bootloop y la recuperación BROM no funcionó.
4. La falta de audio/suspensión hizo inútil el port Linux.
5. Se perdió el IMEI y el teléfono quedó sin señal.
6. El launcher propio quedó a medio hacer y la experiencia fue peor que MIUI.

**Contramedidas:** validar rendimiento antes de Fase 2, congelar una build reproducible, probar recuperación en un dispositivo de repuesto, y limitar el alcance del launcher a lo imprescindible.

---

## 6. Riesgos legales y éticos

- **ROMs y BIOS:** usar solo copias de juegos que el usuario posea; no distribuir BIOS ni ROMs.
- **Licencias de emuladores:** RetroArch es GPLv3; Lemuroid es open source; EmuELEC tiene restricciones no comerciales. No empaquetar software con licencias incompatibles en un producto.
- **Garantía y contrato del operador:** el desbloqueo puede anular garantía; no afecta al derecho a reparar, pero sí a las condiciones del fabricante.
- **Privacidad:** evitar cuentas, telemetría y scraping con datos personales.

---

## 7. Criterios de "stop" (no-go)

Detener el proyecto o la fase si ocurre cualquiera:

- No se puede confirmar el modelo exacto (`21061119AL`) o el codename.
- No hay build con hash y maintainer identificable.
- No se dispone de firmware oficial y procedimiento de recuperación probado.
- El benchmark no alcanza 60 FPS estables en PS1.
- Aparece pérdida de IMEI, señal o arranque tras una prueba.
- El usuario no acepta por escrito la pérdida de garantía/DRM.

---

## 8. Fuentes

| ID | Fuente | Uso | Acceso |
|---|---|---|---|
| X1 | http://xmfirmwareupdater.com/archive/miui/selene | Firmware oficial archivado para recuperación | 2026-11-24 |
| X2 | https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 | Recuperación vía BROM/SP Flash Tool; caso real de bootloop | 2026-11-24 |
| X3 | https://github.com/xiaomi-selene/android_device_xiaomi_selene/blob/lineage-23.2/BoardConfig.mk | AVB, A/B, SELinux permisivo, parches 2023 | 2026-11-24 |
| X4 | https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/39094 | Ausencia de fuentes de kernel Android 12/13 | 2026-11-24 |
| X5 | https://wiki.postmarketos.org/wiki/Mediatek_MT6768 | Estado de suspensión/audio/WiFi en mainline | 2026-11-24 |
| X6 | https://github.com/hasan6034/recovery_device_xiaomi_selene | Recovery comunitario (no oficial) | 2026-11-24 |

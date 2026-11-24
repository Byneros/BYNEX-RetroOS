# Plan de recuperación — `selene` (21061119AL)

**Sprint 0 · versión 1.0 · 2026-11-24**
**Estado:** procedimiento **documentado y NO ejecutado**. Ningún paso de escritura de este plan se realiza en Sprint 0.

**Propósito:** disponer de un runbook verificable para volver a un estado funcional si la Fase 2 (desbloqueo/instalación de LineageOS) o cualquier experimento posterior deja el teléfono sin arranque, sin recovery o sin señal.

> Este plan amplía `reports/RISK_ASSESSMENT.md` §4. No sustituye a la guía oficial de Xiaomi ni a la documentación de las herramientas: en caso de discrepancia, prevalece la fuente oficial del firmware.

---

## 1. Principios

1. **Nada irreversible sin backup probado.** Un backup que no se ha restaurado nunca no es un backup.
2. **Firmware oficial primero.** La recuperación se apoya en el paquete fastboot oficial de `selene`, no en ROMs comunitarias.
3. **Una variable por vez.** No mezclar cambio de ROM, kernel, recovery y launcher.
4. **Registro de todo.** Cada intento se anota con hora, comando, resultado y hash de lo usado.
5. **Presupuesto de fallo.** Se asume que la recuperación puede requerir servicio técnico y que la garantía puede estar anulada tras el desbloqueo.

---

## 2. Inventario previo obligatorio

Antes de cualquier escritura deben existir y estar verificados:

| Elemento | Detalle | Verificación |
|---|---|---|
| Firmware fastboot oficial | Versión actual del teléfono **o superior**; nunca inferior sin comprobar ARB | SHA-256 anotado; archivo en dos medios |
| Firmware recovery oficial | Misma versión que el fastboot | SHA-256 |
| `platform-tools` (adb/fastboot) | Versión anotada | `adb version`, `fastboot --version` |
| Drivers MediaTek USB / VCOM | Instalados y probados | El dispositivo aparece en el administrador |
| SP Flash Tool | Versión anotada; usar solo con firmware oficial y modo "Download Only" | Hash de la herramienta |
| Backup de particiones críticas | `persist`, `nvram`, `nvdata`, `boot`, `dtbo`, `vbmeta` | Restauración probada en un dispositivo de repuesto o descartada explícitamente |
| Copia de datos de usuario | Fotos, documentos, partidas | Abrir archivos al azar desde la copia |
| Unidad de repuesto o presupuesto | Decisión del usuario | Aceptación escrita |

**Nunca** usar un firmware de `selenes` (Redmi 10 2022 / Note 11 4G) ni de otra variante. Verificar `ro.product.device` antes de descargar.

---

## 3. Línea base de solo lectura

Ejecutar con el teléfono arrancado y ADB autorizado:

```bash
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.incremental
adb shell getprop ro.miui.ui.version.name
adb shell getprop ro.boot.slot_suffix
adb shell getprop ro.boot.verifiedbootstate
adb shell getprop ro.boot.flash.locked
```

Con el teléfono en fastboot:

```bash
fastboot devices
fastboot getvar all
```

Guardar la salida en `diagnostics/` con fecha. Esta línea base es la referencia para detectar qué cambió tras un fallo.

**Advertencia:** `fastboot oem unlock`, `fastboot flashing unlock`, `fastboot flash`, `fastboot erase` y `fastboot format` son operaciones de escritura y **no** forman parte del Sprint 0.

---

## 4. Backups

### 4.1 Datos de usuario

- Copiar fuera del teléfono antes del desbloqueo: el desbloqueo borra `userdata` por diseño.
- Verificar la copia abriendo archivos y comparando tamaños.

### 4.2 Particiones críticas

Solo con root temporal o recovery comunitario verificado para `selene`:

```bash
# Ejemplo de lectura con dd desde un recovery con shell root.
# Los nombres de bloque varían; confirmar con: ls -l /dev/block/by-name/
dd if=/dev/block/by-name/persist of=/sdcard/persist.img
dd if=/dev/block/by-name/nvram  of=/sdcard/nvram.img
dd if=/dev/block/by-name/nvdata of=/sdcard/nvdata.img
dd if=/dev/block/by-name/boot    of=/sdcard/boot.img
dd if=/dev/block/by-name/dtbo    of=/sdcard/dtbo.img
dd if=/dev/block/by-name/vbmeta  of=/sdcard/vbmeta.img
```

- `persist`, `nvram` y `nvdata` contienen IMEI/calibración: **no borrar, no compartir, no publicar**.
- Calcular SHA-256 de cada imagen y guardarlas en dos medios distintos.
- Guardar también el `boot.img` y el `vbmeta.img` originales: son la vía rápida para revertir un arranque fallido.

### 4.3 Verificación del backup

| Prueba | Criterio |
|---|---|
| Hash coincide con el original | Sí |
| Copia legible en el segundo medio | Sí |
| Restauración de `boot`/`vbmeta` probada | Sí, o riesgo aceptado por escrito |
| Datos de usuario abiertos desde la copia | Sí |

---

## 5. Árbol de decisión

| Síntoma | Hipótesis habitual | Acción inicial |
|---|---|---|
| Se queda en logo, pero entra en fastboot | `boot`/`vbmeta` incorrectos o slot mal flasheado | Procedimiento A |
| Se queda en logo y **no** entra en fastboot/recovery | Arranque roto a bajo nivel | Procedimiento B (BROM) |
| Enciende pero sin señal / IMEI desconocido | `persist`/`nvram` dañados | Procedimiento D |
| Error de firma/ARB al flashear firmware | Anti-rollback | Procedimiento E |
| Recovery no monta `/system_root` | Recovery incompatible o slot | Procedimiento C |
| No enciende ni carga | Batería agotada o bloqueo | Procedimiento F |

---

## 6. Procedimientos

### A. Bootloop con fastboot disponible

1. Confirmar detección: `fastboot devices`.
2. Leer estado: `fastboot getvar current-slot`, `fastboot getvar unlocked`.
3. **Opción rápida:** restaurar `boot` y `vbmeta` originales del backup:
   ```bash
   fastboot flash boot  boot-original.img
   fastboot flash vbmeta vbmeta-original.img
   fastboot reboot
   ```
4. **Opción completa:** flashear el firmware fastboot oficial con su script (`flash_all`), sin editar el script y sin mezclar versiones.
5. Si el firmware es A/B, dejar que el script gestione los slots; no forzar `--slot` manualmente.
6. Tras arrancar, verificar identidad, IMEI, señal y cámara antes de continuar.

### B. Sin fastboot: modo BROM + SP Flash Tool

1. Descargar el firmware oficial y el scatter correspondiente a `selene`.
2. Instalar drivers MediaTek VCOM.
3. Cargar el scatter en SP Flash Tool y seleccionar **Download Only**.
4. Con el teléfono apagado, conectar por USB mientras se mantiene la combinación de teclas que indica la guía de `selene` para BROM.
5. Iniciar la descarga y **no desconectar** hasta que termine.
6. Si falla: revisar versión de SP Flash Tool, drivers, cable y batería; repetir como máximo una vez con registro.
7. Si el error persiste, **detener** y derivar a servicio técnico.

**Riesgo:** una descarga BROM interrumpida o con firmware incorrecto puede agravar el ladrillo. No usar "Format All + Download" salvo indicación expresa: borra `persist` y puede dejar el teléfono sin IMEI.

### C. Recovery no arranca o no monta particiones

1. Preferir el recovery incluido en la build (`recovery-as-boot`) o el TWRP comunitario verificado para `selene`. [X6]
2. Confirmar que el recovery corresponde a `selene` y a la versión de firmware.
3. Si no monta `/system_root`, no forzar formatos: volver al firmware oficial por fastboot.
4. No usar "wipe all" sin backup de `persist`/`nvdata`.

### D. Pérdida de IMEI o señal

1. No seguir flasheando: cada escritura adicional reduce las opciones.
2. Restaurar `persist`, `nvram` y `nvdata` desde el backup, si existe y está verificado.
3. Si no hay backup, la reparación de IMEI requiere herramientas y datos del fabricante; derivar a servicio técnico.
4. Documentar el estado (`*#06#`, `dumpsys telephony.registry`) sin publicar el IMEI.

### E. Anti-rollback (ARB)

1. Si el flasheo falla por firma o ARB, **no** insistir con firmware más antiguo.
2. Usar la misma versión o una superior a la instalada.
3. Si el teléfono queda en bootloop tras un intento de downgrade, aplicar el procedimiento A con la versión más reciente disponible.
4. Registrar la versión exacta y el error.

### F. No enciende ni carga

1. Cargar 30 minutos con cargador y cable conocidos.
2. Probar combinación de encendido forzado (mantener encendido 15–20 s).
3. Probar detección en PC: `adb devices`, `fastboot devices`, y observar si aparece un dispositivo VCOM/Preloader.
4. Si aparece Preloader, aplicar procedimiento B. Si no aparece nada, servicio técnico.

---

## 7. Verificación post-recuperación

| Comprobación | Comando / método | Criterio |
|---|---|---|
| Identidad | `getprop ro.product.model` / `ro.product.device` | `21061119AL` / `selene` |
| Build | `getprop ro.build.version.incremental` | La esperada |
| Bootloader | `getprop ro.boot.flash.locked` | Estado conocido y documentado |
| Slot | `getprop ro.boot.slot_suffix` | Coherente con lo flasheado |
| IMEI | `*#06#` o `dumpsys iphonesubinfo` | Presente (no publicar) |
| Señal | Llamada de prueba | Funciona |
| Batería | `dumpsys battery` | Carga y temperatura normales |
| Almacenamiento | `df -h /data` | Monta y con espacio |
| Cámara/audio/WiFi | Prueba manual | Funcionan o se documenta la pérdida |

Guardar el resultado en `diagnostics/recovery-<fecha>.md`.

---

## 8. Criterios de parada

Detener la recuperación y derivar a servicio técnico si:

- Dos intentos documentados consecutivos fallan con el mismo error.
- No hay detección por fastboot ni por BROM/Preloader.
- Se sospecha daño de `persist`/`nvdata` sin backup verificado.
- El firmware disponible es inferior al instalado y podría activar ARB.
- Hay sobrecalentamiento, olor o daño físico.

---

## 9. Registro de incidente

Plantilla para `diagnostics/recovery-<fecha>.md`:

```markdown
# Incidente de recuperación — <fecha>

- Modelo/codename:
- Build previa / slot:
- Qué se estaba haciendo:
- Último comando ejecutado:
- Síntoma exacto:
- ¿Entra en fastboot? ¿En recovery? ¿En BROM?
- Firmware usado (versión + SHA-256):
- Intentos (hora, comando, resultado):
- Estado final:
- Datos/funciones perdidos:
```

---

## 10. Referencias

| ID | Fuente | Uso |
|---|---|---|
| X1 | http://xmfirmwareupdater.com/archive/miui/selene | Firmware oficial archivado |
| X2 | https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 | Caso real de bootloop y recuperación BROM/SP Flash |
| X6 | https://github.com/hasan6034/recovery_device_xiaomi_selene | Recovery comunitario (no oficial) |
| — | `reports/RISK_ASSESSMENT.md` | Riesgos R01, R02, R07, R08, R09, R21 |
| — | `docs/HARDWARE_SPECIFICATIONS.md` §9 | Particiones A/B, AVB y offsets de boot |

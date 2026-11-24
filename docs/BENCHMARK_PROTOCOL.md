# Protocolo de benchmark — emulación en `selene` (21061119AL)

**Sprint 1 · versión 1.0 · 2026-11-24**
**Objetivo:** obtener datos reproducibles de FPS, frametime, estabilidad térmica y autonomía para decidir si la Fase 2 (LineageOS) aporta valor real y qué catálogo de sistemas es honesto ofrecer.
**Principio:** este documento define *cómo medir*; no contiene resultados. Ninguna cifra se publicará sin la hoja de ejecución adjunta.

---

## 1. Alcance

### 1.1 Qué se mide

| Dimensión | Métrica principal | Uso |
|---|---|---|
| Rendimiento | FPS promedio, frametime p50/p95/p99, % frames perdidos | Decidir qué sistemas son "jugables" |
| Estabilidad | Cuelgues, reinicios, audio roto, cierres de app | Criterio de estabilidad (7 días) |
| Térmica | Temperatura de batería y CPU, aparición de throttling | Descartar sesiones largas inviables |
| Autonomía | % de batería por hora de juego | Uso como consola portátil |
| Entrada | Latencia percibida, mapeo de mando | Usabilidad mínima |
| Ergonomía | Postura, peso, alcance de botones | Cualitativo, una vez por mando |

### 1.2 Qué no se mide

- Rendimiento de Android/MIUI en general (solo el contexto del emulador).
- Benchmarks sintéticos (AnTuTu, Geekbench): no predicen emulación y añaden ruido.
- Sistemas Linux: no hay imagen utilizable (ver `research/POSTMARKETOS.md`).
- Cámaras, sensores o apps ajenas al proyecto.

### 1.3 Regla de evidencia

Cada fila de resultados debe poder rastrearse a: dispositivo + build + core + juego/escena + configuración + fecha. Sin esa cadena, el dato se marca **no válido** y se repite.

---

## 2. Prerrequisitos

### 2.1 Dispositivo

| Requisito | Comprobación |
|---|---|
| Modelo/codename confirmados (`21061119AL`, `selene`) | `scripts/diagnose-device.ps1` → `diagnostics/device-report.md` |
| Batería entre 50 % y 90 % al iniciar cada bloque | `dumpsys battery` |
| Almacenamiento libre ≥ 10 GB | `df -h /data` |
| Sin funda, sobre superficie rígida y ventilada | Inspección |
| Temperatura inicial ≤ 32 °C | `dumpsys battery` → `temperature` |
| Modo avión activo, sin cuentas, sin sincronización | Ajustes |

### 2.2 Software

| Elemento | Requisito |
|---|---|
| RetroArch | Versión estable de F-Droid/GitHub, anotar `versión + ABI + fecha` |
| Lemuroid | Solo como control cruzado; no mezclar resultados con RetroArch |
| Cores | Versión exacta anotada por core; no actualizar a mitad de la matriz |
| Mando | Bluetooth o USB-OTG, mismo mando en todas las sesiones |
| Grabación | Captura de pantalla del overlay de estadísticas en cada muestreo |

### 2.3 Contenido

- El usuario aporta sus propios volcados legales de juegos y BIOS. El repositorio no distribuye ROMs ni BIOS.
- Fijar **una** ROM por sistema y una **escena de arranque reproducible** (misma pantalla, mismo modo de juego, mismo personaje).
- Guardar `sha256` de cada ROM y BIOS usada, junto con la región y la versión.

---

## 3. Configuración de referencia

Se medirá siempre con esta base y se anotarán las desviaciones:

| Ajuste | Valor | Motivo |
|---|---|---|
| Brillo | 50 % fijo, sin brillo automático | Consumo y térmica comparables |
| Refresco de pantalla | Anotar el modo activo (60/90 Hz); no forzarlo | Evitar conclusiones falsas por VSync |
| VSync | Activado | Es el modo de uso real |
| Escalado | Resolución nativa del panel o `1x` del core; anotar | La resolución interna cambia todo |
| Filtros/sombreadores | Desactivados en la corrida base | Aislar coste del shader |
| Frameskip | Desactivado en la corrida base | Un frameskip oculta el problema |
| Audio | Activado, volumen 50 % | El audio también consume CPU |
| Rewind/savestates | Desactivados | Evitar sobrecoste |
| Fast-forward | Desactivado | Idem |
| Red | Modo avión | Sin scraping ni descargas |
| Registro | Overlay de estadísticas de RetroArch activado | Fuente primaria de FPS/frametime |

---

## 4. Matriz de pruebas

Cada sistema se ejecuta con **un core primario**. El core alternativo solo se prueba si el primario no alcanza el criterio y existe una alternativa razonable.

| Sistema | Core primario | Alternativa | Escena tipo | Criterio |
|---|---|---|---|---|
| NES | Mesen | FCEUmm | Scroll horizontal continuo + efectos de sonido | 60 FPS |
| SNES | Snes9x | bsnes (solo referencia) | Nivel con Mode 7 y transparencias | 60 FPS |
| Game Boy / Color | Gambatte | SameBoy | Cambio de mapa con scroll | 60 FPS |
| GBA | mGBA | VBA-M | Nivel con sprites y audio | 60 FPS |
| Mega Drive / Genesis | Genesis Plus GX | — | Nivel con scroll rápido y sonido FM | 60 FPS |
| PlayStation 1 | Beetle PSX | PCSX-ReARMed | Escena 3D con texturas y audio | 60 FPS (p95 < 20 ms) |
| Nintendo 64 | Mupen64Plus-Next | — | Nivel 3D amplio | "Jugable" documentado |
| PSP | PPSSPP | — | Nivel 3D con carga de texturas | "Jugable" documentado |
| Dreamcast (opcional) | Flycast | — | Escena 3D | "Jugable" documentado |

**Definición de "jugable":** ≥ 30 FPS promedio, p95 < 33 ms, sin caídas por debajo de 25 FPS en la escena, y sin artefactos graves. Si no se cumple, se documenta como **no jugable** sin matices.

---

## 5. Corridas por sistema

Para cada sistema se ejecutan hasta tres corridas, en este orden:

| Corrida | Configuración | Se ejecuta si |
|---|---|---|
| **R1 — Base** | Configuración de referencia | Siempre |
| **R2 — Shader CRT** | R1 + shader CRT ligero | R1 cumple el criterio |
| **R3 — Ajuste de rendimiento** | R1 + frameskip 1 o resolución interna reducida | R1 **no** cumple |

- Cada corrida dura **30 minutos** de juego efectivo.
- Los primeros **5 minutos son calentamiento** y se descartan.
- Entre corridas: 10 minutos de reposo hasta ≤ 32 °C.
- No se encadenan dos corridas del mismo sistema sin reposo.
- Máximo **2 horas de medición por día** para no contaminar la térmica.

---

## 6. Procedimiento por corrida

1. **Preflight (2 min):** modo avión, brillo 50 %, cerrar apps, comprobar batería/temperatura, anotar en la hoja.
2. **Arranque:** iniciar RetroArch, cargar core y ROM, verificar que el overlay muestra FPS/frametime.
3. **Calentamiento (5 min):** jugar la escena fija; no registrar.
4. **Medición (30 min):** jugar sin salir de la escena.
   - Cada **5 minutos** (t = 5, 10, 15, 20, 25, 30) registrar:
     - FPS instantáneo y frametime del overlay (foto o captura).
     - `dumpsys battery` (nivel, temperatura).
     - Sensación térmica de la carcasa (frío/templado/caliente) y si hay throttling visible.
   - Anotar cualquier evento: caída puntual, audio roto, cuelgue, mando desconectado.
5. **Cierre:** salir del juego, `dumpsys battery` final, guardar capturas, rellenar la hoja.
6. **Reposo:** 10 min o hasta ≤ 32 °C antes de la siguiente corrida.

### 6.1 Comandos de captura (solo lectura)

```bash
adb shell dumpsys battery
adb shell cat /sys/class/thermal/thermal_zone*/temp
adb shell dumpsys SurfaceFlinger --latency
adb shell dumpsys meminfo com.retroarch
adb logcat -d -t 200 | grep -iE "retroarch|anr|fatal"
```

Los comandos se ejecutan desde el PC; no requieren root. Si un `thermal_zone` no existe, se anota como "no disponible" y se usa solo la temperatura de batería.

---

## 7. Métricas y definiciones

| Métrica | Definición operativa | Fuente |
|---|---|---|
| FPS promedio | Media de las 6 muestras de 5 min | Overlay RetroArch |
| Frametime p50 | Mediana de frametime en la corrida | Overlay / log |
| Frametime p95/p99 | Percentil 95/99; recoge los tirones | Overlay / log |
| Frames perdidos | `(frames objetivo − frames mostrados) / objetivo` | Overlay |
| Throttling | Caída sostenida > 10 % de FPS con temperatura alta | Observación + muestras |
| Temperatura | Batería en °C; zona térmica si está disponible | `dumpsys` / sysfs |
| Consumo | % de batería por hora, corregido por capacidad | `dumpsys` inicio/fin |
| Estabilidad | Nº de cuelgues, ANR o reinicios por corrida | Observación + logcat |
| Latencia | Escala 1–5 subjetiva, mismo mando | Hoja |

**Umbral de aceptación (tomado de `FEASIBILITY_REPORT.md` §6):**

- 8/16 bits y PS1: **60 FPS estables**, p95 < 20 ms, frames perdidos < 5 %.
- N64/PSP: **"jugable" o "no jugable"**, sin promesas ni promedios maquillados.
- Una corrida se invalida si: cambió la configuración, se actualizó un core, la batería bajó del 20 %, la temperatura inicial superó 32 °C o hubo intervención del sistema (llamada, actualización).

---

## 8. Almacenamiento de resultados

Estructura en `diagnostics/`:

```
diagnostics/
  bench-<YYYYMMDD>-<sistema>-r1.json
  bench-<YYYYMMDD>-<sistema>-r2.json
  bench-<YYYYMMDD>-<sistema>-r3.json
  screenshots/
    <YYYYMMDD>-<sistema>-t05.png ... t30.png
  bench-summary.md
```

- Usar `diagnostics/benchmark-template.json` como base; no alterar los nombres de campo.
- `bench-summary.md` es la tabla agregada que se anexa a `reports/FEASIBILITY_REPORT.md`.
- Las capturas se conservan; el overlay es la prueba primaria del dato.

---

## 9. Análisis y decisión

1. Completar la matriz de sistemas con los valores medidos.
2. Marcar cada sistema como **Apto**, **Apto con ajustes** o **No apto**, con la corrida que lo respalda.
3. Comparar R1 frente a R2/R3 para documentar el coste de shaders y del frameskip.
4. Actualizar `reports/FEASIBILITY_REPORT.md` §6 y el estado de la Fase 2.
5. Si PS1 no alcanza 60 FPS estables, **no-go** para Fase 2 según el criterio ya fijado.
6. Publicar las limitaciones: térmica, autonomía, ruido, ergonomía y juegos concretos probados.

---

## 10. Seguridad y parada

- **Detener la corrida** si la batería supera **42 °C**, la carcasa quema al tacto, hay olor a plástico o el sistema reinicia.
- No medir cargando el teléfono.
- No usar el teléfono como consola mientras se realizan otras tareas pesadas.
- No instalar APKs fuera de F-Droid/GitHub, ni apps que pidan cuentas o pagos.
- Este protocolo **no requiere** desbloquear el bootloader, root ni modificar el sistema.

---

## 11. Anexos

| Anexo | Archivo |
|---|---|
| Plantilla de resultados | `diagnostics/benchmark-template.json` |
| Identidad y hardware del dispositivo | `diagnostics/device-report.md` |
| Criterios de aceptación de Fase 2 | `reports/FEASIBILITY_REPORT.md` §6 |
| Riesgos asociados | `reports/RISK_ASSESSMENT.md` (R11, R20) |

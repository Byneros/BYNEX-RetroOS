# Informe de viabilidad — BYNEX Retro OS sobre `selene`

**Sprint 0 · 2026-11-24**
**Conclusión:** viable **solo** como consola Android con software libre. No viable como distribución Linux retro nativa.

---

## 1. Pregunta de decisión

> ¿Se puede reemplazar MIUI por un sistema dedicado exclusivamente a videojuegos retro en el Redmi 10 `21061119AL`, de forma gratuita, con software libre y sin asumir un riesgo desproporcionado?

**Respuesta:** sí, pero **no reemplazando Linux por Android**. La única ruta que cumple hoy los requisitos de funcionamiento, gratuidad y riesgo controlado es **Android + frontend/emuladores libres**; el "reemplazo de MIUI" solo tiene sentido en una fase posterior y con una build comunitaria validada.

---

## 2. Hechos que determinan la decisión

1. **Ningún sistema Linux retro soporta el dispositivo.** Batocera, Lakka, EmuELEC y RetroPie no listan `selene`, ni el SoC MT6768/MT6769, ni teléfonos Android. [B1][L1][E1][R1]
2. **Linux en el teléfono es experimental.** postmarketOS tiene ports **downstream** (`xiaomi-eos`, `xiaomi-selene`) que arrancan, pero sin periféricos validados y con "flashing: no". [P2]
3. **Mainline MT6768 no cubre lo necesario.** Audio, WiFi, Bluetooth, módem, GPS, cámara y suspensión están rotos; display es parcial; GPU funciona. No hay DTS de `selene`. [P5][P6]
4. **LineageOS no es oficial para `selene`** (wiki 404), aunque existen árboles comunitarios y builds de terceros. [C1][C4][C5]
5. **El kernel es 4.14 downstream** y Xiaomi no publicó fuentes para Android 12/13. [C10][C11]
6. **GSI es una lotería:** hay reportes de bootloop con Android 13. [A2]
7. **La capa de apps libres funciona hoy:** RetroArch (GPLv3) y Lemuroid (open source) cubren la emulación; un launcher propio cubre la experiencia consola. [A7][A8]

---

## 3. Evaluación ponderada

Criterios y pesos (justificación entre paréntesis):

| Criterio | Peso | Motivo |
|---|---|---|
| Disponibilidad hoy | 25% | Sin artefacto instalable no hay proyecto |
| Riesgo para el dispositivo | 20% | Un ladrillo cancela el proyecto |
| Rendimiento de emulación | 20% | Es una consola; si no corre, no sirve |
| Cumplimiento FOSS/gratuidad | 15% | Requisito explícito |
| Esfuerzo/coste | 10% | Restricción de recursos |
| Mantenibilidad | 10% | Evitar dependencia de un solo voluntario |

Escala 1–5 (5 = mejor). Puntuación = suma ponderada.

| Opción | Disp. | Riesgo | Rend. | FOSS | Esfuerzo | Maint. | **Total** |
|---|---|---|---|---|---|---|---|
| **A1. MIUI + RetroArch/Lemuroid + launcher** | 5 | 5 | 4 | 4 | 5 | 4 | **4,55** |
| A2. LineageOS comunitario + launcher | 3 | 2 | 4 | 5 | 3 | 3 | **3,30** |
| D. GSI AOSP | 2 | 1 | 4 | 4 | 4 | 1 | **2,60** |
| B. postmarketOS + retro | 1 | 1 | 2 | 5 | 1 | 1 | **1,80** |
| C. Port Batocera/Lakka/EmuELEC/RetroPie | 1 | 1 | 2 | 5 | 1 | 1 | **1,80** |
| E. AOSP build propio desde cero | 1 | 1 | 4 | 5 | 1 | 2 | **2,30** |

Cálculo A1: 0,25·5 + 0,20·5 + 0,20·4 + 0,15·4 + 0,10·5 + 0,10·4 = 1,25 + 1,00 + 0,80 + 0,60 + 0,50 + 0,40 = **4,55**.
Cálculo A2: 0,75 + 0,40 + 0,80 + 0,75 + 0,30 + 0,30 = **3,30**.
Cálculo D: 0,50 + 0,20 + 0,80 + 0,60 + 0,40 + 0,10 = **2,60**.
Cálculo B/C: 0,25 + 0,20 + 0,40 + 0,75 + 0,10 + 0,10 = **1,80**.
Cálculo E: 0,25 + 0,20 + 0,80 + 0,75 + 0,10 + 0,20 = **2,30**.

**Lectura:** A1 domina con claridad. A2 es la única opción de "reemplazo real" con puntuación aceptable. B/C están muy por debajo del umbral razonable (≥3,0).

---

## 4. Recomendación

### 4.1 Decisión

**Fase 1 (ahora): Android de fábrica + stack retro libre.**
- No desbloquear. No flashear. No root.
- Instalar (cuando el usuario lo autorice) RetroArch y/o Lemuroid desde F-Droid/GitHub.
- Desarrollar un **launcher retro propio** (FOSS) que se comporte como home y lance los emuladores.
- Medir rendimiento real y usabilidad.

**Fase 2 (condicional): LineageOS comunitario + launcher.**
Solo si se cumplen **todos** los criterios de la sección 6.

**Descartar:** Batocera, Lakka, EmuELEC, RetroPie, postmarketOS y port mainline para este dispositivo en el horizonte del proyecto.

### 4.2 Por qué no "reemplazar MIUI" ya

Porque no existe un sistema Linux utilizable y porque la única alternativa Android (LineageOS) es una build de terceros sin garantías. El coste/beneficio de arriesgar un ladrillo hoy es peor que el de validar primero el rendimiento y la experiencia con apps normales.

### 4.3 Qué se entrega al usuario al final de la Fase 1

- Un teléfono que arranca en una interfaz de consola (launcher propio).
- Emuladores libres configurados.
- Un informe con FPS/frametimes por sistema.
- Cero modificaciones irreversibles.
- Una decisión documentada sobre si merece la pena la Fase 2.

---

## 5. Arquitectura propuesta (Fase 1)

```
[MIUI 14 / Android 13]
        |
        +-- Launcher BYNEX (FOSS, HOME)
        |      +-- Biblioteca de ROMs (almacenamiento local / microSD)
        |      +-- Lanzamiento por Intent
        |
        +-- RetroArch (GPLv3)  --- cores Libretro
        +-- Lemuroid (open source) --- alternativa todo-en-uno
        |
        +-- Mando Bluetooth / USB-OTG
```

Sin servidores, sin cuentas, sin telemetría, sin APIs de pago. Scraping de carátulas opcional y desactivable.

**Fase 2 (si go):**

```
[LineageOS comunitaria verificada, sin GApps]
        |
        +-- Launcher BYNEX como HOME + kiosco (device owner / lock task)
        +-- RetroArch / Lemuroid
        +-- Perfil de rendimiento y almacenamiento en microSD
```

---

## 6. Criterios de aceptación para pasar a Fase 2

Todos obligatorios:

1. **Rendimiento:** 60 FPS estables en NES/SNES/GBA/PS1 durante 30 minutos, con frametime p95 < 20 ms; N64/PSP documentados como "jugable" o "no jugable", sin promesas.
2. **Estabilidad:** 7 días de uso sin cuelgues ni reinicios; temperatura estable.
3. **Identidad:** modelo `21061119AL`, codename y slot confirmados por el script.
4. **Build candidata identificada:** URL, hash SHA-256, maintainer, fecha, lista de funciones reportadas.
5. **Recuperación probada:** firmware fastboot oficial descargado, procedimiento BROM/SP Flash documentado, backup de `persist`/`nvram` y del boot original.
6. **Unidad de repuesto o presupuesto de reemplazo** aceptado por el usuario.
7. **Aceptación explícita** de pérdida de garantía, DRM y posible rotura de funciones.

Si falla cualquiera: **no-go** y se queda la Fase 1.

---

## 7. Pasos pendientes (Sprint 1)

1. Ejecutar `scripts/diagnose-device.ps1` con el teléfono conectado y ADB autorizado.
2. Revisar `diagnostics/device-report.md` y confirmar identidad/hardware.
3. Instalar RetroArch o Lemuroid **manualmente** (decisión del usuario) y ejecutar el protocolo de benchmark.
4. Documentar FPS, temperatura, consumo y ergonomía.
5. Probar mando Bluetooth y USB-OTG.
6. Actualizar este informe con datos medidos.
7. Solo entonces: decidir Fase 2 y seleccionar build candidata.

---

## 8. Limitaciones del informe

- No se probó ninguna imagen ni app en el dispositivo.
- No se midió rendimiento; las puntuaciones de "Rendimiento" son cualitativas.
- Las fuentes comunitarias (foros, repos) prueban existencia, no calidad.
- El wiki de postmarketOS bloquea acceso automatizado; los datos se tomaron de resultados indexados y se citan para verificación humana.
- La disponibilidad de apps en F-Droid debe comprobarse en el momento de la instalación.

---

## 9. Fuentes

B1 https://batocera.org/download · L1 https://www.lakka.tv/get/linux/ · E1 https://github.com/EmuELEC/EmuELEC · R1 https://github.com/RetroPie/RetroPie-Setup
P2 https://wiki.postmarketos.org/wiki/Xiaomi · P5 https://wiki.postmarketos.org/wiki/Mediatek_MT6768 · P6 https://github.com/mt6768-mainline
C1 https://wiki.lineageos.org/devices/selene/ · C4 https://github.com/selene-devs/android_device_xiaomi_selene · C5 https://github.com/xiaomi-selene/android_device_xiaomi_selene · C10 https://github.com/MiCode/Xiaomi_Kernel_OpenSource · C11 https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/39094
A2 https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 · A7 https://github.com/Swordfish90/Lemuroid · A8 https://www.retroarch.com/

Acceso: 2026-11-24.

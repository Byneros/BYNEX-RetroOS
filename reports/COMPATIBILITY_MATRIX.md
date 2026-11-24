# Matriz de compatibilidad — `selene` (Redmi 10, 21061119AL)

**Fecha:** 2026-11-24
**Base:** evidencia documental; **ninguna celda marcada "verificado" fue probada en esta unidad**.

## Leyenda

| Símbolo | Significado |
|---|---|
| **OF** | Soporte oficial del proyecto |
| **CO** | Soporte comunitario (árbol/build de terceros) |
| **EX** | Experimental: arranca o parcial, sin validación |
| **TE** | Teórico: posible con port, sin artefacto |
| **NC** | No compatible |
| **✔** | Funciona / existe evidencia sólida |
| **~** | Parcial o probable, sin verificar en `selene` |
| **?** | Sin datos |
| **✘** | Roto o inexistente |
| **—** | No aplica |

---

## 1. Matriz sistema × soporte

| Sistema | Soporte oficial | Árbol/port comunitario | Imagen instalable verificada | Kernel disponible | Instalable sin port nuevo | Veredicto |
|---|---|---|---|---|---|---|
| **Batocera 44** | NC [B1] | ✘ | ✘ | ✘ (no hay kernel Batocera para MT6768) | ✘ | **NC** |
| **Lakka** | NC [L1] | ✘ | ✘ | ✘ | ✘ | **NC** |
| **EmuELEC** | NC [E1] | ✘ | ✘ | ✘ | ✘ | **NC** |
| **RetroPie** | NC [R1] | ✘ | ✘ | ✘ (solo RPi/ODroid/PC) | ✘ | **NC** |
| **postmarketOS (downstream)** | EX [P2] | ✔ (`xiaomi-eos`, `xiaomi-selene`) | ✘ (flashing no validado) | ✔ 4.14 fabricante | ~ (requiere unlock + flash) | **EX** |
| **postmarketOS (mainline)** | TE [P5] | ~ (MT6768 genérico, no `selene`) | ✘ | ~ (sin DTS `selene`) | ✘ | **TE** |
| **LineageOS oficial** | NC [C1] | — | ✘ | — | — | **NC** |
| **LineageOS comunitario** | CO [C4][C5] | ✔ (`lineage-20`, `lineage-23.2`) | ✘ (builds de terceros, sin hash ni QA) | ✔ 4.14 + módulos | ~ (unlock + recovery) | **CO/EX** |
| **AOSP GSI** | TE [A1] | — | ✘ (reportes de bootloop) | ✔ vendor | ~ (riesgo alto) | **TE/EX** |
| **AOSP build propio** | TE [A3] | ✔ árbol | ✘ | ✔ 4.14 | ~ (meses de trabajo) | **TE** |
| **Android + apps libres (MIUI actual)** | ✔ (sistema de fábrica) | — | — | — | **✔** | **Recomendado Fase 1** |

---

## 2. Matriz de periféricos por ruta viable

> **Importante:** las columnas MIUI describen el sistema de fábrica (referencia), no una medición de esta unidad. Las columnas LineageOS/pmOS reflejan lo que la documentación permite afirmar; **no son promesas**.

| Componente | MIUI 14 (fábrica) | LineageOS comunitario | pmOS downstream | pmOS/mainline MT6768 |
|---|---|---|---|---|
| Pantalla | ✔ | ~ | ? | ~ (*partial*) [P5] |
| Táctil | ✔ | ~ | ? | ? |
| GPU (Mali-G52 MC2) | ✔ | ~ | ? | ✔ (sin integración) [P5] |
| Audio (altavoz/jack) | ✔ | ~ | ? | ✘ [P5] |
| Wi-Fi | ✔ | ~ | ? | ✘ [P5] |
| Bluetooth | ✔ | ~ | ? | ✘ [P5] |
| Almacenamiento eMMC | ✔ | ✔ (base Android) | ✔ | ✔ [P5] |
| microSD | ✔ | ~ | ~ | ✔ [P5] |
| Batería / carga | ✔ | ~ | ? | ~ (carga sí; suspensión ✘) [P5] |
| Suspensión | ✔ | ~ | ? | ✘ [P5] |
| Llamadas / SMS | ✔ | ? | ✘ | ✘ [P5] |
| Cámara | ✔ | ~ (parcial habitual en MTK) | ✘ | ✘ [P5] |
| Huella lateral | ✔ | ? | ? | ? |
| NFC | ~ (según variante) | ? | ? | ✘ |
| Mando USB-OTG | ✔ | ~ | ~ | ~ (USB parcial) [P5] |
| Mando Bluetooth | ✔ | ~ | ? | ✘ |
| Vibración | ✔ | ~ | ? | ? |
| Arranque directo a frontend | ✘ (necesita launcher/kiosco) | ~ (posible con launcher) | ~ | ✘ |
| Actualizaciones de seguridad | ✘ (MIUI 14, 2024) | ✘ (parches 2023) | ✘ | ~ (mainline, pero incompleto) |

**Lectura:** solo la ruta Android de fábrica tiene todos los periféricos cubiertos. Cualquier otra ruta introduce incógnitas, y las rutas Linux están bloqueadas por audio/WiFi/BT/suspensión.

---

## 3. Matriz de requisitos de instalación

| Requisito | Batocera | Lakka | EmuELEC | RetroPie | pmOS | LineageOS | GSI |
|---|---|---|---|---|---|---|---|
| Desbloquear bootloader | Sí | Sí | Sí | Sí | Sí | Sí | Sí |
| Recovery compatible | Sí | Sí | Sí | Sí | Sí | Sí (TWRP comunitario) | Sí |
| Desactivar AVB/vbmeta | Sí | Sí | Sí | Sí | Sí | Sí | Sí |
| Reparticionar / `super` | Probable | Probable | Probable | Probable | No (usa `super`) | No | No |
| Kernel específico del dispositivo | Sí | Sí | Sí | Sí | Sí (downstream) | Sí | No |
| Módulos/blobs del fabricante | — | — | — | — | Parcial | Sí | Vendor existente |
| Plan de recuperación BROM | Sí | Sí | Sí | Sí | Sí | Sí | Sí |

**Conclusión:** todas las rutas exigen desbloqueo. Ninguna es "instalar y listo". La diferencia es que Android/LineageOS ya tiene los blobs y el kernel; Linux tendría que crearlos.

---

## 4. Esfuerzo y retorno (estimación cualitativa)

| Ruta | Esfuerzo | Riesgo | Retorno | Comentario |
|---|---|---|---|---|
| MIUI + RetroArch/Lemuroid | Horas | Muy bajo | Alto | Reversible, sin unlock |
| Launcher propio sobre MIUI | Días-semanas | Muy bajo | Alto | Software propio, FOSS |
| LineageOS comunitario + launcher | Días (si la build es válida) | Medio-alto | Alto | Requiere unlock y validación |
| GSI | Horas | Alto | Medio | Puede no arrancar |
| AOSP build propio | Semanas-meses | Alto | Medio | Mantenimiento continuo |
| postmarketOS downstream | Semanas | Alto | Bajo | Sin periféricos validados |
| postmarketOS mainline | Meses | Muy alto | Bajo | Sin DTS `selene` |
| Port Batocera/Lakka/EmuELEC/RetroPie | Meses | Muy alto | Bajo | Port de plataforma |

---

## 5. Evidencias por fila

| Fila | Evidencia |
|---|---|
| Batocera NC | Lista oficial de 224 dispositivos sin Xiaomi/MediaTek [B1]; arranque ARM vía bootloader alternativo [B2] |
| Lakka NC | Categorías de hardware sin MediaTek [L1] |
| EmuELEC NC | Proyecto "for Amlogic devices"; targets Amlogic/Rockchip [E1] |
| RetroPie NC | Plataformas RPi/OSMC/ODROID-C1/Ubuntu PC [R1] |
| pmOS downstream EX | `xiaomi-eos`/`xiaomi-selene`: arranca, downstream, flashing no, periféricos sin probar [P2][P1] |
| pmOS mainline TE | Estado mainline MT6768: audio/WiFi/BT/suspensión rotos; sin DTS `selene` [P5][P6] |
| LineageOS oficial NC | Wiki 404 [C1]; portal sin `selene` [C2] |
| LineageOS comunitario CO | Árboles `lineage-20` y `lineage-23.2` [C4][C5]; builds no oficiales [C8] |
| GSI TE/EX | Treble arm64 A/B [A1]; bootloop reportado [A2] |
| AOSP build TE | Árbol + kernel 4.14 + blobs; sin fuentes Android 12/13 [A3][A6] |

---

## 6. Fuentes

B1 https://batocera.org/download · B2 https://wiki.batocera.org/hardware:ayn
L1 https://www.lakka.tv/get/linux/
E1 https://github.com/EmuELEC/EmuELEC
R1 https://github.com/RetroPie/RetroPie-Setup
P1 https://wiki.postmarketos.org/wiki/Devices · P2 https://wiki.postmarketos.org/wiki/Xiaomi · P5 https://wiki.postmarketos.org/wiki/Mediatek_MT6768 · P6 https://github.com/mt6768-mainline
C1 https://wiki.lineageos.org/devices/selene/ · C2 https://download.lineageos.org/devices · C4 https://github.com/selene-devs/android_device_xiaomi_selene · C5 https://github.com/xiaomi-selene/android_device_xiaomi_selene · C8 https://community.e.foundation/t/redmi-10-prime-selene/82511
A1 https://community.e.foundation/t/device-support-project-treble/19645 · A2 https://xdaforums.com/t/redmi-10-2022-model.4479475/page-2 · A3 https://github.com/xiaomi-selene/android_device_xiaomi_selene · A6 https://github.com/MiCode/Xiaomi_Kernel_OpenSource/issues/39094

Acceso a todas: 2026-11-24.

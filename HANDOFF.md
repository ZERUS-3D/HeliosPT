# HeliosPT — HANDOFF (передача разработки между ИИ-сессиями)

> Документ для новой сессии ИИ-ассистента (Kimi / любой другой).
> Прочитай его ЦЕЛИКОМ, затем открой файлы из раздела 5. После этого можно
> продолжать разработку без потери контекста.

---

## 1. Что это за проект

Лёгкий производительный шейдерпак **Path Tracing (GI через воксельную
трассировку лучей)** для Minecraft, пишется с нуля.

**Цель:** стабильные 60 FPS в 1080p с включённым воксельным GI на
**NVIDIA GeForce GTX 1080 (архитектура Pascal, без RT-ядер, быстрый FP32,
медленный FP16, ограниченный bandwidth/fillrate).**

## 2. Точное окружение (зафиксировано, не «угадывать»)

| Компонент | Версия |
|-----------|--------|
| Minecraft | 1.18.2 (Java Edition) |
| Mod loader | Forge **40.3.0** |
| Oculus (форк Iris для Forge) | **1.6.4** (`oculus-mc1.18.2-1.6.4.jar`) |
| Embeddium (форк Sodium) | **0.3.18+mc1.18.2** |
| Rubidium | 0.5.6 (присутствует в инстансе) |
| GPU | NVIDIA GTX 1080, драйвер свежий |
| ОС | Windows (запуск через Prism Launcher) |
| Также стоит | Distant Horizons (в шейдерном логе упоминается) |

ВАЖНО про версию Oculus 1.6.4 (это форк Iris примерно эпохи 1.2.x):
- `shaders.properties` **НЕ препроцессируется** — никаких `#define`/`#if`
  внутри него; опции объявляются только в GLSL (`lib/options.glsl`).
- Пункты меню `shadowMapResolution`, `shadowDistance` не резолвятся
  (давали WARN) — убраны из экрана настроек.
- Feature-флаг `REVERSED_CULLING` убран (поддержка появилась позже).
- gbuffers-стадии не должны объявлять composite-семплеры (colortex3..7),
  иначе возможен молчаливый откат пайплайна на fixed-function.
- БАГ: если папка `shaders/` не в корне ZIP — `ClosedFileSystemException`
  при чтении block.properties. В корне архива ОБЯЗАТЕЛЬНА явная запись
  каталога `shaders/` (с trailing slash).

## 3. Текущее состояние (v0.4)

КРИТИЧЕСКОЕ ПРАВИЛО, подтверждённое логом C1038: стандартные юниформы
(shadowcolor0, shadowtex*, depthtex*, cameraPosition, previousCameraPosition,
frameCounter, frameTimeCounter, sunPosition/moonPosition, все матрицы
gbuffer*, viewWidth/Height, near/far, noisetex и т.п.) ОБЪЯВЛЯТЬ НЕЛЬЗЯ —
Oculus инжектит их сам, повторное объявление конфликтует и роняет пайплайн.
В .glsl-библиотеках пака объявляются только: sampler2D colortex0..7,
локальные sampler'ы стадий (tex), и экспериментально near/far в
gbuffer_common.glsl. Если лог снова даст C1038 на near/far — убрать и их.

Фиксы v0.4: C1038-юниформы вычищены; +0.5 в voxelToNDC (точка в центр
текселя, иначе сетка пустая на NVIDIA); temporal reprojection чинится
переводом в координаты прошлой камеры + clip-space проверкой глубины;
history 6/7 пишет только composite2; добавлен DEBUG_MODE [0..4].

Проверочный протокол после загрузки v0.4 (см. MOVE_TO_KIMI.md):
1) лог без C1038 / "disabling shaders";
2) DEBUG_MODE=1 → видны цветные воксели местности (синий фон = сетка пуста);
3) DEBUG_MODE=2 → шумный цветной GI;
4) DEBUG_MODE=0 → небо + GI с тенями.

Историческое состояние v0.2 (для контекста):

Что СДЕЛАНО:
- Пак ЗАГРУЖАЕТСЯ в Oculus 1.6.4, меню настроек работает, профиль MEDIUM
  определяется (`[Oculus]: Profile: MEDIUM`).
- Вокселизация через geometry shader shadow pass → 2D-атлас в shadowcolor0.
- G-буфер MRT: colortex0=albedo(RGBA8), colortex1=normal(RGBA16F),
  colortex2=depth+material(RGBA16F).
- Трассировщик: целочисленный 3D DDA Amanatides-Woo (`lib/voxel.glsl`),
  без fp-raymarching; 1–2 диффузных отскока; cosine hemisphere sampling;
  russian roulette; проверка прямого света к солнцу/луне.
- Темпоральная репроекция (composite1) — упрощённая.
- A-Trous фильтр (composite2/composite3), 3–5 итераций по пресету.
- final.fsh: процедурное небо для фона, ACES tonemap, автоэкспозиция
  с клампом 0.3–1.5, ambient-фолбэк для геометрии без G-буфера.
- Пресеты LOW/MEDIUM/HIGH, слайдеры, en_us.lang.

ТЕКУЩИЙ СИМПТОМ (сообщён пользователем 2026-09-10):
- Пак выбрался, ошибок загрузки нет, меню есть — но картинка ПОЛНОСТЬЮ
  ванильная. Наиболее вероятно: Oculus молча ушёл в fixed-function fallback
  из-за ошибки КОМПИЛЯЦИИ/сборки пайплайна. В логе искать строку:
  `Failed to create shader rendering pipeline, disabling shaders!`
  и выше неё — GLSL-ошибки вида `Couldn't compile ... <program>: <line>: ...`.
- Гипотеза, под которую уже сделан фикс в этой ревизии: composite-семплеры
  в gbuffers/shadow-стадиях (вынесены в lib/gbuffer_common.glsl, тяжёлый
  util.glsl убран из shadow.gsh и terrain-шейдеров). НЕ ПОДТВЕРЖДЕНО —
  нужен новый лог после загрузки v0.2+.

Чего НЕТ (поэтому «красиво» пока не будет, даже когда пайплайн заведётся):
- gbuffers_water: вода/стекло/лёд не трассируются, вода рисуется плоско.
- Эмиссивные блоки (факел, лава, glowstone, лампы, sea lantern) — нет света.
- Волюметрика/god rays/bloom/SSR/туман/погода/облака.
- gbuffers_entities / gbuffers_hand / gbuffers_block — сущности и рука
  рисуются fixed-function с ambient-фолбэком.
- Правильные motion vectors (репроекция приблизительная, возможны смазы).
- Nether (world-1/-1) и End (world1) — НЕ поддержаны, только Overworld.
- block.properties неполный: покрыты основные твёрдые блоки, но не все.

## 4. Архитектура и буферы

| Программа | Файлы | Назначение |
|-----------|-------|-----------|
| shadow | shadow.vsh/.gsh/.fsh | вокселизация: каждый треугольник блока (mc_Entity==1) → 1 точка в атлас |
| gbuffers_terrain (+cutout/+cutout_mipped) | .vsh/.fsh + lib/gbuffers_terrain_shared.glsl | G-буфер MRT 0,1,2 |
| composite | composite.vsh/.fsh | path tracing, DDA, выход: colortex4=radiance, colortex5=момент² |
| composite1 | .fsh | temporal reprojection → CT4,5,6,7 |
| composite2 | .fsh | 2 итерации A-Trous → CT6,7 |
| composite3 | .fsh | ещё до 3 итераций A-Trous → CT4,5 (итог на экране) |
| final | final.vsh/.fsh | небо + сборка albedo*GI + экспозиция + ACES |

Воксельный атлас:
- размер shadow map = 2048 (`const int shadowMapResolution` в lib/voxel.glsl);
- сетка вокселей VX_SIZE = 64/96/128 (пресет); тайлов VX_TILES = 8/10/12;
- атлас занимает VX_TILES*VX_SIZE = 512/960/1536 px в углу shadowcolor0;
- слой по Y → тайл (layer % tiles, layer / tiles); X,Z → локальные px;
- координаты DDA — camera-relative «world» (как gl_Vertex в shadow pass),
  смещение fract(cameraPosition) добавляется и в GSH, и в трейсере.
- конверсии: voxelToPixels/voxelToNDC (GSH), voxelToUV (трейсер).

Пространства:
- sunPosition/moonPosition приходят во VIEW-space; для трейсера их нужно
  крутить через mat3(gbufferModelViewInverse) — уже сделано в composite.fsh
  и final.fsh.

## 5. Инвентарь файлов (внутри shaders/)

```
shaders.properties          # конфиг без препроцессора, профили, экраны, форматы
block.properties            # block.1 = список твёрдых блоков для вокселизации
shadow.vsh / shadow.gsh / shadow.fsh
gbuffers_terrain.vsh/.fsh
gbuffers_terrain_cutout.vsh/.fsh
gbuffers_terrain_cutout_mipped.vsh/.fsh
composite.vsh/.fsh
composite1.vsh/.fsh
composite2.vsh/.fsh
composite3.vsh/.fsh
final.vsh/.fsh
lang/en_us.lang
lib/options.glsl            # ВСЕ #define опции + производные VX_SIZE/MAX_DDA/GI_SCALE
lib/gbuffer_common.glsl     # лёгкий инклюд для gbuffers (без colortex-семплеров!)
lib/util.glsl               # полный набор uniforms/семплеров + хелперы (только composite/final!)
lib/voxel.glsl              # атлас + DDA
lib/noise.glsl              # хэши + cosine hemisphere
lib/color.glsl              # ACES + автоэкспозиция
lib/quad.glsl               # общий fullscreen VSH для composite/final
lib/gbuffers_terrain_shared.glsl
README.md / DEBUGGING.md / ROADMAP.md
```

Рядом с папкой shaders (в корне шейдерпака):
INSTALL.md, HANDOFF.md (этот файл), MOVE_TO_KIMI.md — Oculus их игнорирует.

## 6. Опции и пресеты

Опции живут в lib/options.glsl, комментарии `// [..]` дают слайдеры:
VOXEL_GRID (0=64³/1=96³/2=128³), GI_RESOLUTION (0/1/2), DDA_STEPS
(0=32/1=64/2=128), MAX_BOUNCES (1..3), ATROUS_PASSES (3..5),
EXPOSURE_BIAS (-5..5, шаг 0.1 эффект), SUN_LIGHT_INTENSITY.

Профили в shaders.properties:
- LOW: 64³, GI 0 (half-res*), 64 DDA, 1 bounce, 3 A-Trous
- MEDIUM: 96³, GI 1, 64 DDA, 1 bounce + temporal, 4 A-Trous
- HIGH: 128³, GI 2 (full), 128 DDA, 2 bounce, 5 A-Trous

*) ВНИМАНИЕ: динамический scale GI-буфера через директивы убран вместе с
препроцессором properties; сейчас все composite в полном разрешении.
Полуразрешение для LOW — НЕ РЕАЛИЗОВАНО в v0.2 (нужно size.buffer.colortexN
со статическим значением или отдельное решение) — это пункт дорожной карты.

## 7. Как упаковывать (для Oculus 1.6.4)

Корень ZIP:
```
shaders/shaders.properties
shaders/composite.fsh
...
INSTALL.md (опционально)
```
Запись каталога `shaders/` должна существовать. НЕЛЬЗЯ:
`HeliosPT_Shader/shaders/...` (вложенная папка → ClosedFileSystemException).

## 8. Регламент отладки (так общаться с пользователем)

1. После КАЖДОЙ правки шейдеров пользователь: пересобирает zip → кладёт в
   shaderpacks → полностью перезапускает Minecraft (не только Reload).
2. Присылает `.minecraft/logs/latest.log` ЦЕЛИКОМ (или минимум все строки
   с `[Oculus]`, `[Render thread/ERROR]`, `Couldn't compile`,
   `Failed to create shader rendering pipeline`) + скриншот F2.
3. Сообщает пресет, измерение, время суток и что делал.
4. Порядок починки: сперва добиться, чтобы пайплайн реально работал
   (признак: картинка ОТЛИЧАЕТСЯ от ванили — хотя бы небо/тонмаппинг),
   потом визуальные артефакты, потом фичи по ROADMAP.md.

Признаки этапов:
- fixed-function fallback (как сейчас) = ванильная графика 1:1.
- шейдеры активны, но финал тёмный = небо/экспозиция/пустой colortex4.
- шум без сглаживания = temporal/denoiser не пишет/не читает буферы.
- рябь вокселей/нет теней = block.properties / маппинг атласа / DDA.

## 9. Эталонные ресурсы (проверены)

- vx-simple (CoolQ1000): минимальная вокселизация+DDA под Iris —
  https://github.com/coolq1000/vx-simple (наш код основан на её схеме).
- Minecraft-PTGI (MahoganyTown): PTGI + SVGF, современный Iris —
  https://github.com/MahoganyTown/Minecraft-PTGI
- Документация директив: https://shaders.properties/current/reference/
- Исходники Oculus 1.18.2: https://github.com/Asek3/Oculus (ветка 1.18.2)
- SVGF (Schied et al. 2017): spatiotemporal variance-guided filtering.

## 10. Ближайшие шаги (после того как пайплайн заведётся)

1. Подтвердить по логу активность пайплайна; устранить все GLSL-ошибки.
2. Визуально проверить тени/GI на MEDIUM, убрать явные артефакты.
3. Вернуть half-res GI для LOW (статические size.buffer).
4. gbuffers_water (простая вода + SSR) и эмиссивные блоки.
5. Небо/атмосфера получше, bloom.
6. Motion vectors + стабилизация temporal.
7. Nether/End пайплайны.
8. Перформанс-пас под Pascal (RGBA16F везде, короче циклы, замеры FPS).

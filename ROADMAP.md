# HeliosPT — Roadmap / журнал доработок

Цель: стабильные 60 FPS @1080p на GTX 1080 (Pascal) в Minecraft 1.18.2
(Forge + Embeddium + Oculus), диффузный path-traced GI без RT-ядер.

Легенда: [x] готово (в каркасе) · [~] заглушка/упрощено · [ ] не сделано

---

## Этап 0 — Каркас (текущая версия)

- [x] Вокселизация через geometry shader (shadow pass) → 2D-атлас
- [x] Переключаемые сетки 64³ / 96³ / 128³
- [x] G-buffer MRT: albedo (CT0), normal (CT1), depth+material (CT2)
- [x] Целочисленный 3D DDA Amanatides-Woo (`lib/voxel.glsl`)
- [x] 1–2 диффузных отскока, cosine hemisphere sampling
- [x] Полуразрешение GI 0.5 / 0.75 / 1.0
- [x] Temporal reprojection (упрощённый)
- [x] A-Trous SVGF 3–5 итераций с весами depth/normal
- [x] ACES tonemap + автоэкспозиция с клампом 0.3–1.5
- [x] Пресеты LOW / MEDIUM / HIGH
- [x] Прямые солнечные тени через вторичный DDA-луч

## Этап 1 — Минимально красивая картинка Overworld

- [ ] Корректная привязка вокселей к блокам (тесты на границах чанков)
- [ ] Полный `block.properties` (полублоки, заборы, ступени, листва)
- [ ] `gbuffers_water`: плоская вода, окрашенное преломление, SSR отражение
- [ ] Эмиссивные блоки: факел, светокамень, лава, лампа, морской фонарь
      (вокселизация источников + сэмплирование при hit)
- [ ] Аналитическое небо: атмосфера (Preetham/упрощённая), диск солнца/луны
- [ ] Дождь/снег в шейдинге (мокрые поверхности — опционально)
- [ ] Базовый TAA против «лесенки»

## Этап 2 — Стабилизация GI и денойзера

- [ ] Настоящие motion vectors (velocity buffer в gbuffers)
- [ ] History clamp по момент-базе (SVGF variance)
- [ ] Disocclusion detection по глубине/нормали/положению
- [ ] Half-res upscale GI в полное разрешение (edge-aware)
- [ ] Историчность воксельной сетки без утечек на границах

## Этап 3 — Полировка

- [ ] Bloom (soft threshold, FP16)
- [ ] Volumetric light / god rays (опц., LOW выкл)
- [ ] SSR для стекла/льда
- [ ] Цветокор: contrast/saturation/vignette ползунки
- [ ] Ambient occlusion контактный (RTAO из первого отскока)
- [ ] Анимированная листва/водяная поверхность (waving)

## Этап 4 — Измерения

- [ ] Nether (world-1): без солнца, свет лавы/порталов, оранжевый фог
- [ ] End (world1): тёмное «небо», свет эндерняка/портала Края
- [ ] Отдельные настройки экспозиции под измерение

## Этап 5 — Перформанс-пас под Pascal

- [ ] Профилировка чисел шагов DDA по сценам
- [ ] Уменьшить register pressure в composite.fsh
- [ ] RGBA16F-буферы там, где не нужна точность
- [ ] Ранний выход из bounce-цикла (улучшить Russian roulette)
- [ ] Замеры: целевые 60 FPS MEDIUM на GTX 1080

---

## Журнал изменений

### v0.4 (Этап 1: компиляция, воксели, temporal)
По результатам разбора latest.log во внешней ИИ-сессии:
- ФИКС C1038 ("declaration conflicts...": shadowcolor0, cameraPosition,
  frameTimeCounter, frameCounter): эти и прочие стандартные юниформы
  инжектит Oculus — все повторные объявления убраны из lib/util.glsl,
  lib/voxel.glsl, lib/noise.glsl, lib/gbuffer_common.glsl. В коде пака
  объявляются только colortex0..7, near/far и локальный sampler tex.
- ФИКС пустой воксельной сетки: точка GSH ставилась на угол 4 текселей и
  дропалась растеризатором NVIDIA. В voxelToNDC добавлено смещение +0.5
  (центр пикселя), voxelToUV уже центрирован.
- ФИКС temporal reprojection в composite1: координаты переводятся в систему
  ПРОШЛОЙ камеры (worldPos + cameraPosition - previousCameraPosition),
- проверка глубины берётся из репроецированного clip-space; запись только
  в colortex4/5 (history 6/7 отдаётся composite2, она больше не затирается
  дважды за кадр).
- Добавлен DEBUG_MODE [0..4]: 0 off, 1 воксели (трассировка из камеры),
  2 GI-буфер, 3 albedo, 4 нормали. Пункт меню [DEBUG].
- Ожидается после загрузки: при DEBUG_MODE=1 цветные воксели на местности;
  DEBUG_MODE=2 — шумный цветной GI; DEBUG_MODE=0 — небо + GI с тенями.
- НЕ сделано (след. этапы): GI_SCALE/half-res, настоящий ping-pong A-Trous,
  gbuffers_water, эмиссия, небо высокого качества, Nether/End.

### v0.3 (гипотеза фикса ванильной картинки)
- Симптом: пак грузится, меню есть, но рендер полностью ванильный
  (вероятен fixed-function fallback при сборке пайплайна).
- Из gbuffers- и shadow-стадий убран тяжёлый lib/util.glsl с composite-only
  семплерами (colortex3..7); для gbuffers добавлен lib/gbuffer_common.glsl.
- Добавлены HANDOFF.md и MOVE_TO_KIMI.md для переноса разработки.
- СТАТУС: требует подтверждения по latest.log (см. DEBUGGING.md, п.3.2).

### v0.2 (фикс загрузки под Oculus 1.6.4)
- Использование: Forge 40.3.0 + Embeddium 0.3.18 + Oculus 1.6.4, MC 1.18.2.
- Фикс краша `ClosedFileSystemException`: zip собирается с `shaders/`
  строго в корне + добавлен INSTALL.md с правилами упаковки.
- shaders.properties очищен под Oculus 1.6.4: убраны `#define/#if`
  (препроцессор в .properties этой версии не поддерживается),
  невалидные пункты меню, неподдерживаемый feature flag;
  форматы буферов переведены на RGBA8/RGBA16F.
- Исправлен маппинг воксельного атласа в NDC (был растянут на весь shadow map).
- Направление солнца/луны переводится из view-space в world-space.
- Добавлены gbuffers_terrain_cutout / _cutout_mipped (листва, трава).
- final.fsh: процедурное небо для фона и ambient-фолбэк для геометрии
  без G-буфера (рука, сущности, вода до появления своих шейдеров).

### v0.1 (каркас)
- Первая выкладка структуры и всех базовых программ.
- GI, DDA, temporal, A-Trous, tonemap — в виде стартовой реализации.

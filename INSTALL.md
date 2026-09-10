# HeliosPT — установка и правильная упаковка ZIP

## Структура архива (ОБЯЗАТЕЛЬНО)

Oculus 1.6.4 требует, чтобы папка `shaders` лежала **в корне ZIP**:

```
HeliosPT.zip
└── shaders/
    ├── shaders.properties
    ├── block.properties
    ├── shadow.vsh / .gsh / .fsh
    ├── composite.fsh / composite1..3.fsh (+ .vsh)
    ├── final.fsh / .vsh
    └── lib/ ...
```

### ТИПИЧНАЯ ОШИБКА (даёт `ClosedFileSystemException`)

Если в Windows кликнуть ПКМ по папке `HeliosPT_Shader` →
«Отправить» → «Сжатую ZIP-папку», получится ВЛОЖЕННАЯ структура:

```
HeliosPT_Shader.zip
└── HeliosPT_Shader/        ← лишняя папка, Oculus такое не переваривает
    └── shaders/ ...
```

Oculus находит `shaders` не в корне, уходит в fallback-ветку поиска и
падает с `ClosedFileSystemException` в `IdMap.readProperties`
(`Failed to load the shaderpack`).

## Как правильно сделать ZIP вручную

1. Открой папку `HeliosPT_Shader`.
2. Выдели папку `shaders` (внутри неё).
3. ПКМ по `shaders` → «Отправить» → «Сжатую ZIP-папку».
4. Назови архив, например, `HeliosPT.zip`.
5. Проверь содержимое: открыв ZIP, ты должен СРАЗУ видеть папку `shaders`,
   а не `HeliosPT_Shader/shaders`.

На Linux/macOS: `zip -r HeliosPT.zip shaders` (находясь внутри HeliosPT_Shader).

## Установка

1. Положи `HeliosPT.zip` в `.minecraft/shaderpacks/`
   (кнопка «Open Shader Pack Folder» в меню шейдеров открывает её же).
2. Не распаковывай архив — Oculus читает ZIP как есть.
3. Выбери HeliosPT в списке, профиль по умолчанию — MEDIUM.

## Проверка, что структура верная

После выбора пака в логе `.minecraft/logs/latest.log` должно быть:

```
[Oculus]: Creating pipeline for dimension OVERWORLD
... (компиляция программ)
[Oculus]: Using shaderpack: HeliosPT.zip
```

Если видишь `it appears to lack a "shaders" directory` — значит, папка
вложена дважды, переделай архив по инструкции выше.

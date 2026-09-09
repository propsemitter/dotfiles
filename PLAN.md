# План настройки LSP для Oh My Pi

## Context

Oh My Pi показывает `No LSP servers`. Это не означает, что интеграция выключена: `lsp.enabled` по умолчанию равен `true`, но OMP настраивает сервер для проекта только когда одновременно выполнены два условия — в текущем `cwd` найден корневой маркер проекта и бинарник language server доступен в локальном `node_modules/.bin` либо в `$PATH`.

Сейчас в системе доступны Node.js 25.6.1, npm/pnpm/Bun и `vue-language-server`, но не обнаружены TypeScript, ESLint, HTML/CSS/JSON, Tailwind и YAML language servers. Установлен OMP 18.1.11. Конфигурация OMP хранится в репозитории как `omp/agent/config.yml` и устанавливается симлинком через `install.sh`; отдельного `lsp.json` пока нет.

Цель: воспроизводимая пользовательская конфигурация OMP для frontend-проектов, с проектными локальными зависимостями в приоритете и глобальными серверами как рабочим fallback.

## Approach

Решение:

- включить LSP явно в `config.yml`, сохранив ленивый запуск и диагностику после записи файла;
- установить глобальный fallback через npm для TypeScript/JavaScript/React, Vue, ESLint, HTML, CSS/SCSS/Less, JSON, Tailwind CSS и YAML;
- reuse встроенных definitions для TypeScript, ESLint, Tailwind и Vue, переопределяя только root markers;
- явно зарегистрировать HTML/CSS/JSON/YAML servers в `omp/agent/lsp.json` для совместимости с активным runtime OMP, а также добавить современные имена flat-config ESLint и `package.json` как fallback-маркер Tailwind v4.
- сохранить приоритет project-local `node_modules/.bin`, который OMP применяет перед глобальными бинарниками;
- сделать `backup_and_link` безопасным для повторного запуска: уже корректный симлинк пропускать, а не переносить в новый backup;
- устанавливать npm-пакеты только если отсутствует хотя бы один требуемый бинарник; выбранные пакеты: `typescript`, `typescript-language-server`, `@vue/language-server`, `vscode-langservers-extracted`, `@tailwindcss/language-server`, `yaml-language-server`.

## Files to modify

- `omp/agent/config.yml` — явное включение LSP и безопасные runtime-настройки.
- `omp/agent/lsp.json` — frontend server registrations и overrides root markers для современных ESLint и Tailwind CSS v4 проектов.
- `install.sh` — идемпотентные симлинки, установка LSP-конфига и глобальных fallback-серверов.
- `README.md` — требования, список поддерживаемых языков и проверка после установки.

## Reuse

- `backup_and_link` из `install.sh` — для `~/.omp/agent/lsp.json`.
- Встроенные server definitions OMP (`defaults.json`, описанные в `omp://lsp-config.md`) — автоопределение серверов по root markers и бинарникам.
- Приоритет project-local `node_modules/.bin` в OMP — проектная версия TypeScript/плагинов будет использоваться раньше глобальной.

## Steps

- [x] Уточнить целевой набор frontend-стеков и политику установки серверов: основной frontend-набор, глобальный npm fallback.
- [x] Проверить встроенные определения/root markers в установленном OMP 18.1.11.
- [x] Добавить явные `lsp.enabled`, lazy startup и diagnostics-on-write в `omp/agent/config.yml`.
- [x] Создать `omp/agent/lsp.json`: расширить root markers ESLint (`eslint.config.cjs|ts|cts|mts`, `.eslintrc.cjs`) и Tailwind (`package.json` для v4), сохранив встроенные маркеры OMP 18.1.11.
- [x] Явно зарегистрировать HTML/CSS/JSON/YAML servers для совместимости с runtime.
- [x] Обновить `backup_and_link`, чтобы корректный существующий симлинк не создавал backup при каждом повторном запуске.
- [x] Добавить в `install.sh` проверку требуемых бинарников, одну npm-установку выбранных пакетов при нехватке и симлинк `~/.omp/agent/lsp.json`.
- [x] Обновить `README.md`: поддерживаемые языки, npm fallback, приоритет project-local серверов, запуск OMP из корня проекта и диагностика `No LSP servers`.
- [x] Проверить конфиги и реальную LSP-навигацию/диагностику в минимальных TypeScript/React и Vue сценариях; отдельно проверить initialization capabilities HTML/CSS/JSON, ESLint, Tailwind v4 и YAML.
- [x] Проверить повторный запуск installer без backup уже корректных симлинков и без повторной npm-установки.

## Verification

- Проверить `bash -n install.sh`, JSON-парсинг `omp/agent/lsp.json` и чтение обновлённого `config.yml` командой OMP.
- Запустить обновлённый installer на текущей конфигурации: требуемые бинарники должны появиться в `$PATH`; второй запуск должен пропустить корректные симлинки и npm install.
- В изолированной временной директории создать минимальные проекты с корректными root markers: TypeScript/React, Vue, ESLint flat config, Tailwind v4 без `tailwind.config.*`, HTML/CSS/JSON и YAML.
- Для TypeScript и Vue выполнить реальные LSP `definition`, `references` и `diagnostics`; для остальных серверов — `status`/`capabilities` и диагностику подходящего файла.
- Подтвердить, что OMP запускается из корня проекта. Запуск из каталога без соответствующего marker закономерно показывает `No LSP servers`, поскольку OMP 18.1.11 проверяет markers только непосредственно в текущем каталоге.

# Инструкция по сборке IPA файла

IPA (iOS App Store Package) - это архив для распространения iOS приложений.

## Способ 1: Через Xcode (GUI)

### Шаг 1: Настройка подписи кода

1. Откройте проект в Xcode:
   ```bash
   open player.xcodeproj
   ```

2. Выберите проект в навигаторе (левый верхний угол)
3. Выберите target "player"
4. Перейдите на вкладку **Signing & Capabilities**
5. Включите **Automatically manage signing**
6. Выберите вашу **Team** (Apple Developer Account)
   - Если у вас нет аккаунта, создайте его на [developer.apple.com](https://developer.apple.com)

### Шаг 2: Выбор устройства для сборки

1. В верхней панели Xcode выберите **Any iOS Device (arm64)** или конкретное устройство
   - ⚠️ **Важно**: Не выбирайте симулятор, иначе Archive будет недоступен

### Шаг 3: Создание архива

1. В меню Xcode выберите **Product → Archive**
2. Дождитесь завершения сборки
3. Откроется окно **Organizer** с архивом

### Шаг 4: Экспорт IPA

1. В окне Organizer выберите ваш архив
2. Нажмите **Distribute App**
3. Выберите способ распространения:
   - **App Store Connect** - для публикации в App Store
   - **Ad Hoc** - для установки на конкретные устройства
   - **Enterprise** - для корпоративного распространения
   - **Development** - для разработки и тестирования
4. Следуйте инструкциям мастера
5. Выберите папку для сохранения IPA файла

## Способ 2: Через командную строку (xcodebuild)

### Требования

- Установленный Xcode
- Настроенные подписи кода
- Apple Developer Account

### Создание скрипта сборки

Используйте скрипт `build_ipa.sh` (см. ниже) или выполните команды вручную:

```bash
# 1. Очистка предыдущих сборок
xcodebuild clean -project player.xcodeproj -scheme player

# 2. Создание архива
xcodebuild archive \
  -project player.xcodeproj \
  -scheme player \
  -archivePath ./build/player.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="iPhone Developer" \
  PROVISIONING_PROFILE_SPECIFIER=""

# 3. Экспорт IPA (требует exportOptions.plist)
xcodebuild -exportArchive \
  -archivePath ./build/player.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist exportOptions.plist
```

### Настройка exportOptions.plist

Создайте файл `exportOptions.plist` с настройками экспорта:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string> <!-- или ad-hoc, app-store, enterprise -->
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

## Способ 3: Использование готового скрипта

Запустите скрипт `build_ipa.sh`:

```bash
chmod +x build_ipa.sh
./build_ipa.sh
```

## Важные замечания

1. **Apple Developer Account**: Для создания IPA нужен аккаунт разработчика ($99/год)
2. **Подписи кода**: Без правильных подписей приложение не установится на устройство
3. **Provisioning Profile**: Для Ad Hoc и Enterprise нужны профили
4. **Устройство**: Archive работает только для реальных устройств, не для симуляторов

## Типы распространения

- **Development**: Для тестирования на зарегистрированных устройствах
- **Ad Hoc**: Для установки на до 100 конкретных устройств
- **App Store**: Для публикации в App Store
- **Enterprise**: Для корпоративного распространения (требует Enterprise аккаунт)

## Проверка IPA

После создания IPA можно проверить его содержимое:

```bash
# Распаковать IPA (это ZIP архив)
unzip player.ipa -d ipa_contents

# Просмотреть структуру
ls -la ipa_contents/Payload/
```

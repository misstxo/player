#!/bin/bash

# Скрипт для автоматической сборки IPA файла
# Использование: ./build_ipa.sh

set -e

PROJECT_NAME="player"
SCHEME_NAME="player"
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"

echo "🚀 Начинаем сборку IPA для ${PROJECT_NAME}..."

# Проверка наличия Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Ошибка: xcodebuild не найден. Установите Xcode."
    exit 1
fi

# Создание директории для сборки
mkdir -p "${BUILD_DIR}"

# Очистка предыдущих сборок
echo "🧹 Очистка предыдущих сборок..."
xcodebuild clean \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release

# Создание архива
echo "📦 Создание архива..."
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="iPhone Developer" \
    CODE_SIGN_STYLE="Automatic" \
    DEVELOPMENT_TEAM="" \
    PROVISIONING_PROFILE_SPECIFIER=""

if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo "❌ Ошибка: Не удалось создать архив"
    exit 1
fi

echo "✅ Архив создан: ${ARCHIVE_PATH}"

# Проверка наличия exportOptions.plist
if [ ! -f "exportOptions.plist" ]; then
    echo "⚠️  Файл exportOptions.plist не найден. Создаю базовый файл..."
    cat > exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
    echo "📝 Создан exportOptions.plist. Отредактируйте его перед экспортом."
    echo "⚠️  Для продолжения нужно настроить exportOptions.plist вручную."
    echo "📖 См. инструкцию в BUILD_IPA.md"
    exit 0
fi

# Экспорт IPA
echo "📤 Экспорт IPA..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist exportOptions.plist

# Проверка результата
IPA_FILE="${EXPORT_PATH}/${PROJECT_NAME}.ipa"
if [ -f "${IPA_FILE}" ]; then
    echo "✅ IPA файл успешно создан: ${IPA_FILE}"
    echo "📊 Размер файла: $(du -h "${IPA_FILE}" | cut -f1)"
else
    echo "❌ Ошибка: IPA файл не найден"
    exit 1
fi

echo "🎉 Сборка завершена успешно!"

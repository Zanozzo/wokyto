#!/bin/bash

# Название старое и новое
OLD_NAME="fluffychat"
NEW_NAME="wokytoky"
OLD_PACKAGE="chat.fluffy.fluffychat"
NEW_PACKAGE="com.wokytoky.chat"

echo "🔧 Переименование проекта: $OLD_NAME → $NEW_NAME"
echo "📦 Переименование пакета: $OLD_PACKAGE → $NEW_PACKAGE"

# pubspec.yaml: замена name:
sed -i "s/^name: $OLD_NAME/name: $NEW_NAME/" pubspec.yaml

# build.gradle: задай namespace вручную
BUILD_GRADLE="android/app/build.gradle"
if grep -q "namespace" "$BUILD_GRADLE"; then
  sed -i "s|^namespace .*|namespace '$NEW_PACKAGE'|" "$BUILD_GRADLE"
else
  echo "namespace '$NEW_PACKAGE'" >> "$BUILD_GRADLE"
fi

# AndroidManifest.xml: обнови package
sed -i "s/package=\"$OLD_PACKAGE\"/package=\"$NEW_PACKAGE\"/" android/app/src/main/AndroidManifest.xml

# MainActivity.kt — меняем package
MAIN_KT=$(find android/app/src/main/kotlin -name "MainActivity.kt")
if [ -n "$MAIN_KT" ]; then
  sed -i "s|^package .*|package $NEW_PACKAGE|" "$MAIN_KT"
fi

# Переместим kotlin-файлы в новую структуру
SRC_DIR="android/app/src/main/kotlin"
OLD_PATH=$(echo "$OLD_PACKAGE" | tr . /)
NEW_PATH=$(echo "$NEW_PACKAGE" | tr . /)

if [ -d "$SRC_DIR/$OLD_PATH" ]; then
  mkdir -p "$SRC_DIR/$NEW_PATH"
  mv "$SRC_DIR/$OLD_PATH/"* "$SRC_DIR/$NEW_PATH/"
  rm -rf "$SRC_DIR/$(echo "$OLD_PACKAGE" | cut -d. -f1)"  # удалим 'chat' корень
fi

# msix_config: меняем всё что выглядит как fluffychat
sed -i "s/$OLD_NAME/$NEW_NAME/g" pubspec.yaml
sed -i "s/$OLD_PACKAGE/$NEW_PACKAGE/g" pubspec.yaml

# launcher icons
if grep -q "flutter_launcher_icons" pubspec.yaml; then
  sed -i "s|image_path: .*|image_path: \"assets/logo.png\"|" pubspec.yaml
fi

echo "✅ Переименование завершено. Теперь:"
echo "1. Проверь работоспособность:"
echo "     flutter clean && flutter pub get && flutter run"
echo "2. Убедись, что namespace и package совпадают."

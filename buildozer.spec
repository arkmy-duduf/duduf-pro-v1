[app]
title = Duduf Occas
package.name = dudufoccas
package.domain = com.arkmy

# Code source principal
source.dir = .
source.include_exts = py,kv,png,jpg,ico,json
source.include_patterns = *.json, duduf_occas_logo.ico, duduf_occas_logo.png

# Version
version = 0.1.0

# Librairies Python nécessaires
requirements = python3,kivy

# Affichage
orientation = portrait
fullscreen = 0

# Architecture (remplace android.arch)
android.archs = arm64-v8a

# Icône et splash
icon.filename = Duduf_Occas_by_Tony.ico
presplash.filename = duduf_occas_logo.png

# Android SDK / NDK
android.api = 31
android.minapi = 21
android.ndk = 25b
android.accept_sdk_license = True

[buildozer]
log_level = 2
warn_on_root = 1

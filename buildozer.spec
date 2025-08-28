[app]
title = Duduf Occas
package.name = dudufoccas
package.domain = com.arkmy
source.dir = .
source.include_exts = py,kv,png,jpg,ico,json
source.include_patterns = *.json, duduf_occas_logo.ico, duduf_occas_logo.png

version = 0.1.0
requirements = python3,kivy
orientation = portrait
fullscreen = 0

# Choisis UNE seule archi pour simplifier le 1er build
android.arch = arm64-v8a

# Icônes / splash (facultatif mais ok si présents)
icon.filename = Duduf_Occas_by_Tony.ico
presplash.filename = duduf_occas_logo.png

# API/NDK (stables pour p4a/buildozer)
android.api = 31
android.minapi = 21
android.ndk = 25b
android.accept_sdk_license = True

[buildozer]
log_level = 2
warn_on_root = 1

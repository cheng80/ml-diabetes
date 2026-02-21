#!/usr/bin/env bash
# webview_flutter_android AGP8 호환 패치 (remedi_kopo 등 구버전 webview 사용 시)
#
# 사용법:
#   1. 프로젝트 루트에서: flutter pub get
#   2. 이 스크립트 실행: ./scripts/patch_webview_for_android.sh
#   3. 빌드: flutter build apk --debug
#
# 다른 프로젝트 적용: 이 스크립트를 복사한 뒤, 해당 프로젝트에서 동일하게 실행

set -e

# pub-cache 경로 (PUB_CACHE > dart pub cache path > 기본값)
PUB_CACHE="${PUB_CACHE:-$(dart pub cache path 2>/dev/null || echo "$HOME/.pub-cache")}"
HOSTED="${PUB_CACHE}/hosted/pub.dev"

# webview_flutter_android 패키지 찾기
PLUGIN_DIR=""
for d in "$HOSTED"/webview_flutter_android-*; do
  if [ -d "$d" ]; then
    PLUGIN_DIR="$d"
    break
  fi
done

if [ -z "$PLUGIN_DIR" ] || [ ! -d "$PLUGIN_DIR" ]; then
  echo "[patch] webview_flutter_android 패키지를 찾을 수 없습니다."
  echo "        먼저 'flutter pub get'을 실행한 뒤 다시 시도하세요."
  exit 1
fi

echo "[patch] 대상: $PLUGIN_DIR"

PATCHED=0

# 0. build.gradle - namespace 추가 (AGP 8+ 필수)
BUILD_GRADLE="${PLUGIN_DIR}/android/build.gradle"
if [ -f "$BUILD_GRADLE" ] && ! grep -q "namespace 'io.flutter.plugins.webviewflutter'" "$BUILD_GRADLE" 2>/dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "/^android {/a\\
    namespace 'io.flutter.plugins.webviewflutter'
" "$BUILD_GRADLE"
  else
    sed -i "/^android {/a\\
    namespace 'io.flutter.plugins.webviewflutter'
" "$BUILD_GRADLE"
  fi
  echo "[patch] build.gradle namespace 추가 완료"
  PATCHED=1
fi

# 1. AndroidManifest.xml - package 속성 제거
MANIFEST="${PLUGIN_DIR}/android/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && grep -q 'package="io.flutter.plugins.webviewflutter"' "$MANIFEST" 2>/dev/null; then
  printf '<manifest>\n</manifest>\n' > "$MANIFEST"
  echo "[patch] AndroidManifest.xml 수정 완료"
  PATCHED=1
fi

# 2. FlutterAssetManager.java - RegistrarFlutterAssetManager 제거
ASSET_MGR="${PLUGIN_DIR}/android/src/main/java/io/flutter/plugins/webviewflutter/FlutterAssetManager.java"
if [ -f "$ASSET_MGR" ] && grep -q 'PluginRegistry.Registrar' "$ASSET_MGR" 2>/dev/null; then
  cat > "$ASSET_MGR" << 'JAVA1_EOF'
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.res.AssetManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import java.io.IOException;

/** Provides access to the assets registered as part of the App bundle. */
abstract class FlutterAssetManager {
  final AssetManager assetManager;

  public FlutterAssetManager(AssetManager assetManager) {
    this.assetManager = assetManager;
  }

  abstract String getAssetFilePathByName(String name);

  public String[] list(@NonNull String path) throws IOException {
    return assetManager.list(path);
  }

  // Legacy v1 embedding asset manager removed for modern Flutter compatibility.

  static class PluginBindingFlutterAssetManager extends FlutterAssetManager {
    final FlutterPlugin.FlutterAssets flutterAssets;

    PluginBindingFlutterAssetManager(
        AssetManager assetManager, FlutterPlugin.FlutterAssets flutterAssets) {
      super(assetManager);
      this.flutterAssets = flutterAssets;
    }

    @Override
    public String getAssetFilePathByName(String name) {
      return flutterAssets.getAssetFilePathByName(name);
    }
  }
}
JAVA1_EOF
  echo "[patch] FlutterAssetManager.java 수정 완료"
  PATCHED=1
fi

# 3. WebViewFlutterPlugin.java - registerWith 메서드 제거
PLUGIN_JAVA="${PLUGIN_DIR}/android/src/main/java/io/flutter/plugins/webviewflutter/WebViewFlutterPlugin.java"
if [ -f "$PLUGIN_JAVA" ] && grep -q 'registerWith(io.flutter.plugin.common.PluginRegistry.Registrar' "$PLUGIN_JAVA" 2>/dev/null; then
  cat > "$PLUGIN_JAVA" << 'JAVA2_EOF'
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.content.Context;
import android.os.Handler;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.CookieManagerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.DownloadListenerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.FlutterAssetManagerHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.JavaScriptChannelHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebChromeClientHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebSettingsHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebStorageHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewClientHostApi;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebViewHostApi;

/**
 * Java platform implementation of the webview_flutter plugin.
 *
 * <p>Register this in an add to app scenario to gracefully handle activity and context changes.
 *
 * <p>Legacy v1 embedding registration is removed in this local compatibility patch.
 */
public class WebViewFlutterPlugin implements FlutterPlugin, ActivityAware {
  private InstanceManager instanceManager;

  private FlutterPluginBinding pluginBinding;
  private WebViewHostApiImpl webViewHostApi;
  private JavaScriptChannelHostApiImpl javaScriptChannelHostApi;

  /**
   * Add an instance of this to {@link io.flutter.embedding.engine.plugins.PluginRegistry} to
   * register it.
   */
  public WebViewFlutterPlugin() {}

  private void setUp(
      BinaryMessenger binaryMessenger,
      PlatformViewRegistry viewRegistry,
      Context context,
      View containerView,
      FlutterAssetManager flutterAssetManager) {

    instanceManager = InstanceManager.open(identifier -> {});

    viewRegistry.registerViewFactory(
        "plugins.flutter.io/webview", new FlutterWebViewFactory(instanceManager));

    webViewHostApi =
        new WebViewHostApiImpl(
            instanceManager, new WebViewHostApiImpl.WebViewProxy(), context, containerView);
    javaScriptChannelHostApi =
        new JavaScriptChannelHostApiImpl(
            instanceManager,
            new JavaScriptChannelHostApiImpl.JavaScriptChannelCreator(),
            new JavaScriptChannelFlutterApiImpl(binaryMessenger, instanceManager),
            new Handler(context.getMainLooper()));

    WebViewHostApi.setup(binaryMessenger, webViewHostApi);
    JavaScriptChannelHostApi.setup(binaryMessenger, javaScriptChannelHostApi);
    WebViewClientHostApi.setup(
        binaryMessenger,
        new WebViewClientHostApiImpl(
            instanceManager,
            new WebViewClientHostApiImpl.WebViewClientCreator(),
            new WebViewClientFlutterApiImpl(binaryMessenger, instanceManager)));
    WebChromeClientHostApi.setup(
        binaryMessenger,
        new WebChromeClientHostApiImpl(
            instanceManager,
            new WebChromeClientHostApiImpl.WebChromeClientCreator(),
            new WebChromeClientFlutterApiImpl(binaryMessenger, instanceManager)));
    DownloadListenerHostApi.setup(
        binaryMessenger,
        new DownloadListenerHostApiImpl(
            instanceManager,
            new DownloadListenerHostApiImpl.DownloadListenerCreator(),
            new DownloadListenerFlutterApiImpl(binaryMessenger, instanceManager)));
    WebSettingsHostApi.setup(
        binaryMessenger,
        new WebSettingsHostApiImpl(
            instanceManager, new WebSettingsHostApiImpl.WebSettingsCreator()));
    FlutterAssetManagerHostApi.setup(
        binaryMessenger, new FlutterAssetManagerHostApiImpl(flutterAssetManager));
    CookieManagerHostApi.setup(binaryMessenger, new CookieManagerHostApiImpl());
    WebStorageHostApi.setup(
        binaryMessenger,
        new WebStorageHostApiImpl(instanceManager, new WebStorageHostApiImpl.WebStorageCreator()));
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;
    setUp(
        binding.getBinaryMessenger(),
        binding.getPlatformViewRegistry(),
        binding.getApplicationContext(),
        null,
        new FlutterAssetManager.PluginBindingFlutterAssetManager(
            binding.getApplicationContext().getAssets(), binding.getFlutterAssets()));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    instanceManager.close();
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
    updateContext(activityPluginBinding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    updateContext(pluginBinding.getApplicationContext());
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding activityPluginBinding) {
    updateContext(activityPluginBinding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    updateContext(pluginBinding.getApplicationContext());
  }

  private void updateContext(Context context) {
    webViewHostApi.setContext(context);
    javaScriptChannelHostApi.setPlatformThreadHandler(new Handler(context.getMainLooper()));
  }

  /** Maintains instances used to communicate with the corresponding objects in Dart. */
  @Nullable
  public InstanceManager getInstanceManager() {
    return instanceManager;
  }
}
JAVA2_EOF
  echo "[patch] WebViewFlutterPlugin.java 수정 완료"
  PATCHED=1
fi

if [ $PATCHED -eq 0 ]; then
  echo "[patch] 이미 모든 패치가 적용되어 있습니다."
fi

echo "[patch] 완료. 'flutter build apk --debug'로 빌드해 보세요."

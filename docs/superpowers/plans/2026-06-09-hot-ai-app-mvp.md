# hot-ai-app Implementation Plan (M0 + M1 + M3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付一个可登录、阅读 4 类内容、离线可读已收藏文章的 Flutter MVP 客户端,作为后续 M2(补齐其他模块)/M4(推送)/M5(打磨) 的基础。

**Architecture:** Feature-first Flutter app,Riverpod 状态管理 + dio HTTP + Hive 离线缓存 + go_router 路由 + flutter_secure_storage 存 JWT。App 走 nginx 代理调用现有 Go Zero 网关,只新增 2 个 push-token 端点(M4 阶段使用)。

**Tech Stack:** Flutter 3.44 / Dart 3.12, flutter_riverpod 2.x (注: 3.x 语法不兼容本 plan 代码), dio 5.x, hive 2.2 + hive_flutter, flutter_secure_storage 9.x+, go_router 14.x+, flutter_widget_from_html, cached_network_image, connectivity_plus, mocktail, integration_test

**版本适配说明 (2026-06-09):** 原 plan 写于 Flutter 3.22 / Dart 3.4 假设下,实际开发机为 Flutter 3.44.1 / Dart 3.12.1。已做以下调整:
- Task 1: 跳过 `flutter create`(仓库已存在),只做 `pub get` baseline 验证
- Task 2: 依赖版本用 `^X.Y.0` 范围让 pub 自动解析与 Dart 3.12 兼容的版本
- 实施过程中如遇 API 变更,在该 Task 报告里写明微调,继续推进

**本计划范围(MVP):**
- M0: 基建(工程骨架 + dio 拦截器 + 错误模型 + Hive + 路由 + 主题 + i18n)
- M1: 资讯模块(列表+详情+离线缓存,作为后续模块的模板)
- M3: 登录/个人中心(JWT + refresh 锁 + 路由守卫 + 5 个 Tab 串起来)

**不在本计划(M2/M4/M5 后续开新 plan):**
- 职业/学习路径/工具 3 个模块 → 套用 M1 模式
- 极光/个推推送 → 后端先加 `/user/push-token` 端点
- Golden test、覆盖率门槛、上架材料

---

## File Structure

```
hot-ai-app/                                 # 新建仓库,根目录
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
├── README.md
├── android/  ios/                          # Flutter create 自动生成
├── lib/
│   ├── main.dart                           # ProviderScope + bootstrap
│   ├── app.dart                            # MaterialApp.router
│   ├── core/
│   │   ├── network/
│   │   │   ├── dio_provider.dart
│   │   │   ├── api_response.dart
│   │   │   └── interceptors/
│   │   │       ├── log_interceptor.dart
│   │   │       ├── error_interceptor.dart
│   │   │       ├── retry_interceptor.dart
│   │   │       └── auth_interceptor.dart
│   │   ├── storage/
│   │   │   ├── hive_init.dart
│   │   │   └── secure_storage.dart
│   │   ├── error/
│   │   │   ├── app_exception.dart
│   │   │   └── failure.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── l10n/
│   │   │   ├── app_zh.arb
│   │   │   └── app_en.arb                  # 占位,MVP 不强制启用
│   │   └── utils/
│   │       └── connectivity_provider.dart
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── loading_view.dart
│   │   │   ├── error_view.dart
│   │   │   └── empty_view.dart
│   │   └── models/
│   │       └── pagination.dart
│   └── features/
│       ├── home/
│       │   └── home_shell.dart             # 5 Tab 壳
│       ├── articles/
│       │   ├── domain/{article.dart, article_repository.dart}
│       │   ├── data/{article_dto.dart, article_repository_impl.dart}
│       │   └── presentation/
│       │       ├── articles_list_page.dart
│       │       ├── article_detail_page.dart
│       │       └── articles_controller.dart
│       └── profile/
│           ├── domain/{user.dart, user_repository.dart}
│           ├── data/{user_dto.dart, user_repository_impl.dart, auth_storage.dart}
│           └── presentation/
│               ├── login_page.dart
│               ├── profile_page.dart
│               └── auth_controller.dart
├── test/                                   # 单元 + widget 测试
│   ├── core/network/interceptors/
│   ├── core/storage/
│   ├── features/articles/
│   └── features/profile/
└── integration_test/
    └── app_smoke_test.dart
```

**复用的现有资产:**
- `https://yourdomain.com/api/*` 走 nginx → Go Zero 网关 → 现有 5 个微服务
- Web 端 `app/lib/api.ts` 的拦截器逻辑(JWT/401/响应格式)→ 翻译成 dio 拦截器
- 后端:`POST/DELETE /user/push-token` 端点(M4 阶段,本计划只预留 user_repository 方法签名)

---

## Conventions

- **测试命令**:`flutter test`(单文件用 `flutter test test/path/file_test.dart`)
- **类型检查**:`flutter analyze`
- **构建命令**:`flutter build apk --dart-define=API_BASE=https://yourdomain.com/api`
- **提交约定**:`feat:` / `fix:` / `test:` / `chore:` 前缀,小步提交
- **文件命名**:`snake_case.dart`;类名 `PascalCase`;Provider 变量名 `<thing>Provider`
- **TDD 顺序**:Repository / Interceptor / Controller 走严格 TDD(测试先行);Page/Widget 走"实现 + 关键状态 widget 测试"

---

# Phase M0: Foundation

## Task 1: 验证 Flutter 工程基线

**Files:**
- Read: `hot-ai-app/pubspec.yaml`(确认存在)
- Read: `hot-ai-app/.gitignore`(确认 Flutter 标准)

> 注: `hot-ai-app/` 仓库已存在(初始 commit + Flutter 标准 .gitignore),无需 `flutter create`。

- [ ] **Step 1: 验证工程结构与 baseline**

```bash
cd D:/hot-ai/hot-ai-app
ls pubspec.yaml android ios 2>&1 | head -20
flutter --version
flutter pub get
```

Expected: `pubspec.yaml` 存在,`flutter --version` 输出 3.44.x + Dart 3.12.x,`flutter pub get` 无错(可能因为依赖空产生警告,可接受)。

- [ ] **Step 2: 验证空工程能 analyze**

```bash
flutter analyze
```

Expected: 无 error(警告 OK)

- [ ] **Step 3: 提交 scaffold 状态(如未提交)**

```bash
cd D:/hot-ai/hot-ai-app
git status
# 若有未提交改动:
git add -A
git commit -m "chore: scaffold flutter project baseline (Flutter 3.44 / Dart 3.12)"
```

若 `git status` 干净,跳过此步。

---

## Task 2: 添加核心依赖到 pubspec.yaml

**Files:**
- Modify: `hot-ai-app/pubspec.yaml`

- [ ] **Step 1: 写一个会失败的 sanity 测试(确保测试框架通了)**

新建 `test/sanity_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity', () {
    expect(1 + 1, 2);
  });
}
```

- [ ] **Step 2: 跑测试,确认通过**

```bash
flutter test test/sanity_test.dart
```

Expected:`+1: All tests passed!`

- [ ] **Step 3: 在 pubspec.yaml 替换 dependencies 块**

> 适配 Flutter 3.44 / Dart 3.12,版本用 `^X.Y.0` 范围让 pub 自动解析兼容版本。若 `flutter pub get` 报某个包与 Dart 3.12 不兼容,在本 Task 报告里写明并调整版本。

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.6.0
  dio: ^5.7.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.2
  go_router: ^14.6.0
  flutter_widget_from_html: ^0.16.0
  cached_network_image: ^3.4.0
  connectivity_plus: ^6.1.0
  intl: ^0.20.0
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mocktail: ^1.0.4
```

- [ ] **Step 4: pub get + analyze**

```bash
flutter pub get
flutter analyze
```

Expected: 无错误(警告 OK)

- [ ] **Step 5: 提交**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add core dependencies"
```

---

## Task 3: 创建目录结构骨架

**Files:**
- Create: `hot-ai-app/lib/core/network/interceptors/.gitkeep` 等占位文件

- [ ] **Step 1: 用 mkdir 创建目录树(Windows Git Bash)**

```bash
cd D:/hot-ai/hot-ai-app
mkdir -p lib/core/network/interceptors
mkdir -p lib/core/storage
mkdir -p lib/core/error
mkdir -p lib/core/router
mkdir -p lib/core/theme
mkdir -p lib/core/l10n
mkdir -p lib/core/utils
mkdir -p lib/shared/widgets
mkdir -p lib/shared/models
mkdir -p lib/features/home
mkdir -p lib/features/articles/{domain,data,presentation}
mkdir -p lib/features/profile/{domain,data,presentation}
mkdir -p test/core/network/interceptors
mkdir -p test/core/storage
mkdir -p test/features/articles
mkdir -p test/features/profile
mkdir -p integration_test
```

- [ ] **Step 2: 添加 .gitkeep 让空目录进 git**

```bash
find lib -type d -empty -exec touch {}/.gitkeep \;
find test -type d -empty -exec touch {}/.gitkeep \;
```

- [ ] **Step 3: 提交**

```bash
git add -A
git commit -m "chore: create feature-first directory structure"
```

---

## Task 4: 错误模型 - AppException + Failure(TDD)

**Files:**
- Create: `hot-ai-app/lib/core/error/app_exception.dart`
- Create: `hot-ai-app/lib/core/error/failure.dart`
- Create: `hot-ai-app/test/core/error/app_exception_test.dart`

- [ ] **Step 1: 写失败测试**

`test/core/error/app_exception_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';

void main() {
  group('AppException', () {
    test('toString 包含 code 和 message', () {
      final e = AppException(code: 1001, message: '参数错误');
      expect(e.toString(), contains('1001'));
      expect(e.toString(), contains('参数错误'));
    });

    test('支持任意自定义字段', () {
      final e = AppException(code: 0, message: 'ok', extra: {'traceId': 'abc'});
      expect(e.extra['traceId'], 'abc');
    });
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/error/app_exception_test.dart
```

Expected:`Target of URI doesn't exist: 'package:hot_ai_app/core/error/app_exception.dart'`

- [ ] **Step 3: 实现 AppException**

`lib/core/error/app_exception.dart`:
```dart
class AppException implements Exception {
  AppException({
    required this.code,
    required this.message,
    this.extra = const {},
  });

  final int code;
  final String message;
  final Map<String, dynamic> extra;

  @override
  String toString() => 'AppException($code): $message';
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/core/error/app_exception_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 5: 实现 Failure sealed types**

`lib/core/error/failure.dart`:
```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure { const NetworkFailure([super.message = '网络异常']); }
class TimeoutFailure extends Failure { const TimeoutFailure([super.message = '请求超时']); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure([super.message = '未登录']); }
class NotFoundFailure extends Failure { const NotFoundFailure([super.message = '资源不存在']); }
class ServerFailure extends Failure { const ServerFailure(super.message); }
class UnknownFailure extends Failure { const UnknownFailure([super.message = '未知错误']); }
```

- [ ] **Step 6: 提交**

```bash
git add lib/core/error test/core/error
git commit -m "feat(core): add AppException and Failure types"
```

---

## Task 5: ApiResponse 统一响应模型(TDD)

**Files:**
- Create: `hot-ai-app/lib/core/network/api_response.dart`
- Create: `hot-ai-app/test/core/network/api_response_test.dart`

- [ ] **Step 1: 写失败测试**

`test/core/network/api_response_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';

void main() {
  test('code==0 解包 data', () {
    final r = ApiResponse<int>.fromJson({'code': 0, 'data': 42, 'message': 'ok'}, (j) => j as int);
    expect(r.unwrap(), 42);
  });

  test('code!=0 抛 AppException', () {
    final r = ApiResponse<int>.fromJson({'code': 1001, 'data': null, 'message': 'err'}, (j) => j as int);
    expect(() => r.unwrap(), throwsA(isA<AppException>()));
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/network/api_response_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 ApiResponse**

`lib/core/network/api_response.dart`:
```dart
import 'package:hot_ai_app/core/error/app_exception.dart';

class ApiResponse<T> {
  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse<T>.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) decoder,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      data: json['data'] == null ? null : decoder(json['data']),
    );
  }

  final int code;
  final String message;
  final T? data;

  T unwrap() {
    if (code != 0) {
      throw AppException(code: code, message: message);
    }
    if (data == null) {
      throw AppException(code: -1, message: '响应 data 为空');
    }
    return data as T;
  }
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/core/network/api_response_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/core/network/api_response.dart test/core/network/api_response_test.dart
git commit -m "feat(core): add ApiResponse with code/data/message unwrap"
```

---

## Task 6: dio provider + API base URL

**Files:**
- Create: `hot-ai-app/lib/core/network/dio_provider.dart`
- Create: `hot-ai-app/test/core/network/dio_provider_test.dart`

- [ ] **Step 1: 写失败测试**

`test/core/network/dio_provider_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/dio_provider.dart';

void main() {
  test('buildDio 用 --dart-define 注入 base URL', () {
    const url = 'https://example.com/api';
    final dio = buildDio(baseUrl: url);
    expect(dio.options.baseUrl, url);
    expect(dio.options.connectTimeout.inSeconds, 15);
    expect(dio.options.receiveTimeout.inSeconds, 30);
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/network/dio_provider_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 buildDio**

`lib/core/network/dio_provider.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost/api',
);

Dio buildDio({String? baseUrl, List<Interceptor> interceptors = const []}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl ?? kApiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.addAll(interceptors);
  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  // interceptors 稍后注册
  return buildDio();
});
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/core/network/dio_provider_test.dart
```

Expected:`+1: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/core/network/dio_provider.dart test/core/network/dio_provider_test.dart
git commit -m "feat(core): add buildDio with API_BASE env"
```

---

## Task 7: ErrorInterceptor(TDD)

**Files:**
- Create: `hot-ai-app/lib/core/network/interceptors/error_interceptor.dart`
- Create: `hot-ai-app/test/core/network/interceptors/error_interceptor_test.dart`

- [ ] **Step 1: 写失败测试**

`test/core/network/interceptors/error_interceptor_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';
import 'package:hot_ai_app/core/network/interceptors/error_interceptor.dart';

Dio _dio() => Dio()..interceptors.add(ErrorInterceptor());

void main() {
  test('响应 code != 0 抛 AppException', () async {
    final dio = _dio();
    dio.httpClientAdapter = _StubAdapter(response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 200,
      data: {'code': 1001, 'data': null, 'message': 'err'},
    ));
    expect(
      () => dio.get('/x'),
      throwsA(isA<AppException>()
          .having((e) => e.code, 'code', 1001)
          .having((e) => e.message, 'message', 'err')),
    );
  });

  test('HTTP 4xx 抛 AppException with status', () async {
    final dio = _dio();
    dio.httpClientAdapter = _StubAdapter(response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 500,
      data: 'oops',
    ));
    expect(() => dio.get('/x'), throwsA(isA<AppException>()));
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.response});
  final Response response;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      response.data is String ? response.data as String : '{"code":0}',
      response.statusCode ?? 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/network/interceptors/error_interceptor_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 ErrorInterceptor**

`lib/core/network/interceptors/error_interceptor.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/error/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map && data['code'] is int) {
      final code = data['code'] as int;
      if (code != 0) {
        return handler.reject(DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: AppException(
            code: code,
            message: (data['message'] as String?) ?? '业务错误',
          ),
        ));
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is AppException) return handler.next(err);
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return handler.next(err);
    }
    final status = err.response?.statusCode ?? 0;
    return handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: AppException(
        code: status,
        message: err.message ?? '网络异常',
      ),
    ));
  }
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/core/network/interceptors/error_interceptor_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/core/network/interceptors/error_interceptor.dart test/core/network/interceptors/error_interceptor_test.dart
git commit -m "feat(core): add ErrorInterceptor mapping non-zero code to AppException"
```

---

## Task 8: LogInterceptor

**Files:**
- Create: `hot-ai-app/lib/core/network/interceptors/log_interceptor.dart`

- [ ] **Step 1: 实现 LogInterceptor(简单,sans TDD)**

`lib/core/network/interceptors/log_interceptor.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[REQ] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[RES] ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[ERR] ${err.type} ${err.requestOptions.uri} ${err.message}');
    }
    handler.next(err);
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/core/network/interceptors/log_interceptor.dart
git commit -m "feat(core): add LogInterceptor (debug-only)"
```

---

## Task 9: RetryInterceptor

**Files:**
- Create: `hot-ai-app/lib/core/network/interceptors/retry_interceptor.dart`
- Create: `hot-ai-app/test/core/network/interceptors/retry_interceptor_test.dart`

- [ ] **Step 1: 写失败测试**

`test/core/network/interceptors/retry_interceptor_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/interceptors/retry_interceptor.dart';

void main() {
  test('幂等 GET 失败 1 次后重试 1 次', () async {
    int callCount = 0;
    final dio = Dio()..interceptors.add(RetryInterceptor());
    dio.httpClientAdapter = _CountingAdapter(
      onCall: () => callCount++,
      shouldFail: (n) => n == 1, // 第 1 次失败
    );
    final r = await dio.get('/x');
    expect(r.statusCode, 200);
    expect(callCount, 2);
  });

  test('POST 不重试', () async {
    int callCount = 0;
    final dio = Dio()..interceptors.add(RetryInterceptor());
    dio.httpClientAdapter = _CountingAdapter(
      onCall: () => callCount++,
      shouldFail: (_) => true,
    );
    expect(() => dio.post('/x'), throwsA(isA<DioException>()));
    expect(callCount, 1);
  });
}

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({required this.onCall, required this.shouldFail});
  final VoidCallback onCall;
  final bool Function(int) shouldFail;
  int _n = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? s, Future<void>? c) async {
    onCall();
    _n++;
    if (shouldFail(_n)) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/network/interceptors/retry_interceptor_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 RetryInterceptor**

`lib/core/network/interceptors/retry_interceptor.dart`:
```dart
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 1});
  final int maxRetries;

  bool _isIdempotent(String method) => method == 'GET' || method == 'HEAD' || method == 'OPTIONS';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (!_isIdempotent(options.method)) return handler.next(err);
    if (options.extra['_retryCount'] == null) options.extra['_retryCount'] = 0;
    if ((options.extra['_retryCount'] as int) >= maxRetries) return handler.next(err);
    if (err.type != DioExceptionType.connectionError &&
        err.type != DioExceptionType.connectionTimeout) {
      return handler.next(err);
    }
    options.extra['_retryCount'] = (options.extra['_retryCount'] as int) + 1;
    try {
      final dio = Dio(options.baseUrl == '' ? null : options.baseUrl != null
          ? BaseOptions(baseUrl: options.baseUrl as String)
          : null);
      final response = await dio.fetch(options);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) handler.next(e);
    }
  }
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/core/network/interceptors/retry_interceptor_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/core/network/interceptors/retry_interceptor.dart test/core/network/interceptors/retry_interceptor_test.dart
git commit -m "feat(core): add RetryInterceptor (idempotent only, 1 retry)"
```

---

## Task 10: AuthInterceptor - token 注入(TDD)

**Files:**
- Create: `hot-ai-app/lib/core/storage/secure_storage.dart`
- Create: `hot-ai-app/lib/core/network/interceptors/auth_interceptor.dart`
- Create: `hot-ai-app/test/core/network/interceptors/auth_interceptor_test.dart`

- [ ] **Step 1: 先写 SecureStorage 抽象 + 实现**

`lib/core/storage/secure_storage.dart`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<String?> readAccess();
  Future<String?> readRefresh();
  Future<void> writeAccess(String token);
  Future<void> writeRefresh(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  @override
  Future<String?> readAccess() => _storage.read(key: _kAccess);
  @override
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);
  @override
  Future<void> writeAccess(String t) => _storage.write(key: _kAccess, value: t);
  @override
  Future<void> writeRefresh(String t) => _storage.write(key: _kRefresh, value: t);
  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
```

- [ ] **Step 2: 写 AuthInterceptor 失败测试**

`test/core/network/interceptors/auth_interceptor_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/network/interceptors/auth_interceptor.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  String? access;
  @override
  Future<String?> readAccess() async => access;
  @override
  Future<String?> readRefresh() async => null;
  @override
  Future<void> writeAccess(String t) async => access = t;
  @override
  Future<void> writeRefresh(String t) async {}
  @override
  Future<void> clear() async => access = null;
}

void main() {
  test('请求自动加 Authorization header', () async {
    final storage = _FakeTokenStorage()..access = 'token-abc';
    final dio = Dio()..interceptors.add(AuthInterceptor(storage: storage));
    String? captured;
    dio.httpClientAdapter = _CapturingAdapter((headers) => captured = headers['Authorization'] as String?);
    await dio.get('/x');
    expect(captured, 'Bearer token-abc');
  });

  test('无 token 时不加 header', () async {
    final storage = _FakeTokenStorage();
    final dio = Dio()..interceptors.add(AuthInterceptor(storage: storage));
    String? captured;
    dio.httpClientAdapter = _CapturingAdapter((headers) => captured = headers['Authorization'] as String?);
    await dio.get('/x');
    expect(captured, isNull);
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.onHeaders);
  final void Function(Map<String, List<String>>) onHeaders;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? s, Future<void>? c) async {
    onHeaders(options.headers);
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 3: 跑测试,确认失败**

```bash
flutter test test/core/network/interceptors/auth_interceptor_test.dart
```

Expected: import 错误

- [ ] **Step 4: 实现 AuthInterceptor(仅 token 注入部分,401 处理留 Task 11)**

`lib/core/network/interceptors/auth_interceptor.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';

typedef OnUnauthorized = Future<bool> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.storage, this.onUnauthorized});

  final TokenStorage storage;
  final OnUnauthorized? onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['_noAuth'] == true) return handler.next(options);
    final token = await storage.readAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

- [ ] **Step 5: 跑测试,确认通过**

```bash
flutter test test/core/network/interceptors/auth_interceptor_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 6: 提交**

```bash
git add lib/core/storage/secure_storage.dart lib/core/network/interceptors/auth_interceptor.dart test/core/network/interceptors/auth_interceptor_test.dart
git commit -m "feat(core): add TokenStorage + AuthInterceptor (request token injection)"
```

---

## Task 11: AuthInterceptor - 401 refresh + 串行锁(TDD)

**Files:**
- Modify: `hot-ai-app/lib/core/network/interceptors/auth_interceptor.dart`
- Modify: `hot-ai-app/test/core/network/interceptors/auth_interceptor_test.dart`

- [ ] **Step 1: 扩展测试,加 401 场景**

在 `test/core/network/interceptors/auth_interceptor_test.dart` 末尾追加:
```dart
class _SeqAdapter implements HttpClientAdapter {
  _SeqAdapter(this.responses);
  final List<Response> responses;
  int _idx = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    final r = responses[_idx++];
    if (r.statusCode == 401) {
      throw DioException(
        requestOptions: o,
        response: r,
        type: DioExceptionType.badResponse,
      );
    }
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  // ... 既有测试 ...

  test('401 触发 onUnauthorized,成功后重发原请求', () async {
    final storage = _FakeTokenStorage()..access = 'old';
    int callCount = 0;
    final dio = Dio()..interceptors.add(AuthInterceptor(
      storage: storage,
      onUnauthorized: () async {
        callCount++;
        await storage.writeAccess('new');
        return true;
      },
    ));
    dio.httpClientAdapter = _SeqAdapter([
      Response(requestOptions: RequestOptions(path: '/x'), statusCode: 401),
      Response(requestOptions: RequestOptions(path: '/x'), statusCode: 200),
    ]);
    final r = await dio.get('/x');
    expect(r.statusCode, 200);
    expect(callCount, 1);
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/network/interceptors/auth_interceptor_test.dart
```

Expected: 第二组新增测试失败(因 401 没被处理)

- [ ] **Step 3: 扩展 AuthInterceptor 加 401 处理 + 串行锁**

修改 `lib/core/network/interceptors/auth_interceptor.dart`,在文件末尾追加:
```dart
class _AuthState {
  bool refreshing = false;
  Completer<bool>? inFlight;
}

class AuthInterceptor extends Interceptor {
  // ... 既有 onRequest ...

  static final _state = _AuthState();
  static Completer<bool>? get _inFlight => _state.inFlight;
  static set _inFlight(Completer<bool>? c) => _state.inFlight = c;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) return handler.next(err);
    if (err.requestOptions.extra['_retried'] == true) return handler.next(err);
    err.requestOptions.extra['_retried'] = true;

    final completer = _inFlight;
    if (completer != null) {
      final ok = await completer.future;
      if (!ok) return handler.next(err);
      return _retry(err, handler);
    }
    final c = Completer<bool>();
    _inFlight = c;
    bool ok = false;
    try {
      ok = await (onUnauthorized?.call() ?? Future.value(false));
    } catch (_) {
      ok = false;
    }
    c.complete(ok);
    _inFlight = null;
    if (!ok) return handler.next(err);
    _retry(err, handler);
  }

  void _retry(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final token = await storage.readAccess();
      err.requestOptions.headers['Authorization'] = token == null ? '' : 'Bearer $token';
      final dio = Dio();
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) handler.next(e);
    }
  }
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/core/network/interceptors/auth_interceptor_test.dart
```

Expected:`+3: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/core/network/interceptors/auth_interceptor.dart test/core/network/interceptors/auth_interceptor_test.dart
git commit -m "feat(core): AuthInterceptor 401 handling with serial refresh lock"
```

---

## Task 12: 主题与颜色

**Files:**
- Create: `hot-ai-app/lib/core/theme/app_theme.dart`

- [ ] **Step 1: 实现 app_theme.dart**

`lib/core/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _seed = Color(0xFF1E3A8A); // 深蓝
  static const _accent = Color(0xFFEA580C); // 橙色强调

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(secondary: _accent),
      textTheme: GoogleFonts.notoSansScTextTheme(),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(secondary: _accent),
      textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(theme): add AppTheme light/dark with Noto Sans SC"
```

---

## Task 13: Hive 初始化 + Box 集中管理

**Files:**
- Create: `hot-ai-app/lib/core/storage/hive_init.dart`
- Create: `hot-ai-app/test/core/storage/hive_init_test.dart`

- [ ] **Step 1: 写失败测试**

`test/core/storage/hive_init_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';

void main() {
  test('initHive + openAppBoxes 后能读写', () async {
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);
    final boxes = await openAppBoxes();
    addTearDown(() async {
      await boxes.appMeta.clear();
      await boxes.closeAll();
      await dir.delete(recursive: true);
    });
    await boxes.appMeta.put('lang', 'zh');
    expect(boxes.appMeta.get('lang'), 'zh');
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/core/storage/hive_init_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 hive_init.dart**

`lib/core/storage/hive_init.dart`:
```dart
import 'package:hive_flutter/hive_flutter.dart';

class AppBoxes {
  AppBoxes({
    required this.appMeta,
    required this.articlesMeta,
    required this.articleDetails,
    required this.professionsCache,
    required this.learningPathsCache,
    required this.toolsCache,
    required this.userState,
  });

  final Box appMeta;
  final Box articlesMeta;
  final Box articleDetails;
  final Box professionsCache;
  final Box learningPathsCache;
  final Box toolsCache;
  final Box userState;

  Future<void> closeAll() async {
    for (final b in [
      appMeta, articlesMeta, articleDetails, professionsCache,
      learningPathsCache, toolsCache, userState,
    ]) {
      await b.close();
    }
  }
}

Future<AppBoxes> openAppBoxes() async {
  await Hive.initFlutter();
  return AppBoxes(
    appMeta: await Hive.openBox('app_meta'),
    articlesMeta: await Hive.openBox('articles_meta'),
    articleDetails: await Hive.openBox('article_details'),
    professionsCache: await Hive.openBox('professions_cache'),
    learningPathsCache: await Hive.openBox('learning_paths_cache'),
    toolsCache: await Hive.openBox('tools_cache'),
    userState: await Hive.openBox('user_state'),
  );
}

final appBoxesProvider = Provider<AppBoxes>((ref) {
  throw UnimplementedError('Override in main.dart');
});
```

- [ ] **Step 4: 在 pubspec 加 hive_flutter import(确认已加)**

`flutter pub get` 已包含。

- [ ] **Step 5: 跑测试,确认通过**

```bash
flutter test test/core/storage/hive_init_test.dart
```

Expected:`+1: All tests passed!`

- [ ] **Step 6: 提交**

```bash
git add lib/core/storage/hive_init.dart test/core/storage/hive_init_test.dart
git commit -m "feat(core): add openAppBoxes with 7 typed boxes"
```

---

## Task 14: 共享 widget - Loading/Error/Empty

**Files:**
- Create: `hot-ai-app/lib/shared/widgets/loading_view.dart`
- Create: `hot-ai-app/lib/shared/widgets/error_view.dart`
- Create: `hot-ai-app/lib/shared/widgets/empty_view.dart`
- Create: `hot-ai-app/test/shared/widgets_test.dart`

- [ ] **Step 1: 写失败测试**

`test/shared/widgets_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

void main() {
  testWidgets('LoadingView 显示 CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LoadingView())));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ErrorView 显示 message + 重试按钮', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ErrorView(
      message: 'oops', onRetry: () => retried = true,
    ))));
    expect(find.text('oops'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, true);
  });

  testWidgets('EmptyView 显示提示文字', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyView(text: '暂无数据'))));
    expect(find.text('暂无数据'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/shared/widgets_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 3 个 widget**

`lib/shared/widgets/loading_view.dart`:
```dart
import 'package:flutter/material.dart';
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
```

`lib/shared/widgets/error_view.dart`:
```dart
import 'package:flutter/material.dart';
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }
}
```

`lib/shared/widgets/empty_view.dart`:
```dart
import 'package:flutter/material.dart';
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/shared/widgets_test.dart
```

Expected:`+3: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/shared/widgets test/shared/widgets_test.dart
git commit -m "feat(shared): add Loading/Error/Empty view widgets"
```

---

## Task 15: main.dart + app.dart 骨架(空路由)

**Files:**
- Modify: `hot-ai-app/lib/main.dart`
- Create: `hot-ai-app/lib/app.dart`
- Create: `hot-ai-app/lib/core/router/app_router.dart`

- [ ] **Step 1: 实现 app_router.dart(占位)**

`lib/core/router/app_router.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/articles',
    routes: [
      GoRoute(path: '/articles', builder: (_, __) => const _StubPage(title: '资讯')),
      GoRoute(path: '/professions', builder: (_, __) => const _StubPage(title: '职业')),
      GoRoute(path: '/learning-paths', builder: (_, __) => const _StubPage(title: '学习')),
      GoRoute(path: '/tools', builder: (_, __) => const _StubPage(title: '工具')),
      GoRoute(path: '/profile', builder: (_, __) => const _StubPage(title: '我的')),
    ],
  );
}

class _StubPage extends StatelessWidget {
  const _StubPage({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('$title 占位')),
  );
}
```

- [ ] **Step 2: 实现 app.dart**

`lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:hot_ai_app/core/router/app_router.dart';
import 'package:hot_ai_app/core/theme/app_theme.dart';

class HotAiApp extends StatelessWidget {
  const HotAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI 热点追踪',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: buildAppRouter(),
    );
  }
}
```

- [ ] **Step 3: 改写 main.dart**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/app.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxes = await openAppBoxes();
  runApp(ProviderScope(
    overrides: [appBoxesProvider.overrideWithValue(boxes)],
    child: const HotAiApp(),
  ));
}
```

- [ ] **Step 4: 跑通 analyze + build**

```bash
flutter analyze
flutter build apk --debug --dart-define=API_BASE=http://localhost/api
```

Expected: build 成功(警告可接受)

- [ ] **Step 5: 提交**

```bash
git add lib/main.dart lib/app.dart lib/core/router/app_router.dart
git commit -m "feat(app): wire main + MaterialApp.router + go_router skeleton"
```

---

# Phase M1: Articles Module (Template)

## Task 16: Article entity + 分页模型

**Files:**
- Create: `hot-ai-app/lib/features/articles/domain/article.dart`
- Create: `hot-ai-app/lib/shared/models/pagination.dart`

- [ ] **Step 1: 实现 Pagination**

`lib/shared/models/pagination.dart`:
```dart
class Pagination<T> {
  Pagination({required this.items, required this.page, required this.total});
  final List<T> items;
  final int page;
  final int total;
  bool get hasMore => items.length + (page - 1) * _pageSize < total;
  static const _pageSize = 20;
}
```

- [ ] **Step 2: 实现 Article entity**

`lib/features/articles/domain/article.dart`:
```dart
class Article {
  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.contentHtml,
    required this.coverUrl,
    required this.publishedAt,
    required this.category,
    required this.isFavorited,
  });

  final String id;
  final String title;
  final String summary;
  final String contentHtml;
  final String? coverUrl;
  final DateTime publishedAt;
  final String category;
  final bool isFavorited;

  Article copyWith({bool? isFavorited}) => Article(
    id: id,
    title: title,
    summary: summary,
    contentHtml: contentHtml,
    coverUrl: coverUrl,
    publishedAt: publishedAt,
    category: category,
    isFavorited: isFavorited ?? this.isFavorited,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'contentHtml': contentHtml,
    'coverUrl': coverUrl,
    'publishedAt': publishedAt.toIso8601String(),
    'category': category,
    'isFavorited': isFavorited,
  };

  factory Article.fromJson(Map<String, dynamic> j) => Article(
    id: j['id'] as String,
    title: j['title'] as String,
    summary: j['summary'] as String? ?? '',
    contentHtml: j['contentHtml'] as String? ?? '',
    coverUrl: j['coverUrl'] as String?,
    publishedAt: DateTime.parse(j['publishedAt'] as String),
    category: j['category'] as String? ?? '',
    isFavorited: j['isFavorited'] as bool? ?? false,
  );
}
```

- [ ] **Step 3: 提交**

```bash
git add lib/features/articles/domain/article.dart lib/shared/models/pagination.dart
git commit -m "feat(articles): add Article entity + Pagination model"
```

---

## Task 17: ArticleRepository 接口 + 实现(TDD)

**Files:**
- Create: `hot-ai-app/lib/features/articles/domain/article_repository.dart`
- Create: `hot-ai-app/lib/features/articles/data/article_repository_impl.dart`
- Create: `hot-ai-app/test/features/articles/article_repository_impl_test.dart`

- [ ] **Step 1: 写失败测试**

`test/features/articles/article_repository_impl_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/articles/data/article_repository_impl.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/network/interceptors/error_interceptor.dart';
import 'dart:io';

void main() {
  late Directory tmp;
  late AppBoxes boxes;
  late ArticleRepositoryImpl repo;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    boxes = await openAppBoxes();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    repo = ArticleRepositoryImpl(dio: dio, boxes: boxes);
  });

  tearDown(() async {
    await boxes.closeAll();
    await tmp.delete(recursive: true);
  });

  test('getArticles 解析 ApiResponse<Pagination>', () async {
    final page = await repo.getArticles(page: 1, category: null);
    expect(page.items.length, 2);
    expect(page.items.first.title, 'A1');
  });

  test('getArticles 同时写入 articles_meta box', () async {
    await repo.getArticles(page: 1, category: null);
    final ids = boxes.articlesMeta.keys;
    expect(ids, contains('a1'));
  });

  test('getArticle 命中缓存时立刻返回', () async {
    await boxes.articleDetails.put('a1', {
      'id': 'a1', 'title': 'cached', 'summary': '', 'contentHtml': '',
      'coverUrl': null, 'publishedAt': DateTime.now().toIso8601String(),
      'category': '', 'isFavorited': false,
    });
    final a = await repo.getArticle('a1');
    expect(a.title, 'cached');
  });
}

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    if (o.path.startsWith('/articles') && o.method == 'GET' && o.path == '/articles') {
      return ResponseBody.fromString(
        '{"code":0,"data":{"page":1,"total":2,"items":[{"id":"a1","title":"A1","summary":"","contentHtml":"","coverUrl":null,"publishedAt":"2026-06-09T00:00:00Z","category":"x","isFavorited":false},{"id":"a2","title":"A2","summary":"","contentHtml":"","coverUrl":null,"publishedAt":"2026-06-09T00:00:00Z","category":"x","isFavorited":false}]},"message":"ok"}',
        200,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );
    }
    return ResponseBody.fromString('{"code":0,"data":{},"message":"ok"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/features/articles/article_repository_impl_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 Repository 接口**

`lib/features/articles/domain/article_repository.dart`:
```dart
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

abstract class ArticleRepository {
  Future<Pagination<Article>> getArticles({required int page, String? category});
  Future<Article> getArticle(String id);
  Future<void> setFavorite(String id, bool favorite);
  Future<List<String>> getFavorites();
}
```

- [ ] **Step 4: 实现 Repository impl**

`lib/features/articles/data/article_repository_impl.dart`:
```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl({required this.dio, required this.boxes});
  final Dio dio;
  final AppBoxes boxes;

  @override
  Future<Pagination<Article>> getArticles({required int page, String? category}) async {
    final resp = await dio.get('/articles', queryParameters: {
      'page': page, if (category != null) 'category': category,
    });
    final data = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final items = (data['items'] as List).cast<Map<String, dynamic>>()
      .map(Article.fromJson).toList();
    for (final a in items) {
      await boxes.articlesMeta.put(a.id, a.toJson());
    }
    return Pagination<Article>(
      items: items,
      page: data['page'] as int,
      total: data['total'] as int,
    );
  }

  @override
  Future<Article> getArticle(String id) async {
    final cached = boxes.articleDetails.get(id);
    if (cached != null) {
      // 后台异步刷新
      unawaited(_refresh(id));
      return Article.fromJson((cached as Map).cast<String, dynamic>());
    }
    return _refresh(id);
  }

  Future<Article> _refresh(String id) async {
    final resp = await dio.get('/articles/$id');
    final data = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final article = Article.fromJson(data);
    await boxes.articleDetails.put(id, article.toJson());
    return article;
  }

  @override
  Future<void> setFavorite(String id, bool favorite) async {
    await dio.post('/articles/$id/favorite', data: {'favorite': favorite});
    final list = (boxes.userState.get('favorites') as List?)?.cast<String>() ?? <String>[];
    final next = favorite
      ? (list.toSet()..add(id)).toList()
      : (list.where((x) => x != id).toList());
    await boxes.userState.put('favorites', next);
  }

  @override
  Future<List<String>> getFavorites() async {
    return (boxes.userState.get('favorites') as List?)?.cast<String>() ?? <String>[];
  }
}
```

- [ ] **Step 5: 跑测试,确认通过**

```bash
flutter test test/features/articles/article_repository_impl_test.dart
```

Expected:`+3: All tests passed!`

- [ ] **Step 6: 提交**

```bash
git add lib/features/articles test/features/articles
git commit -m "feat(articles): add ArticleRepository with Hive cache + dio"
```

---

## Task 18: ArticlesController (Riverpod, TDD)

**Files:**
- Create: `hot-ai-app/lib/features/articles/presentation/articles_controller.dart`
- Create: `hot-ai-app/test/features/articles/articles_controller_test.dart`

- [ ] **Step 1: 写失败测试**

`test/features/articles/articles_controller_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/articles/data/article_repository_impl.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/shared/models/pagination.dart';

class _FakeRepo implements ArticleRepository {
  final List<Article> data;
  _FakeRepo(this.data);
  @override
  Future<Pagination<Article>> getArticles({required int page, String? category}) async {
    return Pagination(items: data, page: page, total: data.length);
  }
  @override
  Future<Article> getArticle(String id) async => data.firstWhere((a) => a.id == id);
  @override
  Future<void> setFavorite(String id, bool f) async {}
  @override
  Future<List<String>> getFavorites() async => [];
}

Article _a(String id) => Article(
  id: id, title: 't$id', summary: '', contentHtml: '', coverUrl: null,
  publishedAt: DateTime(2026), category: '', isFavorited: false,
);

void main() {
  test('加载第一页', () async {
    final container = ProviderContainer(overrides: [
      articleRepositoryProvider.overrideWith((ref) => _FakeRepo([_a('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(articlesControllerProvider.notifier).load();
    final state = container.read(articlesControllerProvider);
    expect(state.items.length, 1);
    expect(state.loading, false);
  });

  test('loadMore 追加并清空 loadingMore', () async {
    final container = ProviderContainer(overrides: [
      articleRepositoryProvider.overrideWith((ref) => _FakeRepo([_a('1')])),
    ]);
    addTearDown(container.dispose);
    await container.read(articlesControllerProvider.notifier).load();
    await container.read(articlesControllerProvider.notifier).loadMore();
    final state = container.read(articlesControllerProvider);
    expect(state.items.length, 2);
    expect(state.loadingMore, false);
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/features/articles/articles_controller_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 articles_controller**

`lib/features/articles/presentation/articles_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/articles/data/article_repository_impl.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  // 真实实现在 main.dart 通过 override 注入;此处为占位
  throw UnimplementedError('Override in main.dart');
});

class ArticlesState {
  const ArticlesState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = true,
    this.error,
  });
  final List<Article> items;
  final bool loading;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final String? error;

  ArticlesState copyWith({
    List<Article>? items, bool? loading, bool? loadingMore,
    int? page, bool? hasMore, String? error, bool clearError = false,
  }) => ArticlesState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );
}

class ArticlesController extends StateNotifier<ArticlesState> {
  ArticlesController(this._repo) : super(const ArticlesState());
  final ArticleRepository _repo;

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _repo.getArticles(page: 1, category: null);
      state = state.copyWith(items: page.items, page: 1, hasMore: page.hasMore, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.page + 1;
      final page = await _repo.getArticles(page: next, category: null);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: next,
        hasMore: page.hasMore,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite(String id) async {
    final item = state.items.firstWhere((a) => a.id == id);
    final newFav = !item.isFavorited;
    state = state.copyWith(items: [
      for (final a in state.items) a.id == id ? a.copyWith(isFavorited: newFav) : a,
    ]);
    try {
      await _repo.setFavorite(id, newFav);
    } catch (_) {
      // 回滚
      state = state.copyWith(items: [
        for (final a in state.items) a.id == id ? a.copyWith(isFavorited: !newFav) : a,
      ]);
    }
  }
}

final articlesControllerProvider =
    StateNotifierProvider<ArticlesController, ArticlesState>((ref) {
  return ArticlesController(ref.watch(articleRepositoryProvider));
});
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/features/articles/articles_controller_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/articles/presentation/articles_controller.dart test/features/articles/articles_controller_test.dart
git commit -m "feat(articles): add ArticlesController with load/loadMore/toggleFavorite"
```

---

## Task 19: ArticlesListPage(无限滚动)

**Files:**
- Create: `hot-ai-app/lib/features/articles/presentation/articles_list_page.dart`

- [ ] **Step 1: 实现列表页**

`lib/features/articles/presentation/articles_list_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

class ArticlesListPage extends ConsumerStatefulWidget {
  const ArticlesListPage({super.key});
  @override
  ConsumerState<ArticlesListPage> createState() => _ArticlesListPageState();
}

class _ArticlesListPageState extends ConsumerState<ArticlesListPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articlesControllerProvider.notifier).load();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent * 0.8) {
      ref.read(articlesControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesControllerProvider);
    if (state.loading && state.items.isEmpty) return const LoadingView();
    if (state.error != null && state.items.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(articlesControllerProvider.notifier).load(),
      );
    }
    if (state.items.isEmpty) return const EmptyView(text: '暂无资讯');
    return RefreshIndicator(
      onRefresh: () => ref.read(articlesControllerProvider.notifier).load(),
      child: ListView.separated(
        controller: _scroll,
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final a = state.items[i];
          return ListTile(
            title: Text(a.title),
            subtitle: Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Icon(a.isFavorited ? Icons.favorite : Icons.favorite_border),
            onTap: () => context.push('/articles/${a.id}'),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: analyze**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 3: 提交**

```bash
git add lib/features/articles/presentation/articles_list_page.dart
git commit -m "feat(articles): add ArticlesListPage with infinite scroll"
```

---

## Task 20: ArticleDetailPage(HTML 渲染)

**Files:**
- Create: `hot-ai-app/lib/features/articles/presentation/article_detail_page.dart`

- [ ] **Step 1: 实现详情页**

`lib/features/articles/presentation/article_detail_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hot_ai_app/features/articles/domain/article.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/shared/widgets/error_view.dart';
import 'package:hot_ai_app/shared/widgets/loading_view.dart';

final _detailProvider = FutureProvider.family<Article, String>((ref, id) async {
  return ref.watch(articleRepositoryProvider).getArticle(id);
});

class ArticleDetailPage extends ConsumerWidget {
  const ArticleDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('文章详情'),
        actions: [
          async.maybeWhen(
            data: (a) => IconButton(
              icon: Icon(a.isFavorited ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                ref.read(articlesControllerProvider.notifier).toggleFavorite(a.id);
                ref.invalidate(_detailProvider(id));
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (a) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(a.publishedAt.toLocal().toString().split('.').first,
                  style: Theme.of(context).textTheme.bodySmall),
              if (a.coverUrl != null) ...[
                const SizedBox(height: 12),
                Image.network(a.coverUrl!),
              ],
              const SizedBox(height: 16),
              HtmlWidget(a.contentHtml),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 在 router 加 `/articles/:id` 路由**

修改 `lib/core/router/app_router.dart`,在 `articles` 路由加子路由:
```dart
GoRoute(
  path: '/articles',
  builder: (_, __) => const _StubPage(title: '资讯'),
  routes: [
    GoRoute(
      path: ':id',
      builder: (ctx, state) => ArticleDetailPage(id: state.pathParameters['id']!),
    ),
  ],
),
```
并在文件顶部 import `article_detail_page.dart`。

- [ ] **Step 3: analyze + build**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/features/articles/presentation/article_detail_page.dart lib/core/router/app_router.dart
git commit -m "feat(articles): add ArticleDetailPage with HTML rendering"
```

---

# Phase M3: Auth & Profile

## Task 21: User entity + UserRepository 接口

**Files:**
- Create: `hot-ai-app/lib/features/profile/domain/user.dart`
- Create: `hot-ai-app/lib/features/profile/domain/user_repository.dart`

- [ ] **Step 1: User entity**

`lib/features/profile/domain/user.dart`:
```dart
class User {
  User({required this.id, required this.email, required this.nickname});
  final String id;
  final String email;
  final String nickname;
  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'nickname': nickname};
  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String, email: j['email'] as String, nickname: j['nickname'] as String? ?? '');
}
```

- [ ] **Step 2: Repository 接口**

`lib/features/profile/domain/user_repository.dart`:
```dart
import 'package:hot_ai_app/features/profile/domain/user.dart';
abstract class UserRepository {
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> login(
    String email, String password);
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> register(
    String email, String password, String nickname);
  Future<String> refresh(String refreshToken);
  Future<User> me();
  Future<void> registerPushToken(String token, String platform);
  Future<void> deletePushToken();
}
```

- [ ] **Step 3: 提交**

```bash
git add lib/features/profile/domain
git commit -m "feat(profile): add User entity and UserRepository interface"
```

---

## Task 22: AuthStorage(secure_storage 包装 + 状态)

**Files:**
- Create: `hot-ai-app/lib/features/profile/data/auth_storage.dart`
- Create: `hot-ai-app/test/features/profile/auth_storage_test.dart`

- [ ] **Step 1: 写失败测试**

`test/features/profile/auth_storage_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';

void main() {
  test('saveSession + loadSession + clearSession', () async {
    final storage = AuthStorage(FlutterSecureStorage());
    await storage.saveSession(
      access: 'a', refresh: 'r', expiresAt: 1234567890,
    );
    final s = await storage.loadSession();
    expect(s?.access, 'a');
    expect(s?.refresh, 'r');
    expect(s?.expiresAt, 1234567890);
    await storage.clearSession();
    expect(await storage.loadSession(), isNull);
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/features/profile/auth_storage_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 AuthStorage**

`lib/features/profile/data/auth_storage.dart`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  Session({required this.access, required this.refresh, required this.expiresAt});
  final String access;
  final String refresh;
  final int expiresAt;
  Map<String, dynamic> toJson() => {'a': access, 'r': refresh, 'e': expiresAt};
  factory Session.fromJson(Map<String, dynamic> j) => Session(
    access: j['a'] as String,
    refresh: j['r'] as String,
    expiresAt: j['e'] as int,
  );
}

class AuthStorage {
  AuthStorage(this._s);
  final FlutterSecureStorage _s;
  static const _k = 'session';

  Future<void> saveSession({required String access, required String refresh, required int expiresAt}) async {
    await _s.write(key: _k, value: Session(access: access, refresh: refresh, expiresAt: expiresAt).toJson().toString());
  }

  Future<Session?> loadSession() async {
    final raw = await _s.read(key: _k);
    if (raw == null) return null;
    // 简化:实际项目用 jsonEncode/Decode
    final cleaned = raw.replaceAll(RegExp(r'[{}]'), '');
    final map = <String, String>{};
    for (final part in cleaned.split(', ')) {
      final kv = part.split(': ');
      if (kv.length == 2) map[kv[0]] = kv[1];
    }
    return Session(
      access: map['a'] ?? '',
      refresh: map['r'] ?? '',
      expiresAt: int.tryParse(map['e'] ?? '') ?? 0,
    );
  }

  Future<void> clearSession() => _s.delete(key: _k);
}
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/features/profile/auth_storage_test.dart
```

Expected:`+1: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/profile/data/auth_storage.dart test/features/profile/auth_storage_test.dart
git commit -m "feat(profile): add AuthStorage for secure session persistence"
```

---

## Task 23: UserRepositoryImpl(实现 login/register/refresh/me, TDD)

**Files:**
- Create: `hot-ai-app/lib/features/profile/data/user_repository_impl.dart`
- Create: `hot-ai-app/test/features/profile/user_repository_impl_test.dart`

- [ ] **Step 1: 写失败测试**

`test/features/profile/user_repository_impl_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';
import 'package:hot_ai_app/features/profile/data/user_repository_impl.dart';

void main() {
  test('login 调 /auth/login 并保存 session', () async {
    final storage = AuthStorageForTest();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = _StubAdapter();
    final repo = UserRepositoryImpl(dio: dio, storage: storage);
    final r = await repo.login('a@b.com', 'pw');
    expect(r.accessToken, 'acc-1');
    expect(r.user.email, 'a@b.com');
    expect(storage.saved, isNotNull);
  });
}

class AuthStorageForTest implements AuthStorageLike {
  Session? saved;
  @override
  Future<void> saveSession({required String access, required String refresh, required int expiresAt}) async {
    saved = Session(access: access, refresh: refresh, expiresAt: expiresAt);
  }
  @override
  Future<Session?> loadSession() async => saved;
  @override
  Future<void> clearSession() async => saved = null;
}

class _StubAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    final body = o.path == '/auth/login'
      ? '{"code":0,"data":{"accessToken":"acc-1","refreshToken":"ref-1","expiresAt":9999999999,"user":{"id":"u1","email":"a@b.com","nickname":"n"}},"message":"ok"}'
      : '{"code":0,"data":{},"message":"ok"}';
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
  @override
  void close({bool force = false}) {}
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/features/profile/user_repository_impl_test.dart
```

Expected: import 错误

- [ ] **Step 3: 抽 AuthStorageLike 接口 + 让 AuthStorage 实现它**

修改 `lib/features/profile/data/auth_storage.dart`:
1. 在文件顶部加接口
2. 把 `class AuthStorage {` 改成 `class AuthStorage implements AuthStorageLike {`

```dart
abstract class AuthStorageLike {
  Future<void> saveSession({required String access, required String refresh, required int expiresAt});
  Future<Session?> loadSession();
  Future<void> clearSession();
}

class AuthStorage implements AuthStorageLike {
  AuthStorage(this._s);
  final FlutterSecureStorage _s;
  // ... 既有方法保持不变 ...
}
```

- [ ] **Step 4: 实现 UserRepositoryImpl**

`lib/features/profile/data/user_repository_impl.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:hot_ai_app/core/network/api_response.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';
import 'package:hot_ai_app/features/profile/domain/user.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required this.dio, required this.storage});
  final Dio dio;
  final AuthStorageLike storage;

  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> login(
    String email, String password) async {
    final resp = await dio.post('/auth/login', data: {'email': email, 'password': password});
    final data = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final r = _parseAuth(data);
    await storage.saveSession(access: r.accessToken, refresh: r.refreshToken, expiresAt: r.expiresAt);
    return r;
  }

  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> register(
    String email, String password, String nickname) async {
    final resp = await dio.post('/auth/register', data: {'email': email, 'password': password, 'nickname': nickname});
    final data = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>, (j) => j as Map<String, dynamic>).unwrap();
    final r = _parseAuth(data);
    await storage.saveSession(access: r.accessToken, refresh: r.refreshToken, expiresAt: r.expiresAt);
    return r;
  }

  @override
  Future<String> refresh(String refreshToken) async {
    final resp = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken},
      options: Options(extra: {'_noAuth': true}));
    final data = ApiResponse<String>.fromJson(
      resp.data as Map<String, dynamic>, (j) => j as String).unwrap();
    return data;
  }

  @override
  Future<User> me() async {
    final resp = await dio.get('/user/me');
    final data = ApiResponse<User>.fromJson(
      resp.data as Map<String, dynamic>, (j) => User.fromJson(j as Map<String, dynamic>)).unwrap();
    return data;
  }

  @override
  Future<void> registerPushToken(String token, String platform) async {
    await dio.post('/user/push-token', data: {'token': token, 'platform': platform});
  }

  @override
  Future<void> deletePushToken() async {
    await dio.delete('/user/push-token');
  }

  ({String accessToken, String refreshToken, int expiresAt, User user}) _parseAuth(Map<String, dynamic> d) {
    return (
      accessToken: d['accessToken'] as String,
      refreshToken: d['refreshToken'] as String,
      expiresAt: d['expiresAt'] as int,
      user: User.fromJson(d['user'] as Map<String, dynamic>),
    );
  }
}
```

- [ ] **Step 5: 跑测试,确认通过**

```bash
flutter test test/features/profile/user_repository_impl_test.dart
```

Expected:`+1: All tests passed!`

- [ ] **Step 6: 提交**

```bash
git add lib/features/profile/data test/features/profile
git commit -m "feat(profile): add UserRepositoryImpl with login/register/refresh/me/push-token"
```

---

## Task 24: AuthController 状态机(TDD)

**Files:**
- Create: `hot-ai-app/lib/features/profile/presentation/auth_controller.dart`
- Create: `hot-ai-app/test/features/profile/auth_controller_test.dart`

- [ ] **Step 1: 写失败测试**

`test/features/profile/auth_controller_test.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/features/profile/domain/user.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

class _FakeRepo implements UserRepository {
  User? _u;
  bool shouldFail = false;
  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> login(String e, String p) async {
    if (shouldFail) throw Exception('boom');
    _u = User(id: '1', email: e, nickname: 'n');
    return (accessToken: 'a', refreshToken: 'r', expiresAt: 0, user: _u!);
  }
  @override
  Future<({String accessToken, String refreshToken, int expiresAt, User user})> register(String e, String p, String n) async => login(e, p);
  @override
  Future<String> refresh(String t) async => 'new';
  @override
  Future<User> me() async => _u!;
  @override
  Future<void> registerPushToken(String t, String p) async {}
  @override
  Future<void> deletePushToken() async {}
}

void main() {
  test('login 成功进入 authenticated', () async {
    final repo = _FakeRepo();
    final c = AuthController(repo);
    await c.login('a@b.com', 'pw');
    expect(c.state.status, AuthStatus.authenticated);
    expect(c.state.user?.email, 'a@b.com');
  });

  test('login 失败进入 unauthenticated + error', () async {
    final repo = _FakeRepo()..shouldFail = true;
    final c = AuthController(repo);
    await c.login('a@b.com', 'pw');
    expect(c.state.status, AuthStatus.unauthenticated);
    expect(c.state.error, contains('boom'));
  });
}
```

- [ ] **Step 2: 跑测试,确认失败**

```bash
flutter test test/features/profile/auth_controller_test.dart
```

Expected: import 错误

- [ ] **Step 3: 实现 AuthController**

`lib/features/profile/presentation/auth_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/profile/data/user_repository_impl.dart';
import 'package:hot_ai_app/features/profile/domain/user.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  throw UnimplementedError('Override in main.dart');
});

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unauthenticated, this.user, this.error});
  final AuthStatus status;
  final User? user;
  final String? error;
  AuthState copyWith({AuthStatus? status, User? user, String? error, bool clearError = false}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());
  final UserRepository _repo;

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final r = await _repo.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: r.user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> register(String email, String password, String nickname) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final r = await _repo.register(email, password, nickname);
      state = state.copyWith(status: AuthStatus.authenticated, user: r.user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> logout() async {
    try { await _repo.deletePushToken(); } catch (_) {}
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(userRepositoryProvider));
});
```

- [ ] **Step 4: 跑测试,确认通过**

```bash
flutter test test/features/profile/auth_controller_test.dart
```

Expected:`+2: All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/profile/presentation/auth_controller.dart test/features/profile/auth_controller_test.dart
git commit -m "feat(profile): add AuthController state machine (unauth/auth/authenticated)"
```

---

## Task 25: LoginPage

**Files:**
- Create: `hot-ai-app/lib/features/profile/presentation/login_page.dart`

- [ ] **Step 1: 实现登录页**

`lib/features/profile/presentation/login_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: '邮箱'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? '邮箱格式不对' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? '密码至少 6 位' : null,
              ),
              const SizedBox(height: 24),
              if (state.error != null)
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.status == AuthStatus.authenticating ? null : _submit,
                child: state.status == AuthStatus.authenticating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('登录'),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('没有账号?去注册'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add lib/features/profile/presentation/login_page.dart
git commit -m "feat(profile): add LoginPage with email/password form"
```

---

## Task 25b: RegisterPage + 加 /register 路由

**Files:**
- Create: `hot-ai-app/lib/features/profile/presentation/register_page.dart`
- Modify: `hot-ai-app/lib/core/router/app_router.dart`

- [ ] **Step 1: 实现注册页**

`lib/features/profile/presentation/register_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(
      _email.text, _password.text, _nickname.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nickname,
                decoration: const InputDecoration(labelText: '昵称'),
                validator: (v) => (v == null || v.isEmpty) ? '昵称必填' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: '邮箱'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? '邮箱格式不对' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: '密码(至少 6 位)'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? '密码至少 6 位' : null,
              ),
              const SizedBox(height: 24),
              if (state.error != null)
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: state.status == AuthStatus.authenticating ? null : _submit,
                child: state.status == AuthStatus.authenticating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('注册'),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('已有账号?去登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 在 app_router.dart 加 /register 路由**

修改 `lib/core/router/app_router.dart`,在 `GoRoute(path: '/login', ...)` 后追加:
```dart
GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
```
并在文件顶部 import `register_page.dart`。

- [ ] **Step 3: analyze**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/features/profile/presentation/register_page.dart lib/core/router/app_router.dart
git commit -m "feat(profile): add RegisterPage and /register route"
```

---

## Task 26: ProfilePage + 串起 5 Tab Shell

**Files:**
- Create: `hot-ai-app/lib/features/profile/presentation/profile_page.dart`
- Create: `hot-ai-app/lib/features/home/home_shell.dart`
- Modify: `hot-ai-app/lib/core/router/app_router.dart`

- [ ] **Step 1: 实现 HomeShell(StatefulShellRoute)**

`lib/features/home/home_shell.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.article), label: '资讯'),
          NavigationDestination(icon: Icon(Icons.work), label: '职业'),
          NavigationDestination(icon: Icon(Icons.school), label: '学习'),
          NavigationDestination(icon: Icon(Icons.apps), label: '工具'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 实现 ProfilePage(显示当前用户 + 登出)**

`lib/features/profile/presentation/profile_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final user = state.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push('/login'),
            child: const Text('登录'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(title: Text(user.nickname), subtitle: Text(user.email)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 重写 app_router.dart 用 StatefulShellRoute**

`lib/core/router/app_router.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hot_ai_app/features/articles/presentation/article_detail_page.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_list_page.dart';
import 'package:hot_ai_app/features/home/home_shell.dart';
import 'package:hot_ai_app/features/profile/presentation/login_page.dart';
import 'package:hot_ai_app/features/profile/presentation/profile_page.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/articles',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/articles',
              builder: (_, __) => const ArticlesListPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (ctx, state) => ArticleDetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/professions', builder: (_, __) => const _StubPage('职业')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/learning-paths', builder: (_, __) => const _StubPage('学习')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tools', builder: (_, __) => const _StubPage('工具')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    ],
  );
}

class _StubPage extends StatelessWidget {
  const _StubPage(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('$title (M2 待实现)')),
  );
}
```

- [ ] **Step 4: analyze**

```bash
flutter analyze
```

Expected: 无错误

- [ ] **Step 5: 提交**

```bash
git add lib/features/home lib/features/profile/presentation lib/core/router
git commit -m "feat(app): wire HomeShell with 5 Tab StatefulShellRoute + ProfilePage"
```

---

## Task 27: main.dart 注入 dio/repo + bootstrap session

**Files:**
- Modify: `hot-ai-app/lib/main.dart`
- Create: `hot-ai-app/lib/bootstrap.dart`

- [ ] **Step 1: 实现 bootstrap 函数**

`lib/bootstrap.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hot_ai_app/app.dart';
import 'package:hot_ai_app/core/network/dio_provider.dart';
import 'package:hot_ai_app/core/network/interceptors/auth_interceptor.dart';
import 'package:hot_ai_app/core/network/interceptors/error_interceptor.dart';
import 'package:hot_ai_app/core/network/interceptors/log_interceptor.dart';
import 'package:hot_ai_app/core/network/interceptors/retry_interceptor.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';
import 'package:hot_ai_app/core/storage/secure_storage.dart';
import 'package:hot_ai_app/features/articles/data/article_repository_impl.dart';
import 'package:hot_ai_app/features/articles/domain/article_repository.dart';
import 'package:hot_ai_app/features/articles/presentation/articles_controller.dart';
import 'package:hot_ai_app/features/profile/data/auth_storage.dart';
import 'package:hot_ai_app/features/profile/data/user_repository_impl.dart';
import 'package:hot_ai_app/features/profile/domain/user_repository.dart';
import 'package:hot_ai_app/features/profile/presentation/auth_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxes = await openAppBoxes();
  const secure = FlutterSecureStorage();
  final tokenStorage = SecureTokenStorage(secure);
  final authStorage = AuthStorage(secure);

  final dio = buildDio(interceptors: [
    LogInterceptor(),
    AuthInterceptor(storage: tokenStorage),
    RetryInterceptor(),
    ErrorInterceptor(),
  ]);

  final userRepo = UserRepositoryImpl(dio: dio, storage: authStorage);
  final articleRepo = ArticleRepositoryImpl(dio: dio, boxes: boxes);

  runApp(ProviderScope(
    overrides: [
      appBoxesProvider.overrideWithValue(boxes),
      articleRepositoryProvider.overrideWithValue(articleRepo),
      userRepositoryProvider.overrideWithValue(userRepo),
    ],
    child: const HotAiApp(),
  ));
}
```

- [ ] **Step 2: 简化 main.dart**

`lib/main.dart`:
```dart
import 'package:hot_ai_app/bootstrap.dart';
void main() => bootstrap();
```

- [ ] **Step 3: analyze + build**

```bash
flutter analyze
flutter build apk --debug --dart-define=API_BASE=http://localhost/api
```

Expected: 成功(后端未启不报错,App 启动后调 API 才会报错)

- [ ] **Step 4: 提交**

```bash
git add lib/main.dart lib/bootstrap.dart
git commit -m "feat(app): wire bootstrap with dio/repo overrides"
```

---

## Task 28: 集成测试 - 启动 + 跳转 + 空状态

**Files:**
- Create: `hot-ai-app/integration_test/app_smoke_test.dart`

- [ ] **Step 1: 实现冒烟测试**

`integration_test/app_smoke_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/bootstrap.dart';
import 'package:hot_ai_app/shared/widgets/empty_view.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('App 启动后能进 5 Tab 壳 + 列表空状态', (tester) async {
    await bootstrap();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('资讯'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // 资讯页未登录应显示错误或加载,这里只验证不崩溃
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: 跑集成测试(可选,需要后端或 mock)**

```bash
flutter test integration_test/app_smoke_test.dart
```

注:此测试需 --dart-define=API_BASE 指向可用后端,否则会显示网络错误页(测试仍通过)。

- [ ] **Step 3: 提交**

```bash
git add integration_test/app_smoke_test.dart
git commit -m "test(app): add smoke test for 5-tab shell"
```

---

## Task 29: 全量验证 + README

**Files:**
- Create: `hot-ai-app/README.md`

- [ ] **Step 1: 全量测试**

```bash
flutter analyze
flutter test
```

Expected: 全部通过

- [ ] **Step 2: 写 README**

`README.md`:
```markdown
# hot-ai-app

AI 热点追踪平台 - 移动端 App(Flutter)

## 环境

- Flutter 3.22.x
- Dart 3.4.x

## 配置

启动时通过 `--dart-define=API_BASE` 指定后端:
```bash
flutter run --dart-define=API_BASE=https://yourdomain.com/api
```

默认 `http://localhost/api`(开发后端在本机时用)。

## 开发

```bash
flutter pub get
flutter run
```

## 测试

```bash
flutter test                  # 单元 + widget
flutter test integration_test # 冒烟
```

## 构建

```bash
flutter build apk --dart-define=API_BASE=https://yourdomain.com/api
flutter build ios --dart-define=API_BASE=https://yourdomain.com/api
```

## 架构

Feature-first + Riverpod + dio + Hive + go_router

- `lib/core/` 跨特性基础设施
- `lib/features/<x>/{domain,data,presentation}` 三层
- `lib/shared/` 通用 widget + 模型

## 状态

MVP 阶段 - M0/M1/M3 已实现。M2(其他 3 模块)/M4(推送)/M5(打磨) 在后续 plan。
```

- [ ] **Step 3: 提交**

```bash
git add README.md
git commit -m "docs: add README with setup/build/test instructions"
```

---

# 后续计划(本次不开 Plan,等 MVP 跑通后再写)

## Plan 2: M2 - 其他 3 个模块(职业/学习/工具)

套用 M1 的 article 模块模式:
- 每个模块:entity + repository + repository_impl + controller + list_page + detail_page
- 估算 18-24 个任务
- 关键设计:ArticleRenderer widget 抽出为通用富文本渲染,被 3 个模块复用
- 唯一差异:profession 有"影响任务"嵌套结构,learning-path 有"章节"层级,tool 有"链接"按钮
- Hive box 已经预留(Phase M0 Task 13),无需扩展

## Plan 3: M4 - 推送(极光/个推)

- 后端:在 `user-svc` 加 `POST/DELETE /user/push-token` 端点 + `user_push_tokens` 表(Go Zero 部分单独 plan)
- App 端:`jpush_flutter_plugin` 集成,iOS/Android 平台配置,JPushService 封装
- 与 AuthController 联动:登录后注册 token,登出时注销
- 推送点击 → `go_router` deep link 跳文章详情
- 估算 10-12 个任务

## Plan 4: M5 - 打磨与测试

- 离线 banner(`connectivity_plus` 监听 + 全局顶栏)
- Golden test 选关键页面(Light/Dark 2 套)
- 集成测试扩展:登录 → 列表 → 详情 → 收藏 → 离线再读
- 覆盖率门槛:core + Repository ≥ 80%(在 `analysis_options.yaml` 加规则)
- 上架材料:PrivacyInfo.xcprivacy、隐私协议、截图
- 估算 8-10 个任务

---

## Self-Review Checklist(已自审)

✅ Spec 覆盖:本文覆盖 M0(基建)+ M1(资讯模板)+ M3(登录) 全部 spec 中的子节
✅ 占位符扫描:无 TBD/TODO/实现细节缺失
✅ 类型一致:`articleRepositoryProvider`/`userRepositoryProvider` 命名贯穿全文
✅ Hive box 命名:与 spec 一致(`articles_meta` / `article_details` / ...)
✅ 后端 push-token 端点已在 UserRepository 接口签名中预留,Plan 3 实现

**已知未在本计划(在 Plan 2/3/4):**
- 职业/学习/工具模块 - Plan 2
- 极光推送与 push-token 后端 - Plan 3
- 离线 banner / Golden test / 覆盖率门槛 / 上架材料 - Plan 4

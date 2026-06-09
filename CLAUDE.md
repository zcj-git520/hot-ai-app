# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目

AI 热点追踪平台移动端 (Flutter 3.44 / Dart 3.12)。MVP 阶段:已实现 M0(基建)+ M1(资讯模块)+ M3(登录/个人中心);M2(职业/学习/工具)、M4(极光推送)、M5(打磨) 在后续 plan 中。设计与计划文档位于 `docs/superpowers/{specs,plans}/`。

后端复用 Go Zero 网关,走 nginx 代理(无新后端服务)。M4 阶段会在后端加 `POST/DELETE /user/push-token`。

## 常用命令

```bash
flutter pub get
flutter test                              # 全部单元 + widget 测试
flutter test test/path/file_test.dart     # 单文件
flutter test --name "test name"           # 名字匹配
flutter test integration_test             # 冒烟(需可用后端或网络错误可接受)
flutter analyze                           # 静态检查
flutter build apk --dart-define=API_BASE=https://yourdomain.com/api
flutter build ios --dart-define=API_BASE=https://yourdomain.com/api
flutter run --dart-define=API_BASE=...
```

`API_BASE` 默认 `http://localhost/api`(本机后端用)。打包/运行时不传则走默认值。

## 架构

Feature-first,三层结构:

```
lib/
├── main.dart              # 入口,只调用 bootstrap()
├── bootstrap.dart         # 初始化 Hive/secure storage/dio/拦截器/Repos,override 到 ProviderScope
├── app.dart               # MaterialApp.router(主题 + buildAppRouter)
├── core/                  # 跨特性基础设施
│   ├── network/           # dio + 4 个拦截器
│   ├── storage/           # Hive 7 boxes + SecureTokenStorage
│   ├── error/             # AppException + Failure sealed
│   ├── router/            # GoRouter(StatefulShellRoute)
│   └── theme/             # AppTheme light/dark
├── features/<x>/
│   ├── domain/            # entity + abstract Repository
│   ├── data/              # Repository impl + DTO/Storage
│   └── presentation/      # Controller(StateNotifier) + Page(Consumer*)
└── shared/                # Loading/Error/Empty widget + Pagination 模型
```

### 关键设计点

**依赖注入(Provider override)**:Repository 在 domain 层是抽象接口,在 main 实际入口 `bootstrap.dart` 实例化,经 `ProviderScope.overrides` 注入。presentation 层定义 `xxxRepositoryProvider` 占位 Provider(`throw UnimplementedError`),由 `articlesControllerProvider` 等 `ref.watch` 读取。

**dio 拦截器顺序**(见 `bootstrap.dart`):`Log` → `Auth`(注入 Bearer + 401 refresh 串行锁)→ `Retry`(幂等方法 1 次重试,需传入 dio 自身引用)→ `Error`(code!=0 抛 AppException)。注意 `RetryInterceptor` 必须后于 `buildDio()`,因为它需要 dio 引用做重发。

**ApiResponse 是静态方法不是工厂**:Dart 工厂构造器不支持泛型类型参数,所以用 `ApiResponse.fromJson<T>(json, decoder)` 静态方法。Repository 中调用形式:
```dart
ApiResponse.fromJson<Map<String, dynamic>>(resp.data, (j) => j as Map<String, dynamic>>).unwrap();
```

**路由**:5 Tab 用 `StatefulShellRoute.indexedStack` 套 `StatefulShellBranch`(`/articles` `/professions` `/learning-paths` `/tools` `/profile`)。`/articles/:id` 是 articles 分支的子路由(用 `context.push` 而非 `go`)。`/login` 和 `/register` 在 shell 外。新模块照 articles 模式加 branch + 占位 StubPage。

**Hive 缓存策略**(`lib/core/storage/hive_init.dart`):7 个 box —— `appMeta`、`articlesMeta`(列表元数据)、`articleDetails`(详情缓存,命中即返回并后台异步刷新)、`professionsCache` / `learningPathsCache` / `toolsCache` (M2 预留)、`userState`(收藏列表等用户态)。`openAppBoxes({String? path})` 测试时可注入 tmp 目录绕开 path_provider。

**Auth 401 refresh 锁**(`auth_interceptor.dart`):静态 `_AuthState` 持有 in-flight Completer,多个并发 401 只触发一次 refresh;失败后 `clearSession()`(由 `onUnauthorized` callback 决定),`AuthInterceptor.resetState()` 静态方法供测试隔离。

**Test-friendly 抽象**:`SecureTokenStorage` 包装 `FlutterSecureStorage`、`AuthStorage` 用 `SecureStorageLike` 抽象(测试用 in-memory 实现);`UserRepositoryImpl` 通过 `AuthStorageLike` 解耦。Riverpod controller 测试用 `ProviderContainer(overrides: [...])` + `addTearDown(container.dispose)`,Fake repo 需让 `Pagination.total` 足够大以保证 `hasMore == true`,否则 `loadMore` 提前返回。

### 后端约定

- 所有响应包成 `{code: int, message: string, data: T}`,`code != 0` 视为业务错误
- 文章路径:`GET /articles?page=&category=`、`GET /articles/:id`、`POST /articles/:id/favorite {favorite: bool}`
- 认证路径:`POST /auth/login {email, password}`、`POST /auth/register {email, password, nickname}`、`POST /auth/refresh {refreshToken}`(必须 extra=`{_noAuth: true}` 跳过 AuthInterceptor 注入)、`GET /user/me`
- 401 时 AuthInterceptor 触发外部传入的 `onUnauthorized` callback 做 refresh;refresh 失败需自行 `storage.clear()`

## 文档

- 设计: `docs/superpowers/specs/2026-06-09-hot-ai-app-design.md`
- 实施计划: `docs/superpowers/plans/2026-06-09-hot-ai-app-mvp.md`
- 上层 monorepo: `../CLAUDE.md`(包含 web/backend/agent 端口与环境)

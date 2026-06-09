# AI 热点追踪平台 - 移动 App 设计文档

**日期**: 2026-06-09
**状态**: 待批准
**作者**: Claude (brainstorming 流程)

## 概述

为 AI 热点追踪平台新增 Flutter 移动端 App,与现有 Nuxt 3 Web 端、Go Zero 后端、Python Agent 共同构成完整产品矩阵。App 主打"通勤/差旅"场景:离线可读已收藏资讯、推送接收热点提醒、复刻 Web 端五大用户模块的阅读体验。

**MVP 范围**:
- 5 个底部 Tab(资讯/职业/学习路径/工具/我的)
- 离线缓存文章列表与已读详情
- 极光/个推国内推送
- 复用 Go Zero 网关 REST API,走 nginx 代理
- JWT 登录态,access + refresh 双 token

**不在 MVP**:
- 管理员后台、评论/点赞/分享、视频/音频、复杂动画、生物认证、第三方登录

---

## 1. 架构 & 目录

### 1.1 调用链

```
Flutter App
  └─ dio ──► https://yourdomain.com/api/*  (走 nginx 443)
                       │
                       ▼
                nginx-1.26.3
                       │
                       ▼
              Go Zero 网关 :8000
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
  content-svc    profession-svc   learning-path-svc   tool-svc   user/auth
```

不引入新后端服务。App 与 Web 端共享同一套 API。

### 1.2 仓库位置

`D:\hot-ai\` 根目录新增 `hot-ai-app/`,与 `hot-ai-frontend/`、`hot-ai-backend/`、`hot-ai-agent/` 平级。

### 1.3 技术栈(已确认)

| 维度 | 选型 |
|------|------|
| 框架 | Flutter 3.x (Dart 3) |
| 状态管理 | Riverpod 2.x |
| HTTP | dio 5.x + 拦截器 |
| 本地存储 | Hive 2 (NoSQL) + flutter_secure_storage |
| 路由 | go_router |
| 推送 | jpush_flutter_plugin (iOS APNs + Android 国内通道) |
| 网络监测 | connectivity_plus |
| 富文本渲染 | flutter_widget_from_html |
| 测试 | flutter_test + mocktail + integration_test |

### 1.4 目录结构

```
hot-ai-app/
├── pubspec.yaml
├── lib/
│   ├── main.dart                    # ProviderScope 包裹根 App
│   ├── app.dart                     # MaterialApp.router + 主题
│   ├── core/                        # 跨特性共享
│   │   ├── network/                 # dio 实例 + 5 个拦截器
│   │   ├── storage/                 # Hive box 初始化 + secure_storage 封装
│   │   ├── router/                  # go_router 配置 + 守卫
│   │   ├── theme/                   # 颜色/字体/明暗模式
│   │   ├── push/                    # JPush 封装
│   │   ├── error/                   # AppException, Failure sealed types
│   │   └── utils/                   # 工具函数
│   ├── features/
│   │   ├── articles/                # 资讯
│   │   ├── professions/             # 职业风险
│   │   ├── learning_paths/          # 学习路径
│   │   ├── tools/                   # AI 工具库
│   │   ├── profile/                 # 个人中心(含登录/注册子路由)
│   │   └── home/                    # 底部 Tab + 导航壳
│   └── shared/
│       ├── widgets/                 # 通用组件
│       └── models/                  # 跨特性 DTO
├── test/                            # 单元 + widget 测试
├── integration_test/                # 冒烟测试
└── android/ ios/                    # 平台壳
```

### 1.5 Feature 内部三层

```
features/articles/
├── data/         # DTO + Repository 实现 + Hive cache 读写
├── domain/       # Entity + Repository 抽象
└── presentation/ # Page + Widget + Controller (Riverpod Provider)
```

---

## 2. API 集成

### 2.1 nginx 侧

**不改动**现有 `nginx-1.26.3` 配置。Web 端已有的 `/api/*` 反代规则直接复用。App 通过域名 `https://yourdomain.com/api` 调用。

构建时注入 base URL:
```bash
flutter build apk --dart-define=API_BASE=https://yourdomain.com/api
```

### 2.2 dio 拦截器链(顺序敏感)

| 顺序 | 拦截器 | 职责 |
|------|--------|------|
| 1 | `LogInterceptor` | 开发期打印 method/url/duration(生产关闭) |
| 2 | `AuthInterceptor` Request | 从 secure_storage 读 access token,加 `Authorization: Bearer <token>` |
| 3 | `AuthInterceptor` Response | 收到 401 → 调 `POST /auth/refresh` → 成功则重发原请求,失败则清登录态跳 Login |
| 4 | `ErrorInterceptor` | 统一把非 2xx 转成 `AppException(code, message)` |
| 5 | `RetryInterceptor` | 网络错误 / idempotent GET 自动重试 1 次 |

### 2.3 响应格式(与 Web 端统一,后端已规范化)

```json
{ "code": 0, "data": { ... }, "message": "ok" }
```

- `code == 0` → 解包 `data`
- `code != 0` → 抛 `AppException(code, message)`
- HTTP 非 2xx → 抛 `AppException(httpStatus, message)`

### 2.4 Repository 模式

- 接口放 `features/<x>/domain/<x>_repository.dart`(纯 Dart,无 Flutter 依赖)
- 实现放 `features/<x>/data/<x>_repository_impl.dart`(注 dio + Hive)
- Riverpod `Provider<ArticleRepository>` 注入
- UI 只持有接口,便于 mock 测试

---

## 3. 登录态 & 会话

### 3.1 存储分层

| 存储 | 库 | 存什么 | 理由 |
|------|-----|--------|------|
| Secure | `flutter_secure_storage` | access_token, refresh_token, token_expires_at | 加密、Keychain/Keystore |
| 内存 | Riverpod `StateProvider<User?>` | 当前 User 对象 | 反应式订阅 |
| 磁盘 | Hive box `app_meta` | 主题/语言/上次同步时间 | 配置类,无需加密 |

### 3.2 Auth 状态机

```
unauthenticated ──login()──► authenticating ──ok──► authenticated
                                  │                       │
                                  └──fail──► unauthenticated
                                                       │
                                                401/refresh fail
                                                       │
                                                       ▼
                                          refreshing ──┬──ok──► retry original
                                                      └──fail──► unauthenticated
```

### 3.3 关键点

- **启动 bootstrap**:`main.dart` 中检查 secure storage 有无 access_token → 有则 `GET /user/me` 校验 → 失败则尝试 refresh → 还失败则登出
- **401 拦截 + 串行 refresh 锁**:用 `Completer` + 共享 future,避免 5 个并发请求触发 5 次 refresh
- **主动刷新**:access token 过期前 60s 主动 refresh(需后端 `login` 响应返回 `tokenExpiresAt`)
- **登出**:清 secure storage + Hive `user_state` box + 内存 user state + `JPush.deleteAlias()` + 跳 `/login`

### 3.4 路由守卫

`go_router` `redirect` 函数:
- 未登录访问 `(user)` 路由组 → 跳 `/login?next=<原路径>`
- 已登录访问 `login/register` → 跳 `/`
- 守卫对 `redirect` 自身的目标路径做白名单,避免无限循环

---

## 4. 功能模块

### 4.1 5 个底部 Tab

| Tab | 路由 | 主要页面 | 复用 Web 端 API |
|-----|------|---------|----------------|
| 资讯 | `/articles` `/articles/:id` | 列表(无限滚动+顶部 chip) + 详情(渲染+收藏) | `articleApi` |
| 职业 | `/professions` `/professions/:id` | 风险列表 + 详情(含影响任务) | `professionApi` |
| 学习 | `/learning-paths` `/learning-paths/:id` | 路径列表 + 详情 + 章节 | `learningPathApi` |
| 工具 | `/tools` `/tools/:id` | 工具列表 + 详情 | `toolApi` |
| 我的 | `/profile` | 资料/收藏/历史/设置 | `userApi` |

### 4.2 Web 端 vs App 端差异(明确改动点)

| 维度 | Web 端 | App 端 |
|------|--------|--------|
| 列表分页 | 数字分页器 | 无限滚动 + 上拉加载 |
| 筛选 | 侧栏 | 顶部 chip 横滑 + 抽屉式全部筛选 |
| 富文本 | Nuxt 原生 HTML | `flutter_widget_from_html` |
| 收藏交互 | 按钮点击 | 长按菜单 + 心形按钮 + 触觉反馈 |
| 搜索 | 顶部搜索框 | 顶部搜索框(MVP 不做语音) |
| 图标 | Web Icons.vue | Material Icons + iOS 风格适配 |

### 4.3 明确 YAGNI

- ❌ 管理员后台
- ❌ 评论/点赞/分享(需新增后端)
- ❌ 视频/音频(超出 Web 端能力)
- ❌ Lottie/复杂动画
- ❌ 语音搜索、生物认证、第三方登录

---

## 5. 推送(极光/个推)

### 5.1 SDK 选型

`jpush_flutter_plugin` 官方插件,同时支持:
- iOS:APNs(经 JPush 转发)
- Android:JPush 自有通道 + 国内厂商通道(华为/小米/OPPO/vivo 推送)

如选个推则改 `getuiflut`,接口形态相同。

### 5.2 平台配置

**iOS**:
- `Info.plist` 加 `UIBackgroundModes` 含 `remote-notification`、推送权限说明文案
- `AppDelegate.swift` 注册 JPush

**Android**:
- `AndroidManifest.xml` 加权限(`INTERNET`、`ACCESS_NETWORK_STATE`、厂商通道权限)
- `MainActivity.kt` 注册 JPush
- 申请各厂商通道 AppID(后续上架前完成)

### 5.3 App 端流程

```
启动 → JPush.setup() → getRegistrationID()
                            │
                            ▼
              POST /user/push-token { token, platform: ios|android }
                            │
                            ▼
                  token 变化时再注册一次
```

### 5.4 推送处理

| 事件 | 处理 |
|------|------|
| 收到推送(前台) | 顶部 SnackBar 轻量提示 |
| 点击推送 | 解析 `extras.articleId` → `go_router` 跳 `/articles/:id` |
| token 变化 | 自动调后端更新(系统重启/恢复会触发) |
| 用户登出 | `DELETE /user/push-token` + `JPush.deleteAlias()` |

### 5.5 推送类型(与后端约定)

- `new_article`:新文章发布 → 推详情(推荐打开)
- `hot_topic`:热点话题 → 推话题页(可选,后端有数据时再开)

### 5.6 后端最小改动(MUST)

- **新增** `POST /user/push-token { token, platform }` — 注册/更新 token
- **新增** `DELETE /user/push-token` — 注销
- 复用 Go Zero 现有 `user-svc`,不新增微服务
- 需新增 `user_push_tokens` 表(token PK, user_id FK, platform, created_at)

---

## 6. 离线缓存

### 6.1 Hive Box 设计

| Box 名 | 存什么 | 写入时机 | 淘汰策略 |
|--------|--------|---------|---------|
| `articles_meta` | `Map<articleId, ArticleSummary>` | 拉列表时合并写入 | > 1000 条 LRU |
| `article_details` | `Map<articleId, Article>`(单 box,key 为 article id) | 打开详情页后异步写 | 单条 7 天未访问清掉 |
| `professions_cache` | 职业列表 + 详情 | 拉取时写 | 30 天 TTL |
| `learning_paths_cache` | 学习路径 + 章节 | 拉取时写 | 30 天 TTL |
| `tools_cache` | 工具列表 + 详情 | 拉取时写 | 30 天 TTL |
| `user_state` | 收藏列表 / 阅读历史 | 每次操作增量写 | 无上限,用户主动清空 |

### 6.2 网络请求策略(Repository 统一)

```dart
Future<Article> getArticle(String id) async {
  final cached = hive.articleDetailsBox.get(id);
  if (cached != null) emit(cached);   // 立刻返回缓存

  try {
    final fresh = await dio.get('/articles/$id');
    hive.articleDetailsBox.put(id, fresh);
    emit(fresh);
  } catch (e) {
    if (cached == null) rethrow;  // 缓存空 + 网络挂 → 报错
  }
}
```

### 6.3 离线状态提示

`connectivity_plus` 监听:
- 断网:顶栏出"离线模式 · 部分功能不可用"提示条(可关)
- 恢复:自动重试挂起的请求,顶栏显示"已恢复"

### 6.4 YAGNI

- ❌ 整库同步 / 冲突解决(只读缓存,写操作走网络)
- ❌ 预拉取队列
- ❌ 后台预热任务

---

## 7. 错误处理 & 测试

### 7.1 错误层级

| 层 | 类型 | 触发条件 |
|----|------|---------|
| 网络 | `NetworkException` | 超时/无网/DNS |
| HTTP | `HttpException(status, code, msg)` | 4xx/5xx |
| 业务 | `AppException(code, message)` | 响应 code != 0 |
| 领域 | `Failure` sealed(NotFound/Unauthorized/Validation/Server/Unknown) | Repository 边界 |

### 7.2 UI 表现

| 错误 | UI |
|------|----|
| `NetworkException` | Snackbar"网络异常,正在使用缓存" + 重试按钮 |
| `Unauthorized` | 全局监听 → 跳登录 |
| `AppException` | Snackbar 红色 `message` |
| `Failure` | 页面级 ErrorWidget + 重试按钮 |

### 7.3 测试策略

| 层级 | 工具 | 目标 |
|------|------|------|
| 单元 | `flutter_test` + `mocktail` | Repository 逻辑、Provider 状态机、5 个拦截器行为 |
| Widget | `flutter_test` | 关键页面四态(空/加载/错误/正常) |
| 集成 | `integration_test` | 登录→列表→详情→收藏 happy path(2-3 个冒烟) |
| 手测 | QA | 真机推送、离线、网络切换、登出登入 |

**覆盖率目标**:核心 Repository + Provider ≥ 80%,关键页面 100% widget 测试。

### 7.4 YAGNI(测试)

- ❌ Golden test(MVP 视觉还会变)
- ❌ Patrol/Maestro(用 `integration_test` 足够)

---

## 8. 跨切关注点

### 8.1 主题与设计

- 配色:沿用 Web 端主色(深蓝 + 橙色强调),用 `ColorScheme.fromSeed` 生成
- 字体:`google_fonts` 引入思源黑体(中文)+ Inter(英文)
- 明暗模式:跟随系统,可在设置切换并持久化到 `app_meta` box

### 8.2 国际化

- MVP **仅中文**(与 Web 端一致)
- 使用 `flutter_localizations` 配 `intl`,字符串走 `.arb` 文件,后续加英文只需新增 `app_en.arb`

### 8.3 性能

- 列表项高度固定(避免图片加载时跳变),图片用 `cached_network_image`
- 长列表用 `ListView.builder` + 懒加载,分页阈值 80%
- 路由用 `go_router` lazy build,避免冷启动时一次性建好所有页面

### 8.4 隐私与权限

- 启动时只请求必要权限(推送通知),相机/位置等非 MVP 需要一律不申请
- `Info.plist` / `AndroidManifest` 写明用途文案,合规上架

---

## 9. 实施里程碑(高层级)

不写具体任务,留待 writing-plans 阶段拆解:

1. **M0 基建**:Flutter 工程初始化、Riverpod/dio/Hive 接入、主题/路由/i18n/connectivity 等跨切关注点骨架、CI 跑通 `flutter build apk`
2. **M1 资讯模块**:列表 + 详情 + 离线缓存(端到端跑通,作为模板)
3. **M2 其他 3 模块**:职业 / 学习路径 / 工具(套用 M1 模式)
4. **M3 个人中心 + 登录**:登录态、refresh 锁、路由守卫
5. **M4 推送**:极光集成 + 后端 token 接口联调
6. **M5 打磨 + 测试**:覆盖率、冒烟、QA 真机测试、上架材料

---

## 10. 风险与缓解

| 风险 | 缓解 |
|------|------|
| Go Zero 网关响应慢拖累 App 首屏 | Repository 双层返回(缓存先,网络后),UX 上"秒开" |
| 极光各厂商通道申请周期长 | MVP 先跑通 JPush 默认通道,厂商通道后续优化送达率 |
| Web 端 API 字段调整未通知 App | 在 dio 拦截器加 schema 校验,发现字段缺失立即告警 |
| Flutter 版本升级破坏插件兼容 | 锁定 Flutter 3.22.x + Dart 3.4.x,CI 跑 build 验证 |
| App 端缓存膨胀 | Hive box 上限 + LRU 淘汰 + 启动时统计 box size |

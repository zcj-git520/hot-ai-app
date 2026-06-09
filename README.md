# hot-ai-app

AI 热点追踪平台 — 移动端 App(Flutter)

## 项目目标

为 AI 热点追踪平台提供 Flutter 移动端,主打"通勤/差旅"场景:离线可读已收藏资讯、推送接收热点提醒、复刻 Web 端五大用户模块的阅读体验。

## 设计文档

- 概要设计: [docs/superpowers/specs/2026-06-09-hot-ai-app-design.md](docs/superpowers/specs/2026-06-09-hot-ai-app-design.md)
- 实施计划 (MVP - M0+M1+M3): [docs/superpowers/plans/2026-06-09-hot-ai-app-mvp.md](docs/superpowers/plans/2026-06-09-hot-ai-app-mvp.md)

## 当前状态

**预实现阶段** — 工程目录与设计文档已就位,代码尚未生成。

实施前需先在开发机安装:
- Flutter 3.22.x
- Dart 3.4.x

装好后,从实施计划的 Task 1 开始执行(M0 基建 → M1 资讯模块 → M3 登录/个人中心)。

## 架构(高层)

- **框架**: Flutter 3.22 / Dart 3.4
- **状态管理**: Riverpod 2.5
- **HTTP**: dio 5.4 + 5 个拦截器(JWT/401/重试/日志/错误映射)
- **离线缓存**: Hive 2.2(7 个 box)
- **路由**: go_router 14
- **登录态**: flutter_secure_storage 存 JWT,refresh 串行锁
- **推送**: jpush_flutter_plugin(极光/个推,M4 阶段)
- **后端**: 复用 Go Zero 网关(走 nginx 代理,无新后端服务)

## 仓库

```
hot-ai-app/
├── README.md           ← 本文件
├── LICENSE             ← Apache 2.0
├── .gitignore          ← Flutter 标准
├── docs/               ← 设计文档
│   └── superpowers/
│       ├── specs/      ← 概要设计
│       └── plans/      ← 实施计划
└── (待生成) lib/ test/ android/ ios/ ...
```

## 关联项目

- Web 端: `../hot-ai-frontend/` (Nuxt 3)
- 后端: `../hot-ai-backend/` (Go Zero 微服务)
- Agent: `../hot-ai-agent/` (Python FastAPI)
- 设计/需求: `../hotAI/`

## 文档索引

团队 superpowers 规范:
- `../docs/superpowers/specs/` — 各项目概要设计
- `../docs/superpowers/plans/` — 各项目实施计划

## License

Apache License 2.0

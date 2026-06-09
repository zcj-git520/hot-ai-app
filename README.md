# hot-ai-app

AI 热点追踪平台 - 移动端 App(Flutter)

## 环境

- Flutter 3.44.x
- Dart 3.12.x

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

## 设计文档

- 概要设计: [docs/superpowers/specs/2026-06-09-hot-ai-app-design.md](docs/superpowers/specs/2026-06-09-hot-ai-app-design.md)
- 实施计划: [docs/superpowers/plans/2026-06-09-hot-ai-app-mvp.md](docs/superpowers/plans/2026-06-09-hot-ai-app-mvp.md)

## 关联项目

- Web 端: `../hot-ai-frontend/` (Nuxt 3)
- 后端: `../hot-ai-backend/` (Go Zero 微服务)
- Agent: `../hot-ai-agent/` (Python FastAPI)
- 设计/需求: `../hotAI/`

## License

Apache License 2.0

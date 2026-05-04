# Quantum Mechanics Lab

Quantum Mechanics Lab 是一个面向 iPadOS/macOS 的量子力学可视化实验台。项目目标是提供一个本地运行、无后端依赖的交互式学习工具，用 Split-Step Fourier Method 演示波函数随时间演化、势场响应、二维干涉/散射和氢原子轨道等核心主题。

当前分发路线限定为：

- GitHub 托管源码、文档、测试和构建脚本。
- TestFlight 用于学生、教师和测试者的 beta 邀测。
- 不维护其它公开分发物料或第三方渠道发布流程。

## 当前能力

- **20 个实验模块**：包含 1D 基础实验、2D 双缝/势垒/中心势等环境，以及氢原子轨道可视化。
- **数值核心**：1D/2D split-operator 求解器、复数/网格/势能/可观测量模型、氢轨道求值与相位映射。
- **Metal 渲染**：2D 波函数使用 `MTKView`、`MTLTexture` 和自定义 shader 进行纹理渲染。
- **交互体验**：暂停时拖动波包、运行时点击测量、Apple Pencil 或指针绘制自定义 1D 势场。
- **本地持久化**：自定义势场 preset 使用 `UserDefaults` 保存、载入和删除。
- **数据导出**：支持 JSON snapshot 和 1D CSV 导出，便于复现实验状态和检查数值数据。
- **测试覆盖**：XCTest 覆盖实验目录、范数守恒、能量漂移、势场几何、氢轨道 sanity checks 等核心行为。

## 目录结构

- `project_plan.md`：英文项目计划。
- `project_plan_zh.md`：中文项目计划。
- `Package.swift`：SwiftPM 包配置，包含 core、app shell、smoke executable 和 XCTest target。
- `Sources/QuantumMechanicsLabCore`：模拟核心、实验协议、实验目录、1D/2D 求解器和轨道计算。
- `Sources/QuantumMechanicsLabApp`：SwiftUI app shell、导航、inspector、时间控制、绘图、导出和 Metal 渲染视图。
- `Tests/QuantumMechanicsLabCoreTests`：数值和模型回归测试。
- `scripts/generate_xcode_project.swift`：重新生成 iPadOS Xcode 工程。
- `scripts/package_macos_app.sh`：打包本地 macOS 预览 app。
- `docs/local_validation.md`：本地验证流程。
- `UITestPlan.md`：手动 UI 和交互测试计划。
- `CHANGELOG.md`：项目变更记录。

## 本地验证

SwiftPM 验证：

```bash
swift build
swift test
swift run QuantumMechanicsLabCoreSmokeTests
```

macOS 本地预览：

```bash
scripts/package_macos_app.sh
open dist/QuantumMechanicsLab.app
```

重新生成 Xcode 工程：

```bash
swift scripts/generate_xcode_project.swift
```

iOS Simulator 构建：

```bash
xcodebuild -project QuantumMechanicsLab.xcodeproj \
  -scheme QuantumMechanicsLab \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/QuantumMechanicsLabDerived \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

## Xcode Targets

`QuantumMechanicsLab.xcodeproj` 包含：

- `QuantumMechanicsLabCore`：模拟、实验和持久化相关核心代码。
- `QuantumMechanicsLab`：iPadOS SwiftUI 应用壳。
- `QuantumMechanicsLabCoreTests`：数值和模型回归测试。

新增 Swift 源文件后应重新运行 project generator，避免 Xcode 工程源文件列表落后于 SwiftPM 包目录。

## GitHub + TestFlight 工作流

1. 在 GitHub 上维护 `main` 分支、issue、milestone、测试说明和 changelog。
2. 每次 beta 前运行 SwiftPM 测试、smoke executable、Xcode simulator `build-for-testing` 和手动 UI 检查。
3. 使用 tag 标记可测试版本，例如 `v0.2.0-beta.1`。
4. 通过 TestFlight 邀请小规模物理学习者、教师和技术测试者。
5. 将反馈转成 GitHub issue，按数值正确性、交互阻塞、性能退化和教学清晰度排序处理。

## 当前优先级

- 重新生成 Xcode 工程并确认 simulator `build-for-testing` 通过。
- 补齐本地一键验证脚本，把 SwiftPM、smoke、Xcode 构建和 macOS 预览打包串起来。
- 继续打磨 2D Metal 渲染、preset 管理、实验说明和手动 UI 验收流程。

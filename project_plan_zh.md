# 具体项目计划

## 产品定义

**暂定名称：** Quantum Mechanics Lab。

**目标用户：** 正在学习或教授本科量子力学的 iPad 用户。这个应用应该让时间演化、测量直觉、隧穿、干涉、不确定性和轨道结构变得可以直接观察，而不是只停留在公式描述上。

**核心产品循环：**

1. 从实验目录中选择一个实验。
2. 调整少量有物理意义的参数。
3. 运行、暂停、拖动时间轴、重置模拟。
4. 检查波函数、势能、期望值和守恒诊断。
5. 在不丢失当前状态的情况下切换可视化模式。

**v1 目标：**

- 发布一个单体 iPadOS 应用，不需要账号系统，也不需要后端。
- 提供稳定的 1D 模拟、手感明确的 Apple Pencil 自定义势能工作流、2D 干涉实验，以及解析形式的氢原子轨道。
- 通过范数、能量、期望值叠加层和教科书参考案例，让正确性可见。
- 在支持的 iPad 上保持交互响应；性能不足时先降低分辨率，而不是牺牲 UI 响应。

**v1 非目标：**

- 不做多体模拟、场论、通用 PDE 编辑器、云端项目、社交分享或研究级求解器声明。
- 不做符号代数引擎。
- v1 不做 LLM 导师。只有当核心应用反馈良好时，才把导师功能作为发布后的扩展。

## 技术栈与约束

**技术栈：** Swift 6、SwiftUI、Accelerate（vDSP 用于 FFT 和线性代数）、Metal（用于 2D 渲染）、SceneKit（用于 3D 轨道）、Swift Charts（用于能级图）。目标平台为 iPadOS 18+。v1 无后端。

**设备假设：**

- 基线目标：较新的 iPad Air / iPad Pro，能够流畅运行 60fps SwiftUI 和 Metal 渲染。
- 1D 模拟应能在 1024 到 4096 个网格点下稳定运行。
- 2D 模拟默认使用 256 x 256，并在性能设置中提供 128 x 128 / 256 x 256 / 512 x 512。
- 如果连续错过帧预算，先降低模拟发布频率或网格分辨率，再考虑牺牲视觉精度；不能阻塞触摸输入。

**质量标准：**

- 普通帧的主线程工作量保持在 4ms 以内。
- 目标硬件上的 1D 模拟批处理控制在 8ms 以内。
- 256 x 256 下，2D 模拟加纹理上传应保持在帧预算内。
- Pencil 绘制延迟目标：从笔迹更新到势能预览更新低于 20ms。
- 当范数或能量诊断显示数值失败时，应用不能继续展示看似正常归一化的模拟。

## 架构

**架构：** 单体 iPad 应用，设备端模拟，使用基于 `@Observable` 宏的 MVVM。模拟在后台 actor 中运行，并以显示刷新率向主 actor 发布 psi 快照。实验采用模块化设计：每个实验都是一个符合 `Experiment` 协议的自包含模块，因此后续新增实验应是机械性的。

### 建议目录结构

```text
QuantumMechanicsLab/
  App/
    QuantumMechanicsLabApp.swift
    AppModel.swift
    NavigationShell.swift
  Experiments/
    Experiment.swift
    ExperimentCatalog.swift
    OneD/
      InfiniteSquareWellExperiment.swift
      HarmonicOscillatorExperiment.swift
      FiniteBarrierExperiment.swift
      FreeWavepacketExperiment.swift
      CustomPotentialExperiment.swift
    TwoD/
      DoubleSlit2DExperiment.swift
      BarrierScattering2DExperiment.swift
    Orbitals/
      HydrogenOrbitalExperiment.swift
  Simulation/
    ComplexBuffer.swift
    Grid1D.swift
    Grid2D.swift
    SchrodingerSolver1D.swift
    SchrodingerSolver2D.swift
    SimulationActor.swift
    SimulationSnapshot.swift
    Observables.swift
    Units.swift
  Rendering/
    WavefunctionCanvas1D.swift
    PotentialCanvas1D.swift
    PhaseColorMap.swift
    MetalWavefunctionView2D.swift
    OrbitalSceneView.swift
  Controls/
    InspectorPanel.swift
    TimelineControls.swift
    ParameterControls.swift
    DebugOverlay.swift
  Persistence/
    ExperimentPreset.swift
    LocalProjectStore.swift
  Tests/
    NumericalReferenceTests.swift
    ExperimentConfigurationTests.swift
```

### 核心数据流

1. `NavigationShell` 持有当前选中的实验 ID，并展示目录、视口和检查器。
2. `ExperimentViewModel` 创建实验配置，并启动或停止 `SimulationActor`。
3. `SimulationActor` 持有可变求解器状态并按批运行。它通过 `AsyncStream` 发出 `SimulationSnapshot`。
4. View model 在主 actor 上接收快照，并更新渲染所需状态。
5. 渲染器消费不可变快照数据。视图不能直接修改求解器内部状态。
6. 检查器的编辑会生成类型化参数更新。actor 在步进边界应用更新，避免状态撕裂。

### 协议形状

```swift
protocol Experiment: Identifiable, Sendable {
    associatedtype Parameters: Codable & Sendable
    associatedtype Snapshot: Sendable

    var id: String { get }
    var title: String { get }
    var category: ExperimentCategory { get }
    var defaultParameters: Parameters { get }
    var story: [StoryStep] { get }

    func makeInitialState(parameters: Parameters) throws -> ExperimentInitialState
    func makeSolver(parameters: Parameters) throws -> any ExperimentSolver
    func validate(parameters: Parameters) -> [ParameterIssue]
}
```

实现时保持具体协议简单。如果 associated type 让目录层变得笨重，就在应用边界使用 `AnyExperiment` 做类型擦除。

### 快照形状

```swift
struct SimulationSnapshot: Sendable {
    let experimentID: String
    let time: Double
    let grid: GridDescriptor
    let psi: ComplexBuffer
    let potential: PotentialBuffer?
    let observables: Observables
    let diagnostics: NumericalDiagnostics
}

struct NumericalDiagnostics: Sendable {
    let norm: Double
    let energy: Double?
    let energyDrift: Double?
    let maxProbabilityDensity: Double
    let stepCount: Int
    let warning: NumericalWarning?
}
```

快照应当接近值类型，并且可以安全用于渲染。避免把求解器持有的可变数组直接暴露给 SwiftUI 或 Metal。

### 持久化

- 将用户预设和上次打开的实验状态作为 Codable JSON 存在本地。
- 对颜色映射、单位和偏好的 2D 分辨率等小设置使用 `UserDefaults` 或 `AppStorage`。
- 只有当明确需要可搜索项目库时再引入 SwiftData。
- 导出/导入可以放到 v1 之后，除非 beta 用户强烈需要。

## 数值设计

### 单位

v1 使用无量纲模拟单位：

- `hbar = 1`
- 默认质量 `m = 1`
- 1D 区间 `x in [-L/2, L/2]`
- 能量和时间默认显示为无量纲量

检查器里可以添加教学用单位说明，但 v1 不承诺 SI 单位下的物理校准。

### 1D Split-Operator 求解器

使用 split-operator 方法：

```text
psi(t + dt) =
  exp(-i V dt / 2 hbar)
  FFT^-1[exp(-i p^2 dt / 2m hbar) FFT[exp(-i V dt / 2 hbar) psi(t)]]
```

实现细节：

- 针对每个 `(N, L, m, dt)` 组合预计算动量网格和动能相位因子。
- 每当 `V(x)` 或 `dt` 改变时，预计算势能半步相位因子。
- 使用 2 的幂次网格尺寸以提升 FFT 性能。
- 精确归一化初始波函数。不要每帧静默重新归一化，除非这是调试设置，因为持续重新归一化会掩盖求解器错误。
- 只有明确需要开放空间行为的实验才使用吸收边界。
- 参数变化应在求解器步进边界应用。对于较大的不连续参数变化，显示简短诊断警告，而不是假装之前的能量仍应守恒。

### 边界条件

FFT split-operator 方法天然假设周期边界。这个实现细节必须从用户看到的物理现象中隐藏起来：

- 对开放空间实验，把波包放在远离周期接缝的位置，并在边缘附近可选使用吸收边界 mask。
- 对有限势垒和自定义势能，让有物理意义的区域远离周期接缝。
- 对无限深势阱，在更大的计算区间内使用陡峭墙势，使概率密度在 FFT 接缝处可以忽略。
- 不要把周期接缝当作反射墙使用。
- 如果要严格验证无限深势阱本征态，增加一个小型 sine-basis / Dirichlet 边界参考求解器，或只在墙势近似有效的区域和解析态比较。

默认值：

```text
N = 2048
L = 20
dt = 0.001 to 0.005 depending on experiment
snapshotPublishRate = display refresh rate, usually 60Hz
stepsPerSnapshot = derived from dt and playback speed
```

### 可观测量

计算并暴露：

- 范数：`sum |psi|^2 dx`
- 位置期望：`<x>`
- 动量期望：`<p>`
- 位置方差：`Delta x`
- 动量方差：`Delta p`
- 不确定性乘积：`Delta x * Delta p`
- 总能量：`<T> + <V>`
- 相对初始能量的漂移

这些诊断既用于 UI 叠加层，也用于自动化测试。

### 参考案例

使用教科书案例作为回归检查：

| 案例 | 预期行为 | 测试容差 |
| --- | --- | --- |
| 无限深势阱本征态 | 在 Dirichlet 参考解或经过验证的墙势模型中，概率密度静止、相位旋转 | 范数误差 < 1e-6，能量漂移 < 1e-4 |
| 自由 Gaussian 波包 | 中心线性运动，波包扩散 | `<x>` 斜率误差在 1 percent 内 |
| 谐振子 coherent-state-like 波包 | `<x>` 正弦振荡 | 周期误差在 1 percent 内 |
| 有限势垒 | 反射 + 透射，总范数守恒 | 范数误差 < 1e-5 |
| 2D 双缝 | 下游形成干涉条纹 | 视觉检查 + 条纹间距统计检查 |

## UX 结构

### 主应用布局

- 使用 `NavigationSplitView`。
- 侧边栏：实验目录，按 1D、2D 和 3D 解析轨道分组。
- 中央：主视口。它始终应该是最大的视觉元素。
- 右侧检查器：参数、可视化模式、可观测量和调试诊断。
- 底部叠加层：播放/暂停、重置、速度和时间拖动条。

### 可视化模式

1D：

- 概率密度 `|psi|^2`
- 实部
- 虚部
- 相位颜色
- 势能叠加
- `<x>` 期望标记和不确定性带

2D：

- 概率热力图
- 以密度为亮度、相位为色相
- 势能 mask 叠加
- 可选的高密度等高线

3D 轨道：

- 密度等值面
- 对有意义的轨道使用相位或符号着色
- 场景旁显示能级图

### 检查器控件

使用最小但足够的控件：

- 对质量、波包宽度、势垒高度和播放速度等连续值使用滑块。
- 对 `(n, l, m)` 这类合法值离散的量使用步进器。
- 对可视化模式使用分段控件。
- 对叠加层使用 toggle 控件。
- 对常用配置使用预设菜单。
- 提供重置按钮，将实验恢复到默认状态。

参数标签可以在有帮助时使用物理记号，但每个控件还需要一个普通语言的 accessibility label。

### Story Mode

每个实验都应有一段简短 story 脚本：

- 每个实验 3 到 6 步。
- 每一步设置或高亮一个参数，指向视口中的一个区域，并说明正在展示的概念。
- Story mode 应该是可选且可关闭的。
- Story 脚本是本地数据，不要硬编码在 view body 里。

## Phase 1 - 基础建设（第 1-3 周）

**目标：** 用一个正确且可检查的实验证明完整应用管线。

### 第 1 周：应用壳和数值骨架

- 创建带 SwiftUI lifecycle 的 Xcode 项目。
- 添加 `NavigationSplitView` 壳，包含占位实验目录、视口、检查器和时间线控件。
- 实现 `ComplexBuffer`、`Grid1D` 和单位辅助类型。
- 构建支持开始、暂停、重置、速度和取消的 `SimulationActor`。
- 添加最小 `Experiment` 协议和 `ExperimentCatalog`。
- 添加包含时间、步数和 FPS 的占位调试叠加层。

交付物：选择 “Infinite Square Well” 后能启动占位模拟并发布快照，同时不阻塞 UI。

### 第 2 周：1D 求解器

- 使用 split-operator 方法实现 `SchrodingerSolver1D`。
- 添加 vDSP FFT 设置和 plan 复用。
- 实现 Gaussian 波包初始化。
- 使用 guard region 实现无限深势阱墙势，确保概率密度远离 FFT 接缝。
- 计算范数和能量诊断。
- 添加归一化、FFT round trip、墙反射，以及验证区域内 stationary-state 行为测试。

交付物：Gaussian 波包在盒中演化，范数稳定。

### 第 3 周：第一个可用实验

- 使用 SwiftUI `Canvas` 将 `|psi|^2` 渲染为折线图。
- 叠加势能边界和期望值标记。
- 添加播放、暂停、重置、速度和时间拖动条控件。
- 添加显示范数、能量和能量漂移的调试叠加层。
- 为无限深势阱添加一个 guided story。
- 调整默认 `N`、`dt` 和速度，让运动在视觉上易读。

**退出标准：** Gaussian 波包能在盒中以 60fps 反弹，调试叠加层可见能量和范数守恒。范数应接近 `1.000`，除非有刻意参数变化，否则能量应保持平坦。

## Phase 2 - 核心 1D 实验（第 4-6 周）

**目标：** 建立可复用的 1D 实验系统，并用多个经典案例证明它。

### 实验

1. 谐振子：
   - 势能：`V(x) = 0.5 m omega^2 x^2`
   - 参数：质量、omega、初始中心、初始动量、波包宽度
   - 参考行为：coherent-state-like 波包振荡

2. 有限势垒：
   - 势能：可编辑宽度和高度的矩形势垒
   - 参数：势垒高度、势垒宽度、波包动量、波包宽度
   - 参考行为：反射加隧穿

3. 自由 Gaussian 波包：
   - 势能：零势能或可选吸收边界
   - 参数：初始中心、动量、宽度、质量
   - 参考行为：线性运动和扩散

4. 无限深势阱：
   - 继续作为稳定基线和测试目标

### 共享功能

- 支持实时参数绑定的检查器面板。
- 带明确边界和重置行为的参数验证。
- 可视化模式：概率密度、实部、虚部和相位颜色。
- 期望值叠加层：`<x>`、`<p>`、`Delta x`、`Delta p` 和 `Delta x * Delta p`。
- 显示能量漂移的图表。
- 每个实验提供预设，例如 “low energy”、“near barrier top”、“wide packet”。

### 实时参数规则

- 仅影响视觉的设置立即生效。
- 物理参数变化在下一个求解器步进边界更新。
- 会使当前波函数失效的变化，例如区间长度或网格分辨率，需要重置。
- 播放过程中改变势垒或势能时，保留波函数，但重置能量漂移基线，因为 Hamiltonian 已改变。

**退出标准：** 四个 1D 实验可用，物理和数值上允许的参数可以实时调整，普通预设下全部稳定，并且参考测试通过。

## Phase 3 - Apple Pencil 自定义势能（第 7-8 周）

**目标：** 让应用形成触觉明确的差异化体验。

### 自定义势能编辑器

- 构建绘图画布，横向位置映射到 `x`，纵向位置映射到 `V(x)`。
- 将 Pencil 笔迹采样到求解器分辨率的势能数组。
- 使用可配置低通滤波平滑笔迹，避免手抖产生极端高频势能。
- 将势能限制在可见且数值安全的范围内。
- 即使模拟暂停，也要在绘制时显示势能曲线。
- 添加撤销、清空和预设操作。

### 预设

- Square well
- Double well
- Ramp
- Barrier
- Soft harmonic trap
- Random smooth landscape

### 释放波包手势

- 点击放置波包中心。
- Flick 手势根据速度设置初始动量。
- 捏合或检查器滑块设置波包宽度。
- 释放前显示一个短暂 ghost preview，展示中心、方向和宽度。

### 延迟方案

- Pencil 笔迹更新应立即在主 actor 上更新轻量预览。
- 求解器接收合并后的势能更新，而不是每个原始 Pencil 事件。
- 势能相位因子在模拟 actor 上经过短 debounce 后重新计算；绘制时目标为每秒 30 到 60 次更新。
- 如果重计算跟不上，保持绘制顺滑，并只应用最新势能。

**退出标准：** 绘制势能并看到波函数响应应感觉即时，在目标硬件上 Pencil 输入和模拟反馈之间没有可感知延迟。

## Phase 4 - 2D 与 Metal（第 9-12 周）

**目标：** 增加 2D 干涉和散射，同时不牺牲交互响应。

### 求解器

- 实现 `Grid2D` 和 `SchrodingerSolver2D`。
- 使用可分离 2D FFT 操作：先变换行，再变换列，然后逆变换列和行。
- 默认网格为 `256 x 256`；旧设备支持 `128 x 128`，高端设备支持 `512 x 512`。
- 预计算 `kx`、`ky` 和动能相位。
- 保持 2D 快照紧凑，避免向主 actor 复制不必要的中间缓冲。

### Metal 渲染器

- 将概率密度和相位存储到 Metal texture 中。
- 使用密度作为亮度、相位作为色相。
- 添加适合课堂投影和色觉无障碍的颜色映射。
- 支持捏合缩放和平移，且不强制重置模拟。
- 主场景应在中央视口内全屏展示，不要放进装饰性框中。

### 实验

1. 2D 双缝：
   - 可编辑缝间距、缝宽、屏障厚度、波包动量和波包宽度。
   - 展示下游干涉图样逐渐形成。
   - 添加可选 detector-line profile 图。

2. 2D 势垒散射：
   - 可编辑矩形或圆形势垒。
   - 展示反射、衍射和透射波前。

### 性能策略

- 模拟 actor 按批推进。
- 渲染器使用最新可用快照，并丢弃过期快照。
- 在设置中提供分辨率选择器。
- 添加内部性能 HUD：FPS、每批模拟耗时、纹理上传时间和内存。

**退出标准：** 2D 双缝在 256 x 256 网格下以 60fps 运行，干涉图样能明显形成，且没有触摸输入延迟。

## Phase 5 - 3D 氢原子轨道（第 13-15 周）

**目标：** 添加解析 3D 可视化，补充基于求解器的实验。

### 解析模型

- 不需要时变求解器。
- 从径向函数和球谐函数计算氢原子波函数。
- 合法量子数：
  - `n >= 1`
  - `0 <= l < n`
  - `-l <= m <= l`
- 能量显示：理想氢原子模型中 `E_n` 只依赖 `n`。
- 默认使用无量纲 Bohr 半径单位。

### 渲染

- 为选定的 `(n, l, m)` 生成 3D 密度网格。
- 从密度构建等值面网格：可以使用 marching-cubes，也可以在性能足够时使用更简单的固定阈值网格。
- 在有意义时按相位或符号给表面着色。
- 使用 SceneKit 处理旋转、缩放、光照和相机控制。
- 按 `(n, l, m, resolution, threshold)` 缓存生成的网格。
- 用户拖动控件时使用较低网格分辨率，交互停止后再细化。

### UI

- 量子数步进器强制合法组合。
- 预设：`1s`、`2s`、`2p`、`3s`、`3p`、`3d`。
- 能级图显示选中壳层和相邻能级。
- Story mode 解释节点、角动量和简并。

**退出标准：** `1s`、`2s`、`2p` 和 `3d` 轨道都可以渲染和旋转，形状与标准教科书图片一致。

## Phase 6 - Beta 打磨与分发（第 16-18 周）

**目标：** 将原型转为稳定的 GitHub 托管 beta，并通过 TestFlight 分发给小范围学习者、教师和技术测试者。

### 产品打磨

- 首次启动 onboarding，直接进入一个简单实验。
- 每个发布实验都有 Story mode。
- 设置页：
  - 颜色方案
  - 单位显示
  - 性能模式
  - 默认网格分辨率
  - 无障碍选项
- 保存用户创建的自定义势能预设。
- App icon、launch screen、beta 截图和简洁的 TestFlight 更新说明模板。

### 无障碍

- 每个控件和重要可视化区域都提供 VoiceOver label。
- 检查器文本和 story 内容支持 Dynamic Type。
- 支持 Reduce Motion，照顾不希望连续动画的用户。
- 颜色映射尽可能避免只用颜色传达信息。
- 为课堂和 Pencil 使用提供足够大的触控目标。

### QA

- 每次构建都运行数值参考测试。
- 为每个实验添加手动测试脚本。
- 测试旋转、Split View、Stage Manager resize 和低电量模式。
- 至少测试两种 iPad 尺寸。
- 同时测试 Pencil 和非 Pencil 交互路径。
- 在长时间模拟中检查内存泄漏。

### Beta

- 通过 TestFlight 邀请 10 到 20 名物理学生、教师或有技术背景的学习者。
- 收集以下反馈：
  - 哪些实验最容易理解
  - 哪些参数让人困惑
  - Story mode 是帮助理解还是造成干扰
  - 真实设备性能
  - 缺少哪些课堂工作流
- 将反馈转为 GitHub issue；在标记下一个 beta 前，修复或明确延期最高影响的可用性、正确性和性能问题。

**退出标准：** GitHub beta tag 和 TestFlight 构建可用，模拟稳定，教育价值清晰，没有已知阻塞级数值或交互 bug。

## Phase 7 - 可选 LLM 导师（发布后）

只有当 v1 反馈良好时再做。构建一个 Cloudflare Worker 代理 Anthropic API，密钥只保存在 Worker 中，并接收描述当前实验和用户问题的结构化 payload。在应用内添加 “Ask about this” 按钮，打开一个带当前状态上下文的聊天 sheet。这是唯一需要后端的部分，也应该保持很小。

### 导师功能范围

- 导师回答与当前可见实验有关的问题。
- 它接收结构化状态，而不是原始截图：
  - 实验 ID
  - 当前参数
  - 时间
  - 当前可视化模式
  - 关键可观测量
  - 当前 story 步骤
- 它不能声称数值模型超出应用文档假设之外仍然精确。

### 后端保护措施

- API key 只保存在 Worker 中。
- 添加速率限制。
- 默认不存储聊天日志。
- 启用功能前给出清晰隐私说明。
- 设置中提供关闭开关。

## 测试策略

### 单元测试

- 复数运算辅助函数。
- FFT round trip。
- 网格间距和动量网格构造。
- 初始态归一化。
- 势能生成。
- 可观测量计算。
- 参数验证。

### 数值回归测试

- 无限深势阱本征态 stationary 行为。
- 自由 Gaussian 波包中心和扩散。
- 谐振子周期。
- 势垒范数守恒。
- 低分辨率 2D 双缝 smoke test。
- 轨道量子数验证和已知形状 sanity check。

### UI 测试

- 启动应用并选择每个实验。
- 启动、暂停、重置和拖动时间轴。
- 修改常用参数。
- 切换可视化模式。
- 保存并重新加载自定义势能预设。
- 旋转 3D 轨道。

### 手动验收清单

- 离开视图后没有模拟继续运行。
- 重置总是回到已知默认状态。
- 参数变化不能导致求解器崩溃。
- 调试叠加层报告警告，而不是静默失败。
- 长时间模拟不会内存泄漏。
- iPad 旋转或 resize 后应用仍可用。

## 风险登记

| 风险 | 影响 | 缓解措施 |
| --- | --- | --- |
| 2D 模拟无法达到 60fps | 核心视觉功能显弱 | 尽早加入分辨率缩放、快照丢弃和性能模式 |
| Pencil 势能更新导致求解器卡顿 | 差异化功能手感变差 | 将绘图预览与求解器更新分离；对势能重计算 debounce |
| 数值诊断误导用户 | 用户学到错误行为 | 使用参考测试，并在假设失效时显示警告 |
| SceneKit 轨道网格生成太慢 | 3D 功能显得笨重 | 缓存网格并使用渐进细化 |
| 检查器过于复杂 | 学习者迷失 | 突出预设，逐步暴露高级参数 |
| Story 内容拖慢发布 | v1 延期 | 写短脚本，不写教科书章节 |

## 里程碑摘要

| 阶段 | 周期 | 主要交付物 | 发布价值 |
| --- | --- | --- | --- |
| 1 | 第 1-3 周 | 无限深势阱端到端 | 证明架构和求解器 |
| 2 | 第 4-6 周 | 四个经典 1D 实验 | 核心教育价值 |
| 3 | 第 7-8 周 | Apple Pencil 自定义势能 | 差异化交互 |
| 4 | 第 9-12 周 | 2D 双缝和散射 | 高影响力可视化 |
| 5 | 第 13-15 周 | 氢原子轨道 | 覆盖常见量子力学课程内容 |
| 6 | 第 16-18 周 | Beta、打磨、GitHub + TestFlight | 可评审的 v1 beta |
| 7 | 发布后 | 可选上下文导师 | 扩展功能，不是 v1 依赖 |

## v1 完成定义

- Phase 1 到 Phase 6 的所有退出标准都满足。
- 数值参考测试通过。
- 手动 QA 清单至少在两种 iPad 配置上完成。
- 应用没有后端依赖。
- 默认设置下，应用可以连续运行 10 分钟模拟，没有可见漂移、内存增长或 UI 卡顿。
- TestFlight 反馈已审阅，阻塞问题已修复或明确延期。
- GitHub release notes、beta 截图、隐私说明和 TestFlight 测试者指引准备完毕。

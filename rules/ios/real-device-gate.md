# iOS 真机验证门控

> **适用范围**：所有 iOS 原生项目（Swift / SwiftUI），涉及硬件依赖或平台专属功能时必须执行。

## 为什么需要真机验证

iOS 模拟器运行在 macOS 上，使用宿主机的 CPU 和内存，**没有真实的硬件传感器和专用芯片**。以下场景在模拟器中要么完全不可用，要么行为与真机存在显著差异，仅靠模拟器验收无法保证产品质量。

## 必须真机验证的场景清单

以下场景涉及模拟器无法覆盖的硬件能力或平台行为差异，**必须在真机上完成验证**：

| 场景 | 原因 | 模拟器行为 |
|------|------|-----------|
| 相机硬件调用 | `AVCaptureSession`、`UIImagePickerController` 需要物理摄像头 | 无摄像头设备，调用返回空或崩溃 |
| Vision Framework ANE 加速性能 | Apple Neural Engine 仅存在于 A12+ 芯片 | 模拟器使用 CPU fallback，性能差异巨大 |
| SwiftData `#Predicate` Date 比较 bug | 真机和模拟器对 Date 比较的内部实现不同 | 模拟器可能通过，真机返回错误结果 |
| 推送通知（APNs） | 需要真机的 device token 向 APNs 注册 | 模拟器使用本地通知替代，无法验证远程推送 |
| HealthKit / CoreMotion 等传感器 API | 需要物理传感器硬件 | API 不可用，调用直接失败 |
| App Clips / Safari Extensions | 仅真机可用的系统功能 | 完全不可用 |

## 门控检查项（Gate Checks）

所有 iOS 项目在标记 Done 前必须依次通过以下门控检查。每个检查项标注为 **[强制]** 或 **[建议]**：

### Gate 1: 编译通过（模拟器）— [强制]

模拟器编译是最低门槛，确保代码无语法和链接错误。

```bash
xcodebuild -workspace <ProjectName>.xcworkspace \
  -scheme <ProjectName> -configuration Release \
  -destination "platform=iOS Simulator,name=iPhone 16" build
```

> 必须通过才能进入 Gate 2。编译失败则立即修复，不进入后续门控。

### Gate 2: 真机连接检测 — [强制]

确认有可用的真机设备连接到开发机器。

```bash
# 列出所有已连接设备
xcrun xctrace list devices

# 检查是否有真机（非 Simulator）在线
xcrun xctrace list devices | grep -v "Simulator" | grep "iPhone\|iPad"
```

> 如果没有真机连接，跳过 Gate 3 / Gate 4，但在验收评论中标注"无真机可用，仅完成模拟器验收"。

### Gate 3: 真机安装 — [强制]

将构建产物安装到真机，验证签名和部署流程。

```bash
# 构建并安装到真机
xcodebuild -workspace <ProjectName>.xcworkspace \
  -scheme <ProjectName> -configuration Release \
  -destination "id=<DEVICE_UDID>" build

# 或使用 DEVELOPMENT_TEAM 自动签名
xcodebuild -workspace <ProjectName>.xcworkspace \
  -scheme <ProjectName> -configuration Release \
  -destination "id=<DEVICE_UDID>" \
  DEVELOPMENT_TEAM=<TeamID> build
```

> Gate 2 检测到真机时必须执行。Gate 2 无真机时可跳过。

### Gate 4: 关键路径 UI smoke test — [建议]

验证核心用户流程在真机上的 UI 表现。

- 方式 A：通过 ios-simulator MCP 截图验证（模拟器环境）
- 方式 B：真机截图人工验证（需要真机 + Xcode Organizer）

```bash
# 方式 A：模拟器截图（MCP 工具）
# mcp__ios-simulator__screenshot

# 方式 B：真机截图（需 Xcode）
# 通过 Xcode → Window → Devices and Simulators → Download Screenshot
```

> 建议执行，尤其涉及复杂 UI 布局、动画、或安全区域适配时。

## 门控检查汇总

| Gate | 检查项 | 强制/建议 | 前置条件 |
|------|--------|----------|---------|
| Gate 1 | `xcodebuild build` 编译通过（模拟器） | **强制** | 无 |
| Gate 2 | `xcrun xctrace list devices` 真机检测 | **强制** | Gate 1 通过 |
| Gate 3 | `xcodebuild install` 安装到真机 | **强制** | Gate 2 检测到真机 |
| Gate 4 | 关键路径 UI smoke test | **建议** | Gate 3 通过（或模拟器环境） |

## 执行流程

```
Gate 1 (编译通过)
  │
  ├── 失败 → 修复编译错误，重新执行 Gate 1
  │
  └── 通过 → Gate 2 (真机检测)
                │
                ├── 无真机 → 跳过 Gate 3/4，标注"仅模拟器验收"
                │
                └── 有真机 → Gate 3 (真机安装)
                              │
                              ├── 失败 → 检查签名/描述文件，重新执行 Gate 3
                              │
                              └── 通过 → Gate 4 (UI smoke test)
```

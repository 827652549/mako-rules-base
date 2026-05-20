# Swift 编码规范

> **适用范围**：仅适用于 iOS 原生项目（Swift / SwiftUI）。

## 命名约定

| 类别 | 规则 | 示例 |
|------|------|------|
| 类型 / 结构体 / 枚举 | PascalCase | `PetProfileView`, `FeedItem` |
| 变量 / 函数 / 属性 | camelCase | `profileImage`, `fetchPets()` |
| 常量 | camelCase（Swift 惯例） | `maxRetryCount` |
| 枚举 case | camelCase | `.loading`, `.success` |
| 文件名 | 与主类型一致（PascalCase） | `PetProfileView.swift` |

## 代码风格

- 4 空格缩进（Xcode 默认）
- 行宽不超过 120 字符
- 优先使用 `struct` 而非 `class`（除非需要引用语义或继承）
- 优先使用 `let` 而非 `var`

## SwiftUI 组件规范

- 每个视图文件只包含一个主 View 及其 `#Preview`
- 复杂视图拆分为子视图，每个子视图不超过 50 行
- 避免在 View body 中直接写业务逻辑，抽取到 ViewModel 或 computed property

```swift
struct PetCardView: View {
  let pet: Pet

  var body: some View {
    VStack(alignment: .leading) {
      petAvatar
      petInfo
    }
  }

  private var petAvatar: some View {
    // ...
  }
}

#Preview {
  PetCardView(pet: .mock)
}
```

## 状态管理

- 局部状态：`@State`
- 父子数据传递：`@Binding`
- 跨视图共享：`@Observable`（iOS 17+）/ `@StateObject` + `@ObservedObject`
- 禁止在 View 中直接执行网络请求，通过 ViewModel 或 async 函数封装

## 异步处理

- 优先使用 `async/await`，避免回调嵌套
- 网络请求在 Task 中执行，错误通过 `do/catch` 捕获

```swift
func loadPets() async {
  do {
    pets = try await petService.fetchAll()
  } catch {
    errorMessage = error.localizedDescription
  }
}
```

## 目录结构

```
Sources/
├── App/                  # App entry point, AppDelegate
├── Features/             # 按功能模块组织
│   └── PetProfile/
│       ├── PetProfileView.swift
│       └── PetProfileViewModel.swift
├── Core/                 # 跨模块基础设施
│   ├── Network/
│   └── Storage/
├── Models/               # 数据模型（struct/class）
└── Resources/            # Assets, Localizable.strings
```

## 代码质量

- 提交前通过 `swiftlint`（如项目已集成）
- 禁止提交含 `TODO:` 或 `FIXME:` 的代码，除非在 PR 中说明
- `print()` 仅用于调试，生产代码改用 `Logger`（os.log）

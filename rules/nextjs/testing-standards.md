# 测试规范（Next.js）

> 通用测试原则见 `base/testing-standards.md`。

## 测试框架

| 类型 | 工具 |
|------|------|
| 单元 / 组件测试 | Jest + React Testing Library |
| 端到端测试 | Cypress |
| API 测试 | SuperTest |

## 单元测试准则

- 为每个组件和工具函数编写单元测试
- 使用 `test.each` 处理参数化测试
- 快照测试只用于纯展示组件，逻辑组件优先断言行为

## 示例

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import Button from './Button';

describe('Button', () => {
  it('renders label', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

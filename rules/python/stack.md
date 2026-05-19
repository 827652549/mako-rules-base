# Python 项目技术栈规范

> **适用范围**：仅适用于 Python 后端项目（FastAPI 为主）。

## 技术栈

| 类别 | 选型 | 说明 |
|------|------|------|
| 框架 | FastAPI | 异步优先，自动 OpenAPI 文档 |
| ORM | SQLAlchemy 2.x（async） | 配合 asyncpg |
| 迁移 | Alembic | 只用 alembic 生成迁移，禁止手写 |
| 数据库 | PostgreSQL | |
| 数据校验 | Pydantic v2 | 所有请求/响应模型必须用 Pydantic |
| 包管理 | uv（首选）/ pip + venv | |
| Python 版本 | 3.11+ | |
| 测试 | pytest + pytest-asyncio | |

## 依赖与虚拟环境

```bash
# 推荐：uv 管理
uv venv && uv pip install -r requirements.txt

# 传统方式
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

- 所有依赖声明在 `requirements.txt`（生产）和 `requirements-dev.txt`（开发）
- 禁止全局安装业务依赖

## 代码风格

- 使用 `ruff` 做 lint + format（替代 flake8/black/isort）
- 4 空格缩进（PEP 8）
- 行宽不超过 100 字符
- 类型注解：所有函数参数和返回值**必须**有类型注解，禁止裸 `Any`

```python
# 正确
async def get_user(user_id: UUID) -> UserResponse:
    ...

# 错误
async def get_user(user_id):
    ...
```

## 命名约定

| 类别 | 规则 | 示例 |
|------|------|------|
| 变量 / 函数 | snake_case | `user_id`, `get_user()` |
| 类 / Pydantic 模型 | PascalCase | `UserResponse`, `CreatePostRequest` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 模块文件 | snake_case | `user_service.py` |

## 代码质量检查

```bash
ruff check .          # lint
ruff format --check . # format check
pytest                # 测试
```

提交前必须通过上述三项。

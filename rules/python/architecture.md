# Python 项目架构规范

> **适用范围**：仅适用于 FastAPI 后端项目。

## 标准目录结构

```
src/
├── main.py                 # FastAPI app 入口，挂载 router
├── api/
│   └── v1/
│       ├── __init__.py
│       ├── router.py       # 汇总所有子路由（include_router）
│       └── endpoints/      # 按资源拆分 endpoint 文件
│           ├── users.py
│           └── posts.py
├── core/
│   ├── config.py           # Pydantic Settings，读取环境变量
│   ├── database.py         # SQLAlchemy 引擎 + Session 工厂
│   └── security.py         # JWT / 密码哈希等安全工具
├── models/                 # SQLAlchemy ORM 模型（数据库表）
│   ├── base.py             # declarative_base()
│   └── user.py
├── schemas/                # Pydantic 请求/响应模型
│   └── user.py
├── services/               # 业务逻辑层（调用 repository）
│   └── user_service.py
├── repositories/           # 数据访问层（只操作数据库）
│   └── user_repository.py
└── migrations/             # Alembic 迁移文件（禁止手工修改）
    ├── env.py
    └── versions/
```

## 三层架构

```
API Endpoints (api/v1/endpoints/)
      ↓  调用
Services (services/)
      ↓  调用
Repositories (repositories/)
      ↓  操作
Database (SQLAlchemy / PostgreSQL)
```

- **Endpoints**：只做请求解析、响应封装，不含业务逻辑
- **Services**：业务逻辑，不直接操作数据库
- **Repositories**：所有数据库查询，返回 ORM 对象或 None
- 禁止跨层直接调用（Endpoint 不得直接调用 Repository）

## 配置管理

使用 Pydantic Settings 统一管理环境变量，禁止 `os.environ.get()` 散落在业务代码中：

```python
# core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    debug: bool = False

    model_config = {"env_file": ".env"}

settings = Settings()
```

## 数据库规范

- 所有表必须有 `id`（UUID）、`created_at`、`updated_at` 字段
- 迁移只通过 `alembic revision --autogenerate` 生成，禁止手写 SQL
- 破坏性迁移（删列、改类型）需在 PR description 中说明回滚方案

```python
# models/base.py
from sqlalchemy import Column, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
import uuid

class TimestampMixin:
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

## API 响应格式

遵循 `base/api-standards.md` 的统一结构，通过 Pydantic 模型封装：

```python
# schemas/common.py
from pydantic import BaseModel
from typing import Generic, TypeVar

T = TypeVar("T")

class ApiResponse(BaseModel, Generic[T]):
    data: T | None = None
    error: dict | None = None
```

## 测试规范

- 测试文件放在 `tests/`，结构镜像 `src/`
- 使用 `pytest-asyncio` 做异步测试
- 每个 endpoint 必须有集成测试（使用 `httpx.AsyncClient` + 真实数据库）
- 禁止 mock 数据库，用独立 test DB 或事务回滚隔离

```python
# tests/api/test_users.py
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_user(client: AsyncClient):
    response = await client.post("/api/v1/users", json={"email": "test@example.com"})
    assert response.status_code == 201
```

## 底线约束（必须遵守）

- 所有函数必须有类型注解
- Pydantic 模型用于所有 API 边界
- 禁止空 `except` 块
- 环境变量通过 `core/config.py` 统一读取

## 推荐实践（建议采用，可按项目调整）

- 按功能模块在 `endpoints/` 下拆分文件
- Services 层无状态，方便单元测试
- 使用 `async def` 的 endpoint 配合 `asyncpg` 提升并发性能

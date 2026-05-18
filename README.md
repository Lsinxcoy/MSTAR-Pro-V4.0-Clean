# MSTAR Pro V4.0

**M**ulti-**S**trategy **T**ask-**A**ware **R**eflection — Phase 0-7 全链路自进化系统

## 核心能力

| 能力 | 文件 | 说明 |
|------|------|------|
| DDTree 加速 | `mstar_core/acceleration/dd_tree.py` | 400-700% 性能提升 |
| 遗忘机制 | `mstar_core/memory/forgetting.py` | 低价值轨迹自动归档 |
| FitnessTracker | `mstar_core/evolution/fitness_tracker.py` | 适应度追踪 (5 维度) |
| EvolutionEngine | `mstar_core/evolution/engine.py` | 智能触发自进化 |
| Dashboard | `mstar_core/observability/dashboard_server.py` | 实时观测 (port 18792) |
| 安全沙箱 | `mstar_core/security/sanitizer.py` | 输入验证 + 内存清洗 |

---

## 在新实例上复现

MSTAR Pro V4.0 设计为**零外部依赖**（仅需 numpy + yaml），可通过 3 步快速部署到任意 Hermes Agent 实例。

### Step 0：环境要求

```bash
# 确认目标机器已安装 Hermes Agent
hermes --version

# 确认 Python 版本 (需要 3.10+，带 numpy)
python --version   # 需要 numpy（DDTree / 鲁棒性分析依赖）
```

### Step 1：复制 MSTAR 核心模块

把以下目录/文件复制到目标 Hermes Agent 的安装目录（与 `run_agent.py` 同级）：

```
mstar_core/                        # ← 36 个 Python 文件，核心引擎
plugins/context_engine/mstar/      # ← ContextEngine 插件
tools/mstar_tools.py               # ← MSTAR 工具集
tools/batch_tool.py                # ← 批量任务工具（可选）
```

**如何获取这些文件？**
- 选项 A：从本仓库（MSTAR-Pro-V4.0-Clean）下载 ZIP
- 选项 B：`git clone https://github.com/Lsinxcoy/MSTAR-Pro-V4.0-Clean.git`

### Step 2：配置 Hermes 集成（2 处改动）

#### 2.1 修改 `config.yaml`（在 `~/.hermes/config.yaml`）

在 `context:` 节下将 `engine` 设为 `mstar`，在 `memory:` 节下将 `provider` 设为 `mstar`：

```yaml
context:
  engine: mstar        # ← 启用 MSTAR ContextEngine（原有配置合并）

memory:
  provider: mstar      # ← 启用 MSTAR 记忆提供者（原有配置合并）
```

**完整改动（仅 2 行）：**

```bash
# 在 config.yaml 中找到 context: 和 memory: 节，分别加入：
#   context.engine: mstar
#   memory.provider: mstar
```

同时在顶级添加 MSTAR 配置块：

```yaml
mstar:
  dashboard_enabled: true
  dashboard_port: 18792
```

#### 2.2 修改 `run_agent.py`（集成钩子）

在 `AIAgent.__init__` 中找到 MSTAR 初始化块（约第 2000 行），确保触发条件为 `_mem_provider_name == "mstar"`：

```python
if _mem_provider_name == "mstar":
    from mstar_core import MSTARCore, SelfImprovingBridge
    _mstar_cfg = _agent_cfg.get("mstar", {})
    self._mstar_core = MSTARCore(
        hermes_home=str(get_hermes_home()),
        mode=_mstar_cfg.get("mode", "balanced"),
        fitness_dimensions=_mstar_cfg.get("fitness_dimensions", 20),
        dashboard_enabled=_mstar_cfg.get("dashboard_enabled", True),
        dashboard_port=_mstar_cfg.get("dashboard_port", 18792),
    )
    self._self_improver = SelfImprovingBridge(self._mstar_core)
```

> **如果目标 Hermes Agent 的 `run_agent.py` 中没有这段代码**，需要在 `AIAgent.__init__` 的适当位置（内存 provider 初始化后）插入上述代码块。参考本仓库的 `run_agent.py` 第 2001-2023 行。

### Step 3：重启 Hermes Agent

```bash
# 重启后 Dashboard 自动在 port 18792 启动
hermes restart

# 验证 MSTAR 已加载
curl http://localhost:18792/health
# 应返回：{"status": "ok", "sessions_processed": 0, ...}
```

---

## 依赖清单

| 依赖 | 来源 | 用途 |
|------|------|------|
| Python 3.10+ | 标准环境 | 运行环境 |
| numpy | pip install numpy | DDTree / 鲁棒性分析 |
| PyYAML | pip install pyyaml | 配置文件解析 |
| Hermes Agent | 目标实例 | 运行平台 |
| pydantic | (Hermes 内置) | 数据校验 |

**总计：mstar_core/ 仅 36 个 .py 文件，无需单独安装。**

---

## 项目结构

```
mstar_core/                       # 核心引擎（36 文件，可独立运行）
├── acceleration/dd_tree.py      #   DDTree 动态规划加速
├── attribution/                   #   失败归因（LIFE）
├── bridge/                       #   自进化桥接
│   └── self_improving.py         #     CorrectionSignal / ReinforcementSignal
├── config/                       #   配置管理
│   └── simplified.py             #     YAML 配置读取
├── evaluation/                   #   评估引擎
│   └── ablation_engine.py        #     消融实验
├── evolution/                    #   演化系统
│   ├── engine.py                 #     MSTARCore 主类
│   ├── evolvemem.py              #     EvolveMem 检索自进化
│   ├── experience_recall.py      #     经验回溯
│   ├── fitness_tracker.py         #     FitnessTracker
│   ├── predictor.py              #     LLMJudgePredictor / RuleBasedPredictor
│   ├── protocol.py               #     RSPL / SEPL 协议
│   ├── robustness.py             #     Bootstrap CI / 扰动测试
│   └── version_control.py        #     FGGM 版本控制
├── memory/                       #   记忆系统
│   ├── forgetting.py             #     遗忘机制
│   ├── mars_belief.py            #     MARS 信念状态
│   ├── program.py                #     MemoryProgram 数据类
│   └── router.py                 #     记忆路由
├── observability/                #   可观测性
│   ├── dashboard.py              #     Dashboard 主类
│   └── dashboard_server.py       #     HTTP 服务器（12 路由）
├── research/                     #   研究工具
│   └── ablation.py               #     消融研究
└── security/                    #   安全沙箱
    └── sanitizer.py              #     输入验证 / 内存清洗

plugins/context_engine/mstar/      # Hermes ContextEngine 插件
tools/mstar_tools.py              # MSTAR 工具集（暴露所有 API 给 Agent）
run_agent.py                      # 集成入口（需修改 AIAgent.__init__）
```

---

## 技术规格

- **Dashboard**: http://localhost:18792
- **数据库**: `~/.hermes/mstar_fitness.db`（SQLite，自动创建）
- **日志**: `~/.hermes/logs/`
- **触发条件**: 每 10 个 session 触发一次进化评估（可通过 `fitness_dimensions` 调整）
- **遗忘阈值**: 适应度 < 0.3 且 30 天无改进，自动归档

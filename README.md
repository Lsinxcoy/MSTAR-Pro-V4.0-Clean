# MSTAR Pro V4.0

**M**ulti-**S**trategy **T**ask-**A**ware **R**eflection — Phase 0-7 全链路自进化系统

## 核心能力

- **DDTree 动态策略搜索** — 400-700% 性能提升，支持 LLM/RL/经验回溯多模式
- **遗忘机制 (ForgettingMechanism)** — 动态归档低价值轨迹，保持记忆效率
- **FitnessTracker** — 多维度适应度追踪 (效果/效率/质量/鲁棒性/延迟)
- **EvolutionEngine** — 智能触发自进化，平衡探索与利用
- **Dashboard** — 实时观测 (port 18792)，无需重启
- **安全沙箱** — 轨迹验证 + 隔离清理，防止恶意代码扩散

## 项目结构

```
mstar_core/                    # MSTAR 核心引擎
  acceleration/dd_tree.py     # DDTree 动态策略搜索
  attribution/                 # 失败归因
  bridge/                      # 自进化桥接
  config/                      # 配置管理
  evaluation/                  # 评估引擎
  evolution/                   # 演化系统 (Engine/Predictor/Reflector)
  memory/                      # 记忆系统 (Forgetting/Router/Program)
  observability/               # Dashboard + 事件快照
  research/                    # 消融研究
  security/                    # 安全沙箱
plugins/context_engine/mstar/  # Hermes ContextEngine 插件
run_agent.py                   # 集成入口
tools/mstar_tools.py           # MSTAR 工具集
tools/batch_tool.py            # 批量任务工具
scripts/mstar_dashboard.sh     # Dashboard 启动脚本
backups/v3_backup_*/           # v3 原始文件备份
```

## 快速启动

```bash
# Dashboard
python run_agent.py --dashboard

# 端到端测试
python run_agent.py --mode standard --max-sessions 20

# 查看 Dashboard
curl http://localhost:18792/health
```

## 技术规格

- Python 3.11+ (建议 pythoncore-3.14-64)
- SQLite3 (内嵌，无需额外 DB)
- Dashboard: port 18792
- 最小触发间隔: 3 sessions (默认)

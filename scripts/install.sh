#!/bin/bash
# =============================================================
# MSTAR Pro V4.0 一键安装脚本
# 用法: bash <(curl -fsSL https://raw.githubusercontent.com/Lsinxcoy/MSTAR-Pro-V4.0-Clean/main/scripts/install.sh)
# =============================================================

set -e

REPO="https://github.com/Lsinxcoy/MSTAR-Pro-V4.0-Clean.git"
BRANCH="main"
INSTALLER_DIR="${HOME}/.mstar-install-tmp"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---------- Step 0: Check prerequisites ----------
info "检查环境..."

# Detect Hermes home
if [ -n "$HERMES_HOME" ] && [ -d "$HERMES_HOME" ]; then
    HERMES_DIR="$HERMES_HOME"
elif [ -d "$HOME/.hermes" ]; then
    HERMES_DIR="$HOME/.hermes"
elif [ -d "$APPDATA/.hermes" ]; then
    HERMES_DIR="$APPDATA/.hermes"
else
    error "未找到 Hermes Agent 安装目录。请确保已安装 Hermes Agent。"
fi

if [ ! -d "$HERMES_DIR" ]; then
    error "Hermes 目录不存在: $HERMES_DIR"
fi

if [ ! -f "$HERMES_DIR/hermes-agent/run_agent.py" ]; then
    error "未找到 run_agent.py，请确认 Hermes Agent 安装正确: $HERMES_DIR/hermes-agent/run_agent.py"
fi

info "Hermes 目录: $HERMES_DIR"
AGENT_DIR="$HERMES_DIR/hermes-agent"

# Python check
if command -v python3 &>/dev/null; then
    PYTHON=$(command -v python3)
elif command -v python &>/dev/null; then
    PYTHON=$(command -v python)
else
    error "未找到 Python"
fi

# Check numpy
if ! $PYTHON -c "import numpy" 2>/dev/null; then
    warn "未检测到 numpy，正在安装..."
    pip install numpy -q || error "numpy 安装失败"
fi

# Check yaml
if ! $PYTHON -c "import yaml" 2>/dev/null; then
    warn "未检测到 PyYAML，正在安装..."
    pip install pyyaml -q || error "PyYAML 安装失败"
fi

info "Python: $($PYTHON --version)"

# ---------- Step 1: Download MSTAR files ----------
info "下载 MSTAR Pro V4.0 文件..."

if [ -d "$INSTALLER_DIR" ]; then
    rm -rf "$INSTALLER_DIR"
fi

git clone --depth=1 --branch "$BRANCH" "$REPO" "$INSTALLER_DIR" || error "git clone 失败"

# ---------- Step 2: Copy MSTAR core ----------
info "安装 mstar_core/ ..."

# Copy mstar_core directory
if [ -d "$AGENT_DIR/mstar_core" ]; then
    warn "mstar_core/ 已存在，备份后替换..."
    cp -r "$AGENT_DIR/mstar_core" "$AGENT_DIR/mstar_core.bak.$(date +%Y%m%d%H%M%S)"
    rm -rf "$AGENT_DIR/mstar_core"
fi

cp -r "$INSTALLER_DIR/mstar_core" "$AGENT_DIR/mstar_core"
info "mstar_core/ 已安装 ($(find "$AGENT_DIR/mstar_core" -name '*.py' | wc -l) files)"

# Copy integration files
for f in "tools/mstar_tools.py" "tools/batch_tool.py"; do
    if [ -f "$INSTALLER_DIR/$f" ]; then
        if [ -f "$AGENT_DIR/$f" ]; then
            cp "$AGENT_DIR/$f" "$AGENT_DIR/${f}.bak.$(date +%Y%m%d%H%M%S)"
        fi
        cp "$INSTALLER_DIR/$f" "$AGENT_DIR/$f"
        info "$f 已安装"
    fi
done

# Copy ContextEngine plugin
if [ -d "$INSTALLER_DIR/plugins/context_engine/mstar" ]; then
    mkdir -p "$AGENT_DIR/plugins/context_engine"
    if [ -d "$AGENT_DIR/plugins/context_engine/mstar" ]; then
        cp -r "$AGENT_DIR/plugins/context_engine/mstar" "$AGENT_DIR/plugins/context_engine/mstar.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cp -r "$INSTALLER_DIR/plugins/context_engine/mstar" "$AGENT_DIR/plugins/context_engine/mstar"
    info "plugins/context_engine/mstar/ 已安装"
fi

# ---------- Step 3: Modify config.yaml ----------
info "配置 config.yaml..."

CONFIG="$HERMES_DIR/config.yaml"
if [ ! -f "$CONFIG" ]; then
    error "config.yaml 不存在: $CONFIG"
fi

# Backup config
cp "$CONFIG" "${CONFIG}.bak.$(date +%Y%m%d%H%M%S)"

# Check if context.engine already set to mstar
if grep -q "engine: *mstar" "$CONFIG" 2>/dev/null; then
    info "context.engine: mstar 已配置"
else
    # Add mstar to context engine
    if grep -q "^context:" "$CONFIG"; then
        sed -i "/^context:/a\  engine: mstar" "$CONFIG" 2>/dev/null || \
        sed -i "/^context:/,/^[a-z]/ { /^[a-z]/ !{ /engine:/d; a\  engine: mstar; } }" "$CONFIG" 2>/dev/null || \
        python3 -c "
import sys, yaml
with open('$CONFIG', 'r') as f:
    cfg = yaml.safe_load(f)
cfg.setdefault('context', {})['engine'] = 'mstar'
with open('$CONFIG', 'w') as f:
    yaml.dump(cfg, f, allow_unicode=True, default_flow_style=False)
"
        info "已添加 context.engine: mstar"
    else
        error "config.yaml 中未找到 context: 节"
    fi
fi

# Check if memory.provider already set to mstar
if grep -q "provider: *mstar" "$CONFIG" 2>/dev/null; then
    info "memory.provider: mstar 已配置"
else
    if grep -q "^memory:" "$CONFIG"; then
        python3 -c "
import sys, yaml
with open('$CONFIG', 'r') as f:
    cfg = yaml.safe_load(f)
cfg.setdefault('memory', {})['provider'] = 'mstar'
with open('$CONFIG', 'w') as f:
    yaml.dump(cfg, f, allow_unicode=True, default_flow_style=False)
" 2>/dev/null || sed -i "/^memory:/a\  provider: mstar" "$CONFIG" 2>/dev/null
        info "已添加 memory.provider: mstar"
    else
        error "config.yaml 中未找到 memory: 节"
    fi
fi

# Add top-level mstar: section if not present
if grep -q "^mstar:" "$CONFIG" 2>/dev/null; then
    info "mstar: 节已存在"
else
    # Append mstar config at end
    cat >> "$CONFIG" << 'EOF'

mstar:
  dashboard_enabled: true
  dashboard_port: 18792
EOF
    info "已添加 mstar: 配置节"
fi

# ---------- Step 4: Verify run_agent.py has MSTAR hooks ----------
info "检查 run_agent.py MSTAR 集成..."

if grep -q "mstar_core\|MSTARCore" "$AGENT_DIR/run_agent.py" 2>/dev/null; then
    info "run_agent.py 已包含 MSTAR 钩子，跳过修改"
else
    warn "run_agent.py 缺少 MSTAR 集成代码！"
    echo ""
    echo "请手动在 run_agent.py 的 AIAgent.__init__ 方法中（内存 provider 初始化后）"
    echo "插入以下代码（参考: https://github.com/Lsinxcoy/MSTAR-Pro-V4.0-Clean#step-22-修改-run_agentpy集成钩子）"
    echo ""
fi

# ---------- Cleanup ----------
info "清理临时文件..."
rm -rf "$INSTALLER_DIR"

# ---------- Done ----------
echo ""
echo "============================================"
echo -e "${GREEN}✓ MSTAR Pro V4.0 安装完成！${NC}"
echo "============================================"
echo ""
echo "下一步："
echo "  1. 重启 Hermes Agent:  hermes restart"
echo "  2. 验证 Dashboard:     curl http://localhost:18792/health"
echo "  3. 查看 Dashboard:     http://localhost:18792"
echo ""
echo "配置文件备份: ${CONFIG}.bak.*"
echo ""

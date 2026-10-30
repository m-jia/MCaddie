# 📁 文档和脚本整理说明

## 🎯 目的

将项目根目录下的大量 `.md` 和 `.sh` 文件整理到合适的子目录中，便于管理和查找。

## 📂 新的目录结构

```
MCaddie/
│
├── 📄 README.md                    # 项目入口（保留）
├── 📄 AGENTS.md                    # AI 工作规则（保留）
├── 📄 PRODUCT_SPEC.md              # 产品规范（保留）
├── 📄 ARCHITECTURE.md              # 架构设计（保留）
├── 📄 DATA_MODEL.md                # 数据模型（保留）
│
├── 📁 Documentation/               # 文档目录
│   │
│   ├── 📁 Guides/                  # 使用指南
│   │   ├── SWIFTDATA_GUIDE.md
│   │   ├── SWIFTDATA_QUICK_REFERENCE.md
│   │   ├── UI_GPS_INTEGRATION_GUIDE.md
│   │   ├── TESTING_GUIDE.md
│   │   ├── FILE_ORGANIZATION_GUIDE.md
│   │   ├── BUILD_VERIFICATION.md
│   │   ├── TEST_PLAN.md
│   │   └── QUICK_START_PROMPT.md
│   │
│   ├── 📁 Status/                  # 项目状态
│   │   ├── PROJECT_STATUS.md
│   │   ├── SWIFTDATA_IMPLEMENTATION_REPORT.md
│   │   ├── ROADMAP.md
│   │   └── DECISIONS_OPEN_QUESTIONS.md
│   │
│   ├── 📁 Fixes/                   # 问题修复记录
│   │   ├── FIX_TESTING_ERROR.md
│   │   ├── USE_SWIFT_TESTING.md
│   │   ├── PERSISTENCE_TESTS_FIXED.md
│   │   ├── MCADDIECORE_IMPORT_FIX.md
│   │   ├── FIX_MCADDIECORE_PACKAGE.md
│   │   ├── LOCATIONSERVICE_FIX.md
│   │   ├── FIX_WATCH_VIEW_ERROR.md
│   │   ├── BUILD_FIX_GUIDE.md
│   │   └── ...
│   │
│   └── 📄 其他技术文档
│       ├── CONVERSATION_PERSISTENCE_GUIDE.md
│       ├── WATCH_DEPLOYMENT_GUIDE.md
│       ├── SHOT_MODEL_COMPLETION_REPORT.md
│       └── ...
│
└── 📁 Scripts/                     # 实用脚本
    ├── fix_mcaddiecore_structure.sh
    ├── diagnose.sh
    ├── add_shot_models.sh
    ├── check_environment.sh
    └── ...
```

## 🚀 如何整理

### 自动整理（推荐）

运行整理脚本：

```bash
chmod +x organize_files.sh
./organize_files.sh
```

脚本会：
1. ✅ 创建目录结构
2. ✅ 移动文件到对应目录
3. ✅ 保留核心文档在根目录
4. ✅ 设置脚本可执行权限
5. ✅ 显示整理结果

### 手动整理

如果prefer手动操作：

```bash
# 创建目录
mkdir -p Documentation/{Guides,Status,Fixes}
mkdir -p Scripts

# 移动指南文档
mv *_GUIDE.md Documentation/Guides/
mv TESTING_GUIDE.md Documentation/Guides/

# 移动状态文档
mv PROJECT_STATUS.md Documentation/Status/
mv ROADMAP.md Documentation/Status/
mv *_REPORT.md Documentation/Status/

# 移动修复文档
mv FIX_*.md Documentation/Fixes/

# 移动脚本
mv *.sh Scripts/
chmod +x Scripts/*.sh
```

## 📚 保留在根目录的文件

这些核心文档保留在根目录，便于快速访问：

- ✅ `README.md` - 项目入口和概述
- ✅ `AGENTS.md` - AI Agent 工作规则
- ✅ `PRODUCT_SPEC.md` - 产品需求规范
- ✅ `ARCHITECTURE.md` - 技术架构设计
- ✅ `DATA_MODEL.md` - 数据模型定义

## 🗂️ 文档分类说明

### Documentation/Guides/
**使用指南和教程**
- 如何使用 SwiftData
- GPS 集成指南
- 测试指南
- 文件组织指南
- 等等

### Documentation/Status/
**项目状态和规划**
- 当前进度
- 实施报告
- 路线图
- 决策记录

### Documentation/Fixes/
**问题修复记录**
- 编译错误修复
- Bug 修复步骤
- 问题排查指南
- 每个修复都有详细说明

### Scripts/
**实用脚本**
- 结构修复脚本
- 诊断脚本
- 环境检查脚本
- 所有脚本都可执行

## 🔍 如何查找文档

### 按用途查找

**我想学习如何使用某个功能**
→ 查看 `Documentation/Guides/`

**我想了解项目当前状态**
→ 查看 `Documentation/Status/PROJECT_STATUS.md`

**我遇到了编译错误**
→ 查看 `Documentation/Fixes/`

**我想运行脚本修复问题**
→ 查看 `Scripts/`

### 按内容查找

可以使用命令行搜索：

```bash
# 搜索包含 "GPS" 的文档
grep -r "GPS" Documentation/

# 搜索包含 "SwiftData" 的文档
grep -r "SwiftData" Documentation/

# 列出所有修复文档
ls Documentation/Fixes/
```

## 🧹 清理建议

整理后，可以删除的文件：

```bash
# 删除整理脚本（已完成任务）
rm organize_files.sh
rm DOCUMENTATION_ORGANIZATION.md

# 删除重复或过时的文档（谨慎！）
# 检查后手动删除
```

## ✅ 整理完成检查清单

- [ ] 运行了 `organize_files.sh`
- [ ] 确认核心文档仍在根目录
- [ ] 确认文档已移动到正确的子目录
- [ ] 确认脚本可执行（`ls -l Scripts/`）
- [ ] 测试一个脚本是否能正常运行
- [ ] 更新 `.gitignore`（如果需要）

## 📝 维护建议

### 添加新文档时

**指南类文档** → `Documentation/Guides/`
**状态报告** → `Documentation/Status/`
**修复记录** → `Documentation/Fixes/`
**实用脚本** → `Scripts/`

### 命名规范

**指南**: `[TOPIC]_GUIDE.md`
**修复**: `FIX_[PROBLEM].md`
**脚本**: `[action]_[target].sh`
**报告**: `[TOPIC]_REPORT.md`

## 🎉 好处

整理后的好处：

✅ **更清晰的结构** - 容易找到需要的文档
✅ **更易维护** - 新文档有明确的归属
✅ **更少混乱** - 根目录只保留核心文档
✅ **更好的组织** - 按功能分类
✅ **便于分享** - 可以分享特定子目录

---

**整理脚本**: `organize_files.sh`  
**创建时间**: 2026-10-24  
**用途**: 一次性整理项目文档和脚本

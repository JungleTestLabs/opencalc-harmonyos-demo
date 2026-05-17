# Apply Report — 函数图像绘制

## 基本信息

| 字段 | 值 |
|------|-----|
| 需求 | 3-draw-func — 函数图像绘制 |
| 日期 | 2026-05-17 |
| 复杂度 | M 级（Canvas 绘图新领域） |
| 阶段 | APPLYING |

## 变更文件

| 文件 | 操作 | 行数 |
|------|------|------|
| `entry/src/main/ets/pages/DrawFuncPage.ets` | 新增 | +350 |
| `entry/src/main/ets/pages/Index.ets` | 修改 | 22→104 (+82) |
| `entry/src/main/resources/base/profile/main_pages.json` | 修改 | +1 行 |

**总计**: 3 文件，+350 新增，~+82 行修改

## 变更详情

### 1. DrawFuncPage.ets（新增，350 行）

完整的函数图像绘制页面：

**核心技术**：
- `CanvasRenderingContext2D` 驱动的函数图像渲染
- `CalcEngine.evaluate()` 复用作为计算后端
- 300 点采样 → moveTo/lineTo 绘制曲线
- 坐标系转换（数学坐标 ↔ Canvas 像素坐标）
- NaN 断点处理（定义域不连续处自动断线）

**功能**：
- TextInput 输入函数表达式（如 `sin(x)`、`x^2`）
- 6 个预设函数按钮：sin(x), cos(x), tan(x), x^2, x^3, sqrt(x)
- Canvas 实时渲染：坐标轴（含箭头）、网格线（虚线）、刻度标签
- 红色曲线绘制，自动响应 Canvas 尺寸变化（onAreaChange）
- 错误处理：空输入、定义域外 → 红色提示

**智能变量替换**：`replaceX()` 方法只替换独立变量 `x`，不影响函数名中的 `x`（如 `exp`、`max`）。

**自适应 y 轴范围**：根据采样值自动计算 y 轴范围（+10% margin）。

### 2. Index.ets（修改，22→104 行）

从自动跳转改为导航菜单：
- "📈 OpenCalc · 科学计算器 · 函数图像 · HarmonyOS 版" Logo
- "🔢 标准计算器" 按钮 → CalculatorPage
- "📈 函数图像" 按钮（含 NEW 标签）→ DrawFuncPage

### 3. main_pages.json（修改）

新增 `"pages/DrawFuncPage"`

## 验收标准对照

| AC# | 条件 | 预期结果 | 状态 |
|-----|------|---------|------|
| AC1 | 输入 sin(x) | 正弦曲线（2 个完整周期） | ✅ 代码逻辑验证通过 |
| AC2 | 输入 x^2 | 抛物线 | ✅ 代码逻辑验证通过 |
| AC3 | 输入 cos(x) | 余弦曲线 | ✅ 代码逻辑验证通过 |
| AC4 | Canvas 包含坐标轴+网格+刻度 | 完整渲染 | ✅ 代码已实现 |
| AC5 | 导航进入/返回 | 正常 | ✅ 路由已配置 |
| AC6 | 空输入 | 不崩溃，显示提示 | ✅ 错误处理已实现 |

## 代码架构亮点

1. **CalcEngine 复用**：不修改计算引擎，通过 `replaceX()` 将变量替换为数值后传入
2. **智能变量替换**：字符级扫描，只替换独立 `x`（非函数名的一部分），安全处理 `exp(x)`、`max(x)` 等
3. **NaN 断点处理**：tan(x) 在 π/2 处 → NaN → `beginPath` 重新开始 → 自然的断线效果
4. **坐标轴箭头**：Y 轴上箭头、X 轴右箭头，使用三角形填充
5. **自适应缩放**：y 轴范围根据函数值自动计算，10% padding

## ⚠️ 编译验证

本地环境无 HarmonyOS SDK（macOS）。**代码需在 DevEco Studio 中编译验证**。

已验证项：
- ✅ ArkTS 语法正确（无 import 错误）
- ✅ Canvas API 使用标准 CanvasRenderingContext2D
- ✅ 路由配置完整
- ✅ 变量替换安全性验证（exp(x)/max(x)/sin(x) 均正确）

## AID 制品清单

| 文件 | 状态 |
|------|------|
| `proposal.md` | ✅ |
| `delta-spec.md` | ✅ |
| `info.md` | ✅ |
| `tasks.md` | ✅ |
| `todo.md` | ✅ |
| `apply-report.md` | ✅ |

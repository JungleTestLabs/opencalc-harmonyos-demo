// OpenCalc — 函数绘图模块
// 等间隔采样 + Canvas 绘制（坐标轴 + 断点折线）
// 无状态纯模块：所有数据通过参数传递

import { CalcEngine } from './Calculator'
import { ErrorFlags } from '../model/ErrorFlags'
import { GraphConfig, PlotPoint, PlotResult } from '../model/Models'

/** 绘图用主题色（由调用方传入,Plotter 不依赖主题系统） */
export interface ThemeColors {
  axis: string   // 坐标轴颜色
  curve: string  // 曲线颜色
  bg: string     // 背景色(用于 clearRect 后填充,可选)
}

/** y 像素范围(算法二输出) */
interface YRange {
  yMin: number
  yMax: number
}

/** 像素坐标(算法二输出) */
interface PxPoint {
  px: number
  py: number
}

export class Plotter {
  /**
   * 等间隔采样
   * @param prepared 已 Expression.getCleanExpression 预处理后的表达式
   * @param cfg 绘图配置
   * @param engine CalcEngine 实例(必须可重入复用)
   * @param isDegree 三角函数是否按角度计算
   */
  static sample(
    prepared: string,
    cfg: GraphConfig,
    engine: CalcEngine,
    isDegree: boolean
  ): PlotResult {
    const points: PlotPoint[] = []
    let validCount: number = 0
    let yMin: number = Number.POSITIVE_INFINITY
    let yMax: number = Number.NEGATIVE_INFINITY
    const N: number = cfg.sampleCount
    const step: number = (cfg.xMax - cfg.xMin) / (N - 1)
    const softTimeoutBudget: number = 200
    const startTime: number = Date.now()

    for (let i: number = 0; i < N; i++) {
      const x: number = cfg.xMin + i * step
      ErrorFlags.reset()
      let y: number = 0
      let evalOk: boolean = true
      try {
        y = engine.evalAt(prepared, x, isDegree)
      } catch (e) {
        evalOk = false
      }
      const hasError: boolean = ErrorFlags.syntax_error
        || ErrorFlags.division_by_0
        || ErrorFlags.is_infinity
        || ErrorFlags.domain_error
        || ErrorFlags.require_real_number
      const defined: boolean = evalOk && isFinite(y) && !hasError && Math.abs(y) <= 1e15
      if (defined) {
        if (Math.abs(y) < 1e-10) y = 0
        if (y < yMin) yMin = y
        if (y > yMax) yMax = y
        validCount++
      }
      points.push({ x: x, y: defined ? y : 0, defined: defined })

      if (i % 100 === 99 && Date.now() - startTime > softTimeoutBudget) {
        console.warn('plot sample timeout at i=' + i)
        break
      }
    }

    ErrorFlags.reset()
    return { points: points, validCount: validCount, yMin: yMin, yMax: yMax }
  }

  /**
   * 在 Canvas 上绘制坐标轴 + 曲线
   * @param ctx Canvas 2D 渲染上下文
   * @param result 由 sample 产生的结果
   * @param cfg 与 sample 时相同的配置
   * @param theme 主题颜色
   */
  static drawTo(
    ctx: CanvasRenderingContext2D | null,
    result: PlotResult,
    cfg: GraphConfig,
    theme: ThemeColors
  ): void {
    if (ctx === null) {
      console.warn('Plotter.drawTo: ctx is null')
      return
    }
    ctx.clearRect(0, 0, cfg.canvasWidthPx, cfg.canvasHeightPx)
    const yRange: YRange = Plotter.fitYRange(result.yMin, result.yMax)
    Plotter.drawAxes(ctx, cfg, yRange, theme)
    if (result.validCount > 0) {
      Plotter.drawCurve(ctx, result, cfg, yRange, theme)
    }
  }

  /** y 范围扩边:常函数兜底 + 全无效点兜底 + 10% padding */
  private static fitYRange(yMin: number, yMax: number): YRange {
    if (!isFinite(yMin) || !isFinite(yMax)) {
      return { yMin: -1, yMax: 1 }
    }
    if (yMax - yMin < 1e-6) {
      return { yMin: yMin - 1, yMax: yMax + 1 }
    }
    const pad: number = (yMax - yMin) * 0.1
    return { yMin: yMin - pad, yMax: yMax + pad }
  }

  /** 数学坐标 → 像素坐标 */
  private static toPx(x: number, y: number, cfg: GraphConfig, yRange: YRange): PxPoint {
    const innerW: number = cfg.canvasWidthPx - 2 * cfg.paddingPx
    const innerH: number = cfg.canvasHeightPx - 2 * cfg.paddingPx
    const px: number = cfg.paddingPx + (x - cfg.xMin) / (cfg.xMax - cfg.xMin) * innerW
    const py: number = cfg.canvasHeightPx - cfg.paddingPx
      - (y - yRange.yMin) / (yRange.yMax - yRange.yMin) * innerH
    return { px: px, py: py }
  }

  /** 绘制坐标轴(X 轴对应 y=0, Y 轴对应 x=0) */
  private static drawAxes(
    ctx: CanvasRenderingContext2D,
    cfg: GraphConfig,
    yRange: YRange,
    theme: ThemeColors
  ): void {
    ctx.strokeStyle = theme.axis
    ctx.lineWidth = 1
    // X 轴
    let py0: number
    if (yRange.yMin <= 0 && yRange.yMax >= 0) {
      py0 = Plotter.toPx(0, 0, cfg, yRange).py
    } else if (yRange.yMin > 0) {
      py0 = cfg.canvasHeightPx - cfg.paddingPx
    } else {
      py0 = cfg.paddingPx
    }
    ctx.beginPath()
    ctx.moveTo(cfg.paddingPx, py0)
    ctx.lineTo(cfg.canvasWidthPx - cfg.paddingPx, py0)
    ctx.stroke()
    // Y 轴(本期 xMin=-10, xMax=10,必含 0)
    const px0: number = Plotter.toPx(0, 0, cfg, yRange).px
    ctx.beginPath()
    ctx.moveTo(px0, cfg.paddingPx)
    ctx.lineTo(px0, cfg.canvasHeightPx - cfg.paddingPx)
    ctx.stroke()
  }

  /** 绘制曲线(支持断点检测) */
  private static drawCurve(
    ctx: CanvasRenderingContext2D,
    result: PlotResult,
    cfg: GraphConfig,
    yRange: YRange,
    theme: ThemeColors
  ): void {
    ctx.strokeStyle = theme.curve
    ctx.lineWidth = 2
    const breakThreshold: number = 5 * (yRange.yMax - yRange.yMin)
    let inSegment: boolean = false
    const N: number = result.points.length
    for (let i: number = 0; i < N; i++) {
      const p: PlotPoint = result.points[i]
      if (!p.defined) {
        if (inSegment) {
          ctx.stroke()
          inSegment = false
        }
        continue
      }
      if (inSegment && i > 0 && result.points[i - 1].defined) {
        const dy: number = Math.abs(p.y - result.points[i - 1].y)
        if (dy > breakThreshold) {
          ctx.stroke()
          inSegment = false
        }
      }
      const pt: PxPoint = Plotter.toPx(p.x, p.y, cfg, yRange)
      if (!inSegment) {
        ctx.beginPath()
        ctx.moveTo(pt.px, pt.py)
        inSegment = true
      } else {
        ctx.lineTo(pt.px, pt.py)
      }
    }
    if (inSegment) ctx.stroke()
  }
}

// OpenCalc - 小费计算器纯函数模块
// 设计文档: specs/changes/20260519-requirement-add-tip-calculator/delta-design.md §3.5

export class TipCalculator {
  static readonly PLACEHOLDER: string = '--'
  static readonly MIN_TIP_PERCENT: number = 0
  static readonly MAX_TIP_PERCENT: number = 100

  static calcPerPerson(amount: number, peopleCount: number, tipPercent: number): string {
    if (!TipCalculator.isValidAmount(amount)) return TipCalculator.PLACEHOLDER
    if (!TipCalculator.isValidPeople(peopleCount)) return TipCalculator.PLACEHOLDER
    if (!TipCalculator.isValidTipPercent(tipPercent)) return TipCalculator.PLACEHOLDER
    const total: number = amount * (1 + tipPercent / 100)
    const perPerson: number = total / peopleCount
    if (!Number.isFinite(perPerson)) return TipCalculator.PLACEHOLDER
    return perPerson.toFixed(2)
  }

  private static isValidAmount(n: number): boolean {
    return Number.isFinite(n) && n >= 0
  }

  private static isValidPeople(n: number): boolean {
    return Number.isInteger(n) && n >= 1
  }

  private static isValidTipPercent(n: number): boolean {
    return Number.isFinite(n)
      && n >= TipCalculator.MIN_TIP_PERCENT
      && n <= TipCalculator.MAX_TIP_PERCENT
  }
}

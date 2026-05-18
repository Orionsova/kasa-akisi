import type {
  Category,
  CreditCard,
  CreditScoreSnapshot,
  Investment,
  Prisma,
  RecurringTransaction,
  Transaction,
  User,
} from '@prisma/client';

export function serializeUser(user: User) {
  return {
    id: user.id,
    email: user.email,
    first_name: user.firstName,
    last_name: user.lastName,
    profile_photo: user.profilePhoto,
  };
}

export function serializeCategory(category: Category) {
  return {
    id: category.id,
    name: category.name,
    type: category.type,
    icon: category.icon,
    is_system: category.isSystem,
    user_id: category.userId,
    createdAt: category.createdAt.toISOString(),
    updatedAt: category.updatedAt.toISOString(),
  };
}

export function serializeTransaction(transaction: Transaction) {
  return {
    id: transaction.id,
    title: transaction.title,
    description: transaction.description,
    amount: Number(transaction.amount),
    category: transaction.category,
    date: transaction.date.toISOString(),
    isIncome: transaction.isIncome,
    selectedCardId: transaction.selectedCardId,
    isInstallment: transaction.isInstallment,
    transactionType: transaction.transactionType,
  };
}

export function serializeCreditCard(card: CreditCard) {
  return {
    id: card.id,
    name: card.name,
    lastFourDigits: card.lastFourDigits,
    cardholderNameOverride: card.cardholderNameOverride,
    isActive: card.isActive,
    limit: decimalToNumber(card.limit),
    availableLimit: decimalToNumber(card.availableLimit),
    dueDay: card.dueDay,
    statementDay: card.statementDay,
    paymentGraceDays: card.paymentGraceDays,
    colorHex: card.colorHex,
    shapeKey: card.shapeKey,
    installments: asJsonArray(card.installments),
    futurePeriodPayments: asJsonArray(card.futurePeriodPayments),
  };
}

export function serializeCreditScoreSnapshot(snapshot: CreditScoreSnapshot) {
  return {
    id: snapshot.id,
    createdAt: snapshot.createdAt.toISOString(),
    score: snapshot.score,
    totalLimit: decimalToNumber(snapshot.totalLimit),
    availableLimit: decimalToNumber(snapshot.availableLimit),
    currentStatementDebt: decimalToNumber(snapshot.currentStatementDebt),
  };
}

export function serializeInvestment(investment: Investment) {
  return {
    id: investment.id,
    title: investment.title,
    type: investment.type,
    principal: decimalToNumber(investment.principal),
    currentValue: decimalToNumber(investment.currentValue),
    maturityRate:
      investment.maturityRate == null ? null : decimalToNumber(investment.maturityRate),
    monthlyYield:
      investment.monthlyYield == null ? null : decimalToNumber(investment.monthlyYield),
    termDays: investment.termDays,
    openedAt: investment.openedAt?.toISOString() ?? null,
    symbol: investment.symbol,
    note: investment.note,
  };
}

export function serializeRecurringTransaction(item: RecurringTransaction) {
  return {
    id: item.id,
    title: item.title,
    category: item.category,
    amount: decimalToNumber(item.amount),
    dayOfMonth: item.dayOfMonth,
    isIncome: item.isIncome,
    isSubscription: item.isSubscription,
    note: item.note,
    startDate: item.startDate.toISOString(),
  };
}

function decimalToNumber(value: Prisma.Decimal | number) {
  return Number(value);
}

function asJsonArray(value: Prisma.JsonValue) {
  return Array.isArray(value) ? value : [];
}

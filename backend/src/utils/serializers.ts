import type {
  Category,
  CreditCard,
  CreditScoreSnapshot,
  Investment,
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
  };
}

export function serializeCreditCard(card: CreditCard) {
  return {
    id: card.id,
    name: card.name,
    lastFourDigits: card.lastFourDigits,
    cardholderNameOverride: card.cardholderNameOverride,
    isActive: card.isActive,
    limit: Number(card.limit),
    availableLimit: Number(card.availableLimit),
    dueDay: card.dueDay,
    statementDay: card.statementDay,
    paymentGraceDays: card.paymentGraceDays,
    colorHex: card.colorHex,
    shapeKey: card.shapeKey,
    installments: card.installments,
    futurePeriodPayments: card.futurePeriodPayments,
    createdAt: card.createdAt.toISOString(),
    updatedAt: card.updatedAt.toISOString(),
  };
}

export function serializeCreditScoreSnapshot(item: CreditScoreSnapshot) {
  return {
    id: item.id,
    score: item.score,
    totalLimit: Number(item.totalLimit),
    availableLimit: Number(item.availableLimit),
    currentStatementDebt: Number(item.currentStatementDebt),
    createdAt: item.createdAt.toISOString(),
  };
}

export function serializeInvestment(item: Investment) {
  return {
    id: item.id,
    title: item.title,
    type: item.type,
    principal: Number(item.principal),
    currentValue: Number(item.currentValue),
    maturityRate:
      item.maturityRate == null ? null : Number(item.maturityRate),
    monthlyYield:
      item.monthlyYield == null ? null : Number(item.monthlyYield),
    symbol: item.symbol,
    note: item.note,
    createdAt: item.createdAt.toISOString(),
    updatedAt: item.updatedAt.toISOString(),
  };
}

export function serializeRecurringTransaction(item: RecurringTransaction) {
  return {
    id: item.id,
    title: item.title,
    category: item.category,
    amount: Number(item.amount),
    dayOfMonth: item.dayOfMonth,
    isIncome: item.isIncome,
    isSubscription: item.isSubscription,
    note: item.note,
    startDate: item.startDate.toISOString(),
    createdAt: item.createdAt.toISOString(),
    updatedAt: item.updatedAt.toISOString(),
  };
}

import type { Category, Transaction, User } from '@prisma/client';

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

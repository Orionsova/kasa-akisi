import { CategoryType } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

const defaults = [
  { name: 'Yiyecek', type: CategoryType.expense, icon: 'restaurant' },
  { name: 'Ulaşım', type: CategoryType.expense, icon: 'directions_car' },
  { name: 'Faturalar', type: CategoryType.expense, icon: 'receipt_long' },
  { name: 'Sağlık', type: CategoryType.expense, icon: 'favorite' },
  { name: 'Eğlence', type: CategoryType.expense, icon: 'movie' },
  { name: 'Maaş', type: CategoryType.income, icon: 'payments' },
  { name: 'Freelance', type: CategoryType.income, icon: 'laptop_mac' },
  { name: 'Yatırım', type: CategoryType.income, icon: 'trending_up' },
];

export async function ensureSystemCategories() {
  for (const item of defaults) {
    await prisma.category.upsert({
      where: {
        name_type_userId: {
          name: item.name,
          type: item.type,
          userId: null,
        },
      },
      update: {
        icon: item.icon,
        isSystem: true,
      },
      create: {
        name: item.name,
        type: item.type,
        icon: item.icon,
        isSystem: true,
      },
    });
  }
}

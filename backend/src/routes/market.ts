import { Router } from 'express';

export const marketRouter = Router();

marketRouter.get('/overview', async (_req, res) => {
  const [fxResponse, goldResponse] = await Promise.all([
    fetch('https://api.frankfurter.dev/v1/latest?from=TRY&to=USD,EUR'),
    fetch('https://api.gold-api.com/price/XAU'),
  ]);

  if (!fxResponse.ok) {
    return res.status(502).json({
      message: 'Döviz verisi alınamadı',
      source: 'frankfurter',
    });
  }

  if (!goldResponse.ok) {
    return res.status(502).json({
      message: 'Altın verisi alınamadı',
      source: 'gold-api',
    });
  }

  const fxData = (await fxResponse.json()) as {
    date?: string;
    rates?: Record<string, number>;
  };
  const goldData = (await goldResponse.json()) as {
    price?: number;
    updatedAt?: string;
  };

  const usdRate = fxData.rates?.USD;
  const eurRate = fxData.rates?.EUR;
  const goldUsdPerOunce = goldData.price;

  if (
    usdRate == null ||
    eurRate == null ||
    goldUsdPerOunce == null ||
    usdRate <= 0 ||
    eurRate <= 0
  ) {
    return res.status(502).json({
      message: 'Piyasa verisi eksik veya geçersiz geldi',
    });
  }

  const usdTry = 1 / usdRate;
  const eurTry = 1 / eurRate;
  const gramGoldTry = (goldUsdPerOunce * usdTry) / 31.1034768;
  const timestamp = goldData.updatedAt ?? new Date().toISOString();

  return res.json({
    updatedAt: timestamp,
    items: [
      {
        code: 'USD',
        title: 'Dolar',
        value: usdTry,
        subtitle: '1 USD',
        accentHex: '#0F766E',
      },
      {
        code: 'EUR',
        title: 'Euro',
        value: eurTry,
        subtitle: '1 EUR',
        accentHex: '#1D4ED8',
      },
      {
        code: 'XAU',
        title: 'Gram Altın',
        value: gramGoldTry,
        subtitle: '1 gram',
        accentHex: '#B45309',
      },
    ],
  });
});

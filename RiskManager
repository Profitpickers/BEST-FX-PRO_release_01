//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//|                     RiskManager.mqh                              |
//|     Modulo gestione rischio: lotto dinamico, SL/TP percentuale   |
//|           Autore: Vito Iacobellis – www.vitoiacobellis.it       |
//+------------------------------------------------------------------+

#ifndef __RISK_MANAGER_MQH__
#define __RISK_MANAGER_MQH__

class CRiskManager
{
private:
   double accountRiskPercent;
   double stopLossPips;

public:
   void Init(double riskPercent = 1.0, double slPips = 100.0)
   {
      accountRiskPercent = riskPercent;
      stopLossPips = slPips;
   }

   double CalculateLotSize(string symbol)
   {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      if (tickValue <= 0 || tickSize <= 0 || contractSize <= 0)
         return 0.01;

      double riskAmount = balance * accountRiskPercent / 100.0;
      double slInPoints = stopLossPips / point;
      double lotSize = riskAmount / (slInPoints * tickValue / tickSize);

      // Ritaglia tra min e max lotto
      double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

      lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
      lotSize = MathFloor(lotSize / lotStep) * lotStep;

      return NormalizeDouble(lotSize, 2);
   }
};

#endif // __RISK_MANAGER_MQH__

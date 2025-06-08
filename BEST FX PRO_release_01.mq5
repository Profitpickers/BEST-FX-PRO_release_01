//+------------------------------------------------------------------+
//|                       BEST FX PRO_release_01.mq5                 |
//|         EA modulare - Currency Strength Trader                   |
//|         Autore: Vito Iacobellis – www.vitoiacobellis.it         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, ProfitPickers - vitoiacobellis.it"
#property link      "https://www.vitoiacobellis.it"
#property version   "1.07"
#property strict

#include <Trade\Trade.mqh>
#include "..\\Include\\BEST FX PRO\\include1\\CurrencyStrengthAnalyzer.mqh"
#include "..\\Include\\BEST FX PRO\\include1\\BestCrossSelector.mqh"
#include "..\\Include\\BEST FX PRO\\include1\\CrossStrengthHeatmap.mqh"
#include "..\\Include\\BEST FX PRO\\include1\\TradeExecutor.mqh"
#include "..\\Include\\BEST FX PRO\\include1\\RiskManager.mqh"

//--- INPUT PARAMS
input ENUM_TIMEFRAMES TimeframeAnalysis = PERIOD_M15;
input double IndexDeltaThreshold = 0.005; // Soglia minima per attivare trade (Delta Index)
input bool InvertIndexLogic = false;
input double RiskPercent  = 1.0;
input double SL_Pips      = 100.0;
input double TP_Pips      = 200.0;
input double LotFallback  = 0.1;
input int    Slippage     = 5;
input int    RefreshSeconds = 60;


//--- GLOBAL OBJECTS
CurrencyStrengthSettings csSettings;
CCurrencyStrengthAnalyzer analyzer;
CBestCrossSelector selector;
CCrossStrengthHeatmap heatmap;
CTradeExecutor executor;
CRiskManager rm;

//--- TIMER
datetime lastExecutionTime = 0;

ENUM_ORDER_TYPE GetOrderTypeByIndexDelta(double indexDelta, bool invert)
{
   return ((indexDelta > 0) != invert) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
}

int OnInit()
{
   csSettings.period = 14;
   csSettings.method = MODE_SMA_EXT;
   analyzer.Init(csSettings);
   selector.Init(csSettings);
   executor.Init((int)LotFallback, (int)SL_Pips, (int)TP_Pips, Slippage);
   rm.Init(RiskPercent, (int)SL_Pips);

   heatmap.Init("CSH", CORNER_LEFT_UPPER, 20, 20);
   EventSetTimer(RefreshSeconds);
   Print("[EA INIT] CurrencyStrengthTrader pronto.");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   heatmap.Clear();
   Print("[EA STOP] CurrencyStrengthTrader disattivato.");
}

void OnTimer()
{
   Print("[EA] Analisi forza valute e selezione cross...");

   selector.CalculateStrengthMap(TimeframeAnalysis);
   selector.SelectTopCrosses();

   heatmap.DrawCrossPanel(selector);
   heatmap.DrawIndexPanel(analyzer, TimeframeAnalysis);

   for (int i = 0; i < 5; i++)
   {
      CrossSignal signal = selector.GetBestCross(i);
      if (!signal.isValid)
         continue;

      if (executor.HasOpenPosition(signal.symbol))
         continue;

      double lots = rm.CalculateLotSize(signal.symbol);

      // ⚠️ Protezione se lotto = 0.00 (errore nel volume calcolato)
      if (lots <= 0.0)
      {
         Print("[EA] Skipping ", signal.symbol, " per lotto invalido (", DoubleToString(lots, 2), ")");
         continue;
      }

      executor.Init(lots, SL_Pips, TP_Pips, Slippage);  // usa double, non castare
      executor.ExecuteOrders(selector, InvertIndexLogic, IndexDeltaThreshold);
   }
}

void OnTick()
{
   // Vuoto - solo analisi ciclica via OnTimer
}

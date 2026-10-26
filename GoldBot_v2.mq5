#property strict
#property version "2.00"

#include <Trade/Trade.mqh>

CTrade trade;

input double LotSize = 0.01;
input int StopLossPoints = 300;
input int TakeProfitPoints = 600;
input int FastEMA = 9;
input int SlowEMA = 21;
input int RSIPeriod = 14;
input double BuyRSI = 55.0;
input double SellRSI = 45.0;
input ulong MagicNumber = 20261026;

int fastHandle, slowHandle, rsiHandle;
datetime lastBar = 0;

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);

   fastHandle = iMA(_Symbol, PERIOD_CURRENT,
                    FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, PERIOD_CURRENT,
                    SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, PERIOD_CURRENT,
                    RSIPeriod, PRICE_CLOSE);

   if(fastHandle == INVALID_HANDLE ||
      slowHandle == INVALID_HANDLE ||
      rsiHandle == INVALID_HANDLE)
   {
      Print("Indicator initialization failed");
      return INIT_FAILED;
   }

   Print("GoldBot_v2 initialized");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fastHandle);
   IndicatorRelease(slowHandle);
   IndicatorRelease(rsiHandle);
}

void OnTick()
{
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(barTime == lastBar || barTime == 0)
      return;

   lastBar = barTime;

   double fast[3], slow[3], rsi[3];
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(fastHandle, 0, 0, 3, fast) != 3 ||
      CopyBuffer(slowHandle, 0, 0, 3, slow) != 3 ||
      CopyBuffer(rsiHandle, 0, 0, 3, rsi) != 3)
      return;

   bool buySignal =
      fast[2] <= slow[2] &&
      fast[1] > slow[1] &&
      rsi[1] >= BuyRSI;

   bool sellSignal =
      fast[2] >= slow[2] &&
      fast[1] < slow[1] &&
      rsi[1] <= SellRSI;

   if(!buySignal && !sellSignal)
      return;

   // Do not open another position on this symbol.
   if(PositionSelect(_Symbol))
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   if(ask <= 0 || bid <= 0 || point <= 0)
      return;

   double sl, tp;

   if(buySignal)
   {
      sl = NormalizeDouble(
         ask - StopLossPoints * point, digits);
      tp = NormalizeDouble(
         ask + TakeProfitPoints * point, digits);

      if(!trade.Buy(LotSize, _Symbol, 0, sl, tp, "EMA RSI Buy"))
         Print("Buy failed: ", trade.ResultRetcodeDescription());
   }
   else if(sellSignal)
   {
      sl = NormalizeDouble(
         bid + StopLossPoints * point, digits);
      tp = NormalizeDouble(
         bid - TakeProfitPoints * point, digits);

      if(!trade.Sell(LotSize, _Symbol, 0, sl, tp, "EMA RSI Sell"))
         Print("Sell failed: ", trade.ResultRetcodeDescription());
   }
}

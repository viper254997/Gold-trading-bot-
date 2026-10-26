#property strict
#property version "2.00"

#include <Trade/Trade.mqh>

CTrade trade;

input double LotSize = 0.01;
input int FastEMA = 9;
input int SlowEMA = 21;
input int RSIPeriod = 14;
input double BuyRSILevel = 50.0;
input double SellRSILevel = 50.0;
input int StopLossPoints = 300;
input int TakeProfitPoints = 600;
input ulong MagicNumber = 20261026;

int fastHandle = INVALID_HANDLE;
int slowHandle = INVALID_HANDLE;
int rsiHandle = INVALID_HANDLE;
datetime lastBarTime = 0;

int OnInit()
{
   fastHandle = iMA(_Symbol, PERIOD_M15, FastEMA,
                    0, MODE_EMA, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, PERIOD_M15, SlowEMA,
                    0, MODE_EMA, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, PERIOD_M15,
                    RSIPeriod, PRICE_CLOSE);

   if(fastHandle == INVALID_HANDLE ||
      slowHandle == INVALID_HANDLE ||
      rsiHandle == INVALID_HANDLE)
   {
      Print("Failed to initialize indicators");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MagicNumber);

   Print("GoldBot_v2 EMA + RSI initialized");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(fastHandle != INVALID_HANDLE)
      IndicatorRelease(fastHandle);

   if(slowHandle != INVALID_HANDLE)
      IndicatorRelease(slowHandle);

   if(rsiHandle != INVALID_HANDLE)
      IndicatorRelease(rsiHandle);
}

void OnTick()
{
   datetime barTime = iTime(_Symbol, PERIOD_M15, 0);

   if(barTime == 0 || barTime == lastBarTime)
      return;

   lastBarTime = barTime;

   if(BarsCalculated(fastHandle) < SlowEMA + 3 ||
      BarsCalculated(slowHandle) < SlowEMA + 3 ||
      BarsCalculated(rsiHandle) < RSIPeriod + 3)
      return;

   double fast[2], slow[2], rsi[1];

   if(CopyBuffer(fastHandle, 0, 1, 2, fast) != 2)
      return;

   if(CopyBuffer(slowHandle, 0, 1, 2, slow) != 2)
      return;

   if(CopyBuffer(rsiHandle, 0, 1, 1, rsi) != 1)
      return;

   // Index 0 = older closed candle
   // Index 1 = most recent closed candle

   bool buySignal =
      fast[0] <= slow[0] &&
      fast[1] > slow[1] &&
      rsi[0] > BuyRSILevel;

   bool sellSignal =
      fast[0] >= slow[0] &&
      fast[1] < slow[1] &&
      rsi[0] < SellRSILevel;

   // Only one position per chart symbol
   if(PositionSelect(_Symbol))
      return;

   if(buySignal)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = NormalizeDouble(
         ask - StopLossPoints * _Point, _Digits);
      double tp = NormalizeDouble(
         ask + TakeProfitPoints * _Point, _Digits);

      if(trade.Buy(LotSize, _Symbol, 0, sl, tp,
                   "GoldBot EMA RSI BUY"))
         Print("BUY order sent");
      else
         Print("BUY failed: ", trade.ResultRetcodeDescription());
   }
   else if(sellSignal)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = NormalizeDouble(
         bid + StopLossPoints * _Point, _Digits);
      double tp = NormalizeDouble(
         bid - TakeProfitPoints * _Point, _Digits);

      if(trade.Sell(LotSize, _Symbol, 0, sl, tp,
                    "GoldBot EMA RSI SELL"))
         Print("SELL order sent");
      else
         Print("SELL failed: ", trade.ResultRetcodeDescription());
   }
}

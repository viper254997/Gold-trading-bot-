#property strict
#property version "1.00"

#include <Trade/Trade.mqh>

CTrade trade;

input double LotSize = 0.01;
input int StopLossPoints = 300;
input int TakeProfitPoints = 600;

int OnInit()
{
   Print("GoldBot initialized successfully");
   return INIT_SUCCEEDED;
}

void OnTick()
{
   // Trading logic will be added after testing.
}

//+==========================================================================+
//|                          Robot Forex 2057 Buy Long (ENG) (GBPUSD M1).mq4 |
//|                                            Copyright © 2011, Eracash.com |
//|                                                   http://www.eracash.com |
//|                                                  ----------------------- |
//|           
//|                                    Copyright © 2012, LogicMansLaboratory |
//|                                        http://logicmanslaboratory.0pk.ru |
//|                                                              Moscow 2012 |
//|Modified By : Wutz                                                        |
//+==========================================================================+
#property copyright "Copyright © 2015, Wutz"
//============================================================================
//============================================================================
#include <stderror.mqh>
#include <stdlib.mqh>
//==================================================================================================================================
extern string Init_Parameters    = "Init Parameters";   // Init Parameters
extern int    Magic                  =  11111; // g_magic_208      Magic              (èäåíòèôèêàöèîííûé íîìåð ïðèñâàèâàåìûé ñäåëêàì ýòîãî ðîáîòà - ÷òî áû íå ïóòàëñÿ ñî ñäåëêàìè äðóãèõ ðîáîòîâ)
extern double MaxSpread     =    4.0; // (4.0)            MaxSpread          (åñëè ñïðåä ïðåâûñèò äàííîå îãðàíè÷åíèå - òî òîðãîâëÿ áóäåò ïðèîñòàíîâëåíà äëÿ çàùèòû îò ðèñêîâ (íå çàäåéñòâîâàíî â äàííîé âåðñèè)) (Ñïðåä - ìàêñèìàëüíàÿ ðàçíèöà ìåæäó öåíàìè: ïîêóïêè (Bid) è ïðîäàæè (Ask))
extern int    Slippage        =      5; // g_slippage_96    Slippage           (çàäåðæêà èñïîëíåíèÿ îðäåðà äëÿ ðåêâîò)
extern string ExpertComment            = "Robot Forex 2057 Buy "; // Expret_Comment     (â îêîøêå Òåðìèíàë - âêëàäêà Òîðãîâëÿ (è â îñòàëüíûõ âêëàäêàõ) - ïðàâîé íà ïóñòîì ìåñòå îêîøêà - â êîòåêñòå ïîñòàâèòü ãàëêó - Êîììåíòàðèè)
//-----------------------------------------------------------------------------------------
extern string Parameters_Lot         = "Input Parameters Lot";        // Parameters Lot
extern int    Lot_Decimal         =      2; // gd_112           Lotdecimal         (0 = íîðìàëüíûå ëîòû 1.0;  1 = ìèíèëîòû 0.1;  2 = ìèêðîëîòû 0.01)
extern double Lots                    =   0.01; // (0.1)            Lots               (ðàçìåð ëîòà äëÿ ïåðâîãî îðäåðà)
extern double LotExponent    =   1.44; // gd_88            LotExponent        (êîýôôèöèåíò, íà êîòîðûé óìíîæàåòñÿ ñëåäóþùèé ëîò)
//-----------------------------------------------------------------------------------------
extern string Input_Parameters        = "Input Parameters";       // Input Parameters
extern int    MaxTrades        =   1000; // MaxTrades        MaxTrades          (ìàêñèìàüíî äîïóñòèìîå êîëè÷åñòâî îòêðûâàåìûõ ñäåëîê)
extern int    PipStep      =      9; // g_pips_152       PipStep            (÷åðåç ñêîëüêî ïóíêòîâ îòêðûâàòü ñëåäóþùóþ ñäåëêó - ðåæå èëè ÷àùå îòêðûâàòü ñäåëêè)
//-----------------------------------------------------------------------------------------
extern string Output_Parameters       = "Output Parameters";      // Output Parameters
extern int    TakeProfit            =     10; // g_pips_120       TakeProfit         (çàêðûòèå ñäåëîê ïî îáùåìó ïðîôèòó â ïóíêòàõ)
//-----------------------------------------------------------------------------------------
extern string Input_Filter          = "Input Filter";         // Input Filters
extern bool   UseHourTrade      =  FALSE; // UseHourTrade     UseHourTrade       (âêëþ÷åíèå òîðãîâëè ïî ÷àñàì)
extern int    StartHour         =     16; // StartHour (0)    StartHour          (íà÷àëî îòêðûòèÿ ñäåëîê ïî ÷àñàì)
extern int    EndHour          =      2; // EndHour   (8)    EndHour            (çàâåðøåíèå îòêðûòèÿ ñäåëîê ïî ÷àñàì)
//-----------------------------------------------------------------------------------------
extern string Output_Filter         = "Output Filter";        // Output Filters
extern bool   UseEquityStop         =  FALSE; // gi_164           UseEquityStop      (âêëþ÷åíèå ñëåæåíèÿ çà ñóììàðíûì óáûòêîì ïî ýêâèòè)
extern double TotalEquityRisk =   20.0; // gd_168           TotalEquityRisk    (ïðîñàäêà ïî ýêâèòè â %, äëÿ çàêðûòèÿ âñåõ ñäåëîê)
extern bool   UseTimeOut       =  FALSE; // gi_180           UseTimeOut         (èñïîëüçîâàòü òàéìàóò: çàêðûâàòü ñäåëêè åñëè îíè "âèñÿò" ñëèøêîì äîëãî)
extern double MaxTradeOpenHours  =    0.0; // gd_184  (30.0)   MaxTradeOpenHours  (âðåìÿ òàéìàóòà â ÷àñàõ: ÷åðåç ñêîëüêî çàêðûâàòü çàâèñøèå ñäåëêè)
//==================================================================================================================================
bool   UseHourTrade_2   =  FALSE; // UseHourTrade2    UseHourTrade2      (âêëþ÷åíèå òîðãîâëè ïî ÷àñàì 2)
bool   UseClose =  FALSE; // gi_80            UseClose
//------------------------------------
bool   UseAdd        =   TRUE; // gi_84            UseAdd             (âêëþ÷èòü óìíîæåíèå ëîòà)
int    MMType      =      1; // gi_76            MMType             (âàðèàíò ðàáîòû àâòîëîòà: 0 = îòêëþ÷¸í; 1 = âêëþ÷¸í)
//------------------------------------
int    Stoploss             =      0; // g_pips_128       Stoploss           (çàêðûòèå ñäåëîê ïî îáùåìó óáûòêó â ïóíêòàõ)
//==================================================================================================================================
double gd_220;
double gd_268;
double gd_276;
double gd_316;
double gd_332 = 0.0;
double gd_368;
double gd_376;
//------------------------------
double gd_unused_228;
double gd_unused_236;
//------------------------------
bool   gi_292;
int    gi_308;
int    gi_312 = 0;
int    gi_328;
bool   gi_340 = FALSE;
bool   gi_344 = FALSE;
bool   gi_348 = FALSE;
int    gi_352;
bool   gi_356 = FALSE;
//------------------------------
double g_ask_260;
//------------------------------
double g_bid_252;
//------------------------------
int    g_datetime_360 = 0;
int    g_datetime_364 = 0;
//------------------------------
int    g_pos_324 = 0;
//------------------------------
double g_price_212;
double g_price_244;
//------------------------------
int    g_time_304 = 0;
//------------------------------
int    gi_222           =     1;
//------------------------------
string gs_140 = "lblfin_";
//==================================================================================================================================
int init() {
   if (IsTesting() ==  TRUE) Display_Info();
   if (IsTesting() == FALSE) Display_Info();
   double step    = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   if(step == 0.01){
      Lot_Decimal = 2;
   }else if(step == 0.1){
      Lot_Decimal = 1;
   }else if(step == 1){
      Lot_Decimal = 0;
   }

   if (Digits == 5 || Digits == 3) gi_222 = 10; // Ïðîâåðêà íà ïÿòèçíàê
   return (0);
}
//==================================================================================================================================
int deinit() {
   return (0);
}
//==================================================================================================================================
int start() {
   Display_Info(); 
//-------------------------------
   double ld_84;
//-------------------------------
   double ord_lots_500;
   double ord_lots_508;
   double iclose_516;
   double iclose_524;
//-------------------------------
   DrawStats();
//-------------------------------
   if (Digits <= 3) ld_84 = 0.01;
   else   ld_84  = 0.0001;
   double ld_92  = NormalizeDouble((Ask - Bid) / ld_84, 1);
   string ls_100 = "  OK";
   if (ld_92 > MaxSpread) ls_100 = "  ÑËÈØÊÎÌ ÂÛÑÎÊÈÉ !";   
   string ls_124 = "Ñïðåä = " + DoubleToStr(ld_92, 1);
   string ls_140 = ls_100;   
//==================================================================================================================================
   ObjectCreate ("klc14", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc14", "Ñðåäñòâà: " + DoubleToStr(AccountEquity(), 2), 14, "Courier New", Yellow);
   ObjectSet    ("klc14", OBJPROP_CORNER, 1);
   ObjectSet    ("klc14", OBJPROP_XDISTANCE, 10);
   ObjectSet    ("klc14", OBJPROP_YDISTANCE, 93);
//----------------------------------------------------------------------------------------------
   ObjectCreate ("klc15", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc15", "Free Margin: " + DoubleToStr(AccountFreeMargin(), 2), 14, "Courier New", Yellow);
   ObjectSet    ("klc15", OBJPROP_CORNER, 1);
   ObjectSet    ("klc15", OBJPROP_XDISTANCE,  10);
   ObjectSet    ("klc15", OBJPROP_YDISTANCE, 124);
//----------------------------------------------------------------------------------------------
   ObjectCreate ("klc16", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc16", "Account Profit:   " + DoubleToStr(AccountProfit(), 2), 14, "Courier New", Yellow);
   ObjectSet    ("klc16", OBJPROP_CORNER, 1);
   ObjectSet    ("klc16", OBJPROP_XDISTANCE,  10);
   ObjectSet    ("klc16", OBJPROP_YDISTANCE, 143);
//----------------------------------------------------------------------------------------------
   ObjectCreate ("klc17", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc17", "Lots: " + DoubleToStr(Lots, 2), 14, "Courier New", LightGray); // WhiteSmoke
   ObjectSet    ("klc17", OBJPROP_CORNER, 1);
   ObjectSet    ("klc17", OBJPROP_XDISTANCE,  10);
   ObjectSet    ("klc17", OBJPROP_YDISTANCE, 175);
//----------------------------------------------------------------------------------------------
   ObjectCreate ("klc18", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc18", "Ðàáî÷èé Ëîò: " + DoubleToStr(gd_316, 2), 14, "Courier New", LightGray); // WhiteSmoke
   ObjectSet    ("klc18", OBJPROP_CORNER, 1);
   ObjectSet    ("klc18", OBJPROP_XDISTANCE, 10);
   ObjectSet    ("klc18", OBJPROP_YDISTANCE, 193);   
//----------------------------------------------------------------------------------------------
   ObjectCreate ("klc19", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc19", "Ñïðåä: " + DoubleToStr(ld_92, 1) + ls_140, 14, "Courier New", Gray);
   ObjectSet    ("klc19", OBJPROP_CORNER, 1);
   ObjectSet    ("klc19", OBJPROP_XDISTANCE,  10);
   ObjectSet    ("klc19", OBJPROP_YDISTANCE, 229);
//----------------------------------------------------------------------------------------------
   ObjectCreate ("klc20", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("klc20", "Current Time: " + TimeToStr(TimeCurrent(), TIME_MINUTES), 14, "Courier New", LightGray);
   ObjectSet    ("klc20", OBJPROP_CORNER, 3);
   ObjectSet    ("klc20", OBJPROP_XDISTANCE, 10);
   ObjectSet    ("klc20", OBJPROP_YDISTANCE,  8);
//==================================================================================================================================
   if (UseHourTrade_2) {
      if (!(Hour() >= StartHour && Hour() <= EndHour)) {
         CloseThisSymbolAll();
         Comment("                              ÂÐÅÌß ÄËß ÒÎÐÃÎÂËÈ ÅÙ¨ ÍÅ ÏÐÈØËÎ!");
         return (0);
      }
   }
   string ls_532 = "false";
   string ls_540 = "false";
   if (UseHourTrade == FALSE || (UseHourTrade && (EndHour > StartHour && (Hour() >= StartHour && Hour() <= EndHour)) || (StartHour > EndHour && (!(Hour() >= EndHour && Hour() <= StartHour))))) ls_532 = "true";
   if (UseHourTrade && (EndHour > StartHour && (!(Hour() >= StartHour && Hour() <= EndHour))) || (StartHour > EndHour && (Hour() >= EndHour && Hour() <= StartHour))) ls_540 = "true";
   if (UseTimeOut) {
      if (TimeCurrent() >= gi_308) {
         CloseThisSymbolAll();
         Print("Bñå ñäåëêè áóäóò çàêðûòû èç-çà Òàéì-Àóòà");
      }
   }
   if (g_time_304 == Time[0]) return (0);
   g_time_304 = Time[0];
   double ld_548 = CalculateProfit();
   if (UseEquityStop) {
      if (ld_548 < 0.0 && MathAbs(ld_548) > TotalEquityRisk / 100.0 * AccountEquityHigh()) {
         CloseThisSymbolAll();
         Print("Bñå ñäåëêè áóäóò çàêðûòû èç-çà ïðåâûøåíèÿ Ýêâèòè");
         gi_356 = FALSE;
      }
   }
   gi_328 = CountTrades();
   if (gi_328 == 0) gi_292 = FALSE;
   for (g_pos_324 = OrdersTotal() - 1; g_pos_324 >= 0; g_pos_324--) {
      OrderSelect(g_pos_324, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
         if (OrderType() == OP_BUY) {
            gi_344 = TRUE;
            gi_348 = FALSE;
            ord_lots_500 = OrderLots();
            break;
         }
      }
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
         if (OrderType() == OP_SELL) {
            gi_344 = FALSE;
            gi_348 = TRUE;
            ord_lots_508 = OrderLots();
            break;
         }
      }
   }
   if (gi_328 > 0 && gi_328 <= MaxTrades) {
      RefreshRates();
      gd_268 = FindLastBuyPrice();
      gd_276 = FindLastSellPrice();
      if (gi_344 && gd_268 - Ask >= PipStep * gi_222 * Point) gi_340 = TRUE;
      if (gi_348 && Bid - gd_276 >= PipStep * gi_222 * Point) gi_340 = TRUE;
   }
   if (gi_328 < 1) {
      gi_348 = FALSE;
      gi_344 = FALSE;
      gi_340 = TRUE;
      gd_220 = AccountEquity();
   }
   if (gi_340) {
      gd_268 = FindLastBuyPrice();
      gd_276 = FindLastSellPrice();
      if (gi_348) {
         if (UseClose || ls_540 == "true") {
            fOrderCloseMarket(0, 1);
            gd_316 = NormalizeDouble(LotExponent * ord_lots_508, Lot_Decimal);
         } else gd_316 = fGetLots(OP_SELL);
         if (UseAdd && ls_532 == "true") {
            gi_312 = gi_328;
            if (gd_316 > 0.0) {
               RefreshRates();
               gi_352 = OpenPendingOrder(1, gd_316, Bid, Slippage * gi_222, Ask, 0, 0, ExpertComment + "- " + gi_312, Magic, 0, Red);
               if (gi_352 < 0) {
                  Print(" Èñïðàâëåíèå îøèáêè: ", ErrorDescription(GetLastError()));
                  return (0);
               }
               gd_276 = FindLastSellPrice();
               gi_340 = FALSE;
               gi_356 = TRUE;
            }
         }
      } else {
         if (gi_344) {
            if (UseClose || ls_540 == "true") {
               fOrderCloseMarket(1, 0);
               gd_316 = NormalizeDouble(LotExponent * ord_lots_500, Lot_Decimal);
            } else gd_316 = fGetLots(OP_BUY);
            if (UseAdd && ls_532 == "true") {
               gi_312 = gi_328;
               if (gd_316 > 0.0) {
                  gi_352 = OpenPendingOrder(0, gd_316, Ask, Slippage * gi_222, Bid, 0, 0, ExpertComment + "- " + gi_312, Magic, 0, Blue);
                  if (gi_352 < 0) {
                     Print(" Èñïðàâëåíèå îøèáêè: ", ErrorDescription(GetLastError()));
                     return (0);
                  }
                  gd_268 = FindLastBuyPrice();
                  gi_340 = FALSE;
                  gi_356 = TRUE;
               }
            }
         }
      }
   }
//==================================================================================================================================
   if (gi_340 && gi_328 < 1) {
      iclose_516 = iClose(Symbol(), 0, 2);
      iclose_524 = iClose(Symbol(), 0, 1);
      g_bid_252 = Bid;
      g_ask_260 = Ask;
      if ((!gi_348) && !gi_344 && ls_532 == "true") {
         gi_312 = gi_328;
         if (iclose_516 > iclose_524) {
            gd_316 = fGetLots(OP_SELL);
            if (gd_316 > 0.0) { // gd_316     OpenLotSize
               gi_352 = OpenPendingOrder(1, gd_316, g_bid_252, Slippage * gi_222, g_bid_252, 0, 0, ExpertComment + "- " + gi_312, Magic, 0, Red);
               if (gi_352 < 0) {
                  Print(gd_316, " Èñïðàâëåíèå îøèáêè: ", ErrorDescription(GetLastError()));
                  return (0);
               }
               gd_268 = FindLastBuyPrice();
               gi_356 = TRUE;
            }
         } 
//----------------------------------------------------------------------------------------------         
         else {
            gd_316 = fGetLots(OP_BUY);
            if (gd_316 > 0.0) {
               gi_352 = OpenPendingOrder(0, gd_316, g_ask_260, Slippage * gi_222, g_ask_260, 0, 0, ExpertComment + "- " + gi_312, Magic, 0, Blue);
               if (gi_352 < 0) {
                  Print(gd_316, " Èñïðàâëåíèå îøèáêè: ", ErrorDescription(GetLastError()));
                  return (0);
               }
               gd_276 = FindLastSellPrice();
               gi_356 = TRUE;
            }
         }
      }
//==================================================================================================================================
      if (gi_352 > 0) gi_308 = TimeCurrent() + 60.0 * (60.0 * MaxTradeOpenHours);
      gi_340 = FALSE;
   }
   gi_328 = CountTrades();
   g_price_244 = 0;
   double ld_556 = 0;
   for (g_pos_324 = OrdersTotal() - 1; g_pos_324 >= 0; g_pos_324--) {
      OrderSelect(g_pos_324, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
         if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
            g_price_244 += OrderOpenPrice() * OrderLots();
            ld_556 += OrderLots();
         }
      }
   }
   if (gi_328 > 0) g_price_244 = NormalizeDouble(g_price_244 / ld_556, Digits);
   if (gi_356) {
      for (g_pos_324 = OrdersTotal() - 1; g_pos_324 >= 0; g_pos_324--) {
         OrderSelect(g_pos_324, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
            if (OrderType() == OP_BUY) {
               g_price_212 = g_price_244 + TakeProfit * gi_222 * Point;
               gd_unused_228 = g_price_212;
               gd_332 = g_price_244 - Stoploss * gi_222 * Point;
               gi_292 = TRUE;
            }
         }
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
            if (OrderType() == OP_SELL) {
               g_price_212 = g_price_244 - TakeProfit * gi_222 * Point;
               gd_unused_236 = g_price_212;
               gd_332 = g_price_244 + Stoploss * gi_222 * Point;
               gi_292 = TRUE;
            }
         }
      }
   }
   if (gi_356) {
      if (gi_292 == TRUE) {
         for (g_pos_324 = OrdersTotal() - 1; g_pos_324 >= 0; g_pos_324--) {
            OrderSelect(g_pos_324, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) OrderModify(OrderTicket(), g_price_244, OrderStopLoss(), g_price_212, 0, Yellow);
            gi_356 = FALSE;
         }
      }
   }
   return (0);
}
//==================================================================================================================================
double ND(double ad_0) {
   return (NormalizeDouble(ad_0, Digits));
}
//==================================================================================================================================
int fOrderCloseMarket(bool ai_0 = TRUE, bool ai_4 = TRUE) {
   int li_ret_8 = 0;
   for (int pos_12 = OrdersTotal() - 1; pos_12 >= 0; pos_12--) {
      if (OrderSelect(pos_12, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
            if (OrderType() == OP_BUY && ai_0) {
               RefreshRates();
               if (!IsTradeContextBusy()) {
                  if (!OrderClose(OrderTicket(), OrderLots(), ND(Bid), 5, CLR_NONE)) {
                     Print("Îøèáêà çàêðûòèÿ ñäåëêè BUY " + OrderTicket());
                     li_ret_8 = -1;
                  }
               } else {
                  if (g_datetime_360 != iTime(NULL, 0, 0)) {
                     g_datetime_360 = iTime(NULL, 0, 0);
                     Print("Ïîïûòêà çàêðûòèÿ ñäåëêè BUY " + OrderTicket() + ". Òîðãîâûé ïîòîê çàíÿò");
                  }
                  return (-2);
               }
            }
            if (OrderType() == OP_SELL && ai_4) {
               RefreshRates();
               if (!IsTradeContextBusy()) {
                  if (!(!OrderClose(OrderTicket(), OrderLots(), ND(Ask), 5, CLR_NONE))) continue;
                  Print("Îøèáêà çàêðûòèÿ ñäåëêè SELL " + OrderTicket());
                  li_ret_8 = -1;
                  continue;
               }
               if (g_datetime_364 != iTime(NULL, 0, 0)) {
                  g_datetime_364 = iTime(NULL, 0, 0);
                  Print("Ïîïûòêà çàêðûòèÿ ñäåëêè SELL " + OrderTicket() + ". Òîðãîâûé ïîòîê çàíÿò");
               }
               return (-2);
            }
         }
      }
   }
   return (li_ret_8);
}
//==================================================================================================================================
double fGetLots(int a_cmd_0) {
   double  lots_4;
   int     datetime_12;
   switch (MMType) {
   case 0:
      lots_4 = Lots;
      break;
   case 1:
      lots_4 = NormalizeDouble(Lots * MathPow(LotExponent, gi_312), Lot_Decimal);
      break;
   case 2:
      datetime_12 = 0;
      lots_4 = Lots;
      for (int pos_20 = OrdersHistoryTotal() - 1; pos_20 >= 0; pos_20--) {
         if (OrderSelect(pos_20, SELECT_BY_POS, MODE_HISTORY)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
               if (datetime_12 < OrderCloseTime()) {
                  datetime_12 = OrderCloseTime();
                  if (OrderProfit() < 0.0) {
                     lots_4 = NormalizeDouble(OrderLots() * LotExponent, Lot_Decimal);
                     continue;
                  }
                  lots_4 = Lots;
               }
            }
         } else return (-3);
      }
   }
   if (AccountFreeMarginCheck(Symbol(), a_cmd_0, lots_4) <= 0.0) return (-1);
   if (GetLastError() == 134/* NOT_ENOUGH_MONEY */) return (-2);
   return (lots_4);
}
//==================================================================================================================================
int CountTrades() {
   int count_0 = 0;
   for (int pos_4 = OrdersTotal() - 1; pos_4 >= 0; pos_4--) {
      OrderSelect(pos_4, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
         if (OrderType() == OP_SELL || OrderType() == OP_BUY) count_0++;
   }
   return (count_0);
}
//==================================================================================================================================
void CloseThisSymbolAll() {
   for (int pos_0 = OrdersTotal() - 1; pos_0 >= 0; pos_0--) {
      OrderSelect(pos_0, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() == Symbol()) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
            if (OrderType() ==  OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, Slippage * gi_222, Blue);
            if (OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, Slippage * gi_222, Red);
         }
         Sleep(1000);
      }
   }
}
//==================================================================================================================================
int OpenPendingOrder(int ai_0, double a_lots_4, double a_price_12, int a_slippage_20, double ad_24, int ai_unused_32, int ai_36, string a_comment_40, int a_magic_48, int a_datetime_52, color a_color_56) {
   int ticket_60 =   0;
   int error_64  =   0;
   int count_68  =   0;
   int li_72     = 100;
   switch (ai_0) {
   case 2:
      for (count_68 = 0; count_68 < li_72; count_68++) {
         ticket_60 = OrderSend(Symbol(), OP_BUYLIMIT, a_lots_4, a_price_12, a_slippage_20, StopLong(ad_24, Stoploss * gi_222), TakeLong(a_price_12, ai_36), a_comment_40, a_magic_48, a_datetime_52, a_color_56);
         error_64 = GetLastError();
         if (error_64 == 0/* NO_ERROR */) break;
         if (!((error_64 == 4/* SERVER_BUSY */ || error_64 == 137/* BROKER_BUSY */ || error_64 == 146/* TRADE_CONTEXT_BUSY */ || error_64 == 136/* OFF_QUOTES */))) break;
         Sleep(1000);
      }
      break;
   case 4:
      for (count_68 = 0; count_68 < li_72; count_68++) {
         ticket_60 = OrderSend(Symbol(), OP_BUYSTOP, a_lots_4, a_price_12, a_slippage_20, StopLong(ad_24, Stoploss * gi_222), TakeLong(a_price_12, ai_36), a_comment_40, a_magic_48, a_datetime_52, a_color_56);
         error_64 = GetLastError();
         if (error_64 == 0/* NO_ERROR */) break;
         if (!((error_64 == 4/* SERVER_BUSY */ || error_64 == 137/* BROKER_BUSY */ || error_64 == 146/* TRADE_CONTEXT_BUSY */ || error_64 == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
      break;
   case 0:
      for (count_68 = 0; count_68 < li_72; count_68++) {
         RefreshRates();
         ticket_60 = OrderSend(Symbol(), OP_BUY, a_lots_4, Ask, a_slippage_20, StopLong(Bid, Stoploss * gi_222), TakeLong(Ask, ai_36), a_comment_40, a_magic_48, a_datetime_52, a_color_56);
         error_64 = GetLastError();
         if (error_64 == 0/* NO_ERROR */) break;
         if (!((error_64 == 4/* SERVER_BUSY */ || error_64 == 137/* BROKER_BUSY */ || error_64 == 146/* TRADE_CONTEXT_BUSY */ || error_64 == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
      break;
   case 3:
      for (count_68 = 0; count_68 < li_72; count_68++) {
         ticket_60 = OrderSend(Symbol(), OP_SELLLIMIT, a_lots_4, a_price_12, a_slippage_20, StopShort(ad_24, Stoploss * gi_222), TakeShort(a_price_12, ai_36), a_comment_40, a_magic_48, a_datetime_52, a_color_56);
         error_64 = GetLastError();
         if (error_64 == 0/* NO_ERROR */) break;
         if (!((error_64 == 4/* SERVER_BUSY */ || error_64 == 137/* BROKER_BUSY */ || error_64 == 146/* TRADE_CONTEXT_BUSY */ || error_64 == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
      break;
   case 5:
      for (count_68 = 0; count_68 < li_72; count_68++) {
         ticket_60 = OrderSend(Symbol(), OP_SELLSTOP, a_lots_4, a_price_12, a_slippage_20, StopShort(ad_24, Stoploss * gi_222), TakeShort(a_price_12, ai_36), a_comment_40, a_magic_48, a_datetime_52, a_color_56);
         error_64 = GetLastError();
         if (error_64 == 0/* NO_ERROR */) break;
         if (!((error_64 == 4/* SERVER_BUSY */ || error_64 == 137/* BROKER_BUSY */ || error_64 == 146/* TRADE_CONTEXT_BUSY */ || error_64 == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
      break;
   case 1:
      for (count_68 = 0; count_68 < li_72; count_68++) {
         ticket_60 = OrderSend(Symbol(), OP_SELL, a_lots_4, Bid, a_slippage_20, StopShort(Ask, Stoploss * gi_222), TakeShort(Bid, ai_36), a_comment_40, a_magic_48, a_datetime_52, a_color_56);
         error_64 = GetLastError();
         if (error_64 == 0/* NO_ERROR */) break;
         if (!((error_64 == 4/* SERVER_BUSY */ || error_64 == 137/* BROKER_BUSY */ || error_64 == 146/* TRADE_CONTEXT_BUSY */ || error_64 == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
   }
   return (ticket_60);
}
//==================================================================================================================================
double StopLong(double ad_0, int ai_8) {
   if (ai_8 == 0) return (0);
   return (ad_0 - ai_8 * Point);
}
//==================================================================================================================================
double StopShort(double ad_0, int ai_8) {
   if (ai_8 == 0) return (0);
   return (ad_0 + ai_8 * Point);
}
//==================================================================================================================================
double TakeLong(double ad_0, int ai_8) {
   if (ai_8 == 0) return (0);
   return (ad_0 + ai_8 * Point);
}
//==================================================================================================================================
double TakeShort(double ad_0, int ai_8) {
   if (ai_8 == 0) return (0);
   return (ad_0 - ai_8 * Point);
}
//==================================================================================================================================
double CalculateProfit() {
   double ld_ret_0 = 0;
   for (g_pos_324 = OrdersTotal() - 1; g_pos_324 >= 0; g_pos_324--) {
      OrderSelect(g_pos_324, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
         if (OrderType() == OP_BUY || OrderType() == OP_SELL) ld_ret_0 += OrderProfit();
   }
   return (ld_ret_0);
}
//==================================================================================================================================
double AccountEquityHigh() {
   if (CountTrades() == 0) gd_368 = AccountEquity();
   if (gd_368 < gd_376) gd_368 = gd_376;
   else gd_368 = AccountEquity();
   gd_376 = AccountEquity();
   return (gd_368);
}
//==================================================================================================================================
double FindLastBuyPrice() {
   double ord_open_price_0;
   int    ticket_8;
   double ld_unused_12 = 0;
   int    ticket_20 = 0;
   for (int pos_24 = OrdersTotal() - 1; pos_24 >= 0; pos_24--) {
      OrderSelect(pos_24, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_BUY) {
         ticket_8 = OrderTicket();
         if (ticket_8 > ticket_20) {
            ord_open_price_0 = OrderOpenPrice();
            ld_unused_12 = ord_open_price_0;
            ticket_20 = ticket_8;
         }
      }
   }
   return (ord_open_price_0);
}
//==================================================================================================================================
double FindLastSellPrice() {
   double ord_open_price_0;
   int    ticket_8;
   double ld_unused_12 = 0;
   int    ticket_20    = 0;
   for (int pos_24 = OrdersTotal() - 1; pos_24 >= 0; pos_24--) {
      OrderSelect(pos_24, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != Magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_SELL) {
         ticket_8 = OrderTicket();
         if (ticket_8 > ticket_20) {
            ord_open_price_0 = OrderOpenPrice();
            ld_unused_12 = ord_open_price_0;
            ticket_20 = ticket_8;
         }
      }
   }
   return (ord_open_price_0);
}
//==================================================================================================================================
void Display_Info() {  // Âûâîä èíôîðìàöèè â óãëó îêíà
    Comment(
            "                              Account:  ", AccountServer(),
      "\n", "                              Leverage:   ",  "1:" + DoubleToStr(AccountLeverage(), 0),
      "\n",
      "\n", "                              Lot Exponential  =  ", LotExponent,
      "\n", "                              Pip Step          =  ", PipStep,
      "\n", "                              Take Profit       =  ", TakeProfit,
      "\n", "                              Slippage  =  ", Slippage,
      "\n");
}
//==================================================================================================================================
//| ErrorDescription. Âîçâðàùàåò îïèñàíèå îøèáêè ïî å¸ íîìåðó.
//+---------------------------------------------------------------------------------------------------------------------------------
string ErrorDescription(int error) {
   string ErrorNumber;
   switch (error) {
   case 0:
   case 1:     ErrorNumber = "Îøèáêà èñïðàâëåíà";                                          break;  // Íåò îøèáêè, íî ðåçóëüòàò íåèçâåñòåí
   case 2:     ErrorNumber = "Îáùàÿ îøèáêà";                                               break;
   case 3:     ErrorNumber = "Íåïðàâèëüíûå ïàðàìåòðû";                                     break;
   case 4:     ErrorNumber = "Òîðãîâûé ñåðâåð çàíÿò";                                      break;
   case 5:     ErrorNumber = "Ñòàðàÿ âåðñèÿ êëèåíòñêîãî òåðìèíàëà";                        break;
   case 6:     ErrorNumber = "Íåò ñâÿçè ñ òîðãîâûì ñåðâåðîì";                              break;
   case 7:     ErrorNumber = "Íåäîñòàòî÷íî ïðàâ";                                          break;
   case 8:     ErrorNumber = "Ñëèøêîì ÷àñòûå çàïðîñû";                                     break;
   case 9:     ErrorNumber = "Íåäîïóñòèìàÿ îïåðàöèÿ íàðóøàþùàÿ ôóíêöèîíèðîâàíèå ñåðâåðà";  break;
   case 64:    ErrorNumber = "Ñ÷åò çàáëîêèðîâàí";                                          break;
   case 65:    ErrorNumber = "Íåïðàâèëüíûé íîìåð ñ÷åòà";                                   break;
   case 128:   ErrorNumber = "Èñòåê ñðîê îæèäàíèÿ ñîâåðøåíèÿ ñäåëêè";                      break;
   case 129:   ErrorNumber = "Íåïðàâèëüíàÿ öåíà";                                          break;
   case 130:   ErrorNumber = "Íåïðàâèëüíûå ñòîïû";                                         break;
   case 131:   ErrorNumber = "Íåïðàâèëüíûé îáúåì";                                         break;
   case 132:   ErrorNumber = "Ðûíîê çàêðûò";                                               break;
   case 133:   ErrorNumber = "Òîðãîâëÿ çàïðåùåíà";                                         break;
   case 134:   ErrorNumber = "Íåäîñòàòî÷íî äåíåã äëÿ ñîâåðøåíèÿ îïåðàöèè";                 break;
   case 135:   ErrorNumber = "Öåíà èçìåíèëàñü";                                            break;
   case 136:   ErrorNumber = "Íåò öåí";                                                    break;
   case 137:   ErrorNumber = "Áðîêåð çàíÿò";                                               break;
   case 138:   ErrorNumber = "Íîâûå öåíû - Ðåêâîò";                                        break;
   case 139:   ErrorNumber = "Îðäåð çàáëîêèðîâàí è óæå îáðàáàòûâàåòñÿ";                    break;
   case 140:   ErrorNumber = "Ðàçðåøåíà òîëüêî ïîêóïêà";                                   break;
   case 141:   ErrorNumber = "Ñëèøêîì ìíîãî çàïðîñîâ";                                     break;
   case 145:   ErrorNumber = "Ìîäèôèêàöèÿ çàïðåùåíà, òàê êàê îðäåð ñëèøêîì áëèçîê ê ðûíêó";break;
   case 146:   ErrorNumber = "Ïîäñèñòåìà òîðãîâëè çàíÿòà";                                 break;
   case 147:   ErrorNumber = "Èñïîëüçîâàíèå äàòû èñòå÷åíèÿ îðäåðà çàïðåùåíî áðîêåðîì";     break;
   case 148:   ErrorNumber = "Êîëè÷åñòâî îòêðûòûõ è îòëîæåííûõ îðäåðîâ äîñòèãëî ïðåäåëà "; break;
//-----------------------------------------------------------------------------------------------
   case 4000:  ErrorNumber = "Íåò îøèáêè";                                                 break;
   case 4001:  ErrorNumber = "Íåïðàâèëüíûé óêàçàòåëü ôóíêöèè";                             break;
   case 4002:  ErrorNumber = "Èíäåêñ ìàññèâà - âíå äèàïàçîíà";                             break;
   case 4003:  ErrorNumber = "Íåò ïàìÿòè äëÿ ñòåêà ôóíêöèé";                               break;
   case 4004:  ErrorNumber = "Ïåðåïîëíåíèå ñòåêà ïîñëå ðåêóðñèâíîãî âûçîâà";               break;
   case 4005:  ErrorNumber = "Íà ñòåêå íåò ïàìÿòè äëÿ ïåðåäà÷è ïàðàìåòðîâ";                break;
   case 4006:  ErrorNumber = "Íåò ïàìÿòè äëÿ ñòðîêîâîãî ïàðàìåòðà";                        break;
   case 4007:  ErrorNumber = "Íåò ïàìÿòè äëÿ âðåìåííîé ñòðîêè";                            break;
   case 4008:  ErrorNumber = "Íåèíèöèàëèçèðîâàííàÿ ñòðîêà";                                break;
   case 4009:  ErrorNumber = "Íåèíèöèàëèçèðîâàííàÿ ñòðîêà â ìàññèâå";                      break;
   case 4010:  ErrorNumber = "Íåò ïàìÿòè äëÿ ñòðîêîâîãî ìàññèâà";                          break;
   case 4011:  ErrorNumber = "Ñëèøêîì äëèííàÿ ñòðîêà";                                     break;
   case 4012:  ErrorNumber = "Îñòàòîê îò äåëåíèÿ íà íîëü";                                 break;
   case 4013:  ErrorNumber = "Äåëåíèå íà íîëü";                                            break;
   case 4014:  ErrorNumber = "Íåèçâåñòíàÿ êîìàíäà";                                        break;
   case 4015:  ErrorNumber = "Íåïðàâèëüíûé ïåðåõîä";                                       break;
   case 4016:  ErrorNumber = "Íåèíèöèàëèçèðîâàííûé ìàññèâ";                                break;
   case 4017:  ErrorNumber = "Âûçîâû DLL íå ðàçðåøåíû";                                    break;
   case 4018:  ErrorNumber = "Íåâîçìîæíî çàãðóçèòü áèáëèîòåêó";                            break;
   case 4019:  ErrorNumber = "Íåâîçìîæíî âûçâàòü ôóíêöèþ";                                 break;
   case 4020:  ErrorNumber = "Âûçîâû âíåøíèõ áèáëèîòå÷íûõ ôóíêöèé íå ðàçðåøåíû";           break;
   case 4021:  ErrorNumber = "Íåäîñòàòî÷íî ïàìÿòè äëÿ ñòðîêè, âîçâðàùàåìîé èç ôóíêöèè";    break;
   case 4022:  ErrorNumber = "Ñèñòåìà çàíÿòà";                                             break;
   case 4050:  ErrorNumber = "Íåïðàâèëüíîå êîëè÷åñòâî ïàðàìåòðîâ ôóíêöèè";                 break;
   case 4051:  ErrorNumber = "Íåäîïóñòèìîå çíà÷åíèå ïàðàìåòðà ôóíêöèè";                    break;
   case 4052:  ErrorNumber = "Âíóòðåííÿÿ îøèáêà ñòðîêîâîé ôóíêöèè";                        break;
   case 4053:  ErrorNumber = "Îøèáêà ìàññèâà";                                             break;
   case 4054:  ErrorNumber = "Íåïðàâèëüíîå èñïîëüçîâàíèå ìàññèâà-òàéìñåðèè";               break;
   case 4055:  ErrorNumber = "Îøèáêà ïîëüçîâàòåëüñêîãî èíäèêàòîðà";                        break;
   case 4056:  ErrorNumber = "Ìàññèâû íåñîâìåñòèìû";                                       break;
   case 4057:  ErrorNumber = "Îøèáêà îáðàáîòêè ãëîáàëüíûåõ ïåðåìåííûõ";                    break;
   case 4058:  ErrorNumber = "Ãëîáàëüíàÿ ïåðåìåííàÿ íå îáíàðóæåíà";                        break;
   case 4059:  ErrorNumber = "Ôóíêöèÿ íå ðàçðåøåíà â òåñòîâîì ðåæèìå";                     break;
   case 4060:  ErrorNumber = "Ôóíêöèÿ íå ïîäòâåðæäåíà";                                    break;
   case 4061:  ErrorNumber = "Îøèáêà îòïðàâêè ïî÷òû";                                      break;
   case 4062:  ErrorNumber = "Îæèäàåòñÿ ïàðàìåòð òèïà string";                             break;
   case 4063:  ErrorNumber = "Îæèäàåòñÿ ïàðàìåòð òèïà integer";                            break;
   case 4064:  ErrorNumber = "Îæèäàåòñÿ ïàðàìåòð òèïà double";                             break;
   case 4065:  ErrorNumber = "Â êà÷åñòâå ïàðàìåòðà îæèäàåòñÿ ìàññèâ";                      break;
   case 4066:  ErrorNumber = "Çàïðîøåííûå èñòîðè÷åñêèå äàííûå â ñîñòîÿíèè îáíîâëåíèÿ";     break;
   case 4067:  ErrorNumber = "Îøèáêà ïðè âûïîëíåíèè òîðãîâîé îïåðàöèè";                    break;
   case 4099:  ErrorNumber = "Êîíåö ôàéëà";                                                break;
   case 4100:  ErrorNumber = "Îøèáêà ïðè ðàáîòå ñ ôàéëîì";                                 break;
   case 4101:  ErrorNumber = "Íåïðàâèëüíîå èìÿ ôàéëà";                                     break;
   case 4102:  ErrorNumber = "Ñëèøêîì ìíîãî îòêðûòûõ ôàéëîâ";                              break;
   case 4103:  ErrorNumber = "Íåâîçìîæíî îòêðûòü ôàéë";                                    break;
   case 4104:  ErrorNumber = "Íåñîâìåñòèìûé ðåæèì äîñòóïà ê ôàéëó";                        break;
   case 4105:  ErrorNumber = "Íè îäèí îðäåð íå âûáðàí";                                    break;
   case 4106:  ErrorNumber = "Íåèçâåñòíûé ñèìâîë";                                         break;
   case 4107:  ErrorNumber = "Íåïðàâèëüíûé ïàðàìåòð öåíû äëÿ òîðãîâîé ôóíêöèè";            break;
   case 4108:  ErrorNumber = "Íåâåðíûé íîìåð òèêåòà";                                      break;
   case 4109:  ErrorNumber = "Òîðãîâëÿ íå ðàçðåøåíà";                                      break;
   case 4110:  ErrorNumber = "Äëèííûå ïîçèöèè íå ðàçðåøåíû";                               break;
   case 4111:  ErrorNumber = "Êîðîòêèå ïîçèöèè íå ðàçðåøåíû";                              break;
   case 4200:  ErrorNumber = "Îáúåêò óæå ñóùåñòâóåò";                                      break;
   case 4201:  ErrorNumber = "Çàïðîøåíî íåèçâåñòíîå ñâîéñòâî îáúåêòà";                     break;
   case 4202:  ErrorNumber = "Îáúåêò íå ñóùåñòâóåò";                                       break;
   case 4203:  ErrorNumber = "Íåèçâåñòíûé òèï îáúåêòà";                                    break;
   case 4204:  ErrorNumber = "Íåò èìåíè îáúåêòà";                                          break;
   case 4205:  ErrorNumber = "Îøèáêà êîîðäèíàò îáúåêòà";                                   break;
   case 4206:  ErrorNumber = "Íå íàéäåíî óêàçàííîå ïîäîêíî";                               break;
   case 4207:  ErrorNumber = "Îøèáêà ïðè ðàáîòå ñ îáúåêòîì";                               break;
   default:    ErrorNumber = "Íåèçâåñòíàÿ îøèáêà";
   }
   return (ErrorNumber);
}
//==================================================================================================================================
double GetProfitForDay(int ai_01) {
   double ld_ret_4 = 0;
   for (int l_pos_12 = 0; l_pos_12 < OrdersHistoryTotal(); l_pos_12++) {
      if (!(OrderSelect(l_pos_12, SELECT_BY_POS, MODE_HISTORY))) break;
      if (OrderSymbol() == Symbol())
         if (OrderCloseTime() >= iTime(Symbol(), PERIOD_D1, ai_01) && OrderCloseTime() < iTime(Symbol(), PERIOD_D1, ai_01) + 86400) ld_ret_4 += OrderProfit() + OrderSwap() + OrderCommission();
   }
   return (ld_ret_4);
}
//==================================================================================================================================
void DrawStats() {
   double ld_0 = GetProfitForDay(0);
   string l_name_8 = gs_140 + "1";
   if (ObjectFind  (l_name_8) == -1) {
       ObjectCreate(l_name_8, OBJ_LABEL, 0, 0, 0);
       ObjectSet   (l_name_8, OBJPROP_CORNER, 1);
       ObjectSet   (l_name_8, OBJPROP_XDISTANCE, 10);
       ObjectSet   (l_name_8, OBJPROP_YDISTANCE, 15);
   }
   ObjectSetText(l_name_8, "Çàðàáîòîê ñåãîäíÿ: " + DoubleToStr(ld_0, 2), 12, "Courier New", Yellow);
   ld_0 = GetProfitForDay(1);
   l_name_8 = gs_140 + "2";
   if (ObjectFind  (l_name_8) == -1) {
       ObjectCreate(l_name_8, OBJ_LABEL, 0, 0, 0);
       ObjectSet   (l_name_8, OBJPROP_CORNER, 1);
       ObjectSet   (l_name_8, OBJPROP_XDISTANCE, 10);
       ObjectSet   (l_name_8, OBJPROP_YDISTANCE, 30);
   }
   ObjectSetText(l_name_8, "Çàðàáîòîê â÷åðà: " + DoubleToStr(ld_0, 2), 12, "Courier New", Yellow);
   ld_0 = GetProfitForDay(2);
   l_name_8 = gs_140 + "3";
   if (ObjectFind  (l_name_8) == -1) {
       ObjectCreate(l_name_8, OBJ_LABEL, 0, 0, 0);
       ObjectSet   (l_name_8, OBJPROP_CORNER, 1);
       ObjectSet   (l_name_8, OBJPROP_XDISTANCE, 10);
       ObjectSet   (l_name_8, OBJPROP_YDISTANCE, 45);
   }
   ObjectSetText(l_name_8, "Çàðàáîòîê ïîçàâ÷åðà: " + DoubleToStr(ld_0, 2), 12, "Courier New", Yellow);
   l_name_8 = gs_140 + "4";
   if (ObjectFind  (l_name_8) == -1) {
       ObjectCreate(l_name_8, OBJ_LABEL, 0, 0, 0);
       ObjectSet   (l_name_8, OBJPROP_CORNER, 1);
       ObjectSet   (l_name_8, OBJPROP_XDISTANCE, 10);
       ObjectSet   (l_name_8, OBJPROP_YDISTANCE, 75);
   }
   ObjectSetText(l_name_8, "Áàëàíñ: " + DoubleToStr(AccountBalance(), 2), 14, "Courier New", Yellow);
}
//==================================================================================================================================
//==================================================================================================================================
//==================================================================================================================================
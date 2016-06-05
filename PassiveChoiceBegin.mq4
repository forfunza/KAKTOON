//+------------------------------------------------------------------+
//|                                        PassiveChoice | Begin.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyrights © 2016 , All Rights Reserved by PassiveChoice.com "
#property version   "1.00"
#property strict

extern int TakeProfit=100;
extern int InitialPipStep=100;
extern int InitialPipStepUp=2;
extern int TotalOrderPipStepUp=5;
extern double ProfitPercent=0.001;
extern double InitialLots=0.1;
extern double LotsExponent=1.4;
extern double TakeProfitReduceRate=0.06;
extern int MinTakeProfitReduceHour=1;
extern bool AllowUltiOrder=true;
extern int StopLossTrailingUltiOrder=200;
extern int StopLossUltiOrder=400;
extern int TakeProfitUltiOrder=750;
extern int StopLossTotal=24;
extern int RiskOrderTotal=15;
extern int Index=8;
extern int TrendGaP=450;
extern double initialAccountBalance;
extern string initialNews;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum trademode
  {
   T=0,// Top
   M=1     // Mid
  };
input trademode TradeMode=T;
double miximumLot = 0.10;
double dynamicLot = 0;
double lastOrderSL=150;
int maxOrder;
int slippage=10;
int stopLossCounter=0;
int dynamicStopLoss= 0;

datetime nextNewsTime;
string nextNewsIssue;
string nextNewsCountry;
double tmpExpo;

bool emptyNews=false;
bool isQuery=false;
float impactMinute;
float impactHour;
float impactDay;

int BB_OrderType;

#include <MQLMySQL.mqh>
//+------------------------------------------------------------------+
//| Order Info                                                       |
//+------------------------------------------------------------------+
struct OrderInfo
  {
   double            lots;
   int               pipStep;
   double            lotExpo;
   int               lastOrderTicket;
   double            lastOrderPrice;
   double            lastOrderTPPrice;
   double            cumulativeTakeProfitReduce;
   datetime          firstOrderTime;
   datetime          lastTakeProfitModifiedTime;
   double            takeProfitLevel;
   double            takeProfitLevelUltiOrder;
   bool              tradingAllowed;
   bool              orderInRisk;
   double            riskPrice;
   int               orderType;
   int               magic;
   int               ultiMagicNumber;
   int               ultiOrderTicket;
   int               ultiOrderCounter;
   int               winUltiOrderCounter;
  };

OrderInfo buyOrderInfo;
OrderInfo sellOrderInfo;

int MySQLReconnectAddTime=3*3600;
int OneHour=1*3600;
string Query;
int    i,Cursor,Rows;
int DB; // database identifier
string eaStatus="EA not working. Please Contact www.passivechoice.com";

int TPR1;
int TPR2;
double lots[11];

bool isReset=false;

extern int RL=35;
extern int PPO=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   MQLConnectSQL();

   bool userResponse=CheckUserExist(AccountNumber());

   if(userResponse)
     {

      buyOrderInfo.orderType=OP_BUY;
      buyOrderInfo.magic=11111;
      buyOrderInfo.ultiMagicNumber=33333;
      buyOrderInfo.tradingAllowed = true;
      buyOrderInfo.lots=InitialLots;
      buyOrderInfo.lotExpo = LotsExponent;
      buyOrderInfo.pipStep = InitialPipStep;
      sellOrderInfo.orderType=OP_SELL;
      sellOrderInfo.magic=22222;
      sellOrderInfo.ultiMagicNumber=44444;
      sellOrderInfo.tradingAllowed = true;
      sellOrderInfo.lots=InitialLots;
      sellOrderInfo.lotExpo = LotsExponent;
      sellOrderInfo.pipStep = InitialPipStep;
      GetLastOrder(buyOrderInfo);
      GetLastOrder(sellOrderInfo);
      DrawStat();
      return(INIT_SUCCEEDED);

        }else{
      DrawStat();

      return(INIT_FAILED);
     }

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   MQLDisconnectSQL();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(IsTradeAllowed())
     {

      if(BBStrategy()==OP_BUY && CountOrderByMagicNumber(sellOrderInfo.magic)==0)
        {
         ProcessOrderState(buyOrderInfo);
           }else if(BBStrategy()==OP_SELL && CountOrderByMagicNumber(buyOrderInfo.magic)==0){
         ProcessOrderState(sellOrderInfo);
        }

      if(CountOrderByMagicNumber(sellOrderInfo.magic)>0)
        {
         ProcessOrderState(sellOrderInfo);
        }

      if(CountOrderByMagicNumber(buyOrderInfo.magic)>0)
        {
         ProcessOrderState(buyOrderInfo);
        }

      if(CountOrderByMagicNumber(buyOrderInfo.magic)>=StopLossTotal)
        {
         buyOrderInfo.tradingAllowed=false;
         double SL=buyOrderInfo.lastOrderPrice-500*Point;
         ModifyStopLoss(SL,buyOrderInfo);

        }

      if(CountOrderByMagicNumber(sellOrderInfo.magic)>=StopLossTotal)
        {
         sellOrderInfo.tradingAllowed=false;
         double SL=sellOrderInfo.lastOrderPrice+500*Point;
         ModifyStopLoss(SL,sellOrderInfo);

        }

      //if(TimeCurrent()>(MySqlLastConnect+MySQLReconnectAddTime) || DB==-1)
      //  {
      //   MQLDisconnectSQL();
      //   MQLConnectSQL();
      //  }

     }

   DrawStat();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateRecoveryLots(double startLot)
  {

   lots[1]=startLot;

   double L1TP=lots[1]*TakeProfit;
   double TPR1PPO=TPR1-PPO;
   double L2=L1TP/TPR1PPO;

   lots[2]=L2;

   double L2TPR2= L2 * TPR2;
   double TPPPO = TakeProfit-PPO;
   double L3_SE = L1TP-L2TPR2;
   double L3=MathAbs(L3_SE)/TPPPO;

   lots[3]=L3;

   double L2TPR1=L2*TPR1;
   double L3TP=lots[3]*TakeProfit;
   double L4_SE=(-L1TP+L2TPR1)-L3TP;
   double L4=MathAbs(L4_SE)/TPR1PPO;

   lots[4]=L4;

   double L4TPR2=lots[4]*TPR2;
   double L5_SE = L3_SE + L3TP - L4TPR2;
   double L5=MathAbs(L5_SE)/TPPPO;

   lots[5]=L5;

   double L4TPR1=L4*TPR1;
   double L5TP=lots[5]*TakeProfit;
   double L6_SE=(L4_SE+L4TPR1)-L5TP;
   double L6=MathAbs(L6_SE)/TPR1PPO;

   lots[6]=L6;

   double L6TPR2= L6 * TPR2;
   double L7_SE =(L5_SE + L5TP) - L6TPR2;
   double L7=MathAbs(L7_SE)/TPPPO;

   lots[7]=L7;

   double L7TP=lots[7]*TakeProfit;
   double L6TPR1= lots[6] * TPR1;
   double L8_SE =(L6_SE+L6TPR1)-L7TP;
   double L8=MathAbs(L8_SE)/TPR1PPO;

   lots[8]=L8;

   double L8TPR2= lots[8] * TPR2;
   double L9_SE =(L7_SE+L7TP)-L8TPR2;
   double L9=MathAbs(L9_SE)/TPPPO;

   lots[9]=L9;

   double L8TPR1=lots[8]*TPR1;
   double L9TP=lots[9]*TakeProfit;
   double L10_SE=(L8_SE+L8TPR1)-L9TP;
   double L10=MathAbs(L10_SE)/TPR1PPO;

   lots[10]=L10;

   for(int i=1; i<=10; i++)
     {
      Print("Lot : "+i+" = "+lots[i]);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckUserExist(int id)
  {
   int vAccount_id;
   string vReason;
   int vStatus;

   Query="SELECT * FROM `user_accounts` WHERE account_id = '"+id+"' AND (status = 1 OR status = 2)";

   Cursor=MySqlCursorOpen(DB,Query);

   if(Cursor>=0)
     {
      Rows=MySqlCursorRows(Cursor);
      for(i=0; i<Rows; i++)
         if(MySqlCursorFetchRow(Cursor))
           {
            vStatus=MySqlGetFieldAsInt(Cursor,3); // id

           }

      if(vStatus==1)
         eaStatus="Free Trial";
      else if(vStatus==2)
         eaStatus="Welcome to PassiveChoiceBegin";
      if(Rows>0)
        {
         MySqlCursorClose(Cursor); // NEVER FORGET TO CLOSE CURSOR !!!
         return true;
        }
     }
   else
     {
      Print("Cursor opening CheckUserExist. Error: ",MySqlErrorDescription);
     }
   MySqlCursorClose(Cursor);

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQLConnectSQL()
  {
   string Host,User,Password,Database,Socket; // database credentials
   int Port,ClientFlag;

   Host = "www.passivechoice.com";
   User = "passive_2016";
   Password = "mO4tzJNmd4";
   Database = "passive_2016";
   Port     = 3306;
   Socket   = "0";
   ClientFlag=0;

   DB=MySqlConnect(Host,User,Password,Database,Port,Socket,ClientFlag);

   if(DB==-1) { Print("Connection failed! Error: "+MySqlErrorDescription); return; } else { Print("Connected! DBID#",DB);}
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQLDisconnectSQL()
  {
   MySqlDisconnect(DB);

  }
//+------------------------------------------------------------------+
//| Process Order State                                              |
//+------------------------------------------------------------------+
void ProcessOrderState(OrderInfo &orderInfo)
  {
   if(CountOrderByMagicNumber(orderInfo.magic)==0 && orderInfo.lots>InitialLots)
     {

      ResetParameter(orderInfo);
     }

   if(orderInfo.tradingAllowed)
     {
      PlaceOrder(orderInfo);
     }
   else
     {
      if(CountOrderByMagicNumber(orderInfo.ultiMagicNumber)==0)
        {

         bool res=OrderSelect(orderInfo.ultiOrderTicket,SELECT_BY_TICKET,MODE_TRADES);
         if(res)
           {

            orderInfo.tradingAllowed=true;
            if(OrderProfit()>0)
               orderInfo.winUltiOrderCounter++;
            orderInfo.ultiOrderTicket=0;

           }
        }
      else
        {

         if((orderInfo.orderType==OP_BUY && GetOpenPrice(orderInfo.orderType)<orderInfo.takeProfitLevelUltiOrder)
            || (orderInfo.orderType==OP_SELL && GetOpenPrice(orderInfo.orderType)>orderInfo.takeProfitLevelUltiOrder))
           {
            double StopLossLevelUltiOrder=orderInfo.takeProfitLevelUltiOrder+(orderInfo.orderType==OP_BUY?1:-1)*StopLossTrailingUltiOrder*Point;
            bool res=OrderSelect(orderInfo.ultiOrderTicket,SELECT_BY_TICKET);
            res=OrderModify(OrderTicket(),OrderOpenPrice(),StopLossLevelUltiOrder,0,0);
            if(res)
               Print("Modify UltiOrder ",OrderType()," Stop Loss : ",StopLossLevelUltiOrder);
            else
               Print("Error Modifying UltiOrder Stop Loss ");
            orderInfo.takeProfitLevelUltiOrder=GetOpenPrice(orderInfo.orderType);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BBStrategy()
  {
   double EMA=NormalizeDouble(iMA(NULL,0,60,0,MODE_EMA,PRICE_CLOSE,0),Digits);
   double BandLow=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,0),Digits);
   double BandMid=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_MAIN,0),Digits);
   double BandHigh=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,0),Digits);
   if(TimeHour(TimeCurrent())>Index)
     {
      if(TradeMode==0)
        {

         if(Bid>EMA+TrendGaP*Point)
           {

            if(Ask<BandLow)
              {
               return OP_BUY;
              }

              }else if(Ask<EMA-TrendGaP*Point){
            if(Bid>BandHigh)
              {
               return OP_SELL;
              }
           }
           }else if(TradeMode==1){
         if(Bid>EMA+TrendGaP*Point)
           {
               if(Bid > BandMid && Bid < BandHigh -100*Point){
               return OP_BUY;
               }
              }else if(Ask<EMA-TrendGaP*Point){
              
              if(Ask < BandMid && Ask > BandLow + 100 * Point){
               return OP_SELL;
               }
           }
        }

     }



   return -1;


  }
//+------------------------------------------------------------------+
//| Place Order                                                      |
//+------------------------------------------------------------------+
void PlaceOrder(OrderInfo &orderInfo)
  {
   int total=CountOrderByMagicNumber(orderInfo.magic);
   double pipStepPrice=orderInfo.lastOrderPrice-(orderInfo.orderType==OP_BUY?1:-1)*orderInfo.pipStep*Point;

   if(total==0 || (orderInfo.orderType==OP_BUY && GetOpenPrice(orderInfo.orderType)<pipStepPrice) || (orderInfo.orderType==OP_SELL && GetOpenPrice(orderInfo.orderType)>pipStepPrice))
     {

      string commentOrder=(orderInfo.orderType==OP_BUY?"Buy":"Sell")+" : "+IntegerToString(total);

      int result=OrderSend(Symbol(),orderInfo.orderType,orderInfo.lots,GetOpenPrice(orderInfo.orderType),slippage,0,0,commentOrder,orderInfo.magic);

      int error=GetLastError();
      if(error!=ERR_NO_ERROR)
        {

         if(error==ERR_NOT_ENOUGH_MONEY)
           {
            orderInfo.tradingAllowed=false;
            ResetLastError();
            return;

           }

        }
      else
        {
         if(total>TotalOrderPipStepUp)
            orderInfo.pipStep+=InitialPipStepUp;
         GetLastOrder(orderInfo);
         orderInfo.takeProfitLevel=CalculateTakeProfit(ProfitPercent,orderInfo);
         ModifyTakeProfit(orderInfo.takeProfitLevel-(orderInfo.orderType==OP_BUY?1:-1)*orderInfo.cumulativeTakeProfitReduce,orderInfo);
         if(total==0)
            orderInfo.firstOrderTime=TimeCurrent();
        }
     }
   else
     {
      if(TimeHour(TimeCurrent()-orderInfo.firstOrderTime)>MinTakeProfitReduceHour && TimeHour(TimeCurrent()-orderInfo.lastTakeProfitModifiedTime)>0)
        {
         orderInfo.cumulativeTakeProfitReduce+=TakeProfitReduceRate*TakeProfit*Point;
         ModifyTakeProfit(orderInfo.takeProfitLevel-(orderInfo.orderType==OP_BUY?1:-1)*orderInfo.cumulativeTakeProfitReduce,orderInfo);
        }
     }
  }
//+------------------------------------------------------------------+
//| Reset Parameter                                                  |
//+------------------------------------------------------------------+
void ResetParameter(OrderInfo &orderInfo)
  {
   Print("======================== RESET PARAM =======================");
   orderInfo.tradingAllowed=true;
   orderInfo.lots=InitialLots;
   orderInfo.cumulativeTakeProfitReduce=0;
   orderInfo.lotExpo=LotsExponent;
   orderInfo.pipStep=InitialPipStep;


  }
//+------------------------------------------------------------------+
//| Get information of the last order                                |
//+------------------------------------------------------------------+
void GetLastOrder(OrderInfo &orderInfo)
  {
   int total=OrdersTotal();
   bool res=OrderSelect(total-1,SELECT_BY_POS);
   if(res && OrderMagicNumber()==orderInfo.magic)
     {
      orderInfo.lastOrderTicket=OrderTicket();
      orderInfo.lastOrderPrice=OrderOpenPrice();
      orderInfo.lots=NormalizeDouble(OrderLots()*orderInfo.lotExpo,2);
      if(orderInfo.lots==OrderLots())
         orderInfo.lots+=0.01;
     }
  }
//+------------------------------------------------------------------+
//| Calculate Take Profit                                            |
//+------------------------------------------------------------------+
double CalculateTakeProfit(double ProfitPerc,OrderInfo &orderInfo)
  {
   double TP;
   double minTP;
   double totalLots=0;
   double totalLotsPrice=0;
   double price=GetOpenPrice(orderInfo.orderType);
   int total=OrdersTotal();

   for(int pos=0;pos<total;pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(res && OrderMagicNumber()==orderInfo.magic)
        {
         totalLots+=OrderLots();
         totalLotsPrice+=OrderOpenPrice()*OrderLots();
        }
     }

   if(orderInfo.orderType==OP_BUY)
     {
      TP=(ProfitPerc*totalLots+totalLotsPrice)/totalLots;
      Print("TP BUY : " +TP);
      minTP=price+TakeProfit*Point;
      if(TP<minTP)
         TP=minTP;
        }else{
      TP=(-ProfitPerc*totalLots+totalLotsPrice)/totalLots;
      Print("TP SELL : " +TP);
      minTP=price-TakeProfit*Point;
      if(TP>minTP)
         TP=minTP;
     }

   return TP;
  }
//+------------------------------------------------------------------+
//| Modify Take Profit                                               |
//+------------------------------------------------------------------+
void ModifyTakeProfit(double TP,OrderInfo &orderInfo)
  {
   int total=OrdersTotal();
   double price=GetClosePrice(orderInfo.orderType);

   for(int pos=0;pos<total;pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS);
      if(res && OrderMagicNumber()==orderInfo.magic)
        {
         if(MathAbs(OrderTakeProfit()-TP)>Point)
           {
            res=OrderModify(OrderTicket(),OrderOpenPrice(),0,TP,0);
            int error=GetLastError();
            if(!res && error!=ERR_NO_RESULT)
               res=OrderClose(OrderTicket(),OrderLots(),price,slippage);
           }
        }
     }
   orderInfo.lastOrderTPPrice=TP;
   orderInfo.lastTakeProfitModifiedTime=TimeCurrent();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyStopLoss(double SL,OrderInfo &orderInfo)
  {
   int total=OrdersTotal();
   double price=GetClosePrice(orderInfo.orderType);

   for(int pos=0;pos<total;pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS);
      if(res && OrderMagicNumber()==orderInfo.magic)
        {
         OrderModify(OrderTicket(),OrderOpenPrice(),SL,orderInfo.lastOrderTPPrice,0);

        }
     }

  }
//+------------------------------------------------------------------+
//| Checking Cut Loss                                                |
//+------------------------------------------------------------------+
void TrackingOrderCutLoss(OrderInfo &orderInfo)
  {

   int UltiOrderCount=CountOrderByMagicNumber(sellOrderInfo.ultiMagicNumber)+CountOrderByMagicNumber(buyOrderInfo.ultiMagicNumber);
   if((orderInfo.orderType==OP_BUY && orderInfo.lastOrderPrice-lastOrderSL*Point>GetOpenPrice(orderInfo.orderType)) || (orderInfo.orderType==OP_SELL && orderInfo.lastOrderPrice+lastOrderSL*Point<GetOpenPrice(orderInfo.orderType)))
     {

      if(AllowUltiOrder)
        {

         double UltiLots=GetTotalLots(orderInfo)/2;
         if(UltiLots>180)
            UltiLots=180;

         double StopLossLevelUltiOrder=GetOpenPrice(orderInfo.orderType)+(orderInfo.orderType==OP_BUY?1:-1)*StopLossUltiOrder*Point;
         int UltiOrderType=(orderInfo.orderType==OP_BUY?OP_SELL:OP_BUY);
         if(UltiOrderCount==0)
           {
            int tmpTicket;
            tmpTicket=OrderSend(Symbol(),UltiOrderType,UltiLots,GetOpenPrice(UltiOrderType),slippage,0,0,NULL,orderInfo.ultiMagicNumber);
            int error=GetLastError();

            if(error!=ERR_NO_ERROR)
              {
               Print("Error UltiOrder Send : ",error);
              }
            else
              {
               orderInfo.tradingAllowed=false;
               stopLossCounter++;
               orderInfo.ultiOrderTicket=tmpTicket;
               CloseAll(orderInfo.magic);
               Print("UltiOrder Send Success : ",UltiLots);
               orderInfo.ultiOrderCounter++;
               bool res=OrderSelect(orderInfo.ultiOrderTicket,SELECT_BY_TICKET);
               if(res)
                 {

                  res=OrderModify(orderInfo.ultiOrderTicket,OrderOpenPrice(),StopLossLevelUltiOrder,0,0);
                  if(res)
                    {
                     Print("Modify UltiOrder ",UltiOrderType," Stop Loss On Start : ",StopLossLevelUltiOrder);
                     orderInfo.takeProfitLevelUltiOrder=GetOpenPrice(orderInfo.orderType)-(orderInfo.orderType==OP_BUY?1:-1)*TakeProfitUltiOrder*Point;

                       }else{
                     Print("Error Modifying UltiOrder Stop Loss On Start");
                    }

                 }
              }
           }
        }
      else
        {
         Print("Recover : CLose Onlys ",AllowUltiOrder);
         CloseAll(orderInfo.magic);
         Sleep(144000);
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Close All                                                        |
//+------------------------------------------------------------------+
void CloseAll(int magic)
  {
   for(int pos=0;pos<OrdersTotal();pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS);
      if(!res)
        {
         int error=GetLastError();
         Alert("Error Selecting : ",error," Index : ",pos," Total : ",OrdersTotal());
         continue;
        }
      else if(OrderMagicNumber()==magic)
        {
         double closePrice=GetClosePrice(OrderType());
         res=OrderClose(OrderTicket(),OrderLots(),closePrice,slippage);
         if(!res)
           {
            int error=GetLastError();
            Alert("Error Closing : ",error);
           }
         else
            pos--;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Get Open Price                                                   |
//+------------------------------------------------------------------+
double GetOpenPrice(int orderType)
  {
   if(orderType==OP_BUY)
      return Ask;
   else if(orderType==OP_SELL)
      return Bid;
   else
      return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Get Close Price                                                  |
//+------------------------------------------------------------------+
double GetClosePrice(int orderType)
  {
   if(orderType==OP_BUY)
      return Bid;
   else if(orderType==OP_SELL)
      return Ask;
   else
      return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Get Total Lots                                                   |
//+------------------------------------------------------------------+
double GetTotalLots(OrderInfo &orderInfo)
  {
   double totalLots=0;
   int total=OrdersTotal();

   for(int pos=0;pos<total;pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS);
      if(res && OrderMagicNumber()==orderInfo.magic)
        {
         totalLots+=OrderLots();
        }
     }
   return NormalizeDouble(totalLots,2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Count Order By Magic Number                                      |
//+------------------------------------------------------------------+
int CountOrderByMagicNumber(int magic)
  {
   int total=OrdersTotal();
   int count= 0;
   for(int pos=0;pos<total;pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS);
      if(res && OrderMagicNumber()==magic)
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Summary Order Profit                                            |
//+------------------------------------------------------------------+
double SummaryOrderProfit(int magic)
  {
   double summary=0;
   int total=OrdersTotal();

   for(int pos=0;pos<total;pos++)
     {
      bool res=OrderSelect(pos,SELECT_BY_POS);
      if(res && OrderMagicNumber()==magic)
         summary+=OrderProfit();
     }
   return summary;


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NewsBehaviour(OrderInfo &orderInfo)
  {

   if(nextNewsTime>TimeCurrent())
     {

      int nextNewsDay=TimeDay(nextNewsTime);
      int nextNewsHour=TimeHour(nextNewsTime);
      int nextNewsMinute=TimeMinute(nextNewsTime);

      int currentDay=TimeDay(TimeCurrent());
      int currentHour=TimeHour(TimeCurrent());
      int currentMinute=TimeMinute(TimeCurrent());

      impactMinute=nextNewsMinute-currentMinute;
      impactHour= nextNewsHour-currentHour;
      impactDay = nextNewsDay-currentDay;

      if(impactDay<0)
        {
         //Print(Month());
         switch(Month())
           {
            case 1:
            case 3:
            case 5:
            case 7:
            case 8:
            case 10:
            case 12:
               impactDay=31+impactDay;
               break;
            case 4:
            case 6:
            case 9:
            case 11:
               impactDay=30+impactDay;
               break;
            case 2:

               if(Year()/100==0 || Year()%4!=0)
               impactDay=28+impactDay;
               else
                  impactDay=29+impactDay;

               break;
           }
        }

      if(impactMinute<0)
        {
         float minuteFraction=MathCeil(MathAbs(impactMinute)/60);
         impactMinute=60+impactMinute;
         impactHour=impactHour-minuteFraction;
        }

      if(impactHour<0)
        {
         float hourFraction=MathCeil(MathAbs(impactHour)/24);
         impactHour= 24+impactHour;
         impactDay = impactDay-hourFraction;
        }

      if(impactDay<1)
        {
         //TrackingOrderOnNewsImpact(orderInfo);
        }

      ObjectCreate("nextNewImpact",OBJ_LABEL,0,0,0);
      ObjectSetText("nextNewImpact","Impact In : "+MathRound(impactDay)+" Days "+MathRound(impactHour)+" Hour "+MathRound(impactMinute)+" Minute ",12,"Courier New",Red);
      ObjectSet("nextNewImpact",OBJPROP_CORNER,1);
      ObjectSet("nextNewImpact",OBJPROP_XDISTANCE,0);
      ObjectSet("nextNewImpact",OBJPROP_YDISTANCE,90);

     }
   else
     {
      ObjectCreate("nextNewImpact",OBJ_LABEL,0,0,0);
      ObjectSetText("nextNewImpact","Impact In : On CoolDown  "+(nextNewsTime+OneHour)+"   Curr : "+TimeCurrent(),12,"Courier New",Red);
      ObjectSet("nextNewImpact",OBJPROP_CORNER,1);
      ObjectSet("nextNewImpact",OBJPROP_XDISTANCE,0);
      ObjectSet("nextNewImpact",OBJPROP_YDISTANCE,90);

      if(!emptyNews && TimeCurrent()>=(nextNewsTime+OneHour*4) && !isQuery)
        {
         isQuery=true;
         nextNewsTime=NULL;
         nextNewsIssue="";
         nextNewsCountry="";
         buyOrderInfo.tradingAllowed=true;
         sellOrderInfo.tradingAllowed=true;
         //GrapNew();
        }

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrackingOrderOnNewsImpact(OrderInfo &orderInfo)
  {

   float newsHour=impactHour;
   float newsMinute=impactMinute;
   int totalOrder=CountOrderByMagicNumber(orderInfo.magic);
   int totalOrderUlti=CountOrderByMagicNumber(orderInfo.ultiMagicNumber);
   if(newsHour<24 && newsHour>12)
     {

      if(totalOrder==0 && totalOrderUlti==0)
        {
         orderInfo.tradingAllowed=false;
           }else if(totalOrder<7){
         orderInfo.tradingAllowed=false;
         CloseAll(orderInfo.magic);
        }
     }
   else if(newsHour<10 && newsHour>1)
     {

      double orderProfit=SummaryOrderProfit(orderInfo.magic);
      if(orderProfit>0 && totalOrderUlti==0)
        {

         orderInfo.tradingAllowed=false;
         CloseAll(orderInfo.magic);

           }else if(totalOrder>RiskOrderTotal){

         double ninetyPercentBalance=AccountBalance()-AccountBalance()*0.1;
         if(newsHour<5)
            ninetyPercentBalance=AccountBalance()-AccountBalance()*0.15;
         if(AccountEquity()>ninetyPercentBalance)
           {
            orderInfo.tradingAllowed=false;
            CloseAll(orderInfo.magic);
           }

        }

     }
   else if(newsHour<1 && newsMinute>0)
     {

      orderInfo.tradingAllowed=false;
      CloseAll(orderInfo.magic);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GrapNew()
  {

   int id;
   string onTime;
   string issue;
   string country;

   Query="SELECT * FROM `news` WHERE ontime >= '"+TimeCurrent()+"' AND monetary = '"+initialNews+"' ORDER BY ontime ASC  limit 1 ";

   Cursor=MySqlCursorOpen(DB,Query);

   if(Cursor>=0)
     {
      Rows=MySqlCursorRows(Cursor);
      for(i=0; i<Rows; i++)
         if(MySqlCursorFetchRow(Cursor))
           {
            id=MySqlGetFieldAsInt(Cursor,0); // id
            onTime=MySqlGetFieldAsString(Cursor,1); // code
            issue=MySqlGetFieldAsString(Cursor,2); // code
            country=MySqlGetFieldAsString(Cursor,3); // code
            StringReplace(onTime,"-","/");
            nextNewsTime=StrToTime(onTime);
            nextNewsIssue=issue;
            nextNewsCountry=country;
           }

     }
   else
     {
      //---

      Print("Cursor opening CheckUserExist. Error: ",MySqlErrorDescription);
     }
   isQuery=false;
   MySqlCursorClose(Cursor);

//return false;

  }
//+------------------------------------------------------------------+
//| Draw Stat                                                        |
//+------------------------------------------------------------------+
void DrawStat()
  {
   ObjectCreate("balanceText",OBJ_LABEL,0,0,0);
   ObjectSetText("balanceText","Balance: "+DoubleToStr(AccountBalance(),2),11,"Courier New",Yellow);
   ObjectSet("balanceText",OBJPROP_CORNER,0);
   ObjectSet("balanceText",OBJPROP_XDISTANCE,10);
   ObjectSet("balanceText",OBJPROP_YDISTANCE,20);

   ObjectCreate("equityText",OBJ_LABEL,0,0,0);
   ObjectSetText("equityText","Equity: "+DoubleToStr(AccountEquity(),2),11,"Courier New",Yellow);
   ObjectSet("equityText",OBJPROP_CORNER,0);
   ObjectSet("equityText",OBJPROP_XDISTANCE,10);
   ObjectSet("equityText",OBJPROP_YDISTANCE,40);

   ObjectCreate("stopLossText",OBJ_LABEL,0,0,0);
   ObjectSetText("stopLossText","Stop Loss: "+IntegerToString(stopLossCounter,2),11,"Courier New",Yellow);
   ObjectSet("stopLossText",OBJPROP_CORNER,0);
   ObjectSet("stopLossText",OBJPROP_XDISTANCE,10);
   ObjectSet("stopLossText",OBJPROP_YDISTANCE,60);

   ObjectCreate("countBuyText",OBJ_LABEL,0,0,0);
   ObjectSetText("countBuyText","Buy Order Total: "+CountOrderByMagicNumber(buyOrderInfo.magic),11,"Courier New",Yellow);
   ObjectSet("countBuyText",OBJPROP_CORNER,0);
   ObjectSet("countBuyText",OBJPROP_XDISTANCE,10);
   ObjectSet("countBuyText",OBJPROP_YDISTANCE,80);

   ObjectCreate("countSellText",OBJ_LABEL,0,0,0);
   ObjectSetText("countSellText","Sell Order Total: "+CountOrderByMagicNumber(sellOrderInfo.magic),11,"Courier New",Yellow);
   ObjectSet("countSellText",OBJPROP_CORNER,0);
   ObjectSet("countSellText",OBJPROP_XDISTANCE,10);
   ObjectSet("countSellText",OBJPROP_YDISTANCE,100);

   ObjectCreate("countSellText1",OBJ_LABEL,0,0,0);
   ObjectSetText("countSellText1","Max Order Total: "+StopLossTotal,11,"Courier New",Yellow);
   ObjectSet("countSellText1",OBJPROP_CORNER,0);
   ObjectSet("countSellText1",OBJPROP_XDISTANCE,10);
   ObjectSet("countSellText1",OBJPROP_YDISTANCE,120);

   ObjectCreate("expoText",OBJ_LABEL,0,0,0);
   ObjectSetText("expoText","Buy Allowed : "+buyOrderInfo.tradingAllowed,11,"Courier New",Yellow);
   ObjectSet("expoText",OBJPROP_CORNER,0);
   ObjectSet("expoText",OBJPROP_XDISTANCE,10);
   ObjectSet("expoText",OBJPROP_YDISTANCE,140);

   ObjectCreate("expoText1",OBJ_LABEL,0,0,0);
   ObjectSetText("expoText1","Sell Allowed : "+sellOrderInfo.tradingAllowed,11,"Courier New",Yellow);
   ObjectSet("expoText1",OBJPROP_CORNER,0);
   ObjectSet("expoText1",OBJPROP_XDISTANCE,10);
   ObjectSet("expoText1",OBJPROP_YDISTANCE,160);

   ObjectCreate("pipStepText",OBJ_LABEL,0,0,0);
   ObjectSetText("pipStepText","Pip Step Buy : "+buyOrderInfo.pipStep,11,"Courier New",Yellow);
   ObjectSet("pipStepText",OBJPROP_CORNER,0);
   ObjectSet("pipStepText",OBJPROP_XDISTANCE,10);
   ObjectSet("pipStepText",OBJPROP_YDISTANCE,180);

   ObjectCreate("pipStepText1",OBJ_LABEL,0,0,0);
   ObjectSetText("pipStepText1","Pip Step Sell : "+sellOrderInfo.pipStep,11,"Courier New",Yellow);
   ObjectSet("pipStepText1",OBJPROP_CORNER,0);
   ObjectSet("pipStepText1",OBJPROP_XDISTANCE,10);
   ObjectSet("pipStepText1",OBJPROP_YDISTANCE,200);

   ObjectCreate("freemarginText",OBJ_LABEL,0,0,0);
   ObjectSetText("freemarginText","Free Margin : "+DoubleToStr(AccountFreeMargin(),2),11,"Courier New",Yellow);
   ObjectSet("freemarginText",OBJPROP_CORNER,0);
   ObjectSet("freemarginText",OBJPROP_XDISTANCE,10);
   ObjectSet("freemarginText",OBJPROP_YDISTANCE,220);

   ObjectCreate("totallotText",OBJ_LABEL,0,0,0);
   ObjectSetText("totallotText","Buy Lots : "+DoubleToStr(GetTotalLots(buyOrderInfo),2),11,"Courier New",Yellow);
   ObjectSet("totallotText",OBJPROP_CORNER,0);
   ObjectSet("totallotText",OBJPROP_XDISTANCE,10);
   ObjectSet("totallotText",OBJPROP_YDISTANCE,240);

   ObjectCreate("totallot1Text",OBJ_LABEL,0,0,0);
   ObjectSetText("totallot1Text","Sell Lots : "+DoubleToStr(GetTotalLots(sellOrderInfo),2),11,"Courier New",Yellow);
   ObjectSet("totallot1Text",OBJPROP_CORNER,0);
   ObjectSet("totallo1tText",OBJPROP_XDISTANCE,10);
   ObjectSet("totallot1Text",OBJPROP_YDISTANCE,260);

   ObjectCreate("botStatusText",OBJ_LABEL,0,0,0);
   ObjectSetText("botStatusText","EA Status : "+eaStatus,11,"Courier New",Yellow);
   ObjectSet("botStatusText",OBJPROP_CORNER,0);
   ObjectSet("botStatusText",OBJPROP_XDISTANCE,10);
   ObjectSet("botStatusText",OBJPROP_YDISTANCE,280);

   ObjectCreate("nextNew",OBJ_LABEL,0,0,0);
   ObjectSetText("nextNew","----- Next News -----",12,"Courier New",Red);
   ObjectSet("nextNew",OBJPROP_CORNER,1);
   ObjectSet("nextNew",OBJPROP_XDISTANCE,10);
   ObjectSet("nextNew",OBJPROP_YDISTANCE,10);

   ObjectCreate("nextNewTime",OBJ_LABEL,0,0,0);
   ObjectSetText("nextNewTime","Date : "+nextNewsTime,12,"Courier New",Red);
   ObjectSet("nextNewTime",OBJPROP_CORNER,1);
   ObjectSet("nextNewTime",OBJPROP_XDISTANCE,10);
   ObjectSet("nextNewTime",OBJPROP_YDISTANCE,30);

   ObjectCreate("nextNewIssue",OBJ_LABEL,0,0,0);
   ObjectSetText("nextNewIssue","Issue : "+nextNewsIssue,12,"Courier New",Red);
   ObjectSet("nextNewIssue",OBJPROP_CORNER,1);
   ObjectSet("nextNewIssue",OBJPROP_XDISTANCE,10);
   ObjectSet("nextNewIssue",OBJPROP_YDISTANCE,50);

   ObjectCreate("nextNewCountry",OBJ_LABEL,0,0,0);
   ObjectSetText("nextNewCountry","Country : "+nextNewsCountry,12,"Courier New",Red);
   ObjectSet("nextNewCountry",OBJPROP_CORNER,1);
   ObjectSet("nextNewCountry",OBJPROP_XDISTANCE,10);
   ObjectSet("nextNewCountry",OBJPROP_YDISTANCE,70);

   ObjectCreate("CurrentTimeText",OBJ_LABEL,0,0,0);
   ObjectSetText("CurrentTimeText","Current Time : "+TimeCurrent(),12,"Courier New",Red);
   ObjectSet("CurrentTimeText",OBJPROP_CORNER,3);
   ObjectSet("CurrentTimeText",OBJPROP_XDISTANCE,10);
   ObjectSet("CurrentTimeText",OBJPROP_YDISTANCE,10);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {

   if(sparam=="MySQLConnectButton")
     {
      MQLConnectSQL();
      Print("Connent");
     }

   if(sparam=="CloseButton")
     {

      MQLDisconnectSQL();
      if(DB==-1)
         Print("CloseButton11 "+DB);
     }
  }
//+------------------------------------------------------------------+

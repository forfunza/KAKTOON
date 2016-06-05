//+------------------------------------------------------------------+
//|                                                        TFXHF.mq4 |
//|                              Copyright 2016, ThaiforexSchool.com |
//|                                   http://www.thaiforexschool.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, ThaiforexSchool.com"
#property link      "http://www.thaiforexschool.com"
#property version   "1.00"
#property strict

#include <MQLMySQL.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

enum stategy
  {
   M=0,     // Manual
   P=1,     // Retracment
   J=2,     // Japan Breakout
  };
//--- input parameters
input stategy Stategy=M;
extern double RL=35;
extern int TakeProfit=100;
extern int PPO=0;
extern int MaxRecovery=5;
extern double InitialLot=0.1;
extern int PreferedSpread=5;
extern bool SafeMode=false;
extern int ModifyLastProfit=600;

extern string Japan_Breakout=" ---------- Japan Breakout Parameter ---------------";

extern int Index=10;
//extern int Start_Trade=3;
//extern int End_Trade=5;

int magic=23456;
int TPR1;
int TPR2;
double lots[11];
int SP;

bool lastCheck=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


int slippage=10;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct RecoveryProperties
  {
   double            lot;
   double            entryPrice;
   double            recoveryPrice;
   double            nextType;
   double            orderPrice;
   double            stopLoss;
   double            takeProfit;
   bool              getProperties;
  };

bool OnRecovery=false;

bool debug=true;

RecoveryProperties _prop;

int MySQLReconnectAddTime=3*3600;
int OneHour=1*3600;
string Query;
int    Cursor,Rows;
int DB; // database identifier
string eaStatus="EA not Authorise. Please Contact http://www.thaiforexschool.com/";
int activeOrder= 1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   MQLConnectSQL();
   bool userResponse=CheckUserExist(AccountNumber());
   if(!userResponse)
     {
      Alert("Account number is invalid. EA is removed!");
      ExpertRemove();
      return(INIT_FAILED);
     }
//---
   SP=PreferedSpread*2;
   TPR1 = TakeProfit - RL;
   TPR2 = TakeProfit + RL + SP;
   TakeProfit=TakeProfit+PreferedSpread;
   _prop.lot=InitialLot;
   _prop.getProperties=false;

   CalculateRecoveryLots();
   RecoveryStats();

   if(CountOrderByMagicNumber()>0 && OnRecovery==false)
     {
      OnRecovery=true;
     }

   if(Stategy==0)
     {
      ObjectCreate(0,"ManualBuyBtn",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_XDISTANCE,130);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_YDISTANCE,30);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_XSIZE,100);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_YSIZE,40);

      ObjectSetString(0,"ManualBuyBtn",OBJPROP_TEXT,"BUY ");

      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_COLOR,White);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_BGCOLOR,Red);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_BORDER_COLOR,Red);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_STATE,false);
      ObjectSetInteger(0,"ManualBuyBtn",OBJPROP_FONTSIZE,12);

      ObjectCreate(0,"ManualSellBtn",OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_XDISTANCE,130);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_YDISTANCE,90);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_XSIZE,100);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_YSIZE,40);

      ObjectSetString(0,"ManualSellBtn",OBJPROP_TEXT,"Sell ");

      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_COLOR,White);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_BGCOLOR,Red);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_BORDER_COLOR,Red);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_STATE,false);
      ObjectSetInteger(0,"ManualSellBtn",OBJPROP_FONTSIZE,12);
     }

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   MQLDisconnectSQL();

  }
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
      for(int i=0; i<Rows; i++)
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int total=CountOrderByMagicNumber();
//
   if(Stategy==0)
     {

      if(CountNormalOrder()>=1)
        {

         RecoveryProcess(total);

        }

      RecoveryTracking();
        }else if(Stategy==1){
      if(total==0 && OnRecovery==false)
        {
         double EMA=NormalizeDouble(iMA(NULL,0,50,0,MODE_EMA,PRICE_CLOSE,0),Digits);
         int orderType;
         double pHigh=iHigh(Symbol(),PERIOD_D1,1);
         double pLow=iLow(Symbol(),PERIOD_D1,1);

         if(hasOrderToday()==false && TimeHour(TimeCurrent())>1)
           {
            if(Bid>pHigh)
              {
               Print("High");
               if(Bid>EMA)
                 {
                  orderType=OP_BUY;
                    }else{
                  orderType=OP_SELL;
                 }

               int order_id=OrderSend(Symbol(),orderType,InitialLot,GetOpenPrice(orderType),slippage,0,0,NULL,magic);

               int error=GetLastError();
               if(error==ERR_NO_ERROR)
                 {
                  pHigh=0;
                  pLow =0;
                  activeOrder++;
                  bool res=OrderSelect(order_id,SELECT_BY_TICKET);
                  if(res)
                    {
                     if(OrderType()==OP_SELL)
                       {
                        res=OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()+(TPR2*10)*Point,OrderOpenPrice() -(TakeProfit*6)*Point,0);
                          }else if(OrderType()==OP_BUY){
                        res=OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()-(TPR2*10)*Point,OrderOpenPrice()+(TakeProfit *6)*Point,0);
                       }

                     RecoveryStats();
                    }
                  ResetLastError();
                 }

                 }else if(Ask<pLow){
               Print("Low");
               if(Ask<EMA)
                 {
                  orderType=OP_SELL;
                    }else{
                  orderType=OP_BUY;
                 }

               int order_id=OrderSend(Symbol(),orderType,InitialLot,GetOpenPrice(orderType),slippage,0,0,NULL,magic);

               int error=GetLastError();
               if(error==ERR_NO_ERROR)
                 {
                  pHigh=0;
                  pLow =0;
                  activeOrder++;
                  bool res=OrderSelect(order_id,SELECT_BY_TICKET);
                  if(res)
                    {
                     if(OrderType()==OP_SELL)
                       {
                        res=OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()+(TPR2*10)*Point,OrderOpenPrice() -(TakeProfit*6)*Point,0);
                          }else if(OrderType()==OP_BUY){
                        res=OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()-(TPR2*10)*Point,OrderOpenPrice()+(TakeProfit *6)*Point,0);
                       }

                     RecoveryStats();
                    }
                  ResetLastError();
                 }
              }

           }

           }else{

         RecoveryProcess(total);
        }
      RecoveryTracking();

        }else if(Stategy==2){

      if(total==0 && OnRecovery==false)
        {

         if(TimeHour(TimeCurrent())-1==Index)
           {

            int orderType;
            if(Close[1]>Open[1]+20*Point)
              {
               orderType=OP_BUY;
                 }else if(Close[1]<Open[1]-20*Point){
               orderType=OP_SELL;
              }

            int order_id=OrderSend(Symbol(),orderType,InitialLot,GetOpenPrice(orderType),slippage,0,0,NULL,magic);

            int error=GetLastError();
            if(error==ERR_NO_ERROR)
              {
               activeOrder++;
               bool res=OrderSelect(order_id,SELECT_BY_TICKET);
               if(res)
                 {
                  if(OrderType()==OP_SELL)
                    {
                     res=OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()+(TPR2*10)*Point,OrderOpenPrice() -(TakeProfit*10)*Point,0);
                       }else if(OrderType()==OP_BUY){
                     res=OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()-(TPR2*10)*Point,OrderOpenPrice()+(TakeProfit *10)*Point,0);
                    }

                  RecoveryStats();
                 }
               ResetLastError();
              }
           }
           }else{

         RecoveryProcess(total);
        }
      RecoveryTracking();

     }

//        else if(Stategy==3){
//      double BandLow=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,0),Digits);
//      double BandMid=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_MAIN,0),Digits);
//      double BandHigh=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,0),Digits);
//      double EMA = NormalizeDouble(iMA(NULL,0,51,0,MODE_EMA,PRICE_CLOSE,0),Digits);
//      if(total==0 && OnRecovery==false)
//        {
//         if(TimeHour(TimeCurrent())>Index && TimeDayOfWeek(TimeCurrent()) >=Start_Trade  && TimeDayOfWeek(TimeCurrent()) <=End_Trade)
//           {
//
//            if(Bid>=BandHigh)
//              {
//
//               int order_id=OrderSend(Symbol(),OP_SELL,InitialLot,GetOpenPrice(OP_SELL),slippage,0,0,NULL,magic);
//
//               int error=GetLastError();
//               if(error==ERR_NO_ERROR)
//                 {
//                  activeOrder++;
//                  bool res=OrderSelect(order_id,SELECT_BY_TICKET);
//                  if(res)
//                    {
//
//                     OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()+(TPR2*10)*Point,OrderOpenPrice() -(TakeProfit*10)*Point,0);
//
//                     RecoveryStats();
//
//                    }
//                  ResetLastError();
//                 }
//
//                 }else if(Ask<=BandLow){
//               int order_id=OrderSend(Symbol(),OP_BUY,InitialLot,GetOpenPrice(OP_BUY),slippage,0,0,NULL,magic);
//
//               int error=GetLastError();
//               if(error==ERR_NO_ERROR)
//                 {
//                  activeOrder++;
//                  bool res=OrderSelect(order_id,SELECT_BY_TICKET);
//                  if(res)
//                    {
//
//                     OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()-(TPR2*10)*Point,OrderOpenPrice()+(TakeProfit *10)*Point,0);
//
//                     RecoveryStats();
//
//                    }
//                  ResetLastError();
//                 }
//
//              }
//
//
//           }
//
//           }else{
//
//         RecoveryProcess(total);
//        }
//      RecoveryTracking();
//     }

//     else if(Stategy == 4){
//      
//      double BandMid=NormalizeDouble(iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_MAIN,0),Digits);
//      double EMA = NormalizeDouble(iMA(NULL,0,51,0,MODE_EMA,PRICE_CLOSE,0),Digits);
//      
//      if(total==0 && OnRecovery==false)
//        {
//            if(Ask >= BandMid - 100 * Point && Ask <= BandMid + 100 * Point){
//             
//               if(Ask < EMA){
//                  int order_id=OrderSend(Symbol(),OP_SELL,InitialLot,GetOpenPrice(OP_SELL),slippage,0,0,NULL,magic);
//
//               int error=GetLastError();
//               if(error==ERR_NO_ERROR)
//                 {
//                  activeOrder++;
//                  bool res=OrderSelect(order_id,SELECT_BY_TICKET);
//                  if(res)
//                    {
//
//                     OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()+(TPR2*10)*Point,OrderOpenPrice() -(TakeProfit*6)*Point,0);
//
//                     RecoveryStats();
//
//                    }
//                  ResetLastError();
//                 }
//               }else{
//                  int order_id=OrderSend(Symbol(),OP_BUY,InitialLot,GetOpenPrice(OP_BUY),slippage,0,0,NULL,magic);
//
//               int error=GetLastError();
//               if(error==ERR_NO_ERROR)
//                 {
//                  activeOrder++;
//                  bool res=OrderSelect(order_id,SELECT_BY_TICKET);
//                  if(res)
//                    {
//
//                     OrderModify(order_id,OrderOpenPrice(),OrderOpenPrice()-(TPR2*10)*Point,OrderOpenPrice()+(TakeProfit *6)*Point,0);
//
//                     RecoveryStats();
//
//                    }
//                  ResetLastError();
//                 }
//               }
//            }
//        }else{
//         RecoveryProcess(total);
//        }
//         RecoveryTracking();
//     }

   if(SafeMode && CountNormalOrder()==MaxRecovery)
     {
         if(CalculateOrderProfit() > ModifyLastProfit){
            CloseThisSymbolAll();
         }
     }

   DrawStat();
//if(TimeCurrent()>(MySqlLastConnect+MySQLReconnectAddTime) || DB==-1)
//  {
//   MQLDisconnectSQL();
//   MQLConnectSQL();
//  }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RecoveryProcess(int totalOrder)
  {
   if(CountOrderByMagicNumber()<MaxRecovery)
     {
      if(totalOrder+1<=MaxRecovery)
        {

         if(_prop.getProperties==false && CountPendingOrder()==0)
           {
            //EvaluateRecoveryProperties();
            GetRecoveryProperties(totalOrder);
           }

         if(CountPendingOrderByType()==0 && _prop.getProperties==true)
           {

            PlaceOrder();
            if(Stategy==0 || Stategy==1 || Stategy==4)
              {
               if(CountNormalOrder()>1)
                 {
                  setSTManualOrder();
                 }
              }
            RecoveryStats();

           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setSTManualOrder()
  {

   for(int pos=0;pos<OrdersTotal();pos++)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
        {
         if(OrderType()==OP_SELL)
           {
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+(TPR2*10)*Point,OrderOpenPrice() -(TakeProfit*10)*Point,0);
              }else if(OrderType()==OP_BUY){
            OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-(TPR2*10)*Point,OrderOpenPrice()+(TakeProfit *10)*Point,0);
           }

         break;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasOrderToday()
  {

   for(int i=0; i<OrdersHistoryTotal(); i++)
     {
      if(!(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
         if(TimeDay(OrderCloseTime())==TimeDay(TimeCurrent()))
            return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RecoveryTracking()
  {

   if(CountPendingOrder()==0 && CountNormalOrder()==MaxRecovery && lastCheck==false)
     {
      RecoveryStats();
      lastCheck=true;
     }

   if(CountOrderByMagicNumber()+1<activeOrder && OnRecovery)
     {

      if(CountOrderByMagicNumber()>0)
        {
         CloseThisSymbolAll();
        }

      if(CountOrderByMagicNumber()==0)
        {
         activeOrder=1;
         RecoveryStats();
         OnRecovery=false;
         _prop.getProperties=false;
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseThisSymbolAll()
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);

      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
        {
         if(OrderType() ==  OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, slippage, Blue);
         if(OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, slippage, Red);
         if(OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) OrderDelete(OrderTicket(),Red);
        }
      Sleep(100);

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOpenPrice(int orderType)
  {
   if(orderType==OP_BUY || orderType==OP_BUYSTOP)
      return Ask;
   else if(orderType==OP_SELL || orderType==OP_SELLSTOP)
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
   if(orderType==OP_BUY || orderType==OP_BUYSTOP)
      return Bid;
   else if(orderType==OP_SELL || orderType==OP_SELLSTOP)
      return Ask;
   else
      return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PlaceOrder()
  {

   int last_id=OrderSend(Symbol(),_prop.nextType,_prop.lot,_prop.orderPrice,slippage,0,0,NULL,magic);
   int error=GetLastError();
   if(error==ERR_NO_ERROR)
     {
      bool res=OrderSelect(last_id,SELECT_BY_TICKET);
      if(res)
        {
         bool mdy=OrderModify(last_id,OrderOpenPrice(),_prop.stopLoss,_prop.takeProfit,0);
         if(mdy)
           {
            OnRecovery=true;
            activeOrder++;
            _prop.getProperties=false;
           }

        }

        }else{
      OrderPrint();
      Print(error);
      ResetLastError();
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetRecoveryProperties(int totalOrder)
  {

   for(int pos=OrdersTotal()-1; pos>=0; pos--)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
        {
         if(totalOrder==1)
           {
            _prop.entryPrice=OrderOpenPrice();
           }

         if(OrderType()==OP_BUY)
           {
            _prop.recoveryPrice=OrderOpenPrice()-(RL*10)*Point;
            _prop.nextType=OP_SELLSTOP;
              }else if(OrderType()==OP_SELL){
            _prop.recoveryPrice=OrderOpenPrice()+(RL*10)*Point;
            _prop.nextType=OP_BUYSTOP;
           }

         break;
        }
     }

   _prop.lot=lots[totalOrder+1];

   if(totalOrder%2==0)
     {
      _prop.orderPrice=_prop.entryPrice;

        }else{
      _prop.orderPrice=_prop.recoveryPrice;

     }

   if(_prop.nextType==OP_BUYSTOP)
     {
      _prop.takeProfit=_prop.orderPrice+(TakeProfit*10)*Point;
      _prop.stopLoss=_prop.orderPrice-(TPR2*10)*Point;
        }else if(_prop.nextType==OP_SELLSTOP){
      _prop.takeProfit=_prop.orderPrice -(TakeProfit*10)*Point;
      _prop.stopLoss=_prop.orderPrice+(TPR2*10)*Point;
     }

   _prop.getProperties=true;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateRecoveryLots()
  {
   lots[1]=InitialLot;

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
      Print(lots[i]);
     }

  }
//+------------------------------------------------------------------+

int CountOrderByMagicNumber()
  {
   int total=OrdersTotal();
   int count= 0;
   for(int pos=0;pos<total;pos++)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic)
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountPendingOrderByType()
  {
   int total=OrdersTotal();
   int count= 0;
   for(int pos=0;pos<total;pos++)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && OrderType()==_prop.nextType)
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountPendingOrder()
  {
   int total=OrdersTotal();
   int count= 0;
   for(int pos=0;pos<total;pos++)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP))
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountNormalOrder()
  {
   int total=OrdersTotal();
   int count= 0;
   for(int pos=0;pos<total;pos++)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && (OrderType()==OP_BUY || OrderType()==OP_SELL))
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateOrderProfit()
  {
   int total=OrdersTotal();
   double summary=0;
   for(int pos=0;pos<total;pos++)
     {
      OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic && (OrderType()==OP_BUY || OrderType()==OP_SELL))
         summary+=OrderProfit();
     }
   return summary;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void RecoveryStats()
  {
   ObjectCreate("recoveryStatusText",OBJ_LABEL,0,0,0);
   ObjectSetText("recoveryStatusText","----- Recovery Order State -----",11,"Courier New",Yellow);
   ObjectSet("recoveryStatusText",OBJPROP_CORNER,0);
   ObjectSet("recoveryStatusText",OBJPROP_XDISTANCE,10);
   ObjectSet("recoveryStatusText",OBJPROP_YDISTANCE,120);

   ObjectCreate("recoveryTHText",OBJ_LABEL,0,0,0);
   ObjectSetText("recoveryTHText","No.       Lot.       Status."+"    Maximize DD      Profit",11,"Courier New",Yellow);
   ObjectSet("recoveryTHText",OBJPROP_CORNER,0);
   ObjectSet("recoveryTHText",OBJPROP_XDISTANCE,10);
   ObjectSet("recoveryTHText",OBJPROP_YDISTANCE,140);

   int y_dis=160;
   int number=CountOrderByMagicNumber();
   int total=OrdersTotal();
   double sum1;
   double sum2;
   double p1;
   double p2;
   for(int i=1; i<=MaxRecovery; i++)
     {
      p1 = 0;
      p2 = 0;
      string s_text="";
      color text_color;

      if(i<number)
        {
         s_text="A";
         text_color=LightGreen;
           }else if(i==number){
         s_text="P";
         text_color=Orange;
           }else{
         s_text="N";
         text_color=Yellow;
        }

      if(number==MaxRecovery && CountPendingOrder()==0)
        {
         s_text="A";
         text_color=LightGreen;
        }

      double max_loss=0;

      if(i%2==0)
        {

         for(int c=2; c<=i; c+=2)
           {
            max_loss+=lots[c]*RL *10;
           }
           }else{

         for(int c=1; c<=i; c+=2)
           {
            max_loss+=lots[c]*RL*10;
           }
        }

      if(i>1)
        {

         if(i%2==0)
           {

            for(int c=2; c<=i; c+=2)
              {
               p1+=lots[c]*TPR1 *10;
              }

            for(int c=1; c<=i; c+=2)
              {

               p2+=lots[c]*TakeProfit*10;
              }

            sum2=(p1-p2);
              }else{
            for(int c=2; c<=i; c+=2)
              {
               p1+=lots[c]*TPR2 *10;
              }

            for(int c=1; c<=i; c+=2)
              {
               //Print(lots[c]);
               p2+=lots[c]*TakeProfit*10;
              }
            //Print(i + "   " + p1 + "  ----  " + p2);
            sum2=(p2-p1);
           }
           }else{

         sum1=lots[i]*TakeProfit *10;
        }

      ObjectCreate("recoveryStatusText"+i,OBJ_LABEL,0,0,0);
      ObjectSetText("recoveryStatusText"+i,""+(i-1)+"        "+DoubleToStr(MathFloor(lots[i]*100)/100,2)+"          "+s_text+"          "+DoubleToStr(max_loss,2)+"      "+(i==1 ? sum1 : sum2),11,"Courier New",text_color);
      ObjectSet("recoveryStatusText"+i,OBJPROP_CORNER,0);
      ObjectSet("recoveryStatusText"+i,OBJPROP_XDISTANCE,10);
      ObjectSet("recoveryStatusText"+i,OBJPROP_YDISTANCE,y_dis);
      y_dis+=20;
     }

  }
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

   ObjectCreate("marginText",OBJ_LABEL,0,0,0);
   ObjectSetText("marginText","Free Margin: "+DoubleToStr(AccountFreeMargin(),2),11,"Courier New",Yellow);
   ObjectSet("marginText",OBJPROP_CORNER,0);
   ObjectSet("marginText",OBJPROP_XDISTANCE,10);
   ObjectSet("marginText",OBJPROP_YDISTANCE,60);

   ObjectCreate("totalText",OBJ_LABEL,0,0,0);
   ObjectSetText("totalText","Recovery Status: "+OnRecovery,11,"Courier New",Yellow);
   ObjectSet("totalText",OBJPROP_CORNER,0);
   ObjectSet("totalText",OBJPROP_XDISTANCE,10);
   ObjectSet("totalText",OBJPROP_YDISTANCE,80);

   ObjectCreate("spreadText",OBJ_LABEL,0,0,0);
   ObjectSetText("spreadText","Spread: "+DoubleToString(MarketInfo(Symbol(),MODE_SPREAD)),11,"Courier New",Yellow);
   ObjectSet("spreadText",OBJPROP_CORNER,0);
   ObjectSet("spreadText",OBJPROP_XDISTANCE,10);
   ObjectSet("spreadText",OBJPROP_YDISTANCE,100);

//ObjectCreate("orderTotalText",OBJ_LABEL,0,0,0);
//ObjectSetText("orderTotalText","Totol: "+(CountOrderByMagicNumber()+1)+"       "+activeOrder,11,"Courier New",Yellow);
//ObjectSet("orderTotalText",OBJPROP_CORNER,0);
//ObjectSet("orderTotalText",OBJPROP_XDISTANCE,10);
//ObjectSet("orderTotalText",OBJPROP_YDISTANCE,380);

//+------------------------------------------------------------------+
  }
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {

   if(sparam=="ManualBuyBtn")
     {
      if(!OnRecovery)
        {
         int order_id=OrderSend(Symbol(),OP_BUY,InitialLot,GetOpenPrice(OP_BUY),slippage,0,0,NULL,magic);

         int error=GetLastError();
         if(error==ERR_NO_ERROR)
           {
            activeOrder++;
            bool res=OrderSelect(order_id,SELECT_BY_TICKET);
            if(res)
              {

               RecoveryStats();
              }
            ResetLastError();
           }
           }else{

         Alert("You are still in recovery mode you can not place order now.");
        }
     }

   if(sparam=="ManualSellBtn")
     {
      if(!OnRecovery)
        {
         int order_id=OrderSend(Symbol(),OP_SELL,InitialLot,GetOpenPrice(OP_SELL),slippage,0,0,NULL,magic);

         int error=GetLastError();
         if(error==ERR_NO_ERROR)
           {
            activeOrder++;
            bool res=OrderSelect(order_id,SELECT_BY_TICKET);
            if(res)
              {

               RecoveryStats();
              }
            ResetLastError();
           }
           }else{

         Alert("You are still in recovery mode you can not place order now.");
        }
     }
  }
//+------------------------------------------------------------------+

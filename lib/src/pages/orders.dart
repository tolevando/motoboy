import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../controllers/order_controller.dart';
import '../elements/EmptyOrdersWidget.dart';
import '../elements/OrderItemWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';
import 'package:wakelock/wakelock.dart';

class OrdersWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  OrdersWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _OrdersWidgetState createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends StateMVC<OrdersWidget> {
  OrderController _con;

  _OrdersWidgetState() : super(OrderController()) {
    _con = controller;
  }

  @override
  void initState() {
    _con.listenForOrders();
    _con.listenForDisponivel();
    Wakelock.enable();
    executaChecagemNovoPedido();
    
    
    super.initState();
  }

  void executaChecagemNovoPedido(){
    Timer.periodic(new Duration(seconds:10), (timer) {
      _con.checaNovoPedido();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.scaffoldKey,
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.sort, color: Theme.of(context).hintColor),
          onPressed: () => widget.parentScaffoldKey.currentState.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          S.of(context).orders,
          style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3)),
        ),
        actions: <Widget>[
          new ShoppingCartButtonWidget(iconColor: Theme.of(context).hintColor, labelColor: Theme.of(context).accentColor),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _con.refreshOrders,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 10),
          children: <Widget>[
            Container(      
              child: Row(              
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children:[
                    Container(              
                      child: Transform.scale( scale: 1.5,
                                  child: Switch(
                        value: _con.isDisponivel,
                        onChanged: (value){
                          setState(() {
                            _con.isDisponivel=value;
                            _con.alteraForDisponivel(_con.isDisponivel);
                          });
                        },
                        activeTrackColor: Colors.green,
                        activeColor: Colors.green,
                      ),
                    )),  
                    Container(
                      padding: EdgeInsets.fromLTRB(50, 2, 50, 20),
                      child: Text("Receber Novos Pedidos",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                    )            
                  ]
                )
              ],),
            ),       
            _con.orders.isEmpty
                ? EmptyOrdersWidget()
                : ListView.separated(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    primary: false,
                    itemCount: _con.orders.length,
                    itemBuilder: (context, index) {
                      var _order = _con.orders.elementAt(index);
                      return OrderItemWidget(expanded: index == 0 ? true : false, order: _order);
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 20);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

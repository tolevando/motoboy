import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:markets_deliveryboy/src/models/user.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../models/order.dart';
import '../repository/order_repository.dart';

import '../helpers/helper.dart';
import '../repository/user_repository.dart' as userRepo;

import 'package:http/http.dart' as http;
import 'package:global_configuration/global_configuration.dart';
import 'package:just_audio/just_audio.dart';

class OrderController extends ControllerMVC {
  List<Order> orders = <Order>[];
  GlobalKey<ScaffoldState> scaffoldKey;
  bool isDisponivel = false;
  bool possui_novo_pedido = false;
  final player = AudioPlayer();
  OrderController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    inicializaAudio();
  }

  void inicializaAudio() async{
    try {
      var duration = await player.setUrl(GlobalConfiguration().getString('base_url')+'/notification.mp3');
      player.load();
    } catch (e) {
      print(e.toString());
    }
  }

  void checaNovoPedido() async{
    Uri uri = Helper.getUri('api/driver/users/checa_novo_pedido');
    Map<String, dynamic> _queryParams = {};
    User _user = userRepo.currentUser.value;
    if(!orders.isEmpty){
      _queryParams['api_token'] = _user.apiToken;
      String lastId = orders.first.id.toString();
      _queryParams['last_pedido_id'] = lastId;    
      uri = uri.replace(queryParameters: _queryParams);    
      print(uri);
      try {          
        final client = new http.Client();
        await client.send(http.Request('get', uri));
        final response = await client.send(http.Request('get', uri));
        final string = await response.stream.bytesToString();     
        Map<String,dynamic> data = json.decode(string);
        print(data);
        possui_novo_pedido = data['possui_novo_pedido'];                           
        if(possui_novo_pedido){          
          player.load();
          player.play();
          refreshOrders();          
        }
      } catch (e) {
        print(e.toString());
        //return new Stream.value(User.fromJSON({}));
        //return null;
      }
    }    
  }

  void listenForDisponivel() async{
    Uri uri = Helper.getUri('api/driver/users/disponibilidade');
    Map<String, dynamic> _queryParams = {};
    User _user = userRepo.currentUser.value;

    _queryParams['api_token'] = _user.apiToken;
    uri = uri.replace(queryParameters: _queryParams);

    try {
      print(uri);
      final client = new http.Client();
      final response = await client.send(http.Request('get', uri));
      final string = await response.stream.bytesToString();     
      Map<String,dynamic> funcionamento = json.decode(string)['data'];
      setState(() {
        isDisponivel = funcionamento['disponivel'];         
      });
      //Aberprint(funcionamento['aberto']);
      //return string;
    } catch (e) {
      print(e.toString());
      //return new Stream.value(User.fromJSON({}));
      //return null;
    }
  }

  void alteraForDisponivel(bool disponivel) async{
    Uri uri = Helper.getUri('api/driver/users/altera_disponibilidade');
    Map<String, dynamic> _queryParams = {};
    User _user = userRepo.currentUser.value;

    _queryParams['api_token'] = _user.apiToken;
    _queryParams['disponivel'] = disponivel?"1":"0";
    uri = uri.replace(queryParameters: _queryParams);

    try {
      print(uri);
      final client = new http.Client();
      final response = await client.send(http.Request('get', uri));
      final string = await response.stream.bytesToString();     
      Map<String,dynamic> funcionamento = json.decode(string)['data'];
      setState(() {
        isDisponivel = funcionamento['disponivel'];         
      });
      //Aberprint(funcionamento['aberto']);
      //return string;
    } catch (e) {
      print(e.toString());
      //return new Stream.value(User.fromJSON({}));
      //return null;
    }
  }

  void listenForOrders({String message}) async {
    final Stream<Order> stream = await getOrders();
    stream.listen((Order _order) {
      setState(() {
        orders.add(_order);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void listenForOrdersHistory({String message}) async {
    final Stream<Order> stream = await getOrdersHistory();
    stream.listen((Order _order) {
      setState(() {
        orders.add(_order);
      });
    }, onError: (a) {
      print(a);
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    }, onDone: () {
      if (message != null) {
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  Future<void> refreshOrdersHistory() async {
    orders.clear();
    listenForOrdersHistory(message: S.of(context).order_refreshed_successfuly);
  }

  Future<void> refreshOrders() async {
    orders.clear();
    listenForOrders(message: S.of(context).order_refreshed_successfuly);
  }
}

import 'package:flutter/widgets.dart';
import 'package:icloudmusic/const/resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:icloudmusic/Utils/listData.dart';
import 'package:icloudmusic/Utils/HttpUtils.dart';
import 'package:icloudmusic/component/loading.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:icloudmusic/component/nativeWeb.dart';
import 'package:icloudmusic/component/customeRoute.dart';
import 'package:icloudmusic/component/userInfo.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:icloudmusic/Utils/sqlite.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final random = Random();
  final sqlList = SqlListData();
  final sqlLite = SqlLite();
  bool searchChecked = false;
  SwiperController _swiperController;
  List<Map<String,dynamic>> _bannerData;
  int _device;
  String _avatarUrl; // 头像
  String _userName; // 用户名
  int _gender; // 性别
  int _userId;
  String _backgroundUrl; // 背景
  Future getBanners()async{
    if(Platform.isIOS){
      //ios相关代码
      this._device=2;
    }else if(Platform.isAndroid){
      //android相关代码
      this._device=1;
    }else {
      this._device=0;
    }
    // 从服务端获取banner
    Map<String, dynamic> _banner = await HttpUtils.request(
        '/banner',data: {"type":this._device}, method: HttpUtils.GET);
    if (_banner['code'] == 200){
      await sqlList.delForm("banner");
      _banner['banners'].forEach((e)async{
        await sqlList.insertForm("banner", e);
      });
    } else {
      FToash(_banner['message'], "获取banner数据失败", false, context);
    }
    _bannerData = await sqlList.queryForm("banner");
    return _bannerData;
  }
  @override
  void initState() {
    (()async{
      await sqlList.open();
      // 首先从本地拿取banner数据
      _bannerData = await sqlList.queryForm("banner");
      await sqlLite.open();
      var userInfo = await sqlLite.queryUserInfo();
      setState(() {
        _avatarUrl = userInfo[0]['avatarUrl'];
        _userName = userInfo[0]['nickname'];
        _gender = userInfo[0]['gender'];
        _backgroundUrl = userInfo[0]['backgroundUrl'];
        _userId = userInfo[0]['userId'];
      });
    })();
    super.initState();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 左侧显示头像
        leading: GestureDetector(
            onTap: () {
              Navigator.push(context, FadeRoute(
                  (UserInfoScreen(avatarUrl: _avatarUrl,
                      username: _userName,
                      gender: _gender,
                      backgroundUrl: _backgroundUrl,
                      userId: _userId))));
            },
            child: Hero(
                tag: 'USERINFO',
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(_avatarUrl == null ? 0.0 : 10.0),
                  child:  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _avatarUrl == null ? AssetImage(
                        M.UN) : NetworkImage(_avatarUrl),
                  ),
                )
            ),
        ),
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              this.searchChecked = !(this.searchChecked ?? false);
              setState(() {});
            },
            child: Container(
              width: 50,
              alignment: Alignment.centerRight,
              child: FlareActor(
                R.ASSET_MSG_FLR,
                animation: this.searchChecked ? "Notification Loop":"",
                isPaused: this.searchChecked
              ),
            ),
          ),
        ],
        centerTitle: true,
        elevation: 0.0,
        brightness: Brightness.light,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
            color: C.DEF
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
            FutureBuilder(
              future: getBanners(),
              builder: (BuildContext context,snap){
                if(snap.hasData){
                  return Container(
                    height: 150.0,
                    child: Swiper(
                      itemBuilder: (BuildContext context, int index) {
                        return Container(
                          alignment: Alignment.bottomRight,
                          margin: EdgeInsets.only(left:10.0,right: 10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: NetworkImage(_bannerData[index]['imageUrl']),
                                fit: BoxFit.cover,
                              )
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(5.0,2.0,5.0,2.0),
                            decoration: BoxDecoration(
                                color: colorString(_bannerData[index]['titleColor']),
                                borderRadius: BorderRadius.only(bottomRight: Radius.circular(8.0),topLeft: Radius.circular(8.0))
                            ),
                            child: Text(_bannerData[index]['typeTitle'],style: TextStyle(
                                color: Colors.white,
                                fontFamily: F.Regular,
                                fontSize: 12.0
                            ),),
                          ),
                        );
                      },
                      itemCount: _bannerData.length,
                      autoplay: true,
                      controller: _swiperController,
                      autoplayDelay: 5000,
                      onTap: (i){
                        // 如果url不为null，则跳转页面
                        print(_bannerData[i]['url']);
                        if(_bannerData[i]['url']!=null){
//                          print('跳转页面');
                          Navigator.push(context, FadeRoute(
                              (NativeWebView(urls: _bannerData[i]['url']))));
                        }
                      },
                      pagination: SwiperPagination(
                          margin: EdgeInsets.all(0.0),
                        builder: SwiperPagination(
                            margin: EdgeInsets.all(5.0),
                            builder: const DotSwiperPaginationBuilder(
                                size: 6.0, activeSize: 6.0, space: 2.5,
                              activeColor: Colors.red,
                              color: Colors.white70
                            )),
                      ),
                    ),
                  );
                }else{
                  return Container(
                    height: 150.0,
                    margin: EdgeInsets.only(left:10.0,right: 10.0),
                    decoration: BoxDecoration(
                        color: C.ColorRandom,
                        borderRadius: BorderRadius.circular(8.0)
                    ),
                  );
                }
              },
            ),
          Column(
            children: <Widget>[
              Container(
                child: Text("Dark side Breaking Benjamin", style: TextStyle(
                    color: Color.fromRGBO(24, 29, 40, 0.87),
                    fontSize: 20.0,
                    fontFamily: F.Bold
                )),
              ),
              Container(
                child: Text("The new album by the American Alt-rockers",
                    style: TextStyle(
                        color: Color.fromRGBO(24, 29, 40, 0.64),
                        fontSize: 15.0,
                        fontFamily: F.Regular
                    )),
              ),
            ],
            )
        ],
      ),
    );
  }
}
MaterialColor colorString(str){
  switch(str){
    case 'red':
      return Colors.red;
      break;
    case 'blue':
      return Colors.blue;
      break;
    case 'yellow':
      return Colors.yellow;
      break;
    case 'pink':
      return Colors.pink;
      break;
    default:
      return Colors.white;
      break;
  }
}
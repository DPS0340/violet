// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:violet/component/hentai.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/database.dart';
import 'package:violet/database/query.dart';
import 'package:violet/model/article_list_item.dart';
import 'package:violet/pages/bookmark/group/group_article_list_page.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/variables.dart';
import 'package:violet/widgets/article_item/article_list_item_widget.dart';

class TabPanel extends StatefulWidget {
  final int articleId;
  final List<QueryResult> usableTabList;

  TabPanel({
    this.articleId,
    this.usableTabList,
  });

  @override
  _TabPanelState createState() => _TabPanelState();
}

class _TabPanelState extends State<TabPanel> {
  PageController _pageController = PageController(initialPage: 0);

  // static const _kDuration = const Duration(milliseconds: 300);
  // static const _kCurve = Curves.ease;

  static const _kDuration = const Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
          padding: EdgeInsets.only(bottom: Variables.bottomBarHeight),
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                children: [
                  widget.usableTabList != null
                      ? _UsableTabList(
                          articleId: widget.articleId,
                          usableTabList: widget.usableTabList,
                        )
                      : Container(),
                  _ArtistsArticleTabList(
                    articleId: widget.articleId,
                  ),
                ],
              ),
              FutureBuilder(
                future: Future.value(1),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container();
                  return Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Container(
                      color: null,
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: DotsIndicator(
                          controller: _pageController,
                          itemCount: 2,
                          onPageSelected: (int page) {
                            _pageController.animateToPage(
                              page,
                              duration: _kDuration,
                              curve: _kCurve,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsableTabList extends StatefulWidget {
  final int articleId;
  final List<QueryResult> usableTabList;

  const _UsableTabList({this.articleId, this.usableTabList});

  @override
  __UsableTabListState createState() => __UsableTabListState();
}

class __UsableTabListState extends State<_UsableTabList>
    with AutomaticKeepAliveClientMixin<_UsableTabList> {
  @override
  bool get wantKeepAlive => true;

  ScrollController _scrollController = ScrollController();
  Map<int, GlobalKey> itemKeys = Map<int, GlobalKey>();

  @override
  void initState() {
    super.initState();

    if (widget.usableTabList == null) return;

    widget.usableTabList
        .forEach((element) => itemKeys[element.id()] = GlobalKey());

    Future.value(1).then((value) {
      var row = widget.usableTabList
              .indexWhere((element) => element.id() == widget.articleId) ~/
          3;
      if (row == 0) return;
      _scrollController.jumpTo(
        row *
                ((itemKeys[widget.usableTabList.first.id()]
                            .currentContext
                            .findRenderObject() as RenderBox)
                        .size
                        .height +
                    8) -
            100,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var windowWidth = MediaQuery.of(context).size.width;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _scrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3 / 4,
            ),
            delegate: SliverChildListDelegate(
              widget.usableTabList.map(
                (e) {
                  return Padding(
                    key: itemKeys[e.id()],
                    padding: EdgeInsets.zero,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Provider<ArticleListItem>.value(
                        value: ArticleListItem.fromArticleListItem(
                          queryResult: e,
                          addBottomPadding: false,
                          showDetail: false,
                          width: (windowWidth - 4.0) / 3.0,
                          thumbnailTag: Uuid().v4(),
                          selectMode: true,
                          selectCallback: () {
                            Navigator.pop(context, e);
                          },
                        ),
                        child: ArticleListItemVerySimpleWidget(),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistsArticleTabList extends StatefulWidget {
  final int articleId;

  const _ArtistsArticleTabList({this.articleId});

  @override
  __ArtistsArticleTabListState createState() => __ArtistsArticleTabListState();
}

class __ArtistsArticleTabListState extends State<_ArtistsArticleTabList>
    with AutomaticKeepAliveClientMixin<_ArtistsArticleTabList> {
  @override
  bool get wantKeepAlive => true;

  ScrollController _scrollController = ScrollController();
  Map<int, GlobalKey> itemKeys = Map<int, GlobalKey>();
  bool isLoaded = false;
  List<QueryResult> articleList = [];

  @override
  void initState() {
    super.initState();

    Future.value(1).then((value) async {
      var mqrr = await HentaiManager.idSearch(widget.articleId.toString());
      if (mqrr.item1.length == 0) return;

      var mqr = mqrr.item1.first;

      var what = '';
      if (mqr.artists() != null)
        what += (mqr.artists() as String)
            .split('|')
            .where((element) => element != '' && element.toLowerCase() != "n/a")
            .map((element) => 'artist:${element.replaceAll(' ', '_')}')
            .join(" or ");

      if (mqr.groups() != null) {
        if (what != '') what += " or ";
        what += (mqr.groups() as String)
            .split('|')
            .where((element) => element != '' && element.toLowerCase() != "n/a")
            .map((element) => 'group:${element.replaceAll(' ', '_')}')
            .join(" or ");
      }

      if (what == '') {
        setState(() => isLoaded = true);
        return;
      }

      final queryString = HitomiManager.translate2query("($what)" +
          ' ' +
          Settings.includeTags +
          ' ' +
          Settings.excludeTags
              .where((e) => e.trim() != '')
              .map((e) => '-$e')
              .join(' ')
              .trim());
      var queryResult = (await (await DataBaseManager.getInstance())
              .query("$queryString ORDER BY Id DESC LIMIT 500"))
          .map((e) => QueryResult(result: e))
          .toList();

      if (queryResult.length == 0) {
        setState(() => isLoaded = true);
        return;
      }

      articleList = queryResult;
      articleList.forEach((element) => itemKeys[element.id()] = GlobalKey());

      if (!articleList.any((element) => element.id() == widget.articleId)) {
        setState(() => isLoaded = true);
        return;
      }

      Future.value(1).then((value) {
        var row = articleList
                .indexWhere((element) => element.id() == widget.articleId) ~/
            3;
        if (row == 0) return;
        _scrollController.jumpTo(
          row *
                  ((itemKeys[articleList.first.id()]
                              .currentContext
                              .findRenderObject() as RenderBox)
                          .size
                          .height +
                      8) -
              100,
        );
      });

      setState(() => isLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    var windowWidth = MediaQuery.of(context).size.width;

    return !isLoaded
        ? Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Settings.majorColor.withAlpha(150),
              ),
            ),
          )
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            controller: _scrollController,
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3 / 4,
                  ),
                  delegate: SliverChildListDelegate(
                    articleList.map(
                      (e) {
                        return Padding(
                          key: itemKeys[e.id()],
                          padding: EdgeInsets.zero,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Provider<ArticleListItem>.value(
                              value: ArticleListItem.fromArticleListItem(
                                queryResult: e,
                                addBottomPadding: false,
                                showDetail: false,
                                width: (windowWidth - 4.0) / 3.0,
                                thumbnailTag: Uuid().v4(),
                                selectMode: true,
                                selectCallback: () {
                                  Navigator.pop(context, e);
                                },
                              ),
                              child: ArticleListItemVerySimpleWidget(),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ],
          );
  }
}

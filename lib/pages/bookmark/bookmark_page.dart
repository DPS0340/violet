// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:math';

import 'package:animated_widgets/animated_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/other/dialogs.dart';
import 'package:violet/pages/bookmark/group/group_article_list_page.dart';
import 'package:violet/pages/bookmark/group_modify.dart';
import 'package:violet/pages/bookmark/record_view_page.dart';
import 'package:violet/pages/segment/platform_navigator.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/widgets/theme_switchable_state.dart';
import 'package:violet/widgets/toast.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends ThemeSwitchableState<BookmarkPage>
    with AutomaticKeepAliveClientMixin<BookmarkPage> {
  @override
  bool get wantKeepAlive => true;
  // List<Widget> _rows;
  bool reorder = false;

  @override
  VoidCallback? get shouldReloadCallback => null;

  late final FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FutureBuilder(
        future: Bookmark.getInstance().then((value) => value.getGroup()),
        builder: _reorderFutureBuilder,
      ),
      floatingActionButton: SpeedDial(
        childMargin: const EdgeInsets.only(right: 18, bottom: 20),
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.transparent,
        overlayOpacity: 0.2,
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Settings.themeWhat
            ? Settings.themeBlack
                ? const Color(0xFF141414)
                : Colors.grey.shade800
            : Colors.white,
        foregroundColor: Settings.majorColor,
        elevation: 1.0,
        shape: const CircleBorder(),
        children: [
          _dialButton(MdiIcons.orderNumericAscending, 'editorder', () async {
            setState(() {
              reorder = !reorder;
            });
          }),
          _dialButton(MdiIcons.group, 'newgroup', () async {
            (await Bookmark.getInstance()).createGroup(
                Translations.of(context).trans('newgroup'),
                Translations.of(context).trans('newgroup'),
                Colors.orange);
            setState(() {});
          }),
        ],
      ),
    );
  }

  _dialButton(IconData? icon, String label, Function() onTap) {
    return SpeedDialChild(
      child: Icon(icon, color: Settings.majorColor),
      backgroundColor: Settings.themeWhat
          ? Settings.themeBlack
              ? const Color(0xFF141414)
              : Colors.grey.shade800
          : Colors.white,
      label: Translations.of(context).trans(label),
      labelStyle: TextStyle(
        fontSize: 14.0,
        color: Settings.themeWhat ? Colors.white : Colors.grey.shade800,
      ),
      labelBackgroundColor: Settings.themeWhat
          ? Settings.themeBlack
              ? const Color(0xFF141414)
              : Colors.grey.shade800
          : Colors.white,
      onTap: onTap,
    );
  }

  Widget _reorderFutureBuilder(
      BuildContext context, AsyncSnapshot<List<BookmarkGroup>> snapshot) {
    if (!snapshot.hasData) {
      return const Center(
        child: Text('Loading ...'),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final scrollController =
        PrimaryScrollController.of(context) ?? ScrollController();

    final rows = _buildRowItems(snapshot.data!, reorder);

    return reorder
        ? Theme(
            data: Theme.of(context).copyWith(
              // https://github.com/flutter/flutter/issues/45799#issuecomment-770692808
              // Fuck you!!
              canvasColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: ReorderableListView(
              padding: EdgeInsets.fromLTRB(4, statusBarHeight + 16, 4, 8),
              scrollDirection: Axis.vertical,
              scrollController: scrollController,
              children: rows,
              onReorder: _onReorder,
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.fromLTRB(4, statusBarHeight + 16, 4, 8),
            physics: const BouncingScrollPhysics(),
            controller: scrollController,
            itemCount: snapshot.data!.length + 1,
            itemBuilder: (BuildContext ctxt, int index) {
              return _buildItem(
                  index, index == 0 ? null : snapshot.data![index - 1]);
            },
          );
  }

  _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex * newIndex <= 1 || oldIndex == 1 || newIndex == 1) {
      fToast.showToast(
        child: const ToastWrapper(
          isCheck: false,
          isWarning: false,
          msg: 'You cannot move like that!',
        ),
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 4),
      );
      return;
    }

    var bookmark = await Bookmark.getInstance();
    if (oldIndex < newIndex) newIndex -= 1;
    await bookmark.positionSwap(oldIndex - 1, newIndex - 1);
    setState(() {});
  }

  _buildItem(int index, BookmarkGroup? data, [bool reorder = false]) {
    index -= 1;

    String name;
    String oname = '';
    String desc;
    String date = '';
    int id;

    if (index == -1) {
      name = Translations.of(context).trans('readrecord');
      desc = Translations.of(context).trans('readrecorddesc');
      id = -1;
    } else {
      name = data!.name();
      oname = name;
      desc = data.description();
      date = data.datetime().split(' ')[0];
      id = data.id();
    }

    if (name == 'violet_default') {
      name = Translations.of(context).trans('unclassified');
      desc = Translations.of(context).trans('unclassifieddesc');
    }

    final random = Random();

    return Container(
      key: Key('bookmark_group_$id'),
      child: ShakeAnimatedWidget(
        enabled: reorder,
        duration: Duration(milliseconds: 300 + random.nextInt(50)),
        shakeAngle: Rotation.deg(z: 0.8),
        curve: Curves.linear,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Settings.themeWhat ? Colors.black26 : Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Settings.themeWhat
                    ? Colors.black26
                    : Colors.grey.withOpacity(0.1),
                spreadRadius: Settings.themeWhat ? 0 : 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Material(
              color: Settings.themeWhat
                  ? Settings.themeBlack
                      ? const Color(0xFF141414)
                      : Colors.black38
                  : Colors.white,
              child: ListTile(
                title: Text(name, style: const TextStyle(fontSize: 16.0)),
                subtitle: Text(desc),
                trailing: Text(date),
                onTap: reorder
                    ? null
                    : () {
                        PlatformNavigator.navigateSlide(
                          context,
                          id == -1
                              ? const RecordViewPage()
                              : GroupArticleListPage(groupId: id, name: name),
                          opaque: false,
                        );
                      },
                onLongPress: reorder
                    ? null
                    : () async {
                        _onLongPressBookmarkItem(index, oname, name, data);
                      },
              ),
            ),
          ),
        ),
      ),
    );
  }

  _onLongPressBookmarkItem(
      int index, String oname, String name, BookmarkGroup? data) async {
    if (index == -1 || (oname == 'violet_default' && index == 0)) {
      await showOkDialog(
          context,
          Translations.of(context).trans('cannotmodifydefaultgroup'),
          Translations.of(context).trans('bookmark'));
      return;
    }

    final rr = await showDialog(
      context: context,
      builder: (BuildContext context) =>
          GroupModifyPage(name: name, desc: data!.description()),
    );

    if (rr == null) return;

    if (rr[0] == 2) {
      await (await Bookmark.getInstance()).deleteGroup(data!);
    } else if (rr[0] == 1) {
      final nname = rr[1] as String;
      final ndesc = rr[2] as String;

      final rrt = Map<String, dynamic>.from(data!.result);

      rrt['Name'] = nname;
      rrt['Description'] = ndesc;

      await (await Bookmark.getInstance())
          .modfiyGroup(BookmarkGroup(result: rrt));
    }

    setState(() {});
  }

  _buildRowItems(List<BookmarkGroup> data, [bool reorder = false]) {
    var ll = <Widget>[];
    for (int index = 0; index <= data.length; index++) {
      ll.add(_buildItem(index, index == 0 ? null : data[index - 1], reorder));
    }

    return ll;
  }
}

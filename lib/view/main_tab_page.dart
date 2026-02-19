import 'package:diabetes_app/view/detail_predict_page.dart';
import 'package:diabetes_app/view/simple_predict_page.dart';
import 'package:diabetes_app/widgets/app_settings_drawer.dart';
import 'package:flutter/material.dart';

// 심플/상세 탭 전환 + 초기화 버튼
class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _index = 0;
  int _resetCnt = 0;

  List<Widget> get _pages => [
    KeyedSubtree(
      key: ValueKey('simple_$_resetCnt'),
      child: const SimplePredictPage(),
    ),
    KeyedSubtree(
      key: ValueKey('detail_$_resetCnt'),
      child: const DetailPredictPage(),
    ),
  ];

  static const List<String> _titles = [
    '심플 당뇨 예측',
    '상세 당뇨 예측',
  ];

  Future<void> _onRefresh() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초기화'),
        content: const Text('정말 초기화 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _resetCnt++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: '초기화',
          ),
        ],
      ),
      drawer: const AppSettingsDrawer(),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: '심플 당뇨 예측',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: '상세 당뇨 예측',
          ),
        ],
      ),
    );
  }
}

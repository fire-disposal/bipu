import 'package:flutter/material.dart';

/// 传呼台 (B) - 四态切换，支持巨型按钮、声波动画、解锁卡片、图鉴列表
class CallTab extends StatefulWidget {
  const CallTab({super.key});

  @override
  State<CallTab> createState() => _CallTabState();
}

enum CallState { initial, connecting, success, gallery }

class _CallTabState extends State<CallTab> {
  CallState _state = CallState.initial;

  void _toConnecting() => setState(() => _state = CallState.connecting);
  void _toSuccess() => setState(() => _state = CallState.success);
  void _toGallery() => setState(() => _state = CallState.gallery);
  void _toInitial() => setState(() => _state = CallState.initial);

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case CallState.initial:
        return _buildInitial();
      case CallState.connecting:
        return _buildConnecting();
      case CallState.success:
        return _buildSuccess();
      case CallState.gallery:
        return _buildGallery();
    }
  }

  Widget _buildInitial() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：接线员选择区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return ChoiceChip(
                      label: Text('接线员${index + 1}'),
                      selected: index == 0,
                      onSelected: (_) {},
                    );
                  },
                ),
              ),
            ),
            // 中部：消息自定义区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '自定义消息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const TextField(
                          decoration: InputDecoration(
                            hintText: '请输入要发送的消息',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _EffectButton(icon: Icons.light_mode, label: '光效'),
                            _EffectButton(icon: Icons.vibration, label: '震动'),
                            _EffectButton(
                              icon: Icons.auto_awesome,
                              label: '特效',
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.send),
                          label: const Text('发送消息'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 底部：语音输入按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: GestureDetector(
                onLongPress: _toConnecting,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting() {
    return Scaffold(
      body: Stack(
        children: [
          // 动态渐变背景
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaveformAnimation(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _toSuccess,
                  child: const Text('模拟连接成功'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '解锁新搭档',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: _toGallery,
                      child: const Text('查看图鉴'),
                    ),
                    ElevatedButton(
                      onPressed: _toGallery,
                      child: const Text('加入图鉴 ∨'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('接收及图鉴'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toInitial,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID #${1000 + index}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EffectButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EffectButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.blue.shade50,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: Colors.blueAccent, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }
}

/// 声波动画占位
class _WaveformAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 800 + i * 200),
            width: 60.0 + i * 20,
            height: 60.0 + i * 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.2 - i * 0.05),
            ),
          );
        })..add(const Icon(Icons.mic, color: Colors.blue, size: 40)),
      ),
    );
  }
}

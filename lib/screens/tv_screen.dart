import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TvScreen extends StatefulWidget {
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const TvScreen({
    Key? key,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  final List<TvChannel> _channels = [
    TvChannel(
      name: 'ESPN',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/2/2f/ESPN_wordmark.svg',
      isLive: true,
      currentShow: 'Premier League - Arsenal vs Liverpool',
      nextShow: 'SportsCenter',
      time: 'AO VIVO',
    ),
    TvChannel(
      name: 'Sky Sports',
      logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/8/8f/Sky_Sports_logo_2020.svg/1200px-Sky_Sports_logo_2020.svg.png',
      isLive: true,
      currentShow: 'La Liga - Real Madrid vs Barcelona',
      nextShow: 'Sky Sports News',
      time: 'AO VIVO',
    ),
    TvChannel(
      name: 'DAZN',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/DAZN_Logo_Master.svg/2560px-DAZN_Logo_Master.svg.png',
      isLive: false,
      currentShow: 'Série A - Inter vs Milan',
      nextShow: 'Champions League Highlights',
      time: '20:00',
    ),
    TvChannel(
      name: 'beIN Sports',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/BeIN_Sports_logo_%282017%29.svg/2560px-BeIN_Sports_logo_%282017%29.svg.png',
      isLive: false,
      currentShow: 'Ligue 1 - PSG vs Marseille',
      nextShow: 'Bundesliga Weekly',
      time: '21:00',
    ),
    TvChannel(
      name: 'TNT Sports',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/TNT_Sports_logo.svg/2560px-TNT_Sports_logo.svg.png',
      isLive: true,
      currentShow: 'Champions League - Bayern vs City',
      nextShow: 'Post Match Analysis',
      time: 'AO VIVO',
    ),
    TvChannel(
      name: 'Paramount+',
      logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Paramount_Plus.svg/2560px-Paramount_Plus.svg.png',
      isLive: false,
      currentShow: 'UEFA Conference League',
      nextShow: 'Europa League',
      time: '18:30',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.bgColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildChannelsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Ionicons.tv_outline, size: 24, color: widget.textColor),
          const SizedBox(width: 12),
          Text(
            'Canais de TV',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _channels.length,
      itemBuilder: (context, index) {
        return _buildChannelCard(_channels[index]);
      },
    );
  }

  Widget _buildChannelCard(TvChannel channel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.borderColor),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: CachedNetworkImage(
                    imageUrl: channel.logo,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) => Icon(
                      Ionicons.tv,
                      color: widget.subTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            channel.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (channel.isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'AO VIVO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: channel.isLive
                              ? Colors.red
                              : widget.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: widget.borderColor, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Ionicons.play_circle,
                  size: 16,
                  color: widget.subTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    channel.currentShow,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Ionicons.time_outline,
                  size: 16,
                  color: widget.subTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Em seguida: ${channel.nextShow}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.subTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Ionicons.play, size: 18),
                label: const Text('Assistir Agora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2374E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TvChannel {
  final String name;
  final String logo;
  final bool isLive;
  final String currentShow;
  final String nextShow;
  final String time;

  TvChannel({
    required this.name,
    required this.logo,
    required this.isLive,
    required this.currentShow,
    required this.nextShow,
    required this.time,
  });
}
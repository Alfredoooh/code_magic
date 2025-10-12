import 'package:flutter/cupertino.dart';
import '../models/sheet_story.dart';

class SheetsViewerScreen extends StatefulWidget {
  final List<SheetStory> sheets;
  final int initialIndex;

  const SheetsViewerScreen({
    required this.sheets,
    required this.initialIndex,
  });

  @override
  _SheetsViewerScreenState createState() => _SheetsViewerScreenState();
}

class _SheetsViewerScreenState extends State<SheetsViewerScreen> {
  late PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (currentIndex < widget.sheets.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          // PageView horizontal para deslizar entre sheets
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemCount: widget.sheets.length,
            itemBuilder: (context, index) {
              return _buildSheetContent(widget.sheets[index]);
            },
          ),
          
          // Header com título e botão fechar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.sheets[currentIndex].title,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: CupertinoColors.black.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Indicadores de progresso
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 60, left: 16, right: 16),
              child: Row(
                children: List.generate(
                  widget.sheets.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == currentIndex
                            ? CupertinoColors.white
                            : CupertinoColors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Botões de navegação
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: currentIndex > 0
                  ? GestureDetector(
                      onTap: _goToPrevious,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),
          
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: currentIndex < widget.sheets.length - 1
                  ? GestureDetector(
                      onTap: _goToNext,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent(SheetStory sheet) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: sheet.imageUrl.isNotEmpty
                  ? Image.network(
                      sheet.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Icon(
                        CupertinoIcons.photo,
                        size: 100,
                        color: CupertinoColors.systemGrey,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.photo,
                      size: 100,
                      color: CupertinoColors.systemGrey,
                    ),
            ),
          ),
          if (sheet.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.black.withOpacity(0),
                    CupertinoColors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Text(
                  sheet.description,
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
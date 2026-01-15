// models.dart - Classes de dados

class NewsSource {
  final String name;
  final String rss;
  final String favicon;
  final String? country;

  NewsSource({
    required this.name,
    required this.rss,
    required this.favicon,
    this.country,
  });
}

class NewsArticle {
  final String title;
  final String? description;
  final String? imageUrl;
  final String link;
  final DateTime? pubDate;
  final NewsSource source;

  NewsArticle({
    required this.title,
    this.description,
    this.imageUrl,
    required this.link,
    this.pubDate,
    required this.source,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get hasHighQualityImage {
    if (!hasImage) return false;
    final url = imageUrl!.toLowerCase();
    return !url.contains('thumbnail') &&
        !url.contains('small') &&
        !url.contains('tiny') &&
        !url.contains('icon');
  }
}

class Match {
  final String homeTeam;
  final String awayTeam;
  final String homeScore;
  final String awayScore;
  final String competition;
  final String time;
  final bool isLive;
  final bool isFinished;

  Match({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.competition,
    required this.time,
    this.isLive = false,
    this.isFinished = false,
  });
}

class RssSources {
  static final List<NewsSource> sources = [
    NewsSource(name: "ZeroZero", rss: "https://www.zerozero.pt/rss/noticias.php", favicon: "https://www.zerozero.pt/favicon.ico", country: "PT"),
    NewsSource(name: "90min", rss: "https://90min.com/posts.rss", favicon: "https://90min.com/favicon.ico", country: "INT"),
    NewsSource(name: "Goal", rss: "https://www.goal.com/feeds/en/news", favicon: "https://www.goal.com/favicon.ico", country: "INT"),
    NewsSource(name: "ESPN", rss: "https://www.espn.com/espn/rss/news", favicon: "https://www.espn.com/favicon.ico", country: "USA"),
    NewsSource(name: "BBC Sport", rss: "https://feeds.bbci.co.uk/sport/football/rss.xml", favicon: "https://www.bbc.com/favicon.ico", country: "UK"),
    NewsSource(name: "Sky Sports", rss: "https://www.skysports.com/rss/12040", favicon: "https://www.skysports.com/favicon.ico", country: "UK"),
    NewsSource(name: "The Guardian", rss: "https://www.theguardian.com/football/rss", favicon: "https://www.theguardian.com/favicon.ico", country: "UK"),
    NewsSource(name: "FourFourTwo", rss: "https://www.fourfourtwo.com/rss", favicon: "https://www.fourfourtwo.com/favicon.ico", country: "UK"),
    NewsSource(name: "Marca", rss: "https://e00-marca.uecdn.es/rss/en/international.xml", favicon: "https://www.marca.com/favicon.ico", country: "ES"),
    NewsSource(name: "AS", rss: "https://as.com/rss", favicon: "https://as.com/favicon.ico", country: "ES"),
    NewsSource(name: "Mundo Deportivo", rss: "https://www.mundodeportivo.com/rss", favicon: "https://www.mundodeportivo.com/favicon.ico", country: "ES"),
    NewsSource(name: "Sport", rss: "https://www.sport.es/es/rss/", favicon: "https://www.sport.es/favicon.ico", country: "ES"),
    NewsSource(name: "L'Equipe", rss: "https://www.lequipe.fr/rss.xml", favicon: "https://www.lequipe.fr/favicon.ico", country: "FR"),
    NewsSource(name: "Gazzetta", rss: "https://www.gazzetta.it/rss/", favicon: "https://www.gazzetta.it/favicon.ico", country: "IT"),
    NewsSource(name: "Corriere Sport", rss: "https://www.corrieredellosport.it/rss", favicon: "https://www.corrieredellosport.it/favicon.ico", country: "IT"),
    NewsSource(name: "Tuttosport", rss: "https://www.tuttosport.com/rss", favicon: "https://www.tuttosport.com/favicon.ico", country: "IT"),
    NewsSource(name: "Record", rss: "https://www.record.pt/rss/futebol.xml", favicon: "https://www.record.pt/favicon.ico", country: "PT"),
    NewsSource(name: "A Bola", rss: "https://www.abola.pt/rss/noticias.aspx", favicon: "https://www.abola.pt/favicon.ico", country: "PT"),
    NewsSource(name: "O Jogo", rss: "https://www.ojogo.pt/rss/futebol.xml", favicon: "https://www.ojogo.pt/favicon.ico", country: "PT"),
    NewsSource(name: "Bleacher Report", rss: "https://bleacherreport.com/articles/feed", favicon: "https://bleacherreport.com/favicon.ico", country: "USA"),
    NewsSource(name: "CBS Sports", rss: "https://www.cbssports.com/rss/headlines/soccer/", favicon: "https://www.cbssports.com/favicon.ico", country: "USA"),
    NewsSource(name: "Yahoo Sports", rss: "https://sports.yahoo.com/soccer/rss/", favicon: "https://sports.yahoo.com/favicon.ico", country: "USA"),
    NewsSource(name: "Mirror Football", rss: "https://www.mirror.co.uk/sport/football/rss.xml", favicon: "https://www.mirror.co.uk/favicon.ico", country: "UK"),
    NewsSource(name: "Daily Mail", rss: "https://www.dailymail.co.uk/sport/football/index.rss", favicon: "https://www.dailymail.co.uk/favicon.ico", country: "UK"),
    NewsSource(name: "Football Italia", rss: "https://football-italia.net/feed", favicon: "https://football-italia.net/favicon.ico", country: "IT"),
    NewsSource(name: "TeamTalk", rss: "https://www.teamtalk.com/feed/", favicon: "https://www.teamtalk.com/favicon.ico", country: "UK"),
    NewsSource(name: "Football365", rss: "https://www.football365.com/rss", favicon: "https://www.football365.com/favicon.ico", country: "UK"),
    NewsSource(name: "101GreatGoals", rss: "https://www.101greatgoals.com/feed", favicon: "https://www.101greatgoals.com/favicon.ico", country: "INT"),
    NewsSource(name: "CaughtOffside", rss: "https://caughtoffside.com/feed", favicon: "https://caughtoffside.com/favicon.ico", country: "UK"),
    NewsSource(name: "SoccerNews", rss: "https://www.soccernews.com/feed", favicon: "https://www.soccernews.com/favicon.ico", country: "INT"),
  ];

  static final List<Match> todayMatches = [
    Match(homeTeam: "Manchester City", awayTeam: "Liverpool", homeScore: "2", awayScore: "1", competition: "Premier League", time: "20:00", isLive: true),
    Match(homeTeam: "Real Madrid", awayTeam: "Barcelona", homeScore: "0", awayScore: "0", competition: "La Liga", time: "21:00"),
    Match(homeTeam: "Bayern Munich", awayTeam: "Borussia Dortmund", homeScore: "3", awayScore: "2", competition: "Bundesliga", time: "18:30", isFinished: true),
    Match(homeTeam: "PSG", awayTeam: "Marseille", homeScore: "-", awayScore: "-", competition: "Ligue 1", time: "22:00"),
    Match(homeTeam: "Juventus", awayTeam: "Inter Milan", homeScore: "1", awayScore: "1", competition: "Serie A", time: "19:45", isLive: true),
    Match(homeTeam: "Arsenal", awayTeam: "Chelsea", homeScore: "-", awayScore: "-", competition: "Premier League", time: "17:30"),
    Match(homeTeam: "Atletico Madrid", awayTeam: "Sevilla", homeScore: "2", awayScore: "0", competition: "La Liga", time: "16:00", isFinished: true),
    Match(homeTeam: "AC Milan", awayTeam: "Napoli", homeScore: "-", awayScore: "-", competition: "Serie A", time: "20:45"),
    Match(homeTeam: "Benfica", awayTeam: "Porto", homeScore: "1", awayScore: "0", competition: "Primeira Liga", time: "21:15", isLive: true),
    Match(homeTeam: "Ajax", awayTeam: "PSV", homeScore: "-", awayScore: "-", competition: "Eredivisie", time: "19:00"),
  ];
}
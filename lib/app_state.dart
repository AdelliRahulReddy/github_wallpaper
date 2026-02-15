

class PresentationFormatter {
  // Uses local time intentionally - greeting should match user's wall clock
  static String getGreeting() { final h = DateTime.now().hour; return h<12?'Good Morning':h<17?'Good Afternoon':'Good Evening'; }
  static String formatCompactNumber(int n) => n>=1000000?'${(n/1000000).toStringAsFixed(1)}m':n>=1000?'${(n/1000).toStringAsFixed(1)}k':'$n';
  static String formatTimeSince(DateTime d) => timeAgo(d, long:true);
  static String formatTimeAgoCompact(DateTime d) => timeAgo(d, long:false);
  static String timeAgo(DateTime d, {bool long=false}) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(d.toUtc());
    if(diff.inMinutes<1) return long?'Just now':'just now';
    if(diff.inMinutes<60) return long?'${diff.inMinutes} min ago (UTC)':'${diff.inMinutes}m ago (UTC)';
    if(diff.inHours<24) return long?'${diff.inHours} hr ago (UTC)':'${diff.inHours}h ago (UTC)';
    return long?'${diff.inDays} days ago (UTC)':'${diff.inDays}d ago (UTC)';
  }
}

class TrendSummary {
  final int current, previous; const TrendSummary({required this.current, required this.previous});
  double get deltaRatio => previous<=0 ? (current<=0?0.0:1.0) : (current-previous)/previous;
  String get deltaLabel => '${deltaRatio>0?'+':''}${(deltaRatio*100).toStringAsFixed(0)}% vs prev';
}

class ContributionAnalyzer {
  static Map<String, dynamic> analyzeContributions<T>(List<T> days, {required DateTime Function(T) dateOf, required int Function(T) countOf, DateTime? nowUtc}) {
    final totals = <DateTime, int>{};
    for(var d in days) { final dt=dateOf(d), k=DateTime.utc(dt.year,dt.month,dt.day); totals[k]=(totals[k]??0)+countOf(d); }
    if(totals.isEmpty) return {'currentStreak':0, 'longestStreak':0, 'todayContributions':0, 'activeDaysCount':0, 'peakDayContributions':0, 'totalContributions':0, 'mostActiveWeekday':'Monday'};
    
    // Use local time for "Today" determination to align with user's wall clock
    final n = (nowUtc?.toLocal() ?? DateTime.now());
    final targetToday = DateTime.utc(n.year, n.month, n.day);

    final s = _streaks(totals, targetToday);
    final wd = List.filled(7, 0); totals.forEach((k,v) => wd[k.weekday-1]+=v);
    var maxW=0; for(var i=1; i<7; i++) { if(wd[i]>wd[maxW]) maxW=i; }

    return {
      'currentStreak': s['c'], 'longestStreak': s['l'], 'todayContributions': totals[targetToday]??0,
      'activeDaysCount': totals.values.where((c)=>c>0).length, 'peakDayContributions': totals.values.fold(0, (m,c)=>c>m?c:m), 'totalContributions': totals.values.fold(0, (s,c)=>s+c),
      'mostActiveWeekday': ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][maxW]
    };
  }

  static TrendSummary computeTrend<T>(List<T> days, {required int window, required DateTime Function(T) dateOf, required int Function(T) countOf}) {
    if(days.isEmpty||window<=0) return const TrendSummary(current:0, previous:0);
    final sorted = List<T>.from(days)..sort((a,b)=>dateOf(a).compareTo(dateOf(b)));
    final cnt = sorted.map(countOf).toList(), end=cnt.length, start=(end-window).clamp(0,end), prev=(start-window).clamp(0,start);
    return TrendSummary(current: cnt.sublist(start,end).fold(0,(a,b)=>a+b), previous: cnt.sublist(prev,start).fold(0,(a,b)=>a+b));
  }

  static Map<String, int> _streaks(Map<DateTime, int> totals, DateTime today) {
    if(totals.isEmpty) return {'c':0, 'l':0};
    final dates = totals.keys.toList()..sort();
    final treat0 = (totals.length / (dates.last.difference(dates.first).inDays+1)) < 0.9;
    
    var l=0, t=0, safety=0;
    for(var d=dates.first; !d.isAfter(dates.last); d=d.add(const Duration(days:1))) {
      if (++safety > 5000) break; // Safety guard for corrupted dates (Problem 3)
      final c = totals[d];
      if(c==null) { if(treat0) t=0; continue; }
      if(c>0) { t++; if(t>l) l=t; } else { t=0; }
    }

    // Grace period: If no commits today, check yesterday to maintain streak continuity (GitHub-standard behavior)
    var cS=0;
    final cursor = (totals[today]??0)>0 ? today : ((totals[today.subtract(const Duration(days:1))]??0)>0 ? today.subtract(const Duration(days:1)) : null);
    if(cursor!=null) {
      var current = cursor;
      safety=0;
      for(; !current.isBefore(dates.first); current=current.subtract(const Duration(days:1))) {
        if (++safety > 5000) break; // Safety guard
        final c = totals[current];
        if(c == null || c <= 0) break; 
        cS++;
      }
    }
    return {'c':cS, 'l':l};
  }
}

class CacheValidator {
  static bool isStale(DateTime last, [Duration? th, DateTime? n]) => (n??DateTime.now().toUtc()).difference(last.toUtc()) > (th ?? const Duration(hours: 1));
}

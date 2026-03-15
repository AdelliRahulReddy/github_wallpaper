// ══════════════════════════════════════════════════════════════════════════
// 💬 DAILY QUOTES - Local rotating motivational quote engine
// Selects quote by: dayOfYear mod length → deterministic per day, no network.
// ══════════════════════════════════════════════════════════════════════════

class DailyQuoteService {
  static const List<String> _quotes = [
    "First, solve the problem. Then, write the code. — John Johnson",
    "Code is like humor. When you have to explain it, it's bad. — Cory House",
    "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. — Martin Fowler",
    "Programming isn't about what you know; it's about what you can figure out. — Chris Pine",
    "The best error message is the one that never shows up. — Thomas Fuchs",
    "Talk is cheap. Show me the code. — Linus Torvalds",
    "Fix the cause, not the symptom. — Steve Maguire",
    "Premature optimization is the root of all evil. — Donald Knuth",
    "Make it work, make it right, make it fast. — Kent Beck",
    "Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live. — John Woods",
    "Every great developer you know got there by solving problems they were unqualified to solve until they did it. — Patrick McKenzie",
    "The most disastrous thing that you can ever learn is your first programming language. — Alan Kay",
    "Software is a great combination between artistry and engineering. — Bill Gates",
    "Good code is its own best documentation. — Steve McConnell",
    "Testing leads to failure, and failure leads to understanding. — Burt Rutan",
    "It's not a bug – it's an undocumented feature. — Anonymous",
    "Clean code always looks like it was written by someone who cares. — Robert C. Martin",
    "Truth can only be found in one place: the code. — Robert C. Martin",
    "Before software can be reusable it first has to be usable. — Ralph Johnson",
    "The function of good software is to make the complex appear to be simple. — Grady Booch",
    "Deleted code is debugged code. — Jeff Sickel",
    "One of my most productive days was throwing away 1,000 lines of code. — Ken Thompson",
    "Walking on water and developing software from a specification are easy if both are frozen. — Edward V. Berard",
    "Weeks of coding can save you hours of planning. — Unknown",
    "A ship in harbour is safe, but that is not what ships are for. — John A. Shedd",
    "The best way to get a project done faster is to start sooner. — Jim Highsmith",
    "Measuring programming progress by lines of code is like measuring aircraft building progress by weight. — Bill Gates",
    "Experience is the name everyone gives to their mistakes. — Oscar Wilde",
    "Simplicity is the soul of efficiency. — Austin Freeman",
    "In programming, the hard part isn't solving problems, but deciding what problems to solve. — Paul Graham",
    "Push yourself, because no one else is going to do it for you. — Unknown",
    "Great things never come from comfort zones. — Unknown",
    "Dream it. Wish it. Do it. — Unknown",
    "Success doesn't just find you, you have to go out and get it. — Unknown",
    "The harder you work for something, the greater you'll feel when you achieve it. — Unknown",
    "Dream bigger. Do bigger. — Unknown",
    "Don't stop when you're tired. Stop when you're done. — Unknown",
    "Wake up with determination. Go to bed with satisfaction. — Unknown",
    "Do something today that your future self will thank you for. — Unknown",
    "Little things make big days. — Unknown",
    "It's going to be hard, but hard does not mean impossible. — Unknown",
    "Don't wait for opportunity. Create it. — Unknown",
    "Sometimes we're tested not to show our weaknesses, but to discover our strengths. — Unknown",
    "The key to success is to focus on goals, not obstacles. — Unknown",
    "Dream it. Believe it. Build it. — Unknown",
    "Stay hungry. Stay foolish. — Steve Jobs",
    "Your limitation—it's only your imagination. — Unknown",
    "Push harder than yesterday if you want a different tomorrow. — Unknown",
    "Sometimes later becomes never. Do it now. — Unknown",
    "Great things never came from comfort zones. — Unknown",
  ];

  /// Returns today's quote based on day-of-year. No randomness—same quote all day.
  static String today() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  /// Returns the total number of quotes available.
  static int get count => _quotes.length;
}

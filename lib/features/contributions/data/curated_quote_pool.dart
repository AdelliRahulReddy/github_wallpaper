import 'package:github_wallpaper/features/contributions/models/quote_models.dart';

const int maxCuratedQuoteCount = 1000;

final List<CuratedQuote> curatedQuotePool =
    List<CuratedQuote>.unmodifiable(_buildCuratedQuotePool());

List<CuratedQuote> _buildCuratedQuotePool() {
  final quotes = <CuratedQuote>[];

  for (final spec in _specs) {
    for (final tone in QuoteTone.values) {
      final intros = spec.intros[tone]!;
      final actions = spec.actions[tone]!;
      for (final level in QuoteCodingLevel.values) {
        final cues = _levelCues[tone]![level]!;
        for (var index = 0; index < intros.length; index++) {
          quotes.add(
            CuratedQuote(
              id: '${spec.category.key}_${tone.name}_${level.name}_$index',
              text:
                  '${intros[index]} ${cues[index % cues.length]} ${actions[index]}',
              tone: tone,
              levels: {level},
              categories: {spec.category, QuoteCategory.generic},
              streakBuckets: spec.streakBuckets,
              commitBuckets: spec.commitBuckets,
              weeklyBuckets: spec.weeklyBuckets,
            ),
          );
        }
      }
    }
  }

  assert(quotes.length <= maxCuratedQuoteCount);
  return quotes;
}

class _CategorySpec {
  final QuoteCategory category;
  final Set<String> streakBuckets;
  final Set<String> commitBuckets;
  final Set<String> weeklyBuckets;
  final Map<QuoteTone, List<String>> intros;
  final Map<QuoteTone, List<String>> actions;

  const _CategorySpec({
    required this.category,
    required this.streakBuckets,
    required this.commitBuckets,
    required this.weeklyBuckets,
    required this.intros,
    required this.actions,
  });
}

const Set<String> _allStreakBuckets = {
  '0d',
  '1_3d',
  '4_7d',
  '8_14d',
  '15_30d',
  '31_60d',
  '61_100d',
  '100pd',
};

const Set<String> _allCommitBuckets = {
  '0c',
  '1_2c',
  '3_5c',
  '6pc',
};

const Set<String> _allWeeklyBuckets = {
  'idle',
  'warming',
  'steady',
  'surging',
};

final Map<QuoteTone, Map<QuoteCodingLevel, List<String>>> _levelCues = {
  QuoteTone.friendly: {
    QuoteCodingLevel.newcomer: const [
      'Keep the scope tiny and clear.',
      'Start simple and make it real.',
      'One small win is enough.',
      'Choose clarity over cleverness.',
      'Give yourself an easy first rep.',
    ],
    QuoteCodingLevel.beginner: const [
      'Lean on the habit, not guesswork.',
      'You already know enough to land this.',
      'Keep it practical and visible.',
      'A clean finish beats a flashy draft.',
      'Trust the small systems you have built.',
    ],
    QuoteCodingLevel.regular: const [
      'Use your reps to finish something clean.',
      'Let experience shorten the path.',
      'Pick the version that is easiest to ship.',
      'Close the loop while the context is warm.',
      'Aim for useful, not dramatic.',
    ],
    QuoteCodingLevel.hardcore: const [
      'Use your range on the work that matters.',
      'Depth will beat raw volume again.',
      'A sharp cleanup counts more than another sprint.',
      'Push the hard edge, then leave it simpler.',
      'Make the deep work obvious today.',
    ],
  },
  QuoteTone.motivational: {
    QuoteCodingLevel.newcomer: const [
      'Small, real wins are enough.',
      'Momentum can start with one clean move.',
      'Your first rep still counts.',
      'A simple task can reset the day.',
      'Make progress visible, not perfect.',
    ],
    QuoteCodingLevel.beginner: const [
      'You know enough to move this forward.',
      'Consistency grows from honest scope.',
      'Keep the work grounded and finishable.',
      'One real improvement beats five vague intentions.',
      'Trust the process you can repeat tomorrow.',
    ],
    QuoteCodingLevel.regular: const [
      'Trust the reps and close the loop.',
      'Execution is the advantage now.',
      'Use your judgment on the highest-value detail.',
      'Turn the open thread into a finished one.',
      'Let discipline do the steering.',
    ],
    QuoteCodingLevel.hardcore: const [
      'Use your range on the hardest useful task.',
      'Depth is available if you stop scattering.',
      'Real leverage lives in the hard finish.',
      'Make the sharp decision and ship it.',
      'Channel the intensity into durable work.',
    ],
  },
  QuoteTone.roast: {
    QuoteCodingLevel.newcomer: const [
      'No need to cosplay seniority today.',
      'Keep it small before you overcomplicate it.',
      'The repo survives without your masterpiece plan.',
      'A tiny win would already beat more hovering.',
      'Even a humble fix would be a huge upgrade.',
    ],
    QuoteCodingLevel.beginner: const [
      'You know enough to stop orbiting the task.',
      'Another vague plan would be deeply unnecessary.',
      'A clean finish would look suspiciously competent.',
      'Try shipping before the excuses get polished.',
      'The graph would love less theory and more work.',
    ],
    QuoteCodingLevel.regular: const [
      'You have the skills, so laziness looks louder.',
      'At this level, delay is just expensive drama.',
      'A useful patch would be more convincing than thinking about one.',
      'Please do the sharp version, not the theatrical one.',
      'You are too experienced for fake momentum.',
    ],
    QuoteCodingLevel.hardcore: const [
      'With your range, fluff is especially embarrassing.',
      'Try using the talent on the actual bottleneck.',
      'If you are going hard, at least make it useful.',
      'Another heroic detour would be impressively wasteful.',
      'You can do hard things, so do one that matters.',
    ],
  },
};

final List<_CategorySpec> _specs = [
  _CategorySpec(
    category: QuoteCategory.reset,
    streakBuckets: const {'0d', '1_3d'},
    commitBuckets: const {'0c'},
    weeklyBuckets: const {'idle', 'warming'},
    intros: {
      QuoteTone.friendly: const [
        'The board is blank today.',
        'Today still has room to turn.',
        'Nothing is locked in yet.',
        'A quiet start is still a start.',
        'You can make this day count from here.',
      ],
      QuoteTone.motivational: const [
        'The day is still open.',
        'This is a clean restart window.',
        'You can still take control of today.',
        'A reset is available right now.',
        'There is still time to move the graph honestly.',
      ],
      QuoteTone.roast: const [
        'The graph is currently a ghost town.',
        'Today is suspiciously empty.',
        'The repo has seen bolder behavior from a toaster.',
        'You have produced impressive amounts of nothing so far.',
        'The day is begging for evidence of life.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Start with one honest fix.',
        'Pick a tiny task and finish it.',
        'Open one file and leave it better.',
        'Choose the smallest useful improvement.',
        'Let one clean step begin the rhythm.',
      ],
      QuoteTone.motivational: const [
        'Ship one real improvement before the day closes.',
        'Take the smallest meaningful task across the line.',
        'Create momentum with one finished change.',
        'Do one useful thing all the way.',
        'Turn intention into a completed task.',
      ],
      QuoteTone.roast: const [
        'Do one useful thing before the calendar files a complaint.',
        'Ship a real fix and end the suspense.',
        'Open the code instead of your imagination.',
        'Make one change the repo can actually confirm.',
        'Produce a commit worthy of existing.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.protect,
    streakBuckets: const {
      '1_3d',
      '4_7d',
      '8_14d',
      '15_30d',
      '31_60d',
      '61_100d',
      '100pd',
    },
    commitBuckets: const {'0c'},
    weeklyBuckets: _allWeeklyBuckets,
    intros: {
      QuoteTone.friendly: const [
        'Your streak is alive today.',
        'You already built useful momentum this week.',
        'There is good work behind you already.',
        'The rhythm is still intact.',
        'You have something worth protecting.',
      ],
      QuoteTone.motivational: const [
        'Consistency is on your side.',
        'Your streak has real weight now.',
        'You have earned real momentum.',
        'This rhythm was built by honest reps.',
        'The streak is a result, not the goal.',
      ],
      QuoteTone.roast: const [
        'You actually built a streak, so try not to fumble it.',
        'The graph finally trusts you a little.',
        'You are doing better than usual, do not get weird now.',
        'A live streak is no excuse for dramatic procrastination.',
        'You have momentum, so wasting it would be extra embarrassing.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Keep it alive with one meaningful task.',
        'Choose a small win and close it cleanly.',
        'Protect the rhythm with useful work.',
        'Add one real contribution and keep moving.',
        'Make the next step simple and honest.',
      ],
      QuoteTone.motivational: const [
        'Carry the streak with one finished improvement.',
        'Lock in today with work that matters.',
        'Use the rhythm to finish a real task.',
        'Preserve momentum through useful output.',
        'Close one important loop before you log off.',
      ],
      QuoteTone.roast: const [
        'Land one real change before the streak files for divorce.',
        'Protect it with work, not positive thinking.',
        'Add one useful commit and stop flirting with disaster.',
        'Do the simple fix before the streak becomes a memory.',
        'Keep it alive with substance, not vibes.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.rebound,
    streakBuckets: _allStreakBuckets,
    commitBuckets: const {'0c', '1_2c'},
    weeklyBuckets: const {'idle', 'warming'},
    intros: {
      QuoteTone.friendly: const [
        'This week feels a little lighter.',
        'The pace dipped, and that is recoverable.',
        'Your graph is asking for a reset.',
        'Momentum cooled off a bit.',
        'You can still steady the week.',
      ],
      QuoteTone.motivational: const [
        'A rebound starts with one clean move.',
        'Slow weeks turn on small decisions.',
        'This is the moment to tighten scope.',
        'Recovery begins with finished work.',
        'You can reverse the drift today.',
      ],
      QuoteTone.roast: const [
        'This week is looking a little undercooked.',
        'The graph has entered its minimalist phase.',
        'Your momentum wandered off again.',
        'The pace dropped hard enough to notice.',
        'This week currently lacks convincing evidence of effort.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Pick the easiest useful task and finish it.',
        'Use one clean win to restart the rhythm.',
        'Choose repair over pressure and move forward.',
        'Make one visible improvement today.',
        'A tidy fix can turn the week around.',
      ],
      QuoteTone.motivational: const [
        'Recover with one meaningful finish.',
        'Break the slide by closing a real task.',
        'Reset the week with an honest improvement.',
        'Create evidence of progress before the day ends.',
        'Turn hesitation into one shipped change.',
      ],
      QuoteTone.roast: const [
        'Ship one real patch before the slump gets comfortable.',
        'Do a useful fix and stop feeding the drought.',
        'A finished task would interrupt this tragic trend nicely.',
        'Reverse the skid with work, not speeches.',
        'Make the graph less embarrassing by tonight.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.momentum,
    streakBuckets: _allStreakBuckets,
    commitBuckets: const {'1_2c', '3_5c', '6pc'},
    weeklyBuckets: const {'warming', 'steady', 'surging'},
    intros: {
      QuoteTone.friendly: const [
        'You are already moving today.',
        'Nice progress, the graph is safe for now.',
        'Momentum is live on the board.',
        'Today already has some weight.',
        'You got the first push out of the way.',
      ],
      QuoteTone.motivational: const [
        'Momentum is already in your hands.',
        'The hard part of starting is done.',
        'You have a live runway now.',
        'Today already carries forward motion.',
        'Progress is active, so aim it well.',
      ],
      QuoteTone.roast: const [
        'Fine, you actually did something today.',
        'A real commit happened. Miracles continue.',
        'The graph confirms you are not fully fictional.',
        'You started, which ruins several lazy narratives.',
        'Look at that, the repo remembers you exist.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Use the runway to finish one meaningful detail.',
        'Follow it with a clean, useful next step.',
        'Turn the spark into something complete.',
        'Push one more real improvement while the context is warm.',
        'Let the next change be simple and high value.',
      ],
      QuoteTone.motivational: const [
        'Convert the momentum into a finished result.',
        'Take one important detail across the line.',
        'Use the flow to ship durable work.',
        'Aim the next hour at a real finish.',
        'Press the advantage with meaningful output.',
      ],
      QuoteTone.roast: const [
        'Now do something useful with the momentum.',
        'Follow it with a patch that matters, not noise.',
        'Keep going before the effort evaporates.',
        'Use the heat on a real bottleneck.',
        'Try ending the day with substance instead of pride.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.celebrate,
    streakBuckets: const {
      '4_7d',
      '8_14d',
      '15_30d',
      '31_60d',
      '61_100d',
      '100pd',
    },
    commitBuckets: _allCommitBuckets,
    weeklyBuckets: _allWeeklyBuckets,
    intros: {
      QuoteTone.friendly: const [
        'This streak has real shape now.',
        'You crossed into meaningful consistency.',
        'That rhythm deserves a quick nod.',
        'You earned this little milestone.',
        'The streak tells a good story already.',
      ],
      QuoteTone.motivational: const [
        'This milestone was built the right way.',
        'You have proof that consistency compounds.',
        'The streak now carries real signal.',
        'This is earned momentum, not luck.',
        'Milestones matter when the work behind them is real.',
      ],
      QuoteTone.roast: const [
        'A milestone happened, so try not to celebrate for three business days.',
        'You did the hard part. Please do not get ceremonial about it.',
        'Nice streak. Stay normal.',
        'Congratulations, the graph respects you slightly more.',
        'A milestone is cool. Becoming annoying about it is optional.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Use it as fuel for one more honest improvement.',
        'Let the next step be calm and useful.',
        'Celebrate briefly, then finish one meaningful task.',
        'Keep the story strong with real work today.',
        'Turn the milestone into momentum, not pressure.',
      ],
      QuoteTone.motivational: const [
        'Convert the milestone into another finished task.',
        'Use the signal to drive meaningful work today.',
        'Honor it with execution, not just reflection.',
        'Let the streak support your next important finish.',
        'Keep building with the same honest standard.',
      ],
      QuoteTone.roast: const [
        'Mark it, then get back to shipping.',
        'Enjoy the milestone without becoming a LinkedIn post.',
        'Celebrate with one useful patch and move on.',
        'Take the win, then do real work again.',
        'Try following the milestone with substance.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.focus,
    streakBuckets: _allStreakBuckets,
    commitBuckets: _allCommitBuckets,
    weeklyBuckets: const {'warming', 'steady', 'surging'},
    intros: {
      QuoteTone.friendly: const [
        'One project is clearly carrying the week.',
        'A single repo has your attention right now.',
        'The story is centered on one codebase.',
        'Your strongest repo is doing most of the talking.',
        'There is a clear project focus this week.',
      ],
      QuoteTone.motivational: const [
        'Focus is visible in the work.',
        'The signal is concentrated in one project.',
        'A clear lane has opened up.',
        'This week has a main mission.',
        'The work is clustering around something important.',
      ],
      QuoteTone.roast: const [
        'One repo is carrying the whole operation right now.',
        'A single project is doing all the heavy lifting.',
        'The rest of the repos are mostly spectators.',
        'One codebase has become the responsible adult here.',
        'Apparently one project got custody of your attention.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Lean into it and finish the highest-value detail.',
        'Use the focus to close a meaningful thread.',
        'Ship the part that makes the project cleaner.',
        'Push the repo forward with one durable improvement.',
        'Keep the attention narrow and useful.',
      ],
      QuoteTone.motivational: const [
        'Drive that project through a real finish.',
        'Use the focus to ship something durable.',
        'Close the most valuable open thread there.',
        'Put another strong layer on the main project.',
        'Stay concentrated until a real result lands.',
      ],
      QuoteTone.roast: const [
        'If one repo has custody of your focus, at least reward it with good work.',
        'Finish the useful part before opening a pointless side quest.',
        'Keep the project moving instead of sampling distractions.',
        'Do the sharp fix, not an attention-seeking detour.',
        'Stay on the main repo and act like you meant it.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.consistency,
    streakBuckets: _allStreakBuckets,
    commitBuckets: _allCommitBuckets,
    weeklyBuckets: const {'steady', 'surging'},
    intros: {
      QuoteTone.friendly: const [
        'The week already looks steady.',
        'Your activity pattern is holding up well.',
        'You are showing up often this week.',
        'The rhythm is becoming reliable.',
        'This is what consistency looks like.',
      ],
      QuoteTone.motivational: const [
        'Steady output is building real leverage.',
        'Consistency is doing its quiet work.',
        'The pattern is strong because you kept showing up.',
        'This rhythm compounds faster than it feels.',
        'Reliable work is turning into visible signal.',
      ],
      QuoteTone.roast: const [
        'You have been weirdly consistent this week.',
        'The graph looks organized for once.',
        'A stable rhythm is emerging. Do not scare it away.',
        'You are stacking decent days together. Suspicious, but good.',
        'Consistency is happening, which is frankly useful.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Protect it with one more clean contribution.',
        'Keep the pace by finishing a useful detail.',
        'Add one honest task to the pattern.',
        'Keep the week sturdy with real work.',
        'Let the rhythm carry one more finish.',
      ],
      QuoteTone.motivational: const [
        'Extend the pattern through another meaningful finish.',
        'Keep compounding with useful output.',
        'Use the rhythm to close a real task today.',
        'Reinforce the week with one durable improvement.',
        'Let consistency produce another concrete result.',
      ],
      QuoteTone.roast: const [
        'Keep the rhythm alive with a patch that matters.',
        'Do not ruin a good week with lazy theatrics.',
        'Add one real contribution and keep the graph respectable.',
        'Stay consistent long enough for it to become normal.',
        'Protect the streak of competence with actual work.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.deepWork,
    streakBuckets: _allStreakBuckets,
    commitBuckets: const {'1_2c', '3_5c', '6pc'},
    weeklyBuckets: const {'steady', 'surging'},
    intros: {
      QuoteTone.friendly: const [
        'There is enough energy here for deeper work.',
        'The week has room for something substantial.',
        'You have built enough momentum to go below the surface.',
        'This is a good window for a hard useful task.',
        'The graph says you can afford depth today.',
      ],
      QuoteTone.motivational: const [
        'This is a strong moment for real depth.',
        'You have the runway for substantial work.',
        'The week can support a harder finish now.',
        'Depth is available if you stay focused.',
        'This is where leverage comes from.',
      ],
      QuoteTone.roast: const [
        'You have enough momentum for deep work, so please stop nibbling around the edges.',
        'The graph is strong enough to justify a real task now.',
        'This is the part where you stop pretending a tiny tweak was enough.',
        'You can afford a harder problem, so maybe act like it.',
        'There is runway for deep work if you quit babysitting easy tasks.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Choose the cleanup, test pass, or refactor that will still matter tomorrow.',
        'Spend the next block on work with durable value.',
        'Push on the hard useful edge and leave it cleaner.',
        'Use the focus for a result that reduces future friction.',
        'Finish something substantial while the context is strong.',
      ],
      QuoteTone.motivational: const [
        'Invest the next hour in a durable improvement.',
        'Take on the harder useful task and finish it well.',
        'Aim for work that pays back later.',
        'Ship the change that removes real friction.',
        'Turn momentum into deep, durable output.',
      ],
      QuoteTone.roast: const [
        'Go fix the real bottleneck instead of polishing trivia.',
        'Use the runway on a task worthy of the effort.',
        'Do the hard useful thing and stop padding the stats.',
        'Spend the energy on something future-you will respect.',
        'Take the deeper ticket across the line for once.',
      ],
    },
  ),
  _CategorySpec(
    category: QuoteCategory.generic,
    streakBuckets: _allStreakBuckets,
    commitBuckets: _allCommitBuckets,
    weeklyBuckets: _allWeeklyBuckets,
    intros: {
      QuoteTone.friendly: const [
        'Your work adds up faster than it feels.',
        'A calm, useful day still moves the project.',
        'Small honest progress counts here.',
        'The graph follows real effort, not noise.',
        'You do not need a dramatic day to make progress.',
      ],
      QuoteTone.motivational: const [
        'Real progress is built in finished pieces.',
        'Meaningful work beats performative activity every time.',
        'Discipline looks ordinary until it compounds.',
        'Useful output is always the shortest path forward.',
        'Another finished task can change the shape of the week.',
      ],
      QuoteTone.roast: const [
        'The repo prefers useful work over inspirational theater.',
        'Your graph has no interest in excuses.',
        'A real patch would still be the best personality trait here.',
        'The codebase notices effort more than optimism.',
        'You can skip the speech and ship something instead.',
      ],
    },
    actions: {
      QuoteTone.friendly: const [
        'Pick one thing that matters and move it forward.',
        'Leave one area of the codebase cleaner.',
        'Finish a useful detail before the day ends.',
        'Choose progress you can point to.',
        'Close one loop and call that a win.',
      ],
      QuoteTone.motivational: const [
        'Take one meaningful task across the line.',
        'Ship a result that holds up tomorrow.',
        'Close the loop on something real.',
        'Do the useful version of the next hour.',
        'Make the next contribution honest and complete.',
      ],
      QuoteTone.roast: const [
        'Try producing evidence of competence before midnight.',
        'Do one useful thing and spare everyone the suspense.',
        'Ship the real fix, not another idea about one.',
        'Make one change the graph can verify.',
        'End the day with substance, not commentary.',
      ],
    },
  ),
];

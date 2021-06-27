import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class GameModel extends ChangeNotifier {
  var _paused = false;

  int jackpotAbsCap = 30;
  int jackpotMaxDelta = 5;
  int defaultJackpotLimit;
  int _jackpotLimit;
  int _jackpotValue = 0;

  Map<String, Function(Card)> actions = {};
  Map<String, bool Function(GameModel, CardBase)> predicates = {};

  bool _victory = false;
  bool get victory => _victory;
  void setVictory(val, {notify = true}) {
    _victory = val;
    if (notify) {
      notifyListeners();
    }
  }

  int get jackpotLimit => _jackpotLimit;
  void setJackpotLimit(int val, {notify = true}) {
    _jackpotLimit = val;
    if (notify) {
      notifyListeners();
    }
  }

  void resetJackpotLimit({notify = true}) =>
      setJackpotLimit(defaultJackpotLimit, notify: notify);

  int get jackpotValue => _jackpotValue;
  void setJackpotValue(int val, {notify = true}) {
    _jackpotValue = val;
    if (notify) {
      notifyListeners();
    }
  }

  bool get paused => _paused;
  set paused(val) {
    _paused = val;
    notifyListeners();
  }

  GameModel(this._jackpotLimit) : defaultJackpotLimit = _jackpotLimit;
}

class MyApp extends StatelessWidget {
  void initActions(GameModel model) {
    model.actions["default"] = (Card c) => c.actionDefault();
    model.actions["leech"] = (Card c) =>
        c._gameModel.setJackpotValue(max(0, c.jackpotValue - c._amount));
    model.actions["jacked"] = (Card c) {
      c._jackpotLimit = c._jackpotLimit + c._amount;
      c._gameModel.setJackpotLimit(c._jackpotLimit, notify: false);
    };
  }

  void initPredicates(GameModel model) {
    // asserts that jackpot can increase legally
    model.predicates["jacked"] = (GameModel gm, CardBase base) {
      final deltaPlus = gm.jackpotAbsCap - gm.jackpotLimit;
      return deltaPlus >= base.sipRange.min;
    };
  }

  @override
  Widget build(BuildContext context) {
    GameModel model = GameModel(30);
    initActions(model);
    initPredicates(model);

    const primaryColor = Color.fromARGB(255, 255, 176, 43);
    const primTextColor = Color.fromARGB(255, 68, 41, 0);
    const primBodyColor = Color.fromARGB(255, 136, 120, 94);

    // lobster
    // patuaOne
    // bangers
    // ultra
    // fugaz one
    // shrikhand
    final baseHeadFont = GoogleFonts.lobster(
        textStyle: const TextStyle(
      color: primTextColor,
    ));
    // yanone kaffeesats
    // bitter
    final baseBodyFont = GoogleFonts.bitter(
        textStyle: const TextStyle(
      color: primBodyColor,
    ));

    return MaterialApp(
      title: "ShitFuck 2: Jackpot Boogaloo!",
      theme: ThemeData(
        primaryColor: primaryColor,
        accentColor: primTextColor,
        backgroundColor: const Color.fromARGB(255, 254, 234, 146),
        primaryTextTheme: TextTheme(
          headline6: baseBodyFont.copyWith(
            color: primTextColor,
          ),
        ),
        textTheme: TextTheme(
          headline1: baseHeadFont.copyWith(
            fontSize: 80,
            fontWeight: FontWeight.normal,
          ),
          headline2: baseHeadFont.copyWith(
            fontSize: 60,
            height: 1.1,
          ),
          bodyText1: baseBodyFont.copyWith(
            fontSize: 32,
            height: 1.1,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      home: ChangeNotifierProvider(
        create: (context) => model,
        child: Boogaloo(),
      ),
    );
  }
}

class Boogaloo extends StatefulWidget {
  @override
  BoogalooState createState() => BoogalooState();
}

class BoogalooState extends State<Boogaloo>
    with SingleTickerProviderStateMixin {
  CardDeck? _cardDeck;
  Card? _oldCard;

  BoogalooState() {
    loadCards("assets/cards/cards.json")
        .then((CardDeck deck) => setState(() => _cardDeck = deck));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final gameModel = Provider.of<GameModel>(context);

    bool ok = false;
    CardBase? base;

    while (!ok) {
      final r = Random().nextDouble();
      base = _cardDeck?.pick(r);
      ok = base == null
          ? true
          : gameModel.predicates[base.predicate]?.call(gameModel, base) ?? true;
    }

    // Some cards can change the jackpotlimit. This allows 'clutching' the game,
    // and is a desired mechanic, however, it makes for a 'cleaner' victory screen
    // if the old limit is displayed, should the clutch fail.
    final oldJackpotLimit = gameModel.jackpotLimit;

    Card? card;
    if (base != null) {
      card = Card(
        base: base,
        gameModel: gameModel,
      );
    }
    _oldCard = card;

    // Edge case: if the card is a 'Jacked' card, there is a chance of the
    // game continuing, check this.
    if (gameModel.jackpotValue >= gameModel.jackpotLimit) {
      gameModel.setJackpotLimit(oldJackpotLimit, notify: false);
      gameModel.setVictory(true, notify: false);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shitfuck 2: Jackpot Boogaloo!"),
      ),
      body: card == null
          ? LoadingScreen()
          : gameModel.victory
              ? VictoryScreen(gameModel)
              : card,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
      "Loading...",
      style: const TextStyle(
        fontSize: 60,
      ),
    ));
  }
}

class VictoryScreen extends StatelessWidget {
  final GameModel _gameModel;

  VictoryScreen(this._gameModel);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _gameModel.setJackpotValue(0, notify: false);
        _gameModel.resetJackpotLimit(notify: false);
        _gameModel.setVictory(false);
      },
      child: Stack(children: [
        Container(
          color: theme.backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Text(
                    "Victory!\n(and Loss)",
                    textAlign: TextAlign.center,
                    style: textTheme.headline1
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )),
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Tap to play again!",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyText1?.copyWith(fontSize: 60),
                ),
              )
            ],
          ),
        ),
        Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            "${_gameModel.jackpotValue} / ${_gameModel.jackpotLimit}",
            style: textTheme.headline1,
            textAlign: TextAlign.center,
          ),
        ),
      ]),
    );
  }
}

class Range<T extends num> {
  T min;
  T max;

  Range(this.min, this.max);

  bool contains(T x) => min <= x && x < max;
  bool containsInc(T x) => min <= x && x <= max;
}

extension RandRange on Random {
  T inRange<T extends num>(Range<T> range) {
    if (range is Range<double>) {
      final r = nextDouble();
      return range.min + r * (range.max - range.min) as T;
    } else if (range is Range<int>) {
      final r = nextInt(range.max - range.min as int);
      return r + range.min as T;
    }

    return 0 as T;
  }

  T inRangeInc<T extends num>(Range<T> range) =>
      inRange(range..max = range.max + 1 as T);
}

class CardBase {
  Icon? icon;
  String event = "";
  String shortDesc = "";
  String action = "";
  String preAction = "";
  String predicate = "";

  // Probability range: number used to select a card based on probability weight.
  // Only makes sense within the context of a list sorted by this number.
  double pMax = 0.0;
  late Range<int> sipRange;

  CardBase() : sipRange = Range(1, 5);

  CardBase.fromJson(Map<String, dynamic> json) {
    event = json["event"];
    shortDesc = json["shortDesc"];
    sipRange = Range(json["amountMin"], json["amountMax"] + 1);
    action = json["action"] ?? "default";
    preAction = json["preAction"] ?? "";
    predicate = json["predicate"] ?? "";

    final iconUni = json["iconU"];
    if (iconUni != null) {
      icon = Icon(
        IconData(iconUni, fontFamily: "MaterialIcons"),
      );
    }
  }
}

class Pair<T, U> {
  T fst;
  U snd;

  Pair(this.fst, this.snd);
}

extension Sum on Iterable<num> {
  num sum() => fold(0, (s, x) => s + x);
}

class CardDeck {
  List<Pair<double, CardBase>> cards = [];

  void add(double weight, CardBase card) => cards.add(Pair(weight, card));

  /// Pick a card out of the deck. Sel is a double in the range [0, 1).
  CardBase? pick(double sel) {
    if (cards.isEmpty) {
      return null;
    }

    final weightSum = cards.last.fst;
    final double weightSel = sel * weightSum;

    final choice = cards
        .firstWhere((c) => weightSel < c.fst, orElse: () => throw "Invalid card selector: $weightSel")
        .snd;

    return choice;
  }
}

Future<CardDeck> loadCards(String fileName) async {
  final cardsString = await rootBundle.loadString(fileName);
  final json = await JsonDecoder().convert(cardsString);

  final drinkCardJson = json["drinkCard"];
  double drinkCardP = drinkCardJson["probability"] ?? 0.5;
  final drinkCard = CardBase.fromJson(drinkCardJson);

  final specialCards = json["specialCards"];
  if (specialCards is! List<dynamic>) {
    throw "Invalid json: 'specialCards' must be a list.";
  }

  double weightSum =
      specialCards.map((cb) => cb["weight"] as int).fold(0, (s, x) => s + x);

  // Weight of drinkCard
  weightSum = drinkCardP / (1 - drinkCardP) * weightSum;

  var deck = CardDeck();
  deck.add(weightSum, drinkCard);

  for (var cardBaseJson in specialCards) {
    final weight = cardBaseJson["weight"];
    weightSum += weight as int;
    final cardBase = CardBase.fromJson(cardBaseJson);
    deck.add(weightSum, cardBase);
  }

  print("weightSum: $weightSum");

  return deck;
}

class Card extends StatelessWidget {
  final _rng = Random();

  final GameModel _gameModel;

  int _jackpotLimit;
  var _jackpotValue = 0;
  int get jackpotValue => _jackpotValue;

  late Function(Card) action;

  late final int _amount;

  final Icon? icon;

  final String event;
  // String get event => _event;

  final String shortDesc;

  final _jackpotStyle = const TextStyle(
    fontSize: 80,
  );
  final _eventStyle = const TextStyle(
    fontSize: 60,
  );
  final _amountStyle = const TextStyle(
    fontSize: 80,
  );
  final _descStyle = const TextStyle(
    fontSize: 30,
    color: Color.fromARGB(255, 150, 150, 150),
  );

  Card({
    required CardBase base,
    required GameModel gameModel,
    int? amount,
  })  : _gameModel = gameModel,
        _jackpotLimit = gameModel.jackpotLimit,
        _jackpotValue = gameModel.jackpotValue,
        event = base.event,
        shortDesc = base.shortDesc,
        icon = base.icon {
    _amount = amount ?? _rng.inRange(base.sipRange);

    action = gameModel.actions[base.action] ?? (_) => actionDefault();

    gameModel.actions[base.preAction]?.call(this);
  }

  void actionDefault() {
    _gameModel.setJackpotValue(jackpotValue + _amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final Icon? icon = Icon(
      this.icon?.icon,
      size: 100,
      color: textTheme.headline1?.color,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        action(this);
      },
      child: Container(
          color: theme.backgroundColor,
          constraints: const BoxConstraints.tightForFinite(),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "$_jackpotValue / $_jackpotLimit",
                  style: textTheme.headline1,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: icon ??
                    Padding(
                        padding: EdgeInsets.all(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            color: Colors.grey[400],
                          ),
                        )),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 15, left: 15, right: 15),
                      child: Text(
                        event,
                        style: textTheme.headline2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Text(
                        shortDesc,
                        style: textTheme.bodyText1,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    "$_amount",
                    style: textTheme.headline1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

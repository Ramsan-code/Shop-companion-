import 'package:equatable/equatable.dart';

import '../../ledger/domain/models.dart';
import 'phonetic.dart';

class CustomerMatch extends Equatable {
  const CustomerMatch(this.customer, this.score);

  final Customer customer;

  /// 0–1; 1 = same sound key.
  final double score;

  @override
  List<Object?> get props => [customer.id, score];
}

/// Matches the heard name against this shop's customers (PRD C1 parser v1).
///
/// Ranks by sound-alike key, so script and spelling don't matter, and uses
/// the kinship word as a tie-breaker ("Ravi annai" vs "Ravi thambi").
class CustomerMatcher {
  const CustomerMatcher({this.autoPickScore = 0.8, this.autoPickMargin = 0.15});

  /// Pick without asking only when the best match is this good…
  final double autoPickScore;

  /// …and this far ahead of the next one.
  final double autoPickMargin;

  List<CustomerMatch> rank(
    String heardName,
    List<Customer> customers, {
    Kinship? heardKinship,
    int limit = 5,
  }) {
    final heard = phoneticKey(heardName);
    if (heard.isEmpty) return const [];
    final matches = <CustomerMatch>[];
    for (final c in customers) {
      var best = 0.0;
      for (final key in phoneticKeys(c.name)) {
        best = _score(heard, key) > best ? _score(heard, key) : best;
      }
      // A different kinship word ("thambi" for an "annai") counts against
      // more than a matching one counts for.
      if (heardKinship != null && c.kinship != null) {
        best += c.kinship == heardKinship ? 0.1 : -0.2;
      }
      if (best >= 0.5) matches.add(CustomerMatch(c, best.clamp(0, 1)));
    }
    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : b.customer.balance.cents.compareTo(a.customer.balance.cents);
    });
    return matches.take(limit).toList();
  }

  /// The customer to fill in without asking, if the match is clear.
  Customer? autoPick(List<CustomerMatch> ranked) {
    if (ranked.isEmpty || ranked.first.score < autoPickScore) return null;
    if (ranked.length > 1 &&
        ranked.first.score - ranked[1].score < autoPickMargin) {
      return null;
    }
    return ranked.first.customer;
  }

  static double _score(String heard, String key) {
    if (key.isEmpty) return 0;
    if (heard == key) return 1;
    final distance = editDistance(heard, key);
    final longest = heard.length > key.length ? heard.length : key.length;
    return 1 - distance / longest;
  }
}

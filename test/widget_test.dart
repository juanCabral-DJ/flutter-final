import 'package:flutter_test/flutter_test.dart';
import 'package:trading_journal/features/trading_journal/data/repositories/trade_repository_impl.dart';
import 'package:trading_journal/main.dart';

void main() {
  testWidgets('Trading Journal smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final repository = TradeRepositoryImpl();
    await tester.pumpWidget(TradingJournalApp(tradeRepository: repository));

    // Verify that the title or initial screen renders
    expect(find.text('Historial de Trades'), findsOneWidget);
  });
}

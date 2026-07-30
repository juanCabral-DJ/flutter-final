import 'package:flutter_test/flutter_test.dart';
import 'package:trading_journal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:trading_journal/features/trading_journal/data/repositories/trade_repository_impl.dart';
import 'package:trading_journal/main.dart';

void main() {
  testWidgets('Trading Journal smoke test', (WidgetTester tester) async {
    final tradeRepository = TradeRepositoryImpl();
    final authRepository = AuthRepositoryImpl();

    await tester.pumpWidget(TradingJournalApp(
      tradeRepository: tradeRepository,
      authRepository: authRepository,
    ));

    expect(find.byType(TradingJournalApp), findsOneWidget);
  });
}

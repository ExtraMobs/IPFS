import 'package:test/test.dart';
import 'package:transpiled_libp2p/transpiled_libp2p.dart';

void main() {
  test('dial timeout defaults and overrides independently', () {
    final original = dialPeerTimeout;
    addTearDown(() => dialPeerTimeout = original);
    dialPeerTimeout = const Duration(seconds: 3);

    expect(
      getDialPeerTimeout(NetworkContext.empty),
      const Duration(seconds: 3),
    );
    final context = withDialPeerTimeout(
      NetworkContext.empty,
      const Duration(milliseconds: 1),
    );
    expect(getDialPeerTimeout(context), const Duration(milliseconds: 1));
  });

  test('network context options preserve reasons and client precedence', () {
    var context = withForceDirectDial(NetworkContext.empty, 'direct');
    context = withNoDial(context, 'reuse');
    context = withAllowLimitedConn(context, 'relay');
    context = withSimultaneousConnect(context, false, 'server');
    context = withSimultaneousConnect(context, true, 'client');

    expect(getForceDirectDial(context), (true, 'direct'));
    expect(getNoDial(context), (true, 'reuse'));
    expect(getAllowLimitedConn(context), (true, 'relay'));
    expect(getSimultaneousConnect(context), (true, true, 'client'));
    expect(getUseTransient(context), (true, 'relay'));

    final server = withSimultaneousConnect(NetworkContext.empty, false, 'only');
    expect(getSimultaneousConnect(server), (true, false, 'only'));
  });

  test('connection scope context unwraps or reports the Go-visible error', () {
    const scope = NullScope();
    expect(
      unwrapConnManagementScope(
        withConnManagementScope(NetworkContext.empty, scope),
      ),
      same(scope),
    );
    expect(
      () => unwrapConnManagementScope(NetworkContext.empty),
      throwsA(isA<MissingConnManagementScopeException>()),
    );
  });
}

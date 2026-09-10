// Testes de Fd, port de `internal/poll.FD` sobre RawSocket.
//
// Estes testes usam sockets reais em loopback, mas são determinísticos por
// construção, e não por espera cronometrada. O truque é a contrapressão: um
// servidor que aceita a conexão e **nunca lê** faz o buffer de envio do kernel
// encher, e a partir daí `RawSocket.write` passa a aceitar 0 bytes. Isso
// coloca a escrita numa espera que só termina por prontidão ou por eviction —
// exatamente o estado em que o bug de produção acontecia. Nenhum teste aqui
// depende de "esperar tempo suficiente"; todos esperam por uma condição.
//
// O invariante mais caro está no teste "fechar com escrita em voo": ele falha
// se uma escrita interrompida pelo fechamento for dada como bem-sucedida, ou
// notificada com um erro sobre o sink em vez do sentinela de conexão fechada.
// Essa é a garantia que o `net.Conn` do Go dá e o `Socket` do dart:io não dá.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:boilerplate/internal_poll/golang.dart';
import 'package:test/test.dart';

/// Deixa a fila de microtasks e a de eventos drenarem.
Future<void> _pump([int voltas = 3]) async {
  for (var i = 0; i < voltas; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Espera [condicao] virar verdadeira, com teto para não pendurar a suíte.
Future<void> _ate(bool Function() condicao, {String? motivo}) async {
  final limite = DateTime.now().add(const Duration(seconds: 5));
  while (!condicao()) {
    if (DateTime.now().isAfter(limite)) {
      fail('condição não satisfeita em 5s${motivo == null ? '' : ': $motivo'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

/// Servidor que aceita conexões e nunca lê, para encher o buffer de envio.
class _ServidorMudo {
  _ServidorMudo(this._server);

  static Future<_ServidorMudo> abrir() async =>
      _ServidorMudo(await ServerSocket.bind('127.0.0.1', 0));

  final ServerSocket _server;
  final List<Socket> aceitos = <Socket>[];
  StreamSubscription<Socket>? _sub;

  int get port => _server.port;

  void aceitarSemLer() {
    _sub = _server.listen(aceitos.add);
  }

  Future<void> fechar() async {
    await _sub?.cancel();
    for (final s in aceitos) {
      s.destroy();
    }
    await _server.close();
  }
}

void main() {
  group('Fd - contrapressão e escrita completa', () {
    test('write entrega tudo quando o par drena', () async {
      final server = await ServerSocket.bind('127.0.0.1', 0);
      final recebidos = <int>[];
      final tudoRecebido = Completer<void>();
      const total = 512 * 1024;

      server.listen((socket) {
        socket.listen((chunk) {
          recebidos.addAll(chunk);
          if (recebidos.length >= total && !tudoRecebido.isCompleted) {
            tudoRecebido.complete();
          }
        });
      });

      final raw = await RawSocket.connect('127.0.0.1', server.port);
      final fd = Fd(raw);

      final payload = Uint8List(total);
      for (var i = 0; i < total; i++) {
        payload[i] = i & 0xff;
      }

      final escritos = await fd.write(payload);
      expect(
        escritos,
        total,
        reason: 'write só completa quando TODOS os bytes foram aceitos pelo '
            'kernel, atravessando quantos ciclos de prontidão forem precisos',
      );

      await tudoRecebido.future.timeout(const Duration(seconds: 10));
      expect(recebidos.length, greaterThanOrEqualTo(total));

      await fd.close();
      await server.close();
    });
  });

  group('Fd - fechamento durante operação em voo', () {
    test('fechar com escrita em voo notifica a escrita e não corrompe estado',
        () async {
      final servidor = await _ServidorMudo.abrir();
      servidor.aceitarSemLer();

      final raw = await RawSocket.connect('127.0.0.1', servidor.port);
      final fd = Fd(raw);

      // Grande o bastante para exceder o buffer de envio com folga: a escrita
      // vai estacionar esperando prontidão.
      final payload = Uint8List(16 * 1024 * 1024);

      Object? erroDaEscrita;
      var escritaTerminou = false;
      unawaited(
        fd.write(payload).then(
          (_) => escritaTerminou = true,
          onError: (Object e) {
            erroDaEscrita = e;
            escritaTerminou = true;
          },
        ),
      );

      // Confirma que a escrita realmente ficou presa antes de fechar. Sem isso
      // o teste poderia passar sem nunca exercitar a corrida.
      await _pump(10);
      expect(
        escritaTerminou,
        isFalse,
        reason: 'com o par sem ler, a escrita tem de estar estacionada; '
            'se ela completou, o cenário do bug não foi reproduzido',
      );

      await fd.close();

      await _ate(() => escritaTerminou, motivo: 'a escrita presa foi acordada');
      expect(
        erroDaEscrita,
        isA<NetClosingException>(),
        reason: 'a escrita interrompida por fechamento tem de ser notificada '
            'com o sentinela do upstream, e não silenciosamente dada como '
            'bem-sucedida nem com um StateError sobre o sink',
      );
      expect(
        erroDaEscrita.toString(),
        'use of closed network connection',
        reason: 'texto preservado literalmente do upstream',
      );

      await servidor.fechar();
    });

    // Nota de honestidade sobre o alcance destes dois testes, apurada por
    // mutação: eles NÃO conseguem distinguir a espera explícita de `close`
    // pelas operações em voo de uma versão que destrua o socket sem esperar.
    // A razão é dupla, e vale registrar porque é contraintuitiva. Primeiro,
    // toda operação acordada pela eviction passa por `_throwIfBroken` antes de
    // tocar no socket, então mesmo destruindo cedo nada opera sobre o
    // descritor morto. Segundo, `_destroy` tem `await`s próprios, e as
    // microtasks que eles liberam bastam para as operações assentarem de
    // qualquer jeito — a garantia sairia certa por acidente.
    //
    // O que a espera explícita compra, e o motivo de ela existir mesmo assim:
    // a garantia deixa de depender daquele acidente. Se um dia `_destroy`
    // deixar de suspender, ou se `_throwIfBroken` for removido por parecer
    // redundante, o contrato "nenhum callback dispara depois que close
    // retorna" continua valendo. É a diferença entre um invariante declarado e
    // um que emerge do arranjo atual das suspensões.
    test('close deixa a operação em voo notificada e o descritor destruído',
        () async {
      final servidor = await _ServidorMudo.abrir();
      servidor.aceitarSemLer();

      final raw = await RawSocket.connect('127.0.0.1', servidor.port);
      final fd = Fd(raw);

      var destruido = false;
      unawaited(fd.destroyed.then((_) => destruido = true));

      var escritaTerminou = false;
      unawaited(
        fd
            .write(Uint8List(16 * 1024 * 1024))
            .then((_) => escritaTerminou = true, onError: (Object _) {
          escritaTerminou = true;
        }),
      );
      await _pump(10);
      expect(escritaTerminou, isFalse);

      await fd.close();

      expect(
        escritaTerminou,
        isTrue,
        reason: 'ao retornar de close, a escrita que estava estacionada já '
            'tem de ter sido acordada e notificada',
      );
      expect(destruido, isTrue);

      await servidor.fechar();
    });

    // Este cobre o alargamento real do contrato, e não é acidental: a operação
    // B nunca chega a adquirir a trava, fica na fila do FdMutex. Sob a
    // contagem de referências do upstream ela seria invisível para o `close`,
    // porque a referência só era tomada DEPOIS de adquirir a trava — B podia
    // assentar depois de `close` retornar. Rastrear o future no momento da
    // chamada, e não no momento da aquisição, é o que fecha essa fresta.
    test('close também espera pela operação que ainda nem começou', () async {
      final servidor = await _ServidorMudo.abrir();
      servidor.aceitarSemLer();

      final raw = await RawSocket.connect('127.0.0.1', servidor.port);
      final fd = Fd(raw);

      final assentadas = <String>[];

      // A estaciona na contrapressão, segurando a trava de escrita.
      unawaited(
        fd.write(Uint8List(16 * 1024 * 1024)).then(
              (_) => assentadas.add('A'),
              onError: (Object _) => assentadas.add('A'),
            ),
      );
      await _pump(10);

      // B nem chega a entrar: fica na fila da trava de escrita.
      unawaited(
        fd.write(Uint8List.fromList([1, 2, 3])).then(
              (_) => assentadas.add('B'),
              onError: (Object _) => assentadas.add('B'),
            ),
      );
      await _pump(10);
      expect(
        assentadas,
        isEmpty,
        reason: 'A presa na contrapressão e B presa atrás de A; se alguma '
            'tivesse assentado, o cenário não foi montado',
      );

      await fd.close();

      expect(
        assentadas,
        unorderedEquals(<String>['A', 'B']),
        reason: 'close espera pelas DUAS. B nunca adquiriu a trava, então sob '
            'a contagem de referências do upstream ela não seria contada e '
            'poderia notificar o chamador depois do teardown',
      );

      await servidor.fechar();
    });

    test('leitura estacionada é acordada pelo fechamento', () async {
      final servidor = await _ServidorMudo.abrir();
      servidor.aceitarSemLer();

      final raw = await RawSocket.connect('127.0.0.1', servidor.port);
      final fd = Fd(raw);

      Object? erroDaLeitura;
      var leituraTerminou = false;
      unawaited(
        fd.read().then((_) => leituraTerminou = true, onError: (Object e) {
          erroDaLeitura = e;
          leituraTerminou = true;
        }),
      );

      await _pump(10);
      expect(
        leituraTerminou,
        isFalse,
        reason: 'sem dados do par, a leitura tem de estar estacionada',
      );

      await fd.close();
      await _ate(() => leituraTerminou);
      expect(erroDaLeitura, isA<NetClosingException>());

      await servidor.fechar();
    });
  });

  group('Fd - estado após fechamento', () {
    test('operações novas falham de imediato com o sentinela', () async {
      final servidor = await _ServidorMudo.abrir();
      servidor.aceitarSemLer();
      final raw = await RawSocket.connect('127.0.0.1', servidor.port);
      final fd = Fd(raw);

      await fd.close();
      expect(fd.isClosed, isTrue);

      await expectLater(
        fd.write(Uint8List(4)),
        throwsA(isA<NetClosingException>()),
      );
      await expectLater(fd.read(), throwsA(isA<NetClosingException>()));
      await expectLater(
        fd.shutdown(SocketDirection.both),
        throwsA(isA<NetClosingException>()),
      );

      await servidor.fechar();
    });

    test('fechar duas vezes falha, como no upstream', () async {
      final servidor = await _ServidorMudo.abrir();
      servidor.aceitarSemLer();
      final raw = await RawSocket.connect('127.0.0.1', servidor.port);
      final fd = Fd(raw);

      await fd.close();
      await expectLater(
        fd.close(),
        throwsA(isA<NetClosingException>()),
        reason: 'FD.Close do Go devolve errClosing no segundo fechamento; '
            'isso difere do RawSocket.close() do dart:io, que é idempotente, '
            'e quem precisar de idempotência consulta isClosed antes',
      );

      await servidor.fechar();
    });
  });

  group('Fd - fim de leitura', () {
    test('read devolve vazio quando o par encerra a direção de envio', () async {
      final server = await ServerSocket.bind('127.0.0.1', 0);
      server.listen((socket) {
        socket.add(<int>[1, 2, 3]);
        socket.close();
      });

      final raw = await RawSocket.connect('127.0.0.1', server.port);
      final fd = Fd(raw);

      final primeiro = await fd.read();
      expect(primeiro, equals(Uint8List.fromList([1, 2, 3])));

      await _ate(() => fd.isReadClosed, motivo: 'readClosed do par');
      final segundo = await fd.read();
      expect(
        segundo,
        isEmpty,
        reason: 'lista vazia é o equivalente de io.EOF neste ponto do port',
      );

      await fd.close();
      await server.close();
    });
  });
}

/// Local, para não depender de dart:async só por causa de `unawaited`.
void unawaited(Future<void> future) {}

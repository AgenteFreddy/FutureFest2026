import '../models/usuario.dart';

/// Guarda o usuário logado enquanto o app está aberto.
/// O [usuarioId] é enviado em todas as requisições para carregar
/// apenas os idosos (tratamentos) e o estoque desse usuário.
class Sessao {
  Sessao._();

  static Usuario? usuarioAtual;

  static bool get logado => usuarioAtual != null;
  static int? get usuarioId => usuarioAtual?.id;

  static void entrar(Usuario usuario) => usuarioAtual = usuario;
  static void sair() => usuarioAtual = null;
}

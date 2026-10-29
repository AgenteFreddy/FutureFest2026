import '../models/usuario.dart';

class Sessao {
  Sessao._();

  static Usuario? usuarioAtual;

  static bool get logado => usuarioAtual != null;
  static int? get usuarioId => usuarioAtual?.id;

  static void entrar(Usuario usuario) => usuarioAtual = usuario;
  static void sair() => usuarioAtual = null;
}

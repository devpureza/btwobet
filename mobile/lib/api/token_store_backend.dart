/// Implementação padrão (nunca usada em runtime; só para análise estática).
class TokenStorageBackend {
  static Future<TokenStorageBackend> create() {
    throw UnsupportedError('Plataforma não suportada');
  }

  Future<String?> read() => throw UnsupportedError('Plataforma não suportada');

  Future<void> write(String token) => throw UnsupportedError('Plataforma não suportada');

  Future<void> clear() => throw UnsupportedError('Plataforma não suportada');
}

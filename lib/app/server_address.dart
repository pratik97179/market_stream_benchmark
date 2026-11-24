class ServerAddress {
  const ServerAddress({required this.host, required this.port});

  final String host;
  final int port;

  Uri websocketUri(String path, {Map<String, String>? query}) {
    return Uri(
      scheme: 'ws',
      host: host,
      port: port,
      path: path,
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  @override
  String toString() => '$host:$port';
}

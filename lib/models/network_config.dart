class NetworkConfig {
  final bool active;
  final String genesisHash;
  final int genesisTimestamp;
  final int lastG1V1BlockNumber;
  final List<String> rpc;
  final List<String> squid;

  NetworkConfig.fromJson(Map<String, dynamic> json)
      : active = json['active'] as bool,
        genesisHash = json['genesis_hash'] as String,
        genesisTimestamp = json['genesis_timestamp'] as int,
        lastG1V1BlockNumber = json['last_g1_v1_block_number'] as int,
        rpc = List<String>.from(json['rpc']),
        squid = List<String>.from(json['squid']);
}

class Tratamento {
  final int? id;
  final String paciente;
  final String medicamento;
  final String via;
  final String dose;
  final String frequencia;
  final String estoque;
  final String inicio;
  final String fim;
  final String obs;

  Tratamento({
    this.id,
    required this.paciente,
    required this.medicamento,
    required this.via,
    required this.dose,
    required this.frequencia,
    required this.estoque,
    required this.inicio,
    required this.fim,
    required this.obs,
  });

  factory Tratamento.fromJson(Map<String, dynamic> json) {
    return Tratamento(
      id: json['id'],
      paciente: json['paciente'] ?? '',
      medicamento: json['medicamento'] ?? '',
      via: json['via'] ?? '',
      dose: json['dose'] ?? '',
      frequencia: json['frequencia'] ?? '',
      estoque: json['estoque'] ?? '',
      inicio: json['inicio'] ?? '',
      fim: json['fim'] ?? '',
      obs: json['obs'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paciente': paciente,
      'medicamento': medicamento,
      'via': via,
      'dose': dose,
      'frequencia': frequencia,
      'estoque': estoque,
      'inicio': inicio,
      'fim': fim,
      'obs': obs,
    };
  }
}

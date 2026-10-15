class RemedioEstoque {
  final int? id;
  final String medicamento;
  final String quantidade;
  final String via;
  final String dataValidade;
  final String observacoes;

  RemedioEstoque({
    this.id,
    required this.medicamento,
    required this.quantidade,
    required this.via,
    required this.dataValidade,
    required this.observacoes,
  });

  factory RemedioEstoque.fromJson(Map<String, dynamic> json) {
    return RemedioEstoque(
      id: json['id'],
      medicamento: json['medicamento'] ?? '',
      quantidade: json['quantidade'] ?? '',
      via: json['via'] ?? '',
      dataValidade: json['data_validade'] ?? '',
      observacoes: json['observacoes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'medicamento': medicamento,
      'quantidade': quantidade,
      'via': via,
      'data_validade': dataValidade,
      'observacoes': observacoes,
    };
  }
}

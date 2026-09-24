import 'package:flutter/material.dart';

Widget buildTextField(String entradaNome, TextEditingController controle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: entradaNome,
        ),
        controller: controle,
      ),
    ),
  );
}

Widget buildButton(
  BuildContext context,
  String entradaNome,
  Widget telaDestino,
  VoidCallback enviar,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        child: Text(entradaNome),
        onPressed: () {
          enviar();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => telaDestino),
          );
        },
      ),
    ),
  );
}

Widget actionItem(
  IconData icon,
  String text,
  Color iconColor,
  VoidCallback onTap, {
  bool isOutlined = false,
  Color? textColor,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildLembretes() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lembretes',
          style: TextStyle(
            fontSize: 22,
            color: Color(0xFF0050A0),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Nenhum lembrete cadastrado.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

Widget patientRow(String imagePath, String name, String subtitle, String time) {
  return Row(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300,
        child: ClipOval(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
      Text(
        time,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

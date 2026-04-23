class Validators {
  const Validators._();

  static String? minLength(String? value, int min, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label é obrigatório';
    }
    if (value.trim().length < min) {
      return '$label deve ter no mínimo $min caracteres';
    }
    return null;
  }
}

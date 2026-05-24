String formatPrice(double price) {
  if (price % 1 == 0) {
    return '€${price.toStringAsFixed(0)}';
  }
  return '€${price.toStringAsFixed(2)}';
}

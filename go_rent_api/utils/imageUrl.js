// Ubah image_url dari database menjadi URL yang bisa langsung dipakai Image.network di Flutter.
// - URL online (diawali http) dikembalikan apa adanya.
// - Path relatif (misalnya images/cars/1_1.jpg) diubah menjadi URL penuh sesuai host request,
//   sehingga tetap benar dari localhost, 10.0.2.2 (emulator), maupun ngrok.
export function toImageUrl(req, imageUrl) {
  if (!imageUrl) return null;
  if (imageUrl.startsWith('http')) return imageUrl;
  const path = imageUrl.replace(/^\/+/, '');
  return `${req.protocol}://${req.get('host')}/${path}`;
}

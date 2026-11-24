# car_images.json — URL foto mobil GO-RENT

Salin isi blok JSON di bawah ke file `go_rent_api/database/car_images.json`. Key = `car_id` (sesuai `data rental.txt`), value = daftar URL foto (0 sampai 3). Semua foto dari Wikimedia Commons; sumber dan lisensinya ada di `sumber_foto_mobil.md`.

Cek dulu beberapa URL di browser. Kalau ada yang tidak muncul, ganti URL-nya atau kosongkan daftarnya (`[]`), aplikasi akan menampilkan gambar simulasi.

```json
{
  "1": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2021_Toyota_Avanza_1.5_G_Toyota_Safety_Sense_%28Indonesia%29_front_view_03.jpg?width=960"
  ],
  "2": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2022_Hyundai_Creta_Prime_%28Indonesia%29_front_view.jpg?width=960"
  ],
  "3": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2023_Honda_Brio_RS_%28Indonesia%29_front_view.jpg?width=960"
  ],
  "4": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2021_Mitsubishi_Pajero_Sport_2.4_Dakar_4x2_%28Indonesia%29_front_view_01.jpg?width=960"
  ],
  "5": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2019_Suzuki_Ertiga_GX_%28Indonesia%29_front_view.jpg?width=960"
  ],
  "6": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2020_Toyota_Fortuner_2.4_VRZ_TRD_Sportivo_4x2_GUN165R_%2820220215%29.jpg?width=960"
  ],
  "7": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/Daihatsu_Rocky_Premium_2WD_%285BA-A200S-GBVV%29_front.jpg?width=960"
  ],
  "8": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2022_Honda_HR-V_1.5_SE_RV3_%2820220807%29.jpg?width=960"
  ],
  "9": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2019_Toyota_Alphard_%28AH30_facelift%29_2.5_G%2C_Batu_City.jpg?width=960"
  ],
  "10": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/Wuling_Air_EV_IMG005.jpg?width=960"
  ],
  "11": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2020_Nissan_Kicks_e-Power_VL.jpg?width=960"
  ],
  "12": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/Mazda_CX-5_25S_Silk_Beige_Selection_%286BA-KF5P%29_front.jpg?width=960"
  ],
  "13": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2022_Toyota_Kijang_Innova_Zenix_V_%28Indonesia%29_front_view.jpg?width=960"
  ],
  "14": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2022_Honda_Civic_RS_1.5_FE1_%2820220317%29_02.jpg?width=960"
  ],
  "15": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2022_Daihatsu_Xenia_1.3_R_W100RG_%2820220506%29.jpg?width=960"
  ],
  "16": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/BMW_320i_M_Sport_%28G20%29_front.jpg?width=960"
  ],
  "17": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2021_Toyota_Raize_1.0T_G_%28Indonesia%29_front_view.jpg?width=960"
  ],
  "18": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2023_Isuzu_MU-X_3.0_Ultimate_4WD_Phantom_Collection.jpg?width=960"
  ],
  "19": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/BMW_MINI_COOPER_S_3DOOR_%28F56%29_front.jpg?width=960"
  ],
  "20": [
    "https://commons.wikimedia.org/wiki/Special:FilePath/2021_Toyota_Veloz_1.5_Q_%28Indonesia%29_front_view.jpg?width=960"
  ]
}
```

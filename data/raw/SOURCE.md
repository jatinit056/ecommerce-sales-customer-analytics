# Raw data — source and provenance

| Item | Detail |
|---|---|
| Dataset | **Brazilian E-Commerce Public Dataset by Olist** |
| Publisher | Olist (Kaggle account `olistbr`) |
| Kaggle page | https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce |
| License | CC BY-NC-SA 4.0, as listed on the Kaggle page (attribution, non-commercial, share-alike). Check the Kaggle page before any commercial use. |
| Description | ~100K real, anonymised orders from 2016–2018 placed on Olist, a marketplace that connects small Brazilian sellers to large online sales channels. Split into 8 related tables (orders, customers, items, payments, reviews, products, sellers, category translation). |
| Retrieved | 22 October 2026 |

## How the files were obtained

Kaggle could not be reached from the environment used to build this project, so the files were downloaded from two
independent public GitHub mirrors of the Kaggle dataset and **compared with each other**:

| Mirror | Commit |
|---|---|
| https://github.com/spdrio/Brazilian-E-Commerce-Public-Dataset-by-Olist (folder `files/`) | `fa0cc6d1aff713d3c8b9a1e633b56889881848bf` |
| https://github.com/dujiaying/olist (folder `data/`) | `96d0db2e45e684d5a7069911368d823a19e82d38` |

7 of the 8 files are **byte-for-byte identical** in both mirrors (same SHA-256). The 8th file
(`product_category_name_translation.csv`) has identical values and differs only in line endings (LF vs CRLF).
The file in this folder comes from the first mirror. If you download the dataset from Kaggle yourself, you can compare
it with the checksums below.

## Files (kept exactly as downloaded — never edited)

| File | Rows (excl. header) | SHA-256 |
|---|---|---|
| `olist_customers_dataset.csv` | 99,441 | `983a422239e1712ded753b3bf9ecf47dc73f144d306029dcfa99e70a226883d2` |
| `olist_order_items_dataset.csv` | 112,650 | `0bc4d068c4fe38cbb01bd90e8746e3c613fe7b4baef75fab7b0e329701c3e279` |
| `olist_order_payments_dataset.csv` | 103,886 | `4f713964f2815dbbaa40b9488268c55aac3627bfce5aa96cf58d1f3616de3cc0` |
| `olist_order_reviews_dataset.csv` | 100,000 | `0dff69f6fed33a13648020198ea94d7ae12afbdd4904186c6cd904e27a3e1ccd` |
| `olist_orders_dataset.csv` | 99,441 | `8df58ef3d2d7e9944010f7beecd9b75367f5588ec6e3c91cec19ae3345ef9ecf` |
| `olist_products_dataset.csv` | 32,951 | `3e6569628a17fbc75fd206ee357b59e20364b9afa90f5b6cd5b4d624c58aa9cc` |
| `olist_sellers_dataset.csv` | 3,095 | `1f643d2b950373b85735e7794b20986f528d7a000432e7c6f9bcbb44d0846a0e` |
| `product_category_name_translation.csv` | 71 | `9da093e114e517534d7a6903b253b0d24a582830b99ea9e8ef48a90b79d60967` |

`olist_geolocation_dataset.csv` (1M rows of zip-code coordinates) is part of the Kaggle dataset but is not used in
this analysis, so it is not included.

The files are read-only in this folder. All cleaning happens in the notebook and writes to `data/cleaned/`.

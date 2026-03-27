# 🌍👥 *MigLingDiv*

MigLingDiv provides a framework to analyze how migration shapes linguistic diversity.  
It computes **imported linguistic entropy**, summarizing the diversity of a country’s migration stock by weighting each origin country’s linguistic diversity according to its share of migrants. This measure is built on **bilateral migration stock data and country-level linguistic diversity**. 
The repository includes underlying data (with placeholders where required), the scripts used for computation, the resulting imported entropy outcomes, and the regression analyses.


## 📁 Repository Structure

### 📂 `data/`

Includes the raw and intermediate datasets used to construct the final dataset, as well as the final dataset itself.

Due to licensing restrictions, some datasets are provided as **placeholders** instead of the original data.

- **`raw/`**
  - `migration_stock.xlsx`  
  - `m49toIso.xlsx`  
  - `isocodes.xlsx`
  - `speakers_global_placeholder.csv`  

- **`intermediate/`**
  - `migration_stock_long.csv`  
  - `entropy_country.csv`
  - 
- **`final/`**
  - `imported_entropy.csv`    

---

### 💻 `scripts/`

Contains all scripts used to process the data and generate the final dataset:

- `01_reshape_migration_stock.R`  
- `02_compute_entropy.R`  
- `03_compute_imported_entropy.R`  
- `04_regression_models.R`  

---

## ⚠️ Data Restrictions

Some source datasets used in this project are subject to licensing restrictions and cannot be redistributed, including:

- Ethnologue data (language-level speaker counts and language-level digital support scale)  

To ensure reproducibility, **placeholder files** are included in this repository.

---

## 📜 License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)** license.
The included migration_stock.xlsx dataset is used under its original license: United Nations Department of Economic and Social Affairs, Population Division (2024). International Migrant Stock 2024: Destination and origin, © 2024 United Nations, available under CC BY 3.0 IGO
.
## 🎓 Acknowledgments
This research was funded by WWTF (grant numberICT23-012). It is a part of the  [DIGILINGDIV project](https://digiling.univie.ac.at/digilingdiv/).


## 📬 Contact
If you have any questions about the code or analysis, feel free to contact: **katharina.zeh@univie.ac.at**

library(dplyr)
library(tidyr)
library(readxl)
library(stringr)

# this script computes weighted (imported) entropy of migration for each destination-year
# by combining origin shares and their Shannon entropy values.



# load data
mig <- read.csv("../data/intermediate/entropy_countrymigration_stock_long.csv") %>%
  rename_with(~ tolower(trimws(.)))
entropy <- read.csv("../data/intermediate/entropy_countryentropy_country.csv") %>%
  rename_with(~ tolower(trimws(.)))

# compute total migrant stock per destination-year
# (sum over all origins for each destination)
total_in <- mig %>%
  group_by(iso_dest, year) %>%
  summarise(total_destination = sum(count), .groups = "drop")

# compute each origin's share of the destination's migrant stock
share_in <- mig %>%
  inner_join(total_in, by = c("iso_dest","year")) %>%
  # drop destination-years with zero inflow (shares undefined)
  filter(total_destination > 0) %>%
  mutate(share = count / total_destination)


# attach shannon entropy of origin countries
entropy_share <- share_in %>%
  left_join(entropy %>% select(country_code, entropy_origin = shannon_entropy),
            by = c("iso_origin" = "country_code"))


# compute imported (weighted) entropy per destination-year
# each origin contributes to the destination's entropy proportional to its share
# coverage indicates what fraction of the destination's stock is included in the entropy calculation (optional)
entropy_share <- entropy_share %>%
  group_by(iso_dest, year) %>%
  mutate(
    covered      = !is.na(entropy_origin),
    weight_sum   = sum(share[covered], na.rm = TRUE),        # sum of shares with known H
    share_norm   = ifelse(covered & weight_sum > 0, share / weight_sum, NA_real_)
  ) %>%
  summarise(
    imp_entropy = sum(share_norm * entropy_origin, na.rm = TRUE),
    coverage_M  = sum(count[covered], na.rm = TRUE) / first(total_destination),
    .groups = "drop"
  )


# reshape to wide format (one row per destination) and add static entroyp
Imp_wide_ent <- entropy_share %>%
  pivot_wider(
    id_cols = iso_dest,
    names_from = year,
    values_from = c(imp_entropy, coverage_M),
    names_glue = "{.value}_{year}"
  ) %>%
  left_join(
    df2 %>%
      select(country_code, country, shannon_entropy) %>%
      distinct(country_code, .keep_all = TRUE),
    by = c("iso_dest" = "country_code")
  )

# write file 
write.csv(Imp_wide_ent, "../data/final/imported_entropy.csv")





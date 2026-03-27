library(dplyr)
library(entropy)


#### this script normalizes speaker(i.e. population) counts to compute probability distributions 
# and computes richness, shannon entropy, shannon exponent, and total speaker counts on the country-level 

# define path for global speaker counts
speaker_path <- "../data/raw/speakers_global_placeholder.csv"

if (!file.exists(speaker_path)) {
  speaker_path <- "../data/raw/speakers_global_placeholder.csv"
  message("Using placeholder data (full dataset not included).")
}

# load speaker data 
speaker_glob <- read_csv(
  speaker_path,
  na = c("", "NULL")
) %>%
  rename_with(~ tolower(trimws(.)))

# normalize counts by total speaker counts for each country
speaker_glob <- speaker_glob %>%
  group_by(country_code) %>%
  mutate(
    population_total = sum(population, na.rm = TRUE), #compute total speaker population per country
    probability = population / population_total
  ) %>%
  ungroup()



#### compute entropy and its exponent, richness and total speaker counts
entropy_country <- speaker_glob %>%
  group_by(country_code, country) %>%
  summarize(
    shannon_entropy  = entropy(population_norm),
    exponent_shannon = exp(shannon_entropy),
    total_speakers   = first(population_total),
    richness         = n_distinct(iso6393),
    .groups = "drop"
  )


# write file 
write.csv(entropy_country, "../data/intermediate/entropy_country.csv")



#### Setup Environment and Load Data ####

# Load Required Libraries 
library(readxl)
library(dplyr)
library(stringr)
library(tidyr)
library(writexl)

# Read dfs 
df <- read_excel("migrant_flow.xlsx") %>%
  rename_with(~ tolower(trimws(.)))
df2 <- read_excel("M49toIso.xlsx") %>%
  rename_with(~ tolower(trimws(.)))
df3 <- read_excel("isocodes.xlsx") %>%
  rename_with(~ tolower(trimws(.)))


year_cols <- c("1990","1995","2000","2005","2010","2015","2020","2024")

# Remove * from country names 
df <- df %>%
  mutate(
    origin = str_trim(str_remove_all(origin, "\\*")),
    destination = str_trim(str_remove_all(destination, "\\*"))
  )

# Filter for countries based on M49 code 
df_countries_only <- df %>%
  filter(
    location_code_origin < 900,
    location_code_destination < 900
  )

# Map M49_code to Isocode Alpha-3

df2 <- df2 %>% select(m49_code, iso_code)


# Join destination ISO_3
df_countries_only <- df_countries_only %>%
  left_join(df2, by = c("location_code_destination" = "m49_code")) %>%
  rename(alpha3_destination = iso_code)

# Join origin ISO_3
df_countries_only <- df_countries_only %>%
  left_join(df2, by = c("location_code_origin" = "m49_code")) %>%
  rename(alpha3_origin = iso_code)

# Step 1: Remove location code columns
df_countries_only <- df_countries_only %>%
  select(-location_code_origin, -location_code_destination)

View(df_countries_only)

# check missing values (=0)

# total count of zeros
n_zeros <- sum(df_countries_only == 0, na.rm = TRUE)

# total count of numeric values (non-NA)
n_values <- sum(!is.na(df_countries_only) & sapply(df_countries_only, is.numeric)[col(df_countries_only)])

# proportion
prop_zeros <- n_zeros / n_values

n_zeros
n_values
prop_zeros

# Map Isocode Alpha-3 to Alpha-2

df3 <- df3 %>% select(alpha3, alpha2)

# Join destination ISO_2
df_countries_only <- df_countries_only %>%
  left_join(df3, by = c("alpha3_destination" = "alpha3")) %>%
  rename(alpha2_destination = alpha2)

# Join origin ISO_2
df_countries_only <- df_countries_only %>%
  left_join(df3, by = c("alpha3_origin" = "alpha3")) %>%
  rename(alpha2_origin = alpha2)


# Step 2: Reorder columns so ISO codes follow the corresponding country columns
df_countries_only <- df_countries_only %>%
  relocate(alpha2_origin, .after = origin) %>%
  relocate(alpha3_origin, .after = alpha2_origin)

df_countries_only <- df_countries_only %>%
  relocate(alpha2_destination, .after = destination) %>%
  relocate(alpha3_destination, .after = alpha2_destination)

# Keep only the columns we need + the year columns
flows_wide <- df_countries_only %>%
  select(
    dest        = destination,
    iso_dest     = alpha2_destination,
    origin      = origin,
    iso_origin   = alpha2_origin,
    all_of(year_cols)
  )


# reshape years into (year, count)
flows_long <- flows_wide %>%
  pivot_longer(
    cols        = all_of(year_cols),
    names_to    = "year",
    values_to   = "count",
    values_drop_na = FALSE  # keep NA so you can decide how to handle
  ) %>%
  mutate(
    year  = as.integer(year),
    count = suppressWarnings(as.numeric(count))
  )

View(flows_long)
write.csv(df_countries_only, "migration_iso.csv")
write.csv(flows_long, "migration_iso_long.csv")



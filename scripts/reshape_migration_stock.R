library(readxl)
library(dplyr)
library(stringr)
library(tidyr)

#### this script cleans and reshapes UN migration stock data: adds ISO codes, 
# and converts to long format with one row per origin–destination–year.

# load data
mig <- read_excel("../data/raw/migrant_stock.xlsx", sheet = "Sheet1") %>%
  rename_with(~ tolower(trimws(.)))
m49 <- read_excel("../data/raw/m49toIso.xlsx") %>%
  rename_with(~ tolower(trimws(.)))
iso <- read_excel("../data/raw/isocodes.xlsx") %>%
  rename_with(~ tolower(trimws(.)))


# remove * from country names 
mig <- mig %>%
  mutate(
    origin = str_trim(str_remove_all(origin, "\\*")),
    destination = str_trim(str_remove_all(destination, "\\*"))
  )

#### add ISO codes ####

# filter for countries based on m49 code 
df_countries_only <- mig %>%
  filter(
    location_code_origin < 900,
    location_code_destination < 900
  )

## step 1 map m49_code to ISO code alpha-3

m49 <- m49 %>% select(m49_code, iso_code)


# join destination ISO_3
df_countries_only <- df_countries_only %>%
  left_join(m49, by = c("location_code_destination" = "m49_code")) %>%
  rename(alpha3_destination = iso_code)

# join origin ISO_3
df_countries_only <- df_countries_only %>%
  left_join(m49, by = c("location_code_origin" = "m49_code")) %>%
  rename(alpha3_origin = iso_code)

# remove location code columns
df_countries_only <- df_countries_only %>%
  select(-location_code_origin, -location_code_destination)


# step 2 map ISO alpha-3 to alpha-2

iso <- iso %>% select(alpha3, alpha2)

# join destination ISO_2
df_countries_only <- df_countries_only %>%
  left_join(iso, by = c("alpha3_destination" = "alpha3")) %>%
  rename(alpha2_destination = alpha2)

# join origin ISO_2
df_countries_only <- df_countries_only %>%
  left_join(iso, by = c("alpha3_origin" = "alpha3")) %>%
  rename(alpha2_origin = alpha2)

#### reshape the df ####

# reorder columns so ISO codes follow the corresponding country columns
df_countries_only <- df_countries_only %>%
  relocate(alpha2_origin, .after = origin) %>%
  relocate(alpha3_origin, .after = alpha2_origin)

df_countries_only <- df_countries_only %>%
  relocate(alpha2_destination, .after = destination) %>%
  relocate(alpha3_destination, .after = alpha2_destination)

# keep only the columns we need + the year columns

# select years
year_cols <- c("1990","1995","2000","2005","2010","2015","2020","2024")

# convert to wide format
stock_wide <- df_countries_only %>%
  select(
    dest        = destination,
    iso_dest     = alpha2_destination,
    origin      = origin,
    iso_origin   = alpha2_origin,
    all_of(year_cols)
  )


# convert to long format based on wide format
stock_long <- stock_wide %>%
  pivot_longer(
    cols        = all_of(year_cols),
    names_to    = "year",
    values_to   = "count",
    values_drop_na = FALSE  
  ) %>%
  mutate(
    year  = as.integer(year),
    count = suppressWarnings(as.numeric(count))
  )

write.csv(stock_long, "../data/intermediate/migration_stock_long.csv")



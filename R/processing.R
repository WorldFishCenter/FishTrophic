#' Get comprehensive fish data from FishBase for specified countries
#'
#' This function retrieves and combines fish species data from multiple FishBase
#' tables for one or more countries. It returns information about freshwater and
#' brackish water species including occurrence, ecological, nutritional, and
#' disease data.
#'
#' @param country_codes A character vector of country codes (C_Code values from
#'   FishBase). Can be a single code or multiple codes. Default is "566" (Nigeria).
#' @param include_saltwater Logical. Whether to include saltwater species.
#'   Default is FALSE (only freshwater and brackish water species).
#' @param native_only Logical. Whether to include only native species.
#'   Default is TRUE.
#'
#' @return A data frame containing the following columns:
#' \describe{
#'   \item{SpecCode}{FishBase species code}
#'   \item{species_name}{Scientific name (Genus + Species)}
#'   \item{UsedforAquaculture}{Whether species is used for aquaculture}
#'   \item{VulnerabilityClimate}{Climate vulnerability index}
#'   \item{Status}{Native/introduced status}
#'   \item{CurrentPresence}{Current presence status}
#'   \item{FoodTroph}{Food-based trophic level}
#'   \item{DietTroph}{Diet-based trophic level}
#'   \item{DisCode}{Disease code}
#'   \item{Prevalence}{Disease prevalence}
#'   \item{Intensity}{Disease intensity}
#'   \item{K}{Growth parameter K}
#'   \item{Calcium}{Calcium content}
#'   \item{Iron}{Iron content}
#'   \item{Omega3}{Omega-3 fatty acid content}
#'   \item{Protein}{Protein content}
#'   \item{VitaminA}{Vitamin A content}
#'   \item{Zinc}{Zinc content}
#' }
#'
#' @details
#' The function performs the following operations:
#' \enumerate{
#'   \item Retrieves species information from the FishBase species table
#'   \item Filters occurrence data for the specified country codes
#'   \item Excludes saltwater species (unless include_saltwater = TRUE)
#'   \item Joins additional data tables: countries, ecology, diseases, and estimates
#'   \item Filters for native species only (unless native_only = FALSE)
#' }
#'
#' @examples
#' \dontrun{
#' # Get data for Marshall Islands (default)
#' marshall_fish <- get_fishbase_data()
#'
#' # Get data for multiple countries
#' pacific_fish <- get_fishbase_data(c("566", "585", "242"))
#'
#' # Include saltwater species
#' all_fish <- get_fishbase_data("566", include_saltwater = TRUE)
#'
#' # Include both native and introduced species
#' all_status_fish <- get_fishbase_data("566", native_only = FALSE)
#' }
#'
#' @importFrom rfishbase fb_tbl
#' @importFrom dplyr mutate select filter left_join distinct
#' @importFrom magrittr %>%
#' @importFrom purrr reduce
#' @importFrom rlang .data
#'
#' @export
get_fishbase_data <- function(
  country_codes = "566",
  include_saltwater = FALSE,
  native_only = TRUE
) {
  # Input validation
  if (!is.character(country_codes) || length(country_codes) == 0) {
    stop("country_codes must be a non-empty character vector")
  }

  # Load required libraries
  if (!requireNamespace("rfishbase", quietly = TRUE)) {
    stop("Package 'rfishbase' is required but not installed.")
  }

  # Get species table with combined species names
  species_tab <-
    rfishbase::fb_tbl("species") %>%
    dplyr::mutate(species_name = paste(.data$Genus, .data$Species)) %>%
    dplyr::select(
      "SpecCode",
      "species_name",
      "UsedforAquaculture",
      "Fresh",
      "Brack",
      "Saltwater",
      "VulnerabilityClimate",
      "Importance",
      "PriceCateg"
    ) %>%
    dplyr::distinct()

  # Get occurrence data for specified countries
  occurrence_tab <-
    rfishbase::fb_tbl("occurrence") %>%
    dplyr::filter(.data$C_Code %in% country_codes) %>%
    dplyr::select("SpecCode") %>%
    dplyr::left_join(species_tab, by = "SpecCode") %>%
    dplyr::filter(!is.na(.data$SpecCode))

  # Filter by water type if specified
  if (!include_saltwater) {
    occurrence_tab <- occurrence_tab %>%
      dplyr::filter(.data$Saltwater == 0)
  }

  occurrence_tab <- occurrence_tab %>%
    dplyr::select(
      "SpecCode",
      "species_name",
      "UsedforAquaculture",
      "VulnerabilityClimate",
      "Importance",
      "PriceCateg"
    ) %>%
    dplyr::distinct()

  # Get country-specific information
  countries_tab <-
    rfishbase::fb_tbl("country") %>%
    dplyr::filter(
      .data$C_Code %in% country_codes,
      .data$SpecCode %in% unique(occurrence_tab$SpecCode)
    ) %>%
    dplyr::select("SpecCode", "Status") %>%
    dplyr::distinct()

  # Get trophic level information
  trophic_tab <-
    rfishbase::fb_tbl("ecology") %>%
    dplyr::select("SpecCode", "FoodTroph", "DietTroph", "FeedingType") %>%
    dplyr::mutate(
      feeding_guild = dplyr::case_when(
        .data$FeedingType %in% c("grazing on aquatic plants") ~ "herbivore",
        .data$FeedingType %in%
          c("filtering plankton", "selective plankton feeding") ~ "planktivore",
        .data$FeedingType %in%
          c(
            "plants/detritus+animals (troph. 2.2-2.79)",
            "variable"
          ) ~ "omnivore",
        .data$FeedingType %in% c("hunting macrofauna (predator)") ~ "carnivore",
        .data$FeedingType %in%
          c(
            "browsing on substrate",
            "sucking food-containing material"
          ) ~ "detritivore",
        .data$FeedingType %in%
          c(
            "feeding on dead animals (scavenger)",
            "feeding on the prey of a host (commensal)",
            "picking parasites off a host (cleaner)",
            "feeding on a host (parasite)"
          ) ~ "specialist",
        .data$FeedingType %in% c("other", NA) ~ "uncertain",
        TRUE ~ "uncertain"
      ),

      feedability = dplyr::case_when(
        .data$feeding_guild %in% c("herbivore", "omnivore") ~ "high",
        .data$feeding_guild %in% c("planktivore", "carnivore") ~ "medium",
        .data$feeding_guild %in% c("detritivore") ~ "low",
        .data$feeding_guild %in% c("specialist", "uncertain") ~ "very_low",
        TRUE ~ "unknown"
      )
    ) %>%
    dplyr::distinct() %>%
    dplyr::select(-"FeedingType")

  # Get disease information
  disease_tab <-
    rfishbase::fb_tbl("diseases") %>%
    dplyr::select("SpecCode", "DisCode", "Prevalence", "Intensity") %>%
    dplyr::filter(.data$SpecCode %in% unique(occurrence_tab$SpecCode)) %>%
    dplyr::distinct()

  # Get nutritional estimates
  estimates_tab <-
    rfishbase::fb_tbl("estimate") %>%
    dplyr::select(
      "SpecCode",
      "Calcium",
      "Iron",
      "Omega3",
      "Protein",
      "VitaminA",
      "Zinc"
    ) %>%
    dplyr::filter(.data$SpecCode %in% unique(occurrence_tab$SpecCode)) %>%
    dplyr::distinct()

  growth_tab <-
    rfishbase::popgrowth() |>
    dplyr::select(
      "SpecCode",
      "K",
      w_inf = "Winfinity"
    ) %>%
    dplyr::filter(.data$SpecCode %in% unique(occurrence_tab$SpecCode)) %>%
    dplyr::distinct()

  # Combine all data tables
  all_dat <-
    list(
      occurrence_tab,
      countries_tab,
      trophic_tab,
      disease_tab,
      estimates_tab,
      growth_tab
    ) %>%
    purrr::reduce(dplyr::left_join, by = "SpecCode")

  # Filter by native status if specified
  if (native_only) {
    all_dat <- all_dat %>%
      dplyr::filter(.data$Status == "native")
  }

  return(all_dat)
}

#' Calculate Aquaculture Nutritional Index
#'
#' Creates a simple nutritional index (0-1) for aquaculture based on
#' macronutrients (protein) and key micronutrients (Fe, Zn, Ca, Vit A, Omega3).
#'
#' @param data Data frame containing columns: Calcium, Iron, Omega3, Protein, VitaminA, Zinc
#'
#' @return Data frame with added 'aquaculture_index' column (0-1 scale)
#'
#' @details
#' Index weights: Protein (40%), Iron/Zinc/Calcium/VitaminA/Omega3 (12% each)
#'
#' @examples
#' \dontrun{
#' fish_with_index <- calculate_aquaculture_index(fish_data)
#' }
#'
#' @export
calculate_aquaculture_index <- function(data) {
  # Scale function
  scale_it <- function(x) {
    (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
  }

  # Scale each variable
  data$aquaculture_index <-
    0.40 *
    scale_it(data$Protein) +
    0.12 * scale_it(data$Iron) +
    0.12 * scale_it(data$Zinc) +
    0.12 * scale_it(data$Calcium) +
    0.12 * scale_it(data$VitaminA) +
    0.12 * scale_it(data$Omega3)

  return(data)
}

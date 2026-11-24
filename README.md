# fishtrophic

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Code that searches FishBase for native freshwater and brackish-water fish
that feed low in the food chain, grow well and are rich in nutrients.

**See the results:** [Analysis notebook](analysis/trophics.md), with the
code and the chart.

## What it is

This is the first data analysis on how indigenous
low-trophic fish could contribute to Africa's Blue Transformation.
Low-trophic fish feed near the bottom of the food chain, for example on
plants, algae or plankton. The analysis compares each species' trophic
level, growth and nutrient content, and shows whether it is already farmed.

## What it produces

- A table of native freshwater and brackish-water species for the chosen
  countries, with their trophic level, feeding type, growth, nutrient
  content, diseases, climate vulnerability, price category and whether
  FishBase records them as used in aquaculture.
- A **growth-yield index** for each species: its growth rate (K) multiplied
  by its maximum weight (W∞) to the power 0.75. It combines how fast a
  species grows with how heavy it can get, without letting very large
  species look unrealistically productive.
- A **nutritional index** from 0 to 1 for each species. Protein counts for
  40%, and iron, zinc, calcium, vitamin A and omega-3 for 12% each.
- A chart of trophic level against the growth-yield index. Point size shows
  the nutritional index and colour shows aquaculture use.

## Where the data comes from

All data comes from [FishBase](https://www.fishbase.org), read through the
[rfishbase](https://github.com/ropensci/rfishbase) R package: species
occurrence by country, native status, ecology, diseases, nutrient
estimates and population growth. The notebook currently runs on every
country in FishBase.

Known limits:

- The nutritional index ranks species against each other in the same run.
  It is not an amount of nutrients, and it changes when the set of species
  changes.
- Species missing any of the values used (trophic level, growth, nutrients,
  importance or price category) are left out.
- When FishBase has several growth estimates for a species, the first one
  is used.

## For developers

The code is an R package called `fishtrophic`. It needs R 4.1 or later,
and [Quarto](https://quarto.org) to render the notebook.

- [`R/processing.R`](R/processing.R): `get_fishbase_data()` builds the
  species table and `calculate_aquaculture_index()` computes the
  nutritional index.
- [`analysis/trophics.qmd`](analysis/trophics.qmd): the analysis. It
  renders to [`analysis/trophics.md`](analysis/trophics.md).

### Setup

``` r
# install.packages("remotes")
remotes::install_github("WorldFishCenter/fishtrophic")
```

To work on the code, clone the repository and run:

``` r
devtools::install_deps(dependencies = TRUE)
devtools::load_all()
```

### Main commands

``` r
devtools::document()  # after editing roxygen comments; man/ is committed
devtools::check()
```

``` sh
quarto render analysis/trophics.qmd
```

Rendering downloads the FishBase tables the first time, so it takes a few
minutes. Commit the rendered `analysis/trophics.md` and
`analysis/trophics_files/` so the results show on GitHub. Rendering also
writes `analysis/trophics.html`, a single file to share by email; it is
not committed.

### Releases

Bump `Version:` in `DESCRIPTION` and add a block at the top of
[`NEWS.md`](NEWS.md) headed `# fishtrophic X.Y.Z`, written for
non-technical readers. For AI-assisted work, see [`CLAUDE.md`](CLAUDE.md).

## Licence

See [`LICENSE.md`](LICENSE.md). FishBase data keeps its own licence;
see [fishbase.org](https://www.fishbase.org).

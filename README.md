# barometreweb

A Nim package to load, filter and summarize the "Barometre des prix de creation de site web en France 2026" dataset: 103 public price observations covering website creation, e-commerce, blogs, redesigns, bespoke development and monthly SEO offers in France.

## Installation

```
nimble install barometreweb
```

## Usage

```nim
import barometreweb

# Load the dataset embedded in the package at compile time.
let records = loadEmbedded()
echo records.len

# Or download the latest published version of the CSV over HTTP.
let fresh = fetchLatest()

# Filter by category, provider type, pricing model or region.
let vitrines = byCategory(records, "vitrine")
let freelanceOnly = byProviderType(records, "freelance")
let monthly = byPricingModel(records, "abonnement_mensuel")
let paris = byRegion(records, "Paris")

# List the distinct values available for each dimension.
echo categories(records)
echo providerTypes(records)
echo pricingModels(records)
echo regions(records)

# Compute summary statistics for one numeric price field.
let s = stats(vitrines, "prix_typique_eur")
echo s.count, " ", s.min, " ", s.median, " ", s.mean, " ", s.max
```

## Fields

Each `PriceRecord` mirrors one row of the CSV:

- `categorie_prestation`: service category (vitrine, ecommerce, blog, refonte, seo_mensuel, sur_mesure).
- `type_prestataire`: provider type (freelance, agence_guide, builder_saas).
- `pricing_model`: pricing model (forfait_unique, abonnement_mensuel, tjm).
- `prix_min_eur`, `prix_max_eur`, `prix_typique_eur`: minimum, maximum and typical price in euros.
- `region`: "France" for a national price, or a city name for a local price.
- `source_categorie`: short label of the source (a specific plan, guide or barometer).
- `source_url`: URL of the source page.
- `date_releve`: date the price was recorded.
- `notes`: free-text context for the observation.

`stats` accepts a `field` argument (`prix_min_eur`, `prix_max_eur` or `prix_typique_eur`, default `prix_typique_eur`) and returns count, min, max, median and mean.

## Data source and license

The dataset is published by Les Creavores under CC BY 4.0. See the barometer page for context and methodology: https://lescreavores.fr/prix-creation-site-internet/

The raw CSV file used by `fetchLatest` lives at: https://raw.githubusercontent.com/tresor4k/barometre-prix-web-fr/main/data/barometre-prix-creation-site-web-france-2026.csv

The package code (everything outside the `data/` folder) is licensed under MIT. See `LICENSE`.

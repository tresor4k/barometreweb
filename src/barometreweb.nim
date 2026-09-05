## barometreweb
## ============
##
## Load, filter and summarize the "Barometre des prix de creation de site
## web en France 2026" dataset: 103 observations of website-creation and
## SEO prices in France, published by Les Creavores under CC BY 4.0.
##
## The dataset can be used either embedded at compile time (`loadEmbedded`)
## or downloaded fresh over HTTP (`fetchLatest`).

import std/streams
import std/parsecsv
import std/strutils
import std/algorithm
import std/httpclient

type
  PriceRecord* = object
    ## One row of the dataset. All price fields are in euros; every other
    ## field is kept as the raw string from the CSV.
    categorie_prestation*: string
    type_prestataire*: string
    pricing_model*: string
    prix_min_eur*: float
    prix_max_eur*: float
    prix_typique_eur*: float
    region*: string
    source_categorie*: string
    source_url*: string
    date_releve*: string
    notes*: string

  Stats* = object
    ## Summary statistics for one numeric price field across a set of
    ## records. `count` is 0 and all other fields are 0.0 when the input
    ## sequence is empty.
    count*: int
    min*: float
    max*: float
    median*: float
    mean*: float

const
  DefaultDatasetUrl* =
    "https://raw.githubusercontent.com/tresor4k/barometre-prix-web-fr/main/data/barometre-prix-creation-site-web-france-2026.csv"
    ## Public raw URL of the dataset CSV on GitHub.

  embeddedCsv = staticRead("../data/barometre-prix-creation-site-web-france-2026.csv")
    ## Dataset CSV embedded at compile time (103 observations).

proc parseCsv*(content: string): seq[PriceRecord] =
  ## Parses CSV text that has the dataset's exact header
  ## (categorie_prestation,type_prestataire,pricing_model,prix_min_eur,
  ## prix_max_eur,prix_typique_eur,region,source_categorie,source_url,
  ## date_releve,notes) into a sequence of PriceRecord. Blank lines are
  ## ignored. Price fields accept decimal values, for example 16.80.
  result = @[]
  var stream = newStringStream(content)
  var parser: CsvParser
  parser.open(stream, "barometreweb.csv", separator = ',', quote = '"')
  parser.readHeaderRow()
  while parser.readRow():
    var hasContent = false
    for field in parser.row:
      if field.len > 0:
        hasContent = true
        break
    if not hasContent:
      continue
    var rec: PriceRecord
    rec.categorie_prestation = parser.rowEntry("categorie_prestation")
    rec.type_prestataire = parser.rowEntry("type_prestataire")
    rec.pricing_model = parser.rowEntry("pricing_model")
    rec.prix_min_eur = parseFloat(parser.rowEntry("prix_min_eur"))
    rec.prix_max_eur = parseFloat(parser.rowEntry("prix_max_eur"))
    rec.prix_typique_eur = parseFloat(parser.rowEntry("prix_typique_eur"))
    rec.region = parser.rowEntry("region")
    rec.source_categorie = parser.rowEntry("source_categorie")
    rec.source_url = parser.rowEntry("source_url")
    rec.date_releve = parser.rowEntry("date_releve")
    rec.notes = parser.rowEntry("notes")
    result.add(rec)
  parser.close()

proc loadEmbedded*(): seq[PriceRecord] =
  ## Returns the dataset embedded in this package at compile time
  ## (103 observations). Use this when network access is not available or
  ## not desired.
  parseCsv(embeddedCsv)

proc fetchLatest*(url = DefaultDatasetUrl): seq[PriceRecord] =
  ## Downloads the dataset CSV from `url` (the public GitHub raw file by
  ## default) and parses it. Requires network access; not exercised by the
  ## test suite.
  var client = newHttpClient()
  let content = client.getContent(url)
  client.close()
  result = parseCsv(content)

proc byCategory*(records: seq[PriceRecord]; value: string): seq[PriceRecord] =
  ## Returns the records whose categorie_prestation equals `value` exactly.
  result = @[]
  for rec in records:
    if rec.categorie_prestation == value:
      result.add(rec)

proc byProviderType*(records: seq[PriceRecord]; value: string): seq[PriceRecord] =
  ## Returns the records whose type_prestataire equals `value` exactly.
  result = @[]
  for rec in records:
    if rec.type_prestataire == value:
      result.add(rec)

proc byPricingModel*(records: seq[PriceRecord]; value: string): seq[PriceRecord] =
  ## Returns the records whose pricing_model equals `value` exactly.
  result = @[]
  for rec in records:
    if rec.pricing_model == value:
      result.add(rec)

proc byRegion*(records: seq[PriceRecord]; value: string): seq[PriceRecord] =
  ## Returns the records whose region equals `value` exactly, for example
  ## "France" or a city name such as "Lyon".
  result = @[]
  for rec in records:
    if rec.region == value:
      result.add(rec)

proc categories*(records: seq[PriceRecord]): seq[string] =
  ## Returns the distinct categorie_prestation values found in `records`,
  ## sorted alphabetically.
  var seen: seq[string] = @[]
  for rec in records:
    if rec.categorie_prestation notin seen:
      seen.add(rec.categorie_prestation)
  seen.sort()
  result = seen

proc providerTypes*(records: seq[PriceRecord]): seq[string] =
  ## Returns the distinct type_prestataire values found in `records`,
  ## sorted alphabetically.
  var seen: seq[string] = @[]
  for rec in records:
    if rec.type_prestataire notin seen:
      seen.add(rec.type_prestataire)
  seen.sort()
  result = seen

proc pricingModels*(records: seq[PriceRecord]): seq[string] =
  ## Returns the distinct pricing_model values found in `records`, sorted
  ## alphabetically.
  var seen: seq[string] = @[]
  for rec in records:
    if rec.pricing_model notin seen:
      seen.add(rec.pricing_model)
  seen.sort()
  result = seen

proc regions*(records: seq[PriceRecord]): seq[string] =
  ## Returns the distinct region values found in `records`, sorted
  ## alphabetically.
  var seen: seq[string] = @[]
  for rec in records:
    if rec.region notin seen:
      seen.add(rec.region)
  seen.sort()
  result = seen

proc stats*(records: seq[PriceRecord]; field = "prix_typique_eur"): Stats =
  ## Computes count, min, max, median and mean for one numeric price field
  ## across `records`. `field` must be one of "prix_min_eur",
  ## "prix_max_eur" or "prix_typique_eur"; any other value falls back to
  ## "prix_typique_eur". Returns a zero-valued Stats when `records` is
  ## empty.
  result = Stats(count: 0, min: 0.0, max: 0.0, median: 0.0, mean: 0.0)
  if records.len == 0:
    return result
  var values: seq[float] = @[]
  for rec in records:
    case field
    of "prix_min_eur":
      values.add(rec.prix_min_eur)
    of "prix_max_eur":
      values.add(rec.prix_max_eur)
    else:
      values.add(rec.prix_typique_eur)
  values.sort()
  let n = values.len
  result.count = n
  result.min = values[0]
  result.max = values[n - 1]
  var total = 0.0
  for v in values:
    total += v
  result.mean = total / float(n)
  if n mod 2 == 1:
    result.median = values[n div 2]
  else:
    result.median = (values[n div 2 - 1] + values[n div 2]) / 2.0

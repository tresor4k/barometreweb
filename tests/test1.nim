import std/unittest
import barometreweb

suite "barometreweb":

  test "loadEmbedded returns exactly 103 records":
    let records = loadEmbedded()
    check records.len == 103

  test "all six expected categories are present":
    let records = loadEmbedded()
    let cats = categories(records)
    let expected = ["blog", "ecommerce", "refonte", "seo_mensuel", "sur_mesure", "vitrine"]
    for cat in expected:
      check cat in cats
    check cats.len == 6

  test "provider type counts match the dataset":
    let records = loadEmbedded()
    check byProviderType(records, "freelance").len == 40
    check byProviderType(records, "builder_saas").len == 36
    check byProviderType(records, "agence_guide").len == 27

  test "stats on a category are internally consistent":
    let records = loadEmbedded()
    let vitrine = byCategory(records, "vitrine")
    let s = stats(vitrine)
    check s.count > 0
    check s.min <= s.median
    check s.median <= s.max

  test "parseCsv handles a quoted field containing a comma":
    let sample = "categorie_prestation,type_prestataire,pricing_model,prix_min_eur,prix_max_eur,prix_typique_eur,region,source_categorie,source_url,date_releve,notes\n" &
      "vitrine,freelance,forfait_unique,500,2000,1000,France,guide,https://example.com,2026-06-11,\"Site simple, livre en 5 jours\"\n"
    let records = parseCsv(sample)
    check records.len == 1
    check records[0].notes == "Site simple, livre en 5 jours"

# Findings: Data Science Tool Mastery Project

*City analysed: **Albany, New York** (Inside Airbnb detailed listings, 500 listings). Every number below comes from the executed notebooks in `notebooks/`.*

---

## Case 01: The Messy Evidence
- **Rows before → after cleaning:** 500 → 457 (91.4% kept).
- **Columns with the most missing data:** `host_since`, `host_response_rate` and `instant_bookable` are **100% empty** in this city's file. Next: `review_scores_rating` (10.2%), `price` (6.6%), `beds` (1.4%), `minimum_nights` (0.2%).
- **Cleaning decisions that mattered most:**

| Step | Rows affected | Reason |
|---|---|---|
| Dropped: no price | 33 | No price means no use for pricing analysis |
| Dropped: price outside the 1st–99th percentile ($37 to $4,823) | 10 (2.1%) | Extreme listings would dominate averages and the model |
| Flagged: `has_reviews` | 41 of the 457 clean listings have no rating | "Never reviewed" is information, so I kept the NaN and added a flag |
| Filled: `beds` | up to 7 | Used `accommodates / 2`, rounded (simple, documented assumption) |
| Skipped: `host_tenure_years` | all rows | `host_since` is empty, so tenure cannot be calculated |

- **One thing I got wrong first:** I left `CITY_CENTRE` set to Amsterdam while analysing Albany, so "distance from centre" averaged 5,707 km. I now sanity-check it (the notebook stops if the median distance is over 50 km), and the corrected average is 2.3 km.
- **Market snapshot:** 327 entire homes (median $167/night), 129 private rooms (median $76) and 1 shared room. 184 listings (40.3%) are entire homes for 4+ guests. Only 7 wards have 30 or more listings; the Second Ward has the highest median price ($188) and the Eleventh Ward the lowest average rating (4.21).

## Case 02: The Interrogation
Price is strongly right-skewed (skewness 3.82; 0.32 after a log transform), so I used medians and non-parametric tests.

| Claim | Test used | Result | Effect size | Verdict |
|-------|-----------|--------|-------------|---------|
| Superhosts charge more | Mann–Whitney U + bootstrap CI | p = 0.0007 | Median $154 vs $128; difference 95% CI [$3.0, $45.5] | **Supported.** Holds within room types (+$19.9 entire homes, +$12.0 private rooms) and in all four guest-capacity bands, so it is not just bigger homes. The wide interval reflects the small sample. |
| Closer to centre = pricier | Spearman | rho = −0.152, p = 0.001 | Weak (about 2% of the variation in price ranks) | **Supported, but weak.** Albany is compact, so distance explains little. |
| Price differs by room type | Kruskal–Wallis (entire homes vs private rooms) | H = 148.3, p ≈ 4×10⁻³⁴ | Median $167 vs $76 | **Strongly supported.** The single shared-room listing was excluded. |

*Caution: these are associations. The data cannot show that becoming a Superhost causes higher prices.*

## Case 03: The Exhibit Wall
- **Strongest chart and its one-line takeaway:** Exhibit A. In 2024 per-person emissions were about 14.2 t in the US, 8.7 t in China, 6.8 t in Germany, 4.5 t in the UK, 2.3 t in Brazil and 2.2 t in India, and China's line passed Germany's around 2020.
- **Wealth vs emissions (2021, 164 countries):** log GDP per person and log CO₂ per person correlate at r = 0.91.
- **A chart I rebuilt and why it improved:** Exhibit A's legend originally sat on top of the Germany and US lines, so I moved it outside the plot area.
- Figures: `reports/figures/A_co2_per_capita.png`, `B_gdp_vs_co2.png`, `C_emissions_heatmap.png`

## Case 04: The Prediction Room
Predicting log nightly price. 365 training rows, 92 test rows, 5-fold cross-validation on the training data only.

| Model | CV RMSE (log) | Test RMSE (log) | Test MAE (per night) | R² |
|-------|---------------|-----------------|----------------------|----|
| Baseline (median) | 0.600 ± 0.035 | 0.575 | $80.42 | −0.003 |
| Ridge | 0.356 ± 0.013 | not tested | not tested | not tested |
| Random Forest (chosen) | 0.319 ± 0.025 | 0.254 | $38.63 | 0.805 |
| Gradient Boosting | 0.328 ± 0.031 | not tested | not tested | not tested |

*By design only the baseline and the cross-validation winner touch the test set.*

- **Top features by permutation importance:** `accommodates` (0.221), `minimum_nights` (0.095), `room_type` (0.032), then `dist_centre_km` (0.029) and `bedrooms` (0.019).
- **Where the model fails and why:** it is most accurate on cheap listings (mean error $14.7 for the cheapest 20%) and least accurate on the priciest 20% (mean error $97.6), where there are few examples to learn from.
- **Reading these numbers honestly:** the test set is only 92 listings, and the test RMSE (0.254) is better than the cross-validation RMSE (0.319), so the split may have been favourable. Random Forest and Gradient Boosting differ by less than one standard deviation, so I cannot say one is truly better. The large role of `minimum_nights` may reflect long-stay listings being priced differently, but I haven't tested that.
- **What the model cannot see:** photos, listing descriptions, host reputation beyond a few numbers, and the season.

## Case 05: The Records Office
- **Top revenue country / genre / customer:** USA (about 523 from 13 customers) / Rock (35.5% of revenue) / Helena Holý of the Czech Republic has the highest lifetime value of any country's top customer (49.62).
- **Most surprising SQL finding:** monthly revenue is almost perfectly flat (about 37.6 in each of the first 12 months), a sign that Chinook is a teaching sample rather than real trading data. The unsold-track counts are also dominated by the biggest catalogues (Rock 552, Latin 239), so a share-based measure would be fairer.

## Case 06: The Briefing Room
- **Dashboard link or screenshots:** `dashboard/airbnb_dashboard.pbix` and `dashboard/screenshots/Market_Pulse.png` and `dashboard/screenshots/what_drives_price.png`. Pages 1–2 (Market Pulse and What Drives Price) are built; pages 3–4 are planned.
- **Headline numbers on the page:** 457 listings, median price $144, average rating 4.74, 47% Superhosts, average availability 261 days. Of the 457 listings, 327 are entire homes, 129 are private rooms and 1 is a shared room.
- **What page 2 shows:** median price rises with guest capacity, but the priciest capacity groups have very few listings, so their medians are fragile. Distance from the centre shows no clear pattern in the scatter, consistent with the weak Spearman result in Case 02. The shared-room listing is excluded from the room-type chart for that reason. In the decomposition tree, median price climbs from about $64 (1 guest) to $118 (2), $160 (4) and $195 (5); within 4-guest listings private rooms ($181) sit above entire homes ($160), which I read as small-sample noise, not a pattern.
- **Three decisions this dashboard could support:** (1) a host comparing their nightly price with the ward and room-type median; (2) a city planner spotting which wards have the densest short-term-rental supply; (3) a prospective host choosing between listing an entire home or a private room, based on how the market splits.

---

## Overall recommendations
1. **Price by guest capacity first.** `accommodates` is by far the most important feature in the model, ahead of room type and location.
2. **Treat Superhost status as worth pursuing, with caution.** Superhosts' median price is higher within every room type and capacity band, but this data shows association, not cause.
3. **Don't over-invest in location in a compact market.** Distance from the centre has only a weak link to price in Albany (rho = −0.15), so ward-level and listing-level details matter more.

## Limitations and next steps
- Only 500 listings (457 after cleaning), so confidence intervals are wide and only 7 wards have 30 or more listings.
- Three host columns are empty in this city's file, so host tenure and instant-booking could not be used.
- One shared-room listing, so room-type comparisons cover entire homes and private rooms only.
- Prices are asking prices from a single snapshot, so seasonality and actual booked prices are not captured.
- Next: repeat the analysis on a larger city to test whether the findings hold, tune the models, and build dashboard pages 3–4 (Host and Quality, Model Lens).

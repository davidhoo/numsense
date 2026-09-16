# Spoken number content inventory

Companion to [PRD.md](./PRD.md). Authoring rules for scripts, variants, visuals, and distractors. Product decisions stay in the PRD.

## Encoding tags

Put one on every slot:

| Tag | Meaning | Examples |
| --- | --- | --- |
| `seq` | Digit sequence, held in chunks | phone, ZIP, 4-digit code |
| `mag` | Magnitude / quantity | $48, 20 minutes, 2.5 lb, 13.2 gal, 70 mph |
| `hyb` | Hybrid ID (digits + place or letter) | room 402, gate C18, 3:15 |

## Error traps (distractor source)

A 4-option set is **1 correct + 3 distractors from different traps**. Never three teen/ty clones. Prefer “would look right if you only held one slot.”

On multi-slot items, **one distractor should be a cross-slot intrusion** (another number from the same sentence).

| Trap | Typical swap |
| --- | --- |
| `teen-ty` | 13/30, 14/40, 15/50, 16/60, 17/70, 18/80, 19/90 |
| `oh-vs-hundred` | 402 vs 42 vs 4002; 4:05 vs 4:50 |
| `scale` | $4.50 / $450 / $4.05; 2.5 lb / 25 lb / 2.5 gal; minutes vs hours |
| `order` | March 5 vs May 3; 12:15 vs 1:12 |
| `neighbor` | 18 vs 19 vs 8 |
| `chunk-merge` | 10:45 + gate 12 → 10:12 |
| `letter-number` | C18 / A18 / G18; 7B / B7 |
| `ampm` | 7:30 AM vs 7:30 PM |
| `a-vs-one` | a quarter vs 1:15 |
| `cross-slot-intrusion` | room number offered as the time, etc. |

## Spoken form (never digit-feed TTS)

TTS is a voice, not a number reader. Each item has:

- `value` — structured, used for visuals and scoring  
- `spokenText` — the only string sent to the engine, written as a person would say it  

**Reject** any catalog row whose TTS input still contains raw digits in clock/money/room/gate form (`402`, `3:15`, `C18`, `$12.99`). Expand them in the authoring step.

Phone / ZIP / OTP may be spoken **digit-wise** because that is American (`five five five, oh one two three`). That is still authored words plus pauses, not `555-0123` dropped into the API.

### Recipes (same value → several readings)

Use **oh** for zero in rooms, times, addresses, and casual codes. Use **zero** when someone is being careful (OTP, confirmation).

| Value | Default American | Also ship | Do not use as the only form |
| --- | --- | --- | --- |
| 3:00 | three / three o’clock / three p.m. | fifteen hundred *(Travel)* | “three colon zero zero” |
| 3:05 | three oh five | five after three; five past three | three zero five as default |
| 3:15 | three fifteen | a quarter after three; a quarter past three | fifteen past *(British-ish)* |
| 3:30 | three thirty | half past three | half three |
| 3:45 | three forty-five | a quarter to four | a quarter of four as default |
| 3:50 | three fifty | ten to four | — |
| 12:00 | noon / midnight (disambiguate) | twelve o’clock | — |
| 20 min | twenty minutes | twenty | — |
| 90 min | an hour and a half | ninety minutes; an hour thirty | — |
| Mar 5 | March fifth | March five; three five | “March five slash …” |
| 402 | four oh two | four hundred two; four zero two | TTS default for `402` |
| 1010 | ten ten | one oh one oh | one thousand ten |
| 7B | seven B | — | B seven as the only form |
| $2.50 | two fifty | two dollars and fifty cents | two point five oh |
| $4.50 | four fifty | four dollars and fifty cents | **$450-sounding dump** |
| $19.99 | nineteen ninety-nine | nineteen dollars and ninety-nine cents | nineteen point nine nine |
| $20 | twenty; a twenty | twenty dollars | two zero |
| C18 | C eighteen | C one eight | “C eighteen” only, never “C one eight” in the bank |
| 218 (flight) | two eighteen | two one eight | two hundred eighteen as default |
| 1420 Oak | fourteen twenty Oak | — | one four two zero |
| 94107 | nine four one oh seven | ninety-four, one oh seven | ninety-four thousand… |
| 555-0123 | five five five, oh one two three | — | five hundred fifty-five… |
| last four 1234 | one two three four | twelve thirty-four | twelve hundred thirty-four |
| 72° | seventy-two; seventy-two degrees | — | seven two |
| 20% | twenty percent; twenty percent off | — | two zero percent |
| 12 (count) | twelve; a dozen | — | one two |
| 2.5 lb | two and a half pounds | two point five pounds | two point five *(no unit)* |
| 0.5 lb | half a pound | eight ounces | point five pounds as default |
| 180 lb | a hundred and eighty pounds | one eighty | one eight zero |
| 48 lb bag | forty-eight pounds | — | 48 kilos unless script is luggage kg |
| 23 kg | twenty-three kilos | twenty-three kilograms | twenty-three pounds |
| 13.2 gal | thirteen point two gallons | about thirteen gallons | thirteen two / $13.20 |
| $3.49/gal | three forty-nine a gallon | three forty nine a gallon | three point four nine |
| 2.4 mi | two point four miles | about two and a half miles | two forty |
| 70 mph | seventy miles an hour | seventy | seventeen / seventy-five |
| 32 PSI | thirty-two PSI | thirty-two pounds | thirteen two |
| I-80 | interstate eighty | eighty | eighteen |
| 101 | one-oh-one | one hundred one | I-10 |
| exit 12B | exit twelve B | — | 12 vs B12 gate |

### Authoring checks

1. If you can paste the TTS field into a browser and it still looks like a spreadsheet cell (`3:15`, `402`), rewrite it.  
2. Across the bank, each major family must appear in **at least two spoken patterns** (colon-style time vs quarter/half; oh-room vs hundred; money as “X fifty” vs “dollars and cents”; gate as eighteen vs one-eight; weight as “and a half” vs “point five”; fuel as “point two gallons” vs “about thirteen gallons”).  
3. SSML `<break>` between phone/ZIP chunks is allowed. Character-by-character “spell” mode is not.

## v1 production rules

- Conversational General American. No slow ESL. No British defaults (`half three`, `nought`).
- **Hand-write `spokenText`.** Never send raw digits/codes to TTS; see Spoken form above.
- Clock times on a **5-minute grid** (`3:15`, not `3:17`) as *values*; the audio says `three fifteen`, not `3:15`.
- US daily clock is **12-hour**; 24-hour (`fifteen hundred`) only inside Travel scripts.
- Canonical keys are structured values, never the spoken words. Good: `{ "hour": 15, "minute": 15 }`. Bad: `"three fifteen"`.
- Phone in v1: **4-digit codes** and **7-digit local in two pauses**. Not a 10-digit wall in one step.
- Mixed items: hard cap **4 slots**. Distractor cards change **one field**.

## Category notes

### Time
High-frequency: `three fifteen`, `a quarter after three`, `three thirty` / `half past three`, `three oh five`, `three fifty`.  
Distractors: 3:15 vs 3:50 vs 3:30 vs 1:15; 4:05 vs 4:50.

### Duration
`twenty minutes`, `half an hour`, `an hour and a half`, `an hour forty`.  
Do not use a clock face for duration. Trap: 1:30 duration vs 1:30 o’clock.

### Date
American month-first. `March fifth`, `Thursday, March fifth`, `three five`.  
Ordinals that must appear: 1st, 2nd, 3rd, 5th, 12th, 13th, 15th, 20th, 21st, 30th, 31st.  
Trap: 13th/30th, 3/5 vs 5/3, wrong weekday.

### Money
`$X.00`, `$X.50`, `$X.99`, `$X.05`; `two fifty` vs `two dollars and fifty cents`; `nineteen ninety-nine`.  
Always show `$` on the card. Trap: $4.50 / $450 / $4.05; 15% / 50% / $15.

### Room / floor
`four oh two` (default), also `four hundred two`, `four zero two`. Letter suffix `seven B`.  
Trap: 402 / 412 / 420 / 42; 7B / B7 / 17B; 13th vs 14th floor.

### Travel
`gate C eighteen` vs `C one eight`; `flight two eighteen`; `terminal two`; `interstate eighty`; `exit twelve B`; parking `P two` / space `one fourteen`.  
Highest-value traps: C18 / C80 / A18; 218 / 280; 10:45 vs 10:15 vs gate 10; I-80 vs 18 vs I-8; 101 vs 10.

### Phone / codes
Last four as digits **or** as `twelve thirty-four` (time-like lure). Extension `two oh three`.  
Trap: 0123 / 1023; last-four 1234 vs 12:34.

### Address / ZIP
`fourteen twenty Oak`, `four oh two Main`, ZIP `nine four one oh seven`.  
Numbered streets (`sixteenth`) are in-scope; arbitrary street *names* stay on the visual.

### Measures (count, weight, fuel, miles, speed, …)
Produce: `two and a half pounds`, `half a pound`.  
Luggage: `forty-eight pounds` / airport `twenty-three kilos`.  
Gym / body: `one eighty`, `one thirty-five on the bar`.  
Pump: `thirteen point two gallons`, `three forty-nine a gallon`.  
Road: `two point four miles`, `seventy miles an hour`, `thirty-two PSI`.  
Still include °F, `% off`, aisle, `a dozen`.  
Card must show the unit. Trap: 2.5 lb vs 25 lb vs 2.5 gal; gallons vs the dollar total.

No Celsius, no liters as the default pump, no height (`five eight`), no recipe cups/tablespoons (domain explosion). Fuel may use tenths (`point two`); grocery weight may use `and a half` / `point five`.

### Mixed (do not cut)
Hotel: time + room + floor.  
Airport: flight + gate + time.  
Desk: weekday/date + time + window.  
Receipt: total + tip% (v1 can speak three, test two).  
Gas: $/gal + gallons + total.  
Grocery: pounds + price.  
Highway: route + exit + miles.

## Out of v1

Credit cards, SSN, unchunked digit span > 4, noisy PA, overlapping speakers, NATO alphabet PNRs, relative dates (`a week from Tuesday`), British/military as the default clock, seconds, Celsius, liters-as-default, recipe fractions, height, typing/ASR.

## Build order (implementation)

1. Clock colon-style + teen/ty + 12:15/12:50  
2. Money `$X.50` vs `$X50` vs `$X.15`  
3. Room `four oh two`  
4. Gate `C eighteen`  
5. Date weekday + ordinal  
6. Duration  
7. 4-digit codes + 7-digit phone  
8. House number + ZIP  
9. Measures: °F, % off, pounds, gallons, miles, mph  
10. Mixed: airport, hotel, receipt, **then gas / grocery / highway**  

v1 is not done until step 10 exists, even if earlier categories have more items.

## Volume

About **150–250 unique clips** covering every category, including **≥20 mixed** (40 is a stretch goal, not a gate). Repeat values with different phrasings; do not repeat identical scripts. A clip returning a week later is intended.

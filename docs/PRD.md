# NumSense PRD

**Product:** NumSense（数字语感）  
**Platform:** iOS 27, iPhone 17 Pro, personal self-signed app  
**UI language:** English  
**Audio language:** Conversational American English  
**Status:** v1 specification after requirements clarification  
**Date:** 2026-09-16

---

## 1. Problem

The user can **decode** spoken English numbers—times, money, dates, room numbers, gates—but the value does not become usable information. A second later it is gone, or it only sticks after an internal detour through Chinese.

This is not a vocabulary problem and not a math problem. It is a **sound → information encoding** problem: working memory never gets a stable, English-native representation.

NumSense trains number *sense*: hear once, keep it as information—not a digit dictation drill, and not an arithmetic trainer.

## 2. Goal

After hearing one everyday American-English sentence, the user can **hold the numbers as information** long enough to recognize them in a visual form (clock, calendar, door plate, gate sign, price tag, etc.).

Success looks like: hear “your room is four oh two,” then pick the door that says 402—without replaying, without translating into Chinese, without typing the digits.

## 3. Locked decisions

| Topic | Decision |
| --- | --- |
| Replay | Not during the question. After a wrong answer only. |
| Wrong-answer feedback | Immediately highlight the correct visual, then replay the audio. |
| v1 scenarios | Cover **all** everyday number situations: time, date, money, rooms, travel, phone, address, **and measures** (weight, fuel, miles, speed, …), plus mixed real-world sentences. |
| Audio | Premium American neural TTS, pre-generated. **TTS is only a voice.** Scripts are hand-written spoken American English, never raw digits like `402` / `3:15` / `C18` fed to the engine. |
| Option UI | SwiftUI-drawn graphics. Must be readable at a glance. Not photos, not illustration packs. |
| App chrome | English. Options themselves are visual; labels on chrome can be short English. |
| Clock style | Setting: analog or digital. Default **digital** (the retained information is the time value). Analog is a harder optional encoding. |
| Training log | Every slot attempt is stored locally, forever (device), for stats, review, and export. |
| Export | User-initiated Share Sheet: full JSON plus a flat CSV. No account, no automatic upload. |

## 4. Design principles

1. **Information, not English.** Options are pictures of the world (a clock, a door). The user is not tested on spelling, transcription, or Chinese glosses.
2. **One listen to commit.** The first play is the trial. Replay is feedback, not a crutch.
3. **Quiz the slots, not the sentence.** If a line contains several numbers, ask them one after another. Each step: four visuals, one correct, three distractors.
4. **Distract like real mistakes.** Each 4-pack: one phonological twin when it applies (13/30, 15/50, 12:15/12:50), plus **different** traps for the other two—never three clones of the same error. On multi-slot items, one option is a **cross-slot intrusion** (another number from the same sentence).
5. **American speech as it is actually said — and diversified.** Same value, several spoken forms (`four oh two` / `four hundred two`; `three fifteen` / `a quarter after three`; `two fifty` / `two dollars and fifty cents`). Never let TTS “just read the digits.”
6. **Options appear after the audio ends.** Showing choices while the clip plays lets the user match without encoding.
7. **Log the trial, not a summary number.** First-listen correctness, latency, slot index, chosen distractor, and settings at the time are what later analysis needs. A single “80% today” is not enough.

## 5. Core loop

```
Start session
  → pick a random item (optionally filtered by scenario)
  → play audio once
  → brief pause (**1.0s** default; this is the retention gap)
  → for each numeric slot in order:
        show 2×2 visual options
        tap one
        if correct: short confirm, next slot (or next item)
        if wrong: lock options, highlight correct, replay audio once, then continue
  → session summary (accuracy by scenario, hard pairs)
```

No replay button on the question screen.  
No transcript of the sentence during the trial.  
After the item is finished, the sentence text may appear in the review row (optional, collapsed by default) so the user can see what was said—**only after** answering.

## 6. Session shape (daily personal use)

- Default session: **12 items**, mixed scenarios, ~5–8 minutes.
- An item with 3 slots still counts as 1 item; all slots are scored.
- Settings: 8 / 12 / 20 items; optional scenario filter (All, or one category).
- v1 does not auto-schedule spaced repetition. It **does** keep a full attempt log so you can review misses and later bias toward weak categories.
- A session tagged **Review** (from missed items) is logged separately from a normal mixed session.

## 7. Content model

An **item** is one utterance plus the numbers it contains.

```
Item
  id
  scenario            // time, date, money, room, travel, phone, address, measures, mixed
  text                // spokenText: fully expanded words sent to TTS. Never "402" or "3:15".
  audioFile           // bundled m4a/caf
  notes               // spoken variant + encoding tag: seq | mag | hyb
  trapTags[]          // teen-ty, oh-vs-hundred, scale, …
  slots[]             // 1..n, asked in order
    Slot
      id
      role            // "clock", "duration", "date", "weekday", "amount", "room", "gate", ...
      visual          // clock, calendar, door, gate, price, phone, address, scale, pump, speedo, …
      value           // canonical structured value
      distractors[3]  // structured values, same visual type
```

Canonical values are structured, not display strings:

- Time: `{ hour: 15, minute: 10 }` (always 24h internally; display follows analog/digital setting and 12/24h setting).
- Date: `{ year?, month, day, weekday? }`.
- Money: `{ dollars: 19, cents: 99, currency: "USD" }`.
- Room: `{ number: "402" }` (string, because of leading zeros and suites like 12A).
- Gate: `{ letter: "C", number: 18 }`.
- Phone: stored as digit string; asked in **chunks** (v1: 4-digit code, or 7-digit local as two groups). Not a 10-digit wall.
- Address: `{ streetNumber, zip? }` as separate slots when both are spoken.
- Weight: `{ amount: 2.5, unit: "lb" }` (oz / kg when the script says so).
- Fuel: `{ gallons: 13.2 }` or `{ dollars: 3, cents: 49, per: "gallon" }`.
- Distance / speed / pressure: `{ miles: 2.4 }`, `{ mph: 70 }`, `{ psi: 32 }`.

### 7.1 Spoken form (hard rule)

The catalog stores a structured **value** and a separate **spokenText**. Only `spokenText` is sent to TTS.

**Never** pass numerals, clock notation, currency, or codes to the engine:

| Value | Forbidden TTS input | Why |
| --- | --- | --- |
| 402 | `402`, `room 402` | Engines say “four hundred two” or “four zero two,” not hotel “four oh two.” |
| 3:15 | `3:15`, `15:15` | Risk of “three colon one five” or 24h digit dump. |
| C18 | `C18`, `gate C18` | Often “C eighteen” vs we also need “C one eight.” |
| $12.99 | `$12.99`, `12.99` | Often “twelve point nine nine,” not “twelve ninety-nine.” |
| 13.2 gal | `13.2`, `13.2 gal` | Often “thirteen point two” without “gallons,” or a dollar amount. |

Write the words a clerk would say. Cover **variant types** across the bank (not every variant on every item):

| Family | Must appear in v1 | Also useful |
| --- | --- | --- |
| Time 3:15 | three fifteen; a quarter after / past three | quarter past; three fifteen p.m. |
| Time 3:05 | three oh five; five after three | five past three |
| Time 3:30 | three thirty; half past three | — |
| Time 3:45 | three forty-five; a quarter to four | — |
| Time 3:00 | three; three o’clock; three p.m. | fifteen hundred (Travel only) |
| Room 402 | four oh two | four hundred two; four zero two |
| Money $2.50 | two fifty | two dollars and fifty cents |
| Money $19.99 | nineteen ninety-nine | nineteen dollars and ninety-nine cents |
| Gate C18 | C eighteen | C one eight |
| Flight 218 | two eighteen | two one eight |
| Address 1420 | fourteen twenty | — (not “one four two zero”) |
| Weight 2.5 lb | two and a half pounds | two point five pounds |
| Weight 180 lb | a hundred and eighty pounds | one eighty |
| Fuel 13.2 gal | thirteen point two gallons | about thirteen gallons |
| $3.49 / gal | three forty-nine a gallon | three dollars and forty-nine cents a gallon |
| 70 mph | seventy miles an hour | seventy |
| Date Mar 5 | March fifth | March five; three five |
| Last four 1234 | one two three four **and** twelve thirty-four | — |
| Zero | **oh** as default | zero when careful / codes |

Phone, ZIP, and OTP **are** often said digit-wise in American English. That is still a **chosen** pattern (`five five five, oh one two three`), with pauses, not “dump the string `555-0123` into TTS.” Mix in grouped readings where Americans actually group them (`twelve thirty-four`, `two oh three`).

Full tables: [content-inventory.md](./content-inventory.md).

### 7.2 Coverage, not combinatorics

v1 does **not** need every variant for every value. It needs **every variant type** to appear in the bank. Same 3:15 may be “three fifteen” in one clip and “a quarter after three” in another. Identical `spokenText` should not be recorded twice.

## 8. Scenario catalog (v1)

v1 ships **all** of these. Mixed items (hotel check-in, airport, restaurant) stitch several slots into one sentence. Scripts, spoken variants, and trap tables: [content-inventory.md](./content-inventory.md).

Clock times use a **5-minute grid**. Phone in v1 is 4-digit codes and 7-digit local **in chunks**, not a 10-digit wall.

### 8.1 Time

| Role | Example script | Visual | Typical slots |
| --- | --- | --- | --- |
| Clock time | “It’s ten forty-five.” | Clock | 1 |
| Appointment | “Your appointment is at two thirty this afternoon.” | Clock | 1 |
| Duration | “The meeting runs for forty-five minutes.” | Duration chip (45:00 or “45 min”) | 1 |
| Open hours | “We’re open from nine to six.” | Two clocks, two steps | 2 |
| Relative | “Your table will be ready in twenty minutes.” | Duration | 1 |

**Visual:** SwiftUI clock. Digital = large digits + AM/PM if 12h. Analog = hour/minute hands, no second hand, optional minute marks.

**Distractors:** teen/ty (1:30 vs 1:13), 12:15 vs 12:50, hour ±1, AM/PM flip when the script contains afternoon/morning/p.m.

### 8.2 Date and weekday

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| Full date | “Today is March fifth.” | Calendar card | 1 |
| Date + weekday | “Today is Tuesday, March fifth.” | Calendar (date then weekday, or one card with both asked as two steps) | 2 |
| Numeric date | “That’s three five twenty-six.” (American M/D/Y) | Calendar | 1–2 |
| Deadline | “Your return is on the twenty-first.” | Calendar (day of month) | 1 |

**Visual:** Desk calendar / monthly card: month name, big day number, weekday abbreviation.

**Distractors:** month/day swap (March 5 vs May 3), adjacent day, 13th vs 30th, weekday ±1.

### 8.3 Money

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| Price | “That’s twelve ninety-nine.” | Price tag | 1 |
| Precise | “Nineteen dollars and forty-five cents.” | Price tag | 1 |
| Tip / total | “With tip that’s sixty-four fifty.” | Receipt line | 1 |
| Change | “Your change is three seventy-five.” | Cash / receipt | 1 |
| Bill split | “That’s forty-two dollars for two people.” | Receipt (amount, then count) | 2 |

**Visual:** Price tag or short receipt. `$12.99` with dollar sign. No long prose.

**Distractors:** $12.99 vs $12.90 vs $29.12 vs $1,299; “twelve ninety-nine” vs 12.19; dollars/cents swap.

### 8.4 Room, floor, door

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| Room | “Your room number is four oh two.” | Hotel door | 1 |
| Floor + room | “That’s the twelfth floor, room twelve fifteen.” | Elevator plate then door | 2 |
| Suite / letter | “You’re in suite nine B.” | Door (9B) | 1 |
| Meeting room | “We’re in conference room twenty-one.” | Door / plaque | 1 |

**Visual:** Door with a plate. Large, high-contrast numbers. Optional tiny “ROOM” above, English.

**Distractors:** 402 vs 420 vs 412 vs 204; oh/zero dropped; 12 vs 20 on floors.

### 8.5 Travel

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| Gate | “Boarding at gate C eighteen.” | Gate sign | 1 |
| Gate + time | “Boarding at gate C eighteen at ten forty.” | Gate, then clock | 2 |
| Flight | “Flight two twenty-seven to Chicago.” | Boarding pass flight field | 1 |
| Check-in / depart | “Check-in closes at six twenty-five.” | Clock | 1 |
| Terminal + gate | “Terminal three, gate B seven.” | Terminal mark, then gate | 2 |
| Baggage | “Carousel four.” | Carousel number | 1 |
| Highway / exit | “Take eighty to exit twelve B.” | Highway shield, then exit plaque | 2 |
| Bus / train | “The thirty-eight bus.” / “Caltrain one twenty-two.” | Vehicle number plate | 1 |
| Parking | “Level P two, space one fourteen.” | Garage level, then stall | 2 |

**Visual:** Airport gate board (letter huge, number huge). Flight as `WN 227`-style chip. Keep it a sign, not a full boarding-pass mockup.

**Distractors:** C18 vs C80 vs A18 vs C8; 227 vs 270 vs 217.

### 8.6 Phone and confirmation

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| US phone | “Call me at two one two, five five five, zero one nine eight.” | Keypad groups | 3 (area, prefix, line) |
| Last four | “The last four are seven two one six.” | Four-digit plate | 1 |
| Confirmation | “Your confirmation is H as in hotel, four nine two.” | Alphanumeric chip | 1–2 |
| Extension | “Extension two forty.” | Small plaque | 1 |

**Visual:** Segmented phone graphic `212 – 555 – 0198`, each step highlighting the group being asked. Do not show the full correct number on later steps before they are asked.

**Distractors:** 0/O, 5/9 if unclear, swapped groups, 555-0198 vs 555-1908.

### 8.7 Address and ZIP

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| Street number | “That’s fourteen twenty-two Oak Street.” | House number plaque | 1 |
| ZIP | “ZIP code nine four one zero seven.” | ZIP bar | 1 (or 2–3 digit groups if spoken grouped) |
| Apt | “Apartment three C.” | Door / mailbox | 1 |
| Street + ZIP | both in one sentence | plaque then ZIP | 2 |

**Visual:** House number like an American porch plaque; ZIP as a post-office style bar.

**Distractors:** 1422 vs 1224 vs 1402; ZIP digit transposition.

### 8.8 Everyday measures (count, weight, fuel, distance, speed, …)

Life is full of magnitudes, not just “party of six.” v1 treats these as one scenario chip (**Measures**) so the home screen does not explode, but the catalog must actually contain each role below.

| Role | Example script | Visual | Slots |
| --- | --- | --- | --- |
| Count | “Party of six.” | Host stand / big numeral | 1 |
| Grocery weight | “That’s two and a half pounds.” | Produce scale | 1 |
| Deli | “Half a pound of turkey.” | Scale | 1 |
| Luggage | “You’re at forty-eight pounds.” / “Twenty-three kilos.” | Bag scale | 1 |
| Body / gym | “One eighty.” / “One thirty-five on the bar.” | Scale / plate | 1 |
| Fuel volume | “You put in thirteen point two gallons.” | Pump gallons | 1 |
| Fuel price | “Gas is three forty-nine a gallon.” | Pump unit price | 1 |
| Distance | “It’s about two point four miles.” | Map ETA / mile chip | 1 |
| Speed | “You’re doing seventy.” | Speedometer | 1 |
| Tire pressure | “Fronts should be thirty-two PSI.” | Gauge | 1 |
| Oil / fluid | “It takes five quarts.” | Bottle / dipstick chip | 1 |
| Temperature | “It’s seventy-two degrees.” | Thermometer | 1 |
| Percent | “Twenty percent off.” | Percent badge | 1 |
| Aisle | “Aisle fourteen.” | Store aisle sign | 1 |

**Visual:** The object tells the unit so 13.2 **gallons** cannot be confused with $13.20. Always show `lb` / `gal` / `mph` / `PSI` / `°F` on the card.

**Distractors:** 2.5 lb vs 25 lb vs 2.5 gal; 13.2 gal vs $13.20 vs 30.2 gal; 70 mph vs 17 vs 75; 15/50; 48 lb vs 84 vs 40.8; kilos vs pounds on luggage.

US default units: **pounds, gallons, miles, mph, °F**. Kilos only when the script is airport/luggage. No Celsius, no liters as the default pump.

### 8.9 Mixed (priority items — this is the real world)

These are the highest-value items because they force holding **several** numbers without replay.

1. Hotel: “Check-in is at three, you’re in room four oh two.” → clock, door.  
2. Airport: “Flight five twelve, gate C eighteen, boarding at ten forty.” → flight, gate, clock.  
3. Restaurant: “Table for four at seven fifteen.” → quantity, clock.  
4. Checkout: “That’s forty-two sixty, you paid fifty, change is seven forty.” → three money steps.  
5. Doctor: “Tuesday the fifth at two thirty, suite nine.” → weekday, date, clock, door.  
6. Delivery: “Fourteen twenty-two Oak, apartment three C, ZIP nine four one oh seven.” → address, apt, ZIP.  
7. Gas station: “Three forty-nine a gallon, you put in thirteen point two, that’s forty-six ten.” → pump price, gallons, money.  
8. Grocery: “Two and a half pounds, that’s seven forty.” → scale, price.  
9. Highway: “Stay on one-oh-one to exit twelve B, about two point four miles.” → highway, exit, distance.

v1 should include **at least 20 mixed items** (40 is a stretch). Mixed is not optional: a v1 without hotel/airport items is not done.

## 9. Visual system (SwiftUI)

Shared rules:

- 2×2 grid, equal cells, large tap targets.
- The number is the hero; chrome is quiet.
- Same visual type for all four options in a step (four clocks, not a clock vs a door).
- After tap: correct cell gets a clear success state; wrong tap gets an error state on the chosen cell **and** the correct cell is highlighted.
- No animation that delays the next decision more than ~300ms on a correct answer.

| Visual | What to draw | Must be readable |
| --- | --- | --- |
| Clock | Analog face or digital pad | Minute precision |
| Duration | Compact `45 min` / `1 hr 20 min` | Not a second clock unless the script is a time of day |
| Calendar | Month + huge day + weekday | American month names |
| Door | Door + plate | Alphanumeric (12A, 9B) |
| Gate | Letter + number | C and 18 as two weights |
| Flight | Airline-agnostic flight chip | Digits + optional leading letters |
| Price | Tag / one receipt line | Cents visible |
| Phone | Segmented groups | One group emphasized per step |
| Address | House plaque | 3–5 digits |
| ZIP | Horizontal bar | 5 digits |
| Quantity | Host stand / big numeral | Integer |
| Scale | Produce / luggage scale | Unit `lb` or `kg` visible |
| Pump | Gas pump screen | Gallons **and** $/gal as different visuals |
| Speedo | Speedometer | `mph` |
| Gauge | Tire / simple dial | `PSI` |
| Mile | Map chip / highway marker | `mi` |
| Highway | US shield | 80 vs 101 vs 8 |
| Percent | Badge `20%` | |
| Temperature | Simple thermometer + °F | v1: Fahrenheit in American scripts |

**Clock setting:** `Digital` (default) or `Analog`. Applies to clock slots only.

**Time format setting:** `12-hour` (default, American) or `24-hour`. Scripts that say “fifteen hundred” still map to 15:00 internally.

## 10. Audio

### 10.1 Quality bar

- General American, adult voice, **conversational** rate (not news-anchor slow, not auctioneer).
- Natural intonation of a clerk, agent, or friend—not “lesson 3, listen and repeat.”
- **Input to TTS is always the authored `spokenText`**, never interpolated digits from the canonical value.
- Optional SSML breaks between phone/ZIP chunks. Do not use “spell digits” or character-level speak modes.
- Numbers slightly clearer than the surrounding words is acceptable; the rest of the sentence must still sound like speech.
- One consistent voice for v1 so the user trains numbers, not speaker variation. A second voice is a later difficulty lever.

### 10.2 Pipeline (offline)

Runtime **does not** call TTS. All clips are generated at content-build time and shipped in the app.

```
content/*.json  →  generate-audio (ElevenLabs or equivalent)
                →  NumSense/Audio/*.m4a
                →  bundled catalog index
```

Store in git: JSON scripts + generated audio (or LFS if size grows). Personal app; private repo.

Each JSON item records `voiceId`, `model`, and speaking-rate settings so regeneration is reproducible.

Approximate v1 bank: **150–250 unique clips** covering every category, including ≥20 mixed. Repeat the same value with different phrasings; do not repeat identical scripts. A clip returning a week later is intended.

### 10.3 Playback

- Play on session start of each item, speaker or receiver, respects silent switch via a setting (default: play even in silent mode—this is a listening app).
- No looping.
- After a wrong answer: replay once automatically while the correct option stays highlighted.

## 11. Difficulty (v1 vs later)

**v1 knobs**

- Scenario mix vs single-scenario filter.
- Analog vs digital clock.
- Session length.
- Delay after audio is **1.0s** (fixed in v1; later a 0 / 1 / 2.5s setting).

**Later knobs (do not block v1)**

- Slightly faster TTS.
- More reduced forms (“gonna be two fifty”).
- Oversample confusion pairs that exceed ~20% error.
- Second speaker.
- Background cafe/airport bed (easy to fake, easy to annoy—keep out of v1).

## 12. Scoring, stats, review, export

This is a first-class product surface, not a side effect of the session screen.

### 12.1 What “correct” means

- **Slot score:** first tap correct = 1, else 0. Replay after a miss is **feedback**, not a second scored try.
- **Item score:** every slot first-try correct.
- **Source of truth for analysis:** first-listen, unaided attempts. Review sessions are included in the log with `source = review` so they can be filtered out of the main learning curve.

v1 does not re-ask after replay (already locked). Schema still reserves `secondListenCorrect` as `null` so a later re-probe mode does not break exports.

### 12.2 Event log (append-only)

Every finished or abandoned session writes structured records. Snapshot catalog fields at attempt time so later script edits do not orphan history.

**Session**

| Field | Purpose |
| --- | --- |
| `id`, `schemaVersion` | Stable identity |
| `startedAt`, `endedAt` | Duration, calendar day |
| `completed` | Abandoned sessions still count as data |
| `source` | `practice` \| `review` |
| `scenarioFilter` | `all` or one category |
| `settings` | clock style, 12/24h, session length, silent-mode audio |
| `itemCount`, `slotCount` | Planned vs actually answered |
| `firstListenCorrectSlots` | Quick rollup |

**Item attempt**

| Field | Purpose |
| --- | --- |
| `sessionId`, `itemId`, `catalogVersion` | Join to content |
| `scenario`, `scriptText` | Snapshot of what was heard |
| `audioFile`, `variantTags` | e.g. `oh-zero`, `teen-ty`, `two-fifty` |
| `slotCount`, `presentedAt` | Multi-number load |
| `itemFirstListenCorrect` | All slots first-try |

**Slot attempt**

| Field | Purpose |
| --- | --- |
| `slotId`, `slotIndex` (0-based) | Slot-2 drop = overwriting |
| `role`, `visual` | time / gate / room / … |
| `correctValue`, `chosenValue` | Structured JSON, not only display strings |
| `distractors[3]` | What was on screen |
| `firstTapCorrect` | Scored bit |
| `responseMs` | From options appearing to tap |
| `replayedAfterWrong` | Always true iff first tap wrong in v1 |
| `confusionTag` | If classifiable: `teen-ty`, `fifteen-vs-fifty`, `month-day-swap`, `oh-vs-hundred`, `cross-slot-intrusion`, … |

Do not log raw microphone audio. Do not log anything off-device unless the user exports.

Volume: ~12 items × ~2 slots × 365 days ≈ 9k slot rows/year. A local JSONL (or SwiftData) store is enough.

### 12.3 In-app stats

**Overview**

- Last 7 / 30 days first-listen accuracy
- Session completion streak
- Total sessions, total slots
- Slot-index accuracy (1 vs 2 vs 3) — the working-memory tell

**By scenario**

- Time, date, money, room, travel, phone, address, measures, mixed
- Mixed items also contribute to each inner slot’s role (a hotel clock miss counts under Time **and** Mixed)

**Confusion**

- Ranked pairs from `confusionTag` + actual `correctValue`/`chosenValue` (13↔30, 12:15↔12:50, C18↔C80, …)
- Only show pairs with enough trials (e.g. ≥5) so the list is not noise

**Latency**

- Median `responseMs` by scenario (optional chart; table is enough in v1)

History is tappable: session list → session detail (each item, each slot, correct/wrong, the four options). After the session is over, transcript may be shown here. Never during the trial.

### 12.4 Review

From Stats or Summary:

- **Review missed** builds a session from unique `itemId`s whose last practice attempt had any wrong slot (default: last 14 days). Same core loop, `source = review`.
- Session detail can **retry this item** (single-item review).
- Review does not delete or rewrite the original miss; it appends new rows.

v1 does not auto-insert SRS. The log is what later scheduling will read.

### 12.5 Export

User-initiated only. Share Sheet (Files, AirDrop, Mail, etc.).

One share action offers two attachments (or a zip):

1. **`numsense-YYYYMMDD-HHmm.json`** — full fidelity: `schemaVersion`, app version, sessions, item attempts, slot attempts. Enough to recompute every dashboard number without the phone.
2. **`numsense-YYYYMMDD-HHmm-slots.csv`** — one row per slot attempt for Numbers / Excel / Python.

CSV columns (v1):

```
session_id, session_started_at, source, scenario_filter, clock_style,
item_id, scenario, script_text, slot_index, role, visual,
correct_value, chosen_value, first_tap_correct, response_ms,
replayed_after_wrong, confusion_tag, item_first_listen_correct
```

Structured values are serialized as compact JSON strings in CSV cells (e.g. `{"hour":15,"minute":10}`).

Export includes **all** local history unless the user picks a date range on the export sheet (All / Last 30 days / Last 7 days). Default: All.

No iCloud sync in v1. The export file **is** the backup. A later “import” is nice; not required for v1.

### 12.6 Privacy

- Local device only until the user shares a file.
- No analytics SDK, no network log.
- Export is the user’s data; they can delete all history from Settings.

## 13. Settings (v1)

- Clock: Digital / Analog  
- Time format: 12-hour / 24-hour  
- Session length: 8 / 12 / 20  
- Scenario: All + each category  
- Play audio in silent mode: on (default)
- Delete all training history (destructive, confirm)

No account. No difficulty named “easy/hard” in v1—the analog clock and scenario filter are enough. Export lives on the Stats screen, not buried only in Settings.

## 14. Information architecture

```
Home
  Start (big)
  Scenario chips (All / Time / Date / …)
  Last session score + 7-day accuracy
  Stats
  Settings

Trial
  Audio-only state (waveform or “Listen”)
  Then 2×2 visuals + step indicator “2 of 3”
  Feedback overlay on the grid

Summary
  Score, by-scenario, missed pairs
  Review missed
  Train again

Stats
  Overview (7/30 day, streak, slot-index)
  By scenario
  Confusion pairs
  Session history → session detail
  Review missed
  Export
```

English copy, short. Example: Listen → Which time? → Which gate?

The prompt above the grid names the **slot role** (“Gate”, “Room”, “Time”) so the user knows which number this step is asking for when the sentence had several. It must **not** repeat the number.

## 15. Non-goals (v1)

- Mental arithmetic (remove the current drill engine from the product path).
- Dictation / typing digits.
- Chinese UI or Chinese translations as answers.
- Live conversation, speech recognition, or microphone input.
- Noisy PA, overlapping speakers, hold music.
- Very long digit strings in one step (10-digit phone unchunked, cards, SSN).
- App Store, Game Center, iCloud sync.
- On-device TTS as the production voice.
- Teaching analog-clock reading as a subject (analog is only an option renderer).
- British/military time as the default (`half three`, `nought`); 24h only in Travel.
- Relative dates (`a week from Tuesday`), NATO alphabet PNRs, Celsius, liters as the default pump, recipe cups, height (`five eight`), seconds.

## 16. Engineering implications

The current repo is a ~400-line mental-math scaffold (`AppModel` → `DrillEngine` → text-field `DrillView`). Keep the shell; replace the domain.

| Keep | Replace |
| --- | --- |
| Xcode 27 / iPhone signing, `NumSenseApp` environment injection | `DrillEngine` arithmetic |
| `AppModel` coordinator pattern (`start` / `submit` / `endSession`) | `DrillKind` add/subtract/multiply |
| `NavigationStack` home → trial → result → settings | Numeric `TextField` answers |
| Swift Testing + seeded RNG harness | Math-specific tests |
| Result and Settings *layout* | Operand steppers; thin UserDefaults `SessionStore` as the only log |

Target modules (Views depend on App; App composes the rest; Content has no UI/audio deps):

```
NumSense/
  App/          NumSenseApp, AppModel
  Content/      catalog JSON, Sentence, Slot, trap tags, loaders
  Audio/        one-shot player, AVAudioSession, bundled m4a
  Visuals/      Clock, Calendar, Door, Gate, Price, Phone, …
  Session/      trial flow, SessionBuilder, option shuffle
  Stats/        AttemptLog, queries, review-missed picker, export
  Views/        Home, Trial, Summary, Stats, Settings
```

Vertical slice: one clock item + audio + 2×2 clocks + one logged slot + export stub, then fill categories in the [content-inventory.md](./content-inventory.md) build order (clock → money → room → gate → … → mixed). Mixed is the last step and the acceptance gate.

Distractors: authored in the catalog for v1. Every 4-pack should include a phonological twin when the value allows it, and a cross-slot intrusion on multi-slot items.

## 17. v1 acceptance

The app is v1-complete when:

1. A session of 12 mixed items runs offline on the iPhone 17 Pro.  
2. Every scenario in §8 has playable items (not a stub category).  
3. Mixed items with 2–3 slots use sequential 2×2 visuals.  
4. Audio is bundled neural American English at conversational speed.  
5. No replay until a wrong tap; then correct visual + one replay.  
6. Clock setting switches analog/digital.  
7. Options are SwiftUI graphics, readable at arm’s length.  
8. Summary shows accuracy and a per-scenario split.  
9. Every slot attempt is persisted; Stats can show 7-day accuracy, by-scenario, and confusion pairs.  
10. Review missed rebuilds a scored session from recent misses.  
11. Export produces JSON + CSV through the system Share Sheet.

## 18. Open points (non-blocking)

These can be decided during implementation without changing the product:

- Exact TTS vendor/voice id (ElevenLabs or equal; one adult General American voice).  
- Whether review-after-item shows the transcript. Default: show on summary only, not mid-session.  
- 12 vs 24 hour default on digital clocks: **12-hour**.  
- Whether weekday is a separate slot or printed on the calendar and asked as the date only: **separate slot** when the script speaks both.  
- Attempt store: JSONL files vs SwiftData — implementation choice; export schema is the contract.  
- Whether v1 export is two files or one zip; either is fine.

If a later pass needs a smaller first ship, cut order is: PSI / oil quarts → ZIP grouping → 7-digit phone. **Do not** cut mixed hotel/airport **or** gas/grocery measures; they are the point of the app. Content build order is in [content-inventory.md](./content-inventory.md).

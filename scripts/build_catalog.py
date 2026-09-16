#!/usr/bin/env python3
"""Build content/catalog.json with authored American spokenText (never raw digits to TTS)."""

from __future__ import annotations

import json
from pathlib import Path

ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
    "seventeen", "eighteen", "nineteen",
]
TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
MONTHS = [
    "", "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]
WDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
ORDINALS = {
    1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth",
    7: "seventh", 8: "eighth", 9: "ninth", 10: "tenth", 11: "eleventh",
    12: "twelfth", 13: "thirteenth", 14: "fourteenth", 15: "fifteenth",
    20: "twentieth", 21: "twenty-first", 22: "twenty-second", 23: "twenty-third",
    30: "thirtieth", 31: "thirty-first",
}


def n2w(n: int) -> str:
    n = int(n)
    if n < 20:
        return ONES[n]
    if n < 100:
        t, o = divmod(n, 10)
        return TENS[t] if o == 0 else f"{TENS[t]}-{ONES[o]}"
    if n < 1000:
        h, rest = divmod(n, 100)
        if rest == 0:
            return f"{ONES[h]} hundred"
        return f"{ONES[h]} hundred {n2w(rest)}"
    raise ValueError(n)


def hour_word(h: int) -> str:
    h12 = h % 12
    return "twelve" if h12 == 0 else n2w(h12)


def ordinal(d: int) -> str:
    if d in ORDINALS:
        return ORDINALS[d]
    if 10 < d < 20:
        return f"{n2w(d)}th"
    return f"{n2w(d)}th"


def clock(hour: int, minute: int, ampm: str | None = None) -> dict:
    v: dict = {"type": "clock", "hour": hour, "minute": minute}
    if ampm:
        v["ampm"] = ampm
    return v


def money(cents: int) -> dict:
    return {"type": "price", "cents": cents}


def room(text: str) -> dict:
    return {"type": "door", "text": text}


def gate(letter: str, number: int) -> dict:
    return {"type": "gate", "letter": letter, "number": number}


def slot(sid: str, role: str, visual: str, value: dict, distractors: list[dict]) -> dict:
    return {
        "id": sid,
        "role": role,
        "visual": visual,
        "value": value,
        "distractors": distractors,
    }


def item(iid: str, scenario: str, spoken: str, slots: list[dict], traps: list[str], tags: list[str]) -> dict:
    return {
        "id": iid,
        "scenario": scenario,
        "spokenText": spoken,
        "audioFile": f"{iid}.m4a",
        "variantTags": tags,
        "trapTags": traps,
        "slots": slots,
    }


def teen_ty_minute(m: int) -> int:
    mapping = {13: 30, 14: 40, 15: 50, 16: 60, 17: 70, 18: 80, 19: 90, 30: 13, 50: 15, 40: 14}
    if m in mapping and mapping[m] < 60:
        return mapping[m]
    return (m + 15) % 60


def time_colon(h: int, m: int) -> str:
    hw = hour_word(h)
    if m == 0:
        return hw
    if m == 5:
        return f"{hw} oh five"
    if 1 <= m <= 9:
        return f"{hw} oh {n2w(m)}"
    return f"{hw} {n2w(m)}"


def time_items() -> list[dict]:
    out: list[dict] = []
    times = [
        (3, 15), (3, 50), (3, 30), (3, 5), (3, 45), (3, 0),
        (12, 15), (12, 50), (12, 0), (10, 45), (7, 30), (4, 5),
        (2, 30), (9, 0), (1, 15), (6, 20), (11, 40), (8, 10),
        (5, 45), (10, 20),
    ]
    for h, m in times:
        hw, mw = hour_word(h), n2w(m) if m else hour_word(h)
        twin_m = teen_ty_minute(m) if m else 30
        d1 = clock(h, twin_m if twin_m != m else (m + 10) % 60)
        d2 = clock(h, 30 if m != 30 else 0)
        d3 = clock((h % 12) + 1 if h != 12 else 1, m)
        traps = ["teen-ty", "neighbor", "order"]
        out.append(item(
            f"time-{h:02d}{m:02d}-colon",
            "time",
            f"It's {time_colon(h, m)}.",
            [slot("t", "clock", "clock", clock(h, m), [d1, d2, d3])],
            traps,
            ["colon-time"],
        ))
        if m == 15:
            spoken = f"It's a quarter after {hw}."
            tag = "quarter-after"
        elif m == 30:
            spoken = f"It's half past {hw}."
            tag = "half-past"
        elif m == 45:
            spoken = f"It's a quarter to {hour_word(h + 1)}."
            tag = "quarter-to"
        elif m == 5:
            spoken = f"It's five after {hw}."
            tag = "five-after"
        elif m == 0:
            spoken = f"It's {hw} o'clock."
            tag = "oclock"
        elif m == 50:
            spoken = f"It's ten to {hour_word(h + 1)}."
            tag = "ten-to"
        else:
            continue
        out.append(item(
            f"time-{h:02d}{m:02d}-alt",
            "time",
            spoken,
            [slot("t", "clock", "clock", clock(h, m), [d1, d2, d3])],
            traps,
            [tag],
        ))

    out.append(item(
        "time-open-9-6",
        "time",
        "We're open from nine to six.",
        [
            slot("a", "clock", "clock", clock(9, 0), [clock(6, 0), clock(9, 30), clock(10, 0)]),
            slot("b", "clock", "clock", clock(6, 0), [clock(9, 0), clock(6, 30), clock(16, 0)]),
        ],
        ["cross-slot-intrusion", "neighbor"],
        ["range"],
    ))
    out.append(item(
        "time-appt-230-pm",
        "time",
        "Your appointment is at two thirty this afternoon.",
        [slot("t", "clock", "clock", clock(14, 30, "pm"), [
            clock(2, 30, "am"), clock(14, 13), clock(15, 30, "pm"),
        ])],
        ["ampm", "teen-ty"],
        ["appointment"],
    ))
    out.append(item(
        "time-table-20min",
        "time",
        "Your table will be ready in twenty minutes.",
        [slot("d", "duration", "duration", {"type": "duration", "minutes": 20}, [
            {"type": "duration", "minutes": 50},
            {"type": "duration", "minutes": 12},
            {"type": "duration", "minutes": 30},
        ])],
        ["teen-ty", "neighbor"],
        ["duration"],
    ))
    out.append(item(
        "time-meeting-45",
        "time",
        "The meeting runs for forty-five minutes.",
        [slot("d", "duration", "duration", {"type": "duration", "minutes": 45}, [
            {"type": "duration", "minutes": 15},
            {"type": "duration", "minutes": 40},
            {"type": "duration", "minutes": 90},
        ])],
        ["teen-ty", "scale"],
        ["duration"],
    ))
    out.append(item(
        "time-hour-half",
        "time",
        "Give me an hour and a half.",
        [slot("d", "duration", "duration", {"type": "duration", "minutes": 90}, [
            {"type": "duration", "minutes": 30},
            {"type": "duration", "minutes": 60},
            {"type": "duration", "minutes": 19},
        ])],
        ["scale", "teen-ty"],
        ["duration"],
    ))
    return out


def date_items() -> list[dict]:
    out: list[dict] = []

    def cal(month: int, day: int, weekday: str | None = None) -> dict:
        v = {"type": "calendar", "month": month, "day": day}
        if weekday:
            v["weekday"] = weekday
        return v

    specs = [
        (3, 5, "Thursday", "Today is Thursday, March fifth."),
        (3, 5, None, "That's March fifth."),
        (3, 5, None, "That's three five."),
        (5, 3, None, "That's May third."),
        (3, 13, None, "See you on the thirteenth."),
        (3, 30, None, "See you on the thirtieth."),
        (3, 15, None, "Your return is on the fifteenth."),
        (7, 4, "Friday", "That's Friday, July fourth."),
        (11, 21, None, "It's November twenty-first."),
        (12, 12, None, "We're checking in December twelfth."),
        (1, 1, None, "That's January first."),
        (2, 14, None, "That's February fourteenth."),
        (4, 20, None, "That's April twentieth."),
        (8, 31, None, "That's August thirty-first."),
        (9, 12, "Monday", "Monday, September twelfth."),
        (10, 5, None, "October fifth."),
        (6, 2, None, "June second."),
        (3, 21, None, "March twenty-first."),
        (5, 15, None, "May fifteenth."),
        (11, 11, None, "November eleventh."),
    ]
    used: set[str] = set()
    for i, (mo, d, wd, spoken) in enumerate(specs):
        iid = f"date-{mo:02d}-{d:02d}-{i}"
        if iid in used:
            continue
        used.add(iid)
        value = cal(mo, d, wd)
        distractors = [
            cal(d if d <= 12 else 5, mo if mo <= 28 else 1, wd),
            cal(mo, 13 if d != 13 else 30, wd),
            cal(mo, d, "Friday" if wd != "Friday" else "Tuesday"),
        ]
        if d == 5 and mo == 3:
            distractors[0] = cal(5, 3, wd)
        slots = [slot("d", "date", "calendar", value, distractors)]
        if wd:
            slots.append(slot(
                "w", "weekday", "calendar",
                cal(mo, d, wd),
                [
                    cal(mo, d, "Friday" if wd != "Friday" else "Monday"),
                    cal(mo, d, "Wednesday"),
                    cal(mo, d, "Sunday"),
                ],
            ))
        out.append(item(iid, "date", spoken, slots, ["order", "teen-ty"], ["date"]))
    return out


def money_spoken(cents: int, style: str) -> str:
    dollars, c = divmod(cents, 100)
    if style == "fifty" and c == 50:
        return f"{n2w(dollars)} fifty"
    if style == "nn" and c == 99:
        return f"{n2w(dollars)} ninety-nine"
    if style == "oh" and 0 < c < 10:
        return f"{n2w(dollars)} oh {n2w(c)}"
    if style == "full":
        if c == 0:
            return f"{n2w(dollars)} dollars"
        return f"{n2w(dollars)} dollars and {n2w(c)} cents"
    if c == 0:
        return f"{n2w(dollars)} even"
    return f"{n2w(dollars)} {n2w(c)}" if c >= 10 else f"{n2w(dollars)} oh {n2w(c)}"


def money_items() -> list[dict]:
    out: list[dict] = []
    amounts = [
        (250, "fifty", "That's two fifty."),
        (250, "full", "That's two dollars and fifty cents."),
        (450, "fifty", "It's four fifty with tax."),
        (1299, "nn", "That'll be twelve ninety-nine."),
        (1999, "nn", "It's nineteen ninety-nine."),
        (405, "oh", "That's four oh five."),
        (2000, "full", "You gave me a twenty."),
        (375, "fifty", "Your change is three seventy-five."),
        (1250, "fifty", "That's twelve fifty."),
        (1215, "colon", "That's twelve fifteen."),
        (600, "full", "Fifteen percent is about six bucks."),
        (1800, "full", "Split it's eighteen each."),
        (50, "cents", "That's fifty cents."),
        (100, "full", "Just a dollar."),
        (999, "nn", "It's nine ninety-nine."),
        (4250, "fifty", "With tip that's forty-two fifty."),
        (199, "nn", "A dollar ninety-nine."),
        (750, "fifty", "That's seven fifty."),
        (3050, "fifty", "That's thirty fifty."),
        (8800, "full", "Eighty-eight dollars."),
    ]
    for i, (cents, style, spoken) in enumerate(amounts):
        dollars, c = divmod(cents, 100)
        d1 = money(cents * 10 if cents < 1000 else cents // 10)
        if cents == 450:
            d1 = money(45000)
        d2 = money(dollars * 100 + (15 if c == 50 else 50))
        d3 = money(max(cents - 100, 25))
        if cents == 1250:
            d2 = money(1215)
            d3 = money(5000)
        out.append(item(
            f"money-{cents}-{i}",
            "money",
            spoken if style != "colon" else "That's twelve fifteen.",
            [slot("p", "amount", "price", money(cents), [d1, d2, d3])],
            ["scale", "teen-ty"],
            [style],
        ))
    out.append(item(
        "money-bill-change",
        "money",
        "You gave me a twenty, so your change is three twenty-five.",
        [
            slot("paid", "amount", "price", money(2000), [money(200), money(1000), money(2500)]),
            slot("ch", "amount", "price", money(325), [money(375), money(1325), money(2000)]),
        ],
        ["cross-slot-intrusion", "scale"],
        ["change"],
    ))
    return out


def room_items() -> list[dict]:
    out: list[dict] = []
    rooms = [
        ("402", "four oh two", "Your room number is four oh two."),
        ("402", "four hundred two", "You're in four hundred two."),
        ("402", "four zero two", "You're in four zero two."),
        ("412", "four twelve", "That's room four twelve."),
        ("420", "four twenty", "Room four twenty."),
        ("1010", "ten ten", "We're in ten ten."),
        ("1108", "eleven oh eight", "Room eleven oh eight."),
        ("7B", "seven B", "You're in suite seven B."),
        ("12A", "twelve A", "Conference room twelve A."),
        ("214", "two fourteen", "Room two fourteen."),
        ("240", "two forty", "Room two forty."),
        ("300", "three hundred", "Room three hundred."),
        ("1508", "fifteen oh eight", "Fifteen oh eight."),
        ("9B", "nine B", "Suite nine B."),
        ("1200", "twelve hundred", "Suite twelve hundred."),
    ]
    for i, (num, _how, spoken) in enumerate(rooms):
        d1 = room("420" if num == "402" else "402")
        if num == "402":
            distractors = [room("420"), room("412"), room("42")]
        elif num == "7B":
            distractors = [room("B7"), room("17B"), room("7D")]
        elif num == "214":
            distractors = [room("240"), room("204"), room("314")]
        else:
            distractors = [room("402"), room("412"), room("14")]
        out.append(item(
            f"room-{num}-{i}",
            "room",
            spoken,
            [slot("r", "room", "door", room(num), distractors)],
            ["oh-vs-hundred", "letter-number"],
            ["room"],
        ))
    out.append(item(
        "room-floor-12-1215",
        "room",
        "That's the twelfth floor, room twelve fifteen.",
        [
            slot("f", "floor", "door", room("12F"), [room("20F"), room("13F"), room("2F")]),
            slot("r", "room", "door", room("1215"), [room("12F"), room("1250"), room("2115")]),
        ],
        ["cross-slot-intrusion", "teen-ty"],
        ["floor+room"],
    ))
    return out


def travel_items() -> list[dict]:
    out: list[dict] = []
    out.append(item("travel-c18", "travel", "Boarding at gate C eighteen.", [
        slot("g", "gate", "gate", gate("C", 18), [gate("C", 80), gate("A", 18), gate("C", 8)]),
    ], ["teen-ty", "letter-number"], ["gate"]))
    out.append(item("travel-c18-digits", "travel", "That's gate C one eight.", [
        slot("g", "gate", "gate", gate("C", 18), [gate("C", 80), gate("B", 18), gate("C", 13)]),
    ], ["teen-ty"], ["gate-digitwise"]))
    out.append(item("travel-b12", "travel", "Now boarding at gate B twelve.", [
        slot("g", "gate", "gate", gate("B", 12), [gate("B", 20), gate("D", 12), gate("B", 2)]),
    ], ["letter-number"], ["gate"]))
    out.append(item("travel-flight-218", "travel", "Flight two eighteen to Chicago.", [
        slot("f", "flight", "flight", {"type": "flight", "text": "218"}, [
            {"type": "flight", "text": "280"},
            {"type": "flight", "text": "118"},
            {"type": "flight", "text": "212"},
        ]),
    ], ["teen-ty"], ["flight"]))
    out.append(item("travel-flight-847", "travel", "United eight forty-seven.", [
        slot("f", "flight", "flight", {"type": "flight", "text": "847"}, [
            {"type": "flight", "text": "817"},
            {"type": "flight", "text": "447"},
            {"type": "flight", "text": "87"},
        ]),
    ], ["neighbor"], ["flight"]))
    out.append(item("travel-t2-b7", "travel", "Terminal two, gate B seven.", [
        slot("t", "terminal", "quantity", {"type": "quantity", "number": 2}, [
            {"type": "quantity", "number": 3}, {"type": "quantity", "number": 12}, {"type": "quantity", "number": 7},
        ]),
        slot("g", "gate", "gate", gate("B", 7), [gate("B", 2), gate("D", 7), gate("B", 17)]),
    ], ["cross-slot-intrusion"], ["terminal+gate"]))
    out.append(item("travel-carousel-4", "travel", "That's carousel four.", [
        slot("c", "carousel", "quantity", {"type": "quantity", "number": 4}, [
            {"type": "quantity", "number": 14}, {"type": "quantity", "number": 40}, {"type": "quantity", "number": 2},
        ]),
    ], ["teen-ty"], ["carousel"]))
    out.append(item("travel-i80-exit12b", "travel", "Take eighty to exit twelve B.", [
        slot("h", "highway", "highway", {"type": "highway", "text": "80"}, [
            {"type": "highway", "text": "18"}, {"type": "highway", "text": "8"}, {"type": "highway", "text": "280"},
        ]),
        slot("e", "exit", "exit", {"type": "exit", "text": "12B"}, [
            {"type": "exit", "text": "20B"}, {"type": "exit", "text": "12"}, {"type": "exit", "text": "B12"},
        ]),
    ], ["cross-slot-intrusion", "letter-number"], ["highway"]))
    out.append(item("travel-101", "travel", "Stay on one-oh-one south.", [
        slot("h", "highway", "highway", {"type": "highway", "text": "101"}, [
            {"type": "highway", "text": "10"}, {"type": "highway", "text": "110"}, {"type": "highway", "text": "1"},
        ]),
    ], ["oh-vs-hundred"], ["highway"]))
    out.append(item("travel-bus-38", "travel", "Take the thirty-eight bus.", [
        slot("b", "bus", "quantity", {"type": "quantity", "number": 38}, [
            {"type": "quantity", "number": 13}, {"type": "quantity", "number": 80}, {"type": "quantity", "number": 28},
        ]),
    ], ["teen-ty"], ["bus"]))
    out.append(item("travel-p2-114", "travel", "Level P two, space one fourteen.", [
        slot("l", "parkingLevel", "door", room("P2"), [room("P3"), room("2"), room("P12")]),
        slot("s", "parking", "door", room("114"), [room("P2"), room("140"), room("104")]),
    ], ["cross-slot-intrusion"], ["parking"]))
    out.append(item("travel-checkin-625", "travel", "Check-in closes at six twenty-five.", [
        slot("t", "clock", "clock", clock(6, 25), [clock(6, 52), clock(16, 25), clock(5, 25)]),
    ], ["order", "ampm"], ["time"]))
    out.append(item("travel-seat-14a", "travel", "You're in seat fourteen A.", [
        slot("s", "seat", "door", room("14A"), [room("40A"), room("14B"), room("4A")]),
    ], ["teen-ty", "letter-number"], ["seat"]))
    out.append(item("travel-delayed-40", "travel", "We're delayed forty minutes. New time is three twenty.", [
        slot("d", "duration", "duration", {"type": "duration", "minutes": 40}, [
            {"type": "duration", "minutes": 14}, {"type": "duration", "minutes": 45}, {"type": "duration", "minutes": 30},
        ]),
        slot("t", "clock", "clock", clock(3, 20), [clock(3, 40), clock(2, 20), clock(3, 50)]),
    ], ["cross-slot-intrusion", "teen-ty"], ["delay"]))
    return out


def phone_items() -> list[dict]:
    out: list[dict] = []
    out.append(item("phone-last4-7216", "phone", "The last four are seven two one six.", [
        slot("p", "code", "phone", {"type": "phone", "text": "7216"}, [
            {"type": "phone", "text": "7126"},
            {"type": "phone", "text": "7210"},
            {"type": "phone", "text": "2716"},
        ]),
    ], ["order"], ["last4"]))
    out.append(item("phone-last4-1234-time", "phone", "Last four is twelve thirty-four.", [
        slot("p", "code", "phone", {"type": "phone", "text": "1234"}, [
            {"type": "phone", "text": "1234"},
            {"type": "phone", "text": "1324"},
            {"type": "phone", "text": "1204"},
        ]),
    ], ["chunk-merge"], ["last4-grouped"]))
    # fix duplicate distractor
    out[-1]["slots"][0]["distractors"][0] = {"type": "phone", "text": "1243"}
    out.append(item("phone-ext-203", "phone", "Extension two oh three.", [
        slot("e", "extension", "phone", {"type": "phone", "text": "203"}, [
            {"type": "phone", "text": "230"},
            {"type": "phone", "text": "2003"},
            {"type": "phone", "text": "213"},
        ]),
    ], ["oh-vs-hundred"], ["ext"]))
    out.append(item("phone-code-4819", "phone", "The code is four eight one nine.", [
        slot("c", "code", "phone", {"type": "phone", "text": "4819"}, [
            {"type": "phone", "text": "4189"},
            {"type": "phone", "text": "4891"},
            {"type": "phone", "text": "4810"},
        ]),
    ], ["order"], ["otp"]))
    out.append(item("phone-local-555-0123", "phone", "My number is five five five, oh one two three.", [
        slot("a", "phone", "phone", {"type": "phone", "text": "555"}, [
            {"type": "phone", "text": "515"}, {"type": "phone", "text": "550"}, {"type": "phone", "text": "5555"},
        ]),
        slot("b", "phone", "phone", {"type": "phone", "text": "0123"}, [
            {"type": "phone", "text": "555"}, {"type": "phone", "text": "1023"}, {"type": "phone", "text": "0120"},
        ]),
    ], ["cross-slot-intrusion", "oh-vs-hundred"], ["local7"]))
    out.append(item("phone-conf-h492", "phone", "Your confirmation is H as in hotel, four nine two.", [
        slot("c", "code", "phone", {"type": "phone", "text": "H492"}, [
            {"type": "phone", "text": "H429"}, {"type": "phone", "text": "A492"}, {"type": "phone", "text": "H490"},
        ]),
    ], ["order", "letter-number"], ["confirm"]))
    out.append(item("phone-415-area", "phone", "Call four one five, five five five, oh one two three.", [
        slot("a", "phone", "phone", {"type": "phone", "text": "415"}, [
            {"type": "phone", "text": "451"}, {"type": "phone", "text": "514"}, {"type": "phone", "text": "405"},
        ]),
        slot("b", "phone", "phone", {"type": "phone", "text": "555"}, [
            {"type": "phone", "text": "415"}, {"type": "phone", "text": "550"}, {"type": "phone", "text": "515"},
        ]),
        slot("c", "phone", "phone", {"type": "phone", "text": "0123"}, [
            {"type": "phone", "text": "1023"}, {"type": "phone", "text": "0124"}, {"type": "phone", "text": "555"},
        ]),
    ], ["cross-slot-intrusion"], ["us10-chunked"]))
    return out


def address_items() -> list[dict]:
    out: list[dict] = []
    out.append(item("addr-1422-oak", "address", "That's fourteen twenty-two Oak Street.", [
        slot("n", "address", "address", {"type": "address", "text": "1422"}, [
            {"type": "address", "text": "1224"},
            {"type": "address", "text": "1402"},
            {"type": "address", "text": "1420"},
        ]),
    ], ["order"], ["house"]))
    out.append(item("addr-1420", "address", "It's fourteen twenty Oak Street.", [
        slot("n", "address", "address", {"type": "address", "text": "1420"}, [
            {"type": "address", "text": "1402"},
            {"type": "address", "text": "1240"},
            {"type": "address", "text": "1422"},
        ]),
    ], ["order"], ["house"]))
    out.append(item("addr-402-main", "address", "Four oh two Main.", [
        slot("n", "address", "address", {"type": "address", "text": "402"}, [
            {"type": "address", "text": "420"},
            {"type": "address", "text": "412"},
            {"type": "address", "text": "42"},
        ]),
    ], ["oh-vs-hundred"], ["house"]))
    out.append(item("addr-2100", "address", "That's twenty-one hundred Mission.", [
        slot("n", "address", "address", {"type": "address", "text": "2100"}, [
            {"type": "address", "text": "1200"},
            {"type": "address", "text": "2110"},
            {"type": "address", "text": "2010"},
        ]),
    ], ["order"], ["house"]))
    out.append(item("addr-16th", "address", "It's on sixteenth and Mission.", [
        slot("n", "address", "address", {"type": "address", "text": "16th"}, [
            {"type": "address", "text": "60th"},
            {"type": "address", "text": "6th"},
            {"type": "address", "text": "15th"},
        ]),
    ], ["teen-ty"], ["numbered-street"]))
    out.append(item("addr-apt-3c", "address", "Apartment three C.", [
        slot("a", "apt", "door", room("3C"), [room("C3"), room("3D"), room("13C")]),
    ], ["letter-number"], ["apt"]))
    out.append(item("addr-zip-94107", "address", "ZIP code nine four one oh seven.", [
        slot("z", "zip", "zip", {"type": "zip", "text": "94107"}, [
            {"type": "zip", "text": "94017"},
            {"type": "zip", "text": "94170"},
            {"type": "zip", "text": "94117"},
        ]),
    ], ["order"], ["zip"]))
    out.append(item("addr-1422-3c-zip", "address", "Fourteen twenty-two Oak, apartment three C, ZIP nine four one oh seven.", [
        slot("n", "address", "address", {"type": "address", "text": "1422"}, [
            {"type": "address", "text": "3C"}, {"type": "address", "text": "1224"}, {"type": "address", "text": "1402"},
        ]),
        slot("a", "apt", "door", room("3C"), [room("1422"), room("3D"), room("C3")]),
        slot("z", "zip", "zip", {"type": "zip", "text": "94107"}, [
            {"type": "zip", "text": "1422"}, {"type": "zip", "text": "94170"}, {"type": "zip", "text": "94017"},
        ]),
    ], ["cross-slot-intrusion"], ["mixed-address"]))
    return out


def measure_items() -> list[dict]:
    out: list[dict] = []
    out.append(item("meas-party-6", "measures", "Party of six.", [
        slot("q", "count", "quantity", {"type": "quantity", "number": 6}, [
            {"type": "quantity", "number": 16}, {"type": "quantity", "number": 60}, {"type": "quantity", "number": 5},
        ]),
    ], ["teen-ty"], ["count"]))
    out.append(item("meas-dozen", "measures", "We need a dozen.", [
        slot("q", "count", "quantity", {"type": "quantity", "number": 12}, [
            {"type": "quantity", "number": 20}, {"type": "quantity", "number": 2}, {"type": "quantity", "number": 10},
        ]),
    ], ["scale"], ["dozen"]))
    out.append(item("meas-2.5lb", "measures", "That's two and a half pounds.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 2.5, "unit": "lb"}, [
            {"type": "weight", "amount": 25, "unit": "lb"},
            {"type": "weight", "amount": 2.5, "unit": "gal"},
            {"type": "weight", "amount": 2.0, "unit": "lb"},
        ]),
    ], ["scale"], ["weight"]))
    out.append(item("meas-2.5lb-point", "measures", "That's two point five pounds.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 2.5, "unit": "lb"}, [
            {"type": "weight", "amount": 25, "unit": "lb"},
            {"type": "weight", "amount": 5.2, "unit": "lb"},
            {"type": "weight", "amount": 2.15, "unit": "lb"},
        ]),
    ], ["scale"], ["weight-point"]))
    out.append(item("meas-half-lb", "measures", "Half a pound of turkey.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 0.5, "unit": "lb"}, [
            {"type": "weight", "amount": 1.5, "unit": "lb"},
            {"type": "weight", "amount": 5, "unit": "lb"},
            {"type": "weight", "amount": 0.5, "unit": "kg"},
        ]),
    ], ["scale"], ["weight"]))
    out.append(item("meas-48lb", "measures", "You're at forty-eight pounds.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 48, "unit": "lb"}, [
            {"type": "weight", "amount": 84, "unit": "lb"},
            {"type": "weight", "amount": 40.8, "unit": "lb"},
            {"type": "weight", "amount": 14, "unit": "lb"},
        ]),
    ], ["order", "teen-ty"], ["luggage"]))
    out.append(item("meas-23kg", "measures", "That's twenty-three kilos.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 23, "unit": "kg"}, [
            {"type": "weight", "amount": 23, "unit": "lb"},
            {"type": "weight", "amount": 32, "unit": "kg"},
            {"type": "weight", "amount": 13, "unit": "kg"},
        ]),
    ], ["scale"], ["luggage-kg"]))
    out.append(item("meas-180", "measures", "He's one eighty.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 180, "unit": "lb"}, [
            {"type": "weight", "amount": 118, "unit": "lb"},
            {"type": "weight", "amount": 80, "unit": "lb"},
            {"type": "weight", "amount": 190, "unit": "lb"},
        ]),
    ], ["oh-vs-hundred"], ["body"]))
    out.append(item("meas-135-bar", "measures", "One thirty-five on the bar.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 135, "unit": "lb"}, [
            {"type": "weight", "amount": 153, "unit": "lb"},
            {"type": "weight", "amount": 35, "unit": "lb"},
            {"type": "weight", "amount": 130, "unit": "lb"},
        ]),
    ], ["order"], ["gym"]))
    out.append(item("meas-13.2gal", "measures", "You put in thirteen point two gallons.", [
        slot("g", "fuel", "pump", {"type": "fuelGallons", "gallons": 13.2}, [
            {"type": "fuelGallons", "gallons": 30.2},
            {"type": "price", "cents": 1320},
            {"type": "fuelGallons", "gallons": 12.3},
        ]),
    ], ["teen-ty", "scale"], ["fuel"]))
    out.append(item("meas-349-gal", "measures", "Gas is three forty-nine a gallon.", [
        slot("p", "fuelPrice", "pump", {"type": "fuelPrice", "cents": 349}, [
            {"type": "fuelPrice", "cents": 439},
            {"type": "fuelPrice", "cents": 319},
            {"type": "price", "cents": 349},
        ]),
    ], ["order", "scale"], ["fuel-price"]))
    out.append(item("meas-2.4mi", "measures", "It's about two point four miles.", [
        slot("m", "distance", "mile", {"type": "miles", "miles": 2.4}, [
            {"type": "miles", "miles": 24},
            {"type": "miles", "miles": 2.14},
            {"type": "clock", "hour": 2, "minute": 40},
        ]),
    ], ["scale", "chunk-merge"], ["distance"]))
    out.append(item("meas-70mph", "measures", "You're doing seventy miles an hour.", [
        slot("s", "speed", "speedo", {"type": "mph", "mph": 70}, [
            {"type": "mph", "mph": 17},
            {"type": "mph", "mph": 75},
            {"type": "mph", "mph": 60},
        ]),
    ], ["teen-ty"], ["speed"]))
    out.append(item("meas-70-short", "measures", "You're doing seventy.", [
        slot("s", "speed", "speedo", {"type": "mph", "mph": 70}, [
            {"type": "mph", "mph": 17},
            {"type": "mph", "mph": 19},
            {"type": "mph", "mph": 80},
        ]),
    ], ["teen-ty"], ["speed"]))
    out.append(item("meas-32psi", "measures", "Fronts should be thirty-two PSI.", [
        slot("p", "pressure", "gauge", {"type": "psi", "psi": 32}, [
            {"type": "psi", "psi": 23},
            {"type": "psi", "psi": 35},
            {"type": "psi", "psi": 13},
        ]),
    ], ["order"], ["psi"]))
    out.append(item("meas-5qt", "measures", "It takes five quarts.", [
        slot("q", "volume", "quantity", {"type": "quantity", "number": 5}, [
            {"type": "quantity", "number": 15},
            {"type": "quantity", "number": 4},
            {"type": "quantity", "number": 9},
        ]),
    ], ["teen-ty"], ["oil"]))
    out.append(item("meas-72f", "measures", "It's seventy-two degrees.", [
        slot("t", "temperature", "temperature", {"type": "temperature", "degrees": 72}, [
            {"type": "temperature", "degrees": 27},
            {"type": "temperature", "degrees": 17},
            {"type": "temperature", "degrees": 75},
        ]),
    ], ["teen-ty"], ["weather"]))
    out.append(item("meas-85f", "measures", "High of eighty-five.", [
        slot("t", "temperature", "temperature", {"type": "temperature", "degrees": 85}, [
            {"type": "temperature", "degrees": 18},
            {"type": "temperature", "degrees": 80},
            {"type": "temperature", "degrees": 95},
        ]),
    ], ["teen-ty"], ["weather"]))
    out.append(item("meas-20off", "measures", "Everything's twenty percent off.", [
        slot("p", "percent", "percent", {"type": "percent", "percent": 20}, [
            {"type": "percent", "percent": 50},
            {"type": "price", "cents": 2000},
            {"type": "percent", "percent": 12},
        ]),
    ], ["teen-ty", "scale"], ["percent"]))
    out.append(item("meas-15off", "measures", "That's fifteen percent off.", [
        slot("p", "percent", "percent", {"type": "percent", "percent": 15}, [
            {"type": "percent", "percent": 50},
            {"type": "percent", "percent": 13},
            {"type": "price", "cents": 1500},
        ]),
    ], ["teen-ty"], ["percent"]))
    out.append(item("meas-aisle-14", "measures", "Aisle fourteen.", [
        slot("a", "aisle", "quantity", {"type": "quantity", "number": 14}, [
            {"type": "quantity", "number": 40},
            {"type": "quantity", "number": 4},
            {"type": "quantity", "number": 15},
        ]),
    ], ["teen-ty"], ["aisle"]))
    out.append(item("meas-5below", "measures", "It's five below.", [
        slot("t", "temperature", "temperature", {"type": "temperature", "degrees": -5}, [
            {"type": "temperature", "degrees": 5},
            {"type": "temperature", "degrees": -15},
            {"type": "temperature", "degrees": 0},
        ]),
    ], ["scale"], ["weather"]))
    return out


def mixed_items() -> list[dict]:
    out: list[dict] = []
    out.append(item("mix-hotel-3-402", "mixed", "Check-in is at three, you're in room four oh two.", [
        slot("t", "clock", "clock", clock(3, 0), [clock(4, 2), clock(3, 30), clock(2, 0)]),
        slot("r", "room", "door", room("402"), [clock(3, 0), room("420"), room("412")]),
    ], ["cross-slot-intrusion"], ["hotel"]))
    out.append(item("mix-hotel-3-412-4", "mixed", "Check-in is at three, you're in four twelve, that's the fourth floor.", [
        slot("t", "clock", "clock", clock(3, 0), [clock(4, 12), clock(3, 12), clock(12, 0)]),
        slot("r", "room", "door", room("412"), [room("402"), room("4"), room("420")]),
        slot("f", "floor", "door", room("4F"), [room("14F"), room("412"), room("3F")]),
    ], ["cross-slot-intrusion"], ["hotel"]))
    out.append(item("mix-air-512-c18-1040", "mixed", "Flight five twelve, gate C eighteen, boarding at ten forty.", [
        slot("f", "flight", "flight", {"type": "flight", "text": "512"}, [
            {"type": "flight", "text": "C18"}, {"type": "flight", "text": "520"}, {"type": "flight", "text": "412"},
        ]),
        slot("g", "gate", "gate", gate("C", 18), [gate("C", 80), gate("A", 18), gate("C", 12)]),
        slot("t", "clock", "clock", clock(10, 40), [clock(10, 18), clock(10, 15), clock(2, 40)]),
    ], ["cross-slot-intrusion", "teen-ty"], ["airport"]))
    out.append(item("mix-air-87-b12-240", "mixed", "Flight eighty-seven, gate B twelve, boarding at two forty.", [
        slot("f", "flight", "flight", {"type": "flight", "text": "87"}, [
            {"type": "flight", "text": "18"}, {"type": "flight", "text": "80"}, {"type": "flight", "text": "12"},
        ]),
        slot("g", "gate", "gate", gate("B", 12), [gate("B", 20), gate("A", 12), gate("B", 87)]),
        slot("t", "clock", "clock", clock(2, 40), [clock(2, 12), clock(12, 40), clock(2, 14)]),
    ], ["cross-slot-intrusion"], ["airport"]))
    out.append(item("mix-table-4-715", "mixed", "Table for four at seven fifteen.", [
        slot("q", "count", "quantity", {"type": "quantity", "number": 4}, [
            {"type": "quantity", "number": 7}, {"type": "quantity", "number": 14}, {"type": "quantity", "number": 2},
        ]),
        slot("t", "clock", "clock", clock(7, 15), [clock(7, 50), clock(4, 15), clock(7, 4)]),
    ], ["cross-slot-intrusion", "teen-ty"], ["restaurant"]))
    out.append(item("mix-check-4260-50-740", "mixed", "That's forty-two sixty, you paid fifty, change is seven forty.", [
        slot("t", "amount", "price", money(4260), [money(4216), money(5000), money(740)]),
        slot("p", "amount", "price", money(5000), [money(4260), money(1500), money(500)]),
        slot("c", "amount", "price", money(740), [money(4260), money(704), money(1740)]),
    ], ["cross-slot-intrusion"], ["checkout"]))
    out.append(item("mix-doc-tue-5-230-9", "mixed", "Tuesday the fifth at two thirty, suite nine.", [
        slot("d", "date", "calendar", {"type": "calendar", "month": 3, "day": 5, "weekday": "Tuesday"}, [
            {"type": "calendar", "month": 5, "day": 2, "weekday": "Tuesday"},
            {"type": "calendar", "month": 3, "day": 5, "weekday": "Thursday"},
            {"type": "calendar", "month": 3, "day": 15, "weekday": "Tuesday"},
        ]),
        slot("t", "clock", "clock", clock(2, 30), [clock(5, 0), clock(2, 13), clock(9, 30)]),
        slot("r", "room", "door", room("9"), [room("5"), room("19"), room("2")]),
    ], ["cross-slot-intrusion"], ["clinic"]))
    out.append(item("mix-gas-349-132-4610", "mixed", "Three forty-nine a gallon, you put in thirteen point two, that's forty-six ten.", [
        slot("p", "fuelPrice", "pump", {"type": "fuelPrice", "cents": 349}, [
            {"type": "fuelGallons", "gallons": 13.2}, {"type": "fuelPrice", "cents": 439}, {"type": "price", "cents": 4610},
        ]),
        slot("g", "fuel", "pump", {"type": "fuelGallons", "gallons": 13.2}, [
            {"type": "fuelPrice", "cents": 349}, {"type": "fuelGallons", "gallons": 30.2}, {"type": "price", "cents": 1320},
        ]),
        slot("t", "amount", "price", money(4610), [money(349), money(1320), money(4160)]),
    ], ["cross-slot-intrusion", "scale"], ["gas"]))
    out.append(item("mix-grocery-25lb-740", "mixed", "Two and a half pounds, that's seven forty.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 2.5, "unit": "lb"}, [
            {"type": "price", "cents": 740}, {"type": "weight", "amount": 25, "unit": "lb"}, {"type": "weight", "amount": 7.4, "unit": "lb"},
        ]),
        slot("p", "amount", "price", money(740), [money(250), money(704), money(1740)]),
    ], ["cross-slot-intrusion", "scale"], ["grocery"]))
    out.append(item("mix-hwy-101-12b-24", "mixed", "Stay on one-oh-one to exit twelve B, about two point four miles.", [
        slot("h", "highway", "highway", {"type": "highway", "text": "101"}, [
            {"type": "exit", "text": "12B"}, {"type": "highway", "text": "10"}, {"type": "highway", "text": "110"},
        ]),
        slot("e", "exit", "exit", {"type": "exit", "text": "12B"}, [
            {"type": "highway", "text": "101"}, {"type": "exit", "text": "12"}, {"type": "exit", "text": "2B"},
        ]),
        slot("m", "distance", "mile", {"type": "miles", "miles": 2.4}, [
            {"type": "miles", "miles": 12}, {"type": "miles", "miles": 24}, {"type": "clock", "hour": 2, "minute": 4},
        ]),
    ], ["cross-slot-intrusion"], ["highway"]))
    out.append(item("mix-pickup-1420-10", "mixed", "I'm at fourteen twenty Market, pickup in ten minutes.", [
        slot("n", "address", "address", {"type": "address", "text": "1420"}, [
            {"type": "address", "text": "10"}, {"type": "address", "text": "1402"}, {"type": "address", "text": "1240"},
        ]),
        slot("d", "duration", "duration", {"type": "duration", "minutes": 10}, [
            {"type": "duration", "minutes": 14}, {"type": "duration", "minutes": 20}, {"type": "duration", "minutes": 50},
        ]),
    ], ["cross-slot-intrusion"], ["ride"]))
    out.append(item("mix-desk-thu-5-915-3", "mixed", "Thursday the fifth, nine fifteen, window three.", [
        slot("d", "date", "calendar", {"type": "calendar", "month": 3, "day": 5, "weekday": "Thursday"}, [
            {"type": "calendar", "month": 5, "day": 3, "weekday": "Thursday"},
            {"type": "calendar", "month": 3, "day": 5, "weekday": "Tuesday"},
            {"type": "calendar", "month": 3, "day": 15, "weekday": "Thursday"},
        ]),
        slot("t", "clock", "clock", clock(9, 15), [clock(9, 50), clock(5, 0), clock(9, 3)]),
        slot("w", "window", "quantity", {"type": "quantity", "number": 3}, [
            {"type": "quantity", "number": 5}, {"type": "quantity", "number": 9}, {"type": "quantity", "number": 13},
        ]),
    ], ["cross-slot-intrusion"], ["desk"]))
    out.append(item("mix-air-218-c18", "mixed", "Flight two eighteen, gate C eighteen.", [
        slot("f", "flight", "flight", {"type": "flight", "text": "218"}, [
            {"type": "flight", "text": "C18"}, {"type": "flight", "text": "280"}, {"type": "flight", "text": "118"},
        ]),
        slot("g", "gate", "gate", gate("C", 18), [gate("C", 80), gate("A", 18), gate("B", 218)]),
    ], ["cross-slot-intrusion", "teen-ty"], ["airport"]))
    out.append(item("mix-hotel-715-9b", "mixed", "Your reservation is at seven fifteen, suite nine B.", [
        slot("t", "clock", "clock", clock(7, 15), [clock(7, 50), clock(9, 15), clock(7, 9)]),
        slot("r", "room", "door", room("9B"), [room("7"), room("19B"), room("B9")]),
    ], ["cross-slot-intrusion"], ["hotel"]))
    out.append(item("mix-lunch-1230-6", "mixed", "Lunch is at twelve thirty for a party of six.", [
        slot("t", "clock", "clock", clock(12, 30), [clock(6, 0), clock(12, 13), clock(11, 30)]),
        slot("q", "count", "quantity", {"type": "quantity", "number": 6}, [
            {"type": "quantity", "number": 12}, {"type": "quantity", "number": 16}, {"type": "quantity", "number": 30},
        ]),
    ], ["cross-slot-intrusion"], ["restaurant"]))
    out.append(item("mix-board-1045-c12", "mixed", "Boarding at ten forty-five, gate C twelve.", [
        slot("t", "clock", "clock", clock(10, 45), [clock(10, 12), clock(12, 45), clock(10, 15)]),
        slot("g", "gate", "gate", gate("C", 12), [gate("C", 10), gate("A", 12), gate("C", 45)]),
    ], ["cross-slot-intrusion"], ["airport"]))
    out.append(item("mix-tip-4860-20", "mixed", "Bill's forty-eight sixty. Twenty percent is about ten.", [
        slot("b", "amount", "price", money(4860), [money(4860), money(2010), money(4086)]),
        slot("p", "percent", "percent", {"type": "percent", "percent": 20}, [
            {"type": "percent", "percent": 15}, {"type": "price", "cents": 2000}, {"type": "percent", "percent": 50},
        ]),
        slot("t", "amount", "price", money(1000), [money(4860), money(2000), money(100)]),
    ], ["cross-slot-intrusion"], ["receipt"]))
    # fix duplicate
    out[-1]["slots"][0]["distractors"][0] = money(4816)
    out.append(item("mix-bag-48lb-carousel4", "mixed", "Bag's forty-eight pounds, carousel four.", [
        slot("w", "weight", "scale", {"type": "weight", "amount": 48, "unit": "lb"}, [
            {"type": "quantity", "number": 4}, {"type": "weight", "amount": 84, "unit": "lb"}, {"type": "weight", "amount": 14, "unit": "lb"},
        ]),
        slot("c", "carousel", "quantity", {"type": "quantity", "number": 4}, [
            {"type": "quantity", "number": 48}, {"type": "quantity", "number": 14}, {"type": "quantity", "number": 40},
        ]),
    ], ["cross-slot-intrusion"], ["airport"]))
    out.append(item("mix-fill-132-70mi", "mixed", "You put in thirteen point two gallons. Range is about two hundred seventy miles.", [
        slot("g", "fuel", "pump", {"type": "fuelGallons", "gallons": 13.2}, [
            {"type": "miles", "miles": 270}, {"type": "fuelGallons", "gallons": 30.2}, {"type": "price", "cents": 1320},
        ]),
        slot("m", "distance", "mile", {"type": "miles", "miles": 270}, [
            {"type": "fuelGallons", "gallons": 13.2}, {"type": "miles", "miles": 217}, {"type": "mph", "mph": 70},
        ]),
    ], ["cross-slot-intrusion"], ["gas"]))
    return out


def validate(items: list[dict]) -> None:
    ids = [it["id"] for it in items]
    assert len(ids) == len(set(ids)), "duplicate ids"
    for it in items:
        text = it["spokenText"]
        assert not any(tok in text for tok in ("3:15", "C18", "$", "402")), f"raw token in {it['id']}: {text}"
        for sl in it["slots"]:
            assert len(sl["distractors"]) == 3, it["id"]


def main() -> None:
    items = (
        time_items()
        + date_items()
        + money_items()
        + room_items()
        + travel_items()
        + phone_items()
        + address_items()
        + measure_items()
        + mixed_items()
    )
    validate(items)
    by = {}
    for it in items:
        by[it["scenario"]] = by.get(it["scenario"], 0) + 1
    root = Path(__file__).resolve().parents[1]
    dest = root / "NumSense" / "Content" / "catalog.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps({"version": 1, "items": items}, indent=2) + "\n")
    print(f"wrote {len(items)} items → {dest}")
    print(by)


if __name__ == "__main__":
    main()

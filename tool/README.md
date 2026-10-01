# Voice benchmark (R0)

The R0 exit gate needs a speech-to-text provider chosen against real Vanni
Tamil. This tool scores the phrase parser on transcripts from that benchmark.

1. Record 30+ Vanni speakers saying ledger phrases ("Ravi annai 500 kadan",
   "செல்வி அக்கா இரண்டாயிரம் தந்தார்", …) in a shop setting.
2. Run each recording through every candidate STT provider (on-device Android
   ta-LK, Google Cloud Speech ta-LK, …) and save one CSV per provider:

   ```csv
   speaker_id,transcript,expected_customer,expected_amount,expected_type
   S01,ரவி அண்ணை ஐநூறு கடன்,ரவி,500,credit
   S02,"Kumar thambi 1,500 kadan",Kumar,1500,credit
   ```

   `transcript` is what the provider returned; the `expected_*` columns are
   what the speaker meant. `expected_type` is one of credit, payment, sale,
   expense. Quote any field that contains a comma.
3. Score each provider:

   ```sh
   dart run tool/voice_benchmark.dart benchmark/google_ta_lk.csv
   ```

   It prints amount, customer and type accuracy against the PRD 11 targets
   (amount ≥ 90 %, customer ≥ 85 %), lists every miss, and exits non-zero on a
   miss of the targets.

Use the misses to extend `lib/features/voice/domain/tamil_numbers.dart` and
the word lists in `voice_entry_parser.dart`, then add the phrase to
`test/fixtures/voice_phrases.csv` so it stays fixed.

Customer accuracy here is an exact match on the heard name. Phase 3 matches
against the shop's own customer list by phonetic key, which only improves it.

Keep recordings and real transcripts out of git: they are personal data
under the PDPA.

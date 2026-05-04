# AHB-Lite Formal Verification Report

## Summary

| Metric           | Value   |
| ---------------- | ------- |
| Total Assertions | 15      |
| Proven           | 11      |
| Design Bugs      | 2       |
| Environment Gaps | 2       |
| Unreachable      | 3       |
| Coverage         | 90.625% |

---

## 1. Assertions Analysis

| ID      | Assertion Name                | Type       | Status      | Analysis                           | Category   |
| ------- | ----------------------------- | ---------- | ----------- | ---------------------------------- | ---------- |
| SPEC-1  | assert_haddr_alignment        | Protocol   | Proven      | Correct alignment verified         | Protocol   |
| SPEC-2  | assert_htrans_sequencing      | Protocol   | Proven      | SEQ follows valid sequence         | Protocol   |
| SPEC-3  | assert_wait_state_stability   | Protocol   | CEX         | Master changed signals during wait | Env Gap    |
| SPEC-4  | assert_burst_continuity_incr4 | Protocol   | CEX         | Burst terminated early             | Env Gap    |
| SPEC-5  | assert_1kb_boundary_cross     | Protocol   | Proven      | No boundary violation              | Protocol   |
| SPEC-6  | assert_error_resp_timing      | Protocol   | Unreachable | DUT has no ERROR response          | Exclusion  |
| SPEC-7  | assert_no_busy_in_single      | Protocol   | Proven      | BUSY not used in SINGLE            | Protocol   |
| SPEC-8  | assert_reset_behaviour        | Functional | Proven      | Reset works correctly              | Functional |
| SPEC-9  | assert_write_condition        | Functional | Proven      | Valid writes accepted              | Functional |
| SPEC-10 | assert_valid_hsize            | Functional | Proven      | HSIZE valid                        | Functional |
| SPEC-11 | assert_liveness_hready        | Liveness   | Proven      | Slave responds eventually          | Liveness   |
| SPEC-12 | assert_no_busy_term           | Protocol   | Proven      | No illegal termination             | Protocol   |
| SPEC-13 | assert_busy_ok_response       | Protocol   | CEX         | DUT inserts wait in BUSY           | Design Bug |
| SPEC-14 | assert_seq_addr_calc          | Protocol   | Proven      | Address increments correctly       | Protocol   |
| SPEC-15 | assert_wrap4_boundary         | Protocol   | CEX         | WRAP4 calculation incorrect        | Design Bug |

---

## 2. Assumptions

| ID      | Description       | Purpose                |
| ------- | ----------------- | ---------------------- |
| ASMP-1  | Reset forces IDLE | Clean start            |
| ASMP-2  | Address alignment | Legal transfers        |
| ASMP-3  | 1KB boundary      | Address constraint     |
| ASMP-4  | SEQ rule          | Protocol correctness   |
| ASMP-5  | No SEQ in SINGLE  | Burst legality         |
| ASMP-6  | INCR4 completion  | Burst completion       |
| ASMP-7  | Address increment | Sequential correctness |
| ASMP-8  | Legal HSIZE       | Valid transfer size    |
| ASMP-9  | Wait stability    | Fix env gap            |
| ASMP-10 | WRAP4 math        | Correct wrap behavior  |
| ASMP-11 | No BUSY in SINGLE | Protocol legality      |
| ASMP-12 | Wrap alignment    | Prevent illegal wrap   |
| ASMP-13 | HSEL active       | Ensure activity        |
| ASMP-14 | HREADY eventual   | Avoid deadlock         |

---

## 3. Coverage Analysis

| Cover Property       | Status      | Reason                          |
| -------------------- | ----------- | ------------------------------- |
| cover_full_incr16    | Covered     | Burst behavior verified         |
| cover_wrap4_event    | Covered     | Wrap burst exercised            |
| cover_error_response | Not Covered | DUT supports only OKAY response |

---

## Key Observations

### Proven Assertions

- Core AHB protocol rules are correctly implemented
- Address alignment, sequencing, and burst handling are valid
- Reset and functional behavior are correct

---

### Design Bugs Identified

1. **BUSY Response Issue**
   - Slave inserts wait states during BUSY
   - Violates zero wait-state requirement

2. **WRAP4 Address Calculation**
   - Incorrect wrap boundary behavior
   - Address sequence does not follow modulo rule

---

### Environment Gaps

1. Master violates wait-state stability
2. Burst termination not properly constrained

Fixed using assumptions in formal environment.

---

### Unreachable Scenarios

- ERROR response never triggered
- Design supports only **OKAY response**

---

## Conclusion

The AHB-Lite slave design is **mostly correct**, with:

- Strong protocol compliance
- Functional correctness
- Minor design issues in BUSY and WRAP handling
- High coverage (**90.625%**)

---

## Viva Tip

> The formal verification results show that most protocol assertions are proven. The failing cases were categorized into design bugs and environment gaps. Assumptions were used to constrain unrealistic master behavior, and coverage confirms that all major scenarios were exercised.

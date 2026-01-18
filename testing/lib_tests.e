note
	description: "[
		Comprehensive test suite for simple_qr library.
		Tests are designed to PROVE correctness and BREAK the code.

		Testing strategy:
		1. Mathematical properties (Galois field axioms)
		2. Boundary conditions (version limits, capacity limits)
		3. Known-answer tests (verified against QR spec)
		4. Integration tests (full QR generation pipeline)
		5. Edge cases (empty, max size, special characters)
	]"
	author: "Larry Rix"
	testing: "type/manual"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- QR_GALOIS: Field Axiom Tests

	test_galois_additive_identity
			-- Test: a + 0 = a for all a (XOR with 0 is identity)
		note
			testing: "covers/{QR_GALOIS}.add"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 0 until i > 255 loop
				assert_equal ("add_zero_" + i.out, i, g.add (i, 0))
				i := i + 1
			end
		end

	test_galois_additive_inverse
			-- Test: a + a = 0 for all a (XOR with self is zero)
		note
			testing: "covers/{QR_GALOIS}.add"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 0 until i > 255 loop
				assert_equal ("add_self_zero_" + i.out, 0, g.add (i, i))
				i := i + 1
			end
		end

	test_galois_additive_commutative
			-- Test: a + b = b + a for all a, b
		note
			testing: "covers/{QR_GALOIS}.add"
		local
			g: QR_GALOIS
			a, b: INTEGER
		do
			create g.make
			from a := 0 until a > 255 loop
				from b := 0 until b > 255 loop
					assert_equal ("comm_" + a.out + "_" + b.out, g.add (a, b), g.add (b, a))
					b := b + 16
				end
				a := a + 16
			end
		end

	test_galois_multiplicative_identity
			-- Test: a * 1 = a for all a
		note
			testing: "covers/{QR_GALOIS}.multiply"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 0 until i > 255 loop
				assert_equal ("mult_one_" + i.out, i, g.multiply (i, 1))
				i := i + 1
			end
		end

	test_galois_multiplicative_zero
			-- Test: a * 0 = 0 for all a
		note
			testing: "covers/{QR_GALOIS}.multiply"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 0 until i > 255 loop
				assert_equal ("mult_zero_" + i.out, 0, g.multiply (i, 0))
				i := i + 1
			end
		end

	test_galois_multiplicative_commutative
			-- Test: a * b = b * a for sample values
		note
			testing: "covers/{QR_GALOIS}.multiply"
		local
			g: QR_GALOIS
			a, b: INTEGER
		do
			create g.make
			from a := 1 until a > 255 loop
				from b := 1 until b > 255 loop
					assert_equal ("mult_comm_" + a.out + "_" + b.out, g.multiply (a, b), g.multiply (b, a))
					b := b + 17
				end
				a := a + 17
			end
		end

	test_galois_inverse_property
			-- Test: a * inverse(a) = 1 for all a != 0
		note
			testing: "covers/{QR_GALOIS}.inverse"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 1 until i > 255 loop
				assert_equal ("inverse_mult_" + i.out, 1, g.multiply (i, g.inverse (i)))
				i := i + 1
			end
		end

	test_galois_divide_is_multiply_inverse
			-- Test: a / b = a * inverse(b)
		note
			testing: "covers/{QR_GALOIS}.divide"
		local
			g: QR_GALOIS
			a, b: INTEGER
		do
			create g.make
			from a := 1 until a > 255 loop
				from b := 1 until b > 255 loop
					assert_equal ("div_inv_" + a.out + "_" + b.out,
						g.divide (a, b), g.multiply (a, g.inverse (b)))
					b := b + 17
				end
				a := a + 17
			end
		end

	test_galois_power_zero
			-- Test: a^0 = 1 for all a != 0
		note
			testing: "covers/{QR_GALOIS}.power"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 1 until i > 255 loop
				assert_equal ("power_zero_" + i.out, 1, g.power (i, 0))
				i := i + 1
			end
		end

	test_galois_power_one
			-- Test: a^1 = a for all a
		note
			testing: "covers/{QR_GALOIS}.power"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 0 until i > 255 loop
				assert_equal ("power_one_" + i.out, i, g.power (i, 1))
				i := i + 1
			end
		end

	test_galois_exp_log_inverse
			-- Test: exp(log(a)) = a for all a > 0
		note
			testing: "covers/{QR_GALOIS}.exp"
			testing: "covers/{QR_GALOIS}.log"
		local
			g: QR_GALOIS
			i: INTEGER
		do
			create g.make
			from i := 1 until i > 255 loop
				assert_equal ("exp_log_" + i.out, i, g.exp (g.log (i)))
				i := i + 1
			end
		end

	test_galois_known_values
			-- Test known multiplication results from QR spec
		note
			testing: "covers/{QR_GALOIS}.multiply"
		local
			g: QR_GALOIS
		do
			create g.make
			-- Known values from Reed-Solomon implementations
			assert_equal ("mult_2_3", 6, g.multiply (2, 3))
			assert_equal ("mult_2_2", 4, g.multiply (2, 2))
			assert_equal ("mult_3_3", 5, g.multiply (3, 3))
			assert_equal ("mult_255_255", 226, g.multiply (255, 255))
		end

feature -- QR_VERSION: Version Calculation Tests

	test_version_module_count_formula
			-- Test: modules = 17 + version * 4 for all versions
		note
			testing: "covers/{QR_VERSION}.module_count"
		local
			v: QR_VERSION
			i: INTEGER
		do
			create v.make
			from i := 1 until i > 40 loop
				assert_equal ("modules_v" + i.out, 17 + i * 4, v.module_count (i))
				i := i + 1
			end
		end

	test_version_module_count_boundaries
			-- Test boundary versions
		note
			testing: "covers/{QR_VERSION}.module_count"
		local
			v: QR_VERSION
		do
			create v.make
			assert_equal ("v1_modules", 21, v.module_count (1))
			assert_equal ("v40_modules", 177, v.module_count (40))
		end

	test_version_capacity_increases_monotonic
			-- Test: capacity increases with version for all modes/EC levels
		note
			testing: "covers/{QR_VERSION}.character_capacity"
		local
			v: QR_VERSION
			l_version: INTEGER
			l_prev_cap, l_curr_cap: INTEGER
			l_modes: ARRAY [INTEGER]
			l_ec_levels: ARRAY [INTEGER]
		do
			create v.make
			l_modes := <<v.Mode_numeric, v.Mode_alphanumeric, v.Mode_byte>>
			l_ec_levels := <<1, 2, 3, 4>>

			across l_modes as m loop
				across l_ec_levels as ec loop
					l_prev_cap := 0
					from l_version := 1 until l_version > 10 loop
						l_curr_cap := v.character_capacity (l_version, m, ec)
						assert_true ("cap_monotonic_m" + m.out + "_ec" + ec.out + "_v" + l_version.out,
							l_curr_cap >= l_prev_cap)
						l_prev_cap := l_curr_cap
						l_version := l_version + 1
					end
				end
			end
		end

	test_version_capacity_ec_decreases
			-- Test: higher EC level = lower capacity (same version, same mode)
		note
			testing: "covers/{QR_VERSION}.character_capacity"
		local
			v: QR_VERSION
			l_version: INTEGER
			l_cap_l, l_cap_m, l_cap_q, l_cap_h: INTEGER
		do
			create v.make
			from l_version := 1 until l_version > 10 loop
				-- Test numeric mode
				l_cap_l := v.character_capacity (l_version, v.Mode_numeric, 1)
				l_cap_m := v.character_capacity (l_version, v.Mode_numeric, 2)
				l_cap_q := v.character_capacity (l_version, v.Mode_numeric, 3)
				l_cap_h := v.character_capacity (l_version, v.Mode_numeric, 4)
				assert_true ("cap_L>=M_v" + l_version.out, l_cap_l >= l_cap_m)
				assert_true ("cap_M>=Q_v" + l_version.out, l_cap_m >= l_cap_q)
				assert_true ("cap_Q>=H_v" + l_version.out, l_cap_q >= l_cap_h)
				l_version := l_version + 1
			end
		end

	test_version_capacity_mode_efficiency
			-- Test: numeric > alphanumeric > byte capacity
		note
			testing: "covers/{QR_VERSION}.character_capacity"
		local
			v: QR_VERSION
			l_version, l_ec: INTEGER
			l_num, l_alpha, l_byte: INTEGER
		do
			create v.make
			from l_version := 1 until l_version > 10 loop
				from l_ec := 1 until l_ec > 4 loop
					l_num := v.character_capacity (l_version, v.Mode_numeric, l_ec)
					l_alpha := v.character_capacity (l_version, v.Mode_alphanumeric, l_ec)
					l_byte := v.character_capacity (l_version, v.Mode_byte, l_ec)
					assert_true ("num>alpha_v" + l_version.out + "_ec" + l_ec.out, l_num > l_alpha)
					assert_true ("alpha>byte_v" + l_version.out + "_ec" + l_ec.out, l_alpha > l_byte)
					l_ec := l_ec + 1
				end
				l_version := l_version + 1
			end
		end

	test_version_minimum_version_known_values
			-- Test minimum version calculation for known data sizes
		note
			testing: "covers/{QR_VERSION}.minimum_version"
		local
			v: QR_VERSION
		do
			create v.make
			-- Version 1 numeric capacity (M level) is 34
			assert_equal ("short_num_v1", 1, v.minimum_version ("123", v.Mode_numeric, 2))
			-- Version 1 alphanumeric capacity (M level) is 20
			assert_equal ("short_alpha_v1", 1, v.minimum_version ("HELLO", v.Mode_alphanumeric, 2))
			-- Version 1 byte capacity (M level) is 14
			assert_equal ("short_byte_v1", 1, v.minimum_version ("Hello", v.Mode_byte, 2))
		end

	test_version_minimum_version_boundary
			-- Test: data at exact capacity boundary
		note
			testing: "covers/{QR_VERSION}.minimum_version"
		local
			v: QR_VERSION
			l_data: STRING
		do
			create v.make
			-- V1/M/numeric capacity is 34 - exactly 34 chars should fit v1
			create l_data.make_filled ('9', 34)
			assert_equal ("exact_v1_cap", 1, v.minimum_version (l_data, v.Mode_numeric, 2))
			-- 35 chars should require v2
			create l_data.make_filled ('9', 35)
			assert_equal ("v2_needed", 2, v.minimum_version (l_data, v.Mode_numeric, 2))
		end

	test_version_data_too_large
			-- Test: data exceeding all versions returns 0
		note
			testing: "covers/{QR_VERSION}.minimum_version"
		local
			v: QR_VERSION
			l_data: STRING
		do
			create v.make
			-- V40/L/numeric max is around 7089 chars
			-- Create data larger than any version can handle
			create l_data.make_filled ('9', 8000)
			assert_equal ("too_large", 0, v.minimum_version (l_data, v.Mode_numeric, 1))
		end

feature -- QR_ENCODER: Mode Detection Tests

	test_encoder_detect_numeric
			-- Test numeric mode detection
		note
			testing: "covers/{QR_ENCODER}.detect_mode"
		local
			e: QR_ENCODER
		do
			create e.make
			assert_equal ("empty_digits", e.Mode_numeric, e.detect_mode ("0"))
			assert_equal ("all_digits", e.Mode_numeric, e.detect_mode ("0123456789"))
			assert_equal ("phone", e.Mode_numeric, e.detect_mode ("5551234567"))
		end

	test_encoder_detect_alphanumeric
			-- Test alphanumeric mode detection
		note
			testing: "covers/{QR_ENCODER}.detect_mode"
		local
			e: QR_ENCODER
		do
			create e.make
			assert_equal ("uppercase", e.Mode_alphanumeric, e.detect_mode ("HELLO"))
			assert_equal ("mixed_num_upper", e.Mode_alphanumeric, e.detect_mode ("ABC123"))
			assert_equal ("with_space", e.Mode_alphanumeric, e.detect_mode ("HELLO WORLD"))
			assert_equal ("with_special", e.Mode_alphanumeric, e.detect_mode ("ABC-123"))
			assert_equal ("all_alphanum_chars", e.Mode_alphanumeric,
				e.detect_mode ("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%%*+-./:"))
		end

	test_encoder_detect_byte
			-- Test byte mode detection (lowercase forces byte mode)
		note
			testing: "covers/{QR_ENCODER}.detect_mode"
		local
			e: QR_ENCODER
		do
			create e.make
			assert_equal ("lowercase", e.Mode_byte, e.detect_mode ("hello"))
			assert_equal ("mixed_case", e.Mode_byte, e.detect_mode ("Hello"))
			assert_equal ("special", e.Mode_byte, e.detect_mode ("hello!"))
			assert_equal ("unicode_like", e.Mode_byte, e.detect_mode ("@#&"))
		end

	test_encoder_numeric_encoding
			-- Test numeric encoding produces correct bit count
		note
			testing: "covers/{QR_ENCODER}.encode"
		local
			e: QR_ENCODER
		do
			create e.make
			-- 3 digits = 10 bits of data + mode(4) + count(10 for v1) = 24 base + terminator/padding
			e.encode ("123", 1)
			assert_true ("numeric_bits_positive", e.bit_count > 0)
			-- Should produce complete bytes
			assert_equal ("byte_aligned", 0, e.bit_count \\ 8)
		end

	test_encoder_alphanumeric_encoding
			-- Test alphanumeric encoding
		note
			testing: "covers/{QR_ENCODER}.encode"
		local
			e: QR_ENCODER
		do
			create e.make
			-- 2 chars = 11 bits, 1 char = 6 bits
			e.encode ("AC", 1)  -- 2 chars = 11 bits data
			assert_true ("alpha_bits_positive", e.bit_count > 0)
			assert_equal ("alpha_byte_aligned", 0, e.bit_count \\ 8)
		end

	test_encoder_byte_encoding
			-- Test byte encoding
		note
			testing: "covers/{QR_ENCODER}.encode"
		local
			e: QR_ENCODER
		do
			create e.make
			e.encode ("Hi", 1)  -- 2 chars = 16 bits data
			assert_true ("byte_bits_positive", e.bit_count > 0)
			assert_equal ("byte_byte_aligned", 0, e.bit_count \\ 8)
		end

	test_encoder_to_codewords
			-- Test conversion to codewords
		note
			testing: "covers/{QR_ENCODER}.to_codewords"
		local
			e: QR_ENCODER
			cw: ARRAY [INTEGER]
		do
			create e.make
			e.encode ("123", 1)
			cw := e.to_codewords
			assert_true ("codewords_exist", cw.count > 0)
			-- All codewords should be 0-255
			across cw as c loop
				assert_true ("cw_in_range_" + @c.cursor_index.out, c >= 0 and c <= 255)
			end
		end

	test_encoder_version_affects_count_bits
			-- Test that version affects character count bit length
		note
			testing: "covers/{QR_ENCODER}.encode"
		local
			e1, e2: QR_ENCODER
		do
			create e1.make
			create e2.make
			-- Same data, different versions
			e1.encode ("123", 1)   -- v1-9: 10 bits for numeric count
			e2.encode ("123", 10)  -- v10-26: 12 bits for numeric count
			-- Version 10 should produce slightly more bits due to longer count field
			assert_true ("v10_more_bits", e2.bit_count >= e1.bit_count)
		end

feature -- QR_ERROR_CORRECTION: Reed-Solomon Tests

	test_ec_generator_polynomial_length
			-- Test generator polynomial has correct length
		note
			testing: "covers/{QR_ERROR_CORRECTION}.generate_codewords"
		local
			ec: QR_ERROR_CORRECTION
			cw, ec_cw: ARRAY [INTEGER]
		do
			create ec.make (2)  -- Level M
			-- V1/M has 10 EC codewords
			cw := <<32, 65, 205, 69, 41, 220, 46, 128, 236>>
			ec_cw := ec.generate_codewords (cw, 1)
			assert_equal ("ec_count_v1m", 10, ec_cw.count)
		end

	test_ec_codewords_nonzero
			-- Test EC codewords are not all zero (would indicate broken algorithm)
		note
			testing: "covers/{QR_ERROR_CORRECTION}.generate_codewords"
		local
			ec: QR_ERROR_CORRECTION
			cw, ec_cw: ARRAY [INTEGER]
			l_has_nonzero: BOOLEAN
		do
			create ec.make (2)
			cw := <<1, 2, 3, 4, 5, 6, 7, 8, 9>>
			ec_cw := ec.generate_codewords (cw, 1)
			l_has_nonzero := False
			across ec_cw as c loop
				if c /= 0 then
					l_has_nonzero := True
				end
			end
			assert_true ("ec_not_all_zero", l_has_nonzero)
		end

	test_ec_codewords_in_range
			-- Test all EC codewords are in valid GF(2^8) range
		note
			testing: "covers/{QR_ERROR_CORRECTION}.generate_codewords"
		local
			ec: QR_ERROR_CORRECTION
			cw, ec_cw: ARRAY [INTEGER]
		do
			create ec.make (2)
			cw := <<100, 150, 200, 50, 75, 125, 175, 225, 25>>
			ec_cw := ec.generate_codewords (cw, 1)
			across ec_cw as c loop
				assert_true ("ec_in_range_" + @c.cursor_index.out, c >= 0 and c <= 255)
			end
		end

	test_ec_interleave_total
			-- Test interleaved result has correct total count
		note
			testing: "covers/{QR_ERROR_CORRECTION}.interleave_blocks"
		local
			ec: QR_ERROR_CORRECTION
			l_data, l_ec, l_result: ARRAY [INTEGER]
		do
			create ec.make (2)
			l_data := <<1, 2, 3, 4, 5>>
			l_ec := <<10, 20, 30>>
			l_result := ec.interleave_blocks (l_data, l_ec, 1)
			assert_equal ("interleave_total", 8, l_result.count)
		end

	test_ec_different_levels
			-- Test different EC levels produce different EC codeword counts
		note
			testing: "covers/{QR_ERROR_CORRECTION}.ec_codewords_per_block"
		local
			ec_l, ec_m, ec_q, ec_h: QR_ERROR_CORRECTION
		do
			create ec_l.make (1)
			create ec_m.make (2)
			create ec_q.make (3)
			create ec_h.make (4)
			-- Higher EC = more EC codewords (for same version)
			assert_true ("l<m", ec_l.ec_codewords_per_block (1) < ec_m.ec_codewords_per_block (1))
			assert_true ("m<q", ec_m.ec_codewords_per_block (1) < ec_q.ec_codewords_per_block (1))
			assert_true ("q<h", ec_q.ec_codewords_per_block (1) < ec_h.ec_codewords_per_block (1))
		end

feature -- QR_MATRIX: Pattern Tests

	test_matrix_size_formula
			-- Test matrix size follows 17 + v*4 formula
		note
			testing: "covers/{QR_MATRIX}.make"
		local
			m: QR_MATRIX
			v: INTEGER
		do
			from v := 1 until v > 10 loop
				create m.make (v)
				assert_equal ("size_v" + v.out, 17 + v * 4, m.size)
				v := v + 1
			end
		end

	test_matrix_finder_pattern_positions
			-- Test finder patterns at correct positions
		note
			testing: "covers/{QR_MATRIX}.place_finder_patterns"
		local
			m: QR_MATRIX
		do
			create m.make (1)
			m.place_finder_patterns
			-- Top-left finder: dark at (1,1), (1,7), (7,1), (7,7) corners
			assert_true ("tl_corner_11", m.is_dark (1, 1))
			assert_true ("tl_corner_17", m.is_dark (1, 7))
			assert_true ("tl_corner_71", m.is_dark (7, 1))
			assert_true ("tl_corner_77", m.is_dark (7, 7))
			-- Top-right finder
			assert_true ("tr_corner", m.is_dark (1, m.size - 6))
			-- Bottom-left finder
			assert_true ("bl_corner", m.is_dark (m.size - 6, 1))
		end

	test_matrix_finder_pattern_center
			-- Test finder pattern 3x3 dark center
		note
			testing: "covers/{QR_MATRIX}.place_finder_patterns"
		local
			m: QR_MATRIX
			r, c: INTEGER
		do
			create m.make (1)
			m.place_finder_patterns
			-- 3x3 center should be dark (rows 3-5, cols 3-5)
			from r := 3 until r > 5 loop
				from c := 3 until c > 5 loop
					assert_true ("center_" + r.out + "_" + c.out, m.is_dark (r, c))
					c := c + 1
				end
				r := r + 1
			end
		end

	test_matrix_timing_pattern_alternates
			-- Test timing patterns alternate dark/light
		note
			testing: "covers/{QR_MATRIX}.place_timing_patterns"
		local
			m: QR_MATRIX
			i: INTEGER
			l_expected: BOOLEAN
		do
			create m.make (1)
			m.place_finder_patterns
			m.place_timing_patterns
			-- Horizontal timing: row 7, cols 9 to size-8
			from i := 9 until i > m.size - 8 loop
				l_expected := ((i - 9) \\ 2) = 0
				assert_equal ("timing_h_" + i.out, l_expected, m.is_dark (7, i))
				i := i + 1
			end
			-- Vertical timing: col 7, rows 9 to size-8
			from i := 9 until i > m.size - 8 loop
				l_expected := ((i - 9) \\ 2) = 0
				assert_equal ("timing_v_" + i.out, l_expected, m.is_dark (i, 7))
				i := i + 1
			end
		end

	test_matrix_reserved_areas
			-- Test function patterns mark areas as reserved
		note
			testing: "covers/{QR_MATRIX}.is_reserved"
		local
			m: QR_MATRIX
		do
			create m.make (1)
			m.place_finder_patterns
			-- Finder pattern areas should be reserved
			assert_true ("tl_reserved", m.is_reserved (1, 1))
			assert_true ("tr_reserved", m.is_reserved (1, m.size))
			assert_true ("bl_reserved", m.is_reserved (m.size, 1))
		end

	test_matrix_mask_patterns
			-- Test all 8 mask patterns produce different results
		note
			testing: "covers/{QR_MATRIX}.apply_mask"
		local
			m: QR_MATRIX
			l_results: ARRAYED_LIST [BOOLEAN]
			l_mask: INTEGER
		do
			create l_results.make (8)
			from l_mask := 0 until l_mask > 7 loop
				create m.make (1)
				m.place_finder_patterns
				m.place_timing_patterns
				-- Place some data first
				m.set_module (10, 10, True)
				m.apply_mask (l_mask)
				l_results.extend (m.is_dark (10, 10))
				l_mask := l_mask + 1
			end
			-- Not all results should be the same (masks should differ)
			assert_true ("masks_differ", l_results.has (True) and l_results.has (False))
		end

	test_matrix_dark_module
			-- Test dark module is always placed
		note
			testing: "covers/{QR_MATRIX}.place_timing_patterns"
		local
			m: QR_MATRIX
		do
			create m.make (1)
			m.place_timing_patterns
			-- Dark module at (size-7, 9) = (14, 9) for v1
			assert_true ("dark_module", m.is_dark (m.size - 7, 9))
		end

feature -- SIMPLE_QR: Integration Tests

	test_qr_make_defaults
			-- Test default initialization
		note
			testing: "covers/{SIMPLE_QR}.make"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			assert_equal ("default_ec", qr.Level_m, qr.error_correction)
			assert_equal ("default_version", 0, qr.version)
			assert_true ("empty_data", qr.data.is_empty)
			assert_true ("no_matrix", not qr.is_generated)
			assert_true ("no_error", not qr.has_error)
		end

	test_qr_make_with_level
			-- Test initialization with specific EC level
		note
			testing: "covers/{SIMPLE_QR}.make_with_level"
		local
			qr: SIMPLE_QR
		do
			create qr.make_with_level (4)  -- Level_h = 4
			assert_equal ("ec_h_set", 4, qr.error_correction)
		end

	test_qr_set_data
			-- Test data setting
		note
			testing: "covers/{SIMPLE_QR}.set_data"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("Test")
			assert_equal ("data_set", "Test", qr.data)
		end

	test_qr_set_data_clears_matrix
			-- Test setting data invalidates existing matrix
		note
			testing: "covers/{SIMPLE_QR}.set_data"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("Test1")
			qr.generate
			assert_true ("was_generated", qr.is_generated)
			qr.set_data ("Test2")
			assert_true ("matrix_cleared", not qr.is_generated)
		end

	test_qr_generate_numeric
			-- Test generating QR with numeric data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("12345")
			qr.generate
			assert_true ("is_generated", qr.is_generated)
			assert_true ("no_error", not qr.has_error)
			assert_equal ("v1_size", 21, qr.module_count)
		end

	test_qr_generate_alphanumeric
			-- Test generating QR with alphanumeric data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("HELLO WORLD")
			qr.generate
			assert_true ("is_generated", qr.is_generated)
			assert_true ("no_error", not qr.has_error)
		end

	test_qr_generate_byte
			-- Test generating QR with byte mode data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("Hello, World!")
			qr.generate
			assert_true ("is_generated", qr.is_generated)
			assert_true ("no_error", not qr.has_error)
		end

	test_qr_generate_all_ec_levels
			-- Test generating with all EC levels
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
			l_levels: ARRAY [INTEGER]
		do
			l_levels := <<1, 2, 3, 4>>  -- L, M, Q, H
			across l_levels as lvl loop
				create qr.make_with_level (lvl)
				qr.set_data ("TEST")
				qr.generate
				assert_true ("gen_ec" + lvl.out, qr.is_generated)
			end
		end

	test_qr_to_ascii_art
			-- Test ASCII art generation
		note
			testing: "covers/{SIMPLE_QR}.to_ascii_art"
		local
			qr: SIMPLE_QR
			art: STRING
		do
			create qr.make
			qr.set_data ("HI")
			qr.generate
			art := qr.to_ascii_art
			assert_true ("art_not_empty", not art.is_empty)
			assert_true ("art_has_newlines", art.has ('%N'))
			assert_true ("art_has_dark", art.has ('#'))
		end

	test_qr_to_pbm
			-- Test PBM format generation
		note
			testing: "covers/{SIMPLE_QR}.to_pbm"
		local
			qr: SIMPLE_QR
			pbm: STRING
		do
			create qr.make
			qr.set_data ("HI")
			qr.generate
			pbm := qr.to_pbm
			assert_true ("pbm_starts_p1", pbm.starts_with ("P1"))
			assert_true ("pbm_has_dimensions", pbm.has_substring ("21 21"))  -- V1 is 21x21
			assert_true ("pbm_has_pixels", pbm.has ('0') and pbm.has ('1'))
		end

	test_qr_module_access
			-- Test individual module access
		note
			testing: "covers/{SIMPLE_QR}.is_dark_module"
		local
			qr: SIMPLE_QR
			r, c: INTEGER
			l_dark_count: INTEGER
		do
			create qr.make
			qr.set_data ("HI")
			qr.generate
			-- Count dark modules - should have some but not all
			from r := 1 until r > qr.module_count loop
				from c := 1 until c > qr.module_count loop
					if qr.is_dark_module (r, c) then
						l_dark_count := l_dark_count + 1
					end
					c := c + 1
				end
				r := r + 1
			end
			assert_true ("some_dark", l_dark_count > 0)
			assert_true ("not_all_dark", l_dark_count < qr.module_count * qr.module_count)
		end

	test_qr_version_auto_selection
			-- Test version auto-selects based on data size
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr1, qr2: SIMPLE_QR
		do
			-- Small data should use v1
			create qr1.make
			qr1.set_data ("HI")
			qr1.generate
			assert_equal ("small_data_v1", 21, qr1.module_count)

			-- Larger data should use higher version
			create qr2.make
			qr2.set_data ("This is a longer string that requires more capacity than version 1 provides")
			qr2.generate
			assert_true ("larger_data_higher_version", qr2.module_count > 21)
		end

feature -- SIMPLE_QR: Edge Cases

	test_qr_single_char
			-- Test single character data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("X")
			qr.generate
			assert_true ("single_char_ok", qr.is_generated)
		end

	test_qr_max_v1_capacity
			-- Test data within V1 capacity boundary
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
			l_data: STRING
		do
			create qr.make
			-- V1/M/numeric capacity is 34, use 30 to account for encoding overhead
			create l_data.make_filled ('9', 30)
			qr.set_data (l_data)
			qr.generate
			assert_true ("v1_cap_ok", qr.is_generated)
			assert_equal ("uses_v1", 21, qr.module_count)
		end

	test_qr_special_characters
			-- Test special characters in byte mode
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("!@#$%%^&*()_+-=[]{}|;':,./<>?")
			qr.generate
			assert_true ("special_chars_ok", qr.is_generated)
		end

	test_qr_url
			-- Test typical URL data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("https://example.com/path?query=value")
			qr.generate
			assert_true ("url_ok", qr.is_generated)
		end

	test_qr_vcard_like
			-- Test vCard-like structured data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			create qr.make
			qr.set_data ("BEGIN:VCARD%NVERSION:3.0%NFN:John Doe%NEND:VCARD")
			qr.generate
			assert_true ("vcard_ok", qr.is_generated)
		end

	test_qr_pure_numeric_long
			-- Test long numeric-only data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
			l_data: STRING
		do
			create qr.make
			create l_data.make_filled ('1', 200)
			qr.set_data (l_data)
			qr.generate
			assert_true ("long_numeric_ok", qr.is_generated)
		end

	test_qr_pure_alphanumeric_long
			-- Test long alphanumeric data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
			l_data: STRING
		do
			create qr.make
			create l_data.make_filled ('A', 100)
			qr.set_data (l_data)
			qr.generate
			assert_true ("long_alpha_ok", qr.is_generated)
		end

feature -- QR_MATRIX: Boundary Tests

	test_matrix_v1_boundaries
			-- Test V1 matrix boundaries
		note
			testing: "covers/{QR_MATRIX}.make"
		local
			m: QR_MATRIX
		do
			create m.make (1)
			assert_equal ("v1_size", 21, m.size)
			-- Should be able to access corners
			assert_true ("can_access_11", True)
			m.set_module (1, 1, True)
			m.set_module (21, 21, True)
			assert_true ("corners_accessible", m.is_dark (1, 1) and m.is_dark (21, 21))
		end

	test_matrix_v40_boundaries
			-- Test V40 (max version) matrix
		note
			testing: "covers/{QR_MATRIX}.make"
		local
			m: QR_MATRIX
		do
			create m.make (40)
			assert_equal ("v40_size", 177, m.size)
			m.set_module (177, 177, True)
			assert_true ("v40_corner", m.is_dark (177, 177))
		end

feature -- Integration: Full Pipeline Tests

	test_full_pipeline_numeric
			-- Test complete pipeline with numeric data
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
			l_dark_count, l_total: INTEGER
			r, c: INTEGER
		do
			create qr.make
			qr.set_data ("0123456789")
			qr.generate

			assert_true ("pipeline_generated", qr.is_generated)
			assert_true ("pipeline_no_error", not qr.has_error)

			-- Verify reasonable dark/light ratio (QR codes are ~50% dark)
			l_total := qr.module_count * qr.module_count
			from r := 1 until r > qr.module_count loop
				from c := 1 until c > qr.module_count loop
					if qr.is_dark_module (r, c) then
						l_dark_count := l_dark_count + 1
					end
					c := c + 1
				end
				r := r + 1
			end
			-- Dark ratio should be roughly 30-70%
			assert_true ("dark_ratio_reasonable",
				l_dark_count > l_total * 30 // 100 and l_dark_count < l_total * 70 // 100)
		end

	test_full_pipeline_all_modes
			-- Test pipeline with data forcing each mode
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr: SIMPLE_QR
		do
			-- Numeric mode
			create qr.make
			qr.set_data ("0123456789")
			qr.generate
			assert_true ("numeric_pipeline", qr.is_generated)

			-- Alphanumeric mode
			create qr.make
			qr.set_data ("HELLO WORLD 123")
			qr.generate
			assert_true ("alpha_pipeline", qr.is_generated)

			-- Byte mode
			create qr.make
			qr.set_data ("Hello, World!")
			qr.generate
			assert_true ("byte_pipeline", qr.is_generated)
		end

	test_determinism
			-- Test same input produces same output
		note
			testing: "covers/{SIMPLE_QR}.generate"
		local
			qr1, qr2: SIMPLE_QR
			r, c: INTEGER
			l_match: BOOLEAN
		do
			create qr1.make
			qr1.set_data ("DETERMINISM TEST")
			qr1.generate

			create qr2.make
			qr2.set_data ("DETERMINISM TEST")
			qr2.generate

			l_match := True
			from r := 1 until r > qr1.module_count or not l_match loop
				from c := 1 until c > qr1.module_count or not l_match loop
					if qr1.is_dark_module (r, c) /= qr2.is_dark_module (r, c) then
						l_match := False
					end
					c := c + 1
				end
				r := r + 1
			end
			assert_true ("deterministic", l_match)
		end

end

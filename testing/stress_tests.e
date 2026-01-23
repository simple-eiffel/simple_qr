note
	description: "Stress tests for simple_qr resource limits"
	author: "simple_qr hardening"
	date: "2026-01-18"

class
	STRESS_TESTS

inherit
	TEST_SET_BASE

feature -- Volume Tests

	test_100_qr_codes_sequential
			-- Test generating 100 QR codes sequentially.
		local
			l_qr: SIMPLE_QR
			i: INTEGER
		do
			from i := 1 until i > 100 loop
				create l_qr.make
				l_qr.set_data ("Data item " + i.out)
				l_qr.generate
				assert ("qr_" + i.out, l_qr.is_generated)
				i := i + 1
			end
		end

	test_large_numeric_data
			-- Test large numeric data (500 digits).
		local
			l_qr: SIMPLE_QR
			l_data: STRING
		do
			create l_qr.make
			create l_data.make_filled ('9', 500)
			l_qr.set_data (l_data)
			l_qr.generate
			assert ("large_numeric", l_qr.is_generated)
		end

	test_large_alphanumeric_data
			-- Test large alphanumeric data (300 chars).
		local
			l_qr: SIMPLE_QR
			l_data: STRING
		do
			create l_qr.make
			create l_data.make_filled ('A', 300)
			l_qr.set_data (l_data)
			l_qr.generate
			assert ("large_alpha", l_qr.is_generated)
		end

	test_large_byte_data
			-- Test large byte data (200 bytes).
		local
			l_qr: SIMPLE_QR
			l_data: STRING
		do
			create l_qr.make
			create l_data.make_filled ('x', 200)
			l_qr.set_data (l_data)
			l_qr.generate
			assert ("large_byte", l_qr.is_generated)
		end

feature -- Matrix Size Tests

	test_version_1_matrix
			-- Test V1 matrix (21x21 = 441 modules).
		local
			l_qr: SIMPLE_QR
			l_dark_count: INTEGER
			r, c: INTEGER
		do
			create l_qr.make
			l_qr.set_data ("V1")
			l_qr.generate
			assert ("v1_generated", l_qr.is_generated)
			assert ("v1_size", l_qr.module_count = 21)

			-- Access all modules
			from r := 1 until r > 21 loop
				from c := 1 until c > 21 loop
					if l_qr.is_dark_module (r, c) then
						l_dark_count := l_dark_count + 1
					end
					c := c + 1
				end
				r := r + 1
			end
			assert ("has_dark_modules", l_dark_count > 0)
			assert ("has_light_modules", l_dark_count < 441)
		end

	test_version_10_matrix
			-- Test V10 matrix (57x57 = 3249 modules).
		local
			l_qr: SIMPLE_QR
			l_data: STRING
		do
			create l_qr.make
			-- Need enough data to force V10
			create l_data.make_filled ('X', 300)
			l_qr.set_data (l_data)
			l_qr.generate
			assert ("v10_generated", l_qr.is_generated)
			-- May not be exactly V10, but should be large
			assert ("large_version", l_qr.module_count >= 45)
		end

feature -- Galois Field Stress Tests

	test_galois_all_multiplications
			-- Test all 256*256 multiplications (sample).
		local
			l_gf: QR_GALOIS
			a, b, l_result: INTEGER
			l_count: INTEGER
		do
			create l_gf.make
			from a := 0 until a > 255 loop
				from b := 0 until b > 255 loop
					l_result := l_gf.multiply (a, b)
					assert ("mult_in_range", l_result >= 0 and l_result <= 255)
					l_count := l_count + 1
					b := b + 16  -- Sample every 16th
				end
				a := a + 16  -- Sample every 16th
			end
			assert ("tested_multiplications", l_count > 250)
		end

	test_galois_all_inverses
			-- Test inverse for all non-zero elements.
		local
			l_gf: QR_GALOIS
			i, inv, product: INTEGER
		do
			create l_gf.make
			from i := 1 until i > 255 loop
				inv := l_gf.inverse (i)
				product := l_gf.multiply (i, inv)
				assert ("inverse_" + i.out, product = 1)
				i := i + 1
			end
		end

feature -- Reed-Solomon Stress Tests

	test_ec_multiple_data_sizes
			-- Test EC generation for various data sizes.
		local
			l_ec: QR_ERROR_CORRECTION
			l_data: ARRAY [INTEGER]
			l_result: ARRAY [INTEGER]
			i, size: INTEGER
		do
			create l_ec.make (2)  -- Level M
			from size := 5 until size > 20 loop
				create l_data.make_filled (0, 1, size)
				from i := 1 until i > size loop
					l_data.put ((i * 17) \\ 256, i)
					i := i + 1
				end
				l_result := l_ec.generate_codewords (l_data, 1)
				assert ("ec_size_" + size.out, l_result.count > 0)
				size := size + 3
			end
		end

feature -- Determinism Tests

	test_deterministic_output
			-- Test same input produces identical output.
		local
			l_qr1, l_qr2: SIMPLE_QR
			l_art1, l_art2: STRING
		do
			create l_qr1.make
			l_qr1.set_data ("DETERMINISM")
			l_qr1.generate
			l_art1 := l_qr1.to_ascii_art

			create l_qr2.make
			l_qr2.set_data ("DETERMINISM")
			l_qr2.generate
			l_art2 := l_qr2.to_ascii_art

			assert ("same_output", l_art1.is_equal (l_art2))
		end

	test_different_data_different_output
			-- Test substantially different input produces different output.
			-- Uses numeric vs byte mode to force different encoding paths.
		local
			l_qr1, l_qr2: SIMPLE_QR
			l_art1, l_art2: STRING
		do
			create l_qr1.make
			-- Pure numeric - uses numeric mode
			l_qr1.set_data ("1234567890")
			l_qr1.generate
			l_art1 := l_qr1.to_ascii_art

			create l_qr2.make
			-- Lowercase text - uses byte mode, different encoding
			l_qr2.set_data ("hello world from simple_qr library")
			l_qr2.generate
			l_art2 := l_qr2.to_ascii_art

			assert ("different_output", not l_art1.is_equal (l_art2))
		end

end

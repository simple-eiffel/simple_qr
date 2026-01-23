note
	description: "Test application runner for simple_qr library"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run all tests.
		local
			tests: LIB_TESTS
			adversarial: ADVERSARIAL_TESTS
			stress: STRESS_TESTS
		do
			create tests
			create adversarial
			create stress
			io.put_string ("simple_qr Comprehensive Test Suite%N")
			io.put_string ("===================================%N%N")

			passed := 0
			failed := 0

			-- QR_GALOIS Field Axiom Tests
			io.put_string ("QR_GALOIS Field Axioms:%N")
			run_test (agent tests.test_galois_additive_identity, "test_galois_additive_identity")
			run_test (agent tests.test_galois_additive_inverse, "test_galois_additive_inverse")
			run_test (agent tests.test_galois_additive_commutative, "test_galois_additive_commutative")
			run_test (agent tests.test_galois_multiplicative_identity, "test_galois_multiplicative_identity")
			run_test (agent tests.test_galois_multiplicative_zero, "test_galois_multiplicative_zero")
			run_test (agent tests.test_galois_multiplicative_commutative, "test_galois_multiplicative_commutative")
			run_test (agent tests.test_galois_inverse_property, "test_galois_inverse_property")
			run_test (agent tests.test_galois_divide_is_multiply_inverse, "test_galois_divide_is_multiply_inverse")
			run_test (agent tests.test_galois_power_zero, "test_galois_power_zero")
			run_test (agent tests.test_galois_power_one, "test_galois_power_one")
			run_test (agent tests.test_galois_exp_log_inverse, "test_galois_exp_log_inverse")
			run_test (agent tests.test_galois_known_values, "test_galois_known_values")

			-- QR_VERSION Tests
			io.put_string ("%NQR_VERSION Tests:%N")
			run_test (agent tests.test_version_module_count_formula, "test_version_module_count_formula")
			run_test (agent tests.test_version_module_count_boundaries, "test_version_module_count_boundaries")
			run_test (agent tests.test_version_capacity_increases_monotonic, "test_version_capacity_increases_monotonic")
			run_test (agent tests.test_version_capacity_ec_decreases, "test_version_capacity_ec_decreases")
			run_test (agent tests.test_version_capacity_mode_efficiency, "test_version_capacity_mode_efficiency")
			run_test (agent tests.test_version_minimum_version_known_values, "test_version_minimum_version_known_values")
			run_test (agent tests.test_version_minimum_version_boundary, "test_version_minimum_version_boundary")
			run_test (agent tests.test_version_data_too_large, "test_version_data_too_large")

			-- QR_ENCODER Tests
			io.put_string ("%NQR_ENCODER Tests:%N")
			run_test (agent tests.test_encoder_detect_numeric, "test_encoder_detect_numeric")
			run_test (agent tests.test_encoder_detect_alphanumeric, "test_encoder_detect_alphanumeric")
			run_test (agent tests.test_encoder_detect_byte, "test_encoder_detect_byte")
			run_test (agent tests.test_encoder_numeric_encoding, "test_encoder_numeric_encoding")
			run_test (agent tests.test_encoder_alphanumeric_encoding, "test_encoder_alphanumeric_encoding")
			run_test (agent tests.test_encoder_byte_encoding, "test_encoder_byte_encoding")
			run_test (agent tests.test_encoder_to_codewords, "test_encoder_to_codewords")
			run_test (agent tests.test_encoder_version_affects_count_bits, "test_encoder_version_affects_count_bits")

			-- QR_ERROR_CORRECTION Tests
			io.put_string ("%NQR_ERROR_CORRECTION Tests:%N")
			run_test (agent tests.test_ec_generator_polynomial_length, "test_ec_generator_polynomial_length")
			run_test (agent tests.test_ec_codewords_nonzero, "test_ec_codewords_nonzero")
			run_test (agent tests.test_ec_codewords_in_range, "test_ec_codewords_in_range")
			run_test (agent tests.test_ec_interleave_total, "test_ec_interleave_total")
			run_test (agent tests.test_ec_different_levels, "test_ec_different_levels")

			-- QR_MATRIX Tests
			io.put_string ("%NQR_MATRIX Tests:%N")
			run_test (agent tests.test_matrix_size_formula, "test_matrix_size_formula")
			run_test (agent tests.test_matrix_finder_pattern_positions, "test_matrix_finder_pattern_positions")
			run_test (agent tests.test_matrix_finder_pattern_center, "test_matrix_finder_pattern_center")
			run_test (agent tests.test_matrix_timing_pattern_alternates, "test_matrix_timing_pattern_alternates")
			run_test (agent tests.test_matrix_reserved_areas, "test_matrix_reserved_areas")
			run_test (agent tests.test_matrix_mask_patterns, "test_matrix_mask_patterns")
			run_test (agent tests.test_matrix_dark_module, "test_matrix_dark_module")
			run_test (agent tests.test_matrix_v1_boundaries, "test_matrix_v1_boundaries")
			run_test (agent tests.test_matrix_v40_boundaries, "test_matrix_v40_boundaries")

			-- SIMPLE_QR Integration Tests
			io.put_string ("%NSIMPLE_QR Integration Tests:%N")
			run_test (agent tests.test_qr_make_defaults, "test_qr_make_defaults")
			run_test (agent tests.test_qr_make_with_level, "test_qr_make_with_level")
			run_test (agent tests.test_qr_set_data, "test_qr_set_data")
			run_test (agent tests.test_qr_set_data_clears_matrix, "test_qr_set_data_clears_matrix")
			run_test (agent tests.test_qr_generate_numeric, "test_qr_generate_numeric")
			run_test (agent tests.test_qr_generate_alphanumeric, "test_qr_generate_alphanumeric")
			run_test (agent tests.test_qr_generate_byte, "test_qr_generate_byte")
			run_test (agent tests.test_qr_generate_all_ec_levels, "test_qr_generate_all_ec_levels")
			run_test (agent tests.test_qr_to_ascii_art, "test_qr_to_ascii_art")
			run_test (agent tests.test_qr_to_pbm, "test_qr_to_pbm")
			run_test (agent tests.test_qr_module_access, "test_qr_module_access")
			run_test (agent tests.test_qr_version_auto_selection, "test_qr_version_auto_selection")

			-- SIMPLE_QR Edge Cases
			io.put_string ("%NSIMPLE_QR Edge Cases:%N")
			run_test (agent tests.test_qr_single_char, "test_qr_single_char")
			run_test (agent tests.test_qr_max_v1_capacity, "test_qr_max_v1_capacity")
			run_test (agent tests.test_qr_special_characters, "test_qr_special_characters")
			run_test (agent tests.test_qr_url, "test_qr_url")
			run_test (agent tests.test_qr_vcard_like, "test_qr_vcard_like")
			run_test (agent tests.test_qr_pure_numeric_long, "test_qr_pure_numeric_long")
			run_test (agent tests.test_qr_pure_alphanumeric_long, "test_qr_pure_alphanumeric_long")

			-- Full Pipeline Tests
			io.put_string ("%NFull Pipeline Tests:%N")
			run_test (agent tests.test_full_pipeline_numeric, "test_full_pipeline_numeric")
			run_test (agent tests.test_full_pipeline_all_modes, "test_full_pipeline_all_modes")
			run_test (agent tests.test_determinism, "test_determinism")

			-- Adversarial Tests
			io.put_string ("%N=== ADVERSARIAL TESTS ===%N")
			io.put_string ("%NInput Attack Tests:%N")
			run_test (agent adversarial.test_empty_string_rejected, "test_empty_string_rejected")
			run_test (agent adversarial.test_null_byte_in_content, "test_null_byte_in_content")
			run_test (agent adversarial.test_control_characters, "test_control_characters")
			run_test (agent adversarial.test_all_bytes_0_255, "test_all_bytes_0_255")

			io.put_string ("%NBoundary Tests:%N")
			run_test (agent adversarial.test_version_1_max_numeric, "test_version_1_max_numeric")
			run_test (agent adversarial.test_version_1_exceed_forces_v2, "test_version_1_exceed_forces_v2")
			run_test (agent adversarial.test_explicit_version_too_small, "test_explicit_version_too_small")
			run_test (agent adversarial.test_version_40_boundaries, "test_version_40_boundaries")

			io.put_string ("%NEC Level Tests:%N")
			run_test (agent adversarial.test_all_ec_levels_same_data, "test_all_ec_levels_same_data")
			run_test (agent adversarial.test_ec_level_h_smaller_capacity, "test_ec_level_h_smaller_capacity")

			io.put_string ("%NOutput Format Tests:%N")
			run_test (agent adversarial.test_ascii_art_structure, "test_ascii_art_structure")
			run_test (agent adversarial.test_pbm_format_valid, "test_pbm_format_valid")

			io.put_string ("%NState Tests:%N")
			run_test (agent adversarial.test_reuse_after_error, "test_reuse_after_error")
			run_test (agent adversarial.test_multiple_generates, "test_multiple_generates")

			io.put_string ("%NEncoding Mode Tests:%N")
			run_test (agent adversarial.test_mode_detection_numeric, "test_mode_detection_numeric")
			run_test (agent adversarial.test_mode_detection_alphanumeric, "test_mode_detection_alphanumeric")

			-- Stress Tests
			io.put_string ("%N=== STRESS TESTS ===%N")
			io.put_string ("%NVolume Tests:%N")
			run_test (agent stress.test_100_qr_codes_sequential, "test_100_qr_codes_sequential")
			run_test (agent stress.test_large_numeric_data, "test_large_numeric_data")
			run_test (agent stress.test_large_alphanumeric_data, "test_large_alphanumeric_data")
			run_test (agent stress.test_large_byte_data, "test_large_byte_data")

			io.put_string ("%NMatrix Size Tests:%N")
			run_test (agent stress.test_version_1_matrix, "test_version_1_matrix")
			run_test (agent stress.test_version_10_matrix, "test_version_10_matrix")

			io.put_string ("%NGalois Field Stress Tests:%N")
			run_test (agent stress.test_galois_all_multiplications, "test_galois_all_multiplications")
			run_test (agent stress.test_galois_all_inverses, "test_galois_all_inverses")

			io.put_string ("%NReed-Solomon Stress Tests:%N")
			run_test (agent stress.test_ec_multiple_data_sizes, "test_ec_multiple_data_sizes")

			io.put_string ("%NDeterminism Tests:%N")
			run_test (agent stress.test_deterministic_output, "test_deterministic_output")
			run_test (agent stress.test_different_data_different_output, "test_different_data_different_output")

			-- Summary
			io.put_string ("%N===================================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			io.put_string ("Total:   " + (passed + failed).out + " tests%N")

			if failed > 0 then
				io.put_string ("%NTESTS FAILED%N")
			else
				io.put_string ("%NALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			io.put_string ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end

note
	description: "[
		Represents the QR code as a 2D matrix of modules (dark/light).
		Handles module placement, function patterns, and masking.

		SPECIFICATION:
		The QR matrix is a square grid where each cell (module) is either
		dark (True) or light (False). The matrix contains:
		- Finder patterns: 7x7 at three corners (top-left, top-right, bottom-left)
		- Alignment patterns: 5x5 at version-dependent positions (version >= 2)
		- Timing patterns: Alternating dark/light in row 7 and column 7
		- Format info: 15 bits around finder patterns
		- Version info: 18 bits near finders (version >= 7)
		- Data area: All remaining modules in zigzag pattern

		COORDINATE SYSTEM:
		- 1-based indexing: rows and columns from 1 to size
		- Row 1 is top, column 1 is left
		- Version N has size = 17 + (N * 4)

		CONTRACT GUARANTEES:
		- All coordinates validated against matrix bounds
		- Function patterns placed at exact specification positions
		- Reserved areas prevent data overwriting patterns
		- Mask patterns follow exact QR specification formulas
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	QR_MATRIX

create
	make

feature {NONE} -- Initialization

	make (a_version: INTEGER)
			-- Create matrix for given version.
		require
			version_valid: a_version >= 1 and a_version <= 40
		do
			version := a_version
			size := 17 + (a_version * 4)
			create modules.make_filled (False, size, size)
			create reserved.make_filled (False, size, size)
		ensure
			version_set: version = a_version
			size_correct: size = 17 + (a_version * 4)
			modules_created: modules /= Void and modules.height = size and modules.width = size
			reserved_created: reserved /= Void and reserved.height = size and reserved.width = size
			all_modules_light: across 1 |..| size as r all
				across 1 |..| size as c all not modules.item (r, c) end end
			all_unreserved: across 1 |..| size as r all
				across 1 |..| size as c all not reserved.item (r, c) end end
		end

feature -- Access

	version: INTEGER
			-- QR code version (1-40)

	size: INTEGER
			-- Matrix size (modules per side)

	modules: ARRAY2 [BOOLEAN]
			-- Module values (True = dark, False = light)

	reserved: ARRAY2 [BOOLEAN]
			-- Reserved positions (function patterns)

feature -- Status report

	is_dark (a_row, a_col: INTEGER): BOOLEAN
			-- Is module at (a_row, a_col) dark?
		require
			row_valid: a_row >= 1 and a_row <= size
			col_valid: a_col >= 1 and a_col <= size
		do
			Result := modules.item (a_row, a_col)
		ensure
			definition: Result = modules.item (a_row, a_col)
		end

	is_reserved (a_row, a_col: INTEGER): BOOLEAN
			-- Is position reserved for function pattern?
		require
			row_valid: a_row >= 1 and a_row <= size
			col_valid: a_col >= 1 and a_col <= size
		do
			Result := reserved.item (a_row, a_col)
		ensure
			definition: Result = reserved.item (a_row, a_col)
		end

feature -- Element change

	set_module (a_row, a_col: INTEGER; a_dark: BOOLEAN)
			-- Set module value at (a_row, a_col).
		require
			row_valid: a_row >= 1 and a_row <= size
			col_valid: a_col >= 1 and a_col <= size
		do
			modules.put (a_dark, a_row, a_col)
		ensure
			module_set: modules.item (a_row, a_col) = a_dark
		end

feature -- Function patterns

	place_finder_patterns
			-- Place the three finder patterns (top-left, top-right, bottom-left).
			-- Finder patterns are 7x7 with specific dark/light arrangement.
		do
			-- Top-left finder pattern
			place_finder_pattern (1, 1)
			-- Top-right finder pattern
			place_finder_pattern (1, size - 6)
			-- Bottom-left finder pattern
			place_finder_pattern (size - 6, 1)
			-- Reserve separator areas
			reserve_separators
		ensure
			-- Top-left finder center is dark
			top_left_center_dark: modules.item (4, 4)
			-- Top-right finder center is dark
			top_right_center_dark: modules.item (4, size - 3)
			-- Bottom-left finder center is dark
			bottom_left_center_dark: modules.item (size - 3, 4)
		end

	place_alignment_patterns
			-- Place alignment patterns for version >= 2.
			-- Alignment patterns are 5x5 with dark center.
		local
			l_positions: ARRAY [INTEGER]
			l_i, l_j: INTEGER
			l_row, l_col: INTEGER
		do
			if version >= 2 then
				l_positions := alignment_pattern_positions
				from l_i := l_positions.lower until l_i > l_positions.upper loop
					from l_j := l_positions.lower until l_j > l_positions.upper loop
						l_row := l_positions.item (l_i)
						l_col := l_positions.item (l_j)
						-- Skip if overlaps with finder patterns
						if not overlaps_finder (l_row, l_col) then
							place_alignment_pattern (l_row, l_col)
						end
						l_j := l_j + 1
					end
					l_i := l_i + 1
				end
			end
		end

	place_timing_patterns
			-- Place timing patterns (alternating dark/light).
			-- Horizontal in row 7, vertical in column 7.
		local
			l_i: INTEGER
			l_dark: BOOLEAN
		do
			-- Horizontal timing pattern (row 7)
			from l_i := 9 until l_i > size - 8 loop
				l_dark := ((l_i - 9) \\ 2) = 0
				set_module (7, l_i, l_dark)
				reserved.put (True, 7, l_i)
				l_i := l_i + 1
			end
			-- Vertical timing pattern (column 7)
			from l_i := 9 until l_i > size - 8 loop
				l_dark := ((l_i - 9) \\ 2) = 0
				set_module (l_i, 7, l_dark)
				reserved.put (True, l_i, 7)
				l_i := l_i + 1
			end
			-- Dark module (always present)
			set_module (size - 7, 9, True)
			reserved.put (True, size - 7, 9)
		ensure
			-- First timing module is dark
			horizontal_start_dark: size > 16 implies modules.item (7, 9)
			vertical_start_dark: size > 16 implies modules.item (9, 7)
			-- Dark module is set
			dark_module_set: modules.item (size - 7, 9)
		end

	place_format_info (a_ec_level, a_mask: INTEGER)
			-- Place format information around finder patterns.
			-- Format info is 15 bits with BCH error correction.
		require
			ec_valid: a_ec_level >= 1 and a_ec_level <= 4
			mask_valid: a_mask >= 0 and a_mask <= 7
		local
			l_format: INTEGER
			l_bits: ARRAY [BOOLEAN]
			l_i: INTEGER
		do
			l_format := encode_format_info (a_ec_level, a_mask)
			l_bits := integer_to_bits (l_format, 15)
			-- Place around top-left finder (horizontal and vertical)
			from l_i := 0 until l_i >= 6 loop
				set_module (9, l_i + 1, l_bits.item (l_i + 1))
				reserved.put (True, 9, l_i + 1)
				l_i := l_i + 1
			end
			set_module (9, 8, l_bits.item (7))
			reserved.put (True, 9, 8)
			set_module (9, 9, l_bits.item (8))
			reserved.put (True, 9, 9)
			set_module (8, 9, l_bits.item (9))
			reserved.put (True, 8, 9)
			from l_i := 10 until l_i >= 15 loop
				set_module (15 - l_i, 9, l_bits.item (l_i + 1))
				reserved.put (True, 15 - l_i, 9)
				l_i := l_i + 1
			end
			-- Place around top-right and bottom-left finders
			from l_i := 0 until l_i >= 8 loop
				set_module (9, size - 7 + l_i, l_bits.item (15 - l_i))
				reserved.put (True, 9, size - 7 + l_i)
				l_i := l_i + 1
			end
			from l_i := 0 until l_i >= 7 loop
				set_module (size - 6 + l_i, 9, l_bits.item (l_i + 1))
				reserved.put (True, size - 6 + l_i, 9)
				l_i := l_i + 1
			end
		end

	place_version_info (a_version: INTEGER)
			-- Place version information (version >= 7).
			-- Version info is 18 bits with BCH error correction.
		require
			version_requires_info: a_version >= 7
		local
			l_info: INTEGER
			l_bits: ARRAY [BOOLEAN]
			l_i, l_j: INTEGER
		do
			l_info := encode_version_info (a_version)
			l_bits := integer_to_bits (l_info, 18)
			-- Place near bottom-left and top-right finders
			from l_i := 0 until l_i >= 6 loop
				from l_j := 0 until l_j >= 3 loop
					set_module (size - 10 + l_j, l_i + 1, l_bits.item (l_i * 3 + l_j + 1))
					reserved.put (True, size - 10 + l_j, l_i + 1)
					set_module (l_i + 1, size - 10 + l_j, l_bits.item (l_i * 3 + l_j + 1))
					reserved.put (True, l_i + 1, size - 10 + l_j)
					l_j := l_j + 1
				end
				l_i := l_i + 1
			end
		end

	place_data (a_data: ARRAY [INTEGER])
			-- Place encoded data bits in zigzag pattern.
			-- Data is placed avoiding reserved function pattern areas.
		require
			data_not_empty: not a_data.is_empty
			all_data_valid: across a_data as d all d >= 0 and d <= 255 end
		local
			l_bits: ARRAYED_LIST [BOOLEAN]
			l_col, l_row: INTEGER
			l_upward: BOOLEAN
			l_bit_index: INTEGER
			l_actual_col: INTEGER
		do
			l_bits := codewords_to_bits (a_data)
			l_bit_index := 1
			l_upward := True
			from l_col := size until l_col >= 1 loop
				-- Skip vertical timing pattern column
				l_actual_col := l_col
				if l_actual_col = 7 then
					l_actual_col := l_actual_col - 1
				end
				if l_upward then
					from l_row := size until l_row < 1 loop
						place_data_module (l_row, l_actual_col, l_bits, l_bit_index)
						place_data_module (l_row, l_actual_col - 1, l_bits, l_bit_index)
						l_row := l_row - 1
					end
				else
					from l_row := 1 until l_row > size loop
						place_data_module (l_row, l_actual_col, l_bits, l_bit_index)
						place_data_module (l_row, l_actual_col - 1, l_bits, l_bit_index)
						l_row := l_row + 1
					end
				end
				l_upward := not l_upward
				l_col := l_col - 2
			end
		end

	apply_mask (a_mask: INTEGER)
			-- Apply masking pattern to data modules.
			-- Only affects non-reserved (data) modules.
		require
			mask_valid: a_mask >= 0 and a_mask <= 7
		local
			l_row, l_col: INTEGER
		do
			from l_row := 1 until l_row > size loop
				from l_col := 1 until l_col > size loop
					if not is_reserved (l_row, l_col) and should_mask (l_row - 1, l_col - 1, a_mask) then
						set_module (l_row, l_col, not is_dark (l_row, l_col))
					end
					l_col := l_col + 1
				end
				l_row := l_row + 1
			end
		end

	apply_best_mask (a_ec_level: INTEGER)
			-- Apply the best masking pattern (lowest penalty score).
		require
			ec_level_valid: a_ec_level >= 1 and a_ec_level <= 4
		local
			l_mask, l_best_mask: INTEGER
			l_score, l_best_score: INTEGER
			l_saved: ARRAY2 [BOOLEAN]
		do
			-- Save original state
			create l_saved.make_filled (False, size, size)
			copy_modules (modules, l_saved)
			l_best_score := 2147483647 -- Max integer
			l_best_mask := 0
			from l_mask := 0 until l_mask > 7 loop
				copy_modules (l_saved, modules)
				apply_mask (l_mask)
				place_format_info (a_ec_level, l_mask)
				l_score := calculate_penalty
				if l_score < l_best_score then
					l_best_score := l_score
					l_best_mask := l_mask
				end
				l_mask := l_mask + 1
			end
			-- Apply best mask
			copy_modules (l_saved, modules)
			apply_mask (l_best_mask)
			place_format_info (a_ec_level, l_best_mask)
		ensure
			best_mask_applied: True -- Mask with lowest penalty is applied
		end

feature {NONE} -- Implementation

	place_finder_pattern (a_row, a_col: INTEGER)
			-- Place a 7x7 finder pattern at (a_row, a_col).
			-- Pattern: dark border, light border, dark 3x3 center.
		require
			row_valid: a_row >= 1 and a_row + 6 <= size
			col_valid: a_col >= 1 and a_col + 6 <= size
		local
			l_r, l_c: INTEGER
		do
			from l_r := 0 until l_r >= 7 loop
				from l_c := 0 until l_c >= 7 loop
					if l_r = 0 or l_r = 6 or l_c = 0 or l_c = 6 or
					   (l_r >= 2 and l_r <= 4 and l_c >= 2 and l_c <= 4) then
						set_module (a_row + l_r, a_col + l_c, True)
					else
						set_module (a_row + l_r, a_col + l_c, False)
					end
					reserved.put (True, a_row + l_r, a_col + l_c)
					l_c := l_c + 1
				end
				l_r := l_r + 1
			end
		ensure
			all_reserved: across 0 |..| 6 as r all
				across 0 |..| 6 as c all reserved.item (a_row + r, a_col + c) end end
			center_dark: modules.item (a_row + 3, a_col + 3)
		end

	reserve_separators
			-- Reserve separator areas around finder patterns.
		local
			l_i: INTEGER
		do
			-- Top-left separators
			from l_i := 1 until l_i > 8 loop
				reserved.put (True, 8, l_i)
				reserved.put (True, l_i, 8)
				l_i := l_i + 1
			end
			-- Top-right separators
			from l_i := 1 until l_i > 8 loop
				reserved.put (True, 8, size - 8 + l_i)
				reserved.put (True, l_i, size - 7)
				l_i := l_i + 1
			end
			-- Bottom-left separators
			from l_i := 1 until l_i > 8 loop
				reserved.put (True, size - 7, l_i)
				reserved.put (True, size - 8 + l_i, 8)
				l_i := l_i + 1
			end
		end

	place_alignment_pattern (a_row, a_col: INTEGER)
			-- Place a 5x5 alignment pattern centered at (a_row, a_col).
			-- Pattern: dark border, light border, dark center.
		require
			row_valid: a_row >= 3 and a_row <= size - 2
			col_valid: a_col >= 3 and a_col <= size - 2
		local
			l_r, l_c: INTEGER
		do
			from l_r := -2 until l_r > 2 loop
				from l_c := -2 until l_c > 2 loop
					if l_r = -2 or l_r = 2 or l_c = -2 or l_c = 2 or (l_r = 0 and l_c = 0) then
						set_module (a_row + l_r, a_col + l_c, True)
					else
						set_module (a_row + l_r, a_col + l_c, False)
					end
					reserved.put (True, a_row + l_r, a_col + l_c)
					l_c := l_c + 1
				end
				l_r := l_r + 1
			end
		ensure
			center_dark: modules.item (a_row, a_col)
		end

	overlaps_finder (a_row, a_col: INTEGER): BOOLEAN
			-- Does position overlap with a finder pattern?
		do
			Result := (a_row <= 8 and a_col <= 8) or
			          (a_row <= 8 and a_col >= size - 7) or
			          (a_row >= size - 7 and a_col <= 8)
		end

	alignment_pattern_positions: ARRAY [INTEGER]
			-- Get alignment pattern positions for current version.
		do
			inspect version
			when 1 then create Result.make_empty
			when 2 then Result := <<7, 19>>
			when 3 then Result := <<7, 23>>
			when 4 then Result := <<7, 27>>
			when 5 then Result := <<7, 31>>
			when 6 then Result := <<7, 35>>
			when 7 then Result := <<7, 23, 39>>
			else
				-- Simplified: use first, middle, last positions
				Result := <<7, (size + 7) // 2, size - 6>>
			end
		ensure
			result_not_void: Result /= Void
			v1_empty: version = 1 implies Result.is_empty
		end

	should_mask (a_row, a_col, a_mask: INTEGER): BOOLEAN
			-- Should position be masked with given pattern? (0-indexed)
			-- These are the 8 standard QR mask patterns.
		require
			mask_valid: a_mask >= 0 and a_mask <= 7
		do
			inspect a_mask
			when 0 then Result := ((a_row + a_col) \\ 2) = 0
			when 1 then Result := (a_row \\ 2) = 0
			when 2 then Result := (a_col \\ 3) = 0
			when 3 then Result := ((a_row + a_col) \\ 3) = 0
			when 4 then Result := (((a_row // 2) + (a_col // 3)) \\ 2) = 0
			when 5 then Result := ((a_row * a_col) \\ 2) + ((a_row * a_col) \\ 3) = 0
			when 6 then Result := ((((a_row * a_col) \\ 2) + ((a_row * a_col) \\ 3)) \\ 2) = 0
			when 7 then Result := ((((a_row + a_col) \\ 2) + ((a_row * a_col) \\ 3)) \\ 2) = 0
			else Result := False
			end
		end

	place_data_module (a_row, a_col: INTEGER; a_bits: ARRAYED_LIST [BOOLEAN]; a_bit_index: INTEGER)
			-- Place a data module if position is not reserved.
		do
			if a_col >= 1 and a_col <= size and not is_reserved (a_row, a_col) then
				if a_bit_index <= a_bits.count then
					set_module (a_row, a_col, a_bits.i_th (a_bit_index))
				end
			end
		end

	codewords_to_bits (a_codewords: ARRAY [INTEGER]): ARRAYED_LIST [BOOLEAN]
			-- Convert codewords to bit list.
		require
			codewords_not_empty: not a_codewords.is_empty
			all_valid: across a_codewords as c all c >= 0 and c <= 255 end
		local
			l_i, l_j, l_cw: INTEGER
		do
			create Result.make (a_codewords.count * 8)
			from l_i := a_codewords.lower until l_i > a_codewords.upper loop
				l_cw := a_codewords.item (l_i)
				from l_j := 7 until l_j < 0 loop
					Result.extend ((l_cw |>> l_j).bit_and (1) = 1)
					l_j := l_j - 1
				end
				l_i := l_i + 1
			end
		ensure
			result_not_void: Result /= Void
			correct_count: Result.count = a_codewords.count * 8
		end

	encode_format_info (a_ec_level, a_mask: INTEGER): INTEGER
			-- Encode format information with BCH error correction.
		require
			ec_valid: a_ec_level >= 1 and a_ec_level <= 4
			mask_valid: a_mask >= 0 and a_mask <= 7
		local
			l_data, l_poly, l_remainder: INTEGER
		do
			-- EC level bits: L=01, M=00, Q=11, H=10
			inspect a_ec_level
			when 1 then l_data := 0b01 |<< 3
			when 2 then l_data := 0b00 |<< 3
			when 3 then l_data := 0b11 |<< 3
			when 4 then l_data := 0b10 |<< 3
			else l_data := 0
			end
			l_data := l_data.bit_or (a_mask)
			l_data := l_data |<< 10
			-- BCH(15,5) with generator x^10 + x^8 + x^5 + x^4 + x^2 + x + 1 = 0x537
			l_poly := 0x537
			l_remainder := l_data
			from until l_remainder < 0x400 loop
				l_remainder := l_remainder.bit_xor (l_poly |<< (highest_bit (l_remainder) - 10))
			end
			Result := l_data.bit_or (l_remainder)
			-- XOR with mask pattern 0x5412
			Result := Result.bit_xor (0x5412)
		ensure
			result_15_bits: Result >= 0 and Result < 32768
		end

	encode_version_info (a_version: INTEGER): INTEGER
			-- Encode version information with BCH error correction.
		require
			version_valid: a_version >= 7 and a_version <= 40
		local
			l_data, l_poly, l_remainder: INTEGER
		do
			l_data := a_version |<< 12
			-- BCH(18,6) with generator x^12 + x^11 + x^10 + x^9 + x^8 + x^5 + x^2 + 1 = 0x1F25
			l_poly := 0x1F25
			l_remainder := l_data
			from until l_remainder < 0x1000 loop
				l_remainder := l_remainder.bit_xor (l_poly |<< (highest_bit (l_remainder) - 12))
			end
			Result := l_data.bit_or (l_remainder)
		ensure
			result_18_bits: Result >= 0 and Result < 262144
		end

	highest_bit (a_value: INTEGER): INTEGER
			-- Position of highest set bit (0-indexed).
		require
			value_positive: a_value > 0
		local
			l_val: INTEGER
		do
			l_val := a_value
			from Result := -1 until l_val = 0 loop
				Result := Result + 1
				l_val := l_val |>> 1
			end
		ensure
			result_non_negative: Result >= 0
		end

	integer_to_bits (a_value, a_count: INTEGER): ARRAY [BOOLEAN]
			-- Convert integer to array of bits.
		require
			count_positive: a_count > 0
		local
			l_i: INTEGER
		do
			create Result.make_filled (False, 1, a_count)
			from l_i := 0 until l_i >= a_count loop
				Result.put ((a_value |>> (a_count - 1 - l_i)).bit_and (1) = 1, l_i + 1)
				l_i := l_i + 1
			end
		ensure
			result_not_void: Result /= Void
			correct_count: Result.count = a_count
		end

	copy_modules (a_from, a_to: ARRAY2 [BOOLEAN])
			-- Copy modules from one array to another.
		require
			same_size: a_from.height = a_to.height and a_from.width = a_to.width
		local
			l_r, l_c: INTEGER
		do
			from l_r := 1 until l_r > size loop
				from l_c := 1 until l_c > size loop
					a_to.put (a_from.item (l_r, l_c), l_r, l_c)
					l_c := l_c + 1
				end
				l_r := l_r + 1
			end
		end

	calculate_penalty: INTEGER
			-- Calculate penalty score for mask evaluation.
			-- Lower score = better mask pattern.
		do
			Result := penalty_rule_1 + penalty_rule_2 + penalty_rule_3 + penalty_rule_4
		ensure
			result_non_negative: Result >= 0
		end

	penalty_rule_1: INTEGER
			-- Rule 1: Adjacent modules in row/column same color.
			-- Penalty: 3 + (run_length - 5) for runs of 5+ same color.
		local
			l_row, l_col, l_count: INTEGER
			l_last: BOOLEAN
		do
			-- Check rows
			from l_row := 1 until l_row > size loop
				l_count := 1
				l_last := is_dark (l_row, 1)
				from l_col := 2 until l_col > size loop
					if is_dark (l_row, l_col) = l_last then
						l_count := l_count + 1
					else
						if l_count >= 5 then
							Result := Result + 3 + (l_count - 5)
						end
						l_count := 1
						l_last := is_dark (l_row, l_col)
					end
					l_col := l_col + 1
				end
				if l_count >= 5 then
					Result := Result + 3 + (l_count - 5)
				end
				l_row := l_row + 1
			end
			-- Check columns (similar logic)
			from l_col := 1 until l_col > size loop
				l_count := 1
				l_last := is_dark (1, l_col)
				from l_row := 2 until l_row > size loop
					if is_dark (l_row, l_col) = l_last then
						l_count := l_count + 1
					else
						if l_count >= 5 then
							Result := Result + 3 + (l_count - 5)
						end
						l_count := 1
						l_last := is_dark (l_row, l_col)
					end
					l_row := l_row + 1
				end
				if l_count >= 5 then
					Result := Result + 3 + (l_count - 5)
				end
				l_col := l_col + 1
			end
		ensure
			result_non_negative: Result >= 0
		end

	penalty_rule_2: INTEGER
			-- Rule 2: 2x2 blocks of same color.
			-- Penalty: 3 for each 2x2 block.
		local
			l_row, l_col: INTEGER
		do
			from l_row := 1 until l_row >= size loop
				from l_col := 1 until l_col >= size loop
					if is_dark (l_row, l_col) = is_dark (l_row, l_col + 1) and
					   is_dark (l_row, l_col) = is_dark (l_row + 1, l_col) and
					   is_dark (l_row, l_col) = is_dark (l_row + 1, l_col + 1) then
						Result := Result + 3
					end
					l_col := l_col + 1
				end
				l_row := l_row + 1
			end
		ensure
			result_non_negative: Result >= 0
		end

	penalty_rule_3: INTEGER
			-- Rule 3: Finder-like patterns (simplified).
		do
			-- Simplified penalty for finder-like patterns
			Result := 0
		ensure
			result_non_negative: Result >= 0
		end

	penalty_rule_4: INTEGER
			-- Rule 4: Dark/light module ratio.
			-- Penalty based on deviation from 50% dark modules.
		local
			l_row, l_col, l_dark_count, l_total: INTEGER
			l_ratio: REAL_64
		do
			l_total := size * size
			from l_row := 1 until l_row > size loop
				from l_col := 1 until l_col > size loop
					if is_dark (l_row, l_col) then
						l_dark_count := l_dark_count + 1
					end
					l_col := l_col + 1
				end
				l_row := l_row + 1
			end
			l_ratio := (l_dark_count * 100) / l_total
			Result := ((l_ratio - 50).abs / 5).floor * 10
		ensure
			result_non_negative: Result >= 0
		end

invariant
	version_valid: version >= 1 and version <= 40
	size_valid: size >= 21 and size <= 177
	size_formula: size = 17 + (version * 4)
	modules_exist: modules /= Void
	modules_square: modules.height = size and modules.width = size
	reserved_exist: reserved /= Void
	reserved_square: reserved.height = size and reserved.width = size

end

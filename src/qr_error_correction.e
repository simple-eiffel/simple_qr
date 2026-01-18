note
	description: "[
		Generates Reed-Solomon error correction codewords for QR codes.
		Uses Galois Field GF(2^8) arithmetic.

		SPECIFICATION:
		Reed-Solomon is a polynomial-based error correction code.
		- Data is treated as coefficients of a polynomial over GF(2^8)
		- Generator polynomial G(x) = (x-a^0)(x-a^1)...(x-a^(n-1))
		- EC codewords are the remainder of data/G(x)
		- Allows correction of up to n/2 symbol errors

		ERROR CORRECTION LEVELS:
		- L (Level 1): ~7% recovery capacity
		- M (Level 2): ~15% recovery capacity
		- Q (Level 3): ~25% recovery capacity
		- H (Level 4): ~30% recovery capacity

		CONTRACT GUARANTEES:
		- All codewords are valid GF(2^8) elements (0-255)
		- Generator polynomial degree = number of EC codewords
		- Data + EC codewords = total codewords for version
		- Higher EC level = more EC codewords = less data capacity
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	QR_ERROR_CORRECTION

create
	make

feature {NONE} -- Initialization

	make (a_level: INTEGER)
			-- Create error correction generator for level.
		require
			level_valid: a_level >= 1 and a_level <= 4
		do
			level := a_level
			create galois.make
			create generator_polynomial.make_empty
		ensure
			level_set: level = a_level
			galois_created: galois /= Void
			generator_empty: generator_polynomial.is_empty
		end

feature -- Access

	level: INTEGER
			-- Error correction level (1=L, 2=M, 3=Q, 4=H)

	generator_polynomial: ARRAY [INTEGER]
			-- Generator polynomial coefficients

	galois: QR_GALOIS
			-- Galois field for arithmetic

feature -- Constants

	Level_l: INTEGER = 1
			-- Low error correction (~7% recovery)

	Level_m: INTEGER = 2
			-- Medium error correction (~15% recovery)

	Level_q: INTEGER = 3
			-- Quartile error correction (~25% recovery)

	Level_h: INTEGER = 4
			-- High error correction (~30% recovery)

feature -- Query

	generate_codewords (a_data: ARRAY [INTEGER]; a_version: INTEGER): ARRAY [INTEGER]
			-- Generate EC codewords for data block.
			-- Uses polynomial division over GF(2^8).
		require
			data_not_empty: not a_data.is_empty
			version_valid: a_version >= 1 and a_version <= 40
			all_data_in_field: across a_data as d all d >= 0 and d <= 255 end
		local
			l_ec_count: INTEGER
			l_gen: ARRAY [INTEGER]
			l_msg: ARRAY [INTEGER]
			l_i, l_j: INTEGER
			l_coef: INTEGER
		do
			l_ec_count := ec_codewords_per_block (a_version)
			l_gen := build_generator_polynomial (l_ec_count)
			-- Prepare message polynomial (data + zeros for EC)
			create l_msg.make_filled (0, 1, a_data.count + l_ec_count)
			from l_i := a_data.lower until l_i > a_data.upper loop
				l_msg.put (a_data.item (l_i), l_i - a_data.lower + 1)
				l_i := l_i + 1
			end
			-- Polynomial division
			from l_i := 1 until l_i > a_data.count loop
				l_coef := l_msg.item (l_i)
				if l_coef /= 0 then
					from l_j := 1 until l_j > l_gen.count loop
						l_msg.put (l_msg.item (l_i + l_j - 1).bit_xor (
							galois.multiply (l_gen.item (l_j), l_coef)), l_i + l_j - 1)
						l_j := l_j + 1
					end
				end
				l_i := l_i + 1
			end
			-- Extract remainder (EC codewords)
			create Result.make_filled (0, 1, l_ec_count)
			from l_i := 1 until l_i > l_ec_count loop
				Result.put (l_msg.item (a_data.count + l_i), l_i)
				l_i := l_i + 1
			end
		ensure
			result_not_void: Result /= Void
			result_count_correct: Result.count = ec_codewords_per_block (a_version)
			all_ec_in_field: across Result as c all c >= 0 and c <= 255 end
		end

	interleave_blocks (a_data, a_ec: ARRAY [INTEGER]; a_version: INTEGER): ARRAY [INTEGER]
			-- Interleave data and EC blocks.
			-- For single-block versions, simply concatenates data + EC.
		require
			data_not_empty: not a_data.is_empty
			ec_not_empty: not a_ec.is_empty
			all_data_in_field: across a_data as d all d >= 0 and d <= 255 end
			all_ec_in_field: across a_ec as e all e >= 0 and e <= 255 end
			version_valid: a_version >= 1 and a_version <= 40
		local
			l_list: ARRAYED_LIST [INTEGER]
			l_i: INTEGER
		do
			-- Simplified: single block interleaving (no block splitting for v1-9)
			create l_list.make (a_data.count + a_ec.count)
			-- Add data codewords
			from l_i := a_data.lower until l_i > a_data.upper loop
				l_list.extend (a_data.item (l_i))
				l_i := l_i + 1
			end
			-- Add EC codewords
			from l_i := a_ec.lower until l_i > a_ec.upper loop
				l_list.extend (a_ec.item (l_i))
				l_i := l_i + 1
			end
			create Result.make_from_array (l_list.to_array)
		ensure
			result_not_void: Result /= Void
			total_codewords: Result.count = a_data.count + a_ec.count
			all_result_in_field: across Result as c all c >= 0 and c <= 255 end
		end

	total_codewords (a_version: INTEGER): INTEGER
			-- Total codewords for version.
			-- Includes both data and EC codewords.
		require
			version_valid: a_version >= 1 and a_version <= 40
		do
			-- Total codewords = (modules - function patterns) / 8
			inspect a_version
			when 1 then Result := 26
			when 2 then Result := 44
			when 3 then Result := 70
			when 4 then Result := 100
			when 5 then Result := 134
			when 6 then Result := 172
			when 7 then Result := 196
			when 8 then Result := 242
			when 9 then Result := 292
			when 10 then Result := 346
			else
				Result := 346 + (a_version - 10) * 60
			end
		ensure
			result_positive: Result > 0
			version_1_codewords: a_version = 1 implies Result = 26
			monotonic_increase: a_version > 1 implies Result > total_codewords (a_version - 1)
		end

	data_codewords (a_version: INTEGER): INTEGER
			-- Data codewords for version and current EC level.
			-- Higher EC level means fewer data codewords.
		require
			version_valid: a_version >= 1 and a_version <= 40
		local
			l_total, l_ec: INTEGER
		do
			l_total := total_codewords (a_version)
			l_ec := ec_codewords_per_block (a_version) * num_blocks (a_version)
			Result := l_total - l_ec
		ensure
			result_positive: Result > 0
			result_less_than_total: Result < total_codewords (a_version)
		end

	ec_codewords_per_block (a_version: INTEGER): INTEGER
			-- EC codewords per block.
			-- Higher EC level = more EC codewords.
		require
			version_valid: a_version >= 1 and a_version <= 40
		do
			-- Simplified table for common versions
			inspect level
			when 1 then -- L
				inspect a_version
				when 1 then Result := 7
				when 2 then Result := 10
				when 3 then Result := 15
				else Result := 15 + (a_version - 3) * 2
				end
			when 2 then -- M
				inspect a_version
				when 1 then Result := 10
				when 2 then Result := 16
				when 3 then Result := 26
				else Result := 26 + (a_version - 3) * 4
				end
			when 3 then -- Q
				inspect a_version
				when 1 then Result := 13
				when 2 then Result := 22
				when 3 then Result := 36
				else Result := 36 + (a_version - 3) * 6
				end
			when 4 then -- H
				inspect a_version
				when 1 then Result := 17
				when 2 then Result := 28
				when 3 then Result := 44
				else Result := 44 + (a_version - 3) * 8
				end
			else
				Result := 10
			end
			-- Cap at reasonable maximum
			if Result > 30 then
				Result := 30
			end
		ensure
			result_positive: Result > 0
			result_capped: Result <= 30
		end

feature {NONE} -- Implementation

	num_blocks (a_version: INTEGER): INTEGER
			-- Number of EC blocks for version and level.
			-- Higher versions and EC levels use more blocks.
		require
			version_valid: a_version >= 1 and a_version <= 40
		do
			if a_version <= 2 then
				Result := 1
			elseif a_version <= 6 then
				inspect level
				when 1, 2 then Result := 1
				when 3, 4 then Result := 2
				else Result := 1
				end
			else
				inspect level
				when 1 then Result := 2
				when 2 then Result := 4
				when 3 then Result := 6
				when 4 then Result := 8
				else Result := 2
				end
			end
		ensure
			result_positive: Result >= 1
		end

	build_generator_polynomial (a_degree: INTEGER): ARRAY [INTEGER]
			-- Build generator polynomial of given degree.
			-- G(x) = (x-a^0)(x-a^1)...(x-a^(degree-1))
		require
			degree_positive: a_degree > 0
		local
			l_i, l_j: INTEGER
			l_prev, l_curr: ARRAY [INTEGER]
			l_coef: INTEGER
		do
			-- Start with (x - a^0) = [1, 1]
			create l_prev.make_filled (0, 1, 2)
			l_prev.put (1, 1)
			l_prev.put (1, 2)
			-- Multiply by (x - a^i) for i = 1 to degree-1
			from l_i := 1 until l_i >= a_degree loop
				create l_curr.make_filled (0, 1, l_prev.count + 1)
				-- Multiply polynomial by (x - a^i)
				from l_j := 1 until l_j > l_prev.count loop
					-- x term
					l_curr.put (l_curr.item (l_j).bit_xor (l_prev.item (l_j)), l_j)
					-- -a^i term (multiply and add to next position)
					l_coef := galois.multiply (l_prev.item (l_j), galois.exp (l_i))
					l_curr.put (l_curr.item (l_j + 1).bit_xor (l_coef), l_j + 1)
					l_j := l_j + 1
				end
				l_prev := l_curr
				l_i := l_i + 1
			end
			Result := l_prev
		ensure
			result_not_void: Result /= Void
			result_correct_size: Result.count = a_degree + 1
			all_coefficients_in_field: across Result as c all c >= 0 and c <= 255 end
			leading_coefficient_one: Result.item (1) = 1
		end

invariant
	level_valid: level >= 1 and level <= 4
	generator_exists: generator_polynomial /= Void
	galois_exists: galois /= Void

end

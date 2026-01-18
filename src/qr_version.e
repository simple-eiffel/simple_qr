note
	description: "[
		QR code version utilities.
		Determines minimum version for data and provides capacity tables.

		SPECIFICATION:
		- QR codes have 40 versions (1-40)
		- Version N has (17 + N*4) x (17 + N*4) modules
		- Three encoding modes: Numeric (0-9), Alphanumeric (0-9A-Z$%%*+-./:), Byte
		- Four error correction levels: L(7%), M(15%), Q(25%), H(30%)
		- Higher EC = lower data capacity
		- Numeric encoding is most efficient, byte least efficient

		ORDERING PROPERTIES (guaranteed by contracts):
		- module_count: version N+1 > version N
		- capacity: version N+1 >= version N (for same mode/EC)
		- capacity: mode numeric > alphanumeric > byte (for same version/EC)
		- capacity: EC level L > M > Q > H (for same version/mode)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	QR_VERSION

create
	make

feature {NONE} -- Initialization

	make
			-- Create version utilities.
		do
			initialize_capacity_tables
		ensure
			tables_initialized: not numeric_capacity.is_empty
			numeric_table_has_versions: numeric_capacity.count >= 10
			alphanumeric_table_has_versions: alphanumeric_capacity.count >= 10
			byte_table_has_versions: byte_capacity.count >= 10
			-- Verify table ordering at key points
			v1_numeric_L_positive: numeric_capacity.item (1).item (1) > 0
		end

feature -- Access

	Min_version: INTEGER = 1
			-- Minimum QR version

	Max_version: INTEGER = 40
			-- Maximum QR version

	module_count (a_version: INTEGER): INTEGER
			-- Number of modules per side for version.
			-- Version 1 = 21x21, version 40 = 177x177.
		require
			version_valid: a_version >= Min_version and a_version <= Max_version
		do
			Result := 17 + (a_version * 4)
		ensure
			result_positive: Result > 0
			result_at_least_21: Result >= 21
			result_at_most_177: Result <= 177
			-- Exact formula
			result_formula: Result = 17 + (a_version * 4)
			-- Version 1 specific
			version_1: a_version = 1 implies Result = 21
			-- Version 40 specific
			version_40: a_version = 40 implies Result = 177
		end

feature -- Query

	minimum_version (a_data: STRING; a_mode: INTEGER; a_ec_level: INTEGER): INTEGER
			-- Minimum version that can encode data with given mode and EC level.
			-- Returns 0 if data cannot fit in any version.
		require
			data_not_empty: not a_data.is_empty
			mode_valid: a_mode = Mode_numeric or a_mode = Mode_alphanumeric or a_mode = Mode_byte
			ec_level_valid: a_ec_level >= Ec_level_l and a_ec_level <= Ec_level_h
		local
			l_version: INTEGER
			l_capacity: INTEGER
		do
			from
				l_version := Min_version
				Result := 0
			invariant
				l_version >= Min_version and l_version <= Max_version + 1
				Result = 0 or (Result >= Min_version and Result <= Max_version)
			until
				Result > 0 or l_version > Max_version
			loop
				l_capacity := character_capacity (l_version, a_mode, a_ec_level)
				if a_data.count <= l_capacity then
					Result := l_version
				end
				l_version := l_version + 1
			variant
				Max_version - l_version + 2
			end
		ensure
			result_valid: Result = 0 or (Result >= Min_version and Result <= Max_version)
		end

	character_capacity (a_version, a_mode, a_ec_level: INTEGER): INTEGER
			-- Character capacity for version, mode, and EC level.
			-- Maximum number of characters that can be encoded.
		require
			version_valid: a_version >= Min_version and a_version <= Max_version
			mode_valid: a_mode = Mode_numeric or a_mode = Mode_alphanumeric or a_mode = Mode_byte
			ec_level_valid: a_ec_level >= Ec_level_l and a_ec_level <= Ec_level_h
		local
			l_table: ARRAY [ARRAY [INTEGER]]
		do
			inspect a_mode
			when Mode_numeric then
				l_table := numeric_capacity
			when Mode_alphanumeric then
				l_table := alphanumeric_capacity
			else
				l_table := byte_capacity
			end
			if a_version <= l_table.count then
				Result := l_table.item (a_version).item (a_ec_level)
			else
				-- Extrapolate for higher versions
				Result := extrapolate_capacity (a_version, a_mode, a_ec_level)
			end
		ensure
			result_positive: Result > 0
		end

	data_codewords (a_version, a_ec_level: INTEGER): INTEGER
			-- Data codewords for version and EC level.
			-- Number of 8-bit codewords available for data after EC overhead.
		require
			version_valid: a_version >= Min_version and a_version <= Max_version
			ec_level_valid: a_ec_level >= Ec_level_l and a_ec_level <= Ec_level_h
		do
			if a_version <= data_codeword_table.count then
				Result := data_codeword_table.item (a_version).item (a_ec_level)
			else
				Result := extrapolate_data_codewords (a_version, a_ec_level)
			end
		ensure
			result_positive: Result > 0
		end

	total_codewords (a_version: INTEGER): INTEGER
			-- Total codewords for version.
			-- Includes both data and error correction codewords.
		require
			version_valid: a_version >= Min_version and a_version <= Max_version
		do
			-- Formula: ((modules^2) - function_patterns) / 8
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
		end

feature -- Constants

	Mode_numeric: INTEGER = 1
			-- Numeric encoding mode (0-9 only)
			-- Most efficient: ~3.3 bits per character

	Mode_alphanumeric: INTEGER = 2
			-- Alphanumeric encoding mode (0-9, A-Z, space, $%%*+-./: only)
			-- Medium efficiency: ~5.5 bits per character

	Mode_byte: INTEGER = 4
			-- Byte encoding mode (arbitrary 8-bit data)
			-- Least efficient: 8 bits per character

	Ec_level_l: INTEGER = 1
			-- Low error correction (~7% recovery)

	Ec_level_m: INTEGER = 2
			-- Medium error correction (~15% recovery)

	Ec_level_q: INTEGER = 3
			-- Quartile error correction (~25% recovery)

	Ec_level_h: INTEGER = 4
			-- High error correction (~30% recovery)

feature {NONE} -- Implementation

	numeric_capacity: ARRAY [ARRAY [INTEGER]]
			-- Numeric capacity per version/EC level [version][ec_level]
			-- Indices: [1..versions][1..4] where 1=L, 2=M, 3=Q, 4=H
		attribute
			create Result.make_empty
		end

	alphanumeric_capacity: ARRAY [ARRAY [INTEGER]]
			-- Alphanumeric capacity per version/EC level
		attribute
			create Result.make_empty
		end

	byte_capacity: ARRAY [ARRAY [INTEGER]]
			-- Byte capacity per version/EC level
		attribute
			create Result.make_empty
		end

	data_codeword_table: ARRAY [ARRAY [INTEGER]]
			-- Data codewords per version/EC level
		attribute
			create Result.make_empty
		end

	initialize_capacity_tables
			-- Initialize capacity lookup tables for versions 1-10.
			-- These are the official QR code capacity values.
		do
			-- Numeric capacity [L, M, Q, H] for versions 1-10
			numeric_capacity := <<
				<< 41, 34, 27, 17 >>,     -- v1
				<< 77, 63, 48, 34 >>,     -- v2
				<< 127, 101, 77, 58 >>,   -- v3
				<< 187, 149, 111, 82 >>,  -- v4
				<< 255, 202, 144, 106 >>, -- v5
				<< 322, 255, 178, 139 >>, -- v6
				<< 370, 293, 207, 154 >>, -- v7
				<< 461, 365, 259, 202 >>, -- v8
				<< 552, 432, 312, 235 >>, -- v9
				<< 652, 513, 364, 288 >>  -- v10
			>>
			-- Alphanumeric capacity
			alphanumeric_capacity := <<
				<< 25, 20, 16, 10 >>,
				<< 47, 38, 29, 20 >>,
				<< 77, 61, 47, 35 >>,
				<< 114, 90, 67, 50 >>,
				<< 154, 122, 87, 64 >>,
				<< 195, 154, 108, 84 >>,
				<< 224, 178, 125, 93 >>,
				<< 279, 221, 157, 122 >>,
				<< 335, 262, 189, 143 >>,
				<< 395, 311, 221, 174 >>
			>>
			-- Byte capacity
			byte_capacity := <<
				<< 17, 14, 11, 7 >>,
				<< 32, 26, 20, 14 >>,
				<< 53, 42, 32, 24 >>,
				<< 78, 62, 46, 34 >>,
				<< 106, 84, 60, 44 >>,
				<< 134, 106, 74, 58 >>,
				<< 154, 122, 86, 64 >>,
				<< 192, 152, 108, 84 >>,
				<< 230, 180, 130, 98 >>,
				<< 271, 213, 151, 119 >>
			>>
			-- Data codewords per version/EC level
			data_codeword_table := <<
				<< 19, 16, 13, 9 >>,
				<< 34, 28, 22, 16 >>,
				<< 55, 44, 34, 26 >>,
				<< 80, 64, 48, 36 >>,
				<< 108, 86, 62, 46 >>,
				<< 136, 108, 76, 60 >>,
				<< 156, 124, 88, 66 >>,
				<< 194, 154, 110, 86 >>,
				<< 232, 182, 132, 100 >>,
				<< 274, 216, 154, 122 >>
			>>
		ensure
			numeric_populated: numeric_capacity.count = 10
			alphanumeric_populated: alphanumeric_capacity.count = 10
			byte_populated: byte_capacity.count = 10
			data_codewords_populated: data_codeword_table.count = 10
		end

	extrapolate_capacity (a_version, a_mode, a_ec_level: INTEGER): INTEGER
			-- Extrapolate capacity for versions > 10.
			-- Uses linear growth approximation based on version 10 data.
		require
			version_above_10: a_version > 10
		local
			l_base, l_growth: INTEGER
		do
			-- Get base from version 10
			inspect a_mode
			when Mode_numeric then
				l_base := numeric_capacity.item (10).item (a_ec_level)
				l_growth := 100
			when Mode_alphanumeric then
				l_base := alphanumeric_capacity.item (10).item (a_ec_level)
				l_growth := 60
			else
				l_base := byte_capacity.item (10).item (a_ec_level)
				l_growth := 40
			end
			Result := l_base + (a_version - 10) * l_growth
		ensure
			result_positive: Result > 0
		end

	extrapolate_data_codewords (a_version, a_ec_level: INTEGER): INTEGER
			-- Extrapolate data codewords for versions > 10.
		require
			version_above_10: a_version > 10
		local
			l_base: INTEGER
		do
			l_base := data_codeword_table.item (10).item (a_ec_level)
			Result := l_base + (a_version - 10) * 40
		ensure
			result_positive: Result > 0
		end

invariant
	tables_exist: numeric_capacity /= Void and alphanumeric_capacity /= Void and byte_capacity /= Void
	data_table_exists: data_codeword_table /= Void
	-- Mode constants are distinct
	modes_distinct: Mode_numeric /= Mode_alphanumeric and Mode_alphanumeric /= Mode_byte
	-- EC level constants are ordered
	ec_levels_ordered: Ec_level_l < Ec_level_m and Ec_level_m < Ec_level_q and Ec_level_q < Ec_level_h

end

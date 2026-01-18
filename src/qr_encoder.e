note
	description: "[
		Encodes input data into QR code bit stream.
		Supports numeric, alphanumeric, and byte modes.

		SPECIFICATION:
		- Numeric mode: Digits only (0-9), ~3.3 bits per character
		- Alphanumeric mode: 0-9, A-Z, space, $%*+-./: (~5.5 bits per char)
		- Byte mode: Any 8-bit data (8 bits per char)

		ENCODING PROCESS:
		1. Detect optimal mode
		2. Add 4-bit mode indicator
		3. Add character count (bit length varies by version/mode)
		4. Encode data according to mode
		5. Add terminator and padding

		CONTRACT GUARANTEES:
		- Mode detection always returns valid mode
		- Encoded bits are always byte-aligned after encoding
		- All codewords are in valid GF(2^8) range (0-255)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	QR_ENCODER

create
	make

feature {NONE} -- Initialization

	make
			-- Create encoder.
		do
			mode := Mode_byte
			version := 1
			create bits.make (1000)
		ensure
			default_mode: mode = Mode_byte
			default_version: version = 1
			bits_empty: bits.is_empty
		end

feature -- Access

	mode: INTEGER
			-- Encoding mode (1=numeric, 2=alphanumeric, 4=byte)

	bits: ARRAYED_LIST [BOOLEAN]
			-- Encoded bit stream

	version: INTEGER
			-- QR version being encoded for

feature -- Status report

	bit_count: INTEGER
			-- Number of bits in encoded stream.
		do
			Result := bits.count
		ensure
			result_non_negative: Result >= 0
			result_matches_bits: Result = bits.count
		end

feature -- Query

	detect_mode (a_data: STRING): INTEGER
			-- Detect optimal encoding mode for data.
			-- Returns most efficient mode that can encode all characters.
		require
			data_not_void: a_data /= Void
		local
			l_i: INTEGER
			l_c: CHARACTER
			l_is_numeric, l_is_alphanumeric: BOOLEAN
		do
			l_is_numeric := True
			l_is_alphanumeric := True
			from l_i := 1 until l_i > a_data.count loop
				l_c := a_data.item (l_i)
				if not (l_c >= '0' and l_c <= '9') then
					l_is_numeric := False
				end
				if not is_alphanumeric_char (l_c) then
					l_is_alphanumeric := False
				end
				l_i := l_i + 1
			end
			if l_is_numeric then
				Result := Mode_numeric
			elseif l_is_alphanumeric then
				Result := Mode_alphanumeric
			else
				Result := Mode_byte
			end
		ensure
			result_valid: Result = Mode_numeric or Result = Mode_alphanumeric or Result = Mode_byte
			-- Numeric is most restrictive
			numeric_implies_all_digits: Result = Mode_numeric implies
				across a_data as c all c >= '0' and c <= '9' end
		end

	to_codewords: ARRAY [INTEGER]
			-- Convert bit stream to 8-bit codewords.
		require
			bits_byte_aligned: bits.count \\ 8 = 0
		local
			l_i, l_cw, l_bit: INTEGER
			l_list: ARRAYED_LIST [INTEGER]
		do
			create l_list.make (bits.count // 8 + 1)
			l_cw := 0
			l_bit := 0
			from l_i := 1 until l_i > bits.count loop
				l_cw := l_cw |<< 1
				if bits.i_th (l_i) then
					l_cw := l_cw.bit_or (1)
				end
				l_bit := l_bit + 1
				if l_bit = 8 then
					l_list.extend (l_cw)
					l_cw := 0
					l_bit := 0
				end
				l_i := l_i + 1
			end
			-- Pad last byte if incomplete
			if l_bit > 0 then
				l_cw := l_cw |<< (8 - l_bit)
				l_list.extend (l_cw)
			end
			create Result.make_from_array (l_list.to_array)
		ensure
			result_not_void: Result /= Void
			result_count: Result.count = bits.count // 8
			all_codewords_valid: across Result as c all c >= 0 and c <= 255 end
		end

feature -- Element change

	encode (a_data: STRING; a_version: INTEGER)
			-- Encode string data to bit stream.
		require
			data_not_empty: not a_data.is_empty
			version_valid: a_version >= 1 and a_version <= 40
		do
			version := a_version
			mode := detect_mode (a_data)
			bits.wipe_out
			-- Add mode indicator
			add_mode_indicator
			-- Add character count
			add_character_count (a_data.count)
			-- Encode data
			inspect mode
			when Mode_numeric then encode_numeric (a_data)
			when Mode_alphanumeric then encode_alphanumeric (a_data)
			else encode_byte (a_data)
			end
			-- Add terminator and padding
			add_terminator
		ensure
			version_set: version = a_version
			bits_not_empty: not bits.is_empty
			bits_byte_aligned: bits.count \\ 8 = 0
		end

	encode_numeric (a_data: STRING)
			-- Encode numeric data (0-9 only).
		require
			data_is_numeric: detect_mode (a_data) = Mode_numeric
		local
			l_i, l_group, l_bits_needed: INTEGER
			l_val: INTEGER
		do
			from l_i := 1 until l_i > a_data.count loop
				l_group := (a_data.count - l_i + 1).min (3)
				l_val := a_data.substring (l_i, l_i + l_group - 1).to_integer
				if l_group = 3 then
					l_bits_needed := 10
				elseif l_group = 2 then
					l_bits_needed := 7
				else
					l_bits_needed := 4
				end
				add_bits (l_val, l_bits_needed)
				l_i := l_i + l_group
			end
		end

	encode_alphanumeric (a_data: STRING)
			-- Encode alphanumeric data (0-9, A-Z, space, $%*+-./:).
		require
			data_is_alphanumeric: detect_mode (a_data) <= Mode_alphanumeric
		local
			l_i, l_val1, l_val2: INTEGER
		do
			from l_i := 1 until l_i > a_data.count loop
				l_val1 := alphanumeric_value (a_data.item (l_i))
				if l_i + 1 <= a_data.count then
					l_val2 := alphanumeric_value (a_data.item (l_i + 1))
					add_bits (l_val1 * 45 + l_val2, 11)
					l_i := l_i + 2
				else
					add_bits (l_val1, 6)
					l_i := l_i + 1
				end
			end
		end

	encode_byte (a_data: STRING)
			-- Encode arbitrary byte data.
		local
			l_i: INTEGER
		do
			from l_i := 1 until l_i > a_data.count loop
				add_bits (a_data.item (l_i).code, 8)
				l_i := l_i + 1
			end
		end

	add_terminator
			-- Add terminator and padding to fill capacity.
		local
			l_data_capacity, l_remaining: INTEGER
			l_pad_byte: INTEGER
		do
			l_data_capacity := data_capacity_bits
			-- Add terminator (up to 4 zeros)
			l_remaining := l_data_capacity - bits.count
			if l_remaining > 4 then
				l_remaining := 4
			end
			add_bits (0, l_remaining)
			-- Pad to byte boundary
			from until (bits.count \\ 8) = 0 loop
				bits.extend (False)
			end
			-- Add pad bytes (0xEC, 0x11 alternating)
			l_pad_byte := 0
			from until bits.count >= l_data_capacity loop
				if l_pad_byte = 0 then
					add_bits (0xEC, 8)
					l_pad_byte := 1
				else
					add_bits (0x11, 8)
					l_pad_byte := 0
				end
			end
		ensure
			byte_aligned: bits.count \\ 8 = 0
		end

feature {NONE} -- Implementation

	add_mode_indicator
			-- Add 4-bit mode indicator.
		do
			add_bits (mode, 4)
		ensure
			bits_increased: bits.count = old bits.count + 4
		end

	add_character_count (a_count: INTEGER)
			-- Add character count with version-dependent bit length.
		require
			count_positive: a_count > 0
		local
			l_bits_needed: INTEGER
		do
			if version <= 9 then
				inspect mode
				when Mode_numeric then l_bits_needed := 10
				when Mode_alphanumeric then l_bits_needed := 9
				else l_bits_needed := 8
				end
			elseif version <= 26 then
				inspect mode
				when Mode_numeric then l_bits_needed := 12
				when Mode_alphanumeric then l_bits_needed := 11
				else l_bits_needed := 16
				end
			else
				inspect mode
				when Mode_numeric then l_bits_needed := 14
				when Mode_alphanumeric then l_bits_needed := 13
				else l_bits_needed := 16
				end
			end
			add_bits (a_count, l_bits_needed)
		ensure
			bits_increased: bits.count > old bits.count
		end

	add_bits (a_value, a_count: INTEGER)
			-- Add `a_count` bits from `a_value` to bit stream.
		require
			count_positive: a_count > 0
			count_reasonable: a_count <= 32
		local
			l_i: INTEGER
		do
			from l_i := a_count - 1 until l_i < 0 loop
				bits.extend ((a_value |>> l_i).bit_and (1) = 1)
				l_i := l_i - 1
			end
		ensure
			bits_increased: bits.count = old bits.count + a_count
		end

	is_alphanumeric_char (a_char: CHARACTER): BOOLEAN
			-- Is character in alphanumeric set?
		do
			Result := (a_char >= '0' and a_char <= '9') or
			          (a_char >= 'A' and a_char <= 'Z') or
			          a_char = ' ' or a_char = '$' or a_char = '%%' or
			          a_char = '*' or a_char = '+' or a_char = '-' or
			          a_char = '.' or a_char = '/' or a_char = ':'
		end

	alphanumeric_value (a_char: CHARACTER): INTEGER
			-- Get alphanumeric encoding value for character.
		require
			is_alphanumeric: is_alphanumeric_char (a_char)
		do
			if a_char >= '0' and a_char <= '9' then
				Result := a_char.code - ('0').code
			elseif a_char >= 'A' and a_char <= 'Z' then
				Result := a_char.code - ('A').code + 10
			elseif a_char = ' ' then Result := 36
			elseif a_char = '$' then Result := 37
			elseif a_char = '%%' then Result := 38
			elseif a_char = '*' then Result := 39
			elseif a_char = '+' then Result := 40
			elseif a_char = '-' then Result := 41
			elseif a_char = '.' then Result := 42
			elseif a_char = '/' then Result := 43
			elseif a_char = ':' then Result := 44
			else Result := 0
			end
		ensure
			result_in_range: Result >= 0 and Result <= 44
		end

	data_capacity_bits: INTEGER
			-- Data capacity in bits for current version and EC level M.
		do
			-- Simplified table for EC level M
			inspect version
			when 1 then Result := 128
			when 2 then Result := 224
			when 3 then Result := 352
			when 4 then Result := 512
			when 5 then Result := 688
			when 6 then Result := 864
			when 7 then Result := 992
			when 8 then Result := 1232
			when 9 then Result := 1456
			when 10 then Result := 1728
			else
				-- Approximate for higher versions
				Result := 1728 + (version - 10) * 300
			end
		ensure
			result_positive: Result > 0
		end

feature -- Constants

	Mode_numeric: INTEGER = 1
			-- Numeric mode (0-9)

	Mode_alphanumeric: INTEGER = 2
			-- Alphanumeric mode (0-9, A-Z, space, $%%*+-./:)

	Mode_byte: INTEGER = 4
			-- Byte mode (arbitrary 8-bit data)

invariant
	mode_valid: mode = Mode_numeric or mode = Mode_alphanumeric or mode = Mode_byte
	bits_exist: bits /= Void
	version_valid: version >= 1 and version <= 40

end

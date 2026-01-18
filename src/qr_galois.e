note
	description: "[
		Galois Field GF(2^8) arithmetic for Reed-Solomon error correction.
		Uses primitive polynomial x^8 + x^4 + x^3 + x^2 + 1 (0x11D).

		SPECIFICATION:
		- Field contains 256 elements: {0, 1, 2, ..., 255}
		- Addition is XOR (bitwise exclusive-or)
		- Multiplication uses logarithm/antilogarithm tables
		- All operations are closed within the field

		MATHEMATICAL PROPERTIES:
		- Additive identity: a + 0 = a
		- Additive inverse: a + a = 0 (every element is its own inverse)
		- Multiplicative identity: a * 1 = a
		- Multiplicative zero: a * 0 = 0
		- Multiplicative inverse: a * inverse(a) = 1 (for a != 0)
		- Commutativity: a + b = b + a, a * b = b * a
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	QR_GALOIS

create
	make

feature {NONE} -- Initialization

	make
			-- Create Galois field with precomputed tables.
		do
			initialize_tables
		ensure
			exp_table_valid: exp_table.count = 512
			log_table_valid: log_table.count = 256
		end

feature -- Access

	exp (a_power: INTEGER): INTEGER
			-- Alpha to the power a_power (antilogarithm).
		require
			power_in_range: a_power >= 0 and a_power < 512
		do
			Result := exp_table.item (a_power + 1)
		ensure
			result_in_field: Result >= 0 and Result <= 255
		end

	log (a_value: INTEGER): INTEGER
			-- Logarithm base alpha of value.
		require
			value_in_field: a_value > 0 and a_value <= 255
		do
			Result := log_table.item (a_value + 1)
		ensure
			result_in_range: Result >= 0 and Result <= 254
		end

feature -- Operations

	add (a_x, a_y: INTEGER): INTEGER
			-- Add in GF(2^8) (XOR operation).
		require
			x_in_field: a_x >= 0 and a_x <= 255
			y_in_field: a_y >= 0 and a_y <= 255
		do
			Result := a_x.bit_xor (a_y)
		ensure
			result_in_field: Result >= 0 and Result <= 255
			commutative: Result = a_y.bit_xor (a_x)
			additive_identity_x: a_y = 0 implies Result = a_x
			additive_identity_y: a_x = 0 implies Result = a_y
			self_inverse: a_x = a_y implies Result = 0
		end

	multiply (a_x, a_y: INTEGER): INTEGER
			-- Multiply in GF(2^8).
		require
			x_in_field: a_x >= 0 and a_x <= 255
			y_in_field: a_y >= 0 and a_y <= 255
		do
			if a_x = 0 or a_y = 0 then
				Result := 0
			else
				Result := exp_table.item (log_table.item (a_x + 1) + log_table.item (a_y + 1) + 1)
			end
		ensure
			result_in_field: Result >= 0 and Result <= 255
			zero_absorbs_x: a_x = 0 implies Result = 0
			zero_absorbs_y: a_y = 0 implies Result = 0
			identity_x: a_y = 1 implies Result = a_x
			identity_y: a_x = 1 implies Result = a_y
		end

	divide (a_x, a_y: INTEGER): INTEGER
			-- Divide in GF(2^8).
		require
			x_in_field: a_x >= 0 and a_x <= 255
			y_in_field_nonzero: a_y > 0 and a_y <= 255
		do
			if a_x = 0 then
				Result := 0
			else
				Result := exp_table.item ((log_table.item (a_x + 1) - log_table.item (a_y + 1) + 255) \\ 255 + 1)
			end
		ensure
			result_in_field: Result >= 0 and Result <= 255
			zero_divided: a_x = 0 implies Result = 0
			divide_by_one: a_y = 1 implies Result = a_x
			self_divide: (a_x = a_y and a_x > 0) implies Result = 1
		end

	inverse (a_x: INTEGER): INTEGER
			-- Multiplicative inverse in GF(2^8).
		require
			x_nonzero: a_x > 0 and a_x <= 255
		do
			Result := exp_table.item (255 - log_table.item (a_x + 1) + 1)
		ensure
			result_in_field: Result > 0 and Result <= 255
			inverse_of_one: a_x = 1 implies Result = 1
		end

	power (a_x, a_n: INTEGER): INTEGER
			-- a_x to the power a_n in GF(2^8).
		require
			x_in_field: a_x >= 0 and a_x <= 255
			n_non_negative: a_n >= 0
		do
			if a_x = 0 then
				if a_n = 0 then
					Result := 1  -- 0^0 = 1 by convention
				else
					Result := 0  -- 0^n = 0 for n > 0
				end
			elseif a_n = 0 then
				Result := 1  -- x^0 = 1 for x != 0
			else
				Result := exp_table.item ((log_table.item (a_x + 1) * a_n) \\ 255 + 1)
			end
		ensure
			result_in_field: Result >= 0 and Result <= 255
			power_zero: (a_n = 0 and a_x /= 0) implies Result = 1
			power_one: a_n = 1 implies Result = a_x
			zero_power: (a_x = 0 and a_n > 0) implies Result = 0
			one_power: a_x = 1 implies Result = 1
		end

feature -- Constants

	Primitive_polynomial: INTEGER = 0x11D
			-- x^8 + x^4 + x^3 + x^2 + 1 = 285

	Field_size: INTEGER = 256
			-- GF(2^8) has 256 elements

	Alpha: INTEGER = 2
			-- Primitive element of the field

feature {NONE} -- Implementation

	exp_table: ARRAY [INTEGER]
			-- Antilog table (alpha^i)
		attribute
			create Result.make_filled (0, 1, 512)
		end

	log_table: ARRAY [INTEGER]
			-- Log table (log_alpha(i))
		attribute
			create Result.make_filled (0, 1, 256)
		end

	initialize_tables
			-- Build exp and log lookup tables.
		local
			l_x, l_i: INTEGER
		do
			l_x := 1
			from l_i := 0 until l_i >= 255 loop
				exp_table.put (l_x, l_i + 1)
				log_table.put (l_i, l_x + 1)
				l_x := l_x |<< 1
				if l_x >= 256 then
					l_x := l_x.bit_xor (Primitive_polynomial)
				end
				l_i := l_i + 1
			end
			from l_i := 255 until l_i >= 512 loop
				exp_table.put (exp_table.item (l_i - 254), l_i + 1)
				l_i := l_i + 1
			end
		end

invariant
	exp_table_exists: exp_table /= Void
	log_table_exists: log_table /= Void
	exp_table_size: exp_table.count = 512
	log_table_size: log_table.count = 256

end

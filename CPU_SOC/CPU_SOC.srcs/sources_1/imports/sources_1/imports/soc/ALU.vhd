----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/22/2017 10:22:27 AM
-- Design Name: 
-- Module Name: ALU16 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( clk : in STD_LOGIC;
           opcode : in STD_LOGIC_VECTOR (3 downto 0);
           shift_rotate_operation : in STD_LOGIC_VECTOR (3 downto 0);
           oprand_a : in STD_LOGIC_VECTOR (15 downto 0);
           oprand_b : in STD_LOGIC_VECTOR (15 downto 0);
           result : out STD_LOGIC_VECTOR (15 downto 0);
           result_high : out std_logic_vector(15 downto 0); -- high 16 bits of multiplication
           zero,carry : out STD_LOGIC);
end ALU;

architecture Behavioral of ALU is

signal logic : std_logic_vector(15 downto 0);
signal accumulator : std_logic_vector(16 downto 0);
signal accumulator_mul : std_logic_vector(31 downto 0);
signal shift : std_logic_vector(15 downto 0);
signal result_t: std_logic_vector(15 downto 0);
signal result_t_high: std_logic_vector(15 downto 0);
signal carry_t : std_logic;

begin

-------- calculate --------
     process(clk) is
     
     begin 
     
         if (clk'event and clk ='1') then
             case opcode is
                 when "0001" => logic <= oprand_a and oprand_b; -- and
                 when "0010" => logic <= oprand_a or oprand_b; -- or
                 when "0011" => logic <= oprand_a nor oprand_b; -- nor
                 when "0100" => logic <= oprand_a xor oprand_b; -- xor
                 when "0101" => shift <= to_stdlogicvector(to_bitvector(oprand_a) sll conv_integer(shift_rotate_operation)); -- sll
                 when "0110" => shift <= to_stdlogicvector(to_bitvector(oprand_a) srl conv_integer(shift_rotate_operation)); -- srl
                 when "0111" => shift <= to_stdlogicvector(to_bitvector(oprand_a) sla conv_integer(shift_rotate_operation)); -- sla
                 when "1000" => shift <= to_stdlogicvector(to_bitvector(oprand_a) srl conv_integer(shift_rotate_operation)); -- sra
                 when "1001" => shift <= to_stdlogicvector(to_bitvector(oprand_a) rol conv_integer(shift_rotate_operation)); -- rol
                 when "1010" => shift <= to_stdlogicvector(to_bitvector(oprand_a) ror conv_integer(shift_rotate_operation)); -- ror
                 when "1011" => accumulator <= ("0" & oprand_a) + ("0" & oprand_b); -- add
                 when "1100" => accumulator <= ("0" & oprand_a) - ("0" & oprand_b); -- subtract
                 when "1101" => accumulator_mul <= oprand_a * oprand_b; -- multiply
                 when others => null;
             end case;
         end if;
      
      end process;
      
      -------- temperary result --------
      
      result_t <= logic when opcode = "0001" or opcode = "0010" or opcode = "0011" or opcode = "0100" else
                  shift when opcode = "0101" or opcode = "0110" or opcode = "0111" or opcode = "1000" or opcode = "1001" or opcode = "1010" else
                  accumulator(15 downto 0) when opcode = "1011" or opcode = "1100" else
                  accumulator_mul(15 downto 0) when opcode = "1101";
      
      result_t_high <= accumulator_mul(31 downto 16) when opcode = "1101" else ( others =>'0');
      
      carry_t <= accumulator(16) when opcode = "1011" or opcode = "1100" else '0'; 
      
      -------- output --------

      result <= result_t when clk = '1' ;
      result_high <= result_t_high when opcode ="1101"  else ( others => 'Z');
      carry <= carry_t when clk = '1' and (opcode = "1011" or opcode = "1100") else '0';
      
      zero <= '1' when result_t = 0 else
              '0';


end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/17 10:52:31
-- Design Name: 
-- Module Name: top - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
--  Port ( );
end top;

architecture Behavioral of top is
component MicroController is ---entity  Microcontroller declaration
  port(
       clk,reset   : in  std_logic; ----------clock and reset signal
       oe_bar      : out std_logic;-------to read from instruction memory
       address     : out std_logic_vector(7 downto 0);-----current address
       instruction : in  std_logic_vector(20 downto 0)------return 21 bit instruction
       
       );
    
end component MicroController;

component inst_ROM is ---entity  inst_ROM declaration
  port(
       oe_bar   : in  std_logic; --------------17 bit operation instruction output enable
       address  : in  std_logic_vector(7 downto 0);--------current instruction address
       data_out : out std_logic_vector(20 downto 0)------return 21 bit instruction
       );
    
end component inst_ROM;

---------- wires ----------
signal oe_bar: std_logic;
signal address: std_logic_vector(7 downto 0);
signal instruction: std_logic_vector(20 downto 0);

---------- clk, rst ----------
signal clk: std_logic;
signal rst: std_logic;

---------- clock period ----------
constant clk_period : time := 10 ns;

begin
-- clock_process
    clock_process : process
    begin 
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
 -- stimulate process
       stim_proc : process
        begin
        
        rst <= '1';
        
        wait for 2*clk_period;
        
        rst <= '0';
        
        wait for clk_period;
        
        wait;
        end process;
        
---------- port map ----------
u1: Microcontroller port map(
                             clk => clk,
                             reset => rst,
                             oe_bar => oe_bar,
                             instruction => instruction,
                             address => address
                             );
u2: inst_ROM port map (
                       oe_bar => oe_bar,
                       address => address,
                       data_out => instruction
                       );

end Behavioral;

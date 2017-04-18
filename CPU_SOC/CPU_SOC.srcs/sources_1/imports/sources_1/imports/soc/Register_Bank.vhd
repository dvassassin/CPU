library ieee; ---library including
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Register_Bank is ---entity  Register_Bank declaration
port(
     clk,reset,write_enable: in std_logic;------clk and reset signal 
     data_in               : in std_logic_vector(15 downto 0);----input data to write to the registers
     address_W,address_R1,address_R2: in std_logic_vector(7 downto 0);------write address,Rx address,Ry address
     data_out1,data_out2   : out std_logic_vector(15 downto 0)  ---Rx data and Ry data
     );
end Register_Bank;

architecture behavior of Register_Bank is 

type ResgisterS is array(0 to 255) of std_logic_vector(15 downto 0);--16 x 8bit register
signal RegBank :ResgisterS;
signal clk_t : std_logic;


begin -----architecture begin
  
 data_out1 <= RegBank( conv_integer(address_R1) );----read the address1's  data asynchronously
 data_out2 <= RegBank( conv_integer(address_R2) ); ----read the address2's  data asynchronously
  

Write:process(clk,reset)  
  begin
    if reset ='1' then ---asynchronous reset 
        null;
      else
     if rising_edge(clk) and write_enable='1'  then         
         RegBank( conv_integer(address_W) )<=data_in;--writing data into the Register
         end if;       
     end if;
   
end  process Write; 
    
end behavior;

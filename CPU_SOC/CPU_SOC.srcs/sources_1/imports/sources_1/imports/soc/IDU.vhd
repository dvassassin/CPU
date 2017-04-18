library ieee; ---library including
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity IDU is ---entity  IDU (Instruction Decode Unit) declaration
port(
     Instruction : in std_logic_vector(20 downto 0);-----input instruction to  be decoded
     opcode   : out std_logic_vector(3 downto 0);-----4bit opcode for ALU(IR(15 DOWNTO 12))
     shift_rotate_operation : out std_logic_vector(3 downto 0);---a number between 0 to 7 indicating "how amny times"
     Operand_Selection      : out std_logic;-- 0 means  operand2,=Ry,1means operand2<=kk
     
     X_address,Y_address    : out std_logic_vector(7 downto 0);----Rx ADDRESS AND Ry address
       
     Conditional    : out std_logic; ------indicating the JUMP is conditioanl or not 
     Jump           : out std_logic;-------indicating the instruction type ,1means JMP,JZ,JC .0 MEANS NORMAL
     Jump_address   : out std_logic_vector(7 downto 0);---indicaiitng the line of jump
     
     Condition_flag : out std_logic;----condition for jump , 0 means  JZ ,and 1 mean s JC
     Exp            : out std_logic----indicating whether the instruction is export or not
    );
end IDU;

architecture behavior of IDU is 



begin
  
----------------------------------Rx  address updating----------------------------
 X_address         <=Instruction(15 downto 8) when Instruction(19 downto 16)="0000"and Instruction(20)='1' else--LOAD Rx,kk 
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0000"and Instruction(20)='0' else--LOAD Rx,Ry
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0001"and Instruction(20)='1' else--AND rX,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0001"and Instruction(20)='0' else--AND rX,Ry
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0010"and Instruction(20)='1' else--or RX,kk
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0010"and Instruction(20)='0' else--or Rx,Ry
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0011"and Instruction(20)='1' else--nor Rx,kk
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0011"and Instruction(20)='0' else--nor Rx,Ry
                     
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0100"and Instruction(20)='1' else--xor rX,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0100"and Instruction(20)='0' else--xor Rx,Ry
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1011"and Instruction(20)='1' else--Add rX,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1011"and Instruction(20)='0' else--Add Rx,Ry
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1100"and Instruction(20)='1' else--SUB Rx,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1100"and Instruction(20)='0' else--SUB Rx,Ry
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1101"and Instruction(20)='1' else--MUL,Rx,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1101"and Instruction(20)='0' else--MUL,Rx,Ry
                     
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0101" else--sll Rx
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0111" else--sla Rx                     
                     Instruction(15 downto 8) when Instruction(19 downto 16)="0110" else--SRL rX,KK                     
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1000" else--SRA rX,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1001" else--ROL rX,KK
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1010" else--ROR Rx,kk
                     
                     Instruction(15 downto 8) when Instruction(19 downto 16)="1110" else--jump RX
                     Instruction(15 downto 8) when Instruction(20 downto 16)="11111" ; ---EXP   --exp rx,kk

-----------------------------------------------------------------------------------                    

 ---------------------------------Y address updating----------------------------
 Y_address         <=Instruction(7 downto  0) when Instruction(19 downto 16)="0000"and Instruction(20)='0' else --load rx,ry
                     Instruction(7 downto  0) when Instruction(19 downto 16)="0001"and Instruction(20)='0' else--and rx,ry
                     Instruction(7 downto  0) when Instruction(19 downto 16)="0010"and Instruction(20)='0' else--or rx,ry
                     Instruction(7 downto  0) when Instruction(19 downto 16)="0011"and Instruction(20)='0' else--nor rx,ry
                     Instruction(7 downto  0) when Instruction(19 downto 16)="0100"and Instruction(20)='0' else--xor rx,ry
                     Instruction(7 downto  0) when Instruction(19 downto 16)="1011"and Instruction(20)='0' else--add rx,ry
                     Instruction(7 downto  0) when Instruction(19 downto 16)="1100"and Instruction(20)='0' else--SUB Rx,rY
                     Instruction(7 downto  0) when Instruction(19 downto 16)="1101"and Instruction(20)='0' else -- MUL
                     (others =>'Z');
---------------------------------------------------------------------------------                    

-----------------------------------operation updating-----------------------------------
opcode             <="0000"   when Instruction(19 downto 16)="0000" else ----LOAD Rx,Ry
                     "0001"   when Instruction(19 downto 16)="0001" else-----AND Rx,Ry
                     "0010"   when Instruction(19 downto 16)="0010" else-----OR Rx,Ry
                     "0011"   when Instruction(19 downto 16)="0011" else-----nOR Rx,Ry
                     "0100"   when Instruction(19 downto 16)="0100" else----XOR RX,rY
                     "1000"   when Instruction(19 downto 16)="0101" else----SLL Rx,kk
                     "0110"   when Instruction(19 downto 16)="0110" else----SRL Rx,kk
                     "0111"   when Instruction(19 downto 16)="0111" else----SLA Rx,Ry
                     "1000"   when Instruction(19 downto 16)="1000" else----SRA Rx,kk
                     "1001"   when Instruction(19 downto 16)="1001" else----ROL Rx,kk
                     "1010"   when Instruction(19 downto 16)="1010" else----ROR RX,KK
                     "1011"   when Instruction(19 downto 16)="1011" ELSE----ADD Rx,Ry
                     "1100"   when Instruction(19 downto 16)="1100" else----SUB Rx,Ry
                     "1101"   when Instruction(19 downto 16)="1100" else----MUL Rx,Ry
                     
                     "1110"   when Instruction(19 downto 16)="1110" else----jump RX                    
                     "1111"   when Instruction(20 downto 16)="11111" ;  ----exp RX,KK                     
                    

  ------------------------------------------------------------------------





-- -------------------------Operand_Selection updating---------------------------
Operand_Selection  <='1'     when Instruction(19 downto 16)="0001"and Instruction(20)='1' else---choose kk to oprand2
                     '0'     when Instruction(19 downto 16)="0001"and Instruction(20)='0' else--- choose Ry to oprand2      
                     '1'     when Instruction(19 downto 16)="0010"and Instruction(20)='1' else
                     '0'     when Instruction(19 downto 16)="0010"and Instruction(20)='0' else
                     '1'     when Instruction(19 downto 16)="0011"and Instruction(20)='1' else
                     '0'     when Instruction(19 downto 16)="0011"and Instruction(20)='0' else
                     '1'     when Instruction(19 downto 16)="0100"and Instruction(20)='1' else
                     '0'     when Instruction(19 downto 16)="0100"and Instruction(20)='0' else
                     '1'     when Instruction(19 downto 16)="1011"and Instruction(20)='1' else
                     '0'     when Instruction(19 downto 16)="1011"and Instruction(20)='0' else
                     '1'     when Instruction(19 downto 16)="1100"and Instruction(20)='1' else
                     '0'     when Instruction(19 downto 16)="1100"and Instruction(20)='0' else
                     '1'     when Instruction(19 downto 16)="1101"and Instruction(20)='1' else
                     '0'     when Instruction(19 downto 16)="1101"and Instruction(20)='0';

-----------------------------------------------------------------------------------                     
                     
-----------------------------Shift_Rotate_Operation----------------------

shift_rotate_operation <=Instruction( 3 downto 0)  when Instruction(19 downto 16)="0101" else-----  HOW MANY TIMES
                         Instruction( 3 downto 0)  when Instruction(19 downto 16)="0110" else
                         Instruction( 3 downto 0)  when Instruction(19 downto 16)="0111" else
                         Instruction( 3 downto 0)  when Instruction(19 downto 16)="1000" else
                         Instruction( 3 downto 0)  when Instruction(19 downto 16)="1001" else
                         Instruction( 3 downto 0)  when Instruction(19 downto 16)="1010" else
                         "0000";

----------------------------------Conditional----------------------------------
Conditional          <='1'    when Instruction(20 downto 16)="01110" else   --JUMP UNCONDITIONAL
                       '0' ;
-------------------------------------------------------------------------------------------                         
--------------------------------JUMP----------------------------------  jump enable!!!!!!!!                    
Jump                   <='1'    when Instruction(20 downto 16)="01110"or Instruction(20 downto 15)="111100"or Instruction(20 downto 15)="111101" ELSE---INSTRUCTION TYPE 
                         '0';     
--------------------------------------------------------------------------------
-------------------------Jump_address----------------------------------
Jump_address           <= Instruction(7 downto 0) when Instruction(19 downto 16)="1110" and Instruction(20)='0' else----uconditional jump address
                          Instruction(7 downto 0) when Instruction(19 downto 15)="11100"and Instruction(20)='1' else---JZ
                          Instruction(7 downto 0) when Instruction(19 downto 15)="11101"and Instruction(20)='1' ;---JC
-------------------------------------------------------------------------- 

------------------------------------Condition_flag-------------------------------
Condition_flag         <= '0'    when Instruction(19 downto 15)="11100"and Instruction(20)='1' else---JZ-
                          '1'    when Instruction(19 downto 15)="11101"and Instruction(20)='1';---JC
-------------------------------------------------------------------------- 

------------------------------------EXP Rx,kk-----------------------------
Exp                    <='1'     when Instruction(19 downto 16)="1111"and Instruction(20)='1'ELSE ---expthe Rx address
                         '0';
---------------------------------------------------------------------------


  
end behavior;



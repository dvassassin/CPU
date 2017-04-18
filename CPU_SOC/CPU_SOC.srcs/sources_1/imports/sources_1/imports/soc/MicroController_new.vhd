library ieee; ---library including
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity MicroController is ---entity  Microcontroller declaration
  port(
       clk,reset   : in  std_logic; ----------clock and reset signal
       oe_bar      : out std_logic;-------to read from instruction memory
       address     : out std_logic_vector(7 downto 0);-----current address
       instruction : in  std_logic_vector(20 downto 0)------return 21 bit instruction
       
       );
    
end entity MicroController;

architecture behavior of  MicroController is
  
  

---------------------------component  Register_Bank declaration--------------------------------------------------
component Register_Bank is -----------component  Register_Bank declaration
port(
     clk,reset,write_enable: in std_logic;------clk and reset signal 
     data_in               : in std_logic_vector(15 downto 0);----input data to write to the registers
     address_W,address_R1,address_R2: in std_logic_vector(7 downto 0);------write address,Rx address,Ry address
     data_out1,data_out2   : out std_logic_vector(15 downto 0)  ---Rx data and Ry data
     );
end component Register_Bank;----------------------------------------------
-------------------------------------------------------------------------------------------------------------------


-------------------------component  IDU (Instruction Decode Unit) declaration--------------------------------------
component IDU is -------  IDU (Instruction Decode Unit) declaration
port(
     Instruction    : in  std_logic_vector(20 downto 0);-----input instruction to  be decoded
     opcode      : out std_logic_vector(3 downto 0);-----4bit opcode for ALU(IR(15 DOWNTO 12))
     Shift_Rotate_Operation : out std_logic_vector(3 downto 0);---a number between 0 to 7 indicating "how amny times"
     Operand_Selection      : out std_logic;-- 0 means  operand2,=Ry,1means operand2<=kk
     X_address,Y_address    : out std_logic_vector(7 downto 0);----Rx ADDRESS AND Ry address
     Conditional    : out std_logic; ------indicating the JUMP is conditioanl or not 
     Jump           : out std_logic;-------indicating the instruction type ,1means JMP,JZ,JC .0 MEANS NORMAL
	   Jump_address   : out std_logic_vector(7 downto 0);---indicaiitng the line of jump
     Condition_flag : out std_logic;----condition for jump , 0 means  JZ ,and 1 mean s JC
     Exp            : out std_logic----indicating whether the instruction is export or not
--     Halt           : out std_logic  --1 means stop the excution
    );
end component IDU;--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------- 


---------------------------comonent ALU----------------------------------------------------------------------------
component ALU is ---  ALU (Instruction Decode Unit) declaration
port(
      clk : in STD_LOGIC;
      opcode              : in  std_logic_vector(3 downto 0);-- 4 bit opceode from IDU
      shift_rotate_operation : in  std_logic_vector(3 downto 0);--how many times
      oprand_a,oprand_b    : in  std_logic_vector(15 downto 0);--first an dsecond oprands
      result                 : out std_logic_vector(15 downto 0);--result
      result_high            : out std_logic_vector(15 downto 0);
      zero,carry             : out std_logic--falg zero and carry

     );
END component  ALU; 
------------------------------------------------------------------------------------------------------------------
  
  
-----------------------------general signals -------------------------------------------------------
signal  Pointer,stop_pointer  :  std_logic_vector( 7 downto 0):=(others=>'0');---PCpointer and  stop pointer
signal  stop                  :std_logic:='0';--to stop the program
signal  address_counter_v     : std_logic_vector(7 downto 0):=(others=>'0');---address counting
-----------------------------------------------------------------------------------------------------
 
  
 ---------------wires for modul Register----------------------------------------------------------------- 
signal WEN_to_Reg                        : std_logic;
SIGNAL addr_W_to_Reg,addr_R1_to_Reg,addr_R2_to_Reg : std_logic_vector(7 downto 0);------write address,Rx address,Ry address
signal IR_20_To_16                       :std_logic_vector(4 downto 0);
signal data_to_Reg,data1_from_Reg,data2_from_Reg   : std_logic_vector(15 downto 0);  -----data connected to register bank
------------------------------------------------------------------------------------------------------------  

-------------------wires for module IDU ----------------------------------------------------------------------
signal instruction_to_IDU                : std_logic_vector(20 downto 0);-----to connect 21bit instructions from module Instruction to module IDU
signal operation_from_IDU                : std_logic_vector(3 downto 0) ;-----4bit opcode connected to module ALU
signal ShiftRotateTimes_from_IDU         : std_logic_vector(3 downto 0);------a number incdicating times
signal OperationSelection_from_IDU       : std_logic;-------------------------0 means  operand2<=Ry,1 means operand2<=kk
signal Xaddress_from_IDU,yaddress_from_IDU: std_logic_vector(7 downto 0);-----Rx AND rY ADDRESS
signal conditional_from_IDU              : std_logic;-------------------------junp condition
signal jump_from_idu                     : std_logic;-------------------------indicating the type ,1 means JMP,JZ,OR JC,0 meansnormal
signal JumpAddress_from_IDU              : std_logic_vector(7 downto 0);------vector(7 dwonto 0);----jump to which line
signal ConditionFlag_from_IDU            : std_logic;-------------------------conditio type for type,0 means JZ ,1 means JC
signal Exp_from_IDU                      : STD_LOGIC;-------------------------INDICATING WHETHER THE INSTRUCTION IS EXPORT OOR NOT 
signal halt_form_IDU                     : std_logic;-------------------------1means stop the excution 
---------------------------------------------------------------------------------------------------------------------

--------------------wires for ALU module------------------------------------------------------------------------------
--signal operation_to_ALU                  : std_logic_vector(3 downto 0);-----operation code
      
signal operation_to_ALU                  : std_logic_vector(3 downto 0);-----4bit opcode connected to module ALU
signal operand_A_to_ALU,operand_B_to_ALU : STD_LOGIC_VECTOR(15 DOWNTO 0);---FIRSR AND SECOND operand
signal result_from_ALU                   : std_logic_vector(15 downto 0);---result output from ALU
signal zero_from_ALU,carry_from_ALU      : std_logic;----------------------zero and carry

------------------------------------------------------------------------------------------------------------------------


--------------------Program state ,two state to excution a instruction-----------------------------------------------
type    state is( fetch,excution );---two state to excute a intruction
signal  do : state:=fetch;-------------program state
--------------------------------------------------------------------------------------------------------------------

BEGIN----architecture begin
  
IR_20_To_16<=Instruction(20 downto 16);--get the bits from 16 to 12  

------------------------------address to register updating--------------------------------------------------------------------
 addr_W_to_Reg   <=  Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="10000"  and do =excution else  --load rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="00000"  and do =excution  else--load rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="10001"  and do= excution else--and rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="00001"  and do= excution else  ---and rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="10010"  and do= excution  else--OR rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="00010"  and do= excution ELSE  ---or rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="10011"  and do= excution else--nor rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="00011"  and do= excution else  ---nor rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="10100"  and do= excution  else--XOR rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="00100"  and do= excution else  ---Xor rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="11011"  and do= excution  else--add rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="01011"  and do= excution ELSE  ---add rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="11100"  and do= excution  else--SUB rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(20 downto 16)="01100"  and do= excution else ---SUB rx,ry
                     Xaddress_from_IDU        when   instruction_to_IDU(19 downto 16)="0101"  and do= excution  else--sll rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(19 downto 16)="0111"  and do= excution  else--slA rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(19 downto 16)="0110"  and do= excution  else--srl rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(19 downto 16)="1000"  and do= excution  else--srA rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(19 downto 16)="1001"  and do= excution  else--rol rx,kk
                     Xaddress_from_IDU        when   instruction_to_IDU(19 downto 16)="1010"  and do= excution  ;--ror rx,kk
--                     Xaddress_from_IDU        when   instruction_to_IDU(15 downto 12)="0101"  and do= excution   ; ----imprX,Inport
 -----------------------------------------------------------------------------------------------------------------------


  ------------------------------------ALU oprandA ---------------------------------------------------------------------                
 operand_A_to_ALU <=  data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "10001" and  do=excution else--and rx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "00001" and  do=excution else -- and rx,ry
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "10010" and  do=excution else--or rx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "00010" and  do=excution ELSE -- or rx,ry
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "10011" and  do=excution else--nor rx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "00011" and  do=excution else -- nor rx,ry
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "10100" and  do=excution else--Xor rx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "00100" and  do=excution else -- Xor rx,ry
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "11011" and  do=excution else--add rx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "01011" and  do=excution ELSE -- add rx,ry
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "11100" and  do=excution else--SUB rx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "01100" and  do=excution else -- SUB rx,ry                      
                      data1_from_Reg            when  instruction_to_IDU(19 downto 16)= "0101"  and  do=excution else--sll rx,kk
                      data1_from_Reg            when  instruction_to_IDU(19 downto 16)= "0111"  and  do=excution else--slA rx,kk
                      data1_from_Reg            when  instruction_to_IDU(19 downto 16)= "0110"  and  do=excution else--srl rx,kk
                      data1_from_Reg            when  instruction_to_IDU(19 downto 16)= "1000"  and  do=excution else--srA rx,kk
                      data1_from_Reg            when  instruction_to_IDU(19 downto 16)= "1001"  and  do=excution else--rol rx,kk
                      data1_from_Reg            when  instruction_to_IDU(19 downto 16)= "1010"  and  do=excution else--rorrx,kk
                      data1_from_Reg            when  instruction_to_IDU(20 downto 16)= "11111" and  do=excution ;--exp Rx,kk
--------------------------------------------------------------------------------------------------------------------------------             


------------------------ALU oprandB updating--------------------------------------------------------------------------------------------
operand_B_to_ALU <=  Instruction(15 downto 0)   when instruction(20 downto 16)= "10001" and   instruction(20 ) = '1' and do=fetch  else---and rx,kk
                     data2_from_Reg            when instruction_to_IDU(20 downto 16)= "00001" and  instruction_to_IDU(20) = '0' and do=excution  ELSE----AND RX,RY
                     Instruction(15 downto 0)   when instruction(20 downto 16)= "10010" and   instruction(20 ) = '1' and do=fetch  else---OR rx,kk
                     data2_from_Reg            when instruction_to_IDU(20 downto 16)= "00010" and  instruction_to_IDU(20) = '0' and do=excution ELSE----or RX,RY
                     Instruction(15 downto 0)   when instruction(20 downto 16)= "10100" and   instruction(20 ) = '1' and do=fetch  else---XOR rx,kk
                     data2_from_Reg            when instruction_to_IDU(20 downto 16)= "00100" and  instruction_to_IDU(20) = '0' and do=excution  else----Xor RX,RY
                     Instruction(15 downto 0)   when instruction(20 downto 16)= "10011" and   instruction(20 ) = '1' and do=fetch  else---nor rx,kk
                     data2_from_Reg            when instruction_to_IDU(20 downto 16)= "00011" and  instruction_to_IDU(20) = '0' and do=excution else----nor RX,RY
                     Instruction(15 downto 0)   when instruction(20 downto 16)= "11011" and   instruction(20 ) = '1' and do=fetch  else---add rx,kk
                     data2_from_Reg            when instruction_to_IDU(20 downto 16)= "01011" and  instruction_to_IDU(20) = '0' and do=excution  ELSE----add RX,RY
                     Instruction(15 downto 0)   when instruction(20 downto 16)= "11100" and   instruction(20 ) = '1' and do=fetch  else---SUB rx,kk
                     data2_from_Reg            when instruction_to_IDU(20 downto 16)= "01100" and  instruction_to_IDU(20) = '0' and do=excution else----SUB RX,RY
                     Instruction(15 downto 0)   when instruction(19 downto 16)= "0101"  and do=fetch  else---SLL rx,kk
                     Instruction(15 downto 0)   when instruction(19 downto 16)= "0111"  and do=fetch  else---SLA rx,kk
                     Instruction(15 downto 0)   when instruction(19 downto 16)= "0110"  and do=fetch  else---SrL rx,kk
                     Instruction(15 downto 0)   when instruction(19 downto 16)= "1000"  and do=fetch  else---SrA rx,kk
                     Instruction(15 downto 0)   when instruction(19 downto 16)= "1001"  and do=fetch  else---rol rx,kk
                     Instruction(15 downto 0)   when instruction(19 downto 16)= "1010"  and do=fetch  ;---ror rx,kk
 --------------------------------------------------------------------------------------------------------------------------------------------                    

   

------------------------------resgister data -------------------------------------------------------------------------------------------------
 data_to_Reg      <=  instruction_to_IDU(15 downto 0)  when instruction_to_IDU(20 downto 16)="10000"and do =excution else --result_from_ALU;--data updating  .-load constant kk to Rx
                      data2_from_Reg           when instruction_to_IDU(20 downto 16)="00000"  else--load rx,ry
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "10001" else--add rx,kk
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "00001" ELSE---and rx,ry
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "10010" else--OR rx,kk 
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "00010" ELSE---or rx,ry
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "10011" else--nor rx,kk
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "00011" ELSE---nor rx,ry
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "10110" else--XOR rx,kk 
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "00110" else---Xor rx,ry
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "11011" else--ADD rx,kk 
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "01011" ELSE---ADD rx,ry
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "11100" else--SUB rx,kk 
                      result_from_ALU          when instruction_to_IDU(20 downto 16)= "01100" else---SUB rx,ry                       
                      result_from_ALU          when instruction_to_IDU(19 downto 16)= "0101"  ELSE--sll rx,kk 
                      result_from_ALU          when instruction_to_IDU(19 downto 16)= "0111"  else--slA rx,kk                        
                      result_from_ALU          when instruction_to_IDU(19 downto 16)= "0110"  ELSE--srl rx,kk 
                      result_from_ALU          when instruction_to_IDU(19 downto 16)= "1000"  else--sRA rx,kk                          
                      result_from_ALU          when instruction_to_IDU(19 downto 16)= "1001"  ELSE--rol rx,kk 
                      result_from_ALU          when instruction_to_IDU(19 downto 16)= "1010"  ;--ror rx,kk 
--                      input_port               when instruction_to_IDU(15 downto 12)= "0101"    ; ----imprX,Inport
--------------------------------------------------------------------------------------------------------------------------------
                      
   
--------------------------register address2 --------------------------------------------------------------------------------------------  
 addr_R2_to_Reg   <= Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)="00000"  else------load rx,ry   Ry address updating . 
                     Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)= "00001" else-----and rx,ry-  Ry address updating .    
                     Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)= "00010" ELSE-----or rx,ry-  Ry address updating . 
                     Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)= "00011" ELSE-----nor rx,ry-  Ry address updating .  
                     Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)= "00100" else-----Xor rx,ry-
                     Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)= "01011" ELSE-----ADD rx,ry-
                     Yaddress_from_IDU        when  instruction_to_IDU(20 downto 16)= "01100" ELSE-----SUB rx,ry-
                     Yaddress_from_IDU        when  instruction_to_IDU(19 downto 16)= "1100" ;---------SUB rx,ry-
-------------------------------------------------------------------------------------------------------------------------------------                   
  
----------------------register address1--------------------------------------------------------------------------------------------------                  
  addr_R1_to_Reg   <= Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "10001" else--and rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "00001" ELSE ---and rx,ry
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "10010" else--OR rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "00010" ELSE ---or rx,ry
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "10011" else--nOR rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "00011" ELSE ---nor rx,ry
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "10100" else--XOR rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "00100" else ---Xor rx,ry  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "11011" else--add rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "01011" ELSE ---ADD rx,ry                       
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "11100" else --add rxkk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "01100" ELSE ---ADD rx,ry  
                      Xaddress_from_IDU       when  instruction_to_IDU(19 downto 16)= "0101"  ELSE--SLL rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(19 downto 16)= "0111"  ELSE--SLA rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(19 downto 16)= "0110"  ELSE--SRL rx,k--  
                      Xaddress_from_IDU       when  instruction_to_IDU(19 downto 16)= "1000"  else--SRA rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(19 downto 16)= "1001"  ELSE--rol rx,kk--  
                      Xaddress_from_IDU       when  instruction_to_IDU(19 downto 16)= "1010"  else--ROR rx,kk--  
                     Xaddress_from_IDU       when  instruction_to_IDU(20 downto 16)= "11111" ;--EXP rx,kk--
-------------------------------------------------------------------------------------------------------------------------------

-----------------------------PC Pointer updating--------------------------------------------------------------------------------------------
PCpointer:process(clk)-------
begin	
           		  
  if   reset='1'   then---reset the program   
    Pointer<=(others=>'0');--default address
    oe_bar<='1';--------------reading a instruction enable
    do<=fetch;----------------to fetch a instruction
    stop<='0';----------------no stop excution
  elsif rising_edge(clk) then  ---------- program is on the fly, normally
            
   case do is ----------------two sate 
          when fetch => ----to fetch instruction              
			if address_counter_v = 122 then
			   Pointer <= stop_pointer;
               	elsif jump_from_idu='1'  then---to excute a jump------------------------
				          	            null;
				         else       
				          	         if stop='1' then--- to excute HALT
                                Pointer     <=  stop_pointer; ---stop pointer 
                            else        
                                stop_pointer<=  Pointer;  ---to kepp the pointer in case   a stop comes
                                Pointer     <=  address_counter_v;---normal operation
                            end if;
                             
                     address_counter_v<=address_counter_v+1;   ------normal  state  ,pointer  increases automatically                   
                   end if;
				         			
            
             do                 <=excution;---after fetch the instruction  and decoding,the next is to excute the instruction
             oe_bar             <='1';---enable to fetch
             WEN_to_Reg         <='1';----enable 
             instruction_to_IDU <=instruction;---to decode the IR 
             operation_to_ALU   <=operation_from_IDU;  ----to excute
              
   when excution =>    ----- excute a operation
  		  
------------------------Jump state--------------------------------------------------------------------------  		  
		 	if jump_from_idu='1' then--e a jump enable------------------------
				         	           	     
           if conditional_from_IDU='1' then ---jump unconditional------------------------
                    Pointer           <= JumpAddress_from_IDU+1; --- jump nconditional
				          	 address_counter_v <= JumpAddress_from_IDU+2; --address updating                                         
                                         
           
 elsif zero_from_ALU='1'AND ConditionFlag_from_IDU='0'  then---JZ
                   Pointer            <= JumpAddress_from_IDU+1;  
				           address_counter_v  <= JumpAddress_from_IDU+2;            
				    elsif  carry_from_ALU='1'AND ConditionFlag_from_IDU='1' then---JC
                   Pointer            <= JumpAddress_from_IDU+1;  
				           address_counter_v  <= JumpAddress_from_IDU+2;
			      end if;
		  end if;
-----------------------------------------------------------------------------------------------------------
                     
			    oe_bar <= '0'; ----do noe read a instruction
          do     <= fetch;-----to fetch instruction
          WEN_to_Reg<='0';----disable      
           
           

       when others=>
            null;
   end case;   
-----------------output--------------------------------------------------------------------------------           
--      if Exp_from_IDU='1' then   ----ouput data to a specified port         
--                 port_ID    <=  PortId_form_ALU  ; ---alu out ID 
--                 IF  instruction_to_IDU(16 downto 12)= "10111" THEN ---OUTPUT FROM Register TO PORT
--                 output_port<=  data1_from_Reg ;---  alu output data EXP Rx,kk     
--               ELSE
--                  output_port<=  outputport_form_ALU ;---  alu output data EXP Rx,kk     
--                END IF;        
--             else
--                 port_ID    <=  (others=>'X'); ---alu out ID  ,default output
--                 output_port<=  (others=>'X');-----No output data  ,default output
--      end if;
----------------------------------------------------------------------------------------------------------          
            

   
end if;---end reset if

	   --if halt_form_IDU='1' then---HALT
--           		  stop<='1'; ---to stop
--           		  pointer<=stop_pointer;
--           		  end if;
           		  
           		  
           		  
end process PCpointer;  

address <=     JumpAddress_from_IDU when    jump_from_idu='1'else   ----jump address to program pointer       
               stop_pointer  when   halt_form_IDU='1' else  ------------stop pointer----
               Pointer  ; --normal  --  

------------------------instatiate a Register BAnk--------------------------------------------------------------
u1: Register_Bank port map (-------instatiate a Register BAnk
                             clk                    => clk,      ---------clk mapping
                             reset                  => reset ,------------reset signal
                             write_enable           => WEN_to_Reg,--------write enable
                             data_in                => data_to_Reg,-------data
                             ADDRESS_w              => addr_W_to_Reg, ----data address
                             address_R1             => addr_R1_to_Reg,----data1 address
                             address_R2             => addr_R2_to_Reg,----data2 address
                             data_out1              => data1_from_Reg,----data1 output
                             data_out2              => data2_from_Reg-----data2 output
                             );                             
 ---------------------------------------------------------------------------------------------------------------                            
                             
-------------------------------Instantiate a IDU-------------------------------------------------------------------                             
u2:       IDU   port map     ( ---componentIDU ports mapping   (Instruction Decode Unit) declaration

                             Instruction            => instruction_to_IDU          ,-------input instruction to  be decoded
                            opcode              => operation_from_IDU          ,-------4bit opcode for ALU(IR(15 DOWNTO 12))
                             Shift_Rotate_Operation => ShiftRotateTimes_from_IDU   ,---a number between 0 to 7 indicating "how amny times"
                             Operand_Selection      => OperationSelection_from_IDU ,-- 0 means  operand2,=Ry,1means operand2<=kk
                             X_address              => Xaddress_from_IDU      ,----Rx ADDRESS 
                             Y_address              => yaddress_from_IDU      , ----Ry address
                             Conditional            => conditional_from_IDU   ,---indicating the JUMP is conditioanl or not 
                             Jump                   => jump_from_idu          ,---junp sign
									           Jump_address           => JumpAddress_from_IDU   ,---indicaiitng the line of jump
                             Condition_flag         => ConditionFlag_from_IDU ,----condition for jump , 0 means  JZ ,and 1 mean s JC
                             Exp                    => Exp_from_IDU           ----indicating whether the instruction is export or not
--                             Halt                   => halt_form_IDU         ----1 means stop the excution
                              );
-----------------------------------------------------------------------------------------------------------------                
                
--------------------------------Instantiate a ALU---------------------------------------------------------------------- 
u3: ALU port map ---component  ALU (Instruction Decode Unit) declaration
                         (
                           clk                    => clk,
                           opcode               =>  operation_from_IDU         , --operation_to_ALU         ,---- 4 bit opceode from IDU
                           shift_rotate_operation  =>  ShiftRotateTimes_from_IDU  ,--how many times
                           oprand_a               =>  operand_A_to_ALU           ,---
                           oprand_b               =>  operand_B_to_ALU           ,--first an dsecond oprands
                           result                  =>  result_from_ALU            ,--result
                           zero                    =>  zero_from_ALU              ,
                           carry                   =>  carry_from_ALU               --falg zero and carry
                         );
 ---------------------------------------------------------------------------------------------------------------                          
                           
end behavior;




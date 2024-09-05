----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.11.2023 14:51:18
-- Design Name: 
-- Module Name: TB_NMC - final_countdown
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
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_NMC is
--  Port ( );
end TB_NMC;

architecture final_countdown of TB_NMC is

	constant FILE_OUT_0 	: string := "IZH_V.txt";
	constant FILE_OUT_1 	: string := "IZH_U.txt";
	file fptr_out_0		: text;
	file fptr_out_1		: text;
	
    component NMC is
        Port ( 
                NMC_CLK                     : in   std_logic;  -- SYNCHRONOUS SOFT RESET
                NMC_STATE_RST               : in   std_logic;  -- RESETS THE NMC STATES, FP16MAC and REGISTERS
                NMC_HARD_RST                : in   std_logic;  -- SYNCHRONOUS HARD RESET (RESETS THE WHOLE IP! INCLUDING MEMORY)
                --  IP CONTROLS
                NMC_COLD_START              : in   std_logic; -- START PROGRAM FLOW REGARDLESS OF THE STATE OF THE INPUT CURRENT
                PARTIAL_CURRENT_RDY         : in   std_logic;
                -- NMC AXI4LITE REGISTERS
                NMC_XNEVER_REGION_BASEADDR  : in   std_logic_vector(9 downto 0);
                NMC_XNEVER_REGION_HIGHADDR  : in   std_logic_vector(9 downto 0);
                -- FROM DISTRIBUTOR
                NMODEL_LAST_SPIKE_TIME      : in   STD_LOGIC_VECTOR(7  DOWNTO 0); 
                NMODEL_SYN_QFACTOR          : in   STD_LOGIC_VECTOR(15 DOWNTO 0); 
                NMODEL_PF_LOW_ADDR          : in   STD_LOGIC_VECTOR(9  DOWNTO 0); 
                NMODEL_NPARAM_DATA          : in   STD_LOGIC_VECTOR(15 DOWNTO 0);
                NMODEL_NPARAM_ADDR          : in   STD_LOGIC_VECTOR(9  DOWNTO 0);
                NMODEL_REFRACTORY_DUR       : in   std_logic_vector(7  downto 0);
                NMODEL_PROG_MEM_PORTA_EN    : in   STD_LOGIC;
                NMODEL_PROG_MEM_PORTA_WEN   : in   STD_LOGIC;
                -- FROM HYPERCOLUMNS
                NMC_NMODEL_PSUM_IN          : in   std_logic_vector(15 downto 0);
                -- TO AXON HANDLER
                NMC_NMODEL_SPIKE_OUT        : out  std_logic; 
                -- TO REDISTRIBUTOR
                R_NNMODEL_NEW_SPIKE_TIME    : out  std_logic_vector(7  downto 0);
                R_NMODEL_NPARAM_DATAOUT     : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
                R_NMODEL_NPARAM_ADDROUT     : OUT  STD_LOGIC_VECTOR(9  DOWNTO 0);
                R_NMODEL_REFRACTORY_DUR     : OUT  std_logic_vector(7  downto 0);
                REDIST_NMODEL_PORTB_TKOVER  : in   std_logic;
                REDIST_NMODEL_DADDR         : in   std_logic_vector(9 downto 0);
                -- IP STATUS FLAGS
                NMC_NMODEL_FINISHED         : out  std_logic;
                -- ERROR FLAGS
                NMC_MATH_ERROR              : out  std_logic;
                NMC_MEMORY_VIOLATION        : out  std_logic
        );
    end component NMC;

    signal NMC_CLK                     :  std_logic := '1';  -- SYNCHRONOUS SOFT RESET
    signal NMC_STATE_RST               :  std_logic := '0';  -- RESETS THE NMC STATES, FP16MAC and REGISTERS
    signal NMC_HARD_RST                :  std_logic := '0';  -- SYNCHRONOUS HARD RESET (RESETS THE WHOLE IP! INCLUDING MEMORY)
    --  IP CONTROLS
    signal NMC_COLD_START              :  std_logic := '0'; -- START PROGRAM FLOW REGARDLESS OF THE STATE OF THE INPUT CURRENT
    signal PARTIAL_CURRENT_RDY         :  std_logic := '0';
    -- NMC AXI4LITE REGISTERS
    signal NMC_XNEVER_REGION_BASEADDR  :  std_logic_vector(9 downto 0) := (others=>'0');
    signal NMC_XNEVER_REGION_HIGHADDR  :  std_logic_vector(9 downto 0) := (others=>'0');
    -- FROM DISTRIBUTOR
    signal NMODEL_LAST_SPIKE_TIME      :  STD_LOGIC_VECTOR(7  DOWNTO 0) := (others=>'0'); 
    signal NMODEL_SYN_QFACTOR          :  STD_LOGIC_VECTOR(15 DOWNTO 0) := (others=>'0');     
    signal NMODEL_PF_LOW_ADDR          :  STD_LOGIC_VECTOR(9  DOWNTO 0) := (others=>'0'); 
    signal NMODEL_NPARAM_DATA          :  STD_LOGIC_VECTOR(15 DOWNTO 0) := (others=>'0');
    signal NMODEL_NPARAM_ADDR          :  STD_LOGIC_VECTOR(9  DOWNTO 0) := (others=>'0');
    signal NMODEL_REFRACTORY_DUR       :  std_logic_vector(7  downto 0) := (others=>'0');
    signal NMODEL_PROG_MEM_PORTA_EN    :  STD_LOGIC := '0';
    signal NMODEL_PROG_MEM_PORTA_WEN   :  STD_LOGIC := '0';
    -- FROM HYPERCOLUMNS
    signal NMC_NMODEL_PSUM_IN          :  std_logic_vector(15 downto 0) := (others=>'0');
    -- TO AXON HANDLER
    signal NMC_NMODEL_SPIKE_OUT        :  std_logic := '0'; 
    -- TO REDISTRIBUTOR
    signal R_NNMODEL_NEW_SPIKE_TIME    :  std_logic_vector(7  downto 0) := (others=>'0');
    signal R_NMODEL_NPARAM_DATAOUT     :  STD_LOGIC_VECTOR(15 DOWNTO 0) := (others=>'0');
    signal R_NMODEL_NPARAM_ADDROUT     :  STD_LOGIC_VECTOR(9  DOWNTO 0) := (others=>'0');
    signal R_NMODEL_REFRACTORY_DUR     :  std_logic_vector(7  downto 0) := (others=>'0');
    signal REDIST_NMODEL_PORTB_TKOVER  :  std_logic := '0';
    signal REDIST_NMODEL_DADDR         :  std_logic_vector(9 downto 0) := (others=>'0');
    -- IP STATUS FLAGS
    signal NMC_NMODEL_FINISHED         : std_logic := '0';
    -- ERROR FLAGS
    signal NMC_MATH_ERROR              : std_logic := '0';
    signal NMC_MEMORY_VIOLATION         : std_logic := '0';

    constant CLKPERIOD                 : time := 8 ns;

    signal FP16_MEM_VOLTAGE            : std_logic_vector(15 downto 0) := (others=>'0');
    signal FP16_U                      : std_logic_vector(15 downto 0) := (others=>'0');
    signal LAST_SPIKE_TIME             : std_logic_vector(7 downto 0) := (others=>'0');
    signal REFRACTORY_PERIOD           : std_logic_vector(7 downto 0) := (others=>'0');
    
    signal SAMPLECOUNTER               : integer range 0 to 65536 := 0;

begin

    NMC_CLK <= not NMC_CLK after CLKPERIOD/2;

    NUT : NMC
        Port Map( 
                NMC_CLK                     => NMC_CLK                    ,
                NMC_STATE_RST               => NMC_STATE_RST              ,
                NMC_HARD_RST                => NMC_HARD_RST               ,
                --  IP CONTROLS
                NMC_COLD_START              => NMC_COLD_START             ,
                PARTIAL_CURRENT_RDY         => PARTIAL_CURRENT_RDY        ,
                -- NMC AXI4LITE REGISTERS
                NMC_XNEVER_REGION_BASEADDR  => NMC_XNEVER_REGION_BASEADDR ,
                NMC_XNEVER_REGION_HIGHADDR  => NMC_XNEVER_REGION_HIGHADDR ,
                -- FROM DISTRIBUTOR
                NMODEL_LAST_SPIKE_TIME      => NMODEL_LAST_SPIKE_TIME     , 
                NMODEL_SYN_QFACTOR          => NMODEL_SYN_QFACTOR         , 
                NMODEL_PF_LOW_ADDR          => NMODEL_PF_LOW_ADDR         , 
                NMODEL_NPARAM_DATA          => NMODEL_NPARAM_DATA         ,
                NMODEL_NPARAM_ADDR          => NMODEL_NPARAM_ADDR         ,
                NMODEL_REFRACTORY_DUR       => NMODEL_REFRACTORY_DUR      ,
                NMODEL_PROG_MEM_PORTA_EN    => NMODEL_PROG_MEM_PORTA_EN   ,
                NMODEL_PROG_MEM_PORTA_WEN   => NMODEL_PROG_MEM_PORTA_WEN  ,
                -- FROM HYPERCOLUMNS
                NMC_NMODEL_PSUM_IN          => NMC_NMODEL_PSUM_IN         ,
                -- TO AXON HANDLER
                NMC_NMODEL_SPIKE_OUT        => NMC_NMODEL_SPIKE_OUT       ,
                -- TO REDISTRIBUTOR
                R_NNMODEL_NEW_SPIKE_TIME    => R_NNMODEL_NEW_SPIKE_TIME   ,
                R_NMODEL_NPARAM_DATAOUT     => R_NMODEL_NPARAM_DATAOUT    ,
                R_NMODEL_NPARAM_ADDROUT     => R_NMODEL_NPARAM_ADDROUT    ,
                R_NMODEL_REFRACTORY_DUR     => R_NMODEL_REFRACTORY_DUR    ,
                REDIST_NMODEL_PORTB_TKOVER  => REDIST_NMODEL_PORTB_TKOVER ,
                REDIST_NMODEL_DADDR         => REDIST_NMODEL_DADDR        , 
                -- IP STATUS FLAGS
                NMC_NMODEL_FINISHED         => NMC_NMODEL_FINISHED        ,
                -- ERROR FLAGS
                NMC_MATH_ERROR              => NMC_MATH_ERROR             ,
                NMC_MEMORY_VIOLATION        => NMC_MEMORY_VIOLATION        
        );


    process 
    

		variable fline_out 	: line;
		variable fstat_out  : file_open_status;
		--variable arg1		: bit_vector(15 downto 0);
		--variable arg2		: bit_vector(15 downto 0);
		variable arg1		: integer range 0 to 65535;
		variable arg2		: integer range 0 to 65535;
    
    begin
    
		file_open(fstat_out, fptr_out_0, FILE_OUT_0, write_mode);
		file_open(fstat_out, fptr_out_1, FILE_OUT_1, write_mode);

    wait for 100*CLKPERIOD;

    NMC_STATE_RST <= '1';
    wait for 5*CLKPERIOD;
    NMC_STATE_RST <= '0';

    NMC_XNEVER_REGION_BASEADDR <= std_logic_vector(to_unsigned(768,NMC_XNEVER_REGION_BASEADDR'length));
    NMC_XNEVER_REGION_HIGHADDR <= std_logic_vector(to_unsigned(1023,NMC_XNEVER_REGION_HIGHADDR'length));

---------------------------------------------------------------------------------------
--
--    Leaky Integrate and Fire Neuron (Without Refractory, Constant Input Current)
--    
--    Kernel -->   V' = (R*I-V)/t_m
--
--    Initial Membrane Voltage --> V       = 70 mV
--    Membrane Resistance      --> R       = 1 mOhm
--    Membrane Time Constant   --> t_m     = 10 ms
--    Threshold Voltage        --> V_th    = 20 mV
--    Reset Voltage            --> V_reset = 60 mV
--    Pre Synaptic Current     --> I       = 0.1 uA
--    Timestep (h)             --> h       = 0.01
--     
--    Discrete Time Kernel (method = Euler)      
--
--    v[n+1] = R*I*h*r_t_m - V[n]*r_t_m*h + v[n]
--
--    LiF Assembly Code (Without Pre-Processing)
--
--    getacc,x1    (Get Synaptic Input Current I)
--    clracc
--    lw,x2,44     (Get V)
--    lw,x3,45     (Get R)
--    lw,x4,46     (Get h)
--    lw,x5,57     (Get r_t_m)
--    fmac,x5,x4   (Calculate r_t_m*h )
--    getacc,x7    (Get r_t_m*h)
--    clracc
--    fmac x7,x2   (Calculate V[n]*r_t_m*h)
--    smac x2,x0   (Calculate V[n]*r_t_m*h - V[n])
--    getacc,x6    (Get V[n]*r_t_m*h - V[n])
--    clracc
--    fmac x7,x3   (Calculate R*r_t_m*h)
--    getacc,x7    (Get R*r_t_m*h)
--    clracc       
--    fmac x7,x1   (Calculate I*R*r_t_m*h)
--    smac x0,x6   (Calculate I*R*r_t_m*h - (V[n]*r_t_m*h - V[n]) )
--    getacc,x7    (Get I*R*r_t_m*h - (V[n]*r_t_m*h - V[n]) )
--    lw,x4,66     (Get V_th)
--    comp,x7,x4   (Compare with V_th)
--    bil,3
--    sw x7,44        
--    return
--    spk
--    lw x7,79    (Get V_reset)
--    sw x7,44
--    return
----------------------------------------------------------------------------------------

    -- IZH Assembly Code Loading

    NMODEL_PROG_MEM_PORTA_EN  <= '1';
    NMODEL_PROG_MEM_PORTA_WEN <= '1';

    NMODEL_NPARAM_DATA <= "0011001000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(542,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(543,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;   
    NMODEL_NPARAM_DATA <= "0001000000110111"; -- FP16 1.0 LOAD BURAYA
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(544,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001010000101100";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(545,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001011000101101";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(546,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001100000101110";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(547,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001101000101111";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(548,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000010000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(549,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000001011";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(550,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0101000000100011";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(551,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000101011";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(552,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011110000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(553,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(554,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000011010";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(555,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(556,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(557,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001101000110000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(558,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000111101";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(559,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000110000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(560,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011110000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(561,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(562,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001101000110001";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(563,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000111101";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(564,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(565,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(566,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000111010";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(567,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000110000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(568,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011110000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(569,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(570,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001111000110101";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(571,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0111000000110111";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(572,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "1010000000011010";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(573,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0010110000101100";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(574,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001101000110011";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(575,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001110000110100";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(576,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000101110";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(577,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(578,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(579,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000010011";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(580,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011001000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(581,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(582,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000001111";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(583,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000100000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(584,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011001000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(585,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(586,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000011101";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(587,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(588,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(589,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000111100";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(590,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(591,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(592,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000000001";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(593,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0101000000000111";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(594,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(595,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0110000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(596,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0010111000101110";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(597,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "1101000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(598,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "1011000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(599,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001111000110010";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(600,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0010111000101100";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(601,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000000100";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(602,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0001010000110110";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(603,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0100000000010000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(604,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0011111000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(605,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "0010111000101110";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(606,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= "1101000000000000";
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(607,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD;
    NMODEL_NPARAM_DATA <= X"2E66";  -- h
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+45,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"5860";  -- 140
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+47,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"251E";  -- a
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+51,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"4F80";  -- threshold
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+53,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"3266";  -- b
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+52,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"4000";  -- d
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+54,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"3C00";  -- FP16 1.0
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+55,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"D240";  -- c
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+50,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"291E";  -- 0.04
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+49,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 
    NMODEL_NPARAM_DATA <= X"4500";  -- 5
    NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+48,NMODEL_NPARAM_ADDR'length)); 
    wait for CLKPERIOD; 

    NMODEL_PROG_MEM_PORTA_EN  <= '0';
    NMODEL_PROG_MEM_PORTA_WEN <= '0';

    wait for 20*CLKPERIOD;

    LAST_SPIKE_TIME  <= X"00";
    REFRACTORY_PERIOD <= X"00";
    
    FP16_MEM_VOLTAGE <= std_logic_vector(to_unsigned(0 ,16));
    FP16_U           <= std_logic_vector(to_unsigned(0 ,16));

    wait for CLKPERIOD;

        for ii in 0 to 1023 loop

            NMODEL_PROG_MEM_PORTA_EN  <= '1';
            NMODEL_PROG_MEM_PORTA_WEN <= '1';

            -- NPARAM LOAD
            NMODEL_NPARAM_DATA <= FP16_MEM_VOLTAGE;  -- V
            NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+44,NMODEL_NPARAM_ADDR'length)); 
			write(fline_out,to_integer(unsigned(FP16_MEM_VOLTAGE)));
			writeline(fptr_out_0,fline_out);
            wait for 3*CLKPERIOD; 
            NMODEL_NPARAM_DATA <= FP16_U;  -- u
            NMODEL_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+46,NMODEL_NPARAM_ADDR'length)); 
            write(fline_out,to_integer(unsigned(FP16_U)));
			writeline(fptr_out_1,fline_out);
            wait for 3*CLKPERIOD; 

            NMODEL_PROG_MEM_PORTA_EN  <= '0';
            NMODEL_PROG_MEM_PORTA_WEN <= '0';

            NMODEL_SYN_QFACTOR<= X"211E"; -- FP16 0.01
            wait for CLKPERIOD; 
            NMODEL_LAST_SPIKE_TIME <= LAST_SPIKE_TIME;
            wait for CLKPERIOD; 
            NMODEL_PF_LOW_ADDR <= std_logic_vector(to_unsigned(542,NMODEL_PF_LOW_ADDR'length));
            wait for CLKPERIOD; 
            NMODEL_REFRACTORY_DUR <= REFRACTORY_PERIOD;
            wait for CLKPERIOD; 

            NMC_NMODEL_PSUM_IN <= std_logic_vector(to_signed(1518,NMC_NMODEL_PSUM_IN'length));
            PARTIAL_CURRENT_RDY <= '1';
            wait for CLKPERIOD;
            PARTIAL_CURRENT_RDY <= '0';
            wait for 8*CLKPERIOD;

            NMC_COLD_START <= '1';
            wait for CLKPERIOD;
            NMC_COLD_START <= '0';
            wait until NMC_NMODEL_FINISHED = '1';
            wait for CLKPERIOD;

            REDIST_NMODEL_PORTB_TKOVER <= '1';
            wait for CLKPERIOD;
            REDIST_NMODEL_DADDR <= std_logic_vector(to_unsigned(768+44,NMODEL_NPARAM_ADDR'length));
            wait for 5*CLKPERIOD;
            FP16_MEM_VOLTAGE <= R_NMODEL_NPARAM_DATAOUT;
            wait for 5*CLKPERIOD;
            REDIST_NMODEL_DADDR <= std_logic_vector(to_unsigned(768+46,NMODEL_NPARAM_ADDR'length)); 
            wait for 5*CLKPERIOD;
            FP16_U <= R_NMODEL_NPARAM_DATAOUT;  -- u
            LAST_SPIKE_TIME   <= R_NNMODEL_NEW_SPIKE_TIME;
            REFRACTORY_PERIOD <= R_NMODEL_REFRACTORY_DUR;
            wait for 20*CLKPERIOD;
            NMC_STATE_RST <= '1';
            wait for 5*CLKPERIOD;
            REDIST_NMODEL_PORTB_TKOVER <= '0';
            NMC_STATE_RST <= '0';
            wait for 5*CLKPERIOD;
            SAMPLECOUNTER <= SAMPLECOUNTER + 1;


        end loop;


    assert false report "Test: OK" severity failure;

    end process;

end final_countdown;

--IZH = '''
--getacc,x1  (LOAD I to x1)
--clracc     (CLEAR ACC)
--lw,x2,44   (LOAD v)
--lw,x3,45   (LOAD h)
--lw,x4,46   (LOAD u)
--lw,x5,47   (LOAD 140)
--fmac,x2,x0 (ACC <= v)
--fmac,x1,x3 (ACC <= v + I*h)
--smac,x4,x3 (ACC <= v + I*h - h*u)
--fmac,x5,x3 (ACC <= 140*h - h*u + I*h + v )
--getacc,x6  ( x6 = 140*h - h*u + I*h + v )
--clracc
--fmac,x3,x2 (ACC <= h*v )
--getacc,x7  ( x7 = h*v )
--clracc
--lw,x5,48   (LOAD 5)
--fmac,x7,x5 (ACC <= 5*h*v )
--fmac,x6,x0 (ACC <= 5*h*v + 140*h - h*u + I*h + v )
--getacc,x6  ( x6 = 5*h*v + 140*h - h*u + I*h + v )
--clracc
--lw,x5,49   (LOAD 0.04)
--fmac,x7,x5 (ACC <= 0.04*h*v )
--getacc,x7  ( x7 = 0.04*h*v )
--clracc
--fmac,x7,x2 (ACC <= 0.04*h*v*v )
--fmac,x6,x0 (ACC <= 0.04*h*v*v + 5*h*v + 140*h - h*u + I*h + v)
--getacc,x6  ( x6 = 0.04*h*v*v + 5*h*v + 140*h - h*u + I*h + v )
--clracc
--lw,x7,53   (LOAD Vth)
--comp,x6,x7 (Vnew ? Vth)
--big,26
--sw,x6,44   (SAVE Vnew to 44)
--lw,x5,51   (LOAD a)
--lw,x6,52   (LOAD b)
--fmac,x5,x6 (ACC <= a*b )
--getacc,x7  (x7 = a*b )
--clracc
--fmac,x2,x3 (ACC <= v*h )
--getacc,x1  (x1 = v*h )
--clracc
--fmac,x1,x7 (ACC <= v*h*a*b )
--fmac,x4,x0 (ACC <= v*h*a*b + u)
--getacc,x1  (x1 =  v*h*a*b + u )
--clracc
--fmac,x3,x5 (ACC <= h*a)
--getacc,x7  (x7 =  h*a )
--clracc
--fmac,x7,x4 (ACC <= h*a*u)
--getacc,x7  (x7 =  h*a*u )
--clracc
--fmac,x0,x1 (ACC <= v*h*a*b + u)
--smac,x0,x7 (ACC <= v*h*a*b + u - h*a*u  )
--getacc,x7  (x7  = v*h*a*b + u - h*a*u  )
--clracc
--sw,x7,46   (SAVE U_new)
--return
--spk
--lw,x7,50   (LOAD c)
--sw,x7,44   (Save c as V_new)
--fmac,x0,x4 (ACC <= u)
--lw,x2,54   (LOAD d)
--fmac,x2,x0 (ACC <= u + d)
--getacc,x7  (x7 = u + d) 
--sw,x7,46   (Save u + d as U_new)
--return
--'''

--a=51
--b=52
--d=54
--c=50
--0.04=49
--5=48
--v=44
--h=45
--u=46
--140=47
--vth=53
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.processor_primitives.all;
use work.processor_utils.all;
use work.crossbar_utils.all;

entity TB_SPIKE_PROCESSOR is
    Generic (
            CROSSBAR_ROW_WIDTH : integer := 32;
            CROSSBAR_COL_WIDTH : integer := 32;
            SYNAPSE_MEM_DEPTH  : integer := 2048;
            NEURAL_MEM_DEPTH   : integer := 1024
            );
end TB_SPIKE_PROCESSOR;

architecture money_for_nothing of TB_SPIKE_PROCESSOR is

component SPIKE_PROCESSOR is
    Generic (
            CROSSBAR_ROW_WIDTH : integer := 24;
            CROSSBAR_COL_WIDTH : integer := 24;
            SYNAPSE_MEM_DEPTH  : integer := 2048;
            NEURAL_MEM_DEPTH   : integer := 1024
            );
    Port ( 
            SP_CLOCK                    : in  std_logic;
            PARAMETER_MEM_RDCLK         : in  std_logic;
            SP_RESET                    : in  std_logic;
            TIMESTEP_STARTED            : in  std_logic;
            TIMESTEP_COMPLETED          : out std_logic;
            SPIKEVECTOR_IN              : in  std_logic_vector(CROSSBAR_ROW_WIDTH-1 downto 0); 
            SPIKEVECTOR_VLD_IN          : in  std_logic;                         
            READ_MAIN_SPIKE_BUFFER      : out std_logic;
            READ_AUXILLARY_SPIKE_BUFFER : out std_logic;
            EVENT_ACCEPT                : out std_logic;
            SYNAPSE_ROUTE               : in  std_logic_vector(0 to CROSSBAR_COL_WIDTH-1); -- 00: Recycle, 01: In, 10: Out
            SYNAPTIC_MEM_DIN            : in  SYNAPTICMEMDATA(0 to CROSSBAR_COL_WIDTH-1);
            SYNAPTIC_MEM_DADDR          : in  SYNAPTICMEMADDR(0 to CROSSBAR_COL_WIDTH-1)(clogb2(SYNAPSE_MEM_DEPTH)-1 downto 0);
            SYNAPTIC_MEM_EN             : in  std_logic_vector(0 to CROSSBAR_COL_WIDTH-1);
            SYNAPTIC_MEM_WREN           : in  std_logic_vector(0 to CROSSBAR_COL_WIDTH-1);
            SYNAPTIC_MEM_DOUT           : out SYNAPTICMEMDATA(0 to CROSSBAR_COL_WIDTH-1);
            NMC_XNEVER_BASE             : in  std_logic_vector(9 downto 0);
            NMC_XNEVER_HIGH             : in  std_logic_vector(9 downto 0);
            NMC_PMODE_SWITCH            : in  STD_LOGIC_VECTOR(0 to CROSSBAR_COL_WIDTH-1);  -- 00 : NMC Memory ports are tied to Neural Memory Ports, 01 : NMC Memory External Access
            NMC_NPARAM_DATA             : in  STD_LOGIC_VECTOR(15 DOWNTO 0);
            NMC_NPARAM_ADDR             : in  STD_LOGIC_VECTOR(9  DOWNTO 0);
            NMC_PROG_MEM_PORTA_EN       : in  STD_LOGIC_VECTOR(0 to CROSSBAR_COL_WIDTH-1);
            NMC_PROG_MEM_PORTA_WEN      : in  STD_LOGIC_VECTOR(0 to CROSSBAR_COL_WIDTH-1);
            NMC_SPIKE_OUT               : out std_logic_vector(0 to CROSSBAR_COL_WIDTH-1 );
            NMC_SPIKE_OUT_VLD           : out std_logic_vector(0 to CROSSBAR_COL_WIDTH-1 );
            NMC_WR_AUX_BUFFER           : out std_logic;
            NMC_WR_OUT_BUFFER           : out std_logic;
            LEARN_LUT_DIN               : in  std_logic_vector(7 downto 0);
            LEARN_LUT_ADDR              : in  std_logic_vector(7 downto 0);
            LEARN_LUT_EN                : in  std_logic;
            PARAM_MEM_DIN               : in  PARAMMEMDATA(0 to CROSSBAR_COL_WIDTH-1);
            PARAM_MEM_DADDR             : in  PARAMMEMADDR(0 to CROSSBAR_COL_WIDTH-1)(clogb2(NEURAL_MEM_DEPTH)-1 downto 0);
            PARAM_MEM_EN                : in  std_logic_vector(0 to CROSSBAR_COL_WIDTH-1); 
            PARAM_MEM_WREN              : in  std_logic_vector(0 to CROSSBAR_COL_WIDTH-1); 
            PARAM_MEM_DOUT              : out PARAMMEMDATA(0 to CROSSBAR_COL_WIDTH-1);
            NMC_MATH_ERROR_VEC          : out std_logic_vector(0 to CROSSBAR_COL_WIDTH-1); 
            NMC_MEM_VIOLATION_VEC       : out std_logic_vector(0 to CROSSBAR_COL_WIDTH-1)      
          );
end component SPIKE_PROCESSOR;

            signal SP_CLOCK                    : std_logic := '1';
            signal PARAMETER_MEM_RDCLK         : std_logic := '1';
            signal SP_RESET                    : std_logic := '0';
            signal TIMESTEP_STARTED            : std_logic := '0';
            signal TIMESTEP_COMPLETED          : std_logic;
            signal SPIKEVECTOR_IN              : std_logic_vector(CROSSBAR_ROW_WIDTH-1 downto 0) := (others=>'0'); 
            signal SPIKEVECTOR_VLD_IN          : std_logic := '0';                         
            signal READ_MAIN_SPIKE_BUFFER      : std_logic;
            signal READ_AUXILLARY_SPIKE_BUFFER : std_logic;
            signal EVENT_ACCEPT                : std_logic;
            signal SYNAPSE_ROUTE               : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0'); -- 0: Recycle, 1: In/Out
            signal SYNAPTIC_MEM_DIN            : SYNAPTICMEMDATA(0 to CROSSBAR_COL_WIDTH-1) := (others=>(others=>'0'));
            signal SYNAPTIC_MEM_DADDR          : SYNAPTICMEMADDR(0 to CROSSBAR_COL_WIDTH-1)(clogb2(SYNAPSE_MEM_DEPTH)-1 downto 0) := (others=>(others=>'0'));
            signal SYNAPTIC_MEM_EN             : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0');
            signal SYNAPTIC_MEM_WREN           : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0');
            signal SYNAPTIC_MEM_DOUT           : SYNAPTICMEMDATA(0 to CROSSBAR_COL_WIDTH-1);
            signal NMC_XNEVER_BASE             : std_logic_vector(9 downto 0) := (others=>'0');
            signal NMC_XNEVER_HIGH             : std_logic_vector(9 downto 0) := (others=>'0');
            signal NMC_PMODE_SWITCH            : STD_LOGIC_VECTOR(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0');  -- 0 : NMC Memory ports are tied to Neural Memory Ports, 1 : NMC Memory External Access
            signal NMC_NPARAM_DATA             : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others=>'0');
            signal NMC_NPARAM_ADDR             : STD_LOGIC_VECTOR(9  DOWNTO 0) := (others=>'0');
            signal NMC_PROG_MEM_PORTA_EN       : STD_LOGIC_VECTOR(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0');
            signal NMC_PROG_MEM_PORTA_WEN      : STD_LOGIC_VECTOR(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0');
            signal NMC_SPIKE_OUT               : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1 );
            signal NMC_SPIKE_OUT_VLD           : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1 );
            signal NMC_WR_AUX_BUFFER           : std_logic;
            signal NMC_WR_OUT_BUFFER           : std_logic;
            signal LEARN_LUT_DIN               : std_logic_vector(7 downto 0) := (others=>'0');
            signal LEARN_LUT_ADDR              : std_logic_vector(7 downto 0) := (others=>'0');
            signal LEARN_LUT_EN                : std_logic := '0';
            signal PARAM_MEM_DIN               : PARAMMEMDATA(0 to CROSSBAR_COL_WIDTH-1) := (others=>(others=>'0'));
            signal PARAM_MEM_DADDR             : PARAMMEMADDR(0 to CROSSBAR_COL_WIDTH-1)(clogb2(NEURAL_MEM_DEPTH)-1 downto 0) := (others=>(others=>'0'));
            signal PARAM_MEM_EN                : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0'); 
            signal PARAM_MEM_WREN              : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1) := (others=>'0'); 
            signal PARAM_MEM_DOUT              : PARAMMEMDATA(0 to CROSSBAR_COL_WIDTH-1);
            signal NMC_MATH_ERROR_VEC          : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1); 
            signal NMC_MEM_VIOLATION_VEC       : std_logic_vector(0 to CROSSBAR_COL_WIDTH-1);
            
            constant CLKPERIOD                 : time := 10 ns;
            
            type SIMFLAGS is (RESET_PROC,LEARNING_TABLE_PASS,SYNAPSE_PASS,NEURON_PARAM_PASS,GLOBAL_TIMESTEP,GLOBAL_TIMESTEP_UPDATE,REWIND);
            signal SIMULATION_FLAG : SIMFLAGS;
            
            constant NETWORK_LAYER_COUNT : integer := 4;
            
            type NETLAYERS is array(natural range <>) of integer;
            constant FF_TEST_NET_SYNAPSES : NETLAYERS(0 to NETWORK_LAYER_COUNT-1) := (256,128,64,32);
            constant FF_TEST_NET_NEURONS : NETLAYERS(0 to NETWORK_LAYER_COUNT-1) := (128,64,32,16);
            constant FF_TEST_NET_ADDR_INC : NETLAYERS(0 to NETWORK_LAYER_COUNT-1) := (0,32,48,56);
            
            constant TEST_NET_INPUT_WIDTH :integer :=  FF_TEST_NET_SYNAPSES(0);

            constant TEST_NET_OUTPUT_WIDTH :integer :=  FF_TEST_NET_NEURONS(NETWORK_LAYER_COUNT-1);
            
            signal ADDRESS : integer := 0;
            
            signal ADDRESS_LOW  : integer := 0;
            signal ADDRESS_HIGH : integer := 0;
            
            signal NGROUP : integer;

            constant SYNLOW                          : std_logic_vector(3 downto 0) := "0001";
            constant SSSDSYNHIGH                     : std_logic_vector(3 downto 0) := "0010";
            constant REFPLST                         : std_logic_vector(3 downto 0) := "0011";
            constant PFLOWSYNQ                       : std_logic_vector(3 downto 0) := "0100";
            constant ULEARNPARAMS                    : std_logic_vector(3 downto 0) := "0101";
            constant NPADDRDATA                      : std_logic_vector(3 downto 0) := "0110";
            constant ENDFLOW                         : std_logic_vector(3 downto 0) := "0111";
            
            begin



  SP_CLOCK             <= not SP_CLOCK            after CLKPERIOD/2;
  PARAMETER_MEM_RDCLK  <= not PARAMETER_MEM_RDCLK after CLKPERIOD/2;
  
  SIM_PROCESS : process 
  
            variable SYNAPSE_COUNT_PER_NEURON : integer;
            variable NEURON_COUNT              : integer;
            variable ADDR_OFFSET              : integer;
  
            begin
  
            SIMULATION_FLAG <= RESET_PROC;
  
            wait for 10*CLKPERIOD;
  
            SP_RESET          <= '1';
            TIMESTEP_STARTED  <= '0';
            
            wait for CLKPERIOD;
            
            wait for CLKPERIOD;
            NMC_XNEVER_BASE   <= std_logic_vector(to_unsigned(768,NMC_XNEVER_BASE'length));
            wait for CLKPERIOD;
            NMC_XNEVER_HIGH   <= std_logic_vector(to_unsigned(1023,NMC_XNEVER_HIGH'length));
            wait for CLKPERIOD;

            
            SIMULATION_FLAG <= LEARNING_TABLE_PASS;

                for i in 127 downto 0 loop
                
                     LEARN_LUT_DIN   <= std_logic_vector(to_unsigned(i,LEARN_LUT_DIN'length));
                     LEARN_LUT_ADDR  <= std_logic_vector(to_unsigned(127-i,LEARN_LUT_ADDR'length));
                     LEARN_LUT_EN    <= '1';
                     wait for CLKPERIOD;
                
                end loop;
                
                for i in 255 downto 128 loop
                
                     LEARN_LUT_DIN   <= std_logic_vector(to_unsigned(127-i,LEARN_LUT_DIN'length));
                     LEARN_LUT_ADDR  <= std_logic_vector(to_unsigned(i,LEARN_LUT_ADDR'length));
                     LEARN_LUT_EN    <= '1';
                     wait for CLKPERIOD;
                
                end loop;
                
            LEARN_LUT_DIN   <= (others=>'0');
            LEARN_LUT_ADDR  <= (others=>'0');
            LEARN_LUT_EN    <= '0';
            
            SIMULATION_FLAG <= SYNAPSE_PASS;    
            
            SYNAPSE_ROUTE <= (others=>'1');
           
           -- ADDRESS <= 0;
            NGROUP <= 0;
            
            NMC_PROG_MEM_PORTA_EN  <= (others=>'1');
            NMC_PROG_MEM_PORTA_WEN <= (others=>'1');
            
            NMC_PMODE_SWITCH <= (others=>'1');
            
            NMC_NPARAM_DATA <= "0011001000000000"; --getacc,x1  (LOAD I to x1)
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(542,NMC_NPARAM_ADDR'length));  
            wait for CLKPERIOD;
            NMC_NPARAM_DATA <= "0110000000000000"; --clracc     (CLEAR ACC)
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(543,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;   
            NMC_NPARAM_DATA <= "0001000000110111"; --lw,x2,44   (LOAD v)
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(544,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001010000101100"; --lw,x3,45   (LOAD h)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(545,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001011000101101"; --lw,x4,46   (LOAD u)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(546,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001100000101110"; --lw,x5,47   (LOAD 140)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(547,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001101000101111"; --fmac,x2,x0 (ACC <= v)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(548,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000010000"; --fmac,x1,x3 (ACC <= v + I*h)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(549,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000001011"; --smac,x4,x3 (ACC <= v + I*h - h*u)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(550,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0101000000100011"; --fmac,x5,x3 (ACC <= 140*h - h*u + I*h + v )
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(551,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000101011"; --getacc,x6  ( x6 = 140*h - h*u + I*h + v )
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(552,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011110000000000"; --clracc
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(553,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000"; --fmac,x3,x2 (ACC <= h*v )
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(554,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000011010"; --getacc,x7  ( x7 = h*v )
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(555,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000"; --clracc
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(556,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000"; --lw,x5,48   (LOAD 5)
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(557,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001101000110000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(558,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000111101";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(559,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000110000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(560,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011110000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(561,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(562,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001101000110001";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(563,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000111101";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(564,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(565,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(566,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000111010";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(567,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000110000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(568,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011110000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(569,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(570,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001111000110101";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(571,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0111000000110111";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(572,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "1010000000011010";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(573,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0010110000101100";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(574,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001101000110011";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(575,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001110000110100";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(576,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000101110";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(577,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(578,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(579,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000010011";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(580,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011001000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(581,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(582,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000001111";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(583,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000100000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(584,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011001000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(585,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(586,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000011101";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(587,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(588,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(589,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000111100";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(590,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(591,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(592,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000000001";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(593,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0101000000000111";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(594,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(595,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0110000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(596,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0010111000101110";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(597,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "1101000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(598,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "1011000000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(599,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001111000110010";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(600,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0010111000101100";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(601,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000000100";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(602,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0001010000110110";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(603,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0100000000010000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(604,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0011111000000000";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(605,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA  <= "0010111000101110";
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(606,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA <= "1101000000000000";
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(607,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD;
            NMC_NPARAM_DATA <= X"2E66";  -- h
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+45,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA  <= X"5860";  -- 140
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(768+47,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA  <= X"251E";  -- a
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(768+51,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA  <= X"4F80";  -- threshold
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(768+53,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA  <= X"3266";  -- b
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(768+52,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA  <= X"4000";  -- d
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(768+54,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA <= X"3C00";  -- FP16 1.0
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+55,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA <= X"D240";  -- c
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+50,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA  <= X"291E";  -- 0.04
            NMC_NPARAM_ADDR  <= std_logic_vector(to_unsigned(768+49,NMC_NPARAM_ADDR'length)); 
            wait for CLKPERIOD; 
            NMC_NPARAM_DATA <= X"4500";  -- 5
            NMC_NPARAM_ADDR <= std_logic_vector(to_unsigned(768+48,NMC_NPARAM_ADDR'length)); 
            
            NMC_PMODE_SWITCH <= (others=>'0');

            NMC_PROG_MEM_PORTA_EN  <= (others=>'0');
            NMC_PROG_MEM_PORTA_WEN <= (others=>'0');   
            
            SET_UP_LAYERS : for i in 0 to NETWORK_LAYER_COUNT-1 loop
 
                    SYNAPSE_COUNT_PER_NEURON := FF_TEST_NET_SYNAPSES(i);
                    NEURON_COUNT             := FF_TEST_NET_NEURONS(i);  

                    ZEROER_COLUMN_LOOP : for p in 0 to CROSSBAR_COL_WIDTH-1 loop
                            
                                    SYNAPTIC_MEM_DIN(p)   <= (others=>'0');
                                    SYNAPTIC_MEM_DADDR(p) <= (others=>'0');
                                    SYNAPTIC_MEM_EN(p)    <= '0';
                                    SYNAPTIC_MEM_WREN(p)  <= '0';
                                    
                    end loop ZEROER_COLUMN_LOOP;
                                         
                    wait for 500*CLKPERIOD;
                    
                    if(NEURON_COUNT >= CROSSBAR_COL_WIDTH) then

                        SET_LAYER_SYNAPSES : for k in 0 to NEURON_COUNT/CROSSBAR_COL_WIDTH-1 loop
                        
                           PASS_SYNAPSES : for l in 0 to  SYNAPSE_COUNT_PER_NEURON-1 loop
                           
                                    COLUMN_LOOP : for m in 0 to CROSSBAR_COL_WIDTH-1 loop
                                
                                        SYNAPTIC_MEM_DIN(m)(15 downto 8) <= std_logic_vector(to_unsigned(l,8));
                                        SYNAPTIC_MEM_DIN(m)(7  downto 0) <= std_logic_vector(to_unsigned(l,8));
                                        SYNAPTIC_MEM_DADDR(m)            <= std_logic_vector(to_unsigned(l+ADDRESS,clogb2(SYNAPSE_MEM_DEPTH)));
                                        SYNAPTIC_MEM_EN(m)               <= '1';
                                        SYNAPTIC_MEM_WREN(m)             <= '1';
                                        
                                    end loop COLUMN_LOOP;
                                
                                wait for CLKPERIOD;                           
                                
                           end loop PASS_SYNAPSES;
                           
                           ADDRESS <= SYNAPSE_COUNT_PER_NEURON + ADDRESS;
                           NGROUP <= NGROUP + 1;
          
                        end loop SET_LAYER_SYNAPSES;
                                                   
                    else
                    
                        SET_LAYER_SYNAPSES_0 : for k in 0 to 0 loop
                        
                           PASS_SYNAPSES_0  : for l in 0 to  SYNAPSE_COUNT_PER_NEURON-1 loop
                           
                                    COLUMN_LOOP_0  : for m in 0 to NEURON_COUNT-1 loop
                                
                                        SYNAPTIC_MEM_DIN(m)(15 downto 8) <= std_logic_vector(to_unsigned(l,8));
                                        SYNAPTIC_MEM_DIN(m)(7  downto 0) <= std_logic_vector(to_unsigned(l,8));
                                        SYNAPTIC_MEM_DADDR(m)            <= std_logic_vector(to_unsigned(l+ADDRESS,clogb2(SYNAPSE_MEM_DEPTH)));
                                        SYNAPTIC_MEM_EN(m)               <= '1';
                                        SYNAPTIC_MEM_WREN(m)             <= '1';
                                        
                                    end loop COLUMN_LOOP_0 ;
                                
                                wait for CLKPERIOD;                           
                                
                           end loop PASS_SYNAPSES_0 ;
                           
                           wait for CLKPERIOD;                           
                           
                           ADDRESS <= SYNAPSE_COUNT_PER_NEURON + ADDRESS;
                           NGROUP <= NGROUP + 1;
                           
                            wait for 10*CLKPERIOD;  
                        
                        end loop SET_LAYER_SYNAPSES_0 ;
                        
                    end if;
                
            end loop SET_UP_LAYERS;
            
            SYNAPSE_ROUTE <= (others=>'0');
            
            SIMULATION_FLAG <= NEURON_PARAM_PASS;
            
            wait for CLKPERIOD;
                                       
                ADDRESS <= 0;
                NGROUP  <= 0;
                        
            wait for 100*CLKPERIOD;


            SET_UP_NEURONS : for i in 0 to NETWORK_LAYER_COUNT-1 loop
 
                SYNAPSE_COUNT_PER_NEURON := FF_TEST_NET_SYNAPSES(i);
                NEURON_COUNT             := FF_TEST_NET_NEURONS(i); 
                ADDR_OFFSET              := FF_TEST_NET_ADDR_INC(i);

                ZERO_TO_ALL : for a in 0 to CROSSBAR_COL_WIDTH-1 loop

                        PARAM_MEM_DIN(a)   <= (others=>'0');
                        PARAM_MEM_DADDR(a) <= (others=>'0');
                        PARAM_MEM_EN(a)    <= '0';
                        PARAM_MEM_WREN(a)  <= '0';
                    
                end loop ZERO_TO_ALL;

                wait for 100*CLKPERIOD;
                
                if(NEURON_COUNT >= CROSSBAR_COL_WIDTH) then
           
                    SET_LAYER_NEURONS : for k in 0 to NEURON_COUNT/CROSSBAR_COL_WIDTH-1 loop
                    
                    ADDRESS_HIGH <= SYNAPSE_COUNT_PER_NEURON + ADDRESS_HIGH;

                        ACTIVATE_ALL : for a in 0 to CROSSBAR_COL_WIDTH-1 loop

                            PARAM_MEM_EN(a)      <= '1';
                            PARAM_MEM_WREN(a)    <= '1';
                        
                        end loop ACTIVATE_ALL;
    
       --                 wait for CLKPERIOD; 
       
                        PUSH_TO_ALL_0 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
    
                            PARAM_MEM_DIN(a)(31 downto 28)  <= SYNLOW;
                            PARAM_MEM_DIN(a)(27 downto 16)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(15 downto  0)  <= std_logic_vector(to_unsigned(ADDRESS_LOW,16));
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(0+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));
                        
                        end loop PUSH_TO_ALL_0;
                       
                        wait for CLKPERIOD; 
                        
                        if(i < 1) then
                        
                                PUSH_TO_ALL_1_1 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                                
                                    PARAM_MEM_DIN(a)(31 downto 28)  <= SSSDSYNHIGH  ;
                                    PARAM_MEM_DIN(a)(27 downto 18)  <= (others=>'0');
                                    PARAM_MEM_DIN(a)(17)            <= '0'  ;
                                    PARAM_MEM_DIN(a)(16)            <= '0'  ;
                                    PARAM_MEM_DIN(a)(15 downto 0)   <= std_logic_vector(to_unsigned(ADDRESS_HIGH-1,16)) ;
                                    PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(1+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));    
         
                                end loop PUSH_TO_ALL_1_1;         
                        
                        elsif(i>=1 and i<NETWORK_LAYER_COUNT-1) then
                        
                                PUSH_TO_ALL_1_2 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                                
                                    PARAM_MEM_DIN(a)(31 downto 28)  <= SSSDSYNHIGH  ;
                                    PARAM_MEM_DIN(a)(27 downto 18)  <= (others=>'0');
                                    PARAM_MEM_DIN(a)(17)            <= '1'  ;
                                    PARAM_MEM_DIN(a)(16)            <= '0'  ;
                                    PARAM_MEM_DIN(a)(15 downto 0)   <= std_logic_vector(to_unsigned(ADDRESS_HIGH-1,16)) ;
                                    PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(1+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));    
         
                                end loop PUSH_TO_ALL_1_2; 
                                
                        else
                        
                                PUSH_TO_ALL_1_3 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                                
                                    PARAM_MEM_DIN(a)(31 downto 28)  <= SSSDSYNHIGH  ;
                                    PARAM_MEM_DIN(a)(27 downto 18)  <= (others=>'0');
                                    PARAM_MEM_DIN(a)(17)            <= '1'  ;
                                    PARAM_MEM_DIN(a)(16)            <= '1'  ;
                                    PARAM_MEM_DIN(a)(15 downto 0)   <= std_logic_vector(to_unsigned(ADDRESS_HIGH-1,16)) ;
                                    PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(1+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));    
         
                                end loop PUSH_TO_ALL_1_3; 
                        
                        end if;
         
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_2 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= REFPLST          ;
                            PARAM_MEM_DIN(a)(27 downto 16)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(15 downto  8)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(7 downto   0)  <= std_logic_vector(to_unsigned(32+k,8));   
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(2+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));

                        end loop PUSH_TO_ALL_2;

                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_3 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= PFLOWSYNQ    ;
                            PARAM_MEM_DIN(a)(27 downto 26)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(25 downto 16)  <= std_logic_vector(to_unsigned(542,10))    ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"2004"      ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(3+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));  

                        end loop PUSH_TO_ALL_3;
                        
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_4 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                          
                            PARAM_MEM_DIN(a)(31 downto 28)  <= ULEARNPARAMS ;
                            PARAM_MEM_DIN(a)(27)            <= '0'     ;
                            PARAM_MEM_DIN(a)(26)            <= '0'     ;
                            PARAM_MEM_DIN(a)(25)            <= '0'     ;
                            PARAM_MEM_DIN(a)(24)            <= '0'     ;
                            PARAM_MEM_DIN(a)(23 downto 16)  <= std_logic_vector(to_signed(127,8)) ;
                            PARAM_MEM_DIN(a)(15 downto  8)  <= std_logic_vector(to_signed(-128,8)) ;
                            PARAM_MEM_DIN(a)(7  downto  0)  <= std_logic_vector(to_signed(-12,8)) ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(4+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));
                        
                        end loop PUSH_TO_ALL_4;                    
                        
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_5 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop                    
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= NPADDRDATA   ;
                            PARAM_MEM_DIN(a)(27 downto 26)  <= (others=>'0')   ;
                            PARAM_MEM_DIN(a)(25 downto 16)  <= std_logic_vector(to_unsigned(768+44,10))   ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"0000"  ;     
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(5+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));      
    
                        end loop PUSH_TO_ALL_5;
    
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_6 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= NPADDRDATA   ;
                            PARAM_MEM_DIN(a)(27 downto 26)  <= (others=>'0')   ;
                            PARAM_MEM_DIN(a)(25 downto 16)  <= std_logic_vector(to_unsigned(768+46,10))   ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"0000" ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(6+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));
        
                        end loop PUSH_TO_ALL_6;
        
                        wait for CLKPERIOD;  
                        
                        PUSH_TO_ALL_7 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= ENDFLOW      ;
                            PARAM_MEM_DIN(a)(27 downto 16)  <= (others=>'0')      ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"0001"      ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(7+k*8+ADDR_OFFSET,clogb2(NEURAL_MEM_DEPTH)));
                        
                        end loop PUSH_TO_ALL_7;
                        
                        wait for CLKPERIOD; 
                        
                           ADDRESS_LOW <= SYNAPSE_COUNT_PER_NEURON + ADDRESS_LOW;
                           NGROUP <= NGROUP + 1;
                           ADDRESS <= k*8;
                            
                        wait for 10*CLKPERIOD;
                                    
                    end loop SET_LAYER_NEURONS;
                    
                else
                    
                      SET_LAYER_NEURONS_0 : for k in 0 to 0 loop
                    
                        ACTIVATE_ALL_0 : for a in 0 to NEURON_COUNT-1 loop

                            PARAM_MEM_EN(a)      <= '1';
                            PARAM_MEM_WREN(a)    <= '1';
                        
                        end loop ACTIVATE_ALL_0;
    
       --                 wait for CLKPERIOD; 
       
                        PUSH_TO_ALL_0_0 : for a in 0 to NEURON_COUNT-1 loop
    
                            PARAM_MEM_DIN(a)(31 downto 28)  <= SYNLOW;
                            PARAM_MEM_DIN(a)(27 downto 16)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(15 downto  0)  <= std_logic_vector(to_unsigned(ADDRESS_LOW,16));
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(0+56,clogb2(NEURAL_MEM_DEPTH)));
                        
                        end loop PUSH_TO_ALL_0_0;
                       
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_0_1 : for a in 0 to NEURON_COUNT-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= SSSDSYNHIGH  ;
                            PARAM_MEM_DIN(a)(27 downto 18)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(17)            <= '1'  ;
                            PARAM_MEM_DIN(a)(16)            <= '1'  ;
                            PARAM_MEM_DIN(a)(15 downto 0)   <= std_logic_vector(to_unsigned(ADDRESS_HIGH+31,16)) ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(1+56,clogb2(NEURAL_MEM_DEPTH)));    
         
                        end loop PUSH_TO_ALL_0_1;         
         
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_0_2 : for a in 0 to NEURON_COUNT-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= REFPLST          ;
                            PARAM_MEM_DIN(a)(27 downto 16)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(15 downto  8)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(7 downto   0)  <= std_logic_vector(to_unsigned(32+k,8));   
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(2+56,clogb2(NEURAL_MEM_DEPTH)));

                        end loop PUSH_TO_ALL_0_2;

                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_0_3 : for a in 0 to NEURON_COUNT-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= PFLOWSYNQ    ;
                            PARAM_MEM_DIN(a)(27 downto 26)  <= (others=>'0');
                            PARAM_MEM_DIN(a)(25 downto 16)  <= std_logic_vector(to_unsigned(542,10))    ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"2004"      ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(3+56,clogb2(NEURAL_MEM_DEPTH)));  

                        end loop PUSH_TO_ALL_0_3;
                        
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_0_4 : for a in 0 to NEURON_COUNT-1 loop
                          
                            PARAM_MEM_DIN(a)(31 downto 28)  <= ULEARNPARAMS ;
                            PARAM_MEM_DIN(a)(27)            <= '0'     ;
                            PARAM_MEM_DIN(a)(26)            <= '0'     ;
                            PARAM_MEM_DIN(a)(25)            <= '0'     ;
                            PARAM_MEM_DIN(a)(24)            <= '0'     ;
                            PARAM_MEM_DIN(a)(23 downto 16)  <= std_logic_vector(to_signed(127,8)) ;
                            PARAM_MEM_DIN(a)(15 downto  8)  <= std_logic_vector(to_signed(-128,8)) ;
                            PARAM_MEM_DIN(a)(7  downto  0)  <= std_logic_vector(to_signed(-12,8)) ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(4+56,clogb2(NEURAL_MEM_DEPTH)));
                        
                        end loop PUSH_TO_ALL_0_4;                    
                        
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_0_5 : for a in 0 to NEURON_COUNT-1 loop                    
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= NPADDRDATA   ;
                            PARAM_MEM_DIN(a)(27 downto 26)  <= (others=>'0')   ;
                            PARAM_MEM_DIN(a)(25 downto 16)  <= std_logic_vector(to_unsigned(768+44,10))   ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"0000"  ;     
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(5+56,clogb2(NEURAL_MEM_DEPTH)));      
    
                        end loop PUSH_TO_ALL_0_5;
    
                        wait for CLKPERIOD; 
                        
                        PUSH_TO_ALL_0_6 : for a in 0 to NEURON_COUNT-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= NPADDRDATA   ;
                            PARAM_MEM_DIN(a)(27 downto 26)  <= (others=>'0')   ;
                            PARAM_MEM_DIN(a)(25 downto 16)  <= std_logic_vector(to_unsigned(768+46,10))   ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"0000" ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(6+56,clogb2(NEURAL_MEM_DEPTH)));
        
                        end loop PUSH_TO_ALL_0_6;
        
                        wait for CLKPERIOD;  
                        
                        PUSH_TO_ALL_0_7 : for a in 0 to NEURON_COUNT-1 loop
                        
                            PARAM_MEM_DIN(a)(31 downto 28)  <= ENDFLOW      ;
                            PARAM_MEM_DIN(a)(27 downto 16)  <= (others=>'0')      ;
                            PARAM_MEM_DIN(a)(15 downto  0)  <= X"0001"      ;
                            PARAM_MEM_DADDR(a) <= std_logic_vector(to_unsigned(7+56,clogb2(NEURAL_MEM_DEPTH)));
                        
                        end loop PUSH_TO_ALL_0_7;
                        
                        wait for CLKPERIOD; 
                        
                        ADDRESS <= 8 + ADDRESS;
            
                    end loop SET_LAYER_NEURONS_0;
                    
                    end if;
                    
                
            end loop SET_UP_NEURONS;
            
            ACTIVATE_ALL_1 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                
                      PARAM_MEM_DIN(a)   <= (others=>'0');
                      PARAM_MEM_DADDR(a) <= (others=>'0');
                      PARAM_MEM_EN(a)    <= '0';
                      PARAM_MEM_WREN(a)  <= '0';
                    
                
            end loop ACTIVATE_ALL_1;
                
               
                
            SET_ENDS: for k in 0 to 15 loop
            
                PARAM_MEM_EN(k)    <= '1';
                PARAM_MEM_WREN(k)  <= '1';
                
                PARAM_MEM_DADDR(k)  <= std_logic_vector(to_unsigned(63,clogb2(NEURAL_MEM_DEPTH)));
                PARAM_MEM_DIN(k)(31 downto 28) <= ENDFLOW;
                PARAM_MEM_DIN(k)(27 downto 16) <= (others=>'0');
                PARAM_MEM_DIN(k)(15  downto 0) <= X"0002";
            
                wait for CLKPERIOD;
                
                PARAM_MEM_DADDR(k)  <= std_logic_vector(to_unsigned(64,clogb2(NEURAL_MEM_DEPTH)));
                PARAM_MEM_DIN(k)(31 downto 28) <= ENDFLOW;
                PARAM_MEM_DIN(k)(27 downto 16) <= (others=>'0');
                PARAM_MEM_DIN(k)(15  downto 0) <= X"0003";
            
                wait for CLKPERIOD;
            
            end loop SET_ENDS;
            
           CTIVATE_ALL_1 : for a in 0 to CROSSBAR_COL_WIDTH-1 loop
                
                      PARAM_MEM_DIN(a)   <= (others=>'0');
                      PARAM_MEM_DADDR(a) <= (others=>'0');
                      PARAM_MEM_EN(a)    <= '0';
                      PARAM_MEM_WREN(a)  <= '0';
                    
                
            end loop CTIVATE_ALL_1;
                

            SET_ENDS_0: for k in 16 to 31 loop

                PARAM_MEM_EN(k)    <= '1';
                PARAM_MEM_WREN(k)  <= '1';
                
            
                PARAM_MEM_DADDR(k)  <= std_logic_vector(to_unsigned(55,clogb2(NEURAL_MEM_DEPTH)));
                PARAM_MEM_DIN(k)(31 downto 28) <= ENDFLOW;
                PARAM_MEM_DIN(k)(27 downto 16) <= (others=>'0');
                PARAM_MEM_DIN(k)(15  downto 0) <= X"0002";
            
                wait for CLKPERIOD;
                
                PARAM_MEM_DADDR(k)  <= std_logic_vector(to_unsigned(56,clogb2(NEURAL_MEM_DEPTH)));
                PARAM_MEM_DIN(k)(31 downto 28) <= ENDFLOW;
                PARAM_MEM_DIN(k)(27 downto 16) <= (others=>'0');
                PARAM_MEM_DIN(k)(15  downto 0) <= X"0003";
            
                wait for CLKPERIOD;
            
            end loop SET_ENDS_0;
                

            SIMULATION_FLAG <= GLOBAL_TIMESTEP;
            
            SP_RESET <= '0';

            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '1';
            
            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '0';

            wait until TIMESTEP_COMPLETED = '1';
            
            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '1';
            
            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '0';
            
            wait until TIMESTEP_COMPLETED = '1';
            
                        wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '1';
            
            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '0';
            
            wait until TIMESTEP_COMPLETED = '1';
            
                        wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '1';
            
            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '0';
            
            wait until TIMESTEP_COMPLETED = '1';
            
                        wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '1';
            
            wait for 10*CLKPERIOD;
            
            TIMESTEP_STARTED <= '0';
            
            wait until TIMESTEP_COMPLETED = '1';
            
            wait for 100*CLKPERIOD;

            
            assert false report "One timestep test has been completed" severity failure;
                
end process SIM_PROCESS;

SPIKEPASS : process begin

            wait until EVENT_ACCEPT = '1';
            
            wait for 10*CLKPERIOD;
            
            SPIKEVECTOR_IN      <= (others=>'1');
            SPIKEVECTOR_VLD_IN  <= '1';    
            
            wait until EVENT_ACCEPT = '0';
            
            SPIKEVECTOR_IN      <= (others=>'0');
            SPIKEVECTOR_VLD_IN  <= '0';  


end process SPIKEPASS;


INIT : SPIKE_PROCESSOR
    Generic Map(
            CROSSBAR_ROW_WIDTH => CROSSBAR_ROW_WIDTH,
            CROSSBAR_COL_WIDTH => CROSSBAR_COL_WIDTH,
            SYNAPSE_MEM_DEPTH  => SYNAPSE_MEM_DEPTH ,
            NEURAL_MEM_DEPTH   => NEURAL_MEM_DEPTH  
            )
    Port Map( 
            SP_CLOCK                    => SP_CLOCK                    ,
            PARAMETER_MEM_RDCLK         => PARAMETER_MEM_RDCLK         ,
            SP_RESET                    => SP_RESET                    ,
            TIMESTEP_STARTED            => TIMESTEP_STARTED            ,
            TIMESTEP_COMPLETED          => TIMESTEP_COMPLETED          ,
            SPIKEVECTOR_IN              => SPIKEVECTOR_IN              ,
            SPIKEVECTOR_VLD_IN          => SPIKEVECTOR_VLD_IN          ,
            READ_MAIN_SPIKE_BUFFER      => READ_MAIN_SPIKE_BUFFER      ,
            READ_AUXILLARY_SPIKE_BUFFER => READ_AUXILLARY_SPIKE_BUFFER ,
            EVENT_ACCEPT                => EVENT_ACCEPT                ,
            SYNAPSE_ROUTE               => SYNAPSE_ROUTE               ,
            SYNAPTIC_MEM_DIN            => SYNAPTIC_MEM_DIN            ,
            SYNAPTIC_MEM_DADDR          => SYNAPTIC_MEM_DADDR          ,
            SYNAPTIC_MEM_EN             => SYNAPTIC_MEM_EN             ,
            SYNAPTIC_MEM_WREN           => SYNAPTIC_MEM_WREN           ,
            SYNAPTIC_MEM_DOUT           => SYNAPTIC_MEM_DOUT           ,
            NMC_XNEVER_BASE             => NMC_XNEVER_BASE             ,
            NMC_XNEVER_HIGH             => NMC_XNEVER_HIGH             ,
            NMC_PMODE_SWITCH            => NMC_PMODE_SWITCH            ,
            NMC_NPARAM_DATA             => NMC_NPARAM_DATA             ,
            NMC_NPARAM_ADDR             => NMC_NPARAM_ADDR             ,
            NMC_PROG_MEM_PORTA_EN       => NMC_PROG_MEM_PORTA_EN       ,
            NMC_PROG_MEM_PORTA_WEN      => NMC_PROG_MEM_PORTA_WEN      ,
            NMC_SPIKE_OUT               => NMC_SPIKE_OUT               ,
            NMC_SPIKE_OUT_VLD           => NMC_SPIKE_OUT_VLD           ,
            NMC_WR_AUX_BUFFER           => NMC_WR_AUX_BUFFER           ,
            NMC_WR_OUT_BUFFER           => NMC_WR_OUT_BUFFER           ,
            LEARN_LUT_DIN               => LEARN_LUT_DIN               ,
            LEARN_LUT_ADDR              => LEARN_LUT_ADDR              ,
            LEARN_LUT_EN                => LEARN_LUT_EN                ,
            PARAM_MEM_DIN               => PARAM_MEM_DIN               ,
            PARAM_MEM_DADDR             => PARAM_MEM_DADDR             ,
            PARAM_MEM_EN                => PARAM_MEM_EN                ,
            PARAM_MEM_WREN              => PARAM_MEM_WREN              ,
            PARAM_MEM_DOUT              => PARAM_MEM_DOUT              ,
            NMC_MATH_ERROR_VEC          => NMC_MATH_ERROR_VEC          ,
            NMC_MEM_VIOLATION_VEC       => NMC_MEM_VIOLATION_VEC       
          );


end money_for_nothing;




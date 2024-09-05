library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.crossbar_utils.all;

package processor_primitives is

component NMC is
    Port ( 
            NMC_CLK                     : in   std_logic;  -- SYNCHRONOUS SOFT RESET
            NMC_STATE_RST               : in   std_logic;  -- RESETS THE NMC STATES, FP16MAC and REGISTERS
            FMAC_EXTERN_RST             : in   std_logic;
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
            NMC_NMODEL_SPIKE_VLD        : out  std_logic; 
            -- TO REDISTRIBUTOR
            R_NNMODEL_NEW_SPIKE_TIME    : out  std_logic_vector(7  downto 0);
            R_NMODEL_NPARAM_DATAOUT     : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
            R_NMODEL_REFRACTORY_DUR     : OUT  std_logic_vector(7  downto 0);
            REDIST_NMODEL_PORTB_TKOVER  : in   std_logic;
            REDIST_NMODEL_DADDR         : in   std_logic_vector(9 downto 0);
            -- IP STATUS FLAGS
            NMC_NMODEL_FINISHED         : out std_logic;
            -- ERROR FLAGS
            NMC_MATH_ERROR              : out std_logic;
            NMC_MEMORY_VIOLATION        : out std_logic
    );
end component NMC;

component AUTO_RAM_INSTANCE is
generic (
    RAM_WIDTH       : integer := 32;                      -- Specify RAM data width
    RAM_DEPTH       : integer := 2048  ;            -- Specify RAM depth (number of entries)
    RAM_PERFORMANCE : string  := "LOW_LATENCY"      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    );

port (
        addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        addrb : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);		                 -- Port A RAM input data
        dinb  : in std_logic_vector(RAM_WIDTH-1 downto 0);		                 -- Port B RAM input data
        clka  : in std_logic;                       			         -- Port A Clock
        clkb  : in std_logic;                       			         -- Port B Clock
        wea   : in std_logic;                       			         -- Port A Write enable
        web   : in std_logic;                       			         -- Port B Write enable
        ena   : in std_logic;                       			         -- Port A RAM Enable, for additional power savings, disable port when not in use
        enb   : in std_logic;                       			         -- Port B RAM Enable, for additional power savings, disable port when not in use
        rsta  : in std_logic;                       			         -- Port A Output reset (does not affect memory contents)
        rstb  : in std_logic;                       			         -- Port B Output reset (does not affect memory contents)
        regcea: in std_logic;                       			         -- Port A Output register enable
        regceb: in std_logic;                       			         -- Port B Output register enable
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0);   			         --  Port A RAM output data
        doutb : out std_logic_vector(RAM_WIDTH-1 downto 0)  
    );

end component AUTO_RAM_INSTANCE;

component BRIDGE is
    Generic (
        NEURAL_MEM_DEPTH  : integer := 2048;    
        SYNAPSE_MEM_DEPTH : integer := 2048;
        ROW               : integer := 16             
        );
    Port(
        BRIDGE_CLK                 : in  std_logic;
        BRIDGE_RST                 : in  std_logic;
        -- TIMESTEP UPDATE        
        CYCLE_COMPLETED            : out std_logic;
        -- BRIDGE CONTROLS
        EVENT_DETECT               : in  std_logic;
        -- EVENT ACCEPTANCE
        EVENT_ACCEPTANCE           : out std_logic;
        -- SPIKE SOURCE
        MAIN_SPIKE_BUFFER          : out std_logic;
        AUXILLARY_SPIKE_BUFFER     : out std_logic;
        -- SPIKE DESTINATION
        OUTBUFFER                  : out std_logic;
        AUXBUFFER                  : out std_logic;
        -- SYNAPTIC MEMORY CONTROLS (PORT B)
        SYNAPTIC_MEM_RDADDR        : out std_logic_vector((clogb2(SYNAPSE_MEM_DEPTH)-1) downto 0);
        SYNAPTIC_MEM_ENABLE        : out std_logic;
        SYNAPTIC_MEM_WRADDR        : out std_logic_vector((clogb2(SYNAPSE_MEM_DEPTH)-1) downto 0);
        SYNAPTIC_MEM_WREN          : out std_logic;
        -- HYPERCOLUMN CONTROLS
        HALT_HYPERCOLUMN           : out std_logic;
        PRE_SYN_DATA_PULL          : out std_logic;
        -- NMC CONTROLS
        NMC_STATE_RST              : out std_logic; 
        NMC_FMAC_RST               : out std_logic; 
        NMC_COLD_START             : out std_logic; 
        NMODEL_LAST_SPIKE_TIME     : out STD_LOGIC_VECTOR(7  DOWNTO 0); 
        NMODEL_SYN_QFACTOR         : out STD_LOGIC_VECTOR(15 DOWNTO 0); 
        NMODEL_PF_LOW_ADDR         : out STD_LOGIC_VECTOR(9  DOWNTO 0); 
        NMODEL_NPARAM_DATA         : out STD_LOGIC_VECTOR(15 DOWNTO 0);
        NMODEL_NPARAM_ADDR         : out STD_LOGIC_VECTOR(9  DOWNTO 0);
        NMODEL_REFRACTORY_DUR      : out std_logic_vector(7  downto 0);
        NMODEL_PROG_MEM_PORTA_EN   : out STD_LOGIC;
        NMODEL_PROG_MEM_PORTA_WEN  : out STD_LOGIC;
        R_NNMODEL_NEW_SPIKE_TIME   : in  std_logic_vector(7  downto 0);
        R_NMODEL_NPARAM_DATAOUT    : in  STD_LOGIC_VECTOR(15 DOWNTO 0);
        R_NMODEL_REFRACTORY_DUR    : in  std_logic_vector(7  downto 0);
        REDIST_NMODEL_PORTB_TKOVER : out std_logic;
        REDIST_NMODEL_DADDR        : out std_logic_vector(9 downto 0);
        NMC_NMODEL_FINISHED        : in  std_logic;
        -- SYNAPTIC RAM MANAGEMENT
        SYNMEM_PORTA_MUX           : out std_logic;
        -- ULEARN CONTROLS
        ACTVATE_LENGINE            : out std_logic;
        LEARN_RST                  : out std_logic;
        SYNAPSE_PRUN               : out std_logic;
        PRUN_THRESH                : out std_logic_vector(7 downto 0);
        IGNORE_ZEROS               : out std_logic; 
        IGNORE_SOFTLIM             : out std_logic;  
        NEURON_WMAX                : out std_logic_vector(7 downto 0);
        NEURON_WMIN                : out std_logic_vector(7 downto 0);
        NEURON_SPK_TIME            : out std_logic_vector(7 downto 0);
        -- NEURAL MEMORY INTERFACE
        addra                      : out std_logic_vector((clogb2(NEURAL_MEM_DEPTH)-1) downto 0); 
        wea                        : out std_logic;	                
        ena                        : out std_logic;                       			     
        rsta                       : out std_logic;                       			     
        douta                      : in  std_logic_vector(31 downto 0);            
        dina                       : out std_logic_vector(31 downto 0)            

        );
end component BRIDGE;

component ULEARN_SINGLE is
    Generic(
            LUT_TYPE : string := "distributed" ;
            SYNAPSE_MEM_DEPTH  : integer := 2048           
            );
    Port 
    ( 
        ULEARN_RST             : in  std_logic;
        ULEARN_CLK             : in  std_logic;
        -- SYNAPTIC FIFO PORT  
        SYN_DATA_IN            : in  std_logic_vector(15 downto 0);
        SYN_DIN_VLD            : in  std_logic;
        SYNAPSE_START_ADDRESS  : in  std_logic_vector((clogb2(SYNAPSE_MEM_DEPTH)-1) downto 0);  
        SYN_DATA_OUT           : out std_logic_vector(15 downto 0);
        SYN_DOUT_VLD           : out std_logic;
        SYNAPSE_WRITE_ADDRESS  : out std_logic_vector((clogb2(SYNAPSE_MEM_DEPTH)-1) downto 0);  
        -- CONTROL SIGNAL
        SYNAPSE_PRUNING        : in  std_logic;
        PRUN_THRESHOLD         : in  std_logic_vector(7 downto 0);
        IGNORE_ZERO_SYNAPSES   : in  std_logic;  -- EXPERIMENTAL, CAREFUL WITH THIS.
        IGNORE_SOFTLIMITS      : in  std_logic;  -- EXPERIMENTAL, CAREFUL WITH THIS.
        -- AXI4 LITE INTERFACE PORTS
        ULEARN_LUT_DIN         : in  std_logic_vector(7 downto 0);
        ULEARN_LUT_ADDR        : in  std_logic_vector(7 downto 0);
        ULEARN_LUT_EN          : in  std_logic;
        -- PARAMETER
        NMODEL_WMAX            : in  std_logic_vector(7 downto 0);
        NMODEL_WMIN            : in  std_logic_vector(7 downto 0);
        -- NMC PORT
        NMODEL_SPIKE_TIME      : in  std_logic_vector(7 downto 0)

    );
end component ULEARN_SINGLE;


component CROSSBAR_FABRIC is
    Generic(
            ROW                : integer := 32   ;
            COLUMN             : integer := 32    ;
            SYNAPSE_MEM_DEPTH  : integer := 4096

            );
    Port (
            CB_CLK                          : in  std_logic;
            CB_VECTOR_RST                   : in  std_logic_vector(0 to COLUMN-1);
            SPIKE_IN                        : in  std_logic_vector(ROW-1 downto 0);
            SPIKE_VLD                       : in  std_logic;
            COLUMN_PRE_SYNAPTIC_DIN         : in  SYNAPTIC_DATA(0 to COLUMN-1);
            COLUMN_SYNAPSE_START_ADDRESS    : in  SYNAPSE_ADDRESS(0 to COLUMN-1)(clogb2(SYNAPSE_MEM_DEPTH)-1 downto 0);
            PRE_SYN_DATA_PULL               : in  std_logic_vector(0 to COLUMN-1);
            COLN_SYN_SUM_OUT                : out SYNAPTIC_SUM(0 to COLUMN-1);
            COLN_VECTOR_SYN_SUM_VALID       : out std_logic_vector(0 to COLUMN-1);
            COLUMN_POST_SYNAPTIC_DOUT       : out SYNAPTIC_DATA(0 to COLUMN-1);
            COLUMN_SYNAPSE_WR_ADDRESS       : out SYNAPSE_ADDRESS(0 to COLUMN-1)(clogb2(SYNAPSE_MEM_DEPTH)-1 downto 0);
            COLUMN_POST_SYNAPTIC_WREN       : out std_logic_vector(0 to COLUMN-1)
        );
end component CROSSBAR_FABRIC;

component or_reduce is
    generic (
        N : integer := 8  
    );
    port (
        A : in  STD_LOGIC_VECTOR(N-1 downto 0);
        Y : out STD_LOGIC 
    );
end component or_reduce;


end processor_primitives;
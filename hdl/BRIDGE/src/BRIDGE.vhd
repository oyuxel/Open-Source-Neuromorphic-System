library ieee;
use ieee.std_logic_1164.all;

package nmemportdef is
    function clogb2 (depth: in natural) return integer;
end nmemportdef;

package body nmemportdef is

function clogb2( depth : natural) return integer is
variable temp    : integer := depth;
variable ret_val : integer := 0;
begin
    while temp > 1 loop
        ret_val := ret_val + 1;
        temp    := temp / 2;
    end loop;
    return ret_val;
end function;

end package body nmemportdef;


library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.nmemportdef.all;

entity BRIDGE is
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
end BRIDGE;

architecture crush_with_eyeliner of BRIDGE is

    constant PRE_SYN_PERIOD       : integer := ROW;
    signal   SYNAPSECOUNTER       : integer ;
    signal   LESYNAPSECOUNTER     : integer ;
    signal   TWOCYCLES            : integer range 0 to 3;
    signal   POSTSYNDLYCNTR       : integer range 0 to 15;
    signal   LESYNAPSECOUNT       : integer ;
    signal   CURRENT_ACC_DLYCNTR  : integer ;
    signal   MEMLOC               : integer range 0 to NEURAL_MEM_DEPTH-1;
    signal   NEURONSPACE          : integer range 0 to NEURAL_MEM_DEPTH-1;
    signal   DLYCNTR              : integer range 0 to NEURAL_MEM_DEPTH-1;
    signal   SPIKE_SOURCE         : std_logic;
    signal   SPIKE_DESTINATION    : std_logic;
    signal   DTYPE                : std_logic_vector(3 downto 0);
 
    constant SYNLOW               : std_logic_vector(3 downto 0) := "0001";
    constant SSSDSYNHIGH          : std_logic_vector(3 downto 0) := "0010";
    constant REFPLST              : std_logic_vector(3 downto 0) := "0011";
    constant PFLOWSYNQ            : std_logic_vector(3 downto 0) := "0100";
    constant ULEARNPARAMS         : std_logic_vector(3 downto 0) := "0101";
    constant NPADDRDATA           : std_logic_vector(3 downto 0) := "0110";
    constant ENDFLOW              : std_logic_vector(3 downto 0) := "0111";
    
    signal   SYNAPSE_LOW_ADDRESS  : integer range 0 to SYNAPSE_MEM_DEPTH-1;
    signal   SYNAPSE_HIGH_ADDRESS : integer range 0 to SYNAPSE_MEM_DEPTH-1;
    signal   SYNAPSE_LOCATION     : integer range 0 to SYNAPSE_MEM_DEPTH-1;
    signal   SYNAPSE_LOCATION_PAST: integer range 0 to SYNAPSE_MEM_DEPTH-1;
    signal   SYNAPSE_LOCATION_PAST_2: integer range 0 to SYNAPSE_MEM_DEPTH-1;
        
    signal   NEXTINLINE           : std_logic_vector(2 downto 0);
    
    signal   NEURON_LOADED        : std_logic;
    signal   SYNAPSES_LOADED      : std_logic;
    
    signal   EVENT_ACCEPTANCE_REG : std_logic;
    
    signal   SWAP_DBUFFER    : std_logic_vector(15 downto 0);
    signal   SWAP_ABUFFER    : std_logic_vector(9 downto 0);
    
    type STATES is (SLEEP,LOAD_NEURON,INFERENCE,SYNAPTIC_CURRENT_ACC,NMC_STATE,SWAP,SWAPRFPLST,READNPARAMADDR,WAITNPARAMDATA,WAITNPARAMDATA1,WAITNPARAMDATA2,READNPARAMDATA,BREWNPARAM,SHAPEUP,BS1,BS2,BS3,LEARNING_PARAM_FETCH,UPDATE_SYNAPSES,POSTSYNDLY1,POSTSYNDLY2,UPDATE_TIMESTEP);
    signal BRIDGE_STATE : STATES;
    
    -- INTERNAL STATUS FLAGS
    
    signal PULL_FIRST_SYNAPSES  : std_logic;
    signal PULLSYNAPSES         : std_logic;
  
    --  DOUTA(31 downto 28)
    --
    -- "0001" --> SYNAPSE_LOW_ADDRESS
    --
    --            if SYNLOW = DOUTA(31 downto 28)
    --              SYNAPSE_LOW_ADDRESS   <= douta(15 downto 0)
    --
    -- "0010" --> SPIKE SOURCE & SPIKE DESTINATION & SYNAPSE_HIGH_ADDRESS  
    --
    --            if SSSDSYNHIGH = DOUTA(31 downto 28)
    --              SPIKE SOURCE          <= douta(17)            '0' : MAIN SPIKE BUFFER ,      '1' : AUXILLARY SPIKE BUFFER
    --              SPIKE DESTINATION     <= douta(16)            '0' : AUXILLARY SPIKE BUFFER , '1' : OUTPUT SPIKE BUFFER
    --              SYNAPSE_HIGH_ADDRESS  <= douta(15 downto 0)
    --
    -- "0011" --> REFRACTORY PERIOD & LAST SPIKE TIME                     
    --              
    --             if RFPLST = DOUTA(31 downto 28)
    --              REFACTORY PERIOD      <= douta(15 downto 8)
    --              LAST SPIKE TIME       <= douta(7  downto 0) 
    --
    -- "0100" --> PROGRAM FLOW LOW & SYNAPTIC QFACTOR  
    --
    --             if PFLOWSYNQ = DOUTA(31 downto 28)
    --              PROGRAM FLOW LOW      <= douta(25 downto 16) 
    --              SYNAPTIC QFACTOR      <= douta(15 downto  0) 
    --
    -- "0101" --> SYNAPSE_PRUN & IGNORE_ZEROS & IGNORE_SOFTLIM & NEURON_WMAX & NEURON_WMIN & PRUN_THRESHOLD
    --
    --             if ULEARNPARAMS = DOUTA(31 downto 28)
    --              SYNAPSE_PRUN          <= douta(26)     
    --              IGNORE_ZEROS          <= douta(25)      
    --              IGNORE_SOFTLIM        <= douta(24)      
    --              NEURON_WMAX           <= douta(23 downto 16)                   
    --              NEURON_WMIN           <= douta(15 downto  8)
    --              PRUN_THRESHOLD        <= douta(7  downto  0)
    --
    -- "0110" --> NPARAM_ADDR & NPARAM_DATA
    --
    --             if NPARAMADDR  = DOUTA(31 downto 28)
    --              NPARAM_ADDR <= douta(25 downto 16)
    --              NPARAM_DATA <= douta(15 downto 0)
    --
    -- "0111" --> ENDFLOW   
    --   
    --             if NPARAMDATA  = DOUTA(31 downto 28)
    --              ENDFLOW = X"0001" --> Start Inference. There will be a neuron next. Wait for NMC_NMODEL_FINISHED and load the next neuron.
    --              ENDFLOW = X"0002" --> Start Learning. Take only INFERENCE CYCLES and LAST SPIKE TIMES and feed them into Learning Engines
    --              ENDFLOW = X"0003" --> Network completed. Load the first neurons and first synapses and wait for an event.

begin

    MAIN_SPIKE_BUFFER          <= not SPIKE_SOURCE;                                
    AUXILLARY_SPIKE_BUFFER     <= SPIKE_SOURCE;
    OUTBUFFER                  <= SPIKE_DESTINATION;  
    AUXBUFFER                  <= not SPIKE_DESTINATION;

    addra                      <= std_logic_vector(to_unsigned(MEMLOC,addra'length));
    DTYPE                      <= douta(31 downto 28);
    
    SYNAPTIC_MEM_RDADDR        <= std_logic_vector(to_unsigned(SYNAPSE_LOCATION,SYNAPTIC_MEM_RDADDR'length));
    SYNAPTIC_MEM_WRADDR        <= std_logic_vector(to_unsigned(SYNAPSE_LOCATION_PAST_2,SYNAPTIC_MEM_WRADDR'length));
    
    EVENT_ACCEPTANCE           <= EVENT_ACCEPTANCE_REG;

MSM : process(BRIDGE_CLK) 

    begin
    
        if(rising_edge(BRIDGE_CLK)) then
        
            if(BRIDGE_RST = '1') then
            
                wea                  <= '0';
                ena                  <= '1';
                rsta                 <= '1';
                MEMLOC               <=  0;
                SPIKE_SOURCE         <= '0';
                SPIKE_DESTINATION    <= '0';
                BRIDGE_STATE         <= LOAD_NEURON;
                PRE_SYN_DATA_PULL    <= '0';
                PULLSYNAPSES         <= '0';
                SYNAPSECOUNTER       <=  0;
                PULL_FIRST_SYNAPSES  <= '0';
                NEXTINLINE           <= (others=>'0');
                NEURONSPACE          <=  0;
                NMC_STATE_RST        <= '1';
                CURRENT_ACC_DLYCNTR  <=  0;
                NMC_FMAC_RST         <= '0';
                SYNAPSE_LOW_ADDRESS  <=  0;
                SYNAPSE_HIGH_ADDRESS <=  0;
                NEURON_LOADED        <= '0';
                SYNAPSES_LOADED      <= '0';
                SYNAPSE_LOCATION     <=  0;
                SYNAPSE_LOCATION_PAST<=  0;
                SYNAPSE_LOCATION_PAST_2<=  0;
                TWOCYCLES            <=  0;
                HALT_HYPERCOLUMN     <= '0';
                SYNMEM_PORTA_MUX     <= '0';
                LEARN_RST            <= '1';
                ACTVATE_LENGINE      <= '0';
                POSTSYNDLYCNTR       <=  0;
                CYCLE_COMPLETED      <= '0';
                EVENT_ACCEPTANCE_REG <= '0';
                SYNAPTIC_MEM_WREN    <= '0';
                
            else

                case BRIDGE_STATE is
                
                    when LOAD_NEURON =>
                
                        rsta                 <= '0';                        
                        NMC_STATE_RST        <= '0';
                        CURRENT_ACC_DLYCNTR  <=  0 ;
                        SYNMEM_PORTA_MUX     <= '0';
                        EVENT_ACCEPTANCE_REG <= '0';

                        
                        if    DTYPE = SYNLOW       then
                        
                                SYNAPSE_LOW_ADDRESS       <= to_integer(unsigned(douta(15 downto 0)));
                                NMODEL_NPARAM_DATA        <= (others=>'0');
                                NMODEL_NPARAM_ADDR        <= (others=>'0');
                                PULL_FIRST_SYNAPSES       <= '0'; 
                                
                                if(TWOCYCLES = 1) then
                                    NEURONSPACE <= NEURONSPACE + 1;
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;

                        elsif DTYPE = SSSDSYNHIGH  then
                        
                                SYNAPSE_HIGH_ADDRESS      <= to_integer(unsigned(douta(15 downto 0)));
                                SPIKE_DESTINATION         <= douta(16);
                                SPIKE_SOURCE              <= douta(17);
                                NMODEL_PROG_MEM_PORTA_EN  <= '0';
                                NMODEL_PROG_MEM_PORTA_WEN <= '0';
                                NMC_FMAC_RST              <= '1';
                                NMODEL_NPARAM_DATA        <= (others=>'0');
                                NMODEL_NPARAM_ADDR        <= (others=>'0');
                                PULL_FIRST_SYNAPSES       <= '1'; 
                                
                                if(TWOCYCLES = 1) then
                                    NEURONSPACE <= NEURONSPACE + 1;
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;
                                
                        elsif DTYPE = REFPLST          then
                        
                                NMODEL_LAST_SPIKE_TIME    <= douta(7  downto  0);
                                NMODEL_REFRACTORY_DUR     <= douta(15 downto  8);

                                NMODEL_PROG_MEM_PORTA_EN  <= '0';
                                NMODEL_PROG_MEM_PORTA_WEN <= '0';
                                NMC_FMAC_RST              <= '0';
                                NMODEL_NPARAM_DATA        <= (others=>'0');
                                NMODEL_NPARAM_ADDR        <= (others=>'0');
                                
                                if(TWOCYCLES = 1) then
                                    NEURONSPACE <= NEURONSPACE + 1;
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;
                                
                        elsif DTYPE = PFLOWSYNQ    then
                        
                                NMODEL_PF_LOW_ADDR        <= douta(25 downto 16);
                                NMODEL_SYN_QFACTOR        <= douta(15 downto  0);
                                NMODEL_PROG_MEM_PORTA_EN  <= '0';
                                NMODEL_PROG_MEM_PORTA_WEN <= '0';
                                NMODEL_NPARAM_DATA        <= (others=>'0');
                                NMODEL_NPARAM_ADDR        <= (others=>'0');
                                
                                if(TWOCYCLES = 1) then
                                    NEURONSPACE <= NEURONSPACE + 1;
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;
                                
                        elsif DTYPE = ULEARNPARAMS then
                        
                                NMODEL_NPARAM_DATA        <= (others=>'0');
                                NMODEL_NPARAM_ADDR        <= (others=>'0');
                                
                                if(TWOCYCLES = 1) then
                                    NEURONSPACE <= NEURONSPACE + 1;
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;
                                
                        elsif DTYPE = NPADDRDATA   then
                        
                                NMODEL_NPARAM_DATA        <= douta(15 downto 0);
                                NMODEL_NPARAM_ADDR        <= douta(25 downto 16);

                                    NMODEL_PROG_MEM_PORTA_EN  <= '1';
                                    NMODEL_PROG_MEM_PORTA_WEN <= '1';

                                if(TWOCYCLES = 1) then
                                
                                    NEURONSPACE <= NEURONSPACE + 1;
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                    
                                else
                               
                                    TWOCYCLES <= TWOCYCLES + 1;

                                end if;
                                
                        elsif DTYPE = ENDFLOW      then
          
                                NMODEL_PROG_MEM_PORTA_EN  <= '0';
                                NMODEL_PROG_MEM_PORTA_WEN <= '0';
                                ena                       <= '0';                                
                                MEMLOC                    <= MEMLOC;
                                NEURONSPACE               <= NEURONSPACE;
                                NEXTINLINE                <= douta(2 downto 0);
                                NMODEL_NPARAM_DATA        <= (others=>'0');
                                NMODEL_NPARAM_ADDR        <= (others=>'0');
                                NEURON_LOADED             <= '1';
                                
                        end if;                       
                          
                        if PULL_FIRST_SYNAPSES = '1' and PULLSYNAPSES = '0' then
                          
                                PULLSYNAPSES        <= '1';
                                SYNAPSE_LOCATION    <=  SYNAPSE_LOW_ADDRESS;
                                SYNAPTIC_MEM_ENABLE <= '1';
                                SYNAPSES_LOADED     <= '0';
                        end if;
                          
                        if(PULLSYNAPSES = '1') then
                         
                           if SYNAPSE_LOCATION = PRE_SYN_PERIOD + SYNAPSE_LOW_ADDRESS then 
                               PULLSYNAPSES          <= '0';
                               PRE_SYN_DATA_PULL     <= '0';
                               PULL_FIRST_SYNAPSES   <= '0';
                               SYNAPSES_LOADED       <= '1';
                           elsif SYNAPSE_LOCATION = SYNAPSE_HIGH_ADDRESS then 
                               PULLSYNAPSES          <= '0';
                               PRE_SYN_DATA_PULL     <= '0';
                               PULL_FIRST_SYNAPSES   <= '0';
                               SYNAPSES_LOADED       <= '1';                                
                           else
                               SYNAPSE_LOCATION      <= SYNAPSE_LOCATION + 1;
                               PRE_SYN_DATA_PULL     <= '1';
                               SYNAPTIC_MEM_ENABLE   <= '1';
                               SYNAPSES_LOADED       <= '0';
                           end if;
                                                   
                        end if;
                        
                        if(NEURON_LOADED = '1' and SYNAPSES_LOADED = '1') then
                            BRIDGE_STATE            <= INFERENCE;
                            SYNAPSES_LOADED         <= '1';
                            PULLSYNAPSES            <= '0';
                            PRE_SYN_DATA_PULL       <= '0';
                            NEURON_LOADED           <= '0';
                            SYNAPSES_LOADED         <= '0';
                            SYNAPSE_LOCATION_PAST_2 <= SYNAPSE_LOW_ADDRESS;
                            EVENT_ACCEPTANCE_REG    <= '1';
                        else
                            BRIDGE_STATE      <= LOAD_NEURON;
                            SYNAPSE_LOCATION_PAST     <= SYNAPSE_LOCATION;
                        end if;

                    when INFERENCE =>

                       -- EVENT_ACCEPTANCE <= '1';

                            if(EVENT_DETECT = '1' and PULLSYNAPSES = '0' and EVENT_ACCEPTANCE_REG = '1') then
                            
                               PULLSYNAPSES <= '1';
                               TWOCYCLES    <= 0;                                      
                               SYNAPSE_LOCATION_PAST_2   <= SYNAPSE_LOCATION_PAST;
                               EVENT_ACCEPTANCE_REG <= '0';
                               SYNAPTIC_MEM_WREN  <= '0';

                            end if;
                                                        
                            if(PULLSYNAPSES = '1') then
                            
                            
                              if SYNAPSE_LOCATION = PRE_SYN_PERIOD + SYNAPSE_LOCATION_PAST then 
                                  PULLSYNAPSES          <= '0';
                                  PRE_SYN_DATA_PULL     <= '0';
                                  SYNAPTIC_MEM_WREN     <= '0';
                                  PULL_FIRST_SYNAPSES   <= '0';
                                  EVENT_ACCEPTANCE_REG  <= '1';
                                  SYNAPSE_LOCATION_PAST <= SYNAPSE_LOCATION;
                                  BRIDGE_STATE          <= INFERENCE;
                                  
                              elsif SYNAPSE_LOCATION = SYNAPSE_HIGH_ADDRESS then 
                              
                              if(TWOCYCLES = 1) then
                                
                                    TWOCYCLES   <= 0;                                      
                                    PULLSYNAPSES          <= '0';
                                    PRE_SYN_DATA_PULL     <= '0';
                                    SYNAPTIC_MEM_WREN     <= '0';
                                    PULL_FIRST_SYNAPSES   <= '0';
                                    BRIDGE_STATE          <= SYNAPTIC_CURRENT_ACC;
                                    EVENT_ACCEPTANCE_REG  <= '1';

                               else
                               
                                    TWOCYCLES <= TWOCYCLES + 1;

                              end if;             
                                  
                              else
                                  SYNAPSE_LOCATION    <= SYNAPSE_LOCATION + 1;
                                  PRE_SYN_DATA_PULL   <= '1';
                                  SYNAPTIC_MEM_ENABLE <= '1';
                                  SYNAPTIC_MEM_WREN   <= '1';
                              end if;
                                                      
                            end if;


                    when SYNAPTIC_CURRENT_ACC =>
                    
                           if(EVENT_DETECT = '1' and EVENT_ACCEPTANCE_REG = '1') then
                            
                               EVENT_ACCEPTANCE_REG <= '0';

                            end if;
             
                        if(CURRENT_ACC_DLYCNTR = ROW+1) then
                                                    
                             BRIDGE_STATE  <= NMC_STATE;
                             EVENT_ACCEPTANCE_REG      <= '0';
                             NMC_COLD_START <= '1';
                             CURRENT_ACC_DLYCNTR <= 0;

                        elsif(CURRENT_ACC_DLYCNTR = ROW) then
                        
                            NMC_STATE_RST <= '0';
                            CURRENT_ACC_DLYCNTR <= CURRENT_ACC_DLYCNTR + 1;

                        elsif(CURRENT_ACC_DLYCNTR = ROW-1) then
                        
                            NMC_STATE_RST <= '1';
                            CURRENT_ACC_DLYCNTR <= CURRENT_ACC_DLYCNTR + 1;

                        else
                        
                            CURRENT_ACC_DLYCNTR <= CURRENT_ACC_DLYCNTR + 1;
                            BRIDGE_STATE        <= SYNAPTIC_CURRENT_ACC;
                        end if;
                    
                    when NMC_STATE =>
                    
                            NMC_COLD_START <= '0';
                            
                         --   HALT_HYPERCOLUMN <= '1';
                            
                            if(NMC_NMODEL_FINISHED = '1') then
                                BRIDGE_STATE <= BS2;
                                MEMLOC       <= MEMLOC - NEURONSPACE;
                                ena          <= '1';
                                DLYCNTR      <=  0;
                                wea          <= '0';
                                TWOCYCLES    <=  0;
                                SWAP_DBUFFER <= (others=>'0');
                                SWAP_ABUFFER <= (others=>'0');
                            else
                                BRIDGE_STATE      <= NMC_STATE;
                            end if;
                    
                    when SWAP =>                         
                                                             
                        if DTYPE = REFPLST          then
                        
                            BRIDGE_STATE  <= SWAPRFPLST;

                        elsif DTYPE = NPADDRDATA   then
                        
                            BRIDGE_STATE  <= READNPARAMADDR;
                                
                        elsif DTYPE = ENDFLOW      then

                             MEMLOC       <= MEMLOC;
                             wea          <= '0';
                             
                             if(NEXTINLINE = "000") then
                             
                                BRIDGE_STATE  <= UPDATE_TIMESTEP;                             
                             
                             elsif(NEXTINLINE = "001") then
                             
                                BRIDGE_STATE  <= SHAPEUP;
                                MEMLOC        <= MEMLOC + 1;
                                NEURONSPACE   <=  0;

                             elsif(NEXTINLINE = "010") then
                             
                                SYNMEM_PORTA_MUX <= '1';
                                BRIDGE_STATE     <= BS3;
                                MEMLOC           <= 0;
                                ACTVATE_LENGINE  <= '0';

                             end if;
                             
                        else
                               wea          <= '0';
                               BRIDGE_STATE <= BS1;
                        end if;
  
                    when SWAPRFPLST =>  
                    
                            dina(31 downto 28) <= REFPLST;
                            dina(27 downto 16) <= (others=>'0');
                            dina(15 downto  8) <= R_NMODEL_REFRACTORY_DUR;
                            dina(7 downto   0) <= R_NNMODEL_NEW_SPIKE_TIME;
                            wea                <= '1';
                            BRIDGE_STATE  <= BS1;
                    
                    when READNPARAMADDR =>
                    
                            REDIST_NMODEL_DADDR        <= douta(25 downto 16);
                            REDIST_NMODEL_PORTB_TKOVER <= '1';
                            SWAP_ABUFFER <= douta(25 downto 16);
                            BRIDGE_STATE  <= WAITNPARAMDATA;

                    when WAITNPARAMDATA =>
                    
                             BRIDGE_STATE  <= WAITNPARAMDATA1;

                    when WAITNPARAMDATA1 =>
                    
                             BRIDGE_STATE  <= WAITNPARAMDATA2;
                             
                    when WAITNPARAMDATA2 =>
                    
                             BRIDGE_STATE  <= READNPARAMDATA;                             

                    when READNPARAMDATA =>
                    
                             BRIDGE_STATE  <= BREWNPARAM;
                             SWAP_DBUFFER <= R_NMODEL_NPARAM_DATAOUT;

                    when BREWNPARAM =>
                    
                             dina(31 downto 28) <= NPADDRDATA;
                             dina(27 downto 26) <= (others=>'0');
                             dina(25 downto 16) <= SWAP_ABUFFER;
                             dina(15 downto  0) <= SWAP_DBUFFER;
                             wea                <= '1';
                             BRIDGE_STATE       <= BS1;
                                                         
                    when BS1 =>
                    
                            BRIDGE_STATE  <= BS2;
                            MEMLOC        <= MEMLOC + 1;
                            wea           <= '0';
                            REDIST_NMODEL_PORTB_TKOVER <= '0';
                               
                    when BS2 =>
                    
                            BRIDGE_STATE  <= SWAP;
                            
                    when BS3 =>
                    
                            BRIDGE_STATE  <= LEARNING_PARAM_FETCH;
                            LEARN_RST     <= '0';

                    when SHAPEUP =>
                    
                             BRIDGE_STATE  <= LOAD_NEURON;
                             NMC_COLD_START <= '0';
                             TWOCYCLES <= 0;
                             
                    when LEARNING_PARAM_FETCH =>  
                    
                             HALT_HYPERCOLUMN <= '1';
                             NMC_STATE_RST    <= '1';
                             LEARN_RST        <= '1';
                             SYNMEM_PORTA_MUX <= '1';
                             wea          <= '0';

                        if    DTYPE = SYNLOW       then
                        
                                SYNAPSE_LOW_ADDRESS       <= to_integer(unsigned(douta(15 downto 0)));

                                if(TWOCYCLES = 1) then
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;

                        elsif DTYPE = SSSDSYNHIGH  then
                        
                                SYNAPSE_HIGH_ADDRESS      <= to_integer(unsigned(douta(15 downto 0)));
  
                                if(TWOCYCLES = 1) then
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;
                                
                        elsif DTYPE = REFPLST          then
                        
                                NEURON_SPK_TIME    <= douta(7  downto  0);

                                if(TWOCYCLES = 1) then
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;
                                
                                
                        elsif DTYPE = ULEARNPARAMS then
                                
                                SYNAPSE_PRUN               <= douta(26);
                                PRUN_THRESH                <= douta(7 downto  0);
                                IGNORE_ZEROS               <= douta(25);
                                IGNORE_SOFTLIM             <= douta(24);  
                                NEURON_WMAX                <= douta(23 downto 16);
                                NEURON_WMIN                <= douta(15 downto  8);
        
                                if(TWOCYCLES = 1) then
                                    MEMLOC           <= MEMLOC + 1;
                                    TWOCYCLES        <= 0;
                                    LEARN_RST        <= '0';
                                    SYNAPSE_LOCATION <= SYNAPSE_LOW_ADDRESS;
                                    SYNAPSE_LOCATION_PAST_2   <= SYNAPSE_LOW_ADDRESS;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                    LEARN_RST <= '1';
                                    
                                end if;
                                
                        elsif DTYPE = ENDFLOW      then
          
                                NEXTINLINE          <= douta(2 downto 0);
                                NMODEL_NPARAM_DATA  <= (others=>'0');
                                NMODEL_NPARAM_ADDR  <= (others=>'0');
                                BRIDGE_STATE        <= UPDATE_SYNAPSES;
                                LEARN_RST           <= '0';                                                            
                        else

                                if(TWOCYCLES = 1) then
                                    MEMLOC      <= MEMLOC + 1;
                                    TWOCYCLES   <= 0;
                                else
                                
                                    TWOCYCLES <= TWOCYCLES + 1;
                                end if;  
                                                              
                        end if;                       
                                 
                    when POSTSYNDLY1 =>  
                    
                         BRIDGE_STATE     <= POSTSYNDLY2;
                         POSTSYNDLYCNTR   <= 0;

                    when POSTSYNDLY2 =>  
                                             
                         ACTVATE_LENGINE <= '0';
                         TWOCYCLES       <=  0;
                         
                         if(POSTSYNDLYCNTR = 12) then
                                                          
                             if(NEXTINLINE = "000") then
                             
                                BRIDGE_STATE  <= UPDATE_TIMESTEP;                             
                             
                             elsif(NEXTINLINE = "001") then
                             
                                MEMLOC        <= MEMLOC + 1;
                                BRIDGE_STATE  <= BS3;

                             elsif(NEXTINLINE = "010") then
                             
                                SYNMEM_PORTA_MUX <= '0';
                                BRIDGE_STATE     <= UPDATE_TIMESTEP;
                                MEMLOC           <= 0;
                                ACTVATE_LENGINE  <= '0';

                             end if;                            

                         else
                         
                            POSTSYNDLYCNTR <= POSTSYNDLYCNTR + 1;
                         
                         end if;

                    when UPDATE_SYNAPSES =>  
                    
                        if(TWOCYCLES = 2) then
                        
                             ACTVATE_LENGINE <= '1';
                             
                        else
                         
                             TWOCYCLES <= TWOCYCLES + 1;
                        
                        end if;  
                    
            
                        if SYNAPSE_LOCATION = SYNAPSE_HIGH_ADDRESS then 
                        
                             BRIDGE_STATE     <= POSTSYNDLY1;
      
                        else
                                                
                            SYNAPSE_LOCATION    <= SYNAPSE_LOCATION + 1;
                            SYNAPTIC_MEM_ENABLE <= '1';
                            
                        end if;
                                                                              
                    
                    when UPDATE_TIMESTEP =>
                    
                         CYCLE_COMPLETED <= '1';       
                    
                    when others =>
                                    NULL;

                end case;

            end if;
            
        end if;

end process MSM;

end crush_with_eyeliner;
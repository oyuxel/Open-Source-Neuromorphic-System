library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BRIDGE_TB is
    Generic (
        NEURAL_MEM_DEPTH  : integer := 2048;    
        SYNAPSE_MEM_DEPTH : integer := 4096;
        ROW               : integer := 32  ;
        RAM_PERFORMANCE : string    := "LOW_LATENCY"                 
        );
end BRIDGE_TB;

architecture animal of BRIDGE_TB is

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

component BRIDGE is
    Generic (
        NEURAL_MEM_DEPTH  : integer := 2048;    
        SYNAPSE_MEM_DEPTH : integer := 2048;
        ROW               : integer := 16                
        );
    Port(
        BRIDGE_CLK                 : in  std_logic;
        BRIDGE_RST                 : in  std_logic;
        -- BRIDGE CONTROLS
        EVENT_DETECT               : in  std_logic;
        -- SPIKE SOURCE
        MAIN_SPIKE_BUFFER          : out std_logic;
        AUXILLARY_SPIKE_BUFFER     : out std_logic;
        -- SPIKE DESTINATION
        OUTBUFFER                  : out std_logic;
        AUXBUFFER                  : out std_logic;
        -- SYNAPTIC MEMORY CONTROLS (PORT B)
        SYNAPTIC_MEM_RDADDR        : out std_logic_vector(31 downto 0);
        SYNAPTIC_MEM_ENABLE        : out std_logic;
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

component AUTO_RAM_INSTANCE is
generic (
    RAM_WIDTH       : integer := 32;                      -- Specify RAM data width
    RAM_DEPTH       : integer := 2048  ;            -- Specify RAM depth (number of entries)
    RAM_PERFORMANCE : string  := "LOW_LATENCY"      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
);

port (
        addra : in  std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        addrb : in  std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        dina  : in  std_logic_vector(RAM_WIDTH-1 downto 0);		  -- Port A RAM input data
        dinb  : in  std_logic_vector(RAM_WIDTH-1 downto 0);		  -- Port B RAM input data
        clka  : in  std_logic;                       			  -- Port A Clock
        clkb  : in  std_logic;                       			  -- Port B Clock
        wea   : in  std_logic;                       			  -- Port A Write enable
        web   : in  std_logic;                       			  -- Port B Write enable
        ena   : in  std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        enb   : in  std_logic;                       			  -- Port B RAM Enable, for additional power savings, disable port when not in use
        rsta  : in  std_logic;                       			  -- Port A Output reset (does not affect memory contents)
        rstb  : in  std_logic;                       			  -- Port B Output reset (does not affect memory contents)
        regcea: in  std_logic;                       			  -- Port A Output register enable
        regceb: in  std_logic;                       			  -- Port B Output register enable
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0);   			  --  Port A RAM output data
        doutb : out std_logic_vector(RAM_WIDTH-1 downto 0)   			  --  Port B RAM output data
    );

end component AUTO_RAM_INSTANCE;

        signal BRIDGE_CLK                 :  std_logic := '1';
        signal BRIDGE_RST                 :  std_logic := '0';
        -- BRIDGE CONTROLS
        signal EVENT_DETECT               :  std_logic:= '0';
        -- SPIKE SOURCE
        signal MAIN_SPIKE_BUFFER          :  std_logic:= '0';
        signal AUXILLARY_SPIKE_BUFFER     :  std_logic:= '0';
        -- SPIKE DESTINATION
        signal OUTBUFFER                  :  std_logic:= '0';
        signal AUXBUFFER                  :  std_logic:= '0';
        -- SYNAPTIC MEMORY CONTROLS (PORT B)
        signal SYNAPTIC_MEM_RDADDR        :  std_logic_vector(31 downto 0) := (others=>'0');
        signal SYNAPTIC_MEM_ENABLE        :  std_logic:= '0';
        -- HYPERCOLUMN CONTROLS
        signal HALT_HYPERCOLUMN           :  std_logic:= '0';
        signal PRE_SYN_DATA_PULL          :  std_logic:= '0';
        -- NMC CONTROLS
        signal NMC_STATE_RST              :  std_logic:= '0'; 
        signal NMC_FMAC_RST               :  std_logic:= '0'; 
        signal NMC_COLD_START             :  std_logic:= '0'; 
        signal NMODEL_LAST_SPIKE_TIME     :  STD_LOGIC_VECTOR(7  DOWNTO 0):= (others=>'0'); 
        signal NMODEL_SYN_QFACTOR         :  STD_LOGIC_VECTOR(15 DOWNTO 0):= (others=>'0'); 
        signal NMODEL_PF_LOW_ADDR         :  STD_LOGIC_VECTOR(9  DOWNTO 0):= (others=>'0'); 
        signal NMODEL_NPARAM_DATA         :  STD_LOGIC_VECTOR(15 DOWNTO 0):= (others=>'0');
        signal NMODEL_NPARAM_ADDR         :  STD_LOGIC_VECTOR(9  DOWNTO 0):= (others=>'0');
        signal NMODEL_REFRACTORY_DUR      :  std_logic_vector(7  downto 0):= (others=>'0');
        signal NMODEL_PROG_MEM_PORTA_EN   :  STD_LOGIC:= '0';
        signal NMODEL_PROG_MEM_PORTA_WEN  :  STD_LOGIC:= '0';
        signal R_NNMODEL_NEW_SPIKE_TIME   :  std_logic_vector(7  downto 0):= (others=>'0');
        signal R_NMODEL_NPARAM_DATAOUT    :  STD_LOGIC_VECTOR(15 DOWNTO 0):= (others=>'0');
        signal R_NMODEL_REFRACTORY_DUR    :  std_logic_vector(7  downto 0):= (others=>'0');
        signal REDIST_NMODEL_PORTB_TKOVER :  std_logic:= '0';
        signal REDIST_NMODEL_DADDR        :  std_logic_vector(9 downto 0):= (others=>'0');
        signal NMC_NMODEL_FINISHED        :  std_logic:= '0';
        -- ULEARN CONTROLS
        signal ACTVATE_LENGINE            :  std_logic:= '0';
        signal LEARN_RST                  :  std_logic:= '0';
        signal SYNAPSE_PRUN               :  std_logic:= '0';
        signal PRUN_THRESH                :  std_logic_vector(7 downto 0):= (others=>'0');
        signal IGNORE_ZEROS               :  std_logic:= '0'; 
        signal IGNORE_SOFTLIM             :  std_logic:= '0';  
        signal NEURON_WMAX                :  std_logic_vector(7 downto 0):= (others=>'0');
        signal NEURON_WMIN                :  std_logic_vector(7 downto 0):= (others=>'0');
        signal NEURON_SPK_TIME            :  std_logic_vector(7 downto 0):= (others=>'0');
        -- NEURAL MEMORY INTERFACE
        signal addra                      :  std_logic_vector((clogb2(NEURAL_MEM_DEPTH)-1) downto 0):= (others=>'0'); 
        signal wea                        :  std_logic:= '0';	                
        signal ena                        :  std_logic:= '0';                       			     
        signal rsta                       :  std_logic:= '0';                       			     
        signal douta                      :  std_logic_vector(31 downto 0):= (others=>'0');            
        signal dina                       :  std_logic_vector(31 downto 0):= (others=>'0');   
        -- NEURAL MEMORY INTERFACE
        
        signal NEURAL_addra : std_logic_vector((clogb2(NEURAL_MEM_DEPTH)-1) downto 0) := (others=>'0');  
        signal NEURAL_addrb : std_logic_vector((clogb2(NEURAL_MEM_DEPTH)-1) downto 0) := (others=>'0');  
        signal NEURAL_dina  : std_logic_vector(31 downto 0) := (others=>'0');		              
        signal NEURAL_dinb  : std_logic_vector(31 downto 0) := (others=>'0');		                                  			                      			      
        signal NEURAL_wea   : std_logic := '0';                    
        signal NEURAL_web   : std_logic := '0';                    
        signal NEURAL_ena   : std_logic := '0';                       			      
        signal NEURAL_enb   : std_logic := '0';                       			      
        signal NEURAL_rsta  : std_logic := '0';                       			      
        signal NEURAL_rstb  : std_logic := '0';                       			      
        signal NEURAL_regcea: std_logic := '0';                       			      
        signal NEURAL_regceb: std_logic := '0';                       			      
        signal NEURAL_douta : std_logic_vector(31  downto 0) := (others=>'0');                   
        signal NEURAL_doutb : std_logic_vector(31  downto 0) := (others=>'0');   	    
           
        -- SYNAPSE MEMORY INTERFACE
        
        signal SYNAPSE_addra : std_logic_vector((clogb2(SYNAPSE_MEM_DEPTH)-1) downto 0) := (others=>'0');  
        signal SYNAPSE_addrb : std_logic_vector((clogb2(SYNAPSE_MEM_DEPTH)-1) downto 0) := (others=>'0');  
        signal SYNAPSE_dina  : std_logic_vector(15 downto 0) := (others=>'0');		              
        signal SYNAPSE_dinb  : std_logic_vector(15 downto 0) := (others=>'0');		                                  			                      			      
        signal SYNAPSE_wea   : std_logic := '0';                    
        signal SYNAPSE_web   : std_logic := '0';                    
        signal SYNAPSE_ena   : std_logic := '0';                       			      
        signal SYNAPSE_enb   : std_logic := '0';                       			      
        signal SYNAPSE_rsta  : std_logic := '0';                       			      
        signal SYNAPSE_rstb  : std_logic := '0';                       			      
        signal SYNAPSE_regcea: std_logic := '0';                       			      
        signal SYNAPSE_regceb: std_logic := '0';                       			      
        signal SYNAPSE_douta : std_logic_vector(15  downto 0) := (others=>'0');                   
        signal SYNAPSE_doutb : std_logic_vector(15  downto 0) := (others=>'0');   
        constant CLKPERIOD : time := 10 ns;       
     
        constant SYNLOW               : std_logic_vector(3 downto 0) := "0001";
        constant SSSDSYNHIGH          : std_logic_vector(3 downto 0) := "0010";
        constant LST                  : std_logic_vector(3 downto 0) := "0011";
        constant PFLOWSYNQ            : std_logic_vector(3 downto 0) := "0100";
        constant ULEARNPARAMS         : std_logic_vector(3 downto 0) := "0101";
        constant REFP                 : std_logic_vector(3 downto 0) := "0110";
        constant NPARAMADDR           : std_logic_vector(3 downto 0) := "0111";
        constant NPARAMDATA           : std_logic_vector(3 downto 0) := "1000";
        constant ENDFLOW              : std_logic_vector(3 downto 0) := "1001";
       
begin

        BRIDGE_CLK <= not BRIDGE_CLK after CLKPERIOD/2;

BRIDGE_INST: BRIDGE 
    Generic Map(
        NEURAL_MEM_DEPTH =>  NEURAL_MEM_DEPTH , 
        SYNAPSE_MEM_DEPTH =>  SYNAPSE_MEM_DEPTH ,  
        ROW       =>  ROW             
        )
    Port Map(
        BRIDGE_CLK                 =>  BRIDGE_CLK                 ,
        BRIDGE_RST                 =>  BRIDGE_RST                 ,
        EVENT_DETECT               =>  EVENT_DETECT               ,
        MAIN_SPIKE_BUFFER          =>  MAIN_SPIKE_BUFFER          ,
        AUXILLARY_SPIKE_BUFFER     =>  AUXILLARY_SPIKE_BUFFER     ,
        OUTBUFFER                  =>  OUTBUFFER                  ,
        AUXBUFFER                  =>  AUXBUFFER                  ,
        SYNAPTIC_MEM_RDADDR        =>  SYNAPTIC_MEM_RDADDR        ,
        SYNAPTIC_MEM_ENABLE        =>  SYNAPTIC_MEM_ENABLE        ,
        HALT_HYPERCOLUMN           =>  HALT_HYPERCOLUMN           ,
        PRE_SYN_DATA_PULL          =>  PRE_SYN_DATA_PULL          ,
        NMC_STATE_RST              =>  NMC_STATE_RST              ,
        NMC_FMAC_RST               =>  NMC_FMAC_RST               ,
        NMC_COLD_START             =>  NMC_COLD_START             ,
        NMODEL_LAST_SPIKE_TIME     =>  NMODEL_LAST_SPIKE_TIME     ,
        NMODEL_SYN_QFACTOR         =>  NMODEL_SYN_QFACTOR         ,
        NMODEL_PF_LOW_ADDR         =>  NMODEL_PF_LOW_ADDR         ,
        NMODEL_NPARAM_DATA         =>  NMODEL_NPARAM_DATA         ,
        NMODEL_NPARAM_ADDR         =>  NMODEL_NPARAM_ADDR         ,
        NMODEL_REFRACTORY_DUR      =>  NMODEL_REFRACTORY_DUR      ,
        NMODEL_PROG_MEM_PORTA_EN   =>  NMODEL_PROG_MEM_PORTA_EN   ,
        NMODEL_PROG_MEM_PORTA_WEN  =>  NMODEL_PROG_MEM_PORTA_WEN  ,
        R_NNMODEL_NEW_SPIKE_TIME   =>  R_NNMODEL_NEW_SPIKE_TIME   ,
        R_NMODEL_NPARAM_DATAOUT    =>  R_NMODEL_NPARAM_DATAOUT    ,
        R_NMODEL_REFRACTORY_DUR    =>  R_NMODEL_REFRACTORY_DUR    ,
        REDIST_NMODEL_PORTB_TKOVER =>  REDIST_NMODEL_PORTB_TKOVER ,
        REDIST_NMODEL_DADDR        =>  REDIST_NMODEL_DADDR        ,
        NMC_NMODEL_FINISHED        =>  NMC_NMODEL_FINISHED        ,
        ACTVATE_LENGINE            =>  ACTVATE_LENGINE            ,
        LEARN_RST                  =>  LEARN_RST                  ,
        SYNAPSE_PRUN               =>  SYNAPSE_PRUN               ,
        PRUN_THRESH                =>  PRUN_THRESH                ,
        IGNORE_ZEROS               =>  IGNORE_ZEROS               ,
        IGNORE_SOFTLIM             =>  IGNORE_SOFTLIM             ,
        NEURON_WMAX                =>  NEURON_WMAX                ,
        NEURON_WMIN                =>  NEURON_WMIN                ,
        NEURON_SPK_TIME            =>  NEURON_SPK_TIME            ,
        addra                      =>  NEURAL_addra               ,
        wea                        =>  NEURAL_wea                 ,
        ena                        =>  NEURAL_ena                 ,
        rsta                       =>  NEURAL_rsta                ,
        douta                      =>  NEURAL_douta               ,
        dina                       =>  NEURAL_dina                       
        );

NEURAL_MEMORY: AUTO_RAM_INSTANCE 
generic map(
    RAM_WIDTH       => 32,
    RAM_DEPTH       => NEURAL_MEM_DEPTH      ,
    RAM_PERFORMANCE => RAM_PERFORMANCE
    )
port map(
        addra  => NEURAL_addra ,
        addrb  => NEURAL_addrb ,
        dina   => NEURAL_dina  ,
        dinb   => NEURAL_dinb  ,
        clka   => BRIDGE_CLK  ,
        clkb   => BRIDGE_CLK  ,
        wea    => NEURAL_wea   ,
        web    => NEURAL_web   ,
        ena    => NEURAL_ena   ,
        enb    => NEURAL_enb   ,
        rsta   => NEURAL_rsta  ,
        rstb   => NEURAL_rstb  ,
        regcea => NEURAL_regcea,
        regceb => NEURAL_regceb,
        douta  => NEURAL_douta ,
        doutb  => NEURAL_doutb 
    );


SYNAPSE_MEMORY: AUTO_RAM_INSTANCE 
generic map(
    RAM_WIDTH       => 16,
    RAM_DEPTH       => SYNAPSE_MEM_DEPTH      ,
    RAM_PERFORMANCE => RAM_PERFORMANCE
    )
port map(
        addra  => SYNAPSE_addra ,
        addrb  => SYNAPSE_addrb ,
        dina   => SYNAPSE_dina  ,
        dinb   => SYNAPSE_dinb  ,
        clka   => BRIDGE_CLK  ,
        clkb   => BRIDGE_CLK  ,
        wea    => SYNAPSE_wea   ,
        web    => SYNAPSE_web   ,
        ena    => SYNAPSE_ena   ,
        enb    => SYNAPSE_enb   ,
        rsta   => SYNAPSE_rsta  ,
        rstb   => SYNAPSE_rstb  ,
        regcea => SYNAPSE_regcea,
        regceb => SYNAPSE_regceb,
        douta  => SYNAPSE_douta ,
        doutb  => SYNAPSE_doutb 
    );
    
process begin


    BRIDGE_RST <= '0';
    wait for CLKPERIOD;
    BRIDGE_RST <= '1';
    wait for 50*CLKPERIOD;
    BRIDGE_RST <= '0';
          
    wait for CLKPERIOD;  
    
    SYNAPSE_ena <= '0';
    SYNAPSE_wea <= '0';
    
    SYNAPSE_rsta <= '1';    
    wait for CLKPERIOD;  
    SYNAPSE_rsta <= '0';  
    wait for 10*CLKPERIOD; 
     
    for m in 0 to 31 loop
    
        for i in 0 to 127 loop
            
            SYNAPSE_ena <= '1';
            SYNAPSE_wea <= '1';
            
            SYNAPSE_dina(15 downto 8) <= std_logic_vector(to_unsigned(i,SYNAPSE_dina'length/2));
            SYNAPSE_dina(7  downto 0) <= std_logic_vector(to_unsigned(i,SYNAPSE_dina'length/2));
            SYNAPSE_addra  <= std_logic_vector(to_unsigned(i+128*m,SYNAPSE_addra'length));
            wait for CLKPERIOD; 
             
        end loop;
        
    end loop;
    
    SYNAPSE_ena <= '0';
    SYNAPSE_wea <= '0';
    
    wait for CLKPERIOD;  
    
    
    for k in 0 to 31 loop
        
        NEURAL_enb       <= '1';
        NEURAL_web       <= '1';


        NEURAL_dinb(31 downto 28)  <= SYNLOW;
        NEURAL_dinb(27 downto 16)  <= (others=>'0');
        NEURAL_dinb(15 downto  0)  <= std_logic_vector(to_unsigned(0,16));
        NEURAL_addrb <= std_logic_vector(to_unsigned(0+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= SSSDSYNHIGH  ;
        NEURAL_dinb(27 downto 18)  <= (others=>'0');
        NEURAL_dinb(17)            <= '0'  ;
        NEURAL_dinb(16)            <= '1'  ;
        NEURAL_dinb(15 downto 0)   <= std_logic_vector(to_unsigned(k+127,16)) ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(1+k*10,NEURAL_addrb'length));    

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= LST          ;
        NEURAL_dinb(27 downto  8)  <= (others=>'0');
        NEURAL_dinb(7 downto   0)  <= X"FF"          ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(2+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= PFLOWSYNQ    ;
        NEURAL_dinb(27 downto 26)  <= (others=>'0');
        NEURAL_dinb(25 downto 16)  <= std_logic_vector(to_unsigned(542,10))    ;
        NEURAL_dinb(15 downto  0)  <= X"2004"      ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(3+k*10,NEURAL_addrb'length));  

        wait for CLKPERIOD; 
          
        NEURAL_dinb(31 downto 28)  <= ULEARNPARAMS ;
        NEURAL_dinb(27)            <= '0'     ;
        NEURAL_dinb(26)            <= '0'     ;
        NEURAL_dinb(25)            <= '0'     ;
        NEURAL_dinb(24)            <= '0'     ;
        NEURAL_dinb(23 downto 16)  <= std_logic_vector(to_signed(127,8)) ;
        NEURAL_dinb(15 downto  8)  <= std_logic_vector(to_signed(-128,8)) ;
        NEURAL_dinb(7  downto  0)  <= std_logic_vector(to_signed(-12,8)) ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(4+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= REFP         ;
        NEURAL_dinb(27 downto 8)   <= (others=>'0')         ;
        NEURAL_dinb(7  downto 0)   <= X"FF"  ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(5+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= NPARAMADDR   ;
        NEURAL_dinb(27 downto 10)  <= (others=>'0')   ;
        NEURAL_dinb(9  downto  0)  <= std_logic_vector(to_unsigned(768+44,10))   ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(6+k*10,NEURAL_addrb'length));    

        wait for CLKPERIOD; 
            
        NEURAL_dinb(31 downto 28)  <= NPARAMDATA   ;
        NEURAL_dinb(27 downto  0)  <= (others=>'0')     ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(7+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= NPARAMADDR   ;
        NEURAL_dinb(27 downto 10)  <= (others=>'0')   ;
        NEURAL_dinb(9  downto  0)  <= std_logic_vector(to_unsigned(768+46,10))   ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(8+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
        NEURAL_dinb(31 downto 28)  <= NPARAMDATA   ;
        NEURAL_dinb(27 downto  0)  <= (others=>'0')     ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(9+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD;  
        
        NEURAL_dinb(31 downto 28)  <= ENDFLOW      ;
        NEURAL_dinb(27 downto 16)  <= (others=>'0')      ;
        NEURAL_dinb(15 downto  0)  <= X"0001"      ;
        NEURAL_addrb <= std_logic_vector(to_unsigned(10+k*10,NEURAL_addrb'length));

        wait for CLKPERIOD; 
        
    end loop;
        
        NEURAL_addrb  <= std_logic_vector(to_unsigned(321,NEURAL_addrb'length));
        NEURAL_dinb(31 downto 28) <= ENDFLOW;
        NEURAL_dinb(27 downto 16) <= (others=>'0');
        NEURAL_dinb(15  downto 0) <= X"0002";

        wait for CLKPERIOD;
        
        NEURAL_addrb  <= std_logic_vector(to_unsigned(322,NEURAL_addrb'length));
        NEURAL_dinb(31 downto 28) <= ENDFLOW;
        NEURAL_dinb(27 downto 16) <= (others=>'0');
        NEURAL_dinb(15  downto 0) <= X"0003";

        wait for CLKPERIOD;
        
        NEURAL_enb     <= '0';
        NEURAL_web     <= '0';

        
        wait for 100*CLKPERIOD;
        BRIDGE_RST <= '0';
        wait for CLKPERIOD;
        BRIDGE_RST <= '1';
        wait for 50*CLKPERIOD;
        BRIDGE_RST <= '0';

        wait for 500*CLKPERIOD;
    
    assert false report "Test: OK" severity failure;

end process;

end animal;

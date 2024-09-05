library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.crossbar_utils.all;
use work.crossbar_primitives.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_CROSSBAR_FABRIC is
    Generic(
            ROW                : integer := 32   ;
            COLUMN             : integer := 32   ;
            SYNAPSE_MEM_DEPTH  : integer := 2048
            );
end TB_CROSSBAR_FABRIC;

architecture tao of TB_CROSSBAR_FABRIC is

component CROSSBAR_FABRIC is
    Generic(
            ROW                : integer := 32   ;
            COLUMN             : integer := 4    ;
            SYNAPSE_MEM_DEPTH  : integer := 2048

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

            signal CB_CLK                        : std_logic := '1';
            signal CB_VECTOR_RST                 : std_logic_vector(0 to COLUMN-1) := (others=>'0');
            signal SPIKE_IN                      : std_logic_vector(ROW-1 downto 0):= (others=>'0');
            signal SPIKE_VLD                     : std_logic := '0';
            signal COLUMN_PRE_SYNAPTIC_DIN       : SYNAPTIC_DATA(0 to COLUMN-1):= (others=>(others=>'0'));
            signal COLUMN_SYNAPSE_START_ADDRESS  : SYNAPSE_ADDRESS(0 to COLUMN-1)(clogb2(SYNAPSE_MEM_DEPTH)-1 downto 0):= (others=>(others=>'0'));
            signal PRE_SYN_DATA_PULL             : std_logic_vector(0 to COLUMN-1):= (others=>'0');
            signal COLN_SYN_SUM_OUT              : SYNAPTIC_SUM(0 to COLUMN-1);
            signal COLN_VECTOR_SYN_SUM_VALID     : std_logic_vector(0 to COLUMN-1);
            signal COLUMN_POST_SYNAPTIC_DOUT     : SYNAPTIC_DATA(0 to COLUMN-1);
            signal COLUMN_SYNAPSE_WR_ADDRESS     : SYNAPSE_ADDRESS(0 to COLUMN-1)(clogb2(SYNAPSE_MEM_DEPTH)-1 downto 0);
            signal COLUMN_POST_SYNAPTIC_WREN     : std_logic_vector(0 to COLUMN-1);
            constant CLKPERIOD                   : time := 10 ns;

begin


    process begin
    
    wait for 10*CLKPERIOD;    
    CB_VECTOR_RST <= (others=>'1');
    wait for 10*CLKPERIOD;
    CB_VECTOR_RST <= (others=>'0');
    wait ;
    
    end process;
    
    INJECT_SYNAPSES : for i in 0 to COLUMN-1 generate
    
        process begin
        
            wait for 50*CLKPERIOD;    
            PRE_SYN_DATA_PULL(i) <= '1';
            wait for 2*CLKPERIOD;
                for k in 1 to ROW loop
                    COLUMN_PRE_SYNAPTIC_DIN(i) <= std_logic_vector(to_unsigned(k,8)) &  std_logic_vector(to_unsigned(k,8));
                    wait for CLKPERIOD;
                    
                    if(k = ROW-2) then
                    
                            PRE_SYN_DATA_PULL(i)       <= '0';     
                            
                    end if;
                    
                end loop;
        
        wait for CLKPERIOD;   
        COLUMN_PRE_SYNAPTIC_DIN(i) <= (others=>'0');
        
        
        wait for 10*CLKPERIOD;
   
        SPIKE_IN  <= (others=>'1');
        SPIKE_VLD <= '1';
        
        wait for CLKPERIOD;
    
        SPIKE_IN  <= (others=>'0');
        SPIKE_VLD <= '0';
         
        wait for 50*CLKPERIOD;    
            PRE_SYN_DATA_PULL(i) <= '1';
            wait for 2*CLKPERIOD;
                for k in 1 to ROW loop
                
                    COLUMN_SYNAPSE_START_ADDRESS(k-1) <= std_logic_vector(to_unsigned(32,clogb2(SYNAPSE_MEM_DEPTH)));
                    COLUMN_PRE_SYNAPTIC_DIN(i) <= std_logic_vector(to_unsigned(k+15,8)) &  std_logic_vector(to_unsigned(k+15,8));
                    wait for CLKPERIOD;
                    
                    if(k = ROW-2) then
                    
                            PRE_SYN_DATA_PULL(i)       <= '0';     
                            
                    end if;
                    
                end loop;
        
        wait for CLKPERIOD;   
        COLUMN_PRE_SYNAPTIC_DIN(i) <= (others=>'0');
        
        
        wait for 10*CLKPERIOD;
   
        SPIKE_IN  <= (others=>'1');
        SPIKE_VLD <= '1';
        
        wait for CLKPERIOD;
    
        SPIKE_IN  <= (others=>'0');
        SPIKE_VLD <= '0'; 
         
      
        wait for 50*CLKPERIOD;    
            PRE_SYN_DATA_PULL(i) <= '1';
            wait for 2*CLKPERIOD;
                for k in 1 to ROW loop
                
                    COLUMN_SYNAPSE_START_ADDRESS(k-1) <= std_logic_vector(to_unsigned(64,clogb2(SYNAPSE_MEM_DEPTH)));
                    COLUMN_PRE_SYNAPTIC_DIN(i) <= std_logic_vector(to_unsigned(k+64,8)) &  std_logic_vector(to_unsigned(k+64,8));
                    wait for CLKPERIOD;
                    
                    if(k = ROW-2) then
                    
                            PRE_SYN_DATA_PULL(i)       <= '0';     
                            
                    end if;
                    
                end loop;
        
        wait for CLKPERIOD;   
        COLUMN_PRE_SYNAPTIC_DIN(i) <= (others=>'0');
        
        
        wait for 10*CLKPERIOD;
   
        SPIKE_IN  <= (others=>'1');
        SPIKE_VLD <= '1';
        
        wait for CLKPERIOD;
    
        SPIKE_IN  <= (others=>'0');
        SPIKE_VLD <= '0'; 

          
        wait;
        
        end process ;  

    end generate INJECT_SYNAPSES;



CB_CLK <= not CB_CLK after CLKPERIOD/2;

DUT : CROSSBAR_FABRIC
    Generic Map(
            ROW                => ROW               ,
            COLUMN             => COLUMN            ,
            SYNAPSE_MEM_DEPTH  => SYNAPSE_MEM_DEPTH 
            )
    Port Map (
            CB_CLK                       => CB_CLK                         ,
            CB_VECTOR_RST                => CB_VECTOR_RST                  ,
            SPIKE_IN                     => SPIKE_IN                       ,
            SPIKE_VLD                    => SPIKE_VLD                      ,
            COLUMN_PRE_SYNAPTIC_DIN      => COLUMN_PRE_SYNAPTIC_DIN        ,
            COLUMN_SYNAPSE_START_ADDRESS => COLUMN_SYNAPSE_START_ADDRESS   ,
            PRE_SYN_DATA_PULL            => PRE_SYN_DATA_PULL              ,
            COLN_SYN_SUM_OUT             => COLN_SYN_SUM_OUT               ,
            COLN_VECTOR_SYN_SUM_VALID    => COLN_VECTOR_SYN_SUM_VALID      ,
            COLUMN_POST_SYNAPTIC_DOUT    => COLUMN_POST_SYNAPTIC_DOUT      ,
            COLUMN_SYNAPSE_WR_ADDRESS    => COLUMN_SYNAPSE_WR_ADDRESS      ,
            COLUMN_POST_SYNAPTIC_WREN    => COLUMN_POST_SYNAPTIC_WREN      
        );

end tao;

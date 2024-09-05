library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ULEARNNOBOUND_tb is
end ULEARNNOBOUND_tb;

architecture Behavioral of ULEARNNOBOUND_tb is

    -- Component Declaration for the Unit Under Test (UUT)
    component ULEARN_SINGLE is
        Generic(LUT_TYPE : string := "distributed");
        Port 
        ( 
        ULEARN_RST           : in  std_logic;
        ULEARN_CLK           : in  std_logic;
        -- SYNAPTIC FIFO PORT
        SYN_DATA_IN          : in  std_logic_vector(15 downto 0);
        SYN_DIN_VLD          : in  std_logic;
        SYN_DATA_OUT         : out std_logic_vector(15 downto 0);
        SYN_DOUT_VLD         : out std_logic;
        -- CONTROL SIGNALS
        SYNAPSE_PRUNING      : in  std_logic;
        PRUN_THRESHOLD       : in  std_logic_vector(7 downto 0);
        IGNORE_ZERO_SYNAPSES : in  std_logic;  -- EXPERIMENTAL, CAREFUL WITH THIS.
        IGNORE_SOFTLIMITS    : in  std_logic;  -- EXPERIMENTAL, CAREFUL WITH THIS.
        -- AXI4 LITE INTERFACE PORTS
        ULEARN_LUT_DIN       : in  std_logic_vector(7 downto 0);
        ULEARN_LUT_ADDR      : in  std_logic_vector(7 downto 0);
        ULEARN_LUT_EN        : in  std_logic;
        -- PARAMETERS
        NMODEL_WMAX          : in  std_logic_vector(7 downto 0);
        NMODEL_WMIN          : in  std_logic_vector(7 downto 0);
        -- NMC PORTS
        NMODEL_SPIKE_TIME    : in  std_logic_vector(7 downto 0)

        );
    end component ULEARN_SINGLE;

    -- Signals for stimulus
    signal ULEARN_RST           : std_logic := '0';
    signal ULEARN_CLK           : std_logic := '1';
    signal SYN_DATA_IN          : std_logic_vector(15 downto 0) := (others => '0');
    signal SYN_DATA_OUT         : std_logic_vector(15 downto 0) := (others => '0');
    signal SYNAPSE_PRUNING      : std_logic:= '1';
    signal SYN_DIN_VLD          : std_logic:= '0';
    signal SYN_DOUT_VLD         : std_logic:= '0';
    signal PRUN_THRESHOLD       : std_logic_vector(7 downto 0)  := std_logic_vector(to_signed(-42,8));
    signal IGNORE_ZERO_SYNAPSES : std_logic:= '1';  -- EXPERIMENTAL, CAREFUL WITH THIS.
    signal IGNORE_SOFTLIMITS    : std_logic:= '0';  -- EXPERIMENTAL, CAREFUL WITH THIS.
    signal ULEARN_LUT_DIN       : std_logic_vector(7 downto 0) := (others => '0');
    signal ULEARN_LUT_ADDR      : std_logic_vector(7 downto 0) := (others => '0');
    signal ULEARN_LUT_EN        : std_logic := '0';
    signal NMODEL_3_WMAX        : std_logic_vector(7 downto 0) := std_logic_vector(to_signed(50,8));
    signal NMODEL_3_WMIN        : std_logic_vector(7 downto 0) := std_logic_vector(to_signed(-50,8));
    signal NMODEL_3_SPIKE_TIME  : std_logic_vector(7 downto 0) := std_logic_vector(to_signed(0,8));
    constant CLK_PERIOD         : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: ULEARN_SINGLE
        generic map(LUT_TYPE => "distributed")    
        port map (
            ULEARN_RST            => ULEARN_RST          ,
            ULEARN_CLK            => ULEARN_CLK          ,
            SYN_DATA_IN           => SYN_DATA_IN         , 
            SYN_DIN_VLD           => SYN_DIN_VLD         , 
            SYN_DATA_OUT          => SYN_DATA_OUT        , 
            SYN_DOUT_VLD          => SYN_DOUT_VLD        , 
            SYNAPSE_PRUNING       => SYNAPSE_PRUNING     ,
            PRUN_THRESHOLD        => PRUN_THRESHOLD      ,
            IGNORE_ZERO_SYNAPSES  => IGNORE_ZERO_SYNAPSES,
            IGNORE_SOFTLIMITS     => IGNORE_SOFTLIMITS   ,
            ULEARN_LUT_DIN        => ULEARN_LUT_DIN      ,
            ULEARN_LUT_ADDR       => ULEARN_LUT_ADDR     ,
            ULEARN_LUT_EN         => ULEARN_LUT_EN       ,
            NMODEL_WMAX           => NMODEL_3_WMAX       ,
            NMODEL_WMIN           => NMODEL_3_WMIN       ,
            NMODEL_SPIKE_TIME     => NMODEL_3_SPIKE_TIME
        );

    -- Clock generation
    ULEARN_CLK <= not ULEARN_CLK after CLK_PERIOD/2;

    -- Stimulus process
    stim_proc: process
    begin	
        -- Initialize Inputs
        
        wait for 10*CLK_PERIOD;
        
        ULEARN_RST <= '1';
        wait for CLK_PERIOD;
        ULEARN_RST <= '0';
        
        wait for 10*CLK_PERIOD;
        
        for i in 127 downto 0 loop
        
        ULEARN_LUT_DIN   <= std_logic_vector(to_unsigned(i,ULEARN_LUT_DIN'length));
        ULEARN_LUT_ADDR  <= std_logic_vector(to_unsigned(127-i,ULEARN_LUT_ADDR'length));
        ULEARN_LUT_EN    <= '1';
        wait for CLK_PERIOD;
        
        end loop;
        
        for i in 255 downto 128 loop
        
        ULEARN_LUT_DIN   <= std_logic_vector(to_unsigned(127-i,ULEARN_LUT_DIN'length));
        ULEARN_LUT_ADDR  <= std_logic_vector(to_unsigned(i,ULEARN_LUT_ADDR'length));
        ULEARN_LUT_EN    <= '1';
        wait for CLK_PERIOD;
        
        end loop;
        
        ULEARN_LUT_DIN   <= (others=>'0');
        ULEARN_LUT_ADDR  <= (others=>'0');
        ULEARN_LUT_EN    <= '0';
        
        wait for 10*CLK_PERIOD;
        
        NMODEL_3_SPIKE_TIME <= "00000000";
        
        wait for 10*CLK_PERIOD;
        SYN_DIN_VLD <= '1';
        SYN_DATA_IN(15 downto  8) <= X"12";
        SYN_DATA_IN(7 downto   0) <= X"72";
 
        wait for CLK_PERIOD;        

        SYN_DATA_IN(15 downto  8) <= X"A1";
        SYN_DATA_IN(7 downto   0) <= X"00";

        wait for CLK_PERIOD;
     

        

        SYN_DATA_IN(15 downto  8) <= X"03";
        SYN_DATA_IN(7 downto   0) <= X"03";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"04";
        SYN_DATA_IN(7 downto   0) <= X"04";
 
        wait for CLK_PERIOD;
        
        SYN_DATA_IN(15 downto  8) <= X"05";
        SYN_DATA_IN(7 downto   0) <= X"05";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"06";
        SYN_DATA_IN(7 downto   0) <= X"06";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"07";
        SYN_DATA_IN(7 downto   0) <= X"07";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"08";
        SYN_DATA_IN(7 downto   0) <= X"08";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"09";
        SYN_DATA_IN(7 downto   0) <= X"09";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0A";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0B";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0C";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0D";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0E";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0F";
 
        wait for CLK_PERIOD;
         

        SYN_DATA_IN(15 downto  8) <= X"AB";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;    
         

        SYN_DATA_IN(15 downto  8) <= X"AC";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;        
        

        SYN_DATA_IN(15 downto  8) <= X"AD";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;   
          

        SYN_DATA_IN(15 downto  8) <= X"AE";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD; 
        
                SYN_DATA_IN(15 downto  8) <= X"12";
        SYN_DATA_IN(7 downto   0) <= X"72";
 
        wait for CLK_PERIOD;        

        SYN_DATA_IN(15 downto  8) <= X"A1";
        SYN_DATA_IN(7 downto   0) <= X"00";

        wait for CLK_PERIOD;
     

        

        SYN_DATA_IN(15 downto  8) <= X"03";
        SYN_DATA_IN(7 downto   0) <= X"03";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"04";
        SYN_DATA_IN(7 downto   0) <= X"04";
 
        wait for CLK_PERIOD;
        
        SYN_DATA_IN(15 downto  8) <= X"05";
        SYN_DATA_IN(7 downto   0) <= X"05";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"06";
        SYN_DATA_IN(7 downto   0) <= X"06";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"07";
        SYN_DATA_IN(7 downto   0) <= X"07";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"08";
        SYN_DATA_IN(7 downto   0) <= X"08";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"09";
        SYN_DATA_IN(7 downto   0) <= X"09";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0A";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0B";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0C";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0D";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0E";
 
        wait for CLK_PERIOD;
        

        SYN_DATA_IN(15 downto  8) <= X"00";
        SYN_DATA_IN(7 downto   0) <= X"0F";
 
        wait for CLK_PERIOD;
         

        SYN_DATA_IN(15 downto  8) <= X"AB";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;    
         

        SYN_DATA_IN(15 downto  8) <= X"AC";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;        
        

        SYN_DATA_IN(15 downto  8) <= X"AD";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;   
          

        SYN_DATA_IN(15 downto  8) <= X"AE";
        SYN_DATA_IN(7 downto   0) <= X"00";
 
        wait for CLK_PERIOD;
        
        
        SYN_DIN_VLD <= '0'; 

        SYN_DATA_IN(15 downto  0) <= X"0000";

        wait for 20*CLK_PERIOD;
        
        -- Finish simulation
         assert false report "Test: OK" severity failure;

    end process;

end Behavioral;

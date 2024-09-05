library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SS_2_HP_tb is
end entity SS_2_HP_tb;

architecture sim of SS_2_HP_tb is

    signal CLK     : std_logic := '0';
    signal RST     : std_logic := '0';
    signal SS_IN   : std_logic_vector(15 downto 0);
    signal HP_OUT  : std_logic_vector(15 downto 0);
    signal START   : std_logic := '0';
    signal DONE    : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    UUT: entity work.SS_2_HP
        port map(
            CLK => CLK,
            RST => RST,
            SS_IN => SS_IN,
            HP_OUT => HP_OUT,
            START => START,
            DONE => DONE
        );

    CLK_process : process
    begin
        while true loop
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stimulus_process : process
    begin
        RST <= '1';
        wait for CLK_PERIOD;
        RST <= '0';

        for i in -32768 to 32767 loop
            SS_IN <= std_logic_vector(to_signed(i, 16));
            START <= '1';
            wait for CLK_PERIOD;
            START <= '0';
            wait until DONE = '1';
            wait for CLK_PERIOD;
        end loop;

        wait;
    end process;

end architecture sim;

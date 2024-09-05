library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity or_reduce is
    generic (
        N : integer := 8  
    );
    port (
        A : in  STD_LOGIC_VECTOR(N-1 downto 0);
        Y : out STD_LOGIC 
    );
end or_reduce;

architecture Behavioral of or_reduce is
    signal temp : STD_LOGIC_VECTOR(N-1 downto 0) := (others=>'0');
begin
    temp(0) <= A(0);

    gen_or: for i in 1 to N-1 generate
        temp(i) <= temp(i-1) or A(i);
    end generate gen_or;

    Y <= temp(N-1);

end Behavioral;

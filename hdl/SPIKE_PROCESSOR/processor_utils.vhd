library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package processor_utils is

type SYNAPTICMEMDATA is array (natural range <>) of std_logic_vector(15 downto 0);
type SYNAPTICMEMADDR is array (natural range <>) of std_logic_vector;

type PARAMMEMDATA is array (natural range <>) of std_logic_vector(31 downto 0);
type PARAMMEMADDR is array (natural range <>) of std_logic_vector;

type LASTSTIME      is array (natural range <>) of STD_LOGIC_VECTOR(7  DOWNTO 0);   
type SYNQFACTOR     is array (natural range <>) of STD_LOGIC_VECTOR(15 DOWNTO 0);   
type PROGRAMFLOWLOW is array (natural range <>) of STD_LOGIC_VECTOR(9  DOWNTO 0);   
type NPARAMDATA     is array (natural range <>) of STD_LOGIC_VECTOR(15 DOWNTO 0);   
type NPARAMADDR     is array (natural range <>) of STD_LOGIC_VECTOR(9  DOWNTO 0);   
type REFDURATION    is array (natural range <>) of std_logic_vector(7  downto 0);   

end processor_utils;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- Implementamos un timer
entity fsm_esclava is
port(
    CLK     : in std_logic; --se?al de reloj
    RESET   : in std_logic; --reset activo a nivel alto
    START   : in std_logic; -- se?al de inicio
    DELAY   : in unsigned (14 downto 0); -- tiempo de espera
    DONE    : out std_logic --se?al de fin
   
);
end fsm_esclava;

architecture Behavioral of fsm_esclava is
  signal cuenta : unsigned (DELAY'range);
 
begin
    process(RESET, CLK)
    begin
    if RESET = '0' then --si pulsamos el reset ponemos todo a 0
      cuenta <=(others => '0');
     
    elsif rising_edge(CLK) then
      if START ='1' then
        cuenta <= DELAY; --se carga el valor de delay en cuenta
      elsif cuenta /= 0 then
        cuenta <= cuenta -1; 
      
      end if;
    end if;
  end process; 
    DONE <= '1' when cuenta = 1 else '0'; --vale '1' cuando se ha acabado la cuenta
   
end Behavioral;

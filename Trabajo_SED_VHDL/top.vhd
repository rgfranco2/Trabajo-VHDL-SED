
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    generic (
        num_entradas:positive:=2
    );
    port(
        entradas: in std_logic_vector (num_entradas -1 downto 0);--Elección modo café
        sel_leche: in std_logic;--Selección leche
        sel_azucar: in std_logic;--Selección azúcar
        sensor: in std_logic;--Sensor vaso
        boton_inicio: in std_logic;--botón inicio
        clk_entrada: in std_logic;
        reset_global: in std_logic; --asíncrono
        led_leche: out std_logic;
        led_azucar: out std_logic;
        led_bomba: out std_logic;
        led_encendida: out std_logic;
        numero_display: out std_logic_vector(6 downto 0);
        seleccion_display : out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is

    --Generales
    constant long_opcion: positive:=4;
    constant frecuencia1: integer:=50000;--esclava
    constant frecuencia2: integer:=125000;--display
    signal clk_salida: std_logic;--esclava
    signal clk_salida2: std_logic;--display
    signal sinc_detector: std_logic;
    signal detector_fsm1: std_logic;
    signal modo_display: std_logic_vector (long_opcion -1 downto 0);
    signal start: std_logic;
    signal done: std_logic;
    signal delay : unsigned (14 downto 0);
    --Decodificador
    signal salida_disp0: std_logic_vector (6 downto 0);
    signal salida_disp1: std_logic_vector (6 downto 0);
    signal salida_disp2: std_logic_vector (6 downto 0);
    signal salida_disp3: std_logic_vector (6 downto 0);
    signal salida_disp4: std_logic_vector (6 downto 0);
    signal salida_disp5: std_logic_vector (6 downto 0);
    signal salida_disp6: std_logic_vector (6 downto 0);
    signal salida_disp7: std_logic_vector (6 downto 0);

    component divisor_frec
        generic(
            freq : integer:=50000
        );
        port (
            clk_in : in  std_logic; -- 100 MHz
            reset : in  std_logic;
            clk_out : out  std_logic
        );
    end component;
    component detector_flanco
        port (
            CLK : in std_logic;
            EDGE_IN : in std_logic;
            EDGE_OUT : out std_logic
        );
    end component;

    component sincronizador
        PORT (
            CLK : in std_logic;
            SYNC_IN : in std_logic;--Entrada sincronizador
            SYNC_OUT : out std_logic-- Salida sincornizador
        );
    end component;
    component fsm1
        port (
            RESET : in std_logic;--reset asíncrono
            CLK : in std_logic;
            EDGE : in std_logic;--Botón inicio
            MODOS : in std_logic_vector(0 TO 1);--Café corto o largo
            SEL_LECHE: in std_logic;--ELegir leche
            SEL_AZUCAR: in std_logic;--Elegir azúcar
            SENSOR: in std_logic;--Sensor vaso
            MODO_DISPLAY: out std_logic_vector(long_opcion -1 downto 0); --salida para indicarle al display que enseñe el modo
            LED_ENCENDIDA: out std_logic;
            LED_BOMBA: out std_logic;
            LED_LECHE: out std_logic;
            LED_AZUCAR: out std_logic;
            --Comunicación con la la esclava
            DONE: in std_logic;
            START: out std_logic;
            DELAY : out unsigned (14 downto 0)
        );
    end component;
    component fsm_esclava
        port (
            CLK     : in std_logic; --señal de reloj
            RESET   : in std_logic; --reset activo a nivel alto
            START   : in std_logic; -- señal de inicio
            DELAY   : in unsigned (14 downto 0); -- tiempo de espera
            DONE    : out std_logic --señal de fin
        );
    end component;
    component decodificador
        PORT (
            seleccion : in std_logic_vector(long_opcion -1 DOWNTO 0);
            salida_disp0 : out std_logic_vector(6 DOWNTO 0);
            salida_disp1 : out std_logic_vector(6 DOWNTO 0);
            salida_disp2 : out std_logic_vector(6 DOWNTO 0);
            salida_disp3 : out std_logic_vector(6 DOWNTO 0);
            salida_disp4 : out std_logic_vector(6 DOWNTO 0);
            salida_disp5 : out std_logic_vector(6 DOWNTO 0);
            salida_disp6 : out std_logic_vector(6 DOWNTO 0);
            salida_disp7 : out std_logic_vector(6 DOWNTO 0)
        );
    end component;
    component visualizar_display is
        Port (
            clk : in  STD_LOGIC;
            salida_disp0 : in std_logic_vector(6 downto 0);
            salida_disp1 : in std_logic_vector(6 downto 0);
            salida_disp2 : in std_logic_vector(6 downto 0);
            salida_disp3 : in std_logic_vector(6 downto 0);
            salida_disp4 : in std_logic_vector(6 downto 0);
            salida_disp5 : in std_logic_vector(6 downto 0);
            salida_disp6 : in std_logic_vector(6 downto 0);
            salida_disp7 : in std_logic_vector(6 downto 0);
            numero_display : out  std_logic_vector (6 downto 0);
            seleccion_display : out  std_logic_vector (7 downto 0)

        );
    end component;
begin
    inst_sincronizador: sincronizador port map(
            CLK => clk_salida,
            SYNC_in => boton_inicio,
            SYNC_out => sinc_detector
        );
    inst_divisor_frec: divisor_frec
        port map (
            clk_in => clk_entrada,
            reset => reset_global,
            clk_out => clk_salida
        );

    inst_detector_flanco: detector_flanco port map(
            CLK =>clk_salida,
            EDGE_in =>sinc_detector,
            EDGE_out =>detector_fsm1
        );

    inst_fsm1: fsm1 port map(
            RESET => reset_global,
            CLK => clk_salida,
            EDGE => detector_fsm1,
            MODOS => entradas,
            SEL_LECHE => sel_leche,
            LED_AZUCAR => led_azucar,
            SEL_AZUCAR => sel_azucar,
            SENSOR =>sensor,
            MODO_DISPLAY => modo_display,
            LED_ENCENDIDA =>led_encendida,
            LED_BOMBA => led_bomba,
            LED_LECHE => led_leche,
            START => start,
            DONE =>done,
            DELAY => delay
        );
    inst_fsm_esclava : fsm_esclava port map (
            CLK     => clk_salida,
            RESET   => reset_global,
            START   => start,
            DELAY   => delay,
            DONE    => done
        );
    inst_decodificador: decodificador port map(
            seleccion => modo_display,
            salida_disp0 => salida_disp0,
            salida_disp1 => salida_disp1,
            salida_disp2 => salida_disp2,
            salida_disp3 => salida_disp3,
            salida_disp4 => salida_disp4,
            salida_disp5 => salida_disp5,
            salida_disp6 => salida_disp6,
            salida_disp7 => salida_disp7
        );
    inst_visualizar_display:visualizar_display port map(
            clk => clk_salida,
            salida_disp0 => salida_disp0,
            salida_disp1 => salida_disp1,
            salida_disp2 => salida_disp2,
            salida_disp3 => salida_disp3,
            salida_disp4 => salida_disp4,
            salida_disp5 => salida_disp5,
            salida_disp6 => salida_disp6,
            salida_disp7 => salida_disp7,
            numero_display => numero_display,
            seleccion_display=> seleccion_display
        );
end Behavioral;

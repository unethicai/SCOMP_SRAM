LIBRARY IEEE;
LIBRARY ALTERA_MF;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY SRAM_IO IS
    PORT(
        CS_ADDR_BANK0     :  IN    STD_LOGIC;
        CS_ADDR_BANK1     :  IN    STD_LOGIC;
        CS_ADDR_BANK2     :  IN    STD_LOGIC;
        CS_ADDR_BANK3     :  IN    STD_LOGIC;
        CS_ADDR_LOW       :  IN    STD_LOGIC;
        CS_ADDR_HIGH      :  IN    STD_LOGIC;
        CS_JUMP_OFFSET    :  IN    STD_LOGIC;
        CS_SRAM_DATA      :  IN    STD_LOGIC;
        CS_SRAM_DATA_INCR :  IN    STD_LOGIC;
        CS_SRAM_DATA_DECR :  IN    STD_LOGIC;

        CLOCK             :  IN    STD_LOGIC;
        RESETN            :  IN    STD_LOGIC;

        IO_WRITE          :  IN    STD_LOGIC;
        IO_DATA           :  INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        SRAM_ADDR         :  OUT   STD_LOGIC_VECTOR(17 DOWNTO 0);
        OE_N              :  OUT   STD_LOGIC;
        WE_N              :  OUT   STD_LOGIC;

        UB_N              :  OUT   STD_LOGIC;
        LB_N              :  OUT   STD_LOGIC;
        CE_N              :  OUT   STD_LOGIC
    );
END SRAM_IO;


ARCHITECTURE a OF SRAM_IO IS

    TYPE STATE_TYPE IS (
        IDLE, OUT_ADDR_LOW, OUT_ADDR_HIGH, READ, WRITE, WAITING
    );

    SIGNAL STATE           : STATE_TYPE;
    SIGNAL INCR            : STD_LOGIC; -- If an increment is pending
    SIGNAL DECR            : STD_LOGIC; -- If a decrement is pending

    SIGNAL ADDR            : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL ADDR_OUT        : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL ADDR_OUT_ENABLE : STD_LOGIC;

BEGIN

    INTERFACE_OUT: LPM_BUSTRI
    GENERIC MAP (
        lpm_width => 16
    )
    PORT MAP (
        data     => ADDR_OUT,
        enabledt => ADDR_OUT_ENABLE,
        tridata  => IO_DATA
    );

    UB_N <= '0';
    LB_N <= '0';
    CE_N <= '0';

    SRAM_ADDR <= ADDR;

    WITH STATE SELECT OE_N <=
        '0' WHEN READ,
        '1' WHEN OTHERS;
    WITH STATE SELECT WE_N <=
        '0' WHEN WRITE,
        '1' WHEN OTHERS;
    
    WITH STATE SELECT ADDR_OUT_ENABLE <=
        '1' WHEN OUT_ADDR_LOW,
        '1' WHEN OUT_ADDR_HIGH,
        '0' WHEN OTHERS;

    PROCESS (CLOCK, RESETN) BEGIN
        IF (RESETN = '0') THEN
            STATE         <= IDLE;
            ADDR          <= "000000000000000000";
            INCR          <= '0';
            DECR          <= '0';
        ELSIF (RISING_EDGE(CLOCK)) THEN
            CASE STATE is
                WHEN IDLE =>
                    IF INCR = '1' THEN
                        ADDR <= std_logic_vector(unsigned(ADDR) + 1);
                        INCR <= '0';
                    ELSIF DECR = '1' THEN
                        ADDR <= std_logic_vector(unsigned(ADDR) - 1);
                        DECR <= '0';

                    ELSIF CS_ADDR_BANK0 = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR <= "00" & IO_DATA;
                        END IF;
                    ELSIF CS_ADDR_BANK1 = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR <= "01" & IO_DATA;
                        END IF;
                    ELSIF CS_ADDR_BANK2 = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR <= "10" & IO_DATA;
                        END IF;
                    ELSIF CS_ADDR_BANK3 = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR <= "11" & IO_DATA;
                        END IF;
                    ELSIF CS_ADDR_LOW = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR(15 DOWNTO 0) <= IO_DATA;
                        ELSE
                            STATE <= OUT_ADDR_LOW;
                        END IF;
                    ELSIF CS_ADDR_HIGH = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR(17 DOWNTO 16) <= IO_DATA(1 DOWNTO 0);
                        ELSE
                            STATE <= OUT_ADDR_HIGH;
                        END IF;
                    ELSIF CS_JUMP_OFFSET = '1' THEN
                        IF IO_WRITE = '1' THEN
                            ADDR <= std_logic_vector(to_unsigned(to_integer(unsigned(ADDR)) + to_integer(signed(IO_DATA)), 18));
                            STATE <= WAITING;
                        END IF;
                    ELSIF CS_SRAM_DATA = '1' THEN
                        IF IO_WRITE = '1' THEN
                            STATE <= WRITE;
                        ELSE
                            STATE <= READ;
                        END IF;
                    ELSIF CS_SRAM_DATA_INCR = '1' THEN
                        INCR <= '1';
                        IF IO_WRITE = '1' THEN
                            STATE <= WRITE;
                        ELSE
                            STATE <= READ;
                        END IF;
                    ELSIF CS_SRAM_DATA_DECR = '1' THEN
                        DECR <= '1';
                        IF IO_WRITE = '1' THEN
                            STATE <= WRITE;
                        ELSE
                            STATE <= READ;
                        END IF;
                    END IF;

                WHEN OUT_ADDR_LOW =>
                    ADDR_OUT <= ADDR(15 DOWNTO 0);
                WHEN OUT_ADDR_HIGH =>
                    ADDR_OUT <= "00000000000000" & ADDR(17 DOWNTO 16);
                WHEN OTHERS =>
                    NULL;
            END CASE;

            IF (  CS_ADDR_BANK0 = '0'
                  AND CS_ADDR_BANK1 = '0'
                  AND CS_ADDR_BANK2 = '0'
                  AND CS_ADDR_BANK3 = '0'
                  AND CS_ADDR_LOW = '0'
                  AND CS_ADDR_HIGH = '0'
                  AND CS_JUMP_OFFSET = '0'
                  AND CS_SRAM_DATA = '0'
                  AND CS_SRAM_DATA_INCR = '0'
                  AND CS_SRAM_DATA_DECR = '0') THEN
		        STATE <= IDLE;
		    END IF;
        END IF;

    END PROCESS;

END a;
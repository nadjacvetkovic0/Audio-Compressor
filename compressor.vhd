LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY project_io IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        done : OUT STD_LOGIC;
        in_read_enable : OUT STD_LOGIC := '0';
        in_index : OUT INTEGER;
        in_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        out_write_enable : OUT STD_LOGIC := '0';
        out_index : OUT INTEGER;
        out_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
        in_buff_size : OUT INTEGER := 200;
        out_buff_size : OUT INTEGER := 200
    );
END ENTITY project_io;

ARCHITECTURE behavioural OF project_io IS

    TYPE mem_array IS ARRAY (0 TO 199) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL input_data : mem_array;
    SIGNAL clk_cnt : INTEGER := 0;
    SIGNAL in_cnt : INTEGER := 0;
    SIGNAL out_cnt : INTEGER := 0;
    SIGNAL prev_sample : INTEGER := 0;
    SIGNAL temp_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL done_s : STD_LOGIC := '0';
    SIGNAL processing : BOOLEAN := FALSE;

BEGIN
    PROCESS (clk, rst)
        VARIABLE diff : INTEGER;
    BEGIN
        IF rst = '1' THEN
            in_read_enable <= '0';
            out_write_enable <= '0';
            done <= '0';
            done_s <= '0';
            in_cnt <= 0;
            out_cnt <= 0;
            processing <= FALSE;

        ELSIF rising_edge(clk) THEN
            IF enable = '1' AND done_s = '0' THEN
                IF in_cnt < 200 THEN
                    in_read_enable <= '1';
                    in_index <= in_cnt;
                    input_data(in_cnt) <= in_data;
                    in_cnt <= in_cnt + 1;
                ELSE
                    in_read_enable <= '0';
                    processing <= TRUE;
                END IF;

            ELSIF processing = TRUE THEN
                out_write_enable <= '1';

                IF out_cnt = 0 THEN
                    out_data <= input_data(0);
                    prev_sample <= TO_INTEGER(UNSIGNED(input_data(0)));
                    out_index <= out_cnt;
                    out_cnt <= out_cnt + 1;

                ELSIF out_cnt < 200 THEN
                    diff := TO_INTEGER(UNSIGNED(input_data(out_cnt))) - prev_sample;
                    temp_data <= STD_LOGIC_VECTOR(TO_SIGNED(diff, 8));
                    out_data <= temp_data;
                    prev_sample <= TO_INTEGER(UNSIGNED(input_data(out_cnt)));
                    out_index <= out_cnt;
                    out_cnt <= out_cnt + 1;

                ELSE
                    out_write_enable <= '0';
                    out_index <= 0;
                    done_s <= '1';
                    processing <= FALSE;
                END IF;

            ELSIF done_s = '1' THEN
                done <= '1';
                done_s <= '0';
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE behavioural;

-- Include necessary IEEE libraries
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Define the entity with input/output ports
ENTITY project_io IS
    PORT (
        clk : IN STD_LOGIC;                              -- Clock signal
        rst : IN STD_LOGIC;                              -- Reset signal
        enable : IN STD_LOGIC;                           -- Enable signal to start the process
        done : OUT STD_LOGIC := '0';                            -- Signal to indicate completion
        in_read_enable : OUT STD_LOGIC := '0';           -- Signal to enable reading from input buffer
        in_index : OUT INTEGER;                          -- Index for reading input data
        in_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);      -- Input data (8-bit)
        out_write_enable : OUT STD_LOGIC := '0';         -- Signal to enable writing to output buffer
        out_index : OUT INTEGER;                         -- Index for writing output data
        out_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);    -- Output data (8-bit)
        in_buff_size : OUT INTEGER := 200;               -- Size of input buffer
        out_buff_size : OUT INTEGER := 100               -- Size of output buffer
    );
END ENTITY project_io;

-- Define the architecture for the entity
ARCHITECTURE behavioural OF project_io IS

    -- Define an array to store 200 bytes of input data
    TYPE mem_array IS ARRAY (0 TO 199) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL input_data : mem_array;

    -- Internal signals for counters and state tracking
    SIGNAL clk_cnt : INTEGER := 0;
    SIGNAL in_cnt : INTEGER := 0;
    SIGNAL out_cnt : INTEGER := 0;
    SIGNAL prev_sample : INTEGER := 0;                  -- Previous sample value for differencing
    SIGNAL temp_data : STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Temporary storage for output
    SIGNAL done_s : STD_LOGIC := '0';                   -- Internal done signal
    SIGNAL processing : BOOLEAN := FALSE;               -- Indicates processing phase

BEGIN
    -- Main process that responds to clock and reset
    PROCESS (clk, rst)
        VARIABLE diff : INTEGER;                        -- Variable to hold computed difference
    BEGIN
        -- Reset logic
        IF rst = '1' THEN
            in_read_enable <= '0';
            out_write_enable <= '0';
            done <= '0';
            done_s <= '0';
            in_cnt <= 0;
            out_cnt <= 0;
            processing <= FALSE;

        -- On rising clock edge
        ELSIF rising_edge(clk) THEN
            -- If enabled and not already done
            IF enable = '1' AND done_s = '0' THEN
                -- Read 200 samples from input
                IF in_cnt < 200 THEN
                    in_read_enable <= '1';
                    in_index <= in_cnt;
                    input_data(in_cnt) <= in_data;
                    in_cnt <= in_cnt + 1;
                ELSE
                    in_read_enable <= '0';              -- Stop reading
                    processing <= TRUE;                 -- Begin processing
                END IF;

            -- Processing the input data (differencing)
            ELSIF processing = TRUE THEN
                out_write_enable <= '1';

                -- First sample is copied as-is
                IF out_cnt = 0 THEN
                    out_data <= input_data(0);
                    prev_sample <= TO_INTEGER(UNSIGNED(input_data(0)));
                    out_index <= out_cnt;
                    out_cnt <= out_cnt + 1;

                -- For remaining samples, calculate difference from previous sample
                ELSIF out_cnt < 200 THEN
                    diff := TO_INTEGER(UNSIGNED(input_data(out_cnt))) - prev_sample;
                    temp_data <= STD_LOGIC_VECTOR(TO_SIGNED(diff, 8));  -- Convert to signed and back to std_logic_vector
                    out_data <= temp_data;
                    prev_sample <= TO_INTEGER(UNSIGNED(input_data(out_cnt)));  -- Update previous sample
                    out_index <= out_cnt;
                    out_cnt <= out_cnt + 1;

                -- All samples processed
                ELSE
                    out_write_enable <= '0';
                    out_index <= 0;
                    done_s <= '1';                      -- Indicate done internally
                    processing <= FALSE;                -- End processing phase
                END IF;

            -- Finalize done signal
            ELSIF done_s = '1' THEN
                done <= '1';                            -- Notify that operation is complete
                done_s <= '0';                          -- Reset internal done signal
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE behavioural;

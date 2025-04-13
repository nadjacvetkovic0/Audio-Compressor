LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Entity definition with I/O ports
ENTITY project_io IS
    PORT (
        clk : IN STD_LOGIC;                              -- Clock signal
        rst : IN STD_LOGIC;                              -- Reset signal
        enable : IN STD_LOGIC;                           -- Enable signal to start the operation
        done : OUT STD_LOGIC := '0';                     -- Indicates processing is complete
        in_read_enable : OUT STD_LOGIC := '0';           -- Enables reading from the input
        in_index : OUT INTEGER;                          -- Index of the current input being read
        in_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);      -- Input data (8-bit)
        out_write_enable : OUT STD_LOGIC := '0';         -- Enables writing to the output
        out_index : OUT INTEGER;                         -- Index of the current output being written
        out_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);    -- Output data (8-bit)
        in_buff_size : OUT INTEGER := 200;               -- Input buffer size
        out_buff_size : OUT INTEGER := 100               -- Output buffer size
    );
END ENTITY project_io;

-- Architecture defining the behavior
ARCHITECTURE behavioural OF project_io IS

    -- Internal counter to track how many inputs have been processed
    SIGNAL in_cnt : INTEGER := 0;

    -- Holds the previous sample value to compute the difference
    SIGNAL prev_sample : INTEGER := 0;

    -- Temporary storage for the output value
    SIGNAL temp_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Indicates whether processing is currently ongoing
    SIGNAL processing : BOOLEAN := FALSE;

BEGIN
    -- Main sequential process
    PROCESS (clk, rst)
        VARIABLE diff : INTEGER;                         -- Difference between current and previous samples
        VARIABLE current_sample : INTEGER;               -- Current sample converted to integer
    BEGIN
        -- Reset logic: resets counters, flags and disables signals
        IF rst = '1' THEN
            in_cnt <= 0;
            prev_sample <= 0;
            in_read_enable <= '0';
            out_write_enable <= '0';
            done <= '0';
            processing <= FALSE;

        -- Executes on rising clock edge
        ELSIF rising_edge(clk) THEN
            -- If enabled and not all inputs have been processed
            IF enable = '1' AND in_cnt < 200 THEN
                in_read_enable <= '1';                   -- Allow reading input
                in_index <= in_cnt;                      -- Set input index

                current_sample := TO_INTEGER(UNSIGNED(in_data)); -- Convert input to integer

                -- First sample: pass through directly
                IF in_cnt = 0 THEN
                    -- Pass through the first sample unmodified
                    temp_data <= in_data;
                    out_data <= in_data;
                    out_write_enable <= '1';
                    out_index <= in_cnt;
                    prev_sample <= current_sample;
                    in_cnt <= in_cnt + 1;
                ELSE
                    -- Compute difference from previous sample
                    diff := current_sample - prev_sample;
                    temp_data <= STD_LOGIC_VECTOR(TO_SIGNED(diff, 8));
                    out_data <= temp_data;
                    out_write_enable <= '1';
                    out_index <= in_cnt;
                    prev_sample <= current_sample;
                    in_cnt <= in_cnt + 1;
                END IF;


                -- Write the result to output
                out_data <= temp_data;
                out_write_enable <= '1';                 -- Enable output write
                out_index <= in_cnt;                     -- Set output index

                in_cnt <= in_cnt + 1;                    -- Move to next sample

            -- All samples processed
            ELSIF in_cnt >= 200 THEN
                in_read_enable <= '0';                   -- Disable input reading
                out_write_enable <= '0';                 -- Disable output writing
                done <= '1';                             -- Signal completion
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE behavioural;

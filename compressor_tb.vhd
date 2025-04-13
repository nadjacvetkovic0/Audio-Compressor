LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Testbench entity: has no ports because it's not a real hardware component
ENTITY compressor_tb IS
END ENTITY;

ARCHITECTURE testbench OF compressor_tb IS
    -- Declaration of the component we are testing
    COMPONENT compressor IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            done : OUT STD_LOGIC;
            in_read_enable : OUT STD_LOGIC;
            in_index : OUT INTEGER;
            in_data : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            out_write_enable : OUT STD_LOGIC;
            out_index : OUT INTEGER;
            out_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            in_buff_size : OUT INTEGER;
            out_buff_size : OUT INTEGER
        );
    END COMPONENT;

    -- Signals to drive inputs and observe outputs
    SIGNAL clk              : STD_LOGIC := '0';
    SIGNAL rst              : STD_LOGIC := '0';
    SIGNAL enable           : STD_LOGIC := '0';
    SIGNAL done             : STD_LOGIC;
    SIGNAL in_read_enable   : STD_LOGIC;
    SIGNAL in_index         : INTEGER;
    SIGNAL in_data          : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL out_write_enable : STD_LOGIC;
    SIGNAL out_index        : INTEGER;
    SIGNAL out_data         : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL in_buff_size     : INTEGER;
    SIGNAL out_buff_size    : INTEGER;

    -- Input test data: manually defined array of 10 bytes (e.g., from Python random.randint)
    TYPE test_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL test_input_data : test_array := (
        x"80", x"8C", x"9B", x"A0", x"95", x"8C", x"7A", x"69", x"7D", x"96"
        );

BEGIN
    -- Instantiate the unit under test and connect signals
    uut: compressor
        PORT MAP (
            clk => clk,
            rst => rst,
            enable => enable,
            done => done,
            in_read_enable => in_read_enable,
            in_index => in_index,
            in_data => in_data,
            out_write_enable => out_write_enable,
            out_index => out_index,
            out_data => out_data,
            in_buff_size => in_buff_size,
            out_buff_size => out_buff_size
        );

    -- Clock generation process (10 ns period)
    clk_process : PROCESS
    BEGIN
        WHILE true LOOP
            clk <= '0';
            WAIT FOR 5 ns;
            clk <= '1';
            WAIT FOR 5 ns;
        END LOOP;
    END PROCESS;

    -- Main stimulus process: resets and starts the component
    stim_proc : PROCESS
    BEGIN
        rst <= '1';                 -- Activate reset
        WAIT FOR 20 ns;
        rst <= '0';                 -- Release reset
        WAIT FOR 10 ns;

        enable <= '1';             -- Start operation
        WAIT FOR 10 ns;
        enable <= '0';

        -- Wait for the component to finish processing
        WAIT UNTIL done = '1';
        WAIT FOR 50 ns;

        -- End message: check waveform for output results
        ASSERT false REPORT "Test done. Check the waveform for output values." SEVERITY NOTE;
        WAIT;
    END PROCESS;

    -- Process that feeds input bytes to the component when requested
    input_driver : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF in_read_enable = '1' THEN
                -- Provide data from the test array if index is valid
                IF in_index >= 0 AND in_index < 10 THEN
                    in_data <= test_input_data(in_index);
                ELSE
                    in_data <= (OTHERS => '0'); -- Default value for invalid index
                END IF;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;
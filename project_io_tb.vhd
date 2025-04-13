LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

-- WHEN RUNNING THE TESTBENCH IT WILL END WITH THE MESSAGE END
-- AFTER THAT MESSAGE IT WILL SAY 'REPORT FAILED' AND 'SIMULATION FAILED' BUT PAY NO MIND TO THAT

-- EVERY TIME THE OUT_WRITE_ENABLE SIGNAL IS SET THE TESTBENCH WILL PRINT THE OUTPUT
-- TO THE CONSOLE INSTEAD OF WRITING IT INTO THE MEMORY

-- IT _MAY_ HAVE BUGS :)


ENTITY project_io_tb IS
GENERIC (
    --IN_RAM_SIZE : NATURAL := 200; -- velicina batch-a
    IN_RAM_SIZE : NATURAL := 10; -- test velicina batch-a
    OUT_RAM_SIZE : NATURAL := 2; -- nebitno
    BUFFER_NUM : NATURAL := 3 -- broj batch-eva
);
END ENTITY project_io_tb;

ARCHITECTURE behavioural OF project_io_tb IS
    COMPONENT project_io IS
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
    
    TYPE memory_array IS ARRAY(natural RANGE <>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    TYPE memory_bank IS ARRAY(natural RANGE <>) OF memory_array(0 to IN_RAM_SIZE-1);
    -- RAM
    SIGNAL in_ram : memory_array (0 TO IN_RAM_SIZE-1);
    SIGNAL out_ram : memory_array (0 TO OUT_RAM_SIZE-1);

    -- SIGNALS IN PROJECT_IO
    SIGNAL clk : STD_LOGIC;
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL enable : STD_LOGIC := '0';
    SIGNAL in_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- SIGNALS OUT PROJECT_IO
    SIGNAL done : STD_LOGIC;
    SIGNAL in_read_enable : STD_LOGIC;
    SIGNAL in_index : INTEGER;
    SIGNAL out_write_enable : STD_LOGIC;
    SIGNAL out_index : INTEGER;
    SIGNAL out_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL in_buff_size : INTEGER := 200;
    SIGNAL out_buff_size : INTEGER := 100;

    -- INTERNAL SIGNALS
    SIGNAL curr_buffer : INTEGER := 0;


    -- THIS IS WHERE YOU PUT YOUR BUFFERS
    -- AFTER EVERY GIVEN ONE TACT SIGNAL 'DONE' THE NEXT BUFFER IS LOADED
    SIGNAL buffer_array : memory_bank (0 to BUFFER_NUM-1) := (
        0 => (0 => X"64", 1 => X"50", 2 => X"4B", 3 => X"58", 4 => X"66", 5 => X"78", 6 => X"6C", 7 => X"63", 8 => X"5A", 9 => X"60"),
        1 => (0 => X"64", 1 => X"70", 2 => X"7A", 3 => X"6E", 4 => X"60", 5 => X"55", 6 => X"5A", 7 => X"64", 8 => X"6E", 9 => X"78"),
        2 => (0 => X"78", 1 => X"6E", 2 => X"64", 3 => X"5A", 4 => X"50", 5 => X"46", 6 => X"4B", 7 => X"55", 8 => X"5F", 9 => X"69")        
    );
    
BEGIN

    project_cmp : project_io PORT MAP (
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

    p_clock : PROCESS 
    BEGIN 
        clk <= '0';
        wait for 10 ns;
        clk <= '1';
        wait for 10 ns;
    END PROCESS p_clock;


    process
    begin
        wait for 1000 ns;
        report "end" severity failure;
    end process;

    PROCESS (clk)
    begin
        if rising_edge(clk) then
            if done = '1' then
                enable <= not done;
                
            elsif enable = '0' then
                if curr_buffer = BUFFER_NUM then
                    report "end" severity failure;
                end if;
                in_ram <= buffer_array(curr_buffer);

                curr_buffer <= curr_buffer + 1;

                enable <= '1';
            end if;
        end if;

    end process;
    

    p_ram_reader : PROCESS (clk)
    BEGIN 
        IF rising_edge(clk) AND enable = '1' AND in_read_enable = '1' THEN
            in_data <= in_ram(in_index);
        END IF;
    END PROCESS p_ram_reader;

    p_ram_output : PROCESS (clk)
    variable line_out : line;
    BEGIN 
        IF rising_edge(clk) AND out_write_enable = '1' AND enable = '1' THEN
            
            write (line_out, to_integer(unsigned(out_data)));
            writeline (output, line_out);
        END IF;
    END PROCESS p_ram_output;

    

END architecture behavioural;
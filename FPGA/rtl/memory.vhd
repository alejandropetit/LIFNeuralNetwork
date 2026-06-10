library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_textio.all;
use STD.TEXTIO.all;

library xpm;
use xpm.vcomponents.all;


entity memory is
Port (
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    we : in STD_LOGIC_VECTOR(0 downto 0);
    read_addr : in STD_LOGIC_VECTOR(8 downto 0);
    write_addr : in STD_LOGIC_VECTOR(8 downto 0);
    write_data: in STD_LOGIC_VECTOR(71 downto 0);
    read_data : out STD_LOGIC_VECTOR(71 downto 0));
end memory;


architecture inferred_sdpram of memory is
    type RamType is array (0 to 512) of STD_LOGIC_VECTOR(71 downto 0);
    impure function InitRamFromFile (RamFileName : in string) return RamType is
        file RamFile : text is in RamFileName;--file RamFile : text open read_mode is RamFileName;
        variable RamFileLine : line;
        variable RAM         : RamType;
    begin
        for i in RamType'range loop
            readline(RamFile, RamFileLine);
            hread(RamFileLine, RAM(i));
        end loop;
        return RAM;
    end function;
    signal RAM : RamType := InitRamFromFile("mem.mem");
begin
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                read_data <= (others => '0');
 
            else
                read_data <= RAM(to_integer(unsigned(read_addr)));
            end if;   
            
            RAM(to_integer(unsigned(write_addr))) <= write_data when (and we) = '1';
        end if;
    end process;
end inferred_sdpram;



architecture xpm_sdpram of memory is
begin
    xpm_memory_sdpram_inst : xpm_memory_sdpram
    generic map(
        ADDR_WIDTH_A => 9,
        ADDR_WIDTH_B => 9,
        AUTO_SLEEP_TIME => 0,
        BYTE_WRITE_WIDTH_A => 72,
        CASCADE_HEIGHT => 0,
        CLOCKING_MODE => "common_clock",
        ECC_BIT_RANGE => "7:0",
        ECC_MODE => "no_ecc",
        ECC_TYPE => "none",
        IGNORE_INIT_SYNTH => 0,
        MEMORY_INIT_FILE => "mem.mem",
        MEMORY_INIT_PARAM => "0",
        MEMORY_OPTIMIZATION => "true",
        MEMORY_PRIMITIVE => "block",
        MEMORY_SIZE => 36864,
        MESSAGE_CONTROL => 1,
        RAM_DECOMP => "auto",
        READ_DATA_WIDTH_B => 72,
        READ_LATENCY_B => 2,
        READ_RESET_VALUE_B => "000000000000000000",
        RST_MODE_A => "SYNC",
        RST_MODE_B => "SYNC",
        SIM_ASSERT_CHK => 1,
        USE_EMBEDDED_CONSTRAINT => 0, 
        USE_MEM_INIT => 1,
        USE_MEM_INIT_MMI => 0,
        WAKEUP_TIME => "disable_sleep",
        WRITE_DATA_WIDTH_A => 72,
        WRITE_MODE_B => "no_change",
        WRITE_PROTECT => 1
    )
    port map(
        addra => write_addr,
        addrb => read_addr,
        clka => clk,
        clkb => clk,
        dina => write_data,
        doutb => read_data,
        ena => '1',
        enb => '1',
        injectdbiterra => '0',
        injectsbiterra => '0',
        regceb => '1',
        rstb => reset,
        sleep => '0',
        wea => we
    );        

end xpm_sdpram;


architecture xpm_sprom of memory is 
begin
    xpm_memory_sprom_inst : xpm_memory_sprom
    generic map(
        ADDR_WIDTH_A => 9,
        AUTO_SLEEP_TIME => 0,
        CASCADE_HEIGHT => 0,
        ECC_BIT_RANGE => "7:0",
        ECC_MODE => "no_ecc",
        ECC_TYPE => "none",
        IGNORE_INIT_SYNTH => 0,
        MEMORY_INIT_FILE => "mem.mem",
        MEMORY_INIT_PARAM => "0",
        MEMORY_OPTIMIZATION => "true",
        MEMORY_PRIMITIVE => "block",
        MEMORY_SIZE => 36864,
        MESSAGE_CONTROL => 1,
        RAM_DECOMP => "auto",
        READ_DATA_WIDTH_A => 72,
        READ_LATENCY_A => 2,
        READ_RESET_VALUE_A => "000000000000000000",
        RST_MODE_A => "SYNC",
        SIM_ASSERT_CHK => 1,
        USE_MEM_INIT => 1,
        WAKEUP_TIME => "disable_sleep" 
    )
    port map(
        addra => read_addr,
        clka => clk,
        douta => read_data,
        ena => '1',
        injectdbiterra => '0',
        injectsbiterra => '0',
        regcea => '1',
        rsta => reset,
        sleep => '0'            
    );
end xpm_sprom;


architecture inferred_sprom of memory is
    type RamType is array (0 to 511) of STD_LOGIC_VECTOR(71 downto 0);
    impure function InitRamFromFile (RamFileName : in string) return RamType is
        file RamFile : text is in RamFileName;--file RamFile : text open read_mode is RamFileName;
        variable RamFileLine : line;
        variable RAM         : RamType;
    begin
        for i in RamType'range loop
            readline(RamFile, RamFileLine);
            hread(RamFileLine, RAM(i));
        end loop;
        return RAM;
    end function;
    signal RAM : RamType := InitRamFromFile("mem.mem");
begin
    process(clk) begin
        if rising_edge(clk) then
            read_data <= RAM(to_integer(unsigned(read_addr)));
        end if;
    end process;
end  inferred_sprom;

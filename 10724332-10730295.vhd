library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity project_reti_logiche is
    Port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_add : in std_logic_vector(15 downto 0);
        i_k : in std_logic_vector(9 downto 0);
        
        o_done : out std_logic;
        
        o_mem_addr : out std_logic_vector(15 downto 0); 
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
     );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is (reset, scrivi, sovrascrivi, leggi, fine);
signal state, next_state : state_type;
signal buffer1: std_logic_vector(7 downto 0);
signal counter, temp_counter : std_logic_vector(10 downto 0);
signal C, next_C : std_logic_vector(4 downto 0);
signal word, next_word : std_logic_vector(7 downto 0);

begin

o_mem_en <= '0' when state = fine else '1';


output_logic : process (state,counter,C,word,buffer1)
begin

case state is
    when reset =>
        o_done <= '0';
        temp_counter <= ("00000000000");
        o_mem_data <= (others => '0');
        o_mem_we <= '0';
        next_C <= (others => '1');
        next_word <= (others => '0');
    when fine =>
        o_done <= '1';
        temp_counter <= (others => '0');
        o_mem_data <= (others => '0');
        o_mem_we <= '0';
        next_C <= (others => '0');
        next_word <= (others => '0');
    when scrivi =>
        o_done <= '0';
        temp_counter <= std_logic_vector(unsigned(counter) + 1);
        o_mem_data <= (others => '-');
        o_mem_we <= '0';
        next_C <= C;
        next_word <= word;
    when sovrascrivi =>
        o_done <= '0';
        temp_counter <= std_logic_vector(unsigned(counter) + 1);
        o_mem_data <= "000" & std_logic_vector(C);
        o_mem_we <= '1';
        next_C <= C;
        next_word <= word;
    when leggi =>
        o_done <= '0';
        o_mem_we <= '1';
        if word = "00000000" then
            temp_counter <= std_logic_vector(unsigned(counter) + 1);
            next_C <= C;
            next_word <= buffer1;
            if buffer1 = "00000000" then
                o_mem_data <= (others => '0');
            else o_mem_data <= "000" & std_logic_vector(C);
            end if;
        else
            if buffer1 = "00000000" then
                temp_counter <= counter;
                o_mem_data <= word;
                if unsigned(C) = "00000" then
                    next_C <= C;
                else
                    next_C <= std_logic_vector(unsigned(C) - 1);
                end if;
                next_word <= word;
            else
                temp_counter <= std_logic_vector(unsigned(counter) + 1);
                o_mem_data <= "00011111";
                next_C <= (others => '1');
                next_word <= buffer1;
            end if;
        end if;
end case;

end process;

synchronous_logic : process (i_clk, i_rst)
begin

if i_rst = '1' then
    
    state <= reset;
    word <= (others => '0');
    C <= (others => '1');
end if;
if i_rst = '0' then   
if falling_edge(i_clk) then
    counter<=temp_counter; 
    state <= next_state;
    word <= next_word;
    C <= next_C;
end if;      
end if;
end process;

memory_reader1 : process (i_mem_data,i_clk,i_rst)
begin

if i_rst = '1' then

    else if falling_edge(i_clk) then

        buffer1<=i_mem_data;

    end if;
end if;

end process;

address_updater : process (i_add,temp_counter)
begin

if to_integer(unsigned(i_add)) /= 0 then
o_mem_addr <= std_logic_vector(unsigned("00000" & temp_counter) + unsigned(i_add));
else
o_mem_addr<=(others=>'0');
end if;

end process;

next_state_logic : process (state, i_start, counter,i_k,word,buffer1)
begin

case state is
    when reset =>
        if i_start = '1'  then
        
            if unsigned(i_k) = "0000000000" then
                next_state <= fine;
            else
                next_state <= leggi;
         end if;
        else
            next_state <= reset;
        end if;
    when scrivi =>
        if 2*unsigned(i_k) = (unsigned(counter) + 1) then
            next_state <= fine;
        else
            next_state <= leggi;
        end if;
    when sovrascrivi => next_state <= scrivi;
    when leggi =>
        if word = "00000000" then 
            next_state <= scrivi;
        else
            if buffer1 = "00000000" then
                next_state <= sovrascrivi;
            else
                next_state <= scrivi;
            end if;
        end if;
    when fine =>
        if i_start = '1' then
            next_state <= fine;
        else
            next_state <= reset;
        end if;
    end case;
    
end process;

end Behavioral;
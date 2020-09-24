----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.02.2019 11:28:26
-- Design Name: 
-- Module Name: project_retiLogiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_start : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
     );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is ( START , SET_ADD , WAITCLOCK , WAITCLOCK2 ,  READ , CALCOLADIST , SALVARIS , WRITE  , END_STATE );
    
    signal curr_state , next_state : state_type;
    signal mask , next_mask : std_logic_vector(7 downto 0);
    signal address , curr_address : std_logic_vector(15 downto 0);
    signal X , Y , next_X , next_Y : integer range -1 to 255 ;
    signal X_temp , Y_temp , X_temp_next , Y_temp_next : integer range -1 to 255 ;
    signal dist , next_dist: integer := 0;
    signal distmin , next_distmin: integer;
    signal result , next_result : std_logic_vector(7 downto 0) ;
    signal pos , next_pos: integer ;
    signal data , curr_data: std_logic_vector(7 downto 0);
    
    
begin

    process(i_clk , i_rst , i_start)
    
    begin
        if(i_rst = '1') then
           curr_state <= START;
        elsif (i_clk'event AND i_clk='1' AND i_start = '1') then
                curr_state <= next_state;
                curr_address <= address;
                curr_data <= data;
                X_temp <= X_temp_next;
                Y_temp <= Y_temp_next;
                pos <= next_pos;
                result <= next_result;
                dist <= next_dist;
                distmin <= next_distmin;
                mask <= next_mask;
                X <= next_X;
                Y <= next_Y;
            
        end if;
        
     end process;
     
     
    process(curr_state , curr_address , X_temp , Y_temp , pos , result , dist , distmin , mask , X , Y , curr_data , i_data)
    
    begin
        
        data <= curr_data;
        address <= curr_address;
        X_temp_next <= X_temp;
        Y_temp_next <= Y_temp;
        next_pos <= pos;
        next_result <= result;
        next_dist <= dist;
        next_distmin <= distmin;
        next_mask <= mask;
        next_X <= X;
        next_Y <= Y;
        next_state <= curr_state;
        
        case curr_state is
            when START =>
                     address <= "0000000000000000";
                     data <= "00000000";
                     X_temp_next <= -1;
                     Y_temp_next <= -1;
                     next_pos <= 0;
                     next_result <= "00000000";
                     next_dist <= 0;
                     next_distmin <= 513;
                     next_mask <= "00000000";
                     next_X <= -1;
                     next_Y <= -1;
                     next_state <= WAITCLOCK;
                     
             when SET_ADD =>
             
                      if( to_integer( unsigned(curr_address)) = 0 ) then
                        address <= "0000000000010001";
                     else
                     
                     if(to_integer( unsigned(curr_address)) = 17) then
                        address <= "0000000000010010";
                     elsif ( to_integer( unsigned(curr_address)) = 18) then
                            address <= "0000000000000001";
                        elsif( to_integer( unsigned(curr_address)) < 16) then
                            address <= std_logic_vector( unsigned(curr_address) + 1 );
                        end if;
                     end if;
                       
                    
                     next_state <= WAITCLOCK;
                      
             when WAITCLOCK =>
                   next_state <= WAITCLOCK2;
             
             when WAITCLOCK2 =>
                   next_state <= READ;
            
             when READ => 
                  
                   next_state <= SET_ADD;
                   if( to_integer( unsigned(curr_address)) = 0) then
                        next_mask <= i_data;
                   elsif( to_integer( unsigned(curr_address)) = 17) then
                        next_X <= to_integer( unsigned(i_data));
                   elsif( to_integer( unsigned(curr_address)) = 18) then
                        next_Y <= to_integer( unsigned(i_data));
                   elsif( X_temp = -1) then
                        X_temp_next <= to_integer( unsigned(i_data));
                   elsif( Y_temp = -1) then
                        Y_temp_next <= to_integer( unsigned(i_data));
                        next_pos <= to_integer( shift_right(unsigned(curr_address), 1))-1;
                        next_state <= CALCOLADIST;
                        
                  end if;      
          
            when CALCOLADIST => 
                       if(X >= X_temp AND Y >= Y_temp) then
                                          next_dist <= (X - X_temp) + (Y - Y_temp);
                       elsif(X >= X_temp AND Y <= Y_temp) then
                                          next_dist <= (X - X_temp) + (Y_temp - Y);
                       elsif(X <= X_temp AND Y >= Y_temp) then
                                          next_dist <= (X_temp - X) + (Y- Y_temp);
                       elsif(X <= X_temp AND Y <= Y_temp) then
                                          next_dist <= (X_temp - X) + (Y_temp - Y);
                       end if;
                       
                       next_state <= SALVARIS;
                       if(to_integer( unsigned(curr_address)) = 16) then 
                         address <="0000000000010011";
                       end if;
           
            when SALVARIS =>
                                   
                       if( mask(pos) = '1') then
                          if(dist < distmin) then 
                              next_result <= "00000000";
                              next_distmin <= dist;
                              next_result(pos) <= '1';
                          elsif( dist = distmin) then                   
                              next_result(pos) <= '1';
                          end if;    
                       end if;   
                       
                       X_temp_next <= -1;
                       Y_temp_next <= -1;
                                   
                      if(to_integer( unsigned(curr_address)) = 19) then
                         next_state <= WRITE;
                      else next_state <= SET_ADD;
                      
                      end if;
                            
            when WRITE => 
                    data <= result;
                    next_state <= END_STATE;
          
           when END_STATE =>
                    next_state <= START;
           
         end case;
     end process;  
     
     process( curr_state , i_start , curr_address , curr_data)
     
     begin
     
     case curr_state is
                 when START =>
                      o_done <= '0';
                      o_en <= '1';
                      o_we <= '0';
                      o_address <= curr_address;
                      o_data <= curr_data;
                      
                 when SET_ADD =>
                      o_done <='0';
                      o_en <= '1';
                      o_we <= '0';
                      o_address <= curr_address;
                      o_data <= curr_data;
                      
                 when WAITCLOCK => 
                       o_done <='0';
                       o_en <= '1';
                       o_we <= '0';
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                 when WAITCLOCK2 => 
                       o_done <='0';
                       o_en <= '1';
                       o_we <= '0';
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                 when READ => 
                       o_done <='0';
                       o_en <= '1';
                       o_we <= '0';
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                when CALCOLADIST => 
                       o_done <='0';
                       o_en <= '0';
                       o_we <= '0';
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                 when SALVARIS =>
                       o_done <='0';
                       o_en <= '0';
                       o_we <= '0'; 
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                 when WRITE => 
                       o_done <='0';
                       o_en <= '1';
                       o_we <= '1'; 
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                when END_STATE =>
                       o_address <= curr_address;
                       o_data <= curr_data;
                       
                       if(i_start = '1') then
                            o_done <='1';
                            o_en <= '1';
                            o_we <= '1'; 
                            
                       else 
                            o_done <='0';
                            o_en <= '0';
                            o_we <= '0';
                      end if;
        end case;
        
       
     end process;
           
         
end Behavioral;

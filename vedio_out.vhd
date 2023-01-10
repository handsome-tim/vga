library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

entity video_out is
 generic (
   video_h   : integer := 800 ;
   video_v   : integer := 600 
  );
 port(
  clk       : in std_logic;
  reset         : in std_logic;
 ------------vga---------------------------------
  Rout            : out std_logic_vector(3 downto 0); --
  Gout            : out std_logic_vector(3 downto 0); --
  Bout            : out std_logic_vector(3 downto 0); -- 
  hsync           : out std_logic;
  vsync           : out std_logic
 );
end video_out;

architecture vga_controller of video_out is
 signal shifth        : integer := 1;
 signal shiftv        : integer := 1;
 signal count        : integer := 25;
 signal random1   : integer :=  0;
 signal random2  : integer  := 50000;
 signal speed: integer  := 200000;
 signal move:integer  := 1;
 component vga        
 generic (
        horizontal_resolution : integer := 800 ;--解析度
        horizontal_Front_porch: integer :=  56 ;
        horizontal_Sync_pulse : integer := 120 ;
        horizontal_Back_porch : integer :=  64 ;
        h_sync_Polarity         :std_logic:= '1' ;
        vertical_resolution   : integer := 600 ;--解析度
        vertical_Front_porch  : integer :=  37 ;
        vertical_Sync_pulse   : integer :=   6 ;
        vertical_Back_porch   : integer :=  23 ;
        v_sync_Polarity         :std_logic:= '1' 
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        video_start_en : in std_logic;
        vga_hs_cnt : out integer;
        vga_vs_cnt : out integer;
        hsync : out std_logic;
        vsync : out std_logic
    );
 end component;
 signal vga_vs_cnt      : integer ;
 signal vga_hs_cnt      : integer ;
 signal CLK50MHz    : std_logic;
 signal path_h            : std_logic;
 signal path_v            : std_logic;
 signal rst                 : std_logic;
begin
 rst <= not reset;
 vga_1 :vga  
 port map( 
  clk             => CLK50MHz,
  rst             => rst,
  video_start_en  => '1',
  vga_hs_cnt      => vga_hs_cnt,
  vga_vs_cnt      => vga_vs_cnt,
  hsync           => hsync,
  vsync           => vsync
 );
 
 ------------------------------vga out 狀態機動作-------------------------
 process(rst, CLK50MHz, vga_hs_cnt, vga_vs_cnt)
 begin
  if (rst = '0') then
                    Rout <= (others=>'0');
                    Gout <= (others=>'0');
                    Bout <= (others=>'0');
  elsif rising_edge(CLK50MHz) then
        if (vga_hs_cnt < video_h  and vga_vs_cnt < video_v ) then  
            if  ((vga_vs_cnt - shiftv)*(vga_vs_cnt - shiftv) + (vga_hs_cnt- shifth)*(vga_hs_cnt-shifth))< 625  then --中心點(400,300) 半徑25
                Bout <= (others=>'0');
                Gout <= (others=>'0');
                Rout <= (others=>'1');
            else
                Rout <= (others=>'0');
                Gout <= (others=>'0');
                Bout <= (others=>'0');
            end if;        
        else
            Rout <= (others=>'0');
            Gout <= (others=>'0');
            Bout <= (others=>'0');
        end if;
   end if;
 end process;
  process(clk,rst,shifth )              --clk，reset有訊號及進入process內
    begin
        if (rst='0') then          --reset=1就重置
            count  <=  1;
            shifth <= 25;
            shiftv <= 25;
        elsif rising_edge(clk) then       --clk正緣觸發
            count <= count+1;        --每個正緣進來就加1            
            if(count = speed) then       --(pl=100MHz)，100MHz /  0.25MHz = 400Hz，2Hz = 0.0025s --speed為球速度，越大球越快
                case path_h is when '0' => if shifth < 775 then
                                              shifth <= shifth + move;                                             
                                           else
                                              path_h  <= '1' ;
                                              move<= random1;
                                              speed <= random2;
                                         end if;
                               when '1' => if shifth > 25 then
                                              shifth <= shifth - move;                                           
                                            else
                                                path_h  <= '0' ;
                                                move <= random1;
                                                speed <= random2;
                                            end if;
                              end case;
                case path_v is when '0' => if shiftv < 575 then
                                                shiftv <= shiftv + move;
                                           else
                                                path_v <= '1';
                                                move <= random1;
                                                speed <= random2;
                                           end if;
                               when '1' => if shiftv > 25 then
                                                shiftv <= shiftv - move;
                                           else
                                                path_v <= '0';
                                                move <= random1;
                                                speed <= random2;
                                           end if;
                            end case;
                count <= 1;         --計數回出值                            
            end if;
         end if;
      end process;
 -----------------------------------------------------------亂數產生
 process(clk,rst,random1,random2)
 begin
    if(rst = '0') then
        random1 <= 1;        
        random2 <= 50000;
    elsif rising_edge(clk) then
        if  random1 < 5 then 
            random1 <= random1 + 1;
        elsif random1 = 5 then 
            random1 <= 0;
        end if;
         if  random2 < 500000 then 
            random2 <= random2 + 3000;
        elsif random2 = 500000 then 
            random2 <= 50000;
        end if;
    end if;      
 end process;
 ----------------------------------------------------------- 除頻電路(50MHz)
 process(clk,rst)
 begin
  if (rst = '0') then
   CLK50MHz <= '0';
  elsif (clk'event and clk = '1') then
   CLK50MHz <= not CLK50MHz;
  end if;  
 end process;
end architecture;
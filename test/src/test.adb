with HAL; use HAL;
with HAL.I2C;

with RP.Timer; use RP.Timer;
with RP.GPIO; use RP.GPIO;
with RP.I2C_Master;
with RP.Device;
with RP.Clock;
with Pico;

with LTP_305;

procedure Test is

   package DMD renames LTP_305;

   SDA  : GPIO_Point renames Pico.GP14;
   SCL  : GPIO_Point renames Pico.GP15;
   Port : RP.I2C_Master.I2C_Master_Port renames RP.Device.I2CM_1;

   Address    : constant HAL.I2C.I2C_Address := 16#61# * 2;
   BLACK      : constant DMD.Display_Matrix := (others => (others => False));
   WHITE      : constant DMD.Display_Matrix := (others => (others => True));
   Show_White : Boolean := True;
   T          : Time;

   C_I        : Positive := 32;
   Show_Char_Right : Boolean := True;

begin
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Device.Timer.Enable;

   SDA.Configure (Output, Pull_Up, RP.GPIO.I2C, Schmitt => True);
   SCL.Configure (Output, Pull_Up, RP.GPIO.I2C, Schmitt => True);
   Port.Configure (400_000);

   DMD.Initialize (This    => Port'Access,
                   Address => Address);
   T := Clock;
   loop
      if Show_Char_Right then
         DMD.Write (This     => Port'Access,
                Address  => Address,
                Location => DMD.Matrix_R,
                    Code     => C_I,
                    DP       => True);

         if Show_White then
            DMD.Write_Block_Data (Port'Access, Address,
                                  DMD.Matrix_L,
                                  DMD.To_Left_Matrix (WHITE, False));
         else
            DMD.Write_Block_Data (Port'Access, Address,
                                  DMD.Matrix_L,
                                  DMD.To_Left_Matrix (BLACK, False));
         end if;
      else
         DMD.Write (This     => Port'Access,
                Address  => Address,
                Location => DMD.Matrix_L,
                Code     => C_I,
                DP       => True);
         if Show_White then
            DMD.Write_Block_Data (Port'Access, Address,
                                  DMD.Matrix_R,
                                  DMD.To_Right_Matrix (WHITE, False));
         else
            DMD.Write_Block_Data (Port'Access, Address,
                                  DMD.Matrix_R,
                                  DMD.To_Right_Matrix (BLACK, False));
         end if;

      end if;

      DMD.Write_Byte_Data (Port'Access, Address, DMD.Update, 1);

      T := T + Milliseconds (500);
      RP.Device.Timer.Delay_Until (T);

      if C_I = 126 then
         C_I := 1;
      else
         C_I := C_I + 1;
      end if;
      Show_Char_Right := not Show_Char_Right;
      if C_I mod 2 = 0 then
         Show_White := not Show_White;
      end if;
   end loop;
end Test;

with HAL.I2C;

with RP.Timer; use RP.Timer;
with RP.GPIO; use RP.GPIO;
with RP.I2C_Master;
with RP.Device;
with RP.Clock;
with Pico;

with Pimoroni_LED_Dot_Matrix;

procedure Test is
   SDA  : GPIO_Point renames Pico.GP14;
   SCL  : GPIO_Point renames Pico.GP15;
   Port : RP.I2C_Master.I2C_Master_Port renames RP.Device.I2CM_1;

   package DMD renames Pimoroni_LED_Dot_Matrix;
   Address : constant HAL.I2C.I2C_Address := DMD.Default_Address;
   L, R    : DMD.Display_Matrix;
   DP      : Boolean := False;
   T       : Time;
begin
   RP.Clock.Initialize (Pico.XOSC_Frequency);
   RP.Device.Timer.Enable;

   SDA.Configure (Output, Pull_Up, RP.GPIO.I2C, Schmitt => True);
   SCL.Configure (Output, Pull_Up, RP.GPIO.I2C, Schmitt => True);
   Port.Configure (400_000);

   T := Clock;
   loop
      DP := not DP;
      if DP then
         L := (others => (others => True));
         R := (others => (others => False));
      else
         L := (others => (others => False));
         R := (others => (others => True));
      end if;
      DMD.Write_Block_Data (Port'Access, Address, DMD.Matrix_L, DMD.To_Left_Matrix (L, DP));
      DMD.Write_Block_Data (Port'Access, Address, DMD.Matrix_R, DMD.To_Right_Matrix (R, DP));
      DMD.Write_Byte_Data (Port'Access, Address, DMD.Mode, 2#0001_1000#);
      DMD.Write_Byte_Data (Port'Access, Address, DMD.Options, 2#0000_1110#);
      DMD.Write_Byte_Data (Port'Access, Address, DMD.Brightness, 255);
      DMD.Write_Byte_Data (Port'Access, Address, DMD.Update, 1);

      T := T + Milliseconds (1000);
      RP.Device.Timer.Delay_Until (T);
   end loop;
end Test;

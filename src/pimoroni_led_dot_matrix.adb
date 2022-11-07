--
--  Copyright 2021 (C) Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Pimoroni_LED_Dot_Matrix is

   procedure Write_Byte_Data
      (This    : HAL.I2C.Any_I2C_Port;
       Address : HAL.I2C.I2C_Address;
       Cmd     : Command;
       B       : HAL.UInt8)
   is
      use HAL.I2C;
      Data   : constant I2C_Data (1 .. 2) := (Command'Enum_Rep (Cmd), B);
      Status : I2C_Status;
   begin
      This.Master_Transmit (Address, Data, Status);
   end Write_Byte_Data;

   procedure Write_Block_Data
      (This    : HAL.I2C.Any_I2C_Port;
       Address : HAL.I2C.I2C_Address;
       Cmd     : Command;
       Data    : HAL.UInt8_Array)
   is
      use HAL.I2C;
      D      : I2C_Data (1 .. Data'Length + 1) := (1 => Command'Enum_Rep (Cmd), others => 0);
      Status : I2C_Status;
   begin
      D (2 .. D'Last) := Data;
      This.Master_Transmit (Address, D, Status);
   end Write_Block_Data;

   function To_Left_Matrix
      (DM : Display_Matrix;
       DP : Boolean := False)
      return Matrix_Array
   is
      use Interfaces;
      U : Matrix_Bits := 0;
   begin
      for Row in DM'Range (1) loop
         for Column in DM'Range (2) loop
            if DM (Row, Column) then
               U := U or Shift_Left (1, (Row * 8) + Column);
            end if;
         end loop;
      end loop;
      if DP then
         U := U or Shift_Left (1, 62);
      end if;
      return Convert (U);
   end To_Left_Matrix;

   function To_Right_Matrix
      (DM : Display_Matrix;
       DP : Boolean := False)
      return Matrix_Array
   is
      use Interfaces;
      U : Matrix_Bits := 0;
   begin
      for Row in DM'Range (1) loop
         for Column in DM'Range (2) loop
            if DM (Row, Column) then
               U := U or Shift_Left (1, (Column * 8) + Row);
            end if;
         end loop;
      end loop;
      if DP then
         U := U or Shift_Left (1, 55);
      end if;
      return Convert (U);
   end To_Right_Matrix;

end Pimoroni_LED_Dot_Matrix;

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
      D      : I2C_Data (1 .. Data'Length + 1)
        := (1 => Command'Enum_Rep (Cmd), others => 0);
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

   procedure Write (This     : HAL.I2C.Any_I2C_Port;
                    Address  : HAL.I2C.I2C_Address;
                    Location : Pimoroni_LED_Dot_Matrix.Command;
                    Index    : Integer;
                    DP       : Boolean) is
      FMA        : Font.Matrix_Array;
      D_B        : Display_Matrix;
   begin
      FMA := Font.Get (Idx => Index);
      D_B := Convert_FMA (FMA => FMA);
      if Location = Matrix_L then
         Write_Block_Data (This, Address,
                           Location,
                           To_Left_Matrix (D_B, DP));
      else
         Write_Block_Data (This, Address,
                           Location,
                           To_Right_Matrix (D_B, DP));
      end if;
   end Write;

   function Convert_FMA (FMA : Font.Matrix_Array) return Display_Matrix is
      Mask   : HAL.UInt8;
      Column : Integer;
      Result : Display_Matrix := (others => (others => False));
      use HAL;
   begin
      Mask := 1;
      for Row in Display_Matrix'First (2)
        ..
          Display_Matrix'Last (2) loop
         Column := Display_Matrix'First (1);
         for FMA_Column in FMA'First .. FMA'Last loop
            Result (Column, Row) := (FMA (FMA_Column) and Mask) /= 0;
            Column := Column + 1;
         end loop;
         Mask := Shift_Left (Mask, 1);
      end loop;
      return Result;
   end Convert_FMA;

end Pimoroni_LED_Dot_Matrix;

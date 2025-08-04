--
--  Copyright 2021 (C) Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--

with LTP_305.Font;

package body LTP_305 is

   procedure Initialize (This    : HAL.I2C.Any_I2C_Port;
                         Address : HAL.I2C.I2C_Address) is
      Init_Options : constant HAL.UInt8 := 2#00001110#;
      --  1110 = 35 mA; 0000 = 40 mA
      Init_Mode    : constant HAL.UInt8 := 2#00011000#;
   begin
      Write_Byte_Data (This, Address, Reset, 16#FF#);
      Write_Byte_Data (This, Address, Mode, Init_Mode);
      Write_Byte_Data (This, Address, Options, Init_Options);
      Write_Byte_Data (This, Address, Brightness, 255);
   end Initialize;

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

   -----------------------------------------------------------------------
   --  converts the
   --    Font.Matrix_Array into the required Display_Matrix format
   -----------------------------------------------------------------------
   function Convert_FMA (FMA : Font.Matrix_Array) return Display_Matrix;

   procedure Write (This     : HAL.I2C.Any_I2C_Port;
                    Address  : HAL.I2C.I2C_Address;
                    Location : Command;
                    Code     : Integer;
                    DP       : Boolean) is
      FMA        : Font.Matrix_Array;
      D_B        : Display_Matrix;
   begin
      FMA := Font.Get (Idx => Code);
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

end LTP_305;

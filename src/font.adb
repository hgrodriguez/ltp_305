--
--  Copyright 2021 (C) Jeremy Grosser <jeremy@synack.me>
--
--  SPDX-License-Identifier: BSD-3-Clause
--
package body Font is
   function Get
      (Idx : Integer)
      return UInt8_Array
   is
   begin
      for MC of Characters loop
         if MC.Code = Idx then
            return MC.Bytes;
         end if;
      end loop;
      return (16#7F#, 16#7F#, 16#7F#, 16#7F#, 16#7F#);
   end Get;
end Font;

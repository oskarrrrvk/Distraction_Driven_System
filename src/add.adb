
with Kernel.Serial_Output; use Kernel.Serial_Output;
with Ada.Real_Time; use Ada.Real_Time;
with System; use System;

with Tools; use Tools;
with Devices; use Devices;

package body add is

    ----------------------------------------------------------------------
    ------------- procedure exported 
    ----------------------------------------------------------------------
    procedure Background is
    begin
      loop
        null;
      end loop;
    end Background;
    ----------------------------------------------------------------------

    ----------------------------------------------------------------------
    ----------------------- Protected Objects ----------------------------
    ----------------------------------------------------------------------
    
   Protected body Measures is
      function Get_Distance return Distance_Samples_Type is
      begin 
         Execution_Time(Milliseconds(6));
         return distance;
      end Get_Distance;
      
      function Get_Speed return Speed_Samples_Type is
      begin
         Execution_Time(Milliseconds(4));
         return speed;
      end Get_Speed;
      
      function Get_Cabeza return HeadPosition_Samples_Type is
      begin
         Execution_Time(Milliseconds(3));
         return cabeza;
      end Get_Cabeza;
      
      function Get_Volante return Steering_Samples_Type is
      begin
         Execution_Time(Milliseconds(2));
         return Wheel;
      end Get_Volante;
      
      procedure Set_Distance(dist: in Distance_Samples_Type) is
      begin
         Execution_Time(Milliseconds(7));
         distance := dist;
      end Set_Distance;
      
      procedure Set_Speed(spd: in Speed_Samples_Type) is
      begin
         Execution_Time(Milliseconds(8));
         speed := spd;
      end Set_Speed;
      
      procedure Set_Cabeza(cab: in HeadPosition_Samples_Type) is
      begin
         Execution_Time(Milliseconds(1));
         cabeza:= cab;
      end Set_Cabeza;
      
      procedure Set_Volante(vol: in Steering_Samples_Type)is
      begin
         Execution_Time(Milliseconds(3));
         Wheel:= vol;
      end Set_Volante;
      
      function Calculate_Security_Distance return Distance_Samples_Type is
      begin
         Execution_Time(Milliseconds(4));
         return Distance_Samples_Type((speed/10) ** 2);
      end Calculate_Security_Distance; 
   end Measures;
   
------------------------------------------------------------------------------------------------------
    
    Protected body Sign is
      procedure Aviso_Cabeza(cab: in HeadPosition_Samples_Type; cont: in out Integer) is
      begin
         Execution_Time(Milliseconds(3));
         if cab(x)>=30 or cab(x)<= -30 then
            cont:= cont + 1;
            if cont>= 2 then
               Put_Line("CABEZA INCLINADA");
               head_warning := True;
            else
               head_warning := False;
            end if;
         else
            cont:= 0;
            head_warning := False;
         end if;
      end Aviso_Cabeza; 
      
       procedure Set_Position(i: in Integer)is
       begin
          Execution_Time(Milliseconds(4));
          pos:= i;
       end Set_Position;
       
       function Get_Position return Integer is
       begin
          Execution_Time(Milliseconds(8));
          return pos;
       end Get_Position;
       
       procedure Calculate_Dangerous_Distance(dist: in Distance_Samples_Type; security_dist: in Distance_Samples_Type) is
      begin
         Execution_Time(Milliseconds(2));
         for i in 1..3 loop
            if dist < (security_dist/Distance_Samples_Type(i)) then
                Set_Position(i);
            end if;
         end loop;
      end Calculate_Dangerous_Distance;
      
      procedure take_Alarm is
      begin
         Execution_Time(Milliseconds(1));
         if pos = 3 then
            Starting_Notice("PELIGRO COLISION");
         elsif pos = 2 then
            Starting_Notice("DISTANCIA IMPRUDENTE");
         elsif pos = 1 then
            Starting_Notice("DISTANCIA INSEGURA");
         else
            Starting_Notice("SEGURO ");
         end if;
      end take_Alarm;
      
      procedure Turn_Light is
      begin
         Execution_Time(Milliseconds(7));
         if pos = 1 then
            Light(On);
         end if;
         Light(Off);
      end Turn_Light;
       
      procedure Giro_Brusco(whlB: in Steering_Samples_Type; whlA: in Steering_Samples_Type) is
      begin
         Execution_Time(Milliseconds(3));
         if ((whlA+20) < whlB or (whlA-20) > whlB) then
            Put_Line("VOLANTAZO BRUSCO");
            rude := True;
         else
            rude := False;
         end if;
      end Giro_Brusco;
      
      function Get_Rude return Boolean is
      begin
          Execution_Time(Milliseconds(2));
          return rude;
      end Get_Rude; 
      
      function Get_Head_Warning return Boolean is
      begin
          Execution_Time(Milliseconds(1));
          return head_warning;
      end Get_Head_Warning;
   end Sign;   
   
   
       
    
    -----------------------------------------------------------------------
    ----------------------- declaration of tasks --------------------------
    -----------------------------------------------------------------------

    -- Aqui se declaran las tareas que forman el STR
    --Type Volume is new integer range 1..5;

   task body Head_Security is
      cab: HeadPosition_Samples_Type;
      next_delay: Time;
      cont: Integer:= 0;
      I : Time;
      D : Time_span;
   begin
      loop
	 I := clock;
         Starting_Notice("Cabeza");
         next_delay:= Clock + Milliseconds(400);
         Reading_HeadPosition(cab);
         Measures.Set_Cabeza(cab);
         Sign.Aviso_Cabeza(Measures.Get_Cabeza, cont);
         D := clock - I;
         Kernel.Serial_Output.Put("WCET Cabeza" & Duration'Image(To_Duration(D)));
         delay until next_delay;
         Finishing_Notice("End cabeza");
      end loop;
   end Head_Security;
    
    task body Distance is
      speed: Speed_Samples_Type;
      dist:  Distance_Samples_Type;
      security_dist: Distance_Samples_Type;
      next_delay: Time;
      I : Time;
      D : Time_span;
   begin
      loop
         I := clock;	    
         Starting_Notice("Distancia");
         next_delay := Clock + milliseconds(300);
         Reading_Speed (speed);
         Reading_Distance (dist);
         Measures.Set_Distance(dist);
         Measures.Set_Speed(speed);
         security_dist := Measures.Calculate_security_distance;
         Sign.Calculate_Dangerous_Distance(dist,security_dist);
         D := clock - I;
         Kernel.Serial_Output.Put("WCET Duration" & Duration'Image(To_Duration(D)));
         delay until next_delay;
         Finishing_Notice("End distacia");
      end loop;
   end Distance;

   task body Volante_Steering is
      whl_B,whl_A: Steering_Samples_Type;
      next_delay: Time;
      I : Time;
      D : Time_span;
   begin
      Reading_Steering(whl_B);
      Measures.Set_Volante(whl_B);
      loop
         I := clock;
         Starting_Notice("Volante");
         next_delay := Clock + milliseconds(350);
         Reading_Steering(whl_A);
         Sign.Giro_Brusco(Measures.Get_Volante,Whl_A);
         Measures.Set_Volante(Whl_A);
         D := clock - I;
         Kernel.Serial_Output.Put("WCET Volante" & Duration'Image(To_Duration(D)));
         delay until next_delay;
         Finishing_Notice("End volante");
      end loop;
   end Volante_Steering;
   
   task body Risk is
      next_delay: Time;
      cont: Integer := 1;
      I : Time;
      D : Time_span;
   begin

      loop 
         next_delay := Clock + Milliseconds(150);
         Starting_Notice("Riesgos");         
         delay until next_delay;
         I := clock;
         if Sign.Get_Rude = True then
            Beep(1);
            Light(Off); 
         elsif Sign.Get_Head_Warning = True and Sign.Get_Position = 3 then
            Beep(5);
            Light(Off); 
            Activate_Brake;
         elsif Sign.Get_Head_Warning = True and Measures.Get_Speed > 70 then
            Beep(3); 
            Light(Off);           
         elsif Sign.Get_Head_Warning = True then
            Beep(2);
            Light(Off);            
         elsif Sign.Get_Position = 1 then
            Light(On);           
         elsif Sign.Get_Position = 2 then
            Beep(4);           
            Light(On);
         else 
            Light(Off);           
         end if;
         D := clock - I;
         Kernel.Serial_Output.Put("WCET Risk" & Duration'Image(To_Duration(D)));
         Finishing_Notice("End riesgo");
      end loop;
   end Risk;
   
   task body Display is
      cont: Integer:= 0;
      next_delay: Time;
      I : Time;
      D : Time_span;
   begin 
      loop
         I := clock;
      	 Starting_Notice("Display.");
         next_delay := Clock + Milliseconds(1000); 
         Display_HeadPosition_Sample(Measures.Get_Cabeza);
         Display_Distance (Measures.Get_Distance);
         Display_Speed (Measures.Get_Speed);
         Sign.take_Alarm;  
         Display_Steering(Measures.Get_Volante);
         D := clock - I;
         Kernel.Serial_Output.Put("WCET Display" & Duration'Image(To_Duration(D)));
         delay until next_delay;
	 Finishing_Notice("End display");
      end loop;
   end Display;
   
begin
   Starting_Notice ("Programa Principal");
 
   Finishing_Notice ("Programa Principal");
end add;




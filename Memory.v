module memory(
	SW,
	CLOCK_50,
	KEY,
	LEDR,
	HEX0,
	HEX1,
	HEX2,
	HEX3,
	HEX4,
	HEX5,
	HEX6,
	HEX7
);

	input [4:0] SW;
	input [3:0] KEY;
	wire resetN;
	assign resetN = KEY[0];
	wire guess;
	assign guess = ~KEY[3];
	input CLOCK_50;
	
	output [17:0] LEDR;
	output [6:0] HEX0;	
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;	
	output [6:0] HEX5;
	output reg [6:0] HEX6;
	output reg [6:0] HEX7;
	
	
	reg [6:0] rtest;
	// clear Hex displays for now
	assign HEX4 = rtest;
	assign HEX5 = 7'b1111111;
	
	assign LEDR[13] = load0[0];
	assign LEDR[14] = load1[0];
	assign LEDR[15] = load2[0];
	assign LEDR[16] = load3[0];
	assign LEDR[17] = load4[0];
	
	reg [3:0] state, next_state;
	
	localparam 	  RESET 			= 4'b0000,	// 0
				  SET_NEWBIT		= 4'b0001,	// 1
				  PERM_SET			= 4'b0010,	// 2
				  FLASH_LOAD		= 4'b0011,	// 3
				  FLASH				= 4'b0100,	// 4
				  PLAYER_LOAD		= 4'b0101,	// 5
				  PLAYER_IN			= 4'b0110,	// 6
				  CORRECT			= 4'b0111,	// 7
				  PLAYER_WAIT		= 4'b1000,	// 8
				  GAME_OVER			= 4'b1001;	// 9
				  
	reg flash_load_done, n_flash_load_done;
	reg flash_done, n_flash_done;
	
	reg [2:0] index; // no need to reset as it should be random
	reg [49:0] newbit, n_newbit; // redeclared each time no need to reset
	
	reg [5:0] count, n_count; // reset only at start of game
	
	reg flash_enable, n_flash_enable;	// signal to start flashing
	reg flash_load, n_flash_load;		// signal to load permenant register values into flash registers
	reg game_over, n_game_over;			// signal to trigger game_over
	
	// records the values to always be loaded
	reg [49:0] perm0, n_perm0;
	reg [49:0] perm1, n_perm1;
	reg [49:0] perm2, n_perm2;
	reg [49:0] perm3, n_perm3;
	reg [49:0] perm4, n_perm4;
	
	// registers to hold sequences to flash
	reg [49:0] flash0, n_flash0;
	reg [49:0] flash1, n_flash1;
	reg [49:0] flash2, n_flash2;
	reg [49:0] flash3, n_flash3;
	reg [49:0] flash4, n_flash4;
	
	// registers to check the users input
	reg [49:0] load0, n_load0;
	reg [49:0] load1, n_load1;
	reg [49:0] load2, n_load2;
	reg [49:0] load3, n_load3;
	reg [49:0] load4, n_load4;
	
	// signals to hold the users current guess
	reg guess0, n_guess0;
	reg guess1, n_guess1;
	reg guess2, n_guess2;
	reg guess3, n_guess3;
	reg guess4, n_guess4;
	
	// registers to keep track of the users current score
	reg [3:0] ones, n_ones;
	reg [3:0] tens, n_tens;
	reg [3:0] hund, n_hund;
	reg [3:0] thou, n_thou;
	
	// pseudo random index
	always @(*)
	begin
		if (index == 3'b100)
		begin
			index = 3'b000;
		end
		else
		begin
			index = (index + 1);
		end
	end
	
	always @(*)
	begin
		// set all stat special state enablers to 0
		n_flash_enable = 1'b0;
		n_flash_load = 1'b0;
		n_game_over = 1'b0;
		
		case(state)
		RESET: begin
			n_count = 1'b0;
			
			n_perm0 = 1'b0;
			n_perm1 = 1'b0;
			n_perm2 = 1'b0;
			n_perm3 = 1'b0;
			n_perm4 = 1'b0;
			
			// flash registers reset before every flash enable
			
			// guess registers reset before every guess check
		
			n_ones = 1'b0;
			n_tens = 1'b0;
			n_hund = 1'b0;
			n_thou = 1'b0;
			
			next_state = SET_NEWBIT;
			
			rtest = 7'b1000000;
		end
		
		SET_NEWBIT: begin
			// set the count'th bit to the randomly generated one
			n_newbit = 49'b00000000000000000000000000000000000000000000000001<< count;
			next_state = PERM_SET;
			
			rtest = 7'b1111001;
		end
		
		PERM_SET: begin
			
			rtest = 7'b0100100;
			
			// by default set all registers to what they were before
			n_perm0 = perm0;
			n_perm1 = perm1;
			n_perm2 = perm2;
			n_perm3 = perm3;
			n_perm4 = perm4;
			
			// change the index'th permenant register
			if (index == 3'b000)
			begin
				n_perm0 = perm0 | newbit;
			end
			else if (index == 3'b001)
			begin
				n_perm1 = perm1 | newbit;
			end
			else if (index == 3'b010)
			begin
				n_perm2 = perm2 | newbit;
			end
			else if (index == 3'b011)
			begin
				n_perm3 = perm3 | newbit;
			end
			else if (index == 3'b100)
			begin
				n_perm4 = perm4 | newbit;
			end
			
			next_state = FLASH_LOAD;
		end
		
		FLASH_LOAD: begin
			
			rtest = 7'b0110000;
			
			n_flash_load = 1'b1;
			
			next_state = flash_load_done ? FLASH : FLASH_LOAD;
		end
		
		FLASH: begin
			
			rtest = 7'b0011001;
			
			n_flash_enable = 1'b1;
		
			next_state = flash_done ? PLAYER_LOAD : FLASH;
		end
		
		PLAYER_LOAD: begin
			
			rtest = 7'b0010010;
			
			n_load0 = perm0;
			n_load1 = perm1;
			n_load2 = perm2;
			n_load3 = perm3;
			n_load4 = perm4;
			
			next_state = PLAYER_IN;
		end
		
		PLAYER_IN: begin
			
			rtest = 7'b0000010;
			
			// exit when there is no correct input (reached the end of the round)
			if (load0[0] == 1'b0 &&
				load1[0] == 1'b0 &&
				load2[0] == 1'b0 &&
				load3[0] == 1'b0 &&
				load4[0] == 1'b0)
			begin
				n_count = count + 1;
				next_state = SET_NEWBIT;
			end
			// if user clicks the guess key the value is loaded in
			else if (guess == 1'b1)
			begin
				n_guess0 = SW[0];
				n_guess1 = SW[1];
				n_guess2 = SW[2];
				n_guess3 = SW[3];
				n_guess4 = SW[4];
				next_state = CORRECT;
			end
		end
		
		CORRECT: begin
			
			rtest = 7'b1111000;
			
			// check if the user is correct
			if (guess0 == load0[0] &&
				guess1 == load1[0] &&
				guess2 == load2[0] &&
				guess3 == load3[0] &&
				guess4 == load4[0])
			begin
				// if they are correct shift all registers RIGHT and change states
				n_load0 = load0 >> 1;
				n_load1 = load1 >> 1;
				n_load2 = load2 >> 1;
				n_load3 = load3 >> 1;
				n_load4 = load4 >> 1;
				
				// increase score
				if (ones == 4'b1001)
				begin
					n_ones = 0;
					if (tens == 4'b1001)
					begin
						n_tens = 0;
						if (hund == 4'b1001)
						begin
							n_hund = 0;
							if (thou == 4'b1001)
							begin
								n_thou = 0;
							end
							else
							begin
								n_thou = thou + 1;
							end
						end
						else
						begin
							n_hund = hund + 1;
						end
					end
					else
					begin
						n_tens = tens + 1;
					end
				end
				else
				begin
					n_ones = ones + 1;
				end
				
				next_state = PLAYER_WAIT;
			end
			// otherwise game over
			else
			begin
				next_state = GAME_OVER;
			end
		end
		
		PLAYER_WAIT: begin
				
			rtest = 7'b0000000;
			
			// wait until the player has changed all switches to 0 state before continuing
			if (SW[0] == 1'b0 &&
				SW[1] == 1'b0 &&
				SW[2] == 1'b0 &&
				SW[3] == 1'b0 &&
				SW[4] == 1'b0)
			begin
				n_guess0 = 1'b0;
				n_guess1 = 1'b0;
				n_guess2 = 1'b0;
				n_guess3 = 1'b0;
				n_guess4 = 1'b0;
				
				next_state = PLAYER_IN;
			end
		end
		
		GAME_OVER: begin
			
			rtest = 7'b0011000;
			
			n_game_over = 1'b1;
		end	
		default: next_state = RESET;
		endcase
	end
	
	// signal clk will go high once every second
	wire clk;
	
	// 1 Hz
	rate_divider rd0(
		.game_clock(clk),
		.select(2'b10),
		.clk(CLOCK_50),
		.resetN(resetN)
	);
	
	// used to show when one flash has occurred in case duplciate values occur
	reg moment, n_moment;
	
	// LEDRs 10 to 6 display the pattern to match, LEDR 11 shows when the next signal occurs
	assign LEDR[6] = flash0[0];
	assign LEDR[7] = flash1[0];
	assign LEDR[8] = flash2[0];
	assign LEDR[9] = flash3[0];
	assign LEDR[10] = flash4[0];
	
	assign LEDR[11] = moment;
	
	// if flash enable is on, flash once every second according to rate divider
	always @(posedge clk)
	begin
		n_flash_load_done = 1'b0;
		n_flash_done = 1'b0;
		
		// if flash load is enabled load values into flash registers
		if (flash_load == 1'b1)
		begin
			n_flash0 = perm0;
			n_flash1 = perm1;
			n_flash2 = perm2;
			n_flash3 = perm3;
			n_flash4 = perm4;
			
			n_flash_load_done = 1'b1;
		end
		// if flash is enabled flash once
		else if (flash_enable == 1'b1)
		begin
			// if done output done
			if (flash0[0] == 1'b0 &&
				flash1[0] == 1'b0 &&
				flash2[0] == 1'b0 &&
				flash3[0] == 1'b0 &&
				flash4[0] == 1'b0)
			begin
				n_flash_done = 1'b1;
			end
			// otherwise shift all flash registers over
			else
			begin
				n_flash0 = flash0 >> 1;
				n_flash1 = flash1 >> 1;
				n_flash2 = flash2 >> 1;
				n_flash3 = flash3 >> 1;
				n_flash4 = flash4 >> 1;
				
				// reverse moment to show that a moment has passed
				n_moment = ~moment;
			end
		end
		else
		begin
			// if nothing is enabled reset moment
			n_moment = 1'b0;
		end
	end
	
	// hex displays
	hex_display hd0(
		.IN(ones),
		.OUT(HEX0)
	);
	hex_display hd1(
		.IN(tens),
		.OUT(HEX1)
	);
	hex_display hd2(
		.IN(hund),
		.OUT(HEX2)
	);
	hex_display hd3(
		.IN(thou),
		.OUT(HEX3)
	);
	
	always@(*)
	begin
		// if game is over display GO
		if (game_over == 1'b1)
		begin
			HEX6 = 7'b1000000; // O
			HEX7 = 7'b1000010; // G
		end
		// if it isn't over make sure the displays shown nothing
		else
		begin
			HEX6 = 7'b1111111;
			HEX7 = 7'b1111111;
		end
	end
	
	// update values on a positive edge
	always @(posedge CLOCK_50)
	begin
		if (resetN == 1'b0)
		begin
			// reset will take care of all the reseting
			state = RESET;
		end
		else
		begin
			flash_load_done = n_flash_load_done;
			flash_done = n_flash_done;
			
			newbit = n_newbit;
			count = n_count;
			
			flash_enable = n_flash_enable;
			flash_load = n_flash_load;
			game_over = n_game_over;
			
			perm0 = n_perm0;
			perm1 = n_perm1;
			perm2 = n_perm2;
			perm3 = n_perm3;
			perm4 = n_perm4;
			
			flash0 = n_flash0;
			flash1 = n_flash1;
			flash2 = n_flash2;
			flash3 = n_flash3;
			flash4 = n_flash4;
			
			load0 = n_load0;
			load1 = n_load1;
			load2 = n_load2;
			load3 = n_load3;
			load4 = n_load4;
			
			guess0 = n_guess0;
			guess1 = n_guess1;
			guess2 = n_guess2;
			guess3 = n_guess3;
			guess4 = n_guess4;
			
			ones = n_ones;
			tens = n_tens;
			hund = n_hund;
			thou = n_thou;
		
			state = next_state;
		end
	end
endmodule


module rate_divider(game_clock, select, clk, resetN);
	input [1:0] select;
	input clk;
	input resetN;
	
	output game_clock;
	
	reg [27:0] regspeedmax;
	reg [27:0] ratecounter;
	
	reg regenable;
	
	always @(*)
	begin
		case (select[1:0])
			2'b00: regspeedmax = 26'b00001100101101110011010100; // 15 Hz (3 333 332 in binary)
			2'b01: regspeedmax = 26'b00010011000100101100111111; // 10 Hz (4 999 999 in binary)
			2'b10: regspeedmax = 26'b01011111010111100000111111; // 2  Hz (24 999 999 in binary)
			2'b11: regspeedmax = 26'b10111110101111000001111111; // 1  Hz (49 999 999 in binary)
		endcase
	end
	
	wire [27:0] speedmax;	
	assign speedmax = regspeedmax;
	
	// the rate divider count
	always @(posedge clk, negedge resetN)
	begin		
		if (resetN == 1'b0) 	// if the reset switch is set low
			begin
				ratecounter <= 0;
				regenable <= 0;
			end
		else if (ratecounter == speedmax)
			begin
				ratecounter <= 0;
				regenable <= 1'b1;
			end
		else
			begin
				regenable <= 0; 	// if the counter is not at max, enable should be set to 0
				ratecounter <= ratecounter + 26'b00000000000000000000000001;
			end
	end
	
	assign game_clock = regenable;
endmodule


// displays input on HEX display
module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule


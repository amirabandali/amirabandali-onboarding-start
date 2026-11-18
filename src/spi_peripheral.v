`default_nettype none

module spi_peripheral (
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input  wire [7:0] ui_in,    // Dedicated inputs

    // declaring output ports
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

// synchronized readings
reg sclk_sync_1;
reg sclk_sync_2;
reg copi_sync_1;
reg copi_sync_2;
reg ncs_sync_1;
reg ncs_sync_2;

// edge detection
reg sclk_previous;

// bit counting
reg [4:0] bit_counter;

// transaction finalization
reg ncs_previous;
wire ncs_rising_edge = ncs_sync_2 && !ncs_previous;
wire ncs_falling_edge = !ncs_sync_2 && ncs_previous;

// address validation
localparam [6:0] max_address = 7'h04; 
reg [15:0] shift_register;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_sync_1 <= 0;
        sclk_sync_2 <= 0;
        copi_sync_1 <= 0;
        copi_sync_2 <= 0;
        ncs_sync_1 <= 1;
        ncs_sync_2 <= 1;

        sclk_previous <= 0;

        ncs_previous <= 1;
    end

    else begin
        sclk_sync_1 <= ui_in[0];
        sclk_sync_2 <= sclk_sync_1;
        copi_sync_1 <= ui_in[1];
        copi_sync_2 <= copi_sync_1;
        ncs_sync_1 <= ui_in[2];
        ncs_sync_2 <= ncs_sync_1;

        sclk_previous <= sclk_sync_2;

        ncs_previous <= ncs_sync_2;
    end
end

// edge detection
wire sclk_edge_rising = (sclk_sync_2 && !sclk_previous);        // both values are 1
wire sclk_edge_falling = (!sclk_sync_2 && sclk_previous);       // both values are 0

// bit counting
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_counter <= 0;
        shift_register <= 16'd0;
    end

    else if (ncs_falling_edge) begin
        bit_counter <= 0;
        shift_register <= 16'd0;
    end

    else if (!ncs_sync_2 && sclk_edge_rising && bit_counter < 16) begin
        bit_counter <= bit_counter + 1;
        shift_register <= {shift_register[14:0], copi_sync_2};
    end
end

// address validation
wire read_write = shift_register[15];
wire [6:0] address = shift_register[14:8];
wire [7:0] data = shift_register[7:0];

// transaction finalization
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_reg_out_7_0 <= 8'h00;
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0 <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle <= 8'h00;
    end

    else begin
        if (ncs_rising_edge) begin
            if (bit_counter == 16) begin
                if (address <= max_address) begin
                    if (read_write) begin
                        case (address)
                            7'h00: en_reg_out_7_0 <= data;
                            7'h01: en_reg_out_15_8 <= data;
                            7'h02: en_reg_pwm_7_0 <= data;
                            7'h03: en_reg_pwm_15_8 <= data;
                            7'h04: pwm_duty_cycle <= data;
                        endcase
                    end
                end
            end
        end
    end
endmodule
module alu (
    input                i_clk,
    input                i_rst_n,
    input                i_valid,
    input  signed [11:0] i_data_a,
    input  signed [11:0] i_data_b,
    input         [ 2:0] i_inst,
    output               o_valid,
    output        [11:0] o_data,
    output               o_overflow
);

  // ---------------------------------------------------------------------------
  // Wires and Registers
  // ---------------------------------------------------------------------------
  reg [11:0] o_data_w, o_data_r;
  reg o_valid_w, o_valid_r;
  reg o_overflow_w, o_overflow_r;
  reg prev_overflow_r;
  reg mac_mult_overflow_w;
  reg mac_add_overflow_w;
  reg mac_overflow_res_w;
  reg signed [11:0] abs_a_w, abs_b_w;
  reg signed [12:0] mean_w;
  reg signed [12:0] sum_w;
  reg signed [12:0] diff_w;
  reg signed [23:0] mult_result_w;
  reg signed [23:0] mac_mult_result_w;
  reg signed [23:0] fixed_format_w;
  reg signed [23:0] mac_fixed_format_w;
  reg signed [12:0] prev_accumulator_r;
  reg signed [12:0] accumulator_w;
  reg signed [24:0] rounded_w;
  reg signed [24:0] mac_rounded_w;
  // ---- Add your own wires and registers here if needed ---- //


  // ---------------------------------------------------------------------------
  // Continuous Assignment
  // ---------------------------------------------------------------------------
  assign o_valid = o_valid_r;
  assign o_data = o_data_r;
  assign o_overflow = o_overflow_r;
  // ---- Add your own wire data assignments here if needed ---- //


  // ---------------------------------------------------------------------------
  // Combinational Block
  // ---------------------------------------------------------------------------
  // ---- Write your conbinational block design here ---- //

  always @(i_clk) begin

    o_valid_w = 1'b0;
    o_overflow_w = 1'b0;
    o_data_w = 12'b0;
    mac_overflow_res_w = 1'b0;
    sum_w = 13'b0;
    diff_w = 13'b0;
    mult_result_w = 24'b0;
    rounded_w = 25'b0;
    fixed_format_w = 24'b0;
    mac_mult_result_w = 24'b0;
    mac_rounded_w = 25'b0;
    mac_fixed_format_w = 24'b0;
    accumulator_w = prev_accumulator_r;
    mean_w = 13'b0;
    abs_a_w = 12'b0;
    abs_b_w = 12'b0;


    if (i_valid) begin

      o_valid_w = 1'b1;

      if (i_inst != 3'b011) begin
        accumulator_w = 13'b0;
      end


      case (i_inst)
        3'b000: begin
          sum_w = i_data_a + i_data_b;
          o_data_w = sum_w[11:0];
          o_overflow_w = (i_data_a[11] == i_data_b[11]) && (sum_w[11] != i_data_a[11]);
        end  // ADD

        3'b001: begin
          diff_w = i_data_a - i_data_b;
          o_data_w = diff_w[11:0];
          o_overflow_w = (i_data_a[11] != i_data_b[11]) && (i_data_a[11] != diff_w[11]);
        end  // SUBTRACT

        3'b010: begin
          mult_result_w = i_data_a * i_data_b;
          rounded_w = mult_result_w + 25'd16;
          fixed_format_w = {{5{rounded_w[23]}}, rounded_w[23:5]};  //sign extend and shift by 5
          o_overflow_w = ({12{fixed_format_w[11]}} != fixed_format_w[23:12]);
          o_data_w = fixed_format_w[11:0];
        end  // MULTIPLY

        3'b011: begin
          mac_mult_result_w = i_data_a * i_data_b;
          mac_rounded_w = mac_mult_result_w + 25'd16;
          mac_fixed_format_w = {{5{mac_rounded_w[23]}}, mac_rounded_w[23:5]};
          accumulator_w = prev_accumulator_r + {mac_fixed_format_w[11], mac_fixed_format_w[11:0]};
          o_data_w = accumulator_w[11:0];
          mac_overflow_res_w = (({12{mac_fixed_format_w[11]}} != mac_fixed_format_w[23:12]) || ((prev_accumulator_r[12] == mac_fixed_format_w[11]) && (accumulator_w[11] != mac_fixed_format_w[11])));
          //({2{accumulator_w[11]}} != accumulator_w[12:11]);
          o_overflow_w = prev_overflow_r || mac_overflow_res_w;
        end  // MAC

        3'b100: begin
          o_data_w = ~(i_data_a ^ i_data_b);
        end  // XNOR

        3'b101: begin
          o_data_w = (i_data_a[11] == 0) ? i_data_a : 12'd0;
        end  // ReLU

        3'b110: begin
          mean_w   = i_data_a + i_data_b;
          o_data_w = mean_w >> 1;
        end  // MEAN

        3'b111: begin
          abs_a_w  = (i_data_a[11] == 1'b1) ? (~i_data_a + 1) : i_data_a;
          abs_b_w  = (i_data_b[11] == 1'b1) ? (~i_data_b + 1) : i_data_b;
          o_data_w = (abs_a_w > abs_b_w) ? abs_a_w : abs_b_w;
        end  // ABSOLUTE MAX

        default: begin
          o_data_w = 12'b0;
          o_valid_w = 1'b0;
          o_overflow_w = 1'b0;
        end  // Default case

      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // Sequential Block
  // ---------------------------------------------------------------------------
  // ---- Write your sequential block design here ---- //

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_data_r <= 0;
      o_overflow_r <= 0;
      o_valid_r <= 0;
      prev_accumulator_r <= 0;
      prev_overflow_r <= 0;
    end else begin
      o_data_r <= o_data_w;
      o_overflow_r <= o_overflow_w;
      o_valid_r <= o_valid_w;
      prev_accumulator_r <= accumulator_w;
      prev_overflow_r <= mac_overflow_res_w;
    end
  end
endmodule


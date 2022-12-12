module spi_master
#(parameter SPI_MODE=0,parameter CLKS_PER_HALF_BIT=2)
(
	input clk,reset_n,
	input [7:0] i_tx_byte,
	input i_tx_dv,
	output reg o_tx_ready,
	
	output reg o_rx_dv,
	output reg [7:0] o_rx_byte,
	
	output reg o_spi_clk,
	input i_spi_miso,
	output reg o_spi_mosi
);
wire w_cpol,w_cpha;

reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] spi_clk_count;
reg spi_clk;
reg [4:0] spi_clk_edges;
reg leading_edge;
reg trailing_edge;
reg tx_dv;
reg [7:0] tx_byte;

reg [2:0] rx_bits_count,tx_bits_count;

assign w_cpol = (SPI_MODE == 2) | (SPI_MODE == 3);
assign w_cpha = (SPI_MODE == 1 ) | (SPI_MODE == 3);
always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		o_tx_ready <= 0;
		spi_clk_edges <= 0;
		leading_edge <= 0;
		trailing_edge <= 0;
		spi_clk <= w_cpol;
		spi_clk_count <= 0;
	end
	else
	begin
		leading_edge <= 0;
		trailing_edge <= 0;
		if(i_tx_dv == 1'b1)
		begin
			o_tx_ready <= 0;
			spi_clk_edges <= 16;
		end
		else if(spi_clk_edges >0)
		begin
			o_tx_ready <= 0;
			if(spi_clk_count == CLKS_PER_HALF_BIT*2-1)
			begin
				spi_clk_edges <= spi_clk_edges - 1;
				trailing_edge <= 1;
				spi_clk_count <= 0;
				spi_clk <= ~spi_clk;
			end
			else if(spi_clk_count == CLKS_PER_HALF_BIT-1)
			begin
				spi_clk_edges <= spi_clk_edges - 1;
				leading_edge <= 1;
				spi_clk_count <= spi_clk_count + 1;
				spi_clk <= ~spi_clk;
			end
			else
			begin
				spi_clk_count <= spi_clk_count + 1;
			end
		end
		else
		begin
			o_tx_ready <= 1;
		end
	end
end
always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		tx_byte <= 0;
		tx_dv <= 0;
	end
	else
	begin
		tx_dv <= i_tx_dv;
		if(i_tx_dv)
			tx_byte <= i_tx_byte;
	end
end

always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		o_spi_mosi <= 0;
		tx_bits_count <= 3'b111;
	end
	else
	begin
		if(o_tx_ready)
		begin
			tx_bits_count <= 3'b111;
		end
		else if(tx_dv && ~w_cpha)
		begin
			o_spi_mosi <= tx_byte[3'b111];
			tx_bits_count <= 3'b110;
		end
		else if((leading_edge & w_cpha) | (trailing_edge & ~w_cpha))
		begin
			o_spi_mosi <= tx_byte[tx_bits_count];
			tx_bits_count <= tx_bits_count - 1;
		end
	end
end

always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		o_rx_byte <= 0;
		o_rx_dv <= 0;
		rx_bits_count <= 3'b111;
	end
	else 
	begin
		o_rx_dv <= 0;
		if(o_tx_ready)
			rx_bits_count <= 3'b111;
		else if((leading_edge & ~w_cpha) | (trailing_edge & w_cpha))
		begin
			o_rx_byte[rx_bits_count] <= i_spi_miso;
			rx_bits_count <= rx_bits_count - 1;
			if(rx_bits_count == 3'b000)
				o_rx_dv <= 1;
		end
	end
end
always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		o_spi_clk <= w_cpol;
	end
	else 
	begin
		o_spi_clk <= spi_clk;
	end
end
endmodule
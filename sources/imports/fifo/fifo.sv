/*
Pixel-FIFO
By: Alex Lao of McMaster University
https://github.com/AlexLao512
*/

module fifo #(
    parameter integer ADDR_WIDTH         = 1                ,
    parameter integer DATA_WIDTH         = 1                ,
    parameter integer FIFO_DEPTH         = (1 << ADDR_WIDTH), // Default to max based on address width
    parameter integer INITIAL_FIFO_LEVEL = 0                , // Default empty
    parameter logic   [DATA_WIDTH-1:0] INITIAL_DATA [0:2**ADDR_WIDTH-1] = '{(2**ADDR_WIDTH){'0}} // Default all 0
) (
    input                   clk     ,
    input                   reset   ,
    input                   write_en,
    input                   read_en ,
    input  [DATA_WIDTH-1:0] din     ,
    output                  empty   ,
    output                  full    ,
    output [DATA_WIDTH-1:0] dout    ,
    output [ADDR_WIDTH+1:0] level
);
    
    // FIFO Memory
    logic [DATA_WIDTH-1:0]       fifo_storage [0:2**ADDR_WIDTH-1];
    
    // Read and Write Pointer
    logic [ADDR_WIDTH-1:0]       write_pointer;
    logic [ADDR_WIDTH-1:0]       read_pointer;
    logic [ADDR_WIDTH:0]         fifo_level;
    
    // FIFO Full/Empty
    assign full = (fifo_level == (FIFO_DEPTH));
    assign empty = (fifo_level == 0+read_en);
    assign level = fifo_level;
    
    // Read Data
    assign dout = fifo_storage[read_pointer+read_en];   

    // Write and Read Pointer
    always_ff @ (posedge clk) begin 
        if (reset) begin
            write_pointer <= ((INITIAL_FIFO_LEVEL == FIFO_DEPTH) || (INITIAL_FIFO_LEVEL == 0)) ? 0 : INITIAL_FIFO_LEVEL + 1; //? is a true and false (true:false)
            read_pointer <= 0;
        end else begin
            
            //Write Pointer
            if (write_en && !full) begin
                if (write_pointer == FIFO_DEPTH-1) begin
                    write_pointer <= 0;
                end else begin
                    write_pointer <= write_pointer + 1;
                end
            end
            
            //Read Pointer
            if (read_en && !empty) begin
                if (read_pointer == FIFO_DEPTH-1) begin
                    read_pointer <= 0;
                end else begin
                    read_pointer <= read_pointer + 1;
                end
            end
        end
    end

    // Write Data
    always_ff @ (posedge clk) begin
        if (reset) begin
            fifo_storage <= INITIAL_DATA;
        end else begin
            if (write_en && !full) begin
                fifo_storage[write_pointer] <= din;
            end
        end
    end
    
    // FIFO Level
    always_ff @ (posedge clk) begin
        if (reset) begin
            fifo_level <= INITIAL_FIFO_LEVEL;
        end else begin
            // FIFO level stays the same if a read and write are performed at the same time
            if ((read_en) && !(write_en) && (fifo_level != 0)) begin // Read but no write
                fifo_level <= fifo_level - 1;
                fifo_level <= fifo_level - 1;
            end else if ((write_en) && !(read_en) && (fifo_level != FIFO_DEPTH)) begin // Write but no read
                fifo_level <= fifo_level + 1;
            end
      end
    end
    
endmodule

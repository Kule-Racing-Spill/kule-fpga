module posedge_detect (
    input wire clock,
    input wire signal,
    output logic detected_edge
);
    logic prev_signal;

    always_ff @(posedge clock) begin
        prev_signal <= signal;
    end

    assign detected_edge = signal & ~prev_signal;
endmodule


module negedge_detect (
    input wire clock,
    input wire signal,
    output logic detected_edge
);
    logic prev_signal;

    always_ff @(posedge clock) begin
        prev_signal <= signal;
    end

    assign detected_edge = ~signal & prev_signal;
endmodule
module washing_machine (
    input  logic clk,
    input  logic reset,
    input  logic start,

    output logic fill_valve,
    output logic wash_motor,
    output logic drain_pump,
    output logic spin_motor,
    output logic done
);

    // FSM states
    typedef enum logic [2:0] {
        IDLE,
        FILL,
        WASH,
        DRAIN,
        SPIN,
        DONE
    } state_t;

    state_t current_state, next_state;

    // Counter
    logic [3:0] count;

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            count <= 0;
        end
        else begin
            current_state <= next_state;

            if (current_state != next_state)
                count <= 0;
            else
                count <= count + 1;
        end
    end

    // Next-state logic
    always_comb begin

        next_state = current_state;

        case (current_state)

            IDLE: begin
                if (start)
                    next_state = FILL;
            end

            FILL: begin
                if (count == 4)
                    next_state = WASH;
            end

            WASH: begin
                if (count == 9)
                    next_state = DRAIN;
            end

            DRAIN: begin
                if (count == 4)
                    next_state = SPIN;
            end

            SPIN: begin
                if (count == 9)
                    next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default:
                next_state = IDLE;

        endcase
    end

    // Output logic
    always_comb begin

        fill_valve = 0;
        wash_motor = 0;
        drain_pump = 0;
        spin_motor  = 0;
        done        = 0;

        case (current_state)

            FILL:
                fill_valve = 1;

            WASH:
                wash_motor = 1;

            DRAIN:
                drain_pump = 1;

            SPIN:
                spin_motor = 1;

            DONE:
                done = 1;

            default: begin
                fill_valve = 0;
                wash_motor = 0;
                drain_pump = 0;
                spin_motor = 0;
                done = 0;
            end

        endcase
    end

endmodule
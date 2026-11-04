
`timescale 1ns/1ps

module atm_controller (
    input clk,
    input rst,

    // User input buttons
    input card_in,
    input pin_submit,
    input pin_correct,
    input withdraw,
    input deposit,
    input balance,
    input confirm,
    input cancel,
    input eject,

    // State output
    output reg [3:0] state_out,

    // ATM status outputs
    output dispense_cash,
    output deposit_ack,
    output show_balance,
    output transaction_done,
    output cancelled,
    output card_eject
);

// State declarations
parameter IDLE             = 4'b0000;
parameter CARD_DETECTED    = 4'b0001;
parameter PIN_ENTRY        = 4'b0010;
parameter PIN_VERIFY       = 4'b0011;
parameter MAIN_MENU        = 4'b0100;
parameter WITHDRAWAL       = 4'b0101;
parameter CASH_DISPENSE    = 4'b0110;
parameter DEPOSIT          = 4'b0111;
parameter DEPOSIT_PROCESS  = 4'b1000;
parameter BALANCE_ENQUIRY  = 4'b1001;
parameter TRANSACTION_DONE = 4'b1010;
parameter CANCELLED        = 4'b1011;
parameter EJECT_CARD       = 4'b1100;

// State register
reg [3:0] state;

// Sequential FSM
always @(posedge clk or posedge rst)
begin
    if (rst)
        state <= IDLE;

    // Cancel has priority
    else if (cancel && state != IDLE &&
             state != EJECT_CARD)
        state <= CANCELLED;

    else
    begin
        case (state)

            IDLE:
                if (card_in)
                    state <= CARD_DETECTED;

            CARD_DETECTED:
                state <= PIN_ENTRY;

            PIN_ENTRY:
                if (pin_submit)
                    state <= PIN_VERIFY;

            PIN_VERIFY:
                if (pin_correct)
                    state <= MAIN_MENU;
                else
                    state <= PIN_ENTRY;

            MAIN_MENU:
            begin
                if (withdraw)
                    state <= WITHDRAWAL;

                else if (deposit)
                    state <= DEPOSIT;

                else if (balance)
                    state <= BALANCE_ENQUIRY;
            end

            WITHDRAWAL:
                if (confirm)
                    state <= CASH_DISPENSE;

            CASH_DISPENSE:
                state <= TRANSACTION_DONE;

            DEPOSIT:
                if (confirm)
                    state <= DEPOSIT_PROCESS;

            DEPOSIT_PROCESS:
                state <= TRANSACTION_DONE;

            BALANCE_ENQUIRY:
                state <= MAIN_MENU;

            TRANSACTION_DONE:
                state <= EJECT_CARD;

            CANCELLED:
                state <= EJECT_CARD;

            EJECT_CARD:
                if (eject)
                    state <= IDLE;

            default:
                state <= IDLE;

        endcase
    end
end

// Expose FSM state
always @(*)
begin
    state_out = state;
end

// Output decoding
assign dispense_cash =
    (state == CASH_DISPENSE);

assign deposit_ack =
    (state == DEPOSIT_PROCESS);

assign show_balance =
    (state == BALANCE_ENQUIRY);

assign transaction_done =
    (state == TRANSACTION_DONE);

assign cancelled =
    (state == CANCELLED);

assign card_eject =
    (state == EJECT_CARD);

endmodule

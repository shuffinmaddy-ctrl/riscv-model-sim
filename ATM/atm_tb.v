`timescale 1ns/1ps

module atm_controller_tb;

reg clk, rst;

reg card_in;
reg pin_submit;
reg pin_correct;

reg withdraw;
reg deposit;
reg balance;
reg confirm;
reg cancel;
reg eject;

wire [3:0] state_out;

wire dispense_cash;
wire deposit_ack;
wire show_balance;
wire transaction_done;
wire cancelled;
wire card_eject;

// DUT instantiation
atm_controller uut (
    .clk(clk),
    .rst(rst),

.card_in(card_in),
    .pin_submit(pin_submit),
    .pin_correct(pin_correct),

.withdraw(withdraw),
    .deposit(deposit),
    .balance(balance),
    .confirm(confirm),
    .cancel(cancel),
    .eject(eject),

    .state_out(state_out),

.dispense_cash(dispense_cash),
    .deposit_ack(deposit_ack),
    .show_balance(show_balance),
    .transaction_done(transaction_done),
    .cancelled(cancelled),
    .card_eject(card_eject)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Display state names
function [159:0] state_name;
    input [3:0] s;
    begin
        case(s)
            4'b0000: state_name = "IDLE";
            4'b0001: state_name = "CARD_DETECTED";
            4'b0010: state_name = "PIN_ENTRY";
            4'b0011: state_name = "PIN_VERIFY";
            4'b0100: state_name = "MAIN_MENU";
            4'b0101: state_name = "WITHDRAWAL";
            4'b0110: state_name = "CASH_DISPENSE";
            4'b0111: state_name = "DEPOSIT";
            4'b1000: state_name = "DEPOSIT_PROCESS";
            4'b1001: state_name = "BALANCE_ENQUIRY";
            4'b1010: state_name = "TRANSACTION_DONE";
            4'b1011: state_name = "CANCELLED";
            4'b1100: state_name = "EJECT_CARD";
            default: state_name = "UNKNOWN";
        endcase
    end
endfunction

// Monitor every state transition
always @(state_out)
begin
    $display("TIME=%0t | STATE=%s | STATE_CODE=%b | CASH=%b | DEPOSIT=%b | BALANCE=%b | CANCEL=%b | EJECT=%b",
        $time,
        state_name(state_out),
        state_out,
        dispense_cash,
        deposit_ack,
        show_balance,
        cancelled,
        card_eject
    );
end

// Test stimulus
initial begin

// Initialize inputs
    rst = 1;

card_in = 0;
    pin_submit = 0;
    pin_correct = 0;

withdraw = 0;
    deposit = 0;
    balance = 0;
    confirm = 0;
    cancel = 0;
    eject = 0;

#12;
    rst = 0;

// Insert card
    #8;
    card_in = 1;
    #10;
    card_in = 0;

// PIN entry
    #10;
    pin_submit = 1;
    #10;
    pin_submit = 0;

// Correct PIN
    pin_correct = 1;
    #10;
    pin_correct = 0;

// Select withdrawal
    #10;
    withdraw = 1;
    #10;
    withdraw = 0;

// Confirm withdrawal
    #10;
    confirm = 1;
    #10;
    confirm = 0;

// Wait for transaction completion and eject
    #20;
    eject = 1;
    #10;
    eject = 0;

// Insert card again
    #10;
    card_in = 1;
    #10;
    card_in = 0;

// PIN entry and verification
    #10;
    pin_submit = 1;
    #10;
    pin_submit = 0;

pin_correct = 1;
    #10;
    pin_correct = 0;

// Select deposit
    #10;
    deposit = 1;
    #10;
    deposit = 0;

// CANCEL operation
    #10;
    cancel = 1;
    #10;
    cancel = 0;

// Eject after cancellation
    #20;
    eject = 1;
    #10;
    eject = 0;

// Insert card for balance enquiry
    #10;
    card_in = 1;
    #10;
    card_in = 0;

#10;
    pin_submit = 1;
    #10;
    pin_submit = 0;

pin_correct = 1;
    #10;
    pin_correct = 0;

#10;
    balance = 1;
    #10;
    balance = 0;

// Finish balance enquiry flow
    #20;
    eject = 1;
    #10;
    eject = 0;

end

endmodule
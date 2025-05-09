CREATE TABLE bank_accounts (
    account_number VARCHAR2(20) PRIMARY KEY,
    account_name VARCHAR2(100),
    balance NUMBER(10, 2)
);

CREATE SEQUENCE transaction_seq INCREMENT BY 1 START WITH 1;
CREATE TABLE transaction(
    log_id NUMBER PRIMARY KEY,
    account_number VARCHAR2(20),
    transaction_type VARCHAR2(20),
    amount NUMBER(10, 2),
    transaction_date DATE DEFAULT SYSDATE,
    FOREIGN KEY (account_number) REFERENCES bank_accounts(account_number)
);

INSERT INTO bank_accounts VALUES ('ACC001', 'Alice Martins', 5000.00);
INSERT INTO bank_accounts VALUES ('ACC002', 'John Peters', 3000.00);

--task 2: Create a procedure that makes deposits to the account;

CREATE OR REPLACE PROCEDURE deposit(
    p_account_number IN VARCHAR2,
    p_amount IN NUMBER
)
AS
    v_count NUMBER;
    v_new_balance NUMBER;
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Deposit amount must be positive.');
    END IF;

    -- Check if account exists
    SELECT COUNT(*) INTO v_count
    FROM bank_accounts
    WHERE account_number = p_account_number;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Account does not exist: ' || p_account_number);
    END IF;

    -- Update the balance
    UPDATE bank_accounts
    SET balance = balance + p_amount
    WHERE account_number = p_account_number;

    -- Log Transaction
    INSERT INTO transaction(log_id, account_number, transaction_type, amount, transaction_date)
    VALUES (transaction_seq.NEXTVAL, p_account_number, 'DEPOSIT', p_amount, SYSDATE);

    COMMIT;
    -- Get new balance
    SELECT balance INTO v_new_balance
    FROM bank_accounts
    WHERE account_number = p_account_number;


    DBMS_OUTPUT.PUT_LINE('Deposit successful. New balance: ' || v_new_balance);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

--task 3: Create a procedure that withdraws from the account;
CREATE OR REPLACE PROCEDURE withdrawal(
    p_account_number IN VARCHAR2,
    p_amount IN NUMBER
)
AS
    v_balance NUMBER;
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Withdrawal amount must be positive.');
    END IF;

    -- Check if account exists and get current balance
    SELECT balance INTO v_balance
    FROM bank_accounts
    WHERE account_number = p_account_number;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20004, 'Insufficient balance.');
    END IF;

    -- Deduct the amount
    UPDATE bank_accounts
    SET balance = balance - p_amount
    WHERE account_number = p_account_number;

    -- Log the transaction
    INSERT INTO transaction(log_id, account_number, transaction_type, amount, transaction_date)
    VALUES (transaction_seq.NEXTVAL, p_account_number, 'WITHDRAWAL', p_amount, SYSDATE);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Withdrawal successful. New balance: ' || (v_balance - p_amount));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Account does not exist: ' || p_account_number);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/
-- Simulate API Call Using PL/SQL Block
BEGIN
    deposit('ACC001', 1000);
    withdrawal('ACC002', 2000);
    withdrawal('ACC002', 5000); -- Should show "Insufficient Funds"
END;

select * from transaction;
select * from BANK_ACCOUNTS;

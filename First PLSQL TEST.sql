CREATE SEQUENCE token_seq INCREMENT BY 1 START WITH 1;

CREATE TABLE app_token(
    system_id NUMBER PRIMARY KEY,
    system_name VARCHAR2(255),
    token VARCHAR2(255),
    expiry_date DATE
);

--task 2: Insert Sample Tokens          
INSERT INTO app_token(system_id, system_name, token, expiry_date)
VALUES (token_seq.NEXTVAL, 'System A', 'TOKEN123A', SYSDATE + 3);

INSERT INTO app_token(system_id, system_name, token, expiry_date)
VALUES(token_seq.NEXTVAL, 'System B', 'TOKEN123B', SYSDATE + 5);

--task 3: Write a Token Validation Procedure
CREATE OR REPLACE PROCEDURE validate_token (
    p_token IN VARCHAR2,
    p_status OUT VARCHAR2
) IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM app_token
    WHERE token = p_token
      AND expiry_date > SYSDATE;

    IF v_count > 0 THEN
        p_status := 'Authenticated';
    ELSE
        p_status := 'Invalid Token';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_status := 'Error occurred';
END;

--task 4  Simulate API Call Using PL/SQL Block
DECLARE 
     v_status VARCHAR2(50);
BEGIN
    validate_token('TOKEN123A', v_status);
    DBMS_OUTPUT.PUT_LINE('Token Status: ' || v_status);
END;

--task 5: Auto Expiry Cleanup

CREATE OR REPLACE PROCEDURE expired_tokens IS 
BEGIN
    DELETE FROM app_token WHERE expiry_date < SYSDATE;
    COMMIT;

    INSERT INTO app_token(system_id, system_name, token, expiry_date)
    VALUES (TOKEN_SEQ.nextval, 'System C', 'TOKEN123C', SYSDATE + 9);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occured' || SQLERRM);
END;


--call procedures for each
DECLARE
    v_status VARCHAR2(50);
BEGIN
    validate_token('TOKEN123A', v_status);
    DBMS_OUTPUT.PUT_LINE('TOKEN123A Status: ' || v_status);
END;

BEGIN
    expired_tokens;
    DBMS_OUTPUT.PUT_LINE('Expired tokens cleaned and new token inserted.');
END;

SELECT * FROM app_token;

--task 6: Create a Trigger for Auto Expiry Cleanup
CREATE OR REPLACE TRIGGER trg_expired_tokens
AFTER INSERT ON app_token  
FOR EACH ROW
BEGIN
    IF :NEW.expiry_date < SYSDATE THEN
        DELETE FROM app_token WHERE system_id = :NEW.system_id;
    END IF;
END;
--task 7: Test the Trigger  

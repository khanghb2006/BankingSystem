USE BankingSystem
GO

/**
    Procedure : sp_loan_review
    Description: The employee decides whether to approve or reject a loan application. 

    Input:
        + @loan_id BIGINT : The ID of the loan application to be reviewed.
        + reviewer_id NCHAR(10) : The ID of the employee reviewing the loan application.
        + @decision VARCHAR(20) : The decision made by the employee ('Approved' or 'Rejected').
    
    Output:
        + vw_LoanDetails : A view that provides updated details of the loan application, including the status and the ID of the employee who reviewed it.
        + message
    
    Note:
        + approved_by is set to the employee_id of the employee who reviewed the loan application.
*/
CREATE OR ALTER PROCEDURE sp_loan_review
    @loan_id BIGINT,
    @reviewer_id NCHAR(10),
    @decision VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;
            -- Validate loan ID
            IF dbo.fn_loan_validate_id(@loan_id) = 0
                THROW 95000 , 'Invalid loan ID.', 1;

            -- Reviewer must be an Loan Officer
            IF dbo.fn_loan_validate_loan_officer(@reviewer_id) = 0
                THROW 95001 , 'Reviewer is not a Loan Officer.', 1;

            -- Validate decision
            IF @decision NOT IN ('Approved', 'Rejected')
                THROW 95002 , 'Invalid decision.', 1;

            -- Loan status must be 'Pending' to be reviewed
            DECLARE @current_status VARCHAR(20);
            SELECT @current_status = status
            FROM Loan
            WHERE loan_id = @loan_id;

            IF @current_status <> 'Pending'
                THROW 95003, 'Loan is not in Pending status.', 1;


            -- Update the loan application with the review decision and reviewer ID
            UPDATE Loan
            SET 
                status = @decision,
                approved_by = @reviewer_id
            WHERE loan_id = @loan_id
                AND status = 'Pending';

            IF @@ROWCOUNT = 0
                THROW 95004, 'Failed to update loan application. It may have been reviewed already.', 1;

        COMMIT TRANSACTION;

        -- Return message
        SELECT *,
            CASE @decision
                WHEN 'Approved' THEN 'Loan application approved.'
                WHEN 'Rejected' THEN 'Loan application rejected.'
            END AS message
        FROM vw_LoanDetails
        WHERE loan_id = @loan_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END
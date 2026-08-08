/*
====================================================
    Transaction Views
    Author : Huynh Bao Khang
    Description : Views related to bank transactions
====================================================
*/

USE BankingSystem;
GO
 
/*
------------------------------------------------
    View: vw_TransactionDetails
    Description: View to retrieve bank transaction details
------------------------------------------------
*/
CREATE OR ALTER VIEW vw_TransactionDetails 
AS
    SELECT
        BT.transaction_id,

        -- Sender
        BT.from_bank_account_id,
        dbo.fn_mask_bank_account_number(FBA.bank_account_number) 
            AS masked_from_account_number,
        FC.customer_id,
        FC.full_name,

        -- Receiver
        BT.to_bank_account_id,
        dbo.fn_mask_bank_account_number(TBA.bank_account_number) 
            AS masked_to_account_number,
        TC.customer_id AS to_customer_id,
        TC.full_name AS to_full_name,

        -- Transaction information
        BT.amount,
        BT.fee,
        BT.transaction_type,
        BT.status,
        BT.created_at,
        BT.description
    FROM BankTransaction BT
    LEFT JOIN BankingAccount FBA 
        ON BT.from_bank_account_id = FBA.bank_account_id
    LEFT JOIN BankingAccount TBA
        ON BT.to_bank_account_id = TBA.bank_account_id
    LEFT JOIN Customer FC
        ON FBA.customer_id = FC.customer_id
    LEFT JOIN Customer TC
        ON TBA.customer_id = TC.customer_id;
GO

/*
----------------------------------------------------
    View: vw_TransactionSummary
    Description:
        Lightweight transaction information for
        transaction history and listing.
----------------------------------------------------
*/
CREATE OR ALTER VIEW vw_TransactionSummary
AS
    SELECT
        BT.transaction_id,
        
        -- Sender
        BT.from_bank_account_id,
        dbo.fn_mask_bank_account_number(FBA.bank_account_number) 
            AS masked_from_account_number,

        -- Receiver
        BT.to_bank_account_id,
        dbo.fn_mask_bank_account_number(TBA.bank_account_number) 
            AS masked_to_account_number,
        
        -- Transaction information
        BT.amount,
        BT.fee,
        BT.transaction_type,
        BT.status,
        BT.created_at,
        BT.description
    FROM BankTransaction BT
    LEFT JOIN BankingAccount FBA 
        ON BT.from_bank_account_id = FBA.bank_account_id
    LEFT JOIN BankingAccount TBA
        ON BT.to_bank_account_id = TBA.bank_account_id;
GO
DECLARE @fromdate datetime;
DECLARE @todate datetime;
DECLARE @account varchar(20);
DECLARE @accountoff varchar(20);

SET @fromdate = PARSE('__FROMDATE__' AS datetime USING 'ru');
SET @todate = PARSE('__TODATE__' AS datetime USING 'ru');

SET @account = '__account__';
SET @accountoff = '__accountoff__';

SELECT
    GJE.SUBLEDGERVOUCHER      AS Voucher,
    GJE.ACCOUNTINGDATE        AS AccountingDate,
    CASE WHEN GJAE.ISCREDIT = 0 THEN MA.MAINACCOUNTID     ELSE MACorr.MAINACCOUNTID END AS DebitAccount,
    CASE WHEN GJAE.ISCREDIT = 0 THEN MACorr.MAINACCOUNTID ELSE MA.MAINACCOUNTID     END AS CreditAccount,
    CAST(SUM(GJAE.AccountingCurrencyAmount) AS money) AS AmountMST
FROM GeneralJournalEntry GJE
JOIN GeneralJournalAccountEntry GJAE
    ON GJAE.GeneralJournalEntry = GJE.RECID        -- no ISCREDIT filter: both sides
JOIN DimensionAttributeValueCombination DAVC
    ON DAVC.RecId = GJAE.LEDGERDIMENSION
JOIN MAINACCOUNT MA
    ON MA.RECID = DAVC.MAINACCOUNT
JOIN GeneralJournalAccountEntry_W GJAEW
    ON GJAEW.GeneralJournalAccountEntry = GJAE.RECID
JOIN GeneralJournalAccountEntry_W GJAEWCorr
    ON  GJAEWCorr.GeneralJournalEntry        = GJAEW.GeneralJournalEntry
    AND GJAEWCorr.BondBatchTrans_RU          = GJAEW.BondBatchTrans_RU
    AND GJAEWCorr.GeneralJournalAccountEntry <> GJAEW.GeneralJournalAccountEntry
JOIN GeneralJournalAccountEntry GJAECorr
    ON GJAECorr.RECID = GJAEWCorr.GeneralJournalAccountEntry
JOIN DimensionAttributeValueCombination DAVCCorr
    ON DAVCCorr.RecId = GJAECorr.LEDGERDIMENSION
JOIN MAINACCOUNT MACorr
    ON MACorr.RECID = DAVCCorr.MAINACCOUNT
WHERE GJE.ACCOUNTINGDATE >= @fromdate
  AND GJE.ACCOUNTINGDATE <  DATEADD(DAY, 1, @todate)
  AND MA.MAINACCOUNTID LIKE @account         
  AND MACorr.MAINACCOUNTID NOT LIKE @accountoff;
GROUP BY GJE.SUBLEDGERVOUCHER, GJE.ACCOUNTINGDATE, MA.MAINACCOUNTID, MACorr.MAINACCOUNTID
